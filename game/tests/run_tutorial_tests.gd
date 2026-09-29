extends SceneTree

const Tutorial = preload("res://scripts/tutorial_controller.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("M1_A06_TUTORIAL_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var controller := Tutorial.new()
	var state := controller.new_state("L01", [0, 1])
	_check(controller.is_tutorial_level("L01"), "L01 enables tutorial")
	_check(not controller.is_tutorial_level("L02"), "L02 does not enable tutorial")
	_check(controller.current_step(state) == "T1", "fresh tutorial starts at T1")

	var t1 := controller.process_action(state, {"type": "MarkX", "cell": [0, 1]})
	state = t1["state"]
	_check(t1["completed"] == ["T1"], "MarkX completes T1")
	_check(controller.current_step(state) == "T2", "T2 follows T1")

	var t3 := controller.process_action(state, {"type": "MarkStroke", "cells": [[1, 0], [1, 1]]})
	state = t3["state"]
	_check(t3["completed"].has("T3"), "valid stroke completes T3 out of order")
	_check(controller.current_step(state) == "T2", "next step skips completed T3")

	var t2 := controller.process_action(state, {"type": "ClearX", "cell": [0, 1]})
	state = t2["state"]
	_check(t2["completed"].has("T2"), "ClearX completes T2")

	var safe_miss := controller.try_candy_policy("L01", [0, 1], [0, 1])
	_check(safe_miss["penalize"] == false, "tutorial target miss is safe")
	_check(safe_miss["tutorialMessage"] == true, "tutorial target miss explains mistake")
	var normal_miss := controller.try_candy_policy("L01", [1, 1], [0, 1])
	_check(normal_miss["penalize"] == true, "other tutorial cell uses normal penalty")
	_check(controller.try_candy_policy("L02", [0, 1], [0, 1])["penalize"], "later levels use normal penalty")

	state = controller.process_action(state, {"type": "TryCandy", "cell": [0, 1], "correct": true})["state"]
	state = controller.process_action(state, {"type": "ViewRules"})["state"]
	state = controller.process_action(state, {"type": "UseHint", "valid": true})["state"]
	_check(not controller.all_complete(state), "opening Hint alone does not finish T6")
	state = controller.process_action(state, {"type": "CloseHint", "valid": true})["state"]
	_check(controller.all_complete(state), "T1-T6 complete from persisted actions")
	_check(controller.current_step(state) == "", "completed tutorial has no next step")

	var resumed := controller.new_state("L01", [0, 1])
	resumed["tutorialSeenIds"] = state["tutorialSeenIds"].duplicate()
	_check(controller.all_complete(resumed), "reload preserves tutorial milestones")
	_check(controller.should_show("L01", resumed) == false, "completed tutorial does not show again")
	_check(controller.should_show("L02", {"tutorialSeenIds": []}) == false, "non tutorial level never shows tutorial")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append("FAIL: " + label)
