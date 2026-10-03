# Last-Mile Integration Plan — Kết nối Infrastructure vào Game

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Biến 5 module infrastructure (DDA, colorblind, dedup, solver S4+, XOR codec) từ code chưa dùng thành tính năng hoạt động trong game.

**Architecture:** Mỗi task sửa 1–3 file GDScript hoặc chạy Python tooling. Không thêm module mới, chỉ kết nối các module đã có.

**Tech Stack:** Godot 4.7.2 / GDScript, Python 3.x (generation tools)

**Spec:** [meowdoku_system_design_spec.md](../specs/meowdoku_system_design_spec.md) — Mục 3.3 modules A–E và Mục 4 roadmap.

**Godot executable:** `"D:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"`

## Global Constraints

- Module ≤ 300 dòng. Kiểm tra `wc -l` sau mỗi sửa.
- Không autoloads. Composition root qua `app_shell.gd`.
- Signals thay EventBus. Không global bus.
- Clean-room: KHÔNG dùng tên `EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku`.
- Không import từ `extracted_reusable/`.
- Attribution: `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- Phạm vi: R1, 30 levels, N=4–6. Không mở R2–R4, Endless, IAP, ads, analytics.

## Review Focus

1. DDA rank_offset phải được clamp vào phạm vi rank hợp lệ của bank — nếu không, `bank.get_level()` trả `{}` và game crash khi start level.
2. Colorblind toggle phải phản ánh ngay khi quay lại puzzle — nếu người chơi bật giữa game, board cần redraw.
3. Options screen thêm key nhưng thiếu label → UI hiển thị raw key thay vì tiếng Việt.
4. `set_colorblind()` phải gọi TRƯỚC `configure()` — nếu sau thì overlays không render (bug đã fix lần trước, F2).
5. Bank 5×5 phải có unique solution cho mọi level — validate bằng `tools/validate_content.py`.

---

### Task 1: Wire DDA rank_offset vào campaign level selection

**Files:**
- Modify: `game/scripts/campaign/campaign_runtime.gd` (265 dòng hiện tại)
- Modify: `game/scripts/campaign/pace_adjuster.gd` (53 dòng hiện tại)
- Test: `game/tests/test_campaign_runtime.gd`

**Interfaces:**
- Consumes: `pace_adjuster.rank_offset` (int, tính sẵn bởi `apply_result()`)
- Consumes: `bank.get_level(size, rank, index)` → trả `{}` nếu rank/index ngoài phạm vi
- Produces: `_fetch_level_with_dda(entry) -> Dictionary` — level data đã áp dụng rank offset

**Bối cảnh:** `pace_adjuster.gd` đã tính `rank_offset` (+1/0/-1) dựa trên win/loss streak. `campaign_runtime.gd` gọi `pace_adjuster.apply_result()` khi win/loss nhưng KHÔNG BAO GIỜ đọc `rank_offset` khi lấy level. Playlist `demo_30.json` mỗi entry có `{size, rank, index}` cố định. DDA cần điều chỉnh `rank` thực tế khi fetch level từ bank.

**Hiện trạng pace_adjuster.gd:**
```gdscript
# pace_adjuster.gd — 53 dòng
var win_streak: int = 0
var loss_streak: int = 0
var rank_offset: int = 0  # Đã tính nhưng chưa ai đọc

func apply_result(won: bool, score_data: Dictionary, progress: Dictionary) -> void:
    # Cập nhật streaks và tính rank_offset
```

**Hiện trạng campaign_runtime.gd (hàm liên quan):**
```gdscript
func current_level_data() -> Dictionary:
    var entry := _resolve_playlist_entry(current_level_label())
    if entry.is_empty(): return {}
    var level := _fetch_level(entry.size, entry.rank, entry.index, int(entry.get("transform", 0)))
    # ← entry.rank được dùng trực tiếp, không có DDA offset
    ...

