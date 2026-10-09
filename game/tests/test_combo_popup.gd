extends SceneTree

const ComboPopup = preload("res://scripts/screens/combo_popup.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_frame_rects()
	_test_show_selects_word()
	_test_restart_mid_tween()
	_test_reduced_motion_no_pop()
	await _test_hides_after_animation()
	if _fails.is_empty():
		print("COMBO_POPUP_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _make() -> ComboPopup:
	var popup := ComboPopup.new()
	root.add_child(popup)
	return popup

func _test_frame_rects() -> void:
	_assert(ComboPopup.frame_rect(1) == Rect2(0, 0, 512, 128), "level 1 rect")
	_assert(ComboPopup.frame_rect(4) == Rect2(512, 128, 512, 128), "level 4 rect")
	_assert(ComboPopup.frame_rect(12) == Rect2(512, 640, 512, 128), "level 12 rect")
	_assert(ComboPopup.frame_rect(99) == ComboPopup.frame_rect(12), "rect clamps")

func _test_show_selects_word() -> void:
	var popup := _make()
	_assert(not popup.is_showing(), "hidden before first combo")
	popup.show_combo(3, Vector2(200, 100), 1.0)
	_assert(popup.is_showing(), "visible after show")
	_assert(popup.sprite().region_rect == ComboPopup.frame_rect(3), "shows level 3 word")
	_assert(popup.position == Vector2(200, 100), "placed at anchor")
	popup.queue_free()

func _test_restart_mid_tween() -> void:
	var popup := _make()
	var children := popup.get_child_count()
	popup.show_combo(1, Vector2.ZERO, 1.0)
	popup.show_combo(2, Vector2(10, 10), 1.0)
	_assert(popup.get_child_count() == children, "no extra nodes per combo")
	_assert(popup.current_level() == 2, "latest combo wins")
	_assert(popup.sprite().modulate.a == 1.0, "restart resets fade")
	popup.queue_free()

func _test_reduced_motion_no_pop() -> void:
	var popup := _make()
	LayoutTokens.set_motion(false)
	popup.show_combo(10, Vector2.ZERO, 0.8)
	_assert(popup.sprite().scale == Vector2.ONE * 0.8, "full scale immediately")
	_assert(popup.sprite().rotation == 0.0, "no tilt")
	LayoutTokens.set_motion(true)
	popup.queue_free()

func _test_hides_after_animation() -> void:
	var popup := _make()
	popup.show_combo(9, Vector2.ZERO, 1.0)
	var start := Time.get_ticks_msec()
	while popup.is_showing() and Time.get_ticks_msec() - start < 2000:
		await process_frame
	_assert(not popup.is_showing(), "hides after animation")
	popup.queue_free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
