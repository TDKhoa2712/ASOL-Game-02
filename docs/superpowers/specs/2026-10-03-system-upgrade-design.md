# Thiết kế nâng cấp hệ thống CanDoKu — Tham khảo hành vi Meowdoku

> **Trạng thái:** Bản thiết kế chờ duyệt
> **Ngày:** 2026-10-03
> **Phạm vi:** 7 module nâng cấp, triển khai theo 5 phase
> **Tiên quyết:** Nhánh `feat/gameplay-ui-realign` merge vào `dev` trước khi bắt đầu

---

## Mục lục

1. [Nguyên tắc bản quyền](#1-nguyên-tắc-bản-quyền)
2. [Tổng quan 7 module](#2-tổng-quan-7-module)
3. [Module A — Shape Fingerprint (Canonical Dedup)](#3-module-a--shape-fingerprint)
4. [Module B — Pace Adjuster (DDA)](#4-module-b--pace-adjuster)
5. [Module C — Board Solver nâng cao (Locked Subsets + Chains)](#5-module-c--board-solver-nâng-cao)
6. [Module D — Colorblind Mode](#6-module-d--colorblind-mode)
7. [Module E — Puzzle Snapshot (Retry Contract)](#7-module-e--puzzle-snapshot)
8. [Module F — Bank Codec (XOR Encryption)](#8-module-f--bank-codec)
9. [Module G — Bank mở rộng 5×5, 6×6](#9-module-g--bank-mở-rộng)
10. [Lộ trình triển khai 5 phase](#10-lộ-trình-triển-khai)
11. [Rủi ro và giảm thiểu](#11-rủi-ro-và-giảm-thiểu)

---

## 1. Nguyên tắc bản quyền

Tuân thủ AGENTS.md và RST-012:

- **Tham khảo hành vi** từ `extracted_reusable/`, KHÔNG sao chép code, tên hàm, tên enum, chuỗi ký tự
- Tất cả tên module, class, hàm, enum, signal phải **nguyên gốc**
- Tên cấm (clean-room gate): `EventBus`, `EventName`, `GameState`, `SaveStore`, `SoundManager`, `BgmPauseReason`, `VibrateManager`, `BoardGestureRecognizer`, `CellAction`, `CellState`, `BoardInputScheme`, `BankData`, `BankSorter`, `LevelBankIO`, `BankPage`, `QueenDoku`, `queendoku`, `meowdoku`
- Thuật toán toán học công khai (D4 group, CIELAB ΔE, SHA-256, XOR cipher, graph coloring, k-subset enumeration) không phải IP — triển khai lại từ đặc tả toán học
- Clean-room gate phải pass trước mỗi commit:
  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
  # Expected: 0 matches
  ```

---

## 2. Tổng quan 7 module

| Module | File mới/sửa | Phụ thuộc | Phase |
|--------|-------------|-----------|-------|
| A. Shape Fingerprint | `content/shape_fingerprint.gd` (mới) | `board_transform.gd` | P1 |
| B. Pace Adjuster | `campaign/pace_adjuster.gd` (mới), sửa `campaign_runtime.gd` | `progress_manager.gd` | P3 |
| C. Solver nâng cao | Sửa `core/board_solver.gd` | `candy_rules.gd`, `cell_model.gd` | P2 |
| D. Colorblind Mode | Sửa `content/region_painter.gd`, sửa `screens/puzzle_board.gd` | `config_store.gd` | P2 |
| E. Puzzle Snapshot | Sửa `campaign/campaign_runtime.gd`, sửa `state/session_store.gd` | Modules A, D | P1 |
| F. Bank Codec | `content/bank_codec.gd` (mới), sửa `content/bank_reader.gd` | Không | P4 |
| G. Bank mở rộng | Python tools, data files | Module C (để rate chính xác) | P3 |

### Sơ đồ phụ thuộc giữa modules

```
Phase 1: [A: Shape Fingerprint] ──→ [E: Puzzle Snapshot]
Phase 2: [C: Solver nâng cao]  ──→ (enables accurate rating for G)
         [D: Colorblind Mode]  ──→ (E cần overlay data)
Phase 3: [B: Pace Adjuster]    ──→ (cần bank lớn hơn playlist)
         [G: Bank mở rộng]     ──→ (cần C để rate)
Phase 4: [F: Bank Codec]       ──→ (release build only)
```

---

## 3. Module A — Shape Fingerprint

### Mục tiêu

Tính canonical ID cho topology bàn cờ (bất biến dưới D4), dùng để chống trùng lặp khi bank mở rộng.

### Hành vi tham khảo

Reference tính canonical ID bằng: 8 D4 variants → normalize region labels theo scan order → serialize → chọn lexicographic min → SHA-256 lấy 16 ký tự đầu → format `"{size}x{size}_{hash16}"`. Queue gần đây cap 100, tìm kiếm ngược (reverse linear search).

### Thiết kế

**File mới:** `game/scripts/content/shape_fingerprint.gd`

```
extends RefCounted

static func compute(size: int, regions: Array) -> String
  - Với mỗi t trong 0..7:
    - transformed = BoardTransform.transform_regions(regions, size, t)
    - normalized = _remap_labels(transformed, size)
    - serialized = "|".join(normalized)
  - canonical = min(all serialized)
  - hash = SHA256(canonical).hex_encode().substr(0, 16)
  - return "%dx%d_%s" % [size, size, hash]

static func _remap_labels(regions: Array, size: int) -> Array[String]
  - Quét từng ô từ trên-trái sang dưới-phải
  - Label đầu tiên gặp → "A", thứ hai → "B", ...
  - Trả mảng string đã remap
```

**Tích hợp vào ProgressManager:**
- Thêm field `recent_shapes: Array` trong progress data (cap 50 cho R1, có thể tăng lên 100)
- `record_shape(shape_id: String)` — append, trim nếu quá cap
- `has_recent_shape(shape_id: String) -> bool` — reverse linear search

**Tích hợp vào CampaignRuntime:**
- Khi `start_level()`, tính shape_id của level → kiểm tra recent → nếu trùng, thử D4 variant khác (transform_id khác) hoặc chọn level khác cùng rank
- Sau khi kết thúc ván (won/lost), record shape_id

**Tối ưu build-time:**
- Bank JSON đã có `pidHash` — đối chiếu với runtime compute để validate
- Nếu bank entry có sẵn `pidHash`, dùng trực tiếp thay vì tính lại runtime

### Test

- `test_shape_fingerprint.gd`:
  - 8 D4 variants của cùng topology → cùng fingerprint
  - Hai topology khác nhau → fingerprint khác
  - Remap labels: region "C" xuất hiện trước "A" → sau remap "C"→"A", "A"→"B"
  - Khớp với `pidHash` trong bank data

---

## 4. Module B — Pace Adjuster

### Mục tiêu

Điều chỉnh rank level tiếp theo dựa trên chuỗi thắng/thua gần đây — tăng thách thức cho người giỏi, giảm frustration cho người yếu.

### Hành vi tham khảo

Reference có hệ thống DDA phức tạp phụ thuộc level range:
- **Promotion:** consecutive clean wins (không sai, không hint) đạt threshold → strategy +1. Threshold: 2 wins cho level < 51, 1 win cho level ≥ 51.
- **Demotion:** consecutive fails đạt threshold → strategy -1. Threshold: 1 fail cho level < 21, 2 fails cho level ≥ 21. Guard: chỉ demote 1 lần mỗi level. Retry demotion: 2 retries liên tiếp cùng strategy → demote.
- **Caps:** max rank 2 cho level 1-20, max 3 cho 21-50, max 4 cho 51-100. Min rank: 1 (hoặc 2 cho level ≥ 101).
- **Randomization:** Nếu strategy ≥ 3, chọn random rank trong [2, strategy].

### Thiết kế — Đơn giản hóa cho phạm vi R1

CanDoKu R1 chỉ có 30-50 level, N=4-6, rank 1-3. Hệ thống DDA cần đơn giản hơn reference nhưng giữ cùng nguyên lý.

**File mới:** `game/scripts/campaign/pace_adjuster.gd`

```
extends RefCounted

signal adjusted(reason: String, offset: int)

var _clean_streak: int = 0
var _fail_streak: int = 0
var _retry_streak: int = 0
var _last_rank: int = 0
var _demoted_this_level: bool = false

func record_result(won: bool, hints_used: int, mistakes: int, was_retry: bool) -> void
  - won + hints_used == 0 + mistakes == 0 → _clean_streak += 1, _fail_streak = 0
  - won + (hints > 0 hoặc mistakes > 0) → _clean_streak = 0, _fail_streak = 0
  - !won → _fail_streak += 1, _clean_streak = 0
  - was_retry → _retry_streak += 1, else _retry_streak = 0

func rank_offset(level_order: int, base_rank: int) -> int
  - max_rank = 2 nếu level_order <= 15, 3 nếu ≤ 30, else 4
  - Promotion: _clean_streak >= 2 → +1 (cap tại max_rank - base_rank)
  - Demotion: _fail_streak >= 2 VÀ !_demoted_this_level → -1, set _demoted_this_level
  - Retry demotion: _retry_streak >= 2 → -1
  - return clamped offset

func on_level_start() -> void
  - _demoted_this_level = false

func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void
```

**Tích hợp:**
- `CampaignRuntime` giữ instance `pace_adjuster`
- Playlist entry thêm field `base_rank` (= rank hiện tại), runtime rank = base_rank + offset
- `_fetch_level()` tìm level trong bank có rank = target_rank; fallback rank gần nhất nếu không có
- `on_level_won()`/`on_level_lost()` gọi `pace_adjuster.record_result()`
- Persist `pace_adjuster.to_dict()` trong progress save

**Yêu cầu tiên quyết:**
- Bank phải có nhiều level hơn playlist cho mỗi size/rank để DDA có level thay thế
- → Module G (Bank mở rộng) phải hoàn tất trước khi DDA thực sự hoạt động
- Trước đó, pace_adjuster vẫn track streak nhưng offset = 0 nếu bank không có alternative

### Test

- `test_pace_adjuster.gd`:
  - 2 clean wins → offset +1
  - 2 fails → offset -1, demote guard chỉ 1 lần
  - 2 retries → offset -1
  - rank cap theo level_order
  - to_dict/from_dict round-trip

---

## 5. Module C — Board Solver nâng cao

### Mục tiêu

Thêm kỹ thuật Locked Subsets (k=2–6) và Contradiction Chains để giải 100% level bằng logic thuần, hỗ trợ hint chính xác cho mọi rank.

### Hành vi tham khảo

Reference triển khai 5 cấp độ:
- **R1:** Naked single — unit (row/col/zone) có đúng 1 candidate cell
- **Mark hints:** Tự động loại trừ neighbors của candy đã đặt
- **R2:** Box/line reduction — 4 sub-mode (zone→row, zone→col, row→zone, col→zone)
- **R3/R4:** Locked subsets — sinh tổ hợp k zones (k=2..min(unplaced-1, 6)), kiểm tra candidate rows/cols fit trong đúng k lines. R3 cho k≤3, R4 cho k>3. Có reverse variant (k lines chứa đúng k colors). KHÔNG dùng bitmask, dùng Dictionary-based sets.
- **R4_chain/R5_chain:** Contradiction — giả đặt candy, propagate forced singles, kiểm tra empty unit. Depth ≤ 2 = R4_chain, else R5_chain.

### Thiết kế

**Sửa file:** `game/scripts/core/board_solver.gd`

**Thay đổi Technique enum:**
```gdscript
enum Technique {
  ELIMINATION = 1,       # S1: auto-mark (đã có)
  SINGLE_CANDIDATE = 2,  # S2: naked single (đã có)
  LOCK_INTERSECTION = 3, # S3: pointing/claiming (đã có, = R2 reference)
  SUBSET_PAIR = 4,       # S4: locked subsets k=2
  SUBSET_TRIPLE = 5,     # S5: locked subsets k=3
  SUBSET_QUAD = 6,       # S6: locked subsets k=4-6
  CONTRA_CHAIN = 7,      # S7: contradiction chain
}
```

**Hàm mới — `_try_locked_subsets()`:**
```
static func _try_locked_subsets(board, size, regions, max_k: int = 6) -> Dictionary
  - Thu thập unplaced zones
  - Với k = 2, 3, ..., min(unplaced - 1, max_k):
    - Sinh tổ hợp k zones bằng _gen_subsets()
    - Cho mỗi tổ hợp:
      - Thu thập tất cả candidate cells của k zones
      - candidate_rows = set of distinct rows
      - candidate_cols = set of distinct cols
      - Forward: nếu candidate_rows.size() == k → loại candidates ở zones khác trên cùng k rows
      - Forward: nếu candidate_cols.size() == k → loại candidates ở zones khác trên cùng k cols
      - Reverse: nếu k rows chứa candidates chỉ thuộc k zones → loại candidates của k zones ở rows khác
  - Trả {found, eliminated, technique, subset_zones}
```

**Hàm mới — `_try_contradiction()`:**
```
static func _try_contradiction(board, size, regions, max_depth: int = 2) -> Dictionary
  - Cho mỗi candidate cell (r, c):
    - Clone board, đặt candy tại (r, c)
    - Propagate: loop apply_elimination + try_single_candidate
    - Nếu gặp unit rỗng (không còn candidate nào) → contradiction
      → cell (r, c) bị loại
  - depth tracking: mỗi lần propagate tạo chain, depth += 1
  - Trả {found, eliminated, technique: CONTRA_CHAIN}
```

**Cập nhật `next_hint()`:**
```
Thứ tự: S2 → S3 → S4/S5/S6 (subsets) → S7 (contradiction) → "no hint"
```

**Cập nhật `solve_sequence()`:**
- Bỏ fallback thả candy
- Chạy full chain: elimination → single → lock_intersection → subsets → contradiction
- Ghi lại technique cho mỗi step → trả profile `{s1, s2, s3, s4, s5, s6, s7}`

**Hàm mới — `replay_solve()`:**
```
static func replay_solve(size, regions, solution, givens) -> Dictionary
  - Chạy solve_sequence() trên empty board + givens
  - Trả {steps: int, profile: {s1..s7}, max_technique: int, solved: bool}
  - Dùng cho auto-benchmark rating levels
```

**Cân nhắc hiệu năng:**
- N=4: C(4,2)=6 subsets → trivial
- N=6: C(6,2)=15, C(6,3)=20 → vẫn nhanh
- N=8+: C(8,4)=70 — chấp nhận được. C(10,6)=210 — cần profiling
- Giới hạn mặc định max_k=6 cho runtime hint, max_k=3 cho real-time (trong hint button callback)
- Contradiction chain giới hạn max_depth=2 cho runtime

### Tương thích ngược

- S2 và S3 behavior không đổi
- `solve_sequence()` trả array `int` vẫn tương thích — giá trị mới (4-7) chỉ xuất hiện ở level phức tạp hơn
- `progressive_hint()` API không đổi

### Test

- `test_board_solver_advanced.gd`:
  - Level cần subset pair → solver tìm ra elimination chính xác
  - Level cần subset triple → tương tự
  - Contradiction chain: giả đặt dẫn đến bế tắc → cell bị loại
  - `replay_solve()` trên 30 level hiện tại → 100% solved, profile khớp bank pace
  - Performance: solve N=6 trong < 50ms headless

---

## 6. Module D — Colorblind Mode

### Mục tiêu

Người khiếm thị màu phân biệt được tất cả vùng thông qua biểu tượng overlay + bảng màu contrast cao.

### Hành vi tham khảo

Reference chia zones thành hai pool theo luminance: darkest n colors → pattern pool, còn lại → plain pool. 6 biểu tượng: star, diamond, heart, triangle, cross, dot. Overlay color dùng HSV shift (dark zones) hoặc CIE L* binary search lerp-to-white (light zones). Mỗi pool chạy max-distance color assignment độc lập.

### Thiết kế

**Sửa file:** `game/scripts/content/region_painter.gd`

**Thêm:**
```gdscript
enum OverlayIcon { NONE, STAR, DIAMOND, HEART, TRIANGLE, CROSS, DOT }

static func assign_with_overlays(size: int, zones: Array, palette: Array[Color]) -> Dictionary
  - Tính luminance cho mỗi color trong palette: 0.299*R + 0.587*G + 0.114*B
  - Sắp xếp palette theo luminance tăng dần
  - n_pattern = ceili(size / 2.0) — một nửa zones có pattern
  - dark_pool = palette[0..n_pattern-1] (tối nhất)
  - light_pool = palette[n_pattern..]
  - Chạy graph coloring trên từng pool riêng (dùng _build_adjacency + max-distance)
  - Gán OVERLAY_ICONS[i % 6] cho zones thuộc dark pool
  - Trả {colors: Dictionary, overlays: Dictionary}

static func overlay_tint(base_color: Color, is_dark: bool) -> Color
  - Dark zone: tăng saturation +0.15, giảm value -0.1 (HSV)
  - Light zone: dùng CIE L* để lerp toward white đến target delta 8.0
  - Trả color cho overlay icon
```

**Setting mới trong `config_store.gd`:**
- `colorblind_enabled: bool = false`
- Persist trong user config

**Sửa `screens/puzzle_board.gd`:**
- Khi `colorblind_enabled`:
  - Dùng `assign_with_overlays()` thay `assign_colors()`
  - Vẽ overlay icon centered trong mỗi cell bằng `_draw()` hoặc Label node
  - Icon dùng font symbol hoặc vẽ procedural (không cần asset file)

**Sửa `screens/options_screen.gd`:**
- Thêm toggle "Colorblind Mode" / "Chế độ khiếm thị màu"

### Test

- `test_colorblind.gd`:
  - `assign_with_overlays()` trả đúng số zones, mỗi zone có color + overlay
  - Dark zones có overlay ≠ NONE, light zones có overlay = NONE
  - Không hai zone kề nhau cùng color
  - Overlay icon không lặp trong cùng neighborhood
  - `overlay_tint()` trả color với ΔE đủ lớn so với base

---

## 7. Module E — Puzzle Snapshot

### Mục tiêu

Đảm bảo Restart/Resume trả về chính xác cùng bài toán: cùng regions, colors, solution, givens, overlays.

### Hành vi tham khảo

Reference snapshot gồm: bank coordinates (size, rank, index), prebuilt regions + solution, level_seed, prefill_positions, custom_color_map, rating, r1-r5 steps. Deterministic replay = dùng snapshot data, không regenerate.

### Thiết kế

**Sửa `campaign_runtime.gd` — `start_level()`:**

Sau khi fetch level + assign colors + compute overlays + compute shape_id:
```gdscript
var snapshot := {
  "level_id": label,
  "size": level.size,
  "rank": level.rank,
  "bank_index": entry.index,
  "transform_id": entry.get("transform", 0),
  "regions": level.regions.duplicate(true),
  "solution": level.solution.duplicate(true),
  "givens": level.givens.duplicate(true),
  "zone_colors": colors.duplicate(true),    # Dictionary zone→Color hex
  "zone_overlays": overlays.duplicate(true), # Dictionary zone→OverlayIcon int
  "hearts_start": 3,
  "seed": level.get("seed", 0),
  "shape_hash": shape_id,
  "rating": pace_entry.get("rating", 0),
  "solve_profile": pace_entry.get("profile", {}),
  "timestamp_start": Time.get_unix_time_from_system(),
}
```

**Sửa `session_store.gd`:**
- `save_session()` lưu snapshot bên cạnh board state
- `load_session()` trả snapshot + board state

**Sửa `restart_level()`:**
- Đọc snapshot từ session store
- Tạo PlaySession từ snapshot regions/solution/givens thay vì fetch lại từ bank
- Giữ nguyên colors/overlays

**Sửa `resume_level()`:**
- Đọc snapshot + board state
- Khôi phục PlaySession chính xác

### Tương thích ngược

- Session v3 hiện tại không có snapshot → resume cũ vẫn hoạt động (fetch lại từ bank)
- Session v4 mới có snapshot → dùng snapshot nếu có, fallback fetch nếu không

### Test

- `test_puzzle_snapshot.gd`:
  - start → restart → cùng regions, solution, givens, colors
  - start → simulate play → save → resume → board state khớp
  - Session v3 (không snapshot) → fallback fetch thành công

---

## 8. Module F — Bank Codec

### Mục tiêu

Mã hóa file bank JSON trong release build để chống đọc trộm.

### Hành vi tham khảo

Reference dùng repeating-key XOR: `bytes[i] ^= key.unicode_at(i % key_len)`. Editor đọc plain JSON, runtime đọc encoded. Symmetric: encode = decode.

### Thiết kế

**File mới:** `game/scripts/content/bank_codec.gd`

```gdscript
extends RefCounted

static func xor_transform(data: PackedByteArray, key: String) -> PackedByteArray
  - var key_bytes := key.to_utf8_buffer()
  - var result := data.duplicate()
  - for i in range(result.size()):
  -   result[i] ^= key_bytes[i % key_bytes.size()]
  - return result
```

**Sửa `bank_reader.gd`:**
- Load logic:
  ```
  var raw := FileAccess.get_file_as_bytes(path)
  if not OS.has_feature("editor"):
    raw = BankCodec.xor_transform(raw, _get_key())
  var text := raw.get_string_from_utf8()
  var parsed := JSON.parse_string(text)
  ```
- Key: đọc từ `ProjectSettings` hoặc hardcode constant (KHÔNG commit key thật vào repo — dùng export preset hoặc CI inject)

**Python build tool:** `tools/encode_banks.py`
- Đọc tất cả bank JSON → XOR encode → ghi vào thư mục export
- Chạy trước `godot --export-release`

### Lưu ý bảo mật

XOR repeating-key KHÔNG phải mã hóa an toàn — chỉ là obfuscation chống casual reading. Đủ cho game puzzle offline. Không dùng để bảo vệ dữ liệu nhạy cảm.

### Test

- `test_bank_codec.gd`:
  - encode → decode → khớp original
  - decode sai key → garbage (không crash)
- `test_encode_banks.py`:
  - Round-trip encode/decode tất cả bank files

---

## 9. Module G — Bank mở rộng

### Mục tiêu

Sinh bank 5×5 và 6×6 với đủ level cho DDA hoạt động; rate chính xác bằng solver nâng cao.

### Thiết kế

**Dùng tools đã có:**
- `GDD/tools/generate_levels.py` — sinh level candidates
- `GDD/tools/build_playtest_bank.py` — đóng gói bank
- `GDD/tools/generate_pace.py` — sinh pace sidecar
- `tools/validate_content.py` — validate

**Mục tiêu content:**
| Size | Số level tối thiểu | Phân bố rank | Ghi chú |
|------|-------------------|-------------|---------|
| 4×4 | 30 (đã có) | R1: 12, R2: 10, R3: 8 | Giữ nguyên |
| 5×5 | 30 | R1: 8, R2: 12, R3: 8, R4: 2 | Cần solver nâng cao để rate |
| 6×6 | 20 | R1: 4, R2: 8, R3: 6, R4: 2 | S3 levels cần Locked Subsets |

**Auto-rating:**
- Sau khi Module C hoàn tất, chạy `replay_solve()` trên tất cả level candidates
- Rating = f(s2_steps, s3_steps, s4_steps, bottleneck_count, solve_depth)
- Chỉ accept level mà solver giải được 100% bằng logic thuần (max_technique ≤ S6)

**Playlist mở rộng:**
- `demo_30.json` → `campaign_v2.json` (50-80 levels)
- Progression: 4×4 levels 1-20, 5×5 levels 21-40, 6×6 levels 41-50+
- Mỗi size/rank có ≥ 3 alternatives cho DDA chọn

**Cập nhật validator:**
- `tools/validate_content.py` mở rộng accept N=5, N=6
- `tools/verify.py` validate tất cả bank sizes

### Test

- Validate 100% bank content qua `tools/validate_content.py`
- `replay_solve()` 100% levels → solved
- Unique solution verified qua `count_solutions()` (đã có trong Python tools)
- Clean-room gate pass

---

## 10. Lộ trình triển khai

### Phase 1 — Nền tảng dữ liệu (Shape Fingerprint + Puzzle Snapshot)

**Thời lượng ước tính:** 4-5 ngày
**Tiên quyết:** `feat/gameplay-ui-realign` merged vào `dev`

| Task | Nội dung | Ngày |
|------|----------|------|
| P1.1 | Viết `shape_fingerprint.gd` + test | 1.5d |
| P1.2 | Tích hợp recent_shapes vào `progress_manager.gd` | 0.5d |
| P1.3 | Thiết kế puzzle snapshot schema (session v4) | 0.5d |
| P1.4 | Sửa `campaign_runtime.gd` + `session_store.gd` cho snapshot | 1.5d |
| P1.5 | Test snapshot: start/restart/resume deterministic | 0.5d |
| P1.6 | Gate: clean-room + full verify | 0.5d |

**Deliverable:** Restart/Resume deterministic, shape fingerprint sẵn sàng cho dedup.

### Phase 2 — Solver & Accessibility (Locked Subsets + Colorblind)

**Thời lượng ước tính:** 7-8 ngày
**Tiên quyết:** Phase 1 merged

| Task | Nội dung | Ngày |
|------|----------|------|
| P2.1 | Viết `_try_locked_subsets()` k=2 + test | 2d |
| P2.2 | Mở rộng k=3..6 + `_gen_subsets()` | 1d |
| P2.3 | Viết `_try_contradiction()` + test | 1.5d |
| P2.4 | Cập nhật `next_hint()` chain + `solve_sequence()` bỏ fallback | 0.5d |
| P2.5 | Viết `replay_solve()` + benchmark 30 level hiện tại | 0.5d |
| P2.6 | Colorblind: `assign_with_overlays()` + `overlay_tint()` | 1d |
| P2.7 | Colorblind: UI toggle + puzzle_board rendering | 1d |
| P2.8 | Gate: clean-room + full verify + performance profiling | 0.5d |

**Deliverable:** Hint system giải mọi rank, colorblind mode hoạt động.

### Phase 3 — Content & DDA (Bank mở rộng + Pace Adjuster)

**Thời lượng ước tính:** 8-10 ngày
**Tiên quyết:** Phase 2 merged (cần solver nâng cao để rate)

| Task | Nội dung | Ngày |
|------|----------|------|
| P3.1 | Sinh bank 5×5 (30 levels) + validate | 2d |
| P3.2 | Sinh bank 6×6 (20 levels) + validate | 2d |
| P3.3 | Auto-rate tất cả levels bằng `replay_solve()` | 0.5d |
| P3.4 | Thiết kế campaign_v2 playlist (50-80 levels) | 1d |
| P3.5 | Viết `pace_adjuster.gd` + test | 1.5d |
| P3.6 | Tích hợp DDA vào `campaign_runtime.gd` | 1.5d |
| P3.7 | Test end-to-end: DDA chọn level thay thế từ bank | 1d |
| P3.8 | Gate: full verify + content validation | 0.5d |

**Deliverable:** 80 levels đa kích thước, DDA điều chỉnh rank tự động.

### Phase 4 — Release Hardening (Bank Encryption)

**Thời lượng ước tính:** 2-3 ngày
**Tiên quyết:** Phase 3 merged

| Task | Nội dung | Ngày |
|------|----------|------|
| P4.1 | Viết `bank_codec.gd` + test | 0.5d |
| P4.2 | Viết `tools/encode_banks.py` | 0.5d |
| P4.3 | Sửa `bank_reader.gd` editor/runtime branch | 0.5d |
| P4.4 | Test export build đọc được encoded bank | 0.5d |
| P4.5 | Gate: full verify + test release build | 0.5d |

**Deliverable:** Bank files mã hóa trong release, plain trong editor.

### Phase 5 — Polish & Playtest

**Thời lượng ước tính:** 3-5 ngày
**Tiên quyết:** Phase 4 merged

| Task | Nội dung | Ngày |
|------|----------|------|
| P5.1 | Playtest mù 50+ levels — thu thập feedback | 2d |
| P5.2 | Chỉnh DDA thresholds dựa trên playtest data | 1d |
| P5.3 | Chỉnh colorblind UX dựa trên feedback | 0.5d |
| P5.4 | Final gate: full verify + device test Android | 1d |

**Deliverable:** Sản phẩm sẵn sàng cho vòng QA chính thức.

### Tổng thời lượng ước tính: 24-31 ngày làm việc

```
Phase 1 ████░░░░░░░░░░░░░░░░░░░░░░░░░░  (5d)
Phase 2 ░░░░░████████░░░░░░░░░░░░░░░░░░  (8d)
Phase 3 ░░░░░░░░░░░░░█████████░░░░░░░░░  (10d)
Phase 4 ░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░  (3d)
Phase 5 ░░░░░░░░░░░░░░░░░░░░░░░░████░░░  (5d)
```

---

## 11. Rủi ro và giảm thiểu

| Rủi ro | Tác động | Giảm thiểu |
|--------|----------|-----------|
| Locked Subsets k>3 chậm trên GDScript (N=8+) | Hint lag | Giới hạn max_k=3 cho real-time hint, k=6 chỉ cho offline benchmark. Profiling gate: < 50ms |
| Bank 5×5/6×6 không đủ level unique topology | DDA không có alternatives | Tăng seed range, relaxed max_givens. Fallback: DDA offset = 0 |
| Colorblind pattern khó phân biệt trên màn nhỏ | UX kém | Test trên 4.7" screen minimum. Dùng icon ≥ 16dp |
| Session v3→v4 migration lỗi | Mất progress | Đọc v3 backward-compatible, chỉ ghi v4. Không migrate destructive |
| XOR key leak trong decompile | Bank đọc được | Accepted risk — XOR chỉ là obfuscation. Key rotation mỗi version |
| DDA thresholds không phù hợp casual player | Frustration tăng | Playtest Phase 5 chỉnh thresholds. Default conservative (offset = 0 khi uncertainty cao) |
| Nhánh gameplay-ui-realign chưa merge | Block Phase 1 | Ưu tiên close realign trước. Có thể bắt đầu Module C trên nhánh riêng song song |
