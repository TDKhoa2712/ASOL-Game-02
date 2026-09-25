extends SceneTree

const Runtime = preload("res://scripts/mvp_runtime.gd")
const BootstrapScene = preload("res://scenes/bootstrap.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _safe_tutorial_mistake()
	var profile := OS.get_user_data_dir().path_join("r1_tutorial_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var bootstrap = BootstrapScene.instantiate()
	bootstrap.runtime = Runtime.new(profile)
	root.add_child(bootstrap)
	await process_frame
	bootstrap.get_node("ScreenHost/Home/SafeArea/Content/Stack/PlayButton").pressed.emit()
	await process_frame
	var board_screen = bootstrap.get_node("ScreenHost").get_child(0)
	var tutorial_label = board_screen.find_child("TutorialLabel", true, false)
	var board_view = board_screen.find_child("BoardView", true, false)
	_check(tutorial_label != null and tutorial_label.text.contains("(2,2)"), "T1 names the elimination cell without a glow")
	_check(not _has_property(board_view, "tutorial_highlight"), "board has no tutorial highlight renderer")
	bootstrap.runtime.apply_action({"type": "MarkX", "cell": [1, 1]})
	_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T1"), "real MarkX records T1 in progress")
	_check(tutorial_label.text.contains("(2,2)"), "T2 names the same elimination cell")
	var persisted_tutorial: Dictionary = bootstrap.runtime.repository.load_progress().get("data", {}).get("tutorialState", {})
	_check(not persisted_tutorial.has("tutorialCatCell"), "derived cat target is not added to saved progress schema")
	bootstrap.runtime.apply_action({"type": "ClearX", "cell": [1, 1]})
	_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T2"), "real ClearX records T2")
	bootstrap.runtime.apply_action({"type": "MarkStroke", "mode": "mark", "cells": [[1, 0], [1, 2]]})
	_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T3"), "real two-cell stroke records T3")
	_check(tutorial_label.text.contains("(4,3)"), "T4 names the derived cat cell")
	bootstrap.runtime.apply_action({"type": "TryCat", "cell": [3, 2]})
	_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T4"), "correct S2 cat records T4")
	bootstrap.runtime.apply_action({"type": "TryCat", "cell": [0, 0]})
	_check(bootstrap.runtime.engine.session.hearts == 2, "old tutorial cell is no longer exempt after highlight moves")
	board_screen = bootstrap.get_node("ScreenHost").get_child(0)
	var help_button = board_screen.find_child("HelpButton", true, false)
	_check(help_button != null, "puzzle exposes Help")
	if help_button != null:
		help_button.pressed.emit()
		await process_frame
		_check(bootstrap.flow.current_screen == "help", "puzzle Help opens rules")
		_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T5"), "viewing rules records T5")
		bootstrap._on_action("back")
		await process_frame
	board_screen = bootstrap.get_node("ScreenHost").get_child(0)
	var hint_button = board_screen.find_child("HintButton", true, false)
	_check(hint_button != null, "puzzle exposes Hint")
	if hint_button != null:
		hint_button.pressed.emit()
		await process_frame
		_check(not bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T6"), "opening Hint does not finish T6")
		var close_hint = board_screen.find_child("CloseHintButton", true, false)
		_check(close_hint != null and close_hint.visible, "valid Hint exposes explanation close action")
		var mid_hint = Runtime.new(profile)
		mid_hint.initialize()
		_check(mid_hint.engine.session.hint_count == 1, "Hint remains consumed after reload before closing explanation")
		_check(mid_hint.tutorial_controller.current_step(mid_hint.tutorial_state) == "T6", "reload before closing explanation resumes T6")
		if close_hint != null:
			close_hint.pressed.emit()
			await process_frame
			_check(bootstrap.runtime.progress.get("tutorialState", {}).get("tutorialSeenIds", []).has("T6"), "closing valid Hint records T6")
	var resumed = Runtime.new(profile)
	resumed.initialize()
	_check(resumed.tutorial_state.get("tutorialSeenIds", []).has("T1"), "tutorial T1 survives reload")
	var runtime = bootstrap.runtime
	bootstrap.free()
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)
	if failures.is_empty():
		print("R1_TUTORIAL_INTEGRATION_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _safe_tutorial_mistake() -> void:
	var profile := OS.get_user_data_dir().path_join("r1_tutorial_safe_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	var runtime = Runtime.new(profile)
	runtime.initialize()
	runtime.apply_action({"type": "TryCat", "cell": [1, 1]})
	_check(runtime.engine.session.hearts == 3, "wrong cat on the named tutorial cell keeps three hearts")
	_check(runtime.engine.session.cell_state([1, 1]) == "empty", "named tutorial cell stays editable")
	runtime.apply_action({"type": "TryCat", "cell": [0, 0]})
	_check(runtime.engine.session.hearts == 2, "wrong cat outside the named tutorial cell costs one heart")
	runtime.clear_saved_state()
	DirAccess.remove_absolute(profile)
