# Module 7: Campaign — Runtime, Cursor & Navigation

> **Phụ thuộc:** Module 2 (State), Module 3 (Content), Module 4 (Input)
> **Tham khảo:** `extracted_reusable/scripts/gameplay/selector/` (60+ files), `game_state.gd`, cursor system

## Tổng quan

Module Campaign quản lý flow toàn bộ game: load banks, theo dõi progress, chọn level tiếp theo, điều hướng, tutorial.

Reference có level_selector system (60+ files, 5 cursor classes, AB test strategies, DDA). Rebuild giữ cơ chế bank cursor + transform reuse nhưng đơn giản hóa: 1 cursor class, không AB/DDA, playlist-based campaign.

### Hai chế độ chơi

1. **Campaign mode** (demo-30): Playlist cố định 30 level tham chiếu vào banks. Player chơi tuần tự L01→L30.
2. **Infinite mode** (future): Bank cursor duyệt tất cả levels theo rank progression, transform ×8 cho replay. (Chỉ thiết kế API, chưa cần UI)

---

## File 1: `game/scripts/campaign/bank_cursor.gd`

**Trách nhiệm:** Track position in level bank, handle transforms for replay.

**Tham khảo hành vi từ:** `gameplay/selector/cursor/main_bank_cursor.gd` (position + transform counter)

```gdscript
# bank_cursor.gd
extends RefCounted

const BoardTransform = preload("res://scripts/content/board_transform.gd")

var _size: int
var _rank: int
var _index: int = 0
var _transform: int = 0      # 0..7 — rotation/mirror variant
var _bank_count: int          # total levels in (size, rank) bucket

# --- Public API ---

func _init(size: int, rank: int, bank_count: int) -> void
    _size = size
    _rank = rank
    _bank_count = bank_count

func current() -> Dictionary
    # Returns {size, rank, index, transform}
    return {"size": _size, "rank": _rank, "index": _index, "transform": _transform}

func advance() -> Dictionary
    # Move to next level. When bank exhausted, increment transform.
    # When all 8 transforms exhausted, reset to transform 0 (loop).
    _index += 1
    if _index >= _bank_count:
        _index = 0
        _transform = (_transform + 1) % BoardTransform.TRANSFORM_COUNT
    return current()

func set_position(index: int, transform: int = 0) -> void
    _index = clampi(index, 0, _bank_count - 1)
    _transform = clampi(transform, 0, BoardTransform.TRANSFORM_COUNT - 1)

func effective_plays() -> int
    # Total unique plays = bank_count × TRANSFORM_COUNT
    return _bank_count * BoardTransform.TRANSFORM_COUNT

func to_dict() -> Dictionary
    return {"size": _size, "rank": _rank, "index": _index, "transform": _transform}

static func from_dict(d: Dictionary, bank_count: int) -> RefCounted  # returns BankCursor
    var c = new(d["size"], d["rank"], bank_count)
    c.set_position(d.get("index", 0), d.get("transform", 0))
    return c
```

**Khác biệt với reference:**
- 1 class thay 5 (BankCursor, LegacyBankCursor, MainBankCursor, PaceSorted*, TailSorted*)
- Tên: `BankCursor` thay `MainBankCursor`
- Không AB-sorted permutation (levels in bank order)
- Không "bad level" filter / tail sort
- Không LK-modified level interleaving
- Không legacy cursor (level_num < 51 compatibility)
- Serializable to/from dict for save/load

---

## File 2: `game/scripts/campaign/campaign_runtime.gd`

**Trách nhiệm:** Campaign lifecycle — load, play, advance, replay. Supports both playlist mode and infinite mode.

**Tham khảo hành vi từ:** `gameplay/selector/level_selector.gd` + `mvp_runtime.gd` hiện tại

