extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const AppShell = preload("res://scripts/screens/app_shell.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	LayoutTokens.motion_enabled = false
	var today := Rules.today()
	var yesterday := Time.get_date_string_from_unix_time(Rules._unix(today) - 86400)
	var three_ago := Time.get_date_string_from_unix_time(Rules._unix(today) - 3 * 86400)
	var dir := OS.get_user_data_dir().path_join("streak_ui_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.on_round_finished(yesterday)  # streak 1, not kept today -> at risk

	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	title.assists = inv
	root.add_child(title)
	title.setup(null)
	var chip: Button = title.streak_chip
	check(chip != null and chip.visible, "chip on home")
	check(chip.get_parent() is CenterContainer, "chip centered horizontally")
	check(chip.count_label.text == "1", "chip shows count")
	check(not chip.flame.lit, "grey before today's play")
	check(chip.at_risk, "at risk flagged")
	check(not "sheet" in chip, "chip has no popup sheet")
	var asked := [0]
	title.streak_pressed.connect(func(): asked[0] += 1)
	chip.pressed.emit()
	check(asked[0] == 1, "chip tap asks for the streak screen")

	inv.on_round_finished(today)
	chip.refresh()
	check(chip.count_label.text == "2" and chip.flame.lit, "lit after today's play")
	check(not chip.at_risk, "not at risk once kept")

	var lapsed := Inventory.new(dir + "_lapsed")
	lapsed.on_round_finished(three_ago)
	chip.bind(lapsed)
	check(chip.count_label.text == "0" and not chip.at_risk, "missed day: chip shows 0 (Q11)")
	lapsed._store.remove_all()

	var bare: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(bare)
	bare.setup(null)
	check(not bare.streak_chip.visible, "chip hidden without stock")
	title.queue_free(); bare.queue_free()
	inv._store.remove_all()

	await _test_shell_route(dir + "_shell")
	if failures.is_empty():
		print("STREAK_UI_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _test_shell_route(pdir: String) -> void:
	DirAccess.make_dir_recursive_absolute(pdir)
	var shell: AppShell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = pdir
	root.add_child(shell)
	await process_frame
	var home: Control = shell.screen_host.get_child(0)
	home.streak_chip.pressed.emit()
	await process_frame
	check(shell.nav.current() == NavController.Screen.STREAK, "chip navigates to STREAK")
	var screen: Control = shell.screen_host.get_child(0)
	check(screen.name == "StreakScreen", "streak screen shown")
	check(screen.assists == shell.assists, "streak screen gets the shell inventory")
	screen.back_btn.pressed.emit()
	await process_frame
	check(shell.nav.current() == NavController.Screen.TITLE, "back returns home")
	var again: Control = shell.screen_host.get_child(0)
	check(again.name == "TitleScreen" and again.streak_chip.visible, "home chip still bound after back")
	shell.queue_free()
	await process_frame

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
