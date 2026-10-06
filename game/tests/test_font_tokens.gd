extends SceneTree

const FontTokens = preload("res://scripts/theme/font_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_heading_loads()
	_test_heading_regular_loads()
	_test_body_loads()
	_test_body_semibold_loads()
	_test_body_bold_loads()
	_test_caching()
	_test_all_support_vietnamese()

	if _fails.is_empty():
		print("FONT_TOKENS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_heading_loads() -> void:
	var font := FontTokens.heading()
	if font == null:
		_fails.append("heading() returned null")
	elif not font is FontFile:
		_fails.append("heading() did not return FontFile")

func _test_heading_regular_loads() -> void:
	var font := FontTokens.heading_regular()
	if font == null:
		_fails.append("heading_regular() returned null")

func _test_body_loads() -> void:
	var font := FontTokens.body()
	if font == null:
		_fails.append("body() returned null")

func _test_body_semibold_loads() -> void:
	var font := FontTokens.body_semibold()
	if font == null:
		_fails.append("body_semibold() returned null")

func _test_body_bold_loads() -> void:
	var font := FontTokens.body_bold()
	if font == null:
		_fails.append("body_bold() returned null")

func _test_caching() -> void:
	var a := FontTokens.heading()
	var b := FontTokens.heading()
	if a != b:
		_fails.append("heading() not cached — returned different instances")

func _test_all_support_vietnamese() -> void:
	var test_chars := "ĂẮẦẪƠỜƯỪỮỰàáảãạ"
	var fonts: Array[FontFile] = [
		FontTokens.heading(),
		FontTokens.heading_regular(),
		FontTokens.body(),
		FontTokens.body_semibold(),
		FontTokens.body_bold(),
	]
	var names: Array[String] = ["heading", "heading_regular", "body", "body_semibold", "body_bold"]
	for i in range(fonts.size()):
		var font: FontFile = fonts[i]
		if font == null:
			continue
		for ch in test_chars:
			if not font.has_char(ch.unicode_at(0)):
				_fails.append("%s() missing Vietnamese char U+%04X (%s)" % [names[i], ch.unicode_at(0), ch])
				break
