# Module 2: State — Persistence & Configuration

> **Phụ thuộc:** Module 1 (Core) cho schema constants
> **Tham khảo:** `extracted_reusable/scripts/game_state/` (save_store.gd, game_state.gd)

## Tổng quan

Module State quản lý toàn bộ dữ liệu persist: progress campaign, session trong game, settings người dùng. Tham khảo pattern A/B dual-slot từ reference nhưng dùng JSON thay ConfigFile encrypted.

**Reference** là `game_state.gd` (3987 dòng god object) + `save_store.gd` (114 dòng).
**Rebuild** tách thành 4 file nhỏ, mỗi file < 200 dòng.

---

## File 1: `game/scripts/state/dual_slot_store.gd`

**Trách nhiệm:** Low-level atomic file I/O với dual-slot A/B protection.

**Tham khảo hành vi từ:** `save_store.gd` — dual-slot, atomic write, flag file, retry

**Thiết kế mới:**

```gdscript
# dual_slot_store.gd
extends RefCounted

const READ_ATTEMPTS := 3
const RETRY_PAUSE_MS := 60

var _dir: String
var _name: String  # "progress", "session", etc.

func _init(directory: String, file_name: String) -> void

# --- Public API ---

func write_json(data: Dictionary) -> bool
    # Atomic write: serialize → write .tmp → verify → rename to inactive slot → flip flag
    # Returns true on success

func read_json() -> Dictionary
    # Read active slot → if fail, try inactive → if fail, try legacy path
    # Returns {ok: bool, data: Dictionary, recovered: bool, reason: String}

func remove_all() -> void
    # Delete both slots + flag + legacy

func inject_corrupt(content: String) -> bool
    # Test helper: write invalid content to active slot

# --- Internal ---

func _active_label() -> String         # "a" or "b" from flag file
func _slot_file(label: String) -> String  # "{name}.{label}.json"
func _flag_file() -> String            # "{name}.flag"
func _legacy_file() -> String          # "{name}.json" (pre-A/B migration)
func _atomic_save(data: Dictionary, target_path: String) -> bool
func _read_slot(label: String) -> Dictionary  # with retry
func _parse_file(path: String) -> Dictionary
func _flip_flag(label: String) -> void
```

**Khác biệt với reference:**
- Tên: `DualSlotStore` thay `SaveStore`, `write_json`/`read_json` thay `save_config`/`load_config`
- JSON thay encrypted ConfigFile — playtest không cần encryption
- `inject_corrupt` thay `corrupt_for_test`
- Không password parameter
- Constructor nhận `(directory, file_name)` thay `(password, dir, dual_slot, path_a, path_b, flag_path, legacy_path)`

---

## File 2: `game/scripts/state/progress_manager.gd`

**Trách nhiệm:** Campaign progress — current level, completed levels, results.

**Tham khảo hành vi từ:** `game_state.gd` phần progress + `save_repository.gd` hiện tại

**Thiết kế mới:**

```gdscript
# progress_manager.gd
extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")

signal save_failed(reason: String)

const SCHEMA_VER := 2

var _store: DualSlotStore
var current: Dictionary = {}  # in-memory progress

func _init(profile_dir: String) -> void

# --- Public API ---

func load() -> Dictionary
    # Returns {ok: bool, data: Dictionary, recovered: bool, reason: String}

func save() -> bool
    # Persist current progress to disk

func new_progress(first_level_id: String) -> Dictionary
    # Create fresh progress: {progressVersion, currentLevelId, completedLevelIds, results, tutorialState}

func advance_level(level_id: String, score_data: Dictionary, level_order: Array) -> Dictionary
    # Returns {ok: bool, data: Dictionary} with updated progress

func puzzle_fingerprint(level: Dictionary) -> String
    # Deterministic hash for level data

# --- Internal ---

func _validate(data: Dictionary) -> bool
func _migrate(data: Dictionary) -> Dictionary
```

**Schema progress v2 (giữ nguyên):**
```json
{
  "progressVersion": 2,
  "currentLevelId": "L01",
  "completedLevelIds": [],
  "results": {},
  "tutorialState": { "tutorialSeenIds": [] }
}
```

---

## File 3: `game/scripts/state/session_store.gd`

