# CanDoKu — Kế hoạch xây dựng lại hoàn chỉnh

> **For agentic workers:** Đọc file này trước khi bắt đầu bất kỳ module nào. File này chứa execution protocol, interface contracts, và parallel execution map. Mỗi module plan nằm tại `docs/superpowers/plans/rebuild/NN-name.md`.

**Goal:** Xây dựng lại CanDoKu hoàn chỉnh dựa trên kiến trúc và thiết kế tham khảo từ `extracted_reusable/`, tạo phiên bản gốc, không vi phạm bản quyền, tối ưu hơn cho nền tảng Godot 4.x.

**Tham khảo gốc:** 7 module trong `extracted_reusable/scripts/` (~224 files, ~35,700 dòng) cùng level data mẫu (`bankData4x4.json`, `bankData4x4.pace.json`). **Chỉ tham khảo hành vi, KHÔNG copy code.**

**Đích:** Bản playtest 30 level (RST-011), N=4–6, S1–S3, offline, không Endless/IAP/ads/analytics. Kiến trúc bank-based cho scale vô hạn level.

**Tech Stack:** Godot 4.x, GDScript, JSON data, atomic file I/O

**Level Architecture:** Bank + Pace + Playlist (tham khảo `bankData*.json` / `bankData*.pace.json` từ extracted_reusable). Bank chứa levels phân nhóm theo rank; Pace chứa nhịp độ hint; Playlist (campaign) tham chiếu vào bank. Transform system ×8 (rotation + mirror) nhân content.

---

## Execution Protocol — Dành cho agent

### Preflight (BẮT BUỘC trước khi code)

```bash
# 1. Kiểm tra branch — phải bắt đầu từ dev
git status
git branch --show-current   # phải là dev hoặc codex/<module>

# 2. Tạo nhánh module (nếu chưa có)
git checkout -b codex/rebuild-module-NN

# 3. Giữ nguyên thay đổi sẵn có — KHÔNG stash/reset code người khác
git status  # ghi nhận modified files, chỉ commit files thuộc module mình

# 4. Verify tool hoạt động
rtk python -B tools/verify.py --godot <executable>  # hoặc GODOT_BIN
```

### Per-module gate (SAU KHI hoàn thành module)

```bash
# 1. Chạy tests của module
godot --headless --script game/tests/test_<module>.gd

# 2. Clean-room check — KHÔNG được có tên từ reference
grep -rE "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/

# 3. Không import từ extracted_reusable
grep -r "extracted_reusable" game/scripts/ game/tests/

# 4. Commit đúng files
git add game/scripts/<module>/ game/tests/test_<module>.gd
git commit -m "feat(<module>): <mô tả>"
```

### Parallel Execution Map

Modules có thể chạy song song theo wave. Agent chỉ cần đợi wave trước hoàn thành.

```
Wave 1 (song song):  M01-Core  +  M05-Theme
                      ↓              ↓
Wave 2 (song song):  M02-State + M03-Content + M04-Input
                      ↓         ↓              ↓
Wave 3 (song song):  M06-Feedback + M07-Campaign
                      ↓              ↓
Wave 4:              M08-Screens
                      ↓
Wave 5:              M09-Integration
                      ↓
Wave 6:              M10-Content-Generation
```

**Quy tắc:** Module chỉ bắt đầu implement khi TẤT CẢ dependencies đã pass gate. Nếu dependency chưa xong, agent có thể viết tests trước (TDD) dùng mock/stub từ interface contracts bên dưới.

---

## Interface Contracts — API giữa các modules

> Agent implement module X chỉ cần đọc master plan + module plan X. Bảng dưới liệt kê chính xác API mà module khác cung cấp.

### Module 1: Core (`scripts/core/`)

