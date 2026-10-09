# game/tests/test_mascot_motion.gd
extends SceneTree

const MascotMotion = preload("res://scripts/screens/mascot_motion.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_unknown_is_identity()
	_test_appear_grows_and_settles()
	_test_win_jumps_and_lands()
	_test_error_shakes_then_settles()
	_test_sad_loops_seamlessly()
	_test_continuous()
	if _fails.is_empty():
		print("MASCOT_MOTION_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _near(a: float, b: float, eps := 0.02) -> bool:
	return absf(a - b) <= eps

func _same(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if not _near(a[k], b[k]): return false
	return true

func _test_unknown_is_identity() -> void:
	_assert(_same(MascotMotion.sample("nope", 0.5), MascotMotion.IDENTITY), "unknown anim -> identity")
	_assert(_same(MascotMotion.sample("idle", 0.0), MascotMotion.IDENTITY), "idle starts at rest pose")

func _test_appear_grows_and_settles() -> void:
	_assert(MascotMotion.sample("appear", 0.0).sc < 0.3, "appear starts small")
	var end := MascotMotion.sample("appear", 1.0)
	_assert(_near(end.sc, 1.0) and _near(end.sy, 1.0) and _near(end.dy, 0.0), "appear ends at rest size")

func _test_win_jumps_and_lands() -> void:
	_assert(MascotMotion.sample("win", 0.5).dy < -30.0, "win jumps high at mid-air")
	_assert(_near(MascotMotion.sample("win", 1.0).dy, 0.0), "win lands")

func _test_error_shakes_then_settles() -> void:
	var peak := 0.0
	for i in 21: peak = maxf(peak, absf(MascotMotion.sample("error", i / 20.0).dx))
	_assert(peak > 8.0, "error shakes visibly (peak %.1f)" % peak)
	var end := MascotMotion.sample("error", 1.0)
	_assert(_near(end.dx, 0.0, 0.5) and _near(end.tint, 0.0), "error settles without tint")

func _test_sad_loops_seamlessly() -> void:
	_assert(_same(MascotMotion.sample("sad", 0.0), MascotMotion.sample("sad", 1.0)), "sad loop has no seam")

func _test_continuous() -> void:
	for anim in ["appear", "idle", "error", "sad", "win"]:
		var prev := MascotMotion.sample(anim, 0.0)
		for i in range(1, 201):
			var cur := MascotMotion.sample(anim, i / 200.0)
			if absf(cur.dx - prev.dx) > 1.5 or absf(cur.dy - prev.dy) > 1.5 or absf(cur.sy - prev.sy) > 0.25:
				_fails.append("FAIL: %s jumps at u=%.3f" % [anim, i / 200.0]); break
			prev = cur
