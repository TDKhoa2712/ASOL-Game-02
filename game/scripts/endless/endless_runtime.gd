# endless_runtime.gd
class_name EndlessRuntime
extends RefCounted

const LevelSelectorClass = preload("res://scripts/endless/level_selector.gd")
const EndlessConfigClass = preload("res://scripts/endless/endless_config.gd")
const EndlessProgressClass = preload("res://scripts/endless/endless_progress.gd")
const ProgressManagerClass = preload("res://scripts/state/progress_manager.gd")
const SessionStoreClass = preload("res://scripts/state/session_store.gd")
const BankReaderClass = preload("res://scripts/content/bank_reader.gd")
const PlaySessionClass = preload("res://scripts/input/play_session.gd")

signal level_started(level_id: String)
signal level_won(level_id: String, next_id: String)
signal level_lost(level_id: String)
signal save_failed(reason: String)

var bank: BankReaderClass
var progress_manager: ProgressManagerClass
var sessions: SessionStoreClass
var config: RefCounted
var progress: EndlessProgressClass
var selector: RefCounted

var current_session: PlaySessionClass = null
var _current_level_data: Dictionary = {}

func _init(bank_reader: BankReaderClass, pm: ProgressManagerClass, session_store: SessionStoreClass, cfg: RefCounted = null) -> void:
	bank = bank_reader
	progress_manager = pm
	sessions = session_store
	if cfg != null:
		config = cfg
	else:
		config = EndlessConfigClass.default_config()

	progress = EndlessProgressClass.new()
	if progress_manager != null:
		var saved_endless: Dictionary = progress_manager.get_endless_data()
		if not saved_endless.is_empty():
			progress.from_dict(saved_endless)

	selector = LevelSelectorClass.new(bank, config, progress)

func has_pending_session() -> bool:
	return sessions != null and sessions.has_pending()

func resume_level() -> PlaySessionClass:
	if sessions == null:
		return null
	var label := current_level_label()
	if _current_level_data.is_empty():
		return null
	var hash_val: String = str(_current_level_data.get("hash", ""))
	var saved := sessions.load_session(label, hash_val)
	if not saved.ok:
		return null
	current_session = PlaySessionClass.from_save_data(saved.data, _current_level_data)
	return current_session

func start_level(level_arg: Variant = null) -> PlaySessionClass:
	if level_arg is int and level_arg > 0 and level_arg != progress.get_level_num():
		progress.set_level_num(level_arg)
	elif level_arg is String and level_arg.begins_with("Endless "):
		var parsed_num: int = level_arg.trim_prefix("Endless ").to_int()
		if parsed_num > 0 and parsed_num != progress.get_level_num():
			progress.set_level_num(parsed_num)

	var level: Dictionary = selector.select_next_level()
	if level.is_empty():
		return null

	var label := current_level_label()
	level["id"] = label
	level["hash"] = progress_manager.puzzle_fingerprint(level) if progress_manager != null else str(level.hash)
	_current_level_data = level.duplicate(true)

	var session := PlaySessionClass.new(level)
	if sessions != null:
		var save_data := session.to_save_data()
		if not sessions.save_session(save_data):
			save_failed.emit("session_start")
			return null

	current_session = session
	level_started.emit(label)
	return session

func current_level_label() -> String:
	return "Endless %d" % progress.get_level_num()

func current_level_data() -> Dictionary:
	return _current_level_data

func current_pace() -> Dictionary:
	var sz: int = int(_current_level_data.get("size", 4))
	return {"hintCosts": [1, 2, 3] if sz >= 7 else [1, 2]}

func on_level_won(label: String, score_data: Dictionary) -> void:
	if current_session == null or current_session.phase != PlaySessionClass.Phase.WON:
		return

	var time_spent_s: float = float(score_data.get("time_ms", 0)) / 1000.0
	var sz: int = int(_current_level_data.get("size", 4))

	var result := {
		"won": true,
		"time": time_spent_s,
		"size": sz,
		"hints_used": int(score_data.get("hints_used", 0)),
		"mistakes": int(score_data.get("mistakes", 0)),
	}
	selector.on_level_complete(result)
	_persist_progress()

	if sessions != null:
		sessions.clear()

	current_session = null
	var next_label := current_level_label()
	level_won.emit(label, next_label)

func on_level_lost(label: String) -> void:
	if current_session == null:
		return

	var result := {
		"won": false,
		"time": float(current_session.elapsed_ms) / 1000.0,
		"hints_used": current_session.hints_used,
		"mistakes": current_session.mistake_count,
		"size": int(_current_level_data.get("size", 4)),
	}
	selector.on_level_complete(result)
	_persist_progress()

	if sessions != null:
		var saved := current_session.to_save_data()
		saved.status = "failed"
		sessions.save_session(saved)

	level_lost.emit(label)

func restart_level() -> PlaySessionClass:
	if _current_level_data.is_empty():
		return start_level()
	var session := PlaySessionClass.new(_current_level_data)
	if sessions != null:
		sessions.save_session(session.to_save_data())
	current_session = session
	level_started.emit(current_level_label())
	return session

func _persist_progress() -> void:
	if progress_manager != null and progress != null:
		progress_manager.set_endless_data(progress.to_dict())
		if not progress_manager.save():
			save_failed.emit("progress_save")
