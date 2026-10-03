extends SceneTree

const TouchDecoder = preload("res://scripts/input/touch_decoder.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_single_tap()
	_test_double_tap()
	_test_double_tap_no_preview_leak()
	_test_distinct_taps_without_wait()
	_test_swipe()
	_test_swipe_interpolation()
	_test_cancel()
	_test_live_preview()
	_test_second_touch_drag()
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
	_assert(taps.is_empty(), "tap waits while a double tap remains possible")
	d.tick(1351)
	_assert(taps == [[1, 2]], "single tap commits after window")

func _test_double_tap() -> void:
	var d := TouchDecoder.new()
	var dtaps: Array = []
	var taps: Array = []
	d.cell_double_tapped.connect(func(r, c): dtaps.append([r, c]))
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1000)
	_assert(taps.is_empty(), "first tap stays uncommitted")
	d.begin(1, 2, 1200)  # within 350ms window
	_assert(dtaps.is_empty(), "second touch can still become a drag")
	d.finish(1230)
	_assert(dtaps.size() == 1, "double tap emitted on release")
	d.tick(1600)
	_assert(taps.is_empty(), "double tap never commits a mark")

func _test_double_tap_no_preview_leak() -> void:
	var d := TouchDecoder.new()
	var previews: Array = []
	d.preview_changed.connect(func(cells): previews.append(cells.duplicate(true)))
	d.begin(2, 3, 1000)
	_assert(previews.back() == [[2, 3]], "first touch shows preview")
	d.finish(1010)
	_assert(previews.back().is_empty(), "preview cleared while waiting for double tap")
	d.begin(2, 3, 1200)
	d.finish(1220)
	_assert(previews.back().is_empty(), "preview stays clear after double tap completes")

func _test_distinct_taps_without_wait() -> void:
	var d := TouchDecoder.new()
	var taps: Array = []
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.begin(1, 2, 1000)
	d.finish(1010)
	d.begin(1, 3, 1100)
	d.finish(1110)
	_assert(taps == [[1, 2]], "different cell commits previous tap immediately")
	d.tick(1461)
	_assert(taps == [[1, 2], [1, 3]], "new tap commits after window")

func _test_live_preview() -> void:
	var d := TouchDecoder.new()
	var previews: Array = []
	d.preview_changed.connect(func(cells): previews.append(cells.duplicate(true)))
	d.begin(0, 0, 1000)
	_assert(previews.back() == [[0, 0]], "touch shows first cell immediately")
	d.move(0, 2)
	_assert(previews.back() == [[0, 0], [0, 1], [0, 2]], "drag previews its path")
	d.finish(1100)
	_assert(previews.back().is_empty(), "committed swipe clears preview")

func _test_second_touch_drag() -> void:
	var d := TouchDecoder.new()
	var taps: Array = []
	var swipes: Array = []
	var doubles: Array = []
	d.cell_tapped.connect(func(r, c): taps.append([r, c]))
	d.cell_swiped.connect(func(cells): swipes.append(cells))
	d.cell_double_tapped.connect(func(r, c): doubles.append([r, c]))
	d.begin(0, 0, 1000)
	d.finish(1010)
	d.begin(0, 0, 1100)
	d.move(0, 2)
	d.finish(1200)
	_assert(taps == [[0, 0]], "second drag commits first tap")
	_assert(swipes == [[[0, 0], [0, 1], [0, 2]]], "second drag emits stroke")
	_assert(doubles.is_empty(), "second drag is not a double tap")

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
