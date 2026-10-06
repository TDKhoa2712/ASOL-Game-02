extends SceneTree

const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const CandyPalette = preload("res://scripts/theme/candy_palette.gd")

var _fails: Array[String] = []

func _init() -> void:
	var expected := ["bonbon", "lollipop", "gummy_drop", "hard_candy", "toffee", "cotton_puff"]
	for index in range(30):
		var want: String = expected[index / 5]
		var label := "L%02d" % (index + 1)
		if CandyRenderer.type_for_level(index) != want or CandyRenderer.type_for_label(label) != want:
			_fails.append("wrong type for %s" % label)
	for label in ["", "L00", "L31", "bad"]:
		if CandyRenderer.type_for_label(label) != "bonbon":
			_fails.append("bad label fallback: %s" % label)
	for candy_type in CandyPalette.CANDY_TYPES:
		var texture := CandyRenderer.texture_for_type(candy_type)
		if texture == null or texture != CandyRenderer.texture_for_type(candy_type):
			_fails.append("load/cache failed: %s" % candy_type)
	if CandyRenderer.texture_for_type("unknown") != CandyRenderer.texture_for_type("bonbon"):
		_fails.append("unknown texture fallback failed")
	if _fails.is_empty():
		print("CANDY_RENDERER_PASS")
		quit(0)
	else:
		for failure in _fails:
			printerr(failure)
		quit(1)
