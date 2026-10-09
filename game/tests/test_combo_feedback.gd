extends SceneTree

const ComboFeedback = preload("res://scripts/screens/combo_feedback.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

class FakeBoard extends Control:
	func get_cell_rect(row: int, col: int) -> Rect2:
		return Rect2(col * 100, row * 100, 100, 100)

class FakeSfx extends RefCounted:
	var played: Array = []
	func play(effect: int, _force: bool = false) -> void: played.append(effect)

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_streak_plays_voice_and_popup()
	_test_hint_candy_resets()
	_test_reset_restarts_at_one()
	_test_popup_clamped_to_board()
	if _fails.is_empty():
		print("COMBO_FEEDBACK_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _make() -> Array:
	var board := FakeBoard.new()
	board.size = Vector2(600, 600)
	root.add_child(board)
	var sfx := FakeSfx.new()
	var combo := ComboFeedback.new()
	combo.bind(board, sfx)
	return [combo, sfx, board]

func _test_streak_plays_voice_and_popup() -> void:
	var parts := _make(); var combo = parts[0]; var sfx = parts[1]
	_assert(combo.on_candy(2, 2, false) == 1, "first is level 1")
	_assert(combo.on_candy(3, 3, false) == 2, "second is level 2")
	_assert(sfx.played == [SfxCatalog.Effect.COMBO_1, SfxCatalog.Effect.COMBO_2], "voices replace CANDY_YES")
	_assert(combo.popup.is_showing() and combo.popup.current_level() == 2, "popup shows level 2")
	parts[2].queue_free()

func _test_hint_candy_resets() -> void:
	var parts := _make(); var combo = parts[0]; var sfx = parts[1]
	combo.on_candy(1, 1, false)
	combo.popup.hide_combo()
	_assert(combo.on_candy(2, 2, true) == 0, "hint candy is not a combo")
	_assert(sfx.played.back() == SfxCatalog.Effect.CANDY_YES, "hint candy keeps CANDY_YES")
	_assert(not combo.popup.is_showing(), "no popup for hint candy")
	_assert(combo.on_candy(3, 3, false) == 1, "streak restarted after hint")
	parts[2].queue_free()

func _test_reset_restarts_at_one() -> void:
	var parts := _make(); var combo = parts[0]
	combo.on_candy(0, 1, false); combo.on_candy(1, 3, false)
	combo.reset()
	_assert(not combo.popup.is_showing(), "reset hides popup")
	_assert(combo.on_candy(2, 0, false) == 1, "after reset back to NICE")
	parts[2].queue_free()

func _test_popup_clamped_to_board() -> void:
	var parts := _make(); var combo = parts[0]
	combo.on_candy(0, 5, false)
	var half: Vector2 = combo.popup.sprite().region_rect.size * combo.popup.sprite().scale * 0.5
	_assert(combo.popup.position.x + half.x <= 600.0 + 0.01, "right edge inside board")
	_assert(combo.popup.position.y - half.y >= -0.01, "top edge inside board")
	combo.on_candy(0, 0, false)
	_assert(combo.popup.position.x - half.x >= -0.01, "left edge inside board")
	parts[2].queue_free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