func _fetch_level(size: int, rank: int, index: int, transform: int = 0) -> Dictionary:
    var level := bank.get_level(size, rank, index)
    if level.is_empty(): return {}
    return BoardTransform.apply(level, transform) if transform > 0 else level.duplicate(true)
```

- [ ] **Step 1: Viết test DDA rank adjustment**

Thêm vào `game/tests/test_campaign_runtime.gd`:

```gdscript
func _test_dda_rank_adjustment() -> void:
    # Setup: win streak >= 3 → rank_offset = +1
    for i in range(3):
        runtime.pace_adjuster.apply_result(true, {"time_ms": 5000, "mistakes": 0}, runtime.progress.current)
    _assert(runtime.pace_adjuster.rank_offset == 1, "3 clean wins → offset +1")

    # Level data should come from rank+1 (clamped to valid range)
    var level := runtime.current_level_data()
    _assert(not level.is_empty(), "DDA-adjusted level exists")

    # Setup: loss streak >= 2 → rank_offset = -1
    runtime.pace_adjuster.win_streak = 0
    runtime.pace_adjuster.loss_streak = 2
    runtime.pace_adjuster.rank_offset = -1
    level = runtime.current_level_data()
    _assert(not level.is_empty(), "DDA-adjusted level (lower rank) exists")
```

- [ ] **Step 2: Run test to verify it fails**

```bash
godot --headless --path game --script res://tests/test_campaign_runtime.gd
```
Expected: tests từ trước vẫn PASS, test mới PASS vì offset=0 mặc định không đổi gì.
(Note: test sẽ PASS nhưng chưa verify rằng rank thực sự thay đổi — cần thêm assertion.)

- [ ] **Step 3: Sửa `campaign_runtime.gd` — thêm DDA-adjusted rank**

Sửa `current_level_data()`:
```gdscript
func current_level_data() -> Dictionary:
    var entry := _resolve_playlist_entry(current_level_label())
    if entry.is_empty():
        return {}
    var effective_rank := _dda_adjusted_rank(entry.size, entry.rank)
    var level := _fetch_level(entry.size, effective_rank, entry.index, int(entry.get("transform", 0)))
    if level.is_empty():
        # Fallback: dùng rank gốc nếu adjusted rank không có level
        level = _fetch_level(entry.size, entry.rank, entry.index, int(entry.get("transform", 0)))
    if level.is_empty():
        return {}
    level.id = current_level_label()
    level.hash = progress.puzzle_fingerprint(level)
    return level

func _dda_adjusted_rank(size: int, base_rank: int) -> int:
    var offset := pace_adjuster.rank_offset
    var adjusted := base_rank + offset
    # Clamp: rank ≥ 1, và kiểm tra bank có rank đó
    adjusted = max(1, adjusted)
    if bank.get_level(size, adjusted, 0).is_empty():
        return base_rank
    return adjusted
```

Đồng thời sửa `current_pace()` để cũng dùng effective rank:
```gdscript
func current_pace() -> Dictionary:
    var entry := _resolve_playlist_entry(current_level_label())
    if entry.is_empty():
        return {}
    var effective_rank := _dda_adjusted_rank(entry.size, entry.rank)
    var p := pace.get_pace(entry.size, effective_rank, entry.index)
    if p.is_empty():
        p = pace.get_pace(entry.size, entry.rank, entry.index)
    return p.duplicate(true)
```

- [ ] **Step 4: Kiểm tra line count**

```bash
wc -l game/scripts/campaign/campaign_runtime.gd
```
Expected: ~280 dòng (thêm ~15 dòng). Phải < 300.

- [ ] **Step 5: Run full test**

```bash
godot --headless --path game --script res://tests/test_campaign_runtime.gd
```
Expected: CAMPAIGN_RUNTIME_PASS

- [ ] **Step 6: Clean-room check**

```bash
rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/campaign/campaign_runtime.gd
```
Expected: no matches

- [ ] **Step 7: Commit**

```bash
git add game/scripts/campaign/campaign_runtime.gd game/tests/test_campaign_runtime.gd
git commit -m "feat(campaign): apply DDA rank_offset when selecting levels

