extends RefCounted

const BankReader = preload("res://scripts/content/bank_reader.gd")
const PaceReader = preload("res://scripts/content/pace_reader.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")
const ProgressManager = preload("res://scripts/state/progress_manager.gd")
const SessionStore = preload("res://scripts/state/session_store.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const PaceAdjuster = preload("res://scripts/campaign/pace_adjuster.gd")
const SnapshotBuilder = preload("res://scripts/campaign/snapshot_builder.gd")

const PLAYLIST_PATH := "res://data/campaigns/demo_30.json"
const CAMPAIGN_VERSION := 1

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
var _playlist: Array = []
var _pending_win: Dictionary = {}
var _current_snapshot: Dictionary = {}
var pace_adjuster: PaceAdjuster = PaceAdjuster.new()

func _init(bank_reader: BankReader, pace_reader: PaceReader, progress_manager: ProgressManager, session_store: SessionStore) -> void:
	bank = bank_reader
	pace = pace_reader
	progress = progress_manager
	sessions = session_store

func boot() -> Dictionary:
	var loaded := _load_playlist(PLAYLIST_PATH)
	if not loaded.ok:
		return _boot_error(loaded.error)
	_playlist = loaded.playlist
	var sizes: Dictionary = {}
	for entry in _playlist:
		sizes[entry.size] = true
	for size in sizes:
		var bank_result := bank.load_bank(size)
		if not bank_result.ok:
			return _boot_error("bank: " + str(bank_result.errors))
		var pace_result := pace.load_pace(size)
		if not pace_result.ok:
			return _boot_error("pace: " + str(pace_result.errors))
		var errors := pace.validate_against_bank(bank, size)
		if not errors.is_empty():
			return _boot_error("pace mismatch: " + str(errors))
	for entry in _playlist:
		if bank.get_level(entry.size, entry.rank, entry.index).is_empty() or pace.get_pace(entry.size, entry.rank, entry.index).is_empty():
			return _boot_error("missing content for " + entry.label)
	var progress_result := progress.load()
	if not progress_result.ok:
		if progress_result.reason != "missing_or_invalid":
			return _boot_error("progress: " + progress_result.reason)
		progress.current = progress.new_progress(_playlist[0].label)
		if not progress.save():
			save_failed.emit("initial_progress")
			return _boot_error("cannot save progress")
	if progress.current.get("dda") is Dictionary: pace_adjuster.from_dict(progress.current.dda)
	if not playlist_order().has(progress.current.currentLevelId):
		return _boot_error("progress level outside playlist")
	if sessions.has_pending():
		resume_level()
	return {"ok": true, "level": current_level_data(), "pace_entry": current_pace(), "error": ""}

func start_level(label: String) -> PlaySession:
	if label != current_level_label() or is_campaign_done():
		return null
	pace_adjuster.on_level_start()
	var level := current_level_data()
	if level.is_empty():
		return null
	var snapshot: Dictionary
	if not _current_snapshot.is_empty() and _current_snapshot.get("level_id") == label:
		snapshot = _current_snapshot
		var restored := SnapshotBuilder.restore_level(snapshot)
		restored["hash"] = level.hash
		level = restored
	else:
		snapshot = SnapshotBuilder.build(label, level, _resolve_playlist_entry(label), Palette.ZONE_COLORS)
	_current_snapshot = snapshot
	var session := PlaySession.new(level)
	var save_data := session.to_save_data()
	save_data["snapshot"] = snapshot.duplicate(true)
	if not sessions.save_session(save_data):
		save_failed.emit("session_start")
		return null
	current_session = session
	level_started.emit(label)
	return session

func resume_level() -> PlaySession:
	var level := current_level_data()
	if level.is_empty():
		return null
	var saved := sessions.load_session(current_level_label(), level.hash)
	if not saved.ok:
		if saved.recreate:
			sessions.clear()
		return null
	if saved.data.has("snapshot") and saved.data.snapshot is Dictionary:
		_current_snapshot = saved.data.snapshot.duplicate(true)
	current_session = PlaySession.from_save_data(saved.data, level)
	if saved.data.get("status") == "won" and saved.data.get("pendingScoreData") is Dictionary:
		_pending_win = {"label": current_level_label(), "score": saved.data.pendingScoreData.duplicate(true)}
	return current_session

func on_level_won(label: String, score_data: Dictionary) -> void:
	if label != current_level_label() or is_campaign_done() or current_session == null or current_session.phase != PlaySession.Phase.WON:
		return
	_pending_win = {"label": label, "score": score_data.duplicate(true)}
	var win_snapshot := current_session.to_save_data()
	win_snapshot["pendingScoreData"] = score_data.duplicate(true)
	if not _current_snapshot.is_empty():
		win_snapshot["snapshot"] = _current_snapshot.duplicate(true)
	if not sessions.save_session(win_snapshot):
		save_failed.emit("session_win")
		return
	var advanced := progress.advance_level(label, score_data, playlist_order())
	if not advanced.ok:
		save_failed.emit(str(advanced.reason))
		return
	if _current_snapshot.has("shape_hash"):
		progress.record_shape(_current_snapshot.shape_hash)
	pace_adjuster.apply_result(true, score_data, progress.current)
	progress.save()
	_pending_win.clear()
	current_session = null
	_current_snapshot = {}
	sessions.clear()
	var next := next_level_label(label)
	level_won.emit(label, next)
	if next.is_empty():
		campaign_complete.emit()

func on_level_lost(label: String) -> void:
	if label != current_level_label() or current_session == null:
		return
	var saved := current_session.to_save_data()
	saved.status = "failed"
	if not _current_snapshot.is_empty():
		saved["snapshot"] = _current_snapshot.duplicate(true)
	if not sessions.save_session(saved):
		save_failed.emit("session_failed")
		return
	level_lost.emit(label)
	pace_adjuster.apply_result(false, {}, progress.current)
	progress.save()

func retry_save() -> bool:
	if _pending_win.is_empty():
		return false
	on_level_won(_pending_win.label, _pending_win.score)
	return _pending_win.is_empty()

func restart_level() -> PlaySession:
	return start_level(current_level_label())

func replay_campaign() -> void:
	if not is_campaign_done():
		return
	var previous := progress.current.duplicate(true)
	progress.current = progress.new_progress(_playlist[0].label)
	if not progress.save():
		progress.current = previous
		save_failed.emit("replay_progress")
		return
	current_session = null
	sessions.clear()

func current_level_label() -> String:
	return str(progress.current.get("currentLevelId", ""))

func current_level_data() -> Dictionary:
	var entry := _resolve_playlist_entry(current_level_label())
	if entry.is_empty():
		return {}
	var level := _fetch_level(entry.size, entry.rank, entry.index, int(entry.get("transform", 0)))
	if level.is_empty():
		return {}
	level.id = current_level_label()
	level.hash = progress.puzzle_fingerprint(level)
	return level

func current_pace() -> Dictionary:
	var entry := _resolve_playlist_entry(current_level_label())
	if entry.is_empty():
		return {}
	return pace.get_pace(entry.size, entry.rank, entry.index).duplicate(true)

func next_level_label(after: String) -> String:
	var order := playlist_order()
	var index := order.find(after)
	return order[index + 1] if index >= 0 and index + 1 < order.size() else ""

func is_campaign_done() -> bool:
	return not _playlist.is_empty() and completed_count() == _playlist.size()

func has_pending_session() -> bool:
	return sessions.has_pending()

func playlist_order() -> Array[String]:
	var order: Array[String] = []
	for entry in _playlist:
		order.append(entry.label)
	return order

func completed_count() -> int:
	var count := 0
	for label in playlist_order():
		if progress.current.get("completedLevelIds", []).has(label):
			count += 1
	return count

func advance(score_data: Dictionary) -> Dictionary:
	var before := current_level_label()
	on_level_won(before, score_data)
	return {"ok": progress.current.get("completedLevelIds", []).has(before), "next_level": current_level_data() if not is_campaign_done() else {}, "campaign_complete": is_campaign_done()}

func _resolve_playlist_entry(label: String) -> Dictionary:
	for entry in _playlist:
		if entry.label == label:
			return entry
	return {}

func _fetch_level(size: int, rank: int, index: int, transform: int = 0) -> Dictionary:
	var level := bank.get_level(size, rank, index)
	if level.is_empty():
		return {}
	return BoardTransform.apply(level, transform) if transform > 0 else level.duplicate(true)

func _load_playlist(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "playlist missing"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("campaignVersion") != CAMPAIGN_VERSION or not parsed.get("playlist") is Array:
		return {"ok": false, "error": "invalid playlist"}
	var entries: Array = parsed.playlist
	if entries.is_empty():
		return {"ok": false, "error": "empty playlist"}
	var labels: Dictionary = {}
	for entry in entries:
		if not entry is Dictionary or not entry.get("label") is String or str(entry.label).is_empty() or labels.has(entry.label):
			return {"ok": false, "error": "invalid playlist label"}
		for field in ["size", "rank", "index"]:
			var value: Variant = entry.get(field)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)):
				return {"ok": false, "error": "invalid playlist reference"}
		if entry.size < 4 or entry.size > 6 or entry.rank < 1 or entry.index < 0:
			return {"ok": false, "error": "playlist reference out of range"}
		if not entry.get("difficulty") is String:
			return {"ok": false, "error": "missing difficulty"}
		labels[entry.label] = true
	return {"ok": true, "playlist": entries}

func _boot_error(message: String) -> Dictionary:
	return {"ok": false, "level": {}, "pace_entry": {}, "error": message}