```gdscript
# campaign_runtime.gd
extends RefCounted

const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const BankCursor = preload("res://scripts/campaign/bank_cursor.gd")

signal level_started(level_id: String)
signal level_won(level_id: String, next_id: String)
signal level_lost(level_id: String)
signal save_failed(reason: String)
signal campaign_complete()

var bank: BankReader
var pace: PaceReader
var progress: ProgressManager
var sessions: SessionStore
var current_session: PlaySession = null
var _profile_dir: String
var _playlist: Array = []     # loaded from demo_30.json

# --- Lifecycle ---

func _init(profile_dir: String) -> void

func boot() -> bool
    # 1. Load all banks (4x4, 5x5, 6x6)
    # 2. Load all pace sidecars
    # 3. Validate pace vs bank
    # 4. Load campaign playlist
    # 5. Load progress
    # 6. If pending session, try to restore it
    # Returns false on critical error

func start_level(label: String) -> PlaySession
    # Resolve label → bank ref (size, rank, index) via playlist
    # Fetch level from bank, apply transform if applicable
    # Create PlaySession, save session, emit level_started

func resume_level() -> PlaySession
    # Restore session from disk. Returns null if none.

func on_level_won(label: String, score_data: Dictionary) -> void
    # Advance progress to next playlist entry
    # Clear session
    # Emit level_won or campaign_complete (if last)
    # If save fails: keep session, emit save_failed

func on_level_lost(label: String) -> void
    # Clear session, emit level_lost

func retry_save() -> bool

func restart_level() -> PlaySession

func replay_campaign() -> void
    # Reset to first playlist entry (RST-003)

# --- Queries ---

func current_level_label() -> String
    # Returns current playlist label (e.g. "L01")

func current_level_data() -> Dictionary
    # Returns resolved level dict (with transform applied if any)

func current_pace() -> Dictionary
    # Returns pace entry for current level {rSeq, hintCosts}

func next_level_label(after: String) -> String
    # Returns next playlist label, or "" if last

func is_campaign_done() -> bool

func has_pending_session() -> bool

func playlist_order() -> Array[String]
    # Returns ordered labels ["L01", "L02", ...]

func completed_count() -> int

# --- Level resolution ---

func _resolve_playlist_entry(label: String) -> Dictionary
    # Find entry in _playlist by label. Returns {size, rank, index, difficulty}

func _fetch_level(size: int, rank: int, index: int, transform: int = 0) -> Dictionary
    # Get level from bank, apply BoardTransform.apply() if transform > 0
    # Returns full level dict ready for PlaySession

func _load_playlist(path: String) -> Dictionary
    # Load demo_30.json, validate campaignVersion, playlist structure
```

**Khác biệt với reference:**
- Playlist-based thay cursor-based progression (cho campaign mode)
- Bank cursor available nhưng chưa dùng cho UI (future infinite mode)
- `_fetch_level()` integrates transform system
- `current_pace()` returns hint economy data for hint system
- Không DDA difficulty adjustment
- Không AB test strategy selection
- Không multi-provider (server, local, milestone)

---

## File 3: `game/scripts/campaign/tutorial_guide.gd`

**Trách nhiệm:** Tutorial overlay và milestone tracking.

**Tham khảo hành vi từ:** `tutorial_controller.gd` hiện tại

```gdscript
# tutorial_guide.gd
extends RefCounted

signal milestone_reached(milestone_id: String)
signal tutorial_step(text: String, highlight_cell: Array)

const MILESTONES := {
    "T1": {"trigger": "first_board", "text": "Tap a cell to mark X — eliminate where candy can't be"},
    "T2": {"trigger": "first_mark", "text": "Double-tap to try placing candy"},
    "T3": {"trigger": "first_candy", "text": "Find all candies to win!"},
    "T4": {"trigger": "first_hint", "text": "Use hints when you're stuck"},
}

var _seen_ids: Array[String] = []

func _init(seen_ids: Array = []) -> void

func check_trigger(trigger_name: String, context: Dictionary = {}) -> void
func mark_seen(milestone_id: String) -> void
func seen_ids() -> Array[String]
func is_all_done() -> bool
```

---

## File 4: `game/scripts/campaign/nav_controller.gd`

**Trách nhiệm:** Screen navigation state machine.

**Tham khảo hành vi từ:** `ui_flow_controller.gd` hiện tại

```gdscript
# nav_controller.gd
extends RefCounted

signal screen_changed(from_screen: String, to_screen: String)

enum Screen { TITLE, PUZZLE, WIN, LOSE, OPTIONS }

const SCREEN_NAMES := {
    Screen.TITLE: "title",
    Screen.PUZZLE: "puzzle",
    Screen.WIN: "win",
    Screen.LOSE: "lose",
    Screen.OPTIONS: "options",
}

const ROUTES := {
    Screen.TITLE: [Screen.PUZZLE, Screen.OPTIONS],
    Screen.PUZZLE: [Screen.WIN, Screen.LOSE, Screen.TITLE, Screen.OPTIONS],
    Screen.WIN: [Screen.PUZZLE, Screen.TITLE],
    Screen.LOSE: [Screen.PUZZLE, Screen.TITLE],
    Screen.OPTIONS: [Screen.TITLE, Screen.PUZZLE],
}

var current: int = Screen.TITLE

func go_to(target: int) -> bool
func current_name() -> String
```