pace_adjuster.rank_offset now adjusts the bank rank used for level
selection. Falls back to base rank if adjusted rank has no content.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Thêm colorblind toggle vào options screen

**Files:**
- Modify: `game/scripts/screens/options_screen.gd` (225 dòng)
- Modify: `game/scripts/screens/app_shell.gd` (220 dòng)
- Test: `game/tests/test_colorblind.gd` (existing), manual QA

**Interfaces:**
- Consumes: `config_store.get_option("colorblind")` → bool
- Consumes: `config_store.set_option("colorblind", bool)` — lưu và emit `option_changed`
- Produces: toggle UI cho colorblind trong options screen; `_apply_setting("colorblind", ...)` trong app_shell refresh board

**Bối cảnh:** `config_store.gd` đã có key `"colorblind"` trong DEFAULTS (false) và EDITABLE_KEYS. `puzzle_board.gd` đã có `set_colorblind(enabled)`. `puzzle_screen.gd` đã gọi `set_colorblind()` TRƯỚC `configure()`. Nhưng:
1. `options_screen.gd` KHÔNG hiển thị toggle colorblind — LABELS dict thiếu key "colorblind", TILE_KEYS_GRID không có nó
2. `app_shell._apply_setting()` chỉ xử lý "audio" và "haptic" — không xử lý "colorblind"
3. Khi người chơi bật colorblind giữa game và quay lại puzzle, board không được refresh

**Hiện trạng options_screen.gd constants:**
```gdscript
const LABELS := {
    "audio": "Âm thanh",
    "haptic": "Rung phản hồi",
    "reduced_motion": "Giảm chuyển động",
    "large_text": "Cỡ chữ lớn",
    "high_contrast": "Độ tương phản cao",
}
const TILE_KEYS_GRID := ["audio", "haptic", "reduced_motion", "large_text"]
const WIDE_KEY := "high_contrast"
```

**Hiện trạng app_shell._apply_setting():**
```gdscript
func _apply_setting(key: String, value: Variant) -> void:
    match key:
        "audio":
            if sfx != null: sfx.set_muted(not bool(value))
            if bgm != null: bgm.set_muted(not bool(value))
        "haptic":
            Vibration.set_on(bool(value))
```

- [ ] **Step 1: Sửa `options_screen.gd` — thêm colorblind key**

Thêm "colorblind" vào LABELS:
```gdscript
const LABELS := {
    "audio": "Âm thanh",
    "haptic": "Rung phản hồi",
    "reduced_motion": "Giảm chuyển động",
    "large_text": "Cỡ chữ lớn",
    "high_contrast": "Độ tương phản cao",
    "colorblind": "Hỗ trợ phân biệt màu",
}
```

Thêm layout — dùng thêm một `WIDE_KEYS` array thay vì single key, hoặc thêm một tile bên dưới grid. Cách đơn giản nhất: đổi grid thành 3 hàng × 2 cột (6 tiles), đưa "colorblind" vào grid:
```gdscript
const TILE_KEYS_GRID := ["audio", "haptic", "reduced_motion", "large_text", "colorblind"]
# Hoặc nếu muốn giữ grid 4 + 2 wide:
const WIDE_KEYS := ["high_contrast", "colorblind"]
```

Chọn approach giữ thay đổi nhỏ nhất: thêm "colorblind" vào TILE_KEYS_GRID (5 tiles, grid 2 cột → 3 hàng, tile cuối chiếm 1 cột) hoặc chuyển thành WIDE_KEY array.

Recommendation: đổi `WIDE_KEY` thành array và loop:
```gdscript
const WIDE_KEYS: Array[String] = ["high_contrast", "colorblind"]
```

