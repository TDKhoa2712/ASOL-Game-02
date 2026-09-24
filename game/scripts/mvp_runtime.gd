extends RefCounted

const CAMPAIGN_PATH := "res://data/campaign_m1.json"
const CONTRACT_PATH := "res://tests/fixtures/interactions.v2.json"
const LevelLoader = preload("res://scripts/level_loader.gd")
const SaveRepository = preload("res://scripts/save_repository.gd")
const GestureEngine = preload("res://scripts/gesture_engine.gd")
const HintEngine = preload("res://scripts/hint_engine.gd")
const TutorialController = preload("res://scripts/tutorial_controller.gd")

signal level_ready(level_id: String)
signal session_changed(level_id: String, state: Dictionary)
signal level_won(level_id: String, next_level_id: String)
signal level_failed(level_id: String)

var repository
var campaign_path := CAMPAIGN_PATH
var contract: Dictionary = {}
var levels: Dictionary = {}
var level_ids: Array[String] = []
var progress: Dictionary = {}
var engine
var active_level: Dictionary = {}
var current_level_id := ""
var tutorial_state: Dictionary = {}
var last_hint: Dictionary = {}
var initialized := false
var tutorial_controller


func _init(save_dir: String = "", campaign_file: String = "") -> void:
	repository = SaveRepository.new(save_dir)
	if not campaign_file.is_empty():
		campaign_path = campaign_file


func initialize() -> bool:
	if initialized:
		return not levels.is_empty()
	var loaded := LevelLoader.load_document(campaign_path)
	if not loaded.get("ok", false):
		return false
	contract = _read_json(CONTRACT_PATH)
	tutorial_controller = TutorialController.new()
	for level_value in loaded.get("levels", []):
		var level: Dictionary = level_value
		levels[str(level["id"])] = level
	level_ids.assign(levels.keys())
	level_ids.sort_custom(func(left: String, right: String) -> bool:
		return int(levels[left]["order"]) < int(levels[right]["order"])
	)
	if level_ids.is_empty():
		return false

	var loaded_progress: Dictionary = repository.load_progress()
	if loaded_progress.get("ok", false):
		progress = loaded_progress["data"].duplicate(true)
	else:
		progress = repository.new_progress(level_ids[0])
	current_level_id = str(progress.get("currentLevelId", level_ids[0]))
	if not levels.has(current_level_id):
		current_level_id = level_ids[0]
		progress["currentLevelId"] = current_level_id
	tutorial_state = _read_tutorial_state()
	initialized = true
	return _load_active_level(current_level_id)


func start_level(level_id: String, resume: bool = true) -> bool:
	if not initialized and not initialize():
		return false
	if not levels.has(level_id):
		return false
	current_level_id = level_id
	progress["currentLevelId"] = level_id
	repository.save_progress(progress)
	return _load_active_level(level_id, resume)


func apply_action(action: Dictionary) -> void:
	if engine == null:
		return
	engine.session.apply_action(action)


func use_hint() -> Dictionary:
	if engine == null:
		return {"ok": false, "reason": "runtime is not ready"}
	var hint := HintEngine.new().get_hint(active_level, _hint_session_payload())
	if not hint.get("ok", false):
		return hint
	last_hint = hint.get("evidence", {}).duplicate(true)
	engine.session.apply_action({"type": "Hint", "result": "evidence"})
	return {
		"ok": true,
		"consumeHint": true,
		"evidence": last_hint.duplicate(true),
	}


func process_tutorial_action(action: Dictionary) -> Dictionary:
	var result: Dictionary = tutorial_controller.process_action(tutorial_state, action)
	tutorial_state = result.get("state", tutorial_state).duplicate(true)
	progress["tutorialState"] = tutorial_state.duplicate(true)
	repository.save_progress(progress)
	return result


func has_saved_session() -> bool:
	if engine == null or active_level.is_empty():
		return false
	return repository.load_session(current_level_id, repository.puzzle_hash(active_level)).get("ok", false)


