extends RefCounted

static var _heading: FontFile = null
static var _heading_regular: FontFile = null
static var _body: FontFile = null
static var _body_semibold: FontFile = null
static var _body_bold: FontFile = null

static func heading() -> FontFile:
	if _heading == null:
		_heading = _load_font("res://assets/fonts/Baloo2-Bold.ttf")
	return _heading

static func heading_regular() -> FontFile:
	if _heading_regular == null:
		_heading_regular = _load_font("res://assets/fonts/Baloo2-Regular.ttf")
	return _heading_regular

static func body() -> FontFile:
	if _body == null:
		_body = _load_font("res://assets/fonts/Nunito-Regular.ttf")
	return _body

static func body_semibold() -> FontFile:
	if _body_semibold == null:
		_body_semibold = _load_font("res://assets/fonts/Nunito-SemiBold.ttf")
	return _body_semibold

static func body_bold() -> FontFile:
	if _body_bold == null:
		_body_bold = _load_font("res://assets/fonts/Nunito-Bold.ttf")
	return _body_bold

static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path):
		push_warning("FontTokens: missing font file %s" % path)
		return null
	return load(path) as FontFile