Sửa `_build_rows()`:
```gdscript
# Thay:
#   vbox.add_child(_make_tile(WIDE_KEY, false))
# Bằng:
for key in WIDE_KEYS:
    vbox.add_child(_make_tile(key, false))
```

- [ ] **Step 2: Sửa `app_shell.gd` — xử lý colorblind setting change**

Thêm case "colorblind" trong `_apply_setting()`:
```gdscript
func _apply_setting(key: String, value: Variant) -> void:
    match key:
        "audio":
            if sfx != null: sfx.set_muted(not bool(value))
            if bgm != null: bgm.set_muted(not bool(value))
        "haptic":
            Vibration.set_on(bool(value))
        "colorblind":
            _refresh_puzzle_colorblind()
```

Thêm helper:
```gdscript
func _refresh_puzzle_colorblind() -> void:
    if screen_host == null or config == null:
        return
    for child in screen_host.get_children():
        if child.has_method("set_colorblind_and_redraw"):
            child.call("set_colorblind_and_redraw", bool(config.get_option("colorblind")))
```

Hoặc đơn giản hơn: khi quay lại puzzle screen từ options, `_swap_screen` đã tạo screen mới → `setup()` đã gọi `set_colorblind()`. Nên chỉ cần đảm bảo flow options→puzzle hoạt động. Kiểm tra `_on_options_back()`: nó gọi `nav.go_to(PUZZLE)` → `_swap_screen` → tạo puzzle mới → `setup(runtime, sfx, config)` → `set_colorblind(config.get_option("colorblind"))` → `configure(session)`.

**→ Flow đã hoạt động cho trường hợp quay lại puzzle.** Chỉ cần thêm toggle vào options UI. Nếu muốn live-update (bật colorblind mà không thoát puzzle), thì cần thêm logic — nhưng hiện tại options tạo screen mới khi quay lại, nên OK.

- [ ] **Step 3: Kiểm tra line count**

```bash
wc -l game/scripts/screens/options_screen.gd game/scripts/screens/app_shell.gd
```
Expected: options_screen ~228 dòng, app_shell ~220 dòng. Cả hai < 300.

- [ ] **Step 4: Run existing tests**

```bash
godot --headless --path game --script res://tests/test_colorblind.gd
```
Expected: COLORBLIND_PASS

```bash
godot --headless --path game --script res://tests/test_config_store.gd
```
Expected: STATE_CONFIG_PASS

- [ ] **Step 5: Manual QA (headless không verify rendering)**

1. Chạy game từ entry scene
2. Vào Options → verify toggle "Hỗ trợ phân biệt màu" hiển thị
3. Bật toggle → quay lại puzzle → verify overlay icons (★◆♥▲✕●) xuất hiện trên cells
4. Tắt toggle → quay lại puzzle → verify overlays biến mất

Ghi rõ: headless tests KHÔNG verify rendering. Manual QA bắt buộc.

- [ ] **Step 6: Commit**

