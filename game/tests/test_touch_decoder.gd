extends SceneTree

const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_single_tap()
	_test_double_tap()
	_test_distinct_taps_without_wait()
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
	_assert(taps.size() == 1, "single tap emitted on release")
	_assert(taps.size() == 1 and taps[0] == [1, 2], "correct cell")
	d.tick(1500)
	_assert(taps.size() == 1, "single tap not repeated after double-tap window")

func _test_double_tap() -> void:
	var d := TouchDecoder.new()
	var dtaps: Array = []
	var taps: Array = []
	d.cell_double_tapped.connect(func(r, c): dtaps.append([r, c]))
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1000)
	_assert(taps.size() == 1, "first tap responds immediately")
	d.begin(1, 2, 1200)  # within 350ms window
	_assert(dtaps.size() == 1, "double tap emitted")
	d.finish(1230)
	d.tick(1600)
	_assert(taps.size() == 1, "double tap release does not toggle mark again")

func _test_distinct_taps_without_wait() -> void:
	var d := TouchDecoder.new()
	var taps: Array = []
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1010)
	d.begin(1, 3, 1100)
	d.finish(1110)
	_assert(taps == [[1, 2], [1, 3]], "different cells respond on each release")

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
