# Module 8: Screens — UI Presentation

> **Phụ thuộc:** Tất cả module trước
> **Tham khảo:** `extracted_reusable/scripts/game/view/` (30+ files, 12,000+ dòng)

## Tổng quan

Module Screens là lớp trình bày UI. Reference có BaseGamePage (7611 dòng) + GamePage (5054 dòng) — god objects chứa tools, drafts, hints, combos, ads, countdown, rank, streak, golden fish, cheat commands. Rebuild tách thành 7 files nhỏ, mỗi file ≤ 300 dòng.

**Cải tiến từ reference:**
- GIVEN cell rendering (darker candy + gold halo, distinct from player candy)
- LOCKED cell rendering (dimmed overlay + faded grey X)
- Auto-mark animation (staggered fade-in when cells lock after candy placement)
- Progressive hint highlight (highlight unit zone/row/col, then narrow to cell)

---

## File 1: `game/scripts/screens/app_shell.gd`

**Trách nhiệm:** Root entry point — khởi tạo dependencies, chuyển screens.

**Tham khảo hành vi từ:** `bootstrap.gd` hiện tại

```gdscript
# app_shell.gd
extends Control  # root of main.tscn

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const BgmPlayer = preload("res://scripts/feedback/bgm_player.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")

var runtime: CampaignRuntime
var config: ConfigStore
var nav: NavController
var sfx: SfxPlayer
var bgm: BgmPlayer

@onready var screen_host: Control = $ScreenHost

func _ready() -> void:
    # 1. Init config, apply audio/haptic settings
    # 2. Init campaign runtime, boot
    # 3. Init nav controller
    # 4. Init SFX + BGM players (add as children)
    # 5. Connect nav.screen_changed -> _swap_screen
    # 6. Connect config.option_changed -> _apply_setting
    # 7. Show title screen or handle boot error

func _swap_screen(from: String, to: String) -> void:
    # Remove current screen scene, instantiate new one, add to screen_host

func _apply_setting(key: String, _value: Variant) -> void:
    # Sync audio/haptic toggles to players

func _on_boot_error() -> void:
    # Show error dialog for corrupt save
```

**Khác biệt với reference:**
- ~100 dòng thay 330 (`bootstrap.gd`)
- Không autoload — composition root in scene tree
- Dependencies injected, không globals
- `NavController` thay inline screen management

---

## File 2: `game/scripts/screens/title_screen.gd`

**Trách nhiệm:** Home/title screen — play button, level info, settings access.

**Tham khảo hành vi từ:** `home_screen.gd` hiện tại

```gdscript
# title_screen.gd
extends Control

signal play_pressed()
signal options_pressed()

var runtime: CampaignRuntime  # injected

func setup(rt: CampaignRuntime) -> void:
    # Display current level, completed count, play/resume label

func _on_play() -> void:
    play_pressed.emit()

func _on_options() -> void:
    options_pressed.emit()
```

---

## File 3: `game/scripts/screens/puzzle_screen.gd`

**Trách nhiệm:** Main gameplay screen — board, toolbar, timer, hint button.

**Tham khảo hành vi từ:** `base_game_page.gd` (7611 dòng) + `game_page.gd` (5054 dòng) + `board_screen.gd` hiện tại (747 dòng)

**Cải tiến:** auto-mark flow integration, progressive hint display.

