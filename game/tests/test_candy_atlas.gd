# game/tests/test_candy_atlas.gd
extends SceneTree

const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_loads_real_atlas()
	_test_bad_json()
	if _fails.is_empty():
		print("CANDY_ATLAS_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_loads_real_atlas() -> void:
	CandyAtlas.reset()
	_assert(CandyAtlas.ensure_loaded(), "mascot atlas loads")
	var meta := CandyAtlas.meta()
	var expected := {"appear": 12, "idle": 18, "error": 16, "sad": 16, "win": 20}
	for anim in expected:
		_assert(meta.has(anim) and meta[anim].count == expected[anim], "anim %s has %d frames" % [anim, expected[anim]])
	var size := CandyAtlas.texture().get_size()
	for anim in expected:
		for i in expected[anim]:
			var r := CandyAtlas.frame_rect(anim, i)
			_assert(r.size == Vector2(128, 128) and r.end.x <= size.x and r.end.y <= size.y, "%s[%d] inside texture" % [anim, i])
	_assert(CandyAtlas.frame_rect("nope", 0) == Rect2(), "unknown anim -> empty rect")
	_assert(CandyAtlas.frame_rect("idle", 99) == Rect2(), "frame out of range -> empty rect")

func _test_bad_json() -> void:
	CandyAtlas.reset()
	_assert(not CandyAtlas.ensure_loaded("res://assets/candy/anim/mascot_atlas.png", "res://missing.json"), "missing json -> false")
	CandyAtlas.reset()
