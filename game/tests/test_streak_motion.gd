extends SceneTree

const ActivateScreen = preload("res://scripts/screens/streak_activate_screen.gd")
const GiftScreen = preload("res://scripts/screens/streak_gift_screen.gd")
const GiftBoxScript = preload("res://scripts/screens/gift_box_view.gd")
const GlowBurst = preload("res://scripts/ui/glow_burst.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const VIEW := {"count": 4, "best": 9, "kept_today": false, "at_risk": false, "cycle_done": 3}
var failures: Array[String] = []

func _initialize() -> void:
	await process_frame
	_test_glow_burst()
	await _test_activate()
	await _test_gift_box()
	await _test_gift_screen()
	_test_sfx()
	LayoutTokens.motion_enabled = true
	if failures.is_empty():
		print("STREAK_MOTION_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _test_glow_burst() -> void:
	var g := GlowBurst.new()
	root.add_child(g)
	check(g.glow == 0.0 and g.burst == 0.0, "glow burst starts dark")
	g.burst = 0.5; g.glow = 1.0
	check(g.spark_count() == 8, "eight spark streaks")
	g.free()

func _test_activate() -> void:
	LayoutTokens.motion_enabled = true
	var act := ActivateScreen.new()
	root.add_child(act)
	act.setup(VIEW)
	check(act.is_animating(), "activate plays its timeline")
	check(act.count_label.scale != Vector2.ONE, "count waits to pop")
	check(act.continue_btn.modulate.a < 1.0, "continue waits for the timeline")
	act.finish()
	check(not act.is_animating(), "finish stops the timeline")
	check(act.count_label.scale.is_equal_approx(Vector2.ONE), "count settles")
	check(act.flame_holder.scale.is_equal_approx(Vector2.ONE), "flame settles")
	check(is_equal_approx(act.continue_btn.modulate.a, 1.0), "continue shown after finish")
	check(act.strip.cell_state(3) == "done", "today's cell filled")
	act.free()
	LayoutTokens.motion_enabled = false
	var still := ActivateScreen.new()
	root.add_child(still)
	still.setup(VIEW)
	check(not still.is_animating(), "reduced motion: no timeline")
	check(still.count_label.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(still.continue_btn.modulate.a, 1.0), "reduced motion: final layout")
	still.free()

func _test_gift_box() -> void:
	LayoutTokens.motion_enabled = true
	var box: GiftBoxView = GiftBoxScript.create()
	root.add_child(box)
	check(not box.is_open and is_equal_approx(box.lid_lift, 0.0), "box starts closed")
	box.set_open_amount(1.0)
	check(box.lid_lift > 0.9, "lid can lift")
	box.set_open_amount(0.0)
	box.play_open()
	check(not box.is_open, "opening takes time")
	box.finish_open()
	check(box.is_open, "finish_open opens at once")
	box.free()

func _test_gift_screen() -> void:
	LayoutTokens.motion_enabled = true
	var gift := GiftScreen.new()
	root.add_child(gift)
	gift.setup({"hint": 2, "place": 3})
	check(gift.is_animating(), "gift plays its timeline")
	check(not gift.gift.is_open, "box opens later in the timeline")
	check(gift.hint_card.modulate.a < 1.0, "reward cards wait")
	gift.finish()
	check(gift.gift.is_open, "box open after finish")
	check(is_equal_approx(gift.hint_card.modulate.a, 1.0) and is_equal_approx(gift.place_card.modulate.a, 1.0), "reward cards shown")
	gift.free()
	LayoutTokens.motion_enabled = false
	var still := GiftScreen.new()
	root.add_child(still)
	still.setup({"hint": 1, "place": 1})
	check(not still.is_animating() and still.gift.is_open, "reduced motion: box already open")
	still.free()

func _test_sfx() -> void:
	for e in [SfxCatalog.Effect.STREAK_ACTIVATE, SfxCatalog.Effect.STREAK_GIFT]:
		var preset: Dictionary = SfxCatalog.PRESETS[e]
		check(preset.get("type") == "file" and ResourceLoader.exists(preset["path"]), "streak sfx file %d" % e)
	check(SfxCatalog.screen_effect("streak_activate") == SfxCatalog.Effect.STREAK_ACTIVATE, "activate screen sound")
	check(SfxCatalog.screen_effect("streak_gift") == SfxCatalog.Effect.STREAK_GIFT, "gift screen sound")
	check(SfxCatalog.screen_effect("win") == SfxCatalog.Effect.STAGE_CLEAR, "win melody kept")
	check(SfxCatalog.screen_effect("fail") == SfxCatalog.Effect.STAGE_FAIL, "fail melody kept")
	check(SfxCatalog.screen_effect("title") == -1, "other screens silent")

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
