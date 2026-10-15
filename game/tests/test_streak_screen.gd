extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var dir := OS.get_user_data_dir().path_join("streak_screen_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	for day in range(1, 4): inv.on_round_finished("2026-05-%02d" % day)

	var screen: Control = (load("res://scenes/streak.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	screen.setup(inv, "2026-05-03")
	check(screen.name == "StreakScreen", "scene root name")
	check(screen.title_label.text == screen.tr("streak.title"), "title")
	check(screen.count_label.text == "3" and screen.flame.lit, "count and lit flame")
	check(screen.strip.cell_state(2) == "done" and screen.strip.today_index() == -1, "strip kept today")
	check(screen.gift_box == screen.strip.gift_box, "gift box at the end of the strip")
	check(screen.best_label.visible and screen.best_label.text == screen.tr("streak.best") % 3, "best line")
	var back := [false]
	screen.back_pressed.connect(func(): back[0] = true)
	screen.back_btn.pressed.emit()
	check(back[0], "back emits back_pressed")

	screen.setup(inv, "2026-05-04")
	check(screen.count_label.text == "3" and not screen.flame.lit, "next day: grey, count kept")
	check(screen.strip.today_index() == 3, "next day: today cell")
	screen.setup(inv, "2026-05-06")
	check(screen.count_label.text == "0", "missed a day: count 0 (Q11)")
	check(screen.best_label.text == screen.tr("streak.best") % 3, "missed a day: best kept")

	screen.setup(null)
	check(screen.count_label.text == "0" and screen.strip.today_index() == 0, "no inventory renders zeros")
	check(screen.best_label.text == screen.tr("streak.best") % 0, "no inventory best 0")

	for key in ["streak.left", "streak.kept", "streak.at_risk", "streak.start", "streak.gift_got"]:
		check(screen.tr(key) == key, "removed key %s" % key)
	check(not ResourceLoader.exists("res://scripts/screens/streak_sheet.gd"), "streak_sheet removed")

	screen.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_SCREEN_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