**Trách nhiệm:** Lưu/load session trong game (cells, hearts, hints, elapsed time).

**Tham khảo hành vi từ:** `save_repository.gd` phần session

**Thiết kế mới:**

```gdscript
# session_store.gd
extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")

const SCHEMA_VER := 3

var _store: DualSlotStore

func _init(profile_dir: String) -> void

# --- Public API ---

func save_session(data: Dictionary) -> bool
func load_session(level_id: String, expected_hash: String) -> Dictionary
    # Returns {ok, data, reason, recreate} — recreate=true khi hash mismatch
func clear() -> void
func new_session(level_id: String, puzzle_hash: String, board_size: int) -> Dictionary
    # {sessionVersion, levelId, puzzleHash, boardSize, cells, hearts, mistake_count, hints_used, elapsedMs}

# --- Internal ---

func _validate(data: Dictionary, level_id: String, expected_hash: String) -> Dictionary
```

**Schema session v3 (giữ nguyên):**
```json
{
  "sessionVersion": 3,
  "levelId": "L01",
  "puzzleHash": "abc123",
  "boardSize": 4,
  "cells": {},
  "hearts": 3,
  "mistake_count": 0,
  "hints_used": 0,
  "elapsedMs": 0
}
```

---

## File 4: `game/scripts/state/config_store.gd`

**Trách nhiệm:** User settings/preferences — audio, haptic, visual options.

**Tham khảo hành vi từ:** `game_state.gd` phần settings + `settings.gd` hiện tại

**Thiết kế mới:**

```gdscript
# config_store.gd
extends RefCounted

signal option_changed(key: String, value: Variant)

const VERSION := 1
const DEFAULTS := {
    "audio": true,
    "haptic": true,
    "reducedMotion": false,
    "highContrast": false,
    "largeText": false,
}
const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reducedMotion", "highContrast", "largeText"]

var _path: String
var _data: Dictionary = {}

func _init(profile_dir: String) -> void

# --- Public API ---

func load_config() -> void
func save_config() -> void
func get_option(key: String) -> Variant
    # Returns value or null for unknown key
func set_option(key: String, value: Variant) -> void
    # Validates key is editable, saves, emits option_changed
func reset_defaults() -> void
    # Reset all to DEFAULTS, emit option_changed("", null)
func all_options() -> Dictionary
    # Returns copy of current settings
```

**Khác biệt với reference:**
- Tên: `ConfigStore` thay `Settings`, `option_changed` thay `changed`
- `get_option`/`set_option` thay `get_value`/`set_value`
- `EDITABLE_KEYS` thay `_MUTABLE_KEYS`
- Không version migration phức tạp (v1 đủ cho playtest)
- JSON file thay custom dictionary save

---

## Tests

### `game/tests/test_dual_slot_store.gd`

```gdscript
extends SceneTree

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_write_read_roundtrip()
    _test_corrupt_recovery()
    _test_legacy_migration()
    _test_remove_all()
    if _fails.is_empty():
        print("STATE_DUAL_SLOT_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_write_read_roundtrip() -> void:
    var dir := _temp_dir("roundtrip")
    var store := DualSlotStore.new(dir, "test")
    var data := {"version": 1, "value": "hello"}
    _assert(store.write_json(data), "write succeeds")
    var result := store.read_json()
    _assert(result["ok"], "read succeeds")
    _assert(result["data"]["value"] == "hello", "data preserved")
    store.remove_all()
    DirAccess.remove_absolute(dir)

func _test_corrupt_recovery() -> void:
    var dir := _temp_dir("corrupt")
    var store := DualSlotStore.new(dir, "test")
    # Write twice so both slots have data
    store.write_json({"version": 1, "val": "first"})
    store.write_json({"version": 1, "val": "second"})
    # Corrupt active slot
    store.inject_corrupt("NOT_JSON")
    var result := store.read_json()
    _assert(result["ok"], "recovers from inactive")
    _assert(result["recovered"], "recovery flag set")
    store.remove_all()
    DirAccess.remove_absolute(dir)

func _test_legacy_migration() -> void:
    var dir := _temp_dir("legacy")
    DirAccess.make_dir_recursive_absolute(dir)
    # Write legacy file (pre-A/B)
    var legacy := FileAccess.open(dir.path_join("test.json"), FileAccess.WRITE)
    legacy.store_string(JSON.stringify({"version": 1, "val": "legacy"}))
    legacy.flush()
    legacy.close()
    var store := DualSlotStore.new(dir, "test")
    var result := store.read_json()
    _assert(result["ok"], "legacy loads")
    _assert(result["data"]["val"] == "legacy", "legacy data preserved")
    store.remove_all()
    DirAccess.remove_absolute(dir.path_join("test.json"))
    DirAccess.remove_absolute(dir)

func _test_remove_all() -> void:
    var dir := _temp_dir("remove")
    var store := DualSlotStore.new(dir, "test")
    store.write_json({"a": 1})
    store.remove_all()
    var result := store.read_json()
    _assert(not result["ok"], "nothing after remove")
    DirAccess.remove_absolute(dir)

func _temp_dir(tag: String) -> String:
    return OS.get_user_data_dir().path_join("test_%s_%s" % [tag, Time.get_ticks_usec()])

func _assert(cond: bool, label: String) -> void:
    if not cond:
        _fails.append("FAIL: " + label)
```