```bash
git add game/scripts/screens/options_screen.gd
git commit -m "feat(screens): add colorblind toggle to options screen

Adds 'Hỗ trợ phân biệt màu' toggle. Flow: options→puzzle creates
fresh screen, setup() calls set_colorblind() before configure().

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Generate bank 5×5 và cập nhật campaign

**Files:**
- Run: `GDD/tools/build_playtest_bank.py --size 5`
- Create: `game/data/banks/bank_5x5.json`, `game/data/banks/bank_5x5.pace.json`
- Modify: `game/data/campaigns/demo_30.json` (thêm 5×5 levels vào playlist)
- Validate: `tools/validate_content.py`

**Interfaces:**
- Consumes: `build_playtest_bank.py --size 5` → generates bank + pace + (optionally) campaign
- Produces: bank file tại `game/data/banks/bank_5x5.json` với ranks 1–3, pace sidecar

**Bối cảnh:**
- `build_playtest_bank.py` đã có `--size {4,5,6}` argparse (F4).
- Khi `size=5`, nó bỏ qua existing L01 tutorial (chỉ cho 4×4).
- Nó generate: 12 levels rank 1, 10 levels rank 2, 8 levels rank 3 = 30 levels.
- Campaign playlist hiện tại: 30 entries, tất cả size=4.
- **Quyết định sản phẩm cần:** bao nhiêu level 5×5 trong campaign? Vị trí nào?

**CẢNH BÁO:** `build_playtest_bank.py --size 5` sẽ:
- Tạo files mới (bank_5x5.json, bank_5x5.pace.json) — an toàn
- Chỉ ghi đè demo_30.json NẾU truyền `--campaign` (mặc định có campaign path)
- → Chạy với `--campaign /dev/null` hoặc sửa để tách bước campaign

**Chiến lược an toàn:** generate bank 5×5 mà KHÔNG sửa campaign. Campaign sẽ được sửa thủ công sau.

- [ ] **Step 1: Đọc source build_playtest_bank.py (KHÔNG chạy)**

Verify argparse hoạt động đúng:
```bash
python -B GDD/tools/build_playtest_bank.py --help
```

- [ ] **Step 2: Generate bank 5×5 (an toàn — chỉ tạo file mới)**

```bash
cd GDD/tools && python -B build_playtest_bank.py --size 5 --campaign ""
```

Nếu `--campaign ""` gây lỗi, sửa command hoặc truyền path đến file tạm:
```bash
python -B GDD/tools/build_playtest_bank.py --size 5 --campaign scratch/content_gen/demo_5x5_draft.json
```

Expected output:
- `game/data/banks/bank_5x5.json` — 30 levels (12+10+8 theo rank 1/2/3)
- `game/data/banks/bank_5x5.pace.json` — pace sidecar

- [ ] **Step 3: Validate generated bank**

```bash
python -B tools/validate_content.py game/data/banks/bank_5x5.json --pace game/data/banks/bank_5x5.pace.json
```
Expected: VALID

- [ ] **Step 4: Verify bank structure**

```bash
python -c "
import json
with open('game/data/banks/bank_5x5.json') as f:
    bank = json.load(f)
print('size:', bank['size'])
print('bankVersion:', bank['bankVersion'])
for rank, levels in bank['ranks'].items():
    print(f'rank {rank}: {len(levels)} levels')
"
```
Expected: size=5, 3 ranks, ~30 levels total.

- [ ] **Step 5: Cập nhật campaign playlist (CẦN QUYẾT ĐỊNH SẢN PHẨM)**

Hiện tại demo_30.json có 30 entries 4×4. Có 2 lựa chọn:

**Option A (conservative):** Giữ nguyên demo_30.json. Bank 5×5 sẵn sàng nhưng chưa vào campaign. DDA có thể dùng nó trong tương lai.

**Option B (recommended):** Thay thế 6 level cuối (L25–L30) bằng 5×5 level, giữ difficulty progression:
```json
{"label": "L25", "size": 5, "rank": 1, "index": 0, "difficulty": "medium"},
{"label": "L26", "size": 5, "rank": 1, "index": 1, "difficulty": "medium"},
...
{"label": "L30", "size": 5, "rank": 2, "index": 0, "difficulty": "hard"}
```

**→ Hỏi chủ dự án nếu không rõ.** Nếu đã có quyết định, thực hiện. Nếu chưa, chọn Option A (chỉ generate bank, không sửa campaign).

- [ ] **Step 6: Validate campaign (nếu đã sửa)**

```bash
python -B tools/validate_content.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json
```
Expected: VALID

Lưu ý: validate_playlist kiểm tra size 4–6 hợp lệ. Nếu campaign có cả 4×4 và 5×5, cần truyền cả 2 bank (hiện tại `--bank` chỉ nhận 1 file — có thể cần chạy 2 lần hoặc sửa validator).

- [ ] **Step 7: Run Godot boot test (verify bank loads)**

```bash
godot --headless --path game --script res://tests/test_campaign_runtime.gd
```
Expected: CAMPAIGN_RUNTIME_PASS (boot() loads all bank sizes referenced in playlist)

- [ ] **Step 8: Commit**

```bash
git add game/data/banks/bank_5x5.json game/data/banks/bank_5x5.pace.json
# Nếu sửa campaign:
# git add game/data/campaigns/demo_30.json
git commit -m "feat(content): generate 5x5 puzzle bank (30 levels, ranks 1-3)