func save_current_session() -> bool:
	if engine == null or active_level.is_empty():
		return false
	return repository.save_session(_session_snapshot())


func clear_saved_state() -> void:
	repository.clear_all()


func _load_active_level(level_id: String, resume: bool = true) -> bool:
	active_level = levels[level_id].duplicate(true)
	current_level_id = level_id
	engine = GestureEngine.new(active_level, contract)
	var restored := false
	if resume:
		var saved: Dictionary = repository.load_session(level_id, repository.puzzle_hash(active_level))
		if saved.get("ok", false) and int(saved["data"].get("hearts", 0)) > 0:
			engine.session.load_initial(_to_session_initial(saved["data"]))
			restored = true
	if not restored:
		engine.session.reset_attempt()
	if not engine.session.changed.is_connected(_on_session_changed):
		engine.session.changed.connect(_on_session_changed)
	level_ready.emit(level_id)
	return true


func _on_session_changed() -> void:
	if engine == null:
		return
	var snapshot := _session_snapshot()
	repository.save_session(snapshot)
	var events: Array = engine.session.events
	var latest := str(events[-1]) if not events.is_empty() else ""
	if latest == "LevelWon":
		_complete_level()
	elif latest == "LevelFailed":
		level_failed.emit(current_level_id)
	session_changed.emit(current_level_id, snapshot)


func _complete_level() -> void:
	var result := {
		"score": engine.session.scorecard(),
		"mistakes": engine.session.mistake_count,
		"hints": engine.session.hint_count,
		"elapsedMs": 0,
	}
	var completed: Dictionary = repository.complete_level(progress, current_level_id, result, level_ids)
	if not completed.get("ok", false):
		return
	progress = completed["data"].duplicate(true)
	progress["tutorialState"] = tutorial_state.duplicate(true)
	repository.save_progress(progress)
	repository.clear_session()
	var next_level := str(progress.get("currentLevelId", ""))
	level_won.emit(current_level_id, next_level)


func _session_snapshot() -> Dictionary:
	var size := int(active_level.get("size", 0))
	var cells: Array = []
	for row in range(size):
		for column in range(size):
			cells.append(engine.session.cell_state([row, column]))
	return {
		"sessionVersion": repository.SESSION_VERSION,
		"levelId": current_level_id,
		"puzzleHash": repository.puzzle_hash(active_level),
		"cells": cells,
		"hearts": engine.session.hearts,
		"mistakeCount": engine.session.mistake_count,
		"hintCount": engine.session.hint_count,
		"elapsedMs": 0,
	}


func _to_session_initial(saved: Dictionary) -> Dictionary:
	var size := int(active_level.get("size", 0))
	var cells: Dictionary = {}
	var saved_cells: Array = saved.get("cells", [])
	for index in range(mini(saved_cells.size(), size * size)):
		var value := str(saved_cells[index])
		if value != "empty":
			var row := index / size
			var column := index % size
			cells["%d,%d" % [row, column]] = value
	return {
		"cells": cells,
		"hearts": int(saved.get("hearts", 3)),
		"mistakeCount": int(saved.get("mistakeCount", 0)),
		"hintCount": int(saved.get("hintCount", 0)),
	}


func _hint_session_payload() -> Dictionary:
	return {
		"cells": engine.session.cells.duplicate(true),
		"hintCount": engine.session.hint_count,
	}


func _read_tutorial_state() -> Dictionary:
	var saved = progress.get("tutorialState", {})
	if typeof(saved) == TYPE_DICTIONARY and not saved.is_empty():
		return saved.duplicate(true)
	var highlight := [0, 0]
	var trace: Array = active_level.get("logicTrace", [])
	if not trace.is_empty() and typeof(trace[0]) == TYPE_DICTIONARY:
		var conclusion: Dictionary = trace[0].get("conclusion", {})
		highlight = [int(conclusion.get("r", 0)), int(conclusion.get("c", 0))]
	return tutorial_controller.new_state("L01", highlight)


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