```gdscript
# cell_model.gd
enum CellKind { BLANK = 0, MARK = 1, CANDY = 2, WRONG = 3, GIVEN = 4, LOCKED = 5 }
static func is_empty(k: int) -> bool      # chỉ BLANK
static func is_placed(k: int) -> bool     # CANDY hoặc GIVEN
static func is_candy(k: int) -> bool      # CANDY hoặc GIVEN (solver treats cả hai là candy)
static func is_available(k: int) -> bool  # BLANK hoặc MARK — player có thể tương tác
static func is_locked(k: int) -> bool     # GIVEN hoặc LOCKED — immutable
static func is_cross(k: int) -> bool      # MARK, WRONG hoặc LOCKED — hiện dấu X
static func label(k: int) -> String       # "blank", "mark", ... (lowercase)

# candy_rules.gd
static func attempt_candy(level: Dictionary, board: Array, row: int, col: int) -> Dictionary
    # Đúng/sai dựa vào solution[row] == col (GDD 02 GR-15)
    # Returns: {valid: bool, reason: String, auto_marks: Array[[row,col]]}
static func compute_auto_marks(level: Dictionary, board: Array, row: int, col: int) -> Array
    # Lock same row/col/zone/diagonal BLANK cells
    # Returns: Array of [row, col] to set LOCKED
static func compute_all_auto_marks(level: Dictionary, board: Array) -> Array
    # Recompute all locks from all placed candy — for session restore/undo
static func check_win(level: Dictionary, board: Array) -> bool
    # N candy (CANDY + GIVEN) đúng vị trí và còn hearts > 0
static func detect_clash(level: Dictionary, a: Array, b: Array) -> int
    # Returns Clash enum — chỉ dùng cho giải thích lý do sai
static func verify_level(level: Dictionary) -> bool
    # Structural validation: size, regions, solution, adjacency, zone uniqueness

# board_solver.gd — Solve loop: S1(mark) → S2(single) → S3(lock intersection)
enum Technique { ELIMINATION, SINGLE_CANDIDATE, LOCK_INTERSECTION }
static func next_hint(board: Array, size: int, zones: Array, solution: Array) -> Dictionary
    # Suy luận từ board state (không dùng solution để chọn target)
    # solution chỉ dùng cho safety assert
    # Returns: {found, technique, cell, unit_type, unit_id, reason} hoặc {found: false}
static func progressive_hint(board: Array, size: int, zones: Array, solution: Array, click: int, max_clicks: int) -> Dictionary
    # Progressive reveal: click 1 → unit, click 2+ → cell
    # Returns: {stage: "unit"|"cell"|"place", highlight: Array, text: String}
static func solve_sequence(size: int, zones: Array, solution: Array) -> Array[int]
    # Full solve from empty board; returns technique level per cell placement
static func compute_cell_ranks(board: Array, size: int, zones: Array, solution: Array) -> Array
    # NxN Array; rank = highest technique needed before cell placement
    # 0 = already placed, 1 = S1/S2 only, 2 = needs S2, 3 = needs S3, 4 = beyond S3
static func can_place(board: Array, size: int, zones: Array, row: int, col: int) -> bool
    # Core constraint check: cell empty, no candy in row/col/zone, no adjacent candy
```

### Module 2: State (`scripts/state/`)

```gdscript
# dual_slot_store.gd
func _init(dir: String, name: String)
func load() -> Variant           # Returns parsed data hoặc null
func save(data: Variant) -> bool # Returns success
func remove_all() -> void

# progress_manager.gd
func _init(store: DualSlotStore)
func current_level() -> String       # "L01", "L02", ...
func advance(label: String, score: Dictionary) -> void
func completed_count() -> int
func is_done() -> bool
func to_dict() -> Dictionary
signal progress_changed()

# session_store.gd
func _init(store: DualSlotStore)
func save_session(data: Dictionary) -> bool
func load_session() -> Variant       # Dictionary hoặc null
func clear_session() -> void
func has_pending() -> bool

# config_store.gd
func _init(store: DualSlotStore)
func get_option(key: String) -> Variant
func set_option(key: String, value: Variant) -> void
signal option_changed(key: String, value: Variant)
# Keys: "audio", "haptic", "reduced_motion", "high_contrast", "large_text"
```

### Module 3: Content (`scripts/content/`)