```gdscript
# puzzle_screen.gd
extends Control

signal go_home()
signal level_done(won: bool)

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const BoardSolver = preload("res://scripts/core/board_solver.gd")

var runtime: CampaignRuntime
var sfx: SfxPlayer
var session: PlaySession
var _hint_click_count: int = 0  # progressive hint tracking
var _hint_target: Array = []    # current hint target cell

@onready var board: PuzzleBoard = $Board
@onready var hearts_display: Control = $Toolbar/Hearts
@onready var hint_btn: Button = $Toolbar/HintBtn
@onready var undo_btn: Button = $Toolbar/UndoBtn
@onready var restart_btn: Button = $Toolbar/RestartBtn
@onready var home_btn: Button = $Toolbar/HomeBtn
@onready var timer_label: Label = $Toolbar/Timer

func setup(rt: CampaignRuntime, sfx_player: SfxPlayer) -> void:
    # Store refs, create/resume session, configure board

func _connect_session() -> void:
    # Connect session signals: candy_found, mistake_made, auto_marked, level_won, level_failed

func _on_board_tap(row: int, col: int) -> void:
    # Handle tap: if blank -> mark_x; if mark -> unmark
    # Play SFX + haptic
    # Reset hint state if interacting with hinted cell

func _on_board_double_tap(row: int, col: int) -> void:
    # Handle double-tap: try_candy
    # Play SFX + haptic based on result

func _on_hint() -> void:
    # Progressive hint using pace data:
    # Click 1: get hint from BoardSolver.progressive_hint(click=1)
    #          -> highlight entire unit (row/col/zone)
    # Click 2+: BoardSolver.progressive_hint(click=N)
    #          -> narrow to cell
    # Use current_pace().hintCosts to determine max clicks
    var pace_data := runtime.current_pace()
    var costs := pace_data.get("hintCosts", [1])
    var max_clicks := costs[min(_hint_click_count, costs.size() - 1)] if not costs.is_empty() else 1
    var level := session.level
    var hint := BoardSolver.progressive_hint(
        session.board, level["size"], level["regions"],
        level["solution"], _hint_click_count + 1
    )
    if hint.is_empty():
        return
    _hint_click_count += 1
    _hint_target = [hint["row"], hint["col"]]
    if hint.has("unit_type"):
        board.highlight_unit(hint["unit_type"], hint["unit_id"])
    else:
        board.highlight_cell(hint["row"], hint["col"])
    sfx.play(SfxCatalog.Effect.HINT_SHOW)
    session.use_hint()

func _on_undo() -> void:
    # session.undo(), play SFX
    # Undo reverses candy + all auto-marks as one group

func _on_restart() -> void:
    # Confirm dialog -> restart session
    _hint_click_count = 0

func _on_home() -> void:
    # If session dirty: save before leaving

func _on_candy_found(row: int, col: int) -> void:
    sfx.play(SfxCatalog.Effect.CANDY_YES)
    Vibration.pulse(Vibration.Strength.NORMAL)
    _hint_click_count = 0  # reset hint for next step
    board.redraw()

func _on_auto_marked(cells: Array) -> void:
    # Animate auto-mark: staggered lock appearance
    board.animate_locks(cells)
    # Play rate-limited lock SFX for tactile feedback
    sfx.play(SfxCatalog.Effect.LOCK_CELL)

func _on_mistake(row: int, col: int, clash: String) -> void:
    sfx.play(SfxCatalog.Effect.CANDY_NO)
    Vibration.pulse(Vibration.Strength.FIRM)
    _update_hearts()
    board.redraw()

func _on_level_won() -> void:
    sfx.play(SfxCatalog.Effect.STAGE_CLEAR)
    level_done.emit(true)

func _on_level_failed() -> void:
    sfx.play(SfxCatalog.Effect.STAGE_FAIL)
    level_done.emit(false)

func _update_hearts() -> void
func _update_timer(delta: float) -> void
func _process(delta: float) -> void
```

**Khác biệt với reference:**
- ~250 dòng thay 7611+5054 (12,665 dòng combined)
- **Thêm:** `_on_auto_marked()` — animates LOCKED cells appearing after candy
- **Thêm:** Progressive hint flow (`_hint_click_count`, `progressive_hint()`, unit highlight)
- **Thêm:** `LOCK_CELL` SFX on auto-mark
- Không tool system (locate, mouse, draft)
- Không combo/score fly effects
- Không like hand feedback, misplace animation
- Không idle hint timer, strategy overlay
- Không ads, countdown revive, golden fish
- Không cheat commands
- Session + SFX + Haptic injected, không globals

---

## File 4: `game/scripts/screens/puzzle_board.gd`

**Trách nhiệm:** Board rendering — draw all 6 CellKind states, regions, auto-mark animation.

**Tham khảo hành vi từ:** `gameplay/view/board_view.gd` (1803 dòng) + `board_view.gd` hiện tại (342 dòng)

**Cải tiến:** Renders GIVEN (gold halo + dark candy) and LOCKED (dimmed + grey X) states.