---

## Tests

### `game/tests/test_campaign_runtime.gd`

```gdscript
extends SceneTree

const CampaignRuntime = preload("res://scripts/campaign/campaign_runtime.gd")
const BankCursor = preload("res://scripts/campaign/bank_cursor.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_boot()
    _test_start_and_win()
    _test_replay()
    _test_save_failure_recovery()
    _test_cursor_advance()
    _test_cursor_transform_wrap()
    _test_cursor_serialize()
    if _fails.is_empty():
        print("CAMPAIGN_RUNTIME_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_boot() -> void:
    var dir := _temp_dir("boot")
    var rt := CampaignRuntime.new(dir)
    _assert(rt.boot(), "boot succeeds")
    _assert(rt.current_level_label() == "L01", "starts at L01")
    _assert(rt.playlist_order().size() >= 4, "playlist loaded")
    _clean(dir, rt)

func _test_start_and_win() -> void:
    var dir := _temp_dir("win")
    var rt := CampaignRuntime.new(dir)
    rt.boot()
    var session := rt.start_level("L01")
    _assert(session != null, "session created")
    var wins: Array = []
    rt.level_won.connect(func(lid, nid): wins.append([lid, nid]))
    rt.on_level_won("L01", {"score": 400})
    _assert(wins.size() == 1, "won signal emitted")
    _assert(rt.current_level_label() == "L02", "advanced to L02")
    _clean(dir, rt)

func _test_replay() -> void:
    var dir := _temp_dir("replay")
    var rt := CampaignRuntime.new(dir)
    rt.boot()
    rt.replay_campaign()
    _assert(rt.current_level_label() == "L01", "replayed to L01")
    _clean(dir, rt)

func _test_save_failure_recovery() -> void:
    var dir := _temp_dir("savefail")
    var rt := CampaignRuntime.new(dir)
    rt.boot()
    rt.start_level("L01")
    var blocker := dir.path_join("progress.json.tmp")
    DirAccess.make_dir_absolute(blocker)
    var errors: Array = []
    rt.save_failed.connect(func(r): errors.append(r))
    rt.on_level_won("L01", {"score": 400})
    _assert(errors.size() >= 1, "save failure reported")
    _assert(rt.has_pending_session(), "session kept on failure")
    DirAccess.remove_absolute(blocker)
    _assert(rt.retry_save(), "retry succeeds")
    _assert(rt.current_level_label() == "L02", "progress advanced after retry")
    _clean(dir, rt)

func _test_cursor_advance() -> void:
    var cursor := BankCursor.new(4, 1, 5)  # 5 levels in bank
    _assert(cursor.current()["index"] == 0, "starts at 0")
    cursor.advance()
    _assert(cursor.current()["index"] == 1, "advanced to 1")
    # Advance to end of bank
    for i in 4:
        cursor.advance()
    _assert(cursor.current()["index"] == 0, "wrapped to 0")
    _assert(cursor.current()["transform"] == 1, "transform incremented")

func _test_cursor_transform_wrap() -> void:
    var cursor := BankCursor.new(4, 1, 1)  # 1 level, all transforms
    for i in 8:
        cursor.advance()
    _assert(cursor.current()["transform"] == 0, "transform wraps to 0 after 8")

func _test_cursor_serialize() -> void:
    var cursor := BankCursor.new(4, 2, 10)
    cursor.set_position(5, 3)
    var d := cursor.to_dict()
    var restored := BankCursor.from_dict(d, 10)
    _assert(restored.current()["index"] == 5, "index preserved")
    _assert(restored.current()["transform"] == 3, "transform preserved")

func _temp_dir(tag: String) -> String:
    return OS.get_user_data_dir().path_join("test_cr_%s_%s" % [tag, Time.get_ticks_usec()])

func _clean(dir: String, rt: CampaignRuntime) -> void:
    rt.progress._store.remove_all()
    rt.sessions._store.remove_all()
    DirAccess.remove_absolute(dir)

func _assert(cond: bool, label: String) -> void:
    if not cond:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/campaign/`
- [ ] Viết `bank_cursor.gd` (position tracking + transform wrapping)
- [ ] Viết `nav_controller.gd`
- [ ] Viết `tutorial_guide.gd`
- [ ] Viết test `test_campaign_runtime.gd` (fail)
- [ ] Viết `campaign_runtime.gd` (playlist + bank integration)
- [ ] Chạy test → pass
- [ ] Commit: `feat(campaign): add bank cursor, runtime, navigation and tutorial`
