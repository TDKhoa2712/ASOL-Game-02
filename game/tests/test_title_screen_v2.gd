extends SceneTree

const ProgressBarWidget = preload("res://scripts/ui/progress_bar.gd")
const TitleHeroMascot = preload("res://scripts/ui/title_hero_mascot.gd")
const TitleScreen = preload("res://scripts/screens/title_screen.gd")
const TitleLogo = preload("res://scripts/ui/title_logo.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_progress_bar_creates()
	_test_progress_bar_zero()
	_test_progress_bar_overflow()
	_test_hero_mascot()
	_test_title_screen_instantiates()
	_test_title_logo_letters()
	_test_mascot_poke_cycles()
	if _fails.is_empty():
		print("TITLE_V2_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_progress_bar_creates() -> void:
	var bar := ProgressBarWidget.new(10, 30)
	_assert(bar is PanelContainer, "progress_bar is PanelContainer")
	bar.free()

func _test_progress_bar_zero() -> void:
	var bar := ProgressBarWidget.new(0, 0)
	_assert(bar is PanelContainer, "progress_bar zero total ok")
	bar.free()

func _test_progress_bar_overflow() -> void:
	var bar := ProgressBarWidget.new(50, 30)
	_assert(bar is PanelContainer, "progress_bar overflow clamped ok")
	bar.free()

func _test_hero_mascot() -> void:
	var hero := TitleHeroMascot.new()
	_assert(hero is Control, "hero is Control")
	hero.free()

func _test_title_screen_instantiates() -> void:
	var screen := TitleScreen.new()
	screen._ensure_nodes()
	_assert(screen.has_signal("play_pressed"), "has play_pressed")
	_assert(screen.has_signal("endless_pressed"), "has endless_pressed")
	_assert(screen.has_signal("options_pressed"), "has options_pressed")
	_assert(screen.find_child("CandyLogo", true, false) is TitleLogo, "title uses animated TitleLogo")
	screen.free()

func _test_title_logo_letters() -> void:
	var logo := TitleLogo.new()
	_assert(logo.letter_count() == 7, "logo has 7 glyph slots (C a n D o k u)")
	_assert(logo.swirl() != null, "logo has spinning swirl candy for 'o'")
	logo.free()

func _test_mascot_poke_cycles() -> void:
	var hero := TitleHeroMascot.new()
	var seen := {}
	for i in 3:
		seen[hero.poke()] = true
	_assert(seen.size() == 3, "three consecutive pokes give three different reactions")
	_assert(hero.bubble_text() != "", "bubble shows a line after poke")
	hero.free()
