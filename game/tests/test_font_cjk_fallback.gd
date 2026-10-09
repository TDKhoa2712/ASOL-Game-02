extends SceneTree

const FontTokens = preload("res://scripts/theme/font_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_heading_has_cjk_fallback()
	_test_body_has_cjk_fallback()
	_test_cjk_characters_supported()
	_test_string_size_positive()

	if _fails.is_empty():
		print("FONT_CJK_FALLBACK_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _test_heading_has_cjk_fallback() -> void:
	var f := FontTokens.heading()
	_assert(f != null, "heading font must not be null")
	_assert(not f.fallbacks.is_empty(), "heading font must have fallbacks configured")

func _test_body_has_cjk_fallback() -> void:
	var f := FontTokens.body()
	_assert(f != null, "body font must not be null")
	_assert(not f.fallbacks.is_empty(), "body font must have fallbacks configured")

func _test_cjk_characters_supported() -> void:
	var f := FontTokens.body()
	if f == null or f.fallbacks.is_empty():
		return
	var cjk_font: Font = f.fallbacks[0]
	var test_chars := ["あ", "い", "日", "本", "語", "한", "글", "게", "임"]
	for ch in test_chars:
		var code: int = ch.unicode_at(0)
		_assert(cjk_font.has_char(code), "CJK font must support character '%s' (U+%04X)" % [ch, code])

func _test_string_size_positive() -> void:
	var f := FontTokens.body()
	if f == null:
		return
	var ja_size := f.get_string_size("レベル 5", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	_assert(ja_size.x > 0 and ja_size.y > 0, "Japanese string size should be positive, got %s" % str(ja_size))
	var ko_size := f.get_string_size("레벨 5", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	_assert(ko_size.x > 0 and ko_size.y > 0, "Korean string size should be positive, got %s" % str(ko_size))