```gdscript
# bank_reader.gd
func load_bank(size: int) -> bool
func get_level(size: int, rank: int, index: int) -> Dictionary
    # Returns: {size, regions, solution, givens, steps, profile, rating, pidHash, logicTrace, seed}
func get_levels(size: int, rank: int) -> Array
func level_count(size: int, rank: int) -> int
func total_count(size: int) -> int

# pace_reader.gd
func load_pace(size: int) -> bool
func get_pace(size: int, rank: int, index: int) -> Dictionary
    # Returns: {rSeq: Array[int], hintCosts: Array[int]}
func validate_against_bank(bank: BankReader) -> bool

# board_transform.gd
const TRANSFORM_COUNT := 8
enum Transform { R0, R90, R180, R270, M0, M90, M180, M270 }
static func apply(level: Dictionary, t: int) -> Dictionary
    # Returns: level với regions/solution/givens đã transform

# region_painter.gd
static func assign_colors(zone_grid: Array, zone_count: int) -> Dictionary
    # Returns: {zone_id: color_index}
```

### Module 4: Input (`scripts/input/`)

```gdscript
# touch_decoder.gd
signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)
signal cell_swiped(cells: Array)
func begin(row: int, col: int, time_ms: int) -> void
func move(row: int, col: int) -> void
func finish(time_ms: int) -> void
func cancel() -> void
func tick(time_ms: int) -> void

# action_recorder.gd
enum Source { USER, SYSTEM }
func push_group(actions: Array) -> void  # [{row, col, before, after, source}]
func pop_group() -> Array
func can_undo() -> bool
func depth() -> int
func clear() -> void
func to_save_data() -> Array
static func from_save_data(data: Array) -> ActionRecorder

# play_session.gd
signal state_changed()
signal candy_found(row: int, col: int, region: String)
signal mistake_made(row: int, col: int, reason: String)
signal heart_lost(remaining: int)
signal auto_marked(cells: Array)
signal level_won()
signal level_failed()
enum Phase { ACTIVE, WON, FAILED }
func _init(level_data: Dictionary, initial_hearts: int = 3)
func mark_x(row: int, col: int) -> void
func try_candy(row: int, col: int) -> void
func undo() -> bool
func use_hint() -> void
func cell_at(row: int, col: int) -> int       # CellKind
func is_preset(row: int, col: int) -> bool
func can_undo() -> bool
func remaining_candies() -> int
var level: Dictionary
var board: Array          # NxN CellKind
var hearts: int
var mistake_count: int
var hints_used: int
var elapsed_ms: int
var phase: int
var recorder: ActionRecorder
func to_save_data() -> Dictionary
static func from_save_data(data: Dictionary, level_data: Dictionary) -> PlaySession
```

### Module 5: Theme (`scripts/theme/`)

```gdscript
# palette.gd — tất cả const, không có state
const ZONE_COLORS: Array[Color]          # 12 colors
const CANDY_BROWN, CANDY_LIGHT: Color    # player candy
const GIVEN_CANDY, GIVEN_HALO, GIVEN_BG_TINT: Color  # pre-placed candy
const LOCKED_OVERLAY, LOCKED_X_COLOR: Color           # auto-marked cells
const LOCKED_X_ALPHA: float
const ERROR_RED, ERROR_BG: Color
const MARK_WHITE, MARK_STROKE: Color
const BG_CREAM, BG_PAPER, INK, INK_LIGHT: Color
const BTN_PRIMARY, BTN_PRIMARY_HOVER, BTN_DISABLED: Color
static func cell_state_overlay(kind: int) -> Color

# layout_tokens.gd — tất cả const
const BOARD_PADDING := 16
const CELL_GAP_RATIO := 0.008
const DOUBLE_TAP_MS := 350
const MAX_UNDO_DEPTH := 100
const AUTO_MARK_STAGGER_MS := 40
const LOCK_FADE_MS := 120
const INITIAL_HEARTS := 3
```

### Module 6: Feedback (`scripts/feedback/`)

```gdscript
# sfx_catalog.gd
enum Effect { MARK, UNDO, CANDY_YES, CANDY_NO, LOCK_CELL, HINT_SHOW, STAGE_CLEAR, STAGE_FAIL, BTN_PRESS, BOARD_OPEN, RESTART }
const FILE_MAP: Dictionary       # Effect -> String path
const MIN_INTERVAL_MS: Dictionary # Effect -> int (optional per-effect)

# sfx_player.gd (extends Node — add as child)
func play(effect: int) -> void   # rate-limited
func set_muted(on: bool) -> void
func is_muted() -> bool

# bgm_player.gd (extends Node — add as child)
func play_track(path: String) -> void
func stop() -> void
func set_muted(on: bool) -> void

# vibration.gd (static)
enum Strength { SOFT, NORMAL, FIRM }
static func pulse(strength: int) -> void
static func set_on(enabled: bool) -> void
static func is_on() -> bool
static func has_hardware() -> bool
```

