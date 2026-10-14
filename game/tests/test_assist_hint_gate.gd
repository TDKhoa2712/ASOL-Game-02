extends SceneTree

const Coordinator = preload("res://scripts/screens/puzzle_hint_coordinator.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("assist_gate_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	var coord := Coordinator.new()
	coord.inventory = inv
	var empties: Array = []
	coord.stock_empty.connect(func(kind): empties.append(kind))
	var session := PlaySession.new(LEVEL)
	coord.request_hint(session)
	check(inv.count("hint") == 2, "showing a hint costs one")
	check(session.hints_used == 1, "session still counts hint")
	coord.force_release()
	# Wrong X on a solution cell -> WRONG_MARK hint is free
	session.mark_x(0, 1)
	coord.request_hint(session)
	check(inv.count("hint") == 2, "wrong-mark hint is free")
	coord.force_release()
	session.mark_x(0, 1)
	# Pressing hint again while showing only dismisses (no extra cost)
	coord.request_hint(session)
	coord.request_hint(session)
	check(inv.count("hint") == 1, "toggle-close does not charge")
	coord.force_release()
	inv.try_consume("hint")
	coord.request_hint(session)
	check(empties == ["hint"] and inv.count("hint") == 0, "empty stock emits stock_empty")
	check(not coord.is_hint_showing(), "no hint shown when empty")
	# place_candy marks the candy as assist-placed
	var flags: Array = []
	session.candy_found.connect(func(_r, _c, _z): flags.append(coord.is_applying()))
	coord.place_candy(session, [0, 1])
	check(session.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy placed")
	check(flags == [true], "placed while applying (combo resets)")
	check(not coord.is_applying(), "flag cleared")
	# No inventory -> unlimited, no signal
	var free_coord := Coordinator.new()
	free_coord.stock_empty.connect(func(kind): empties.append("free"))
	free_coord.request_hint(PlaySession.new(LEVEL))
	check(not empties.has("free"), "null inventory never empty")
	# Break session <-> lambda <-> coordinator cycles so nothing leaks at exit.
	for c in session.candy_found.get_connections(): session.candy_found.disconnect(c.callable)
	coord.force_release(); coord._session = null; free_coord._session = null
	inv._store.remove_all(); DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("ASSIST_HINT_GATE_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
