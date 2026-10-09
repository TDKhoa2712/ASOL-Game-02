extends SceneTree

const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_show_and_dismiss()
	_test_detail_visible_only_for_chain()
	_test_signals_emitted()
	_test_apply_label_varies()
	_test_formatted_text_with_params()
	if _fails.is_empty():
		print("HINT_OVERLAY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_show_and_dismiss() -> void:
	var overlay := HintOverlay.new()
	_assert(not overlay.is_showing(), "not showing initially")
	overlay.show_hint(_make_hint("WRONG_MARK", "CLEAR_MARK"))
	_assert(overlay.is_showing(), "showing after show_hint")
	overlay.dismiss()
	_assert(not overlay.is_showing(), "not showing after dismiss")
	overlay.free()

func _test_detail_visible_only_for_chain() -> void:
	var overlay := HintOverlay.new()
	overlay.show_hint(_make_hint("SINGLE_CANDIDATE", "PLACE_CANDY"))
	_assert(not overlay._detail_btn.visible, "detail hidden for single")
	overlay.dismiss()
	var chain_hint := _make_hint("CONTRA_CHAIN", "PLACE_MARKS")
	chain_hint["chain_detail"] = {"hypothesis_cell": [0, 0], "depth": 3, "steps": [], "contra_type": "row", "contra_index": 0}
	overlay.show_hint(chain_hint)
	_assert(overlay._detail_btn.visible, "detail visible for chain")
	overlay.free()

func _test_signals_emitted() -> void:
	var overlay := HintOverlay.new()
	var applied := [false]
	var dismissed := [false]
	overlay.hint_applied.connect(func(): applied[0] = true)
	overlay.hint_dismissed.connect(func(): dismissed[0] = true)
	overlay.show_hint(_make_hint("MARK_NEIGHBORS", "PLACE_MARKS"))
	overlay._on_apply()
	_assert(applied[0], "hint_applied emitted")
	overlay.show_hint(_make_hint("MARK_NEIGHBORS", "PLACE_MARKS"))
	overlay._on_dismiss()
	_assert(dismissed[0], "hint_dismissed emitted")
	overlay.free()

func _test_apply_label_varies() -> void:
	var overlay := HintOverlay.new()
	overlay.show_hint(_make_hint("WRONG_MARK", "CLEAR_MARK"))
	_assert(overlay._apply_btn.text != "", "apply has text for wrong mark")
	overlay.dismiss()
	overlay.show_hint(_make_hint("SINGLE_CANDIDATE", "PLACE_CANDY"))
	_assert(overlay._apply_btn.text != "", "apply has text for single")
	overlay.free()

func _test_formatted_text_with_params() -> void:
	var overlay := HintOverlay.new()
	var hint := _make_hint("SINGLE_CANDIDATE", "PLACE_CANDY")
	hint["explanation_key"] = "hint.single_row"
	hint["explanation_params"] = [3]
	overlay.show_hint(hint)
	_assert("3" in overlay._label_text.text, "params formatted into explanation: " + overlay._label_text.text)
	overlay.free()

func _make_hint(strategy: String, action: String) -> Dictionary:
	return {
		"found": true, "strategy": strategy, "action": action,
		"target_cell": [0, 0], "highlight_cells": [[0, 0]],
		"eliminated_cells": [], "explanation_key": "hint.wrong_mark",
		"explanation_params": [], "unit_type": "", "unit_id": "",
	}

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