---

## Nguyên tắc thiết kế

1. **Nguyên gốc hoàn toàn** — Mọi tên biến, hàm, enum, cấu trúc file phải khác extracted_reusable. Tham khảo hành vi, không sao chép code.
2. **Tách module rõ ràng** — Mỗi module ≤ 300 dòng, một trách nhiệm, interface rõ ràng.
3. **Signals thay EventBus** — Dùng Godot signals native, không bus trung tâm.
4. **Offline-first** — Không phụ thuộc backend, mạng, hay account.
5. **Testable** — Logic tách khỏi UI, static functions cho pure logic, test GDScript headless.
6. **Dùng asset có sẵn** — Không tạo asset mới; liệt kê asset cần bổ sung riêng.
7. **Composition root, không autoloads** — `app_shell.gd` khởi tạo tất cả module và inject dependencies. Không dùng autoloads.

---

## Kiến trúc mục tiêu

```
game/
├── scripts/
│   ├── core/                    # Module 1: Domain logic
│   │   ├── candy_rules.gd       # Luật puzzle (thay puzzle_core)
│   │   ├── cell_model.gd        # Cell state enum + helpers
│   │   └── board_solver.gd      # Hint/solver engine
│   │
│   ├── state/                   # Module 2: Persistence & state
│   │   ├── dual_slot_store.gd   # A/B atomic save
│   │   ├── progress_manager.gd  # Campaign progress
│   │   ├── session_store.gd     # In-game session
│   │   └── config_store.gd      # Settings/preferences
│   │
│   ├── content/                 # Module 3: Content pipeline
│   │   ├── bank_reader.gd       # Load & cache level banks (rank-based)
│   │   ├── pace_reader.gd       # Load pace sidecar (hint costs)
│   │   ├── level_validator.gd   # Schema + logic validation
│   │   ├── board_transform.gd   # ×8 rotation/mirror transforms
│   │   └── region_painter.gd    # Region color assignment (LAB)
│   │
│   ├── input/                   # Module 4: Input processing
│   │   ├── touch_decoder.gd     # Raw input → cell actions
│   │   ├── play_session.gd      # Game session state machine
│   │   └── action_recorder.gd   # Undo stack
│   │
│   ├── feedback/                # Module 5: Audio & haptic
│   │   ├── sfx_player.gd        # SFX playback
│   │   ├── bgm_player.gd        # Background music
│   │   ├── sfx_catalog.gd       # Sound registry
│   │   └── vibration.gd         # Haptic feedback
│   │
│   ├── screens/                 # Module 6: UI screens
│   │   ├── app_shell.gd         # Entry point, navigation
│   │   ├── title_screen.gd      # Home/title
│   │   ├── puzzle_screen.gd     # Main gameplay
│   │   ├── puzzle_board.gd      # Board rendering
│   │   ├── result_screen.gd     # Win/fail
│   │   ├── options_screen.gd    # Settings UI
│   │   └── pill_toggle.gd       # Toggle widget
│   │
│   ├── campaign/                # Module 7: Campaign runtime
│   │   ├── campaign_runtime.gd  # Campaign progression
│   │   ├── tutorial_guide.gd    # Tutorial flow
│   │   └── nav_controller.gd    # Screen navigation state
│   │
│   └── theme/                   # Module 8: Visual tokens
│       ├── palette.gd           # Color palette constants
│       └── layout_tokens.gd     # Spacing, sizing tokens
│
├── scenes/                      # Godot scenes (.tscn)
│   ├── main.tscn                # Root scene
│   ├── title.tscn
│   ├── puzzle.tscn
│   ├── win.tscn
│   ├── fail.tscn
│   └── options.tscn
│
├── data/
│   ├── banks/
│   │   ├── bank_4x4.json        # Level bank 4×4 (rank 1-3)
│   │   ├── bank_4x4.pace.json   # Pace sidecar 4×4
│   │   ├── bank_5x5.json        # Level bank 5×5
│   │   ├── bank_5x5.pace.json   # Pace sidecar 5×5
│   │   ├── bank_6x6.json        # Level bank 6×6
│   │   └── bank_6x6.pace.json   # Pace sidecar 6×6
│   └── campaigns/
│       └── demo_30.json          # 30-level playlist → bank refs
│
├── assets/                      # (giữ nguyên hiện có)
│   └── ui/...
│
└── tests/                       # Test files
    ├── test_candy_rules.gd
    ├── test_board_solver.gd
    ├── test_dual_slot_store.gd
    ├── test_progress_manager.gd
    ├── test_bank_reader.gd
    ├── test_touch_decoder.gd
    ├── test_play_session.gd
    ├── test_feedback.gd
    └── test_campaign_runtime.gd
```