### `game/tests/test_progress_manager.gd`

```gdscript
extends SceneTree

const ProgressManager = preload("res://scripts/state/progress_manager.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_new_progress()
    _test_save_load_roundtrip()
    _test_advance_level()
    _test_advance_to_end()
    if _fails.is_empty():
        print("STATE_PROGRESS_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_new_progress() -> void:
    var dir := _temp_dir("new")
    var mgr := ProgressManager.new(dir)
    var p := mgr.new_progress("L01")
    _assert(p["currentLevelId"] == "L01", "initial level")
    _assert(p["completedLevelIds"].is_empty(), "no completed")
    _clean(dir, mgr)

func _test_save_load_roundtrip() -> void:
    var dir := _temp_dir("roundtrip")
    var mgr := ProgressManager.new(dir)
    mgr.current = mgr.new_progress("L01")
    _assert(mgr.save(), "save ok")
    var loaded := mgr.load()
    _assert(loaded["ok"], "load ok")
    _assert(loaded["data"]["currentLevelId"] == "L01", "data matches")
    _clean(dir, mgr)

func _test_advance_level() -> void:
    var dir := _temp_dir("advance")
    var mgr := ProgressManager.new(dir)
    mgr.current = mgr.new_progress("L01")
    var result := mgr.advance_level("L01", {"score": 400}, ["L01", "L02", "L03"])
    _assert(result["ok"], "advance ok")
    _assert(result["data"]["currentLevelId"] == "L02", "moved to L02")
    _assert(result["data"]["completedLevelIds"].has("L01"), "L01 completed")
    _clean(dir, mgr)

func _test_advance_to_end() -> void:
    var dir := _temp_dir("end")
    var mgr := ProgressManager.new(dir)
    mgr.current = mgr.new_progress("L03")
    mgr.current["completedLevelIds"] = ["L01", "L02"]
    var result := mgr.advance_level("L03", {"score": 300}, ["L01", "L02", "L03"])
    _assert(result["ok"], "advance ok")
    _assert(result["data"]["completedLevelIds"].has("L03"), "L03 completed")
    _clean(dir, mgr)

func _temp_dir(tag: String) -> String:
    return OS.get_user_data_dir().path_join("test_pm_%s_%s" % [tag, Time.get_ticks_usec()])

func _clean(dir: String, mgr: ProgressManager) -> void:
    mgr._store.remove_all()
    DirAccess.remove_absolute(dir)

func _assert(cond: bool, label: String) -> void:
    if not cond:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/state/`
- [ ] Viết test `test_dual_slot_store.gd` (fail)
- [ ] Viết `dual_slot_store.gd`
- [ ] Chạy test → pass
- [ ] Viết test `test_progress_manager.gd` (fail)
- [ ] Viết `progress_manager.gd`
- [ ] Chạy test → pass
- [ ] Viết `session_store.gd` (cùng pattern với progress)
- [ ] Viết `config_store.gd`
- [ ] Commit: `feat(state): add dual-slot persistence and settings`
