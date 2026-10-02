extends SceneTree

const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_single_tap()
	_test_double_tap()
	_test_swipe()
	_test_swipe_interpolation()
	_test_cancel()
	if _fails.is_empty():
		print("INPUT_TOUCH_DECODER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_single_tap() -> void:
	var d := TouchDecoder.new()
	var taps: Array = []
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1000)
	d.tick(1500)  # after double-tap window
	_assert(taps.size() == 1, "single tap emitted")
	_assert(taps[0] == [1, 2], "correct cell")

func _test_double_tap() -> void:
	var d := TouchDecoder.new()
	var dtaps: Array = []
	d.cell_double_tapped.connect(func(r, c): dtaps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1000)
	d.begin(1, 2, 1200)  # within 350ms window
	_assert(dtaps.size() == 1, "double tap emitted")

func _test_swipe() -> void:
	var d := TouchDecoder.new()
	var swipes: Array = []
	d.cell_swiped.connect(func(cells): swipes.append(cells))
	d.begin(0, 0, 1000)
	d.move(0, 1)
	d.move(0, 2)
	d.finish(1100)
	_assert(swipes.size() == 1, "swipe emitted")
	_assert(swipes[0].size() == 3, "3 cells in swipe")

func _test_swipe_interpolation() -> void:
	var d := TouchDecoder.new()
	# Test that interpolation fills gaps for diagonal movement
	var interp := d._interpolate_cells([0, 0], [2, 2])
	_assert(interp.size() >= 1, "interpolation fills gap")

func _test_cancel() -> void:
	var d := TouchDecoder.new()
	var taps: Array = []
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.cancel()
	d.tick(1500)
	_assert(taps.is_empty(), "cancel prevents emission")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
