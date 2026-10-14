extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const StreakChip = preload("res://scripts/screens/streak_chip.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var today := Rules.today()
	var yesterday := Time.get_date_string_from_unix_time(Rules._unix(today) - 86400)
	var dir := OS.get_user_data_dir().path_join("streak_ui_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.on_level_won(yesterday)  # streak 1, not kept today -> at risk

	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	title.assists = inv
	root.add_child(title)
	title.setup(null)
	var chip: Button = title.streak_chip
	check(chip != null and chip.visible, "chip on home")
	check(chip.get_parent() is CenterContainer, "chip centered horizontally")
	check(chip.count_label.text == "1", "chip shows count")
	check(chip.icon_rect.modulate == StreakChip.OFF_COLOR, "grey before today's win")
	check(chip.at_risk, "at risk flagged")
	chip.pressed.emit()
	var sheet: Control = chip.sheet
	check(sheet.visible, "sheet opens on tap")
	check(sheet.count_label.text == "1", "sheet count")
	check(sheet.cells.size() == 7, "seven cycle cells")
	check(sheet.cells.filter(func(c): return c.get_meta("done", false)).size() == 1, "one cell done")
	check(sheet.status_label.text == title.tr("streak.at_risk"), "at-risk status")
	sheet.close()
	check(not sheet.visible, "sheet closes")

	inv.on_level_won(today)
	chip.refresh()
	check(chip.count_label.text == "2" and chip.icon_rect.modulate == StreakChip.ON_COLOR, "orange after today's win")
	check(not chip.at_risk, "not at risk once kept")
	chip.pressed.emit()
	check(sheet.status_label.text == title.tr("streak.kept"), "kept status")
	check(sheet.best_label.text == title.tr("streak.best") % 2, "best line")

	var bare: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(bare)
	bare.setup(null)
	check(not bare.streak_chip.visible, "chip hidden without stock")

	title.queue_free(); bare.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_UI_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