---

## Thứ tự thực hiện (Parallel Waves)

| Wave | Module | File plan | Phụ thuộc | Song song với | Ước tính |
|------|--------|-----------|-----------|---------------|----------|
| 1 | **M01 Core** | `rebuild/01-core.md` | Không | M05 | 2h |
| 1 | **M05 Theme** | `rebuild/05-theme.md` | Không | M01 | 30m |
| 2 | **M02 State** | `rebuild/02-state.md` | M01 | M03, M04 | 2h |
| 2 | **M03 Content** | `rebuild/03-content.md` | M01 | M02, M04 | 1.5h |
| 2 | **M04 Input** | `rebuild/04-input.md` | M01 | M02, M03 | 2h |
| 3 | **M06 Feedback** | `rebuild/06-feedback.md` | M02 | M07 | 1h |
| 3 | **M07 Campaign** | `rebuild/07-campaign.md` | M02, M03, M04 | M06 | 2h |
| 4 | **M08 Screens** | `rebuild/08-screens.md` | M01-M07 | — | 3h |
| 5 | **M09 Integration** | `rebuild/09-integration.md` | M01-M08 | — | 2h |
| 6 | **M10 Content Gen** | `rebuild/10-content-gen.md` | M03 | — | 1.5h |
| **Tổng** | | | | | **~17.5h** |

**Tối ưu song song:** Wave 1+2 có thể chạy 5 agents đồng thời → giảm wall-clock từ ~17h xuống ~8h.

**Quy tắc phân nhánh song song:**
- Mỗi agent tạo branch `codex/rebuild-module-NN` từ dev
- Chỉ commit files thuộc module mình: `game/scripts/<folder>/` + `game/tests/test_<name>.gd`
- Không sửa files ngoài module (trừ khi module plan chỉ định rõ)
- Merge vào dev theo thứ tự wave: Wave 1 merge trước, rồi Wave 2, v.v.

---

## Asset cần bổ sung (sau khi code hoàn thành)

### Đang có (dùng ngay)
- `game/assets/ui/board/candy.svg` — hình kẹo
- `game/assets/ui/board/heart.svg` — tim/mạng sống
- `game/assets/ui/board/icon_*.png` — icons (back, help, hint, play, restart, settings, undo)
- `game/assets/ui/home/icon_*.png` — home icons
- `game/assets/ui/icons/icon_*.svg` — settings icons (close, haptic, motion, sound, text_size)

### Cần bổ sung
| Asset | Mục đích | Ưu tiên | Ghi chú |
|-------|----------|---------|---------|
| `audio/sfx/mark.ogg` | SFX đánh X | P1 | Cần cho playtest |
| `audio/sfx/undo.ogg` | SFX undo | P1 | |
| `audio/sfx/candy_found.ogg` | SFX tìm đúng kẹo | P1 | |
| `audio/sfx/candy_wrong.ogg` | SFX đặt sai | P1 | |
| `audio/sfx/hint.ogg` | SFX dùng gợi ý | P2 | |
| `audio/sfx/win.ogg` | SFX thắng level | P1 | |
| `audio/sfx/fail.ogg` | SFX thua level | P1 | |
| `audio/sfx/tap.ogg` | SFX nhấn nút | P2 | |
| `audio/sfx/lock_tick.ogg` | SFX auto-mark lock | P2 | Subtle tick cho auto-mark cells |
| `audio/sfx/restart.ogg` | SFX restart | P3 | |
| `audio/sfx/enter.ogg` | SFX vào board | P3 | |
| `audio/bgm/theme.ogg` | Nhạc nền loop | P2 | Optional cho playtest |
| `assets/ui/board/icon_heart.svg` | Tim trên toolbar | P1 | Có heart.svg rồi |

