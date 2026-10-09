extends RefCounted

static var _heading: FontFile = null
static var _heading_regular: FontFile = null
static var _body: FontFile = null
static var _body_semibold: FontFile = null
static var _body_bold: FontFile = null
static var _cjk_fallback: FontFile = null

static func heading() -> FontFile:
	if _heading == null:
		_heading = _load_font("res://assets/fonts/BeVietnamPro-Bold.ttf")
		_apply_fallbacks(_heading)
	return _heading

static func heading_regular() -> FontFile:
	if _heading_regular == null:
		_heading_regular = _load_font("res://assets/fonts/BeVietnamPro-Regular.ttf")
		_apply_fallbacks(_heading_regular)
	return _heading_regular

static func body() -> FontFile:
	if _body == null:
		_body = _load_font("res://assets/fonts/Nunito-Regular.ttf")
		_apply_fallbacks(_body)
	return _body

static func body_semibold() -> FontFile:
	if _body_semibold == null:
		_body_semibold = _load_font("res://assets/fonts/Nunito-SemiBold.ttf")
		_apply_fallbacks(_body_semibold)
	return _body_semibold

static func body_bold() -> FontFile:
	if _body_bold == null:
		_body_bold = _load_font("res://assets/fonts/Nunito-Bold.ttf")
		_apply_fallbacks(_body_bold)
	return _body_bold

static func _get_cjk_fallback() -> FontFile:
	if _cjk_fallback == null:
		_cjk_fallback = _load_font("res://assets/fonts/NotoSansCJK-subset.ttf")
	return _cjk_fallback

static func _apply_fallbacks(font: FontFile) -> void:
	if font == null:
		return
	var cjk := _get_cjk_fallback()
	if cjk != null and not font.fallbacks.has(cjk):
		font.fallbacks.append(cjk)

static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path):
		push_warning("FontTokens: missing font file %s" % path)
		return null
	return load(path) as FontFile
