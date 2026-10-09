extends SceneTree

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_win_palette()
	_test_lose_palette()
	_test_home_palette()
	_test_animation_constants()
	if _fails.is_empty():
		print("WIDGETS_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_win_palette() -> void:
	_assert(typeof(Palette.WIN_BG_CENTER) == TYPE_COLOR, "WIN_BG_CENTER is Color")
	_assert(typeof(Palette.WIN_RIBBON_BG) == TYPE_COLOR, "WIN_RIBBON_BG is Color")
	_assert(typeof(Palette.WIN_BUTTON_BG) == TYPE_COLOR, "WIN_BUTTON_BG is Color")
	_assert(Palette.CONFETTI_COLORS.size() >= 6, "CONFETTI_COLORS has >= 6 entries")

func _test_lose_palette() -> void:
	_assert(typeof(Palette.LOSE_BG_CENTER) == TYPE_COLOR, "LOSE_BG_CENTER is Color")
	_assert(typeof(Palette.LOSE_RIBBON_BG) == TYPE_COLOR, "LOSE_RIBBON_BG is Color")
	_assert(typeof(Palette.LOSE_BUTTON_BG) == TYPE_COLOR, "LOSE_BUTTON_BG is Color")

func _test_home_palette() -> void:
	_assert(typeof(Palette.HOME_BG_CENTER) == TYPE_COLOR, "HOME_BG_CENTER is Color")
	_assert(typeof(Palette.HOME_BUTTON_BG) == TYPE_COLOR, "HOME_BUTTON_BG is Color")
	_assert(typeof(Palette.HOME_PROGRESS_FILL) == TYPE_COLOR, "HOME_PROGRESS_FILL is Color")

func _test_animation_constants() -> void:
	_assert(LayoutTokens.RIBBON_DROP_MS > 0, "RIBBON_DROP_MS > 0")
	_assert(LayoutTokens.HEART_POP_MS > 0, "HEART_POP_MS > 0")
	_assert(LayoutTokens.CONFETTI_FALL_MIN_MS > 0, "CONFETTI_FALL_MIN_MS > 0")