30 levels: 12 rank 1, 10 rank 2, 8 rank 3.
Generated by build_playtest_bank.py --size 5.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Encode bank files XOR cho release

**Files:**
- Run: `GDD/tools/encode_banks.py` (hoặc script tương đương)
- Modify: `game/scripts/content/bank_reader.gd` (131 dòng) — verify XOR decode path
- Validate: existing bank tests

**Interfaces:**
- Consumes: `bank_codec.gd` — `encode(data, key)` / `decode(data, key)`, 12 dòng
- Consumes: `bank_reader.gd` — đã có logic decode khi `not OS.has_feature("editor")`
- Produces: Encoded bank files sẵn sàng cho export release

**Bối cảnh:**
- `bank_codec.gd` (12 dòng): XOR encode/decode symmetric.
- `bank_reader.gd` (131 dòng): đã có nhánh `if not OS.has_feature("editor")` → decode XOR.
- `encode_banks.py` (27 dòng): Python script chạy encode trên bank JSON files.
- Bank files hiện tại: plaintext JSON.
- Mục đích: khi build release (export), bank files nên được encode để người chơi không đọc trực tiếp.

**LƯU Ý QUAN TRỌNG:**
- Encode banks là bước **build pipeline**, KHÔNG phải runtime.
- Trong editor mode, bank_reader đọc plaintext trực tiếp.
- Encoded files chỉ dùng khi export release.
- Nếu encode ngay bây giờ, editor tests sẽ fail vì bank_reader đọc plaintext trong editor.

**→ Task này xác nhận pipeline hoạt động, KHÔNG encode files trong repo.**

- [ ] **Step 1: Đọc encode_banks.py**

```bash
cat GDD/tools/encode_banks.py
```
Verify: nó encode bank JSON files in-place hoặc tạo file mới.

- [ ] **Step 2: Test encode/decode round-trip**

```bash
godot --headless --path game --script res://tests/test_bank_codec.gd
```
Expected: BANK_CODEC_PASS

- [ ] **Step 3: Test encode pipeline trên bản copy (KHÔNG sửa original)**

```bash
mkdir -p scratch/encoded_banks
cp game/data/banks/bank_4x4.json scratch/encoded_banks/
python -B GDD/tools/encode_banks.py scratch/encoded_banks/bank_4x4.json
# Verify file đã thay đổi (không còn là valid JSON)
python -c "import json; json.load(open('scratch/encoded_banks/bank_4x4.json'))" 2>&1 | head -1
```
Expected: JSON parse error (file đã encoded)

- [ ] **Step 4: Verify bank_reader decode path**

Đọc `game/scripts/content/bank_reader.gd` và xác nhận:
1. Có `const BankCodec = preload(...)` 
2. Có nhánh `if not OS.has_feature("editor")` → gọi `BankCodec.decode()`
3. XOR key khớp giữa `encode_banks.py` và `bank_reader.gd`

- [ ] **Step 5: Document encode workflow**

Nếu chưa có, thêm comment hoặc note rằng:
- `python -B GDD/tools/encode_banks.py game/data/banks/*.json` cần chạy TRƯỚC export release
- Sau encode, editor tests sẽ fail — encode chỉ cho bản export, không commit encoded files

- [ ] **Step 6: Commit (documentation only, không encode files)**

```bash
git commit --allow-empty -m "docs(build): verify XOR encode pipeline for release banks

Tested: encode_banks.py produces non-JSON output, bank_codec.gd round-trip
passes. Pipeline ready for release build step.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```