```gdscript
# puzzle_board.gd
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

signal cell_tapped(row: int, col: int)
signal cell_double_tapped(row: int, col: int)

var _session: PlaySession
var _zone_grid: Array = []
var _zone_colors: Dictionary = {}
var _decoder: TouchDecoder
var _candy_tex: Texture2D = null
var _lock_anim_cells: Array = []     # cells currently animating lock-in
var _lock_anim_progress: float = 1.0 # 0..1 animation progress
var _highlight_cells: Array = []     # hint-highlighted cells
var _highlight_unit: String = ""     # "row"/"col"/"zone" or "" for single cell

func configure(session: PlaySession) -> void:
    # Store session, precompute zone grid + colors, create decoder
    # Connect decoder signals -> re-emit as board signals

func redraw() -> void:
    queue_redraw()

func highlight_cell(row: int, col: int) -> void:
    # Highlight single cell for hint (final reveal)
    _highlight_cells = [[row, col]]
    _highlight_unit = ""
    queue_redraw()

func highlight_unit(unit_type: String, unit_id: Variant) -> void:
    # Highlight all cells in a row/col/zone for progressive hint
    _highlight_unit = unit_type
    _highlight_cells = _cells_in_unit(unit_type, unit_id)
    queue_redraw()

func clear_highlight() -> void:
    _highlight_cells = []
    _highlight_unit = ""
    queue_redraw()

func animate_locks(cells: Array) -> void:
    # Start staggered lock animation for newly locked cells
    _lock_anim_cells = cells
    _lock_anim_progress = 0.0
    # Animation driven by _process

func _ready() -> void:
    # Load candy texture, set minimum size, mouse filter

func _process(delta: float) -> void:
    # Advance lock animation if active
    if _lock_anim_progress < 1.0:
        _lock_anim_progress = minf(_lock_anim_progress + delta / (LayoutTokens.LOCK_FADE_MS / 1000.0), 1.0)
        queue_redraw()
        if _lock_anim_progress >= 1.0:
            _lock_anim_cells = []

func _draw() -> void:
    # Card background
    # For each cell:
    #   1. Draw region color
    #   2. Apply state overlay (Palette.cell_state_overlay)
    #   3. Draw state content:
    #      BLANK:  nothing
    #      MARK:   white X
    #      CANDY:  candy texture (CANDY_BROWN tint)
    #      WRONG:  red X + error background
    #      GIVEN:  candy texture (GIVEN_CANDY tint) + GIVEN_HALO ring
    #      LOCKED: dimmed overlay + faded grey X (LOCKED_X_COLOR at LOCKED_X_ALPHA)
    #   4. If cell in _highlight_cells: draw hint glow
    #   5. If cell in _lock_anim_cells: apply fade-in alpha based on stagger

func _gui_input(event: InputEvent) -> void:
    # Dispatch touch/mouse to decoder

func _cell_at(pos: Vector2) -> Array:
    # Convert pixel position to [row, col]

func _draw_cell_candy(rect: Rect2, is_given: bool) -> void:
    # Draw candy with appropriate tint:
    # is_given=true: GIVEN_CANDY color + GIVEN_HALO halo ring
    # is_given=false: CANDY_BROWN + CANDY_LIGHT

func _draw_cell_x(rect: Rect2, is_wrong: bool, is_locked: bool) -> void:
    # Draw X mark:
    # is_wrong=true: ERROR_RED, full alpha
    # is_locked=true: LOCKED_X_COLOR at LOCKED_X_ALPHA (faded grey)
    # else: MARK_WHITE (player mark)

func _draw_lock_overlay(rect: Rect2, alpha: float) -> void:
    # Draw LOCKED_OVERLAY with animation alpha

func _cells_in_unit(unit_type: String, unit_id: Variant) -> Array:
    # Return all [row,col] in a row/col/zone for progressive hint

func _board_rect() -> Rect2
func _cell_gap(board_w: float) -> float
```

**Khác biệt với reference:**
- ~250 dòng thay 1803
- **Thêm:** `_draw_cell_candy(is_given)` — renders GIVEN vs CANDY distinctly
- **Thêm:** `_draw_cell_x(is_wrong, is_locked)` — renders WRONG vs LOCKED vs MARK
- **Thêm:** `_draw_lock_overlay()` — dimmed overlay for LOCKED cells
- **Thêm:** `animate_locks()` — staggered fade-in animation for auto-marked cells
- **Thêm:** `highlight_unit()` / `highlight_cell()` — progressive hint rendering
- Không `@tool` (editor preview)
- Không `ChangeSource` enum (12 variants)
- Không cell_view.gd separate (inline drawing)
- Không hint overlay region dim, pattern mode
- Không integrity healing, meow feedback
- Không touch enable/disable token system
- Không AB test palette selection (single palette)
- `_decoder: TouchDecoder` thay external gesture engine