---

## Ánh xạ Reference → Rebuild

| Reference module | Hành vi giữ lại | Module rebuild | Khác biệt chính |
|-----------------|-----------------|----------------|------------------|
| `event_bus/` | Không | — | Loại bỏ, dùng signals |
| `game_state/game_state.gd` | Save A/B, settings, progress | `state/*` | Tách 3987 dòng → 4 file < 200 dòng |
| `game_state/save_store.gd` | Dual-slot atomic write | `state/dual_slot_store.gd` | Không encrypt, JSON thay ConfigFile |
| `bank/*` | Bank loading, pace, sorting | `content/bank_reader.gd` + `pace_reader.gd` | Rank-based bank + pace sidecar, không encrypt/AB sort |
| `gameplay/core/hint_engine.gd` | R1-R3 hints | `core/board_solver.gd` | Chỉ S1-S3, API đơn giản hơn |
| `gameplay/core/level_generator.gd` | LAB color map | `content/region_painter.gd` | Tích hợp, không cần AB test |
| `gameplay/model/cell_state.gd` | Cell states (6: BLANK→LOCKED) | `core/cell_model.gd` | 6 states gồm GIVEN + LOCKED cho auto-mark |
| `gameplay/model/cell_action.gd` | Command pattern undo | `input/action_recorder.gd` | Grouped undo (candy + auto-marks = 1 group) |
| `gameplay/view/board_view.gd` | Board render, GIVEN/LOCKED | `screens/puzzle_board.gd` | GIVEN halo + LOCKED overlay + lock animation |
| `game/input/*` | Gesture, swipe interpolation | `input/touch_decoder.gd` | Gộp 11 file → 1, giữ interpolation |
| `game/view/base_game_page.gd` | Game page, progressive hint | `screens/puzzle_screen.gd` | 7611 → ~350 dòng, progressive hint flow |
| `sound/sound_manager.gd` | SFX + BGM + rate limiting | `feedback/sfx_player.gd` + `bgm_player.gd` | 11 SFX, rate limiting cho auto-mark |
| `common/vibrate_manager.gd` | Haptic | `feedback/vibration.gd` | 3 mức, không RAM/AB |
| `gameplay/selector/*` | Level selection, cursor | `campaign/campaign_runtime.gd` + `bank_cursor.gd` | Bank cursor + ×8 transform, không AB/DDA |

---

## Lưu ý quan trọng

1. **Không sao chép từ extracted_reusable/** — Mọi code phải viết mới hoàn toàn
2. **Level architecture: Bank + Pace + Playlist** — Bank chứa levels theo rank, Pace chứa hint economy, Playlist (campaign) tham chiếu vào bank. Transform ×8 cho replay.
3. **Schema giữ nguyên** — Level v4 (string regions, logicTrace proof), progress v2, session v3
4. **Không tạo asset mới** — Chỉ dùng asset hiện có; liệt kê thiếu ở bảng trên
5. **Giữ contract hiện hành** — candy/TryCandy/CandyFound theo RST-008. TryCandy đúng/sai dựa vào `solution[row] == col` (GDD 02 GR-15); `detect_clash()` chỉ dùng để giải thích lý do sai.
6. **Phạm vi playtest** — 30 level (playlist), N=4-6, S1-S3, không Endless/IAP/ads
7. **Test headless** — Mỗi module có test chạy được bằng `godot --headless`
8. **Scale design** — Bank format cho phép thêm hàng trăm level mà không đổi code; transform ×8 nhân nội dung
9. **Auto-mark system** — Đặt candy đúng → tự động lock tất cả ô cùng row/col/zone/diagonal. GIVEN cells cũng tạo auto-marks khi init. Undo = undo candy + undo all auto-marks (grouped).
10. **Progressive hint** — Click 1: highlight unit (row/col/zone). Click 2+: narrow to cell. Dùng hintCosts từ pace data.
11. **SFX rate limiting** — min_interval throttle ngăn spam sound khi auto-mark nhiều cells liên tiếp.
