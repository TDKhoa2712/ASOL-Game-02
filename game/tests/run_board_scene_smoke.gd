extends SceneTree


const BOARD_SCENE_PATH := "res://scenes/board.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	if not ResourceLoader.exists(BOARD_SCENE_PATH):
		_fail("Board scene is missing: %s" % BOARD_SCENE_PATH)
		return

	var packed_scene = load(BOARD_SCENE_PATH)
	var screen = packed_scene.instantiate()
	root.size = Vector2i(1080, 1920)
	root.add_child(screen)
	await process_frame

	_expect(screen.name == "BoardScreen", "Root must be BoardScreen", failures)
	_expect(
		ProjectSettings.get_setting("display/window/size/viewport_width") == 1080,
		"Logical viewport width must stay portrait",
		failures
	)
	_expect(
		ProjectSettings.get_setting("display/window/size/viewport_height") == 1920,
		"Logical viewport height must stay portrait",
		failures
	)
	for node_name in [
		"HeartsLabel",
		"StatusLabel",
		"BoardView",
		"UndoButton",
		"RestartButton",
		"RestartDialog",
	]:
		_expect(
			screen.find_child(node_name, true, false) != null,
			"Missing UI node: %s" % node_name,
			failures
		)
	var hearts: Control = screen.find_child("HeartsLabel", true, false)
	var status: Control = screen.find_child("StatusLabel", true, false)
	var board_view: Control = screen.find_child("BoardView", true, false)
	var rules: Control = screen.find_child("RuleStrip", true, false)
	var regions: Control = screen.find_child("RegionProgress", true, false)
	_expect(rules != null and rules.get_child_count() == 4, "Four rule labels stay visible", failures)
	_expect(regions != null and regions.get_child_count() == int(screen.level["size"]), "Region progress has one slot per region", failures)
	_expect(hearts.get_global_rect().position.x >= 0.0, "Hearts label is clipped", failures)
	_expect(status.get_global_rect().end.x <= 1080.0, "Status label is clipped", failures)
	if rules != null and regions != null:
		_expect(rules.get_global_rect().end.y < board_view.get_global_rect().position.y, "Rules precede board", failures)
		_expect(regions.get_global_rect().position.y > board_view.get_global_rect().end.y, "Region progress follows board", failures)
		_expect(regions.get_global_rect().end.y <= 1920.0, "Region progress is visible", failures)
	for node_name in ["UndoButton", "HintButton", "RestartButton", "HomeButton", "HelpButton", "SettingsButton"]:
		var action: Control = screen.find_child(node_name, true, false)
		_expect(action.get_global_rect().end.y <= 1920.0, "%s is not clipped below screen" % node_name, failures)
		_expect(action.get_global_rect().size.y >= 44.0, "%s has minimum vertical touch target" % node_name, failures)
	_expect(board_view.get_global_rect().size.x / float(screen.level["size"]) >= 44.0, "Board cell reaches minimum touch target", failures)

	var session = screen.get_session()
	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), true))
	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), false))
	board_view.engine.flush_pending()
	_expect(
		session.public_state()["cells"].get("0,0") == "x",
		"Mouse tap must route through BoardView",
		failures
	)
	screen.undo_last_x()
	_expect(
		session.public_state()["cells"].is_empty(),
		"Undo must restore the previous board state",
		failures
	)

	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), true))
	board_view._gui_input(_mouse_motion(Vector2(650.0, 100.0)))
	board_view._gui_input(_mouse_button(Vector2(650.0, 100.0), false))
	_expect(
		session.public_state()["cells"].size() == 4,
		"Mouse drag must route a four-cell stroke through BoardView",
		failures
	)
	screen.undo_last_x()

	board_view._gui_input(_mouse_button(Vector2(100.0, 300.0), true))
	board_view._gui_input(_mouse_button(Vector2(-20.0, 300.0), false))
	board_view.engine.flush_pending()
	_expect(
		session.public_state()["cells"].get("1,0") == "x",
		"Release outside board must finish the owned tap",
		failures
	)
	screen.undo_last_x()

	session.load_initial({"cells": {"0,0": "x_error"}, "hearts": 2, "mistakeCount": 1})
	board_view._gui_input(_touch(0, Vector2(100.0, 100.0), true))
	board_view._gui_input(_touch(1, Vector2(300.0, 100.0), true))
	board_view._gui_input(_touch(1, Vector2(300.0, 100.0), false))
	board_view._gui_input(_touch(0, Vector2(100.0, 100.0), false))
	_expect(
		session.public_state()["cells"] == {"0,0": "x_error"},
		"Locked primary touch must block a mutable secondary touch",
		failures
	)
	screen.confirm_restart()

	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), true))
	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), false))
	board_view._gui_input(_mouse_button(Vector2(100.0, 100.0), true))
	board_view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(
		session.public_state()["cells"].get("0,0") == "x"
		and not board_view.engine.pending_tap,
		"Focus loss must cancel active contact and commit the released tap",
		failures
	)
	screen.confirm_restart()

	session.apply_action({"type": "MarkX", "cell": [0, 0]})
	screen.request_restart()
	await process_frame
	var dialog = screen.find_child("RestartDialog", true, false)
	_expect(dialog.visible, "Restart must ask for confirmation", failures)
	screen.cancel_restart()
	_expect(
		session.public_state()["cells"].get("0,0") == "x",
		"Cancelling restart must preserve progress",
		failures
	)

	screen.request_restart()
	screen.confirm_restart()
	var restarted: Dictionary = session.public_state()
	_expect(restarted["cells"].is_empty(), "Restart must clear cells", failures)
	_expect(restarted["hearts"] == 3, "Restart must restore hearts", failures)

	screen.queue_free()
	await process_frame
	var campaign: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_m1.json"))
	for level_data in campaign.get("levels", []):
		var candidate = packed_scene.instantiate()
		candidate.configure(level_data)
		root.add_child(candidate)
		await process_frame
		var level_id: String = str(level_data.get("id", ""))
		var candidate_board: Control = candidate.find_child("BoardView", true, false)
		var candidate_regions: Control = candidate.find_child("RegionProgress", true, false)
		var candidate_settings: Control = candidate.find_child("SettingsButton", true, false)
		_expect(candidate_regions.get_child_count() == int(level_data["size"]), "%s region slots match size" % level_id, failures)
		_expect(candidate_board.get_global_rect().size.x / float(level_data["size"]) >= 44.0, "%s cells reach touch minimum" % level_id, failures)
		_expect(candidate_settings.get_global_rect().end.y <= 1920.0, "%s Settings remains visible" % level_id, failures)
		candidate.queue_free()
		await process_frame
	if failures.is_empty():
		print("M0_A02_BOARD_SCENE_PASS")
		quit(0)
	else:
		_fail("\n".join(failures))


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _mouse_button(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func _mouse_motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	return event


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