---

## File 5: `game/scripts/screens/result_screen.gd`

**Trách nhiệm:** Win/Fail result screen.

```gdscript
# result_screen.gd
extends Control

signal next_pressed()
signal retry_pressed()
signal home_pressed()
signal replay_pressed()

var _is_win: bool
var _score: int
var _level_id: String
var _is_last_level: bool

func setup(won: bool, score: int, level_id: String, is_last: bool) -> void:
    # Show appropriate message, buttons, score
    # Win last level: show 'Hoàn thành!' message. Replay button hidden for campaign30 playtest (GDD GR-28); only visible for fixture-4 test build (RST-003).

func _on_next() -> void:
    next_pressed.emit()

func _on_retry() -> void:
    retry_pressed.emit()

func _on_home() -> void:
    home_pressed.emit()

func _on_replay() -> void:
    replay_pressed.emit()
```

---

## File 6: `game/scripts/screens/options_screen.gd`

**Trách nhiệm:** Settings UI screen.

**Tham khảo hành vi từ:** `ui/settings_screen.gd` hiện tại

```gdscript
# options_screen.gd
extends Control

signal back_pressed()

const ConfigStore = preload("res://scripts/state/config_store.gd")
const PillToggle = preload("res://scripts/screens/pill_toggle.gd")

var _config: ConfigStore

func setup(config: ConfigStore) -> void:
    # Create toggle rows for each editable key
    # Audio, Haptic, Reduced Motion, High Contrast, Large Text

func _on_toggle(key: String, on: bool) -> void:
    _config.set_option(key, on)

func _on_back() -> void:
    back_pressed.emit()
```

---

## File 7: `game/scripts/screens/pill_toggle.gd`

**Trách nhiệm:** Custom toggle switch widget.

**Tham khảo hành vi từ:** `ui/pill_switch.gd` hiện tại

```gdscript
# pill_toggle.gd
extends Button

signal toggled_value(on: bool)

var _on: bool = false

func set_on(value: bool) -> void
func is_on() -> bool
func _draw() -> void:
    # Pill shape: rounded rect, circle thumb, color based on state
```

---

## Scenes (.tscn)

Mỗi screen cần một scene file tương ứng. Layout cơ bản:

### `game/scenes/main.tscn`
```
Control (app_shell.gd)
+-- PastelBackdrop  # (giữ backdrop hiện có nếu dùng)
+-- ScreenHost (Control)  # container for screen switching
+-- SaveErrorDialog (AcceptDialog, hidden)
```

### `game/scenes/title.tscn`
```
Control (title_screen.gd)
+-- SafeArea (MarginContainer)
|   +-- VBox
|       +-- TitleLabel
|       +-- LevelLabel
|       +-- PlayButton
+-- OptionsButton (top-right)
```

### `game/scenes/puzzle.tscn`
```
Control (puzzle_screen.gd)
+-- Board (PuzzleBoard, puzzle_board.gd)
+-- Toolbar (HBox)
|   +-- HomeBtn
|   +-- Timer
|   +-- Hearts
|   +-- UndoBtn
|   +-- HintBtn
|   +-- RestartBtn
+-- TutorialOverlay (optional)
```

### `game/scenes/win.tscn` / `game/scenes/fail.tscn`
```
Control (result_screen.gd)
+-- MessageLabel
+-- ScoreLabel
+-- NextBtn / RetryBtn
+-- HomeBtn
```

### `game/scenes/options.tscn`
```
Control (options_screen.gd)
+-- Header (BackBtn + Title)
+-- ScrollContainer
    +-- VBox (toggle rows)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/screens/`
- [ ] Viết `pill_toggle.gd`
- [ ] Viết `puzzle_board.gd` — with GIVEN/LOCKED rendering + lock animation + hint highlight
- [ ] Viết `title_screen.gd`
- [ ] Viết `result_screen.gd`
- [ ] Viết `options_screen.gd`
- [ ] Viết `puzzle_screen.gd` — with auto-mark flow + progressive hint
- [ ] Viết `app_shell.gd` (root entry)
- [ ] Tạo scenes: `main.tscn`, `title.tscn`, `puzzle.tscn`, `win.tscn`, `fail.tscn`, `options.tscn`
- [ ] Commit: `feat(screens): add all UI screens with GIVEN/LOCKED states and auto-mark animation`
