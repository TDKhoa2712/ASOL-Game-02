extends SceneTree

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const HeartDisplay = preload("res://scripts/ui/heart_display.gd")
const RibbonBanner = preload("res://scripts/ui/ribbon_banner.gd")
const StatCard = preload("res://scripts/ui/stat_card.gd")
const ConfettiLayer = preload("res://scripts/ui/confetti_layer.gd")
const SunburstRays = preload("res://scripts/ui/sunburst_rays.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_win_palette()
	_test_lose_palette()
	_test_home_palette()
	_test_animation_constants()
	_test_gradient_bg()
	_test_action_button()
	_test_heart_display()
	_test_ribbon_banner()
	_test_stat_card()
	_test_confetti_layer()
	_test_sunburst_rays()
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

func _test_gradient_bg() -> void:
	var bg := GradientBg.new(Color.WHITE, Color.YELLOW, Color.ORANGE)
	_assert(bg is ColorRect, "gradient_bg is ColorRect")
	_assert(bg.material is ShaderMaterial, "gradient_bg has ShaderMaterial")
	bg.free()

func _test_action_button() -> void:
	var btn := ActionButton.create("Test", Color.GREEN, Color.DARK_GREEN, Color.BLACK, 36)
	_assert(btn is Button, "action_button is Button")
	_assert(btn.text == "Test", "action_button text matches")
	var style = btn.get_theme_stylebox("normal")
	_assert(style is StyleBoxFlat, "action_button has StyleBoxFlat")
	_assert((style as StyleBoxFlat).bg_color == Color.GREEN, "action_button bg_color matches")
	btn.free()

func _test_heart_display() -> void:
	var d1 := HeartDisplay.new(3, 3, "win")
	_assert(d1 is HBoxContainer, "heart_display is HBoxContainer")
	_assert(d1.get_child_count() == 3, "heart_display has 3 children (win/3)")
	d1.free()
	var d2 := HeartDisplay.new(3, 1, "win")
	_assert(d2.get_child_count() == 3, "heart_display has 3 children (win/1)")
	d2.free()
	var d3 := HeartDisplay.new(3, 0, "lose")
	_assert(d3.get_child_count() == 3, "heart_display has 3 children (lose/0)")
	d3.free()

func _test_ribbon_banner() -> void:
	var r1 := RibbonBanner.new("HOÀN THÀNH!", "win")
	_assert(r1 is Control, "ribbon_banner win is Control")
	r1.free()
	var r2 := RibbonBanner.new("HẾT TIM RỒI!", "lose")
	_assert(r2 is Control, "ribbon_banner lose is Control")
	r2.free()

func _test_stat_card() -> void:
	var stats: Array[Dictionary] = [
		{"label": "Thời gian", "value": "02:41", "icon": "clock"},
		{"label": "Lỗi sai", "value": "1", "icon": "error"},
	]
	var card := StatCard.new(stats)
	_assert(card is PanelContainer, "stat_card 2-col is PanelContainer")
	card.free()
	var card2 := StatCard.new([{"label": "Thời gian", "value": "03:12", "icon": "clock"}])
	_assert(card2 is PanelContainer, "stat_card 1-col is PanelContainer")
	card2.free()

func _test_confetti_layer() -> void:
	var confetti := ConfettiLayer.new(40)
	_assert(confetti is Control, "confetti_layer is Control")
	confetti.free()

func _test_sunburst_rays() -> void:
	var rays := SunburstRays.new()
	_assert(rays is Control, "sunburst_rays is Control")
	rays.free()
