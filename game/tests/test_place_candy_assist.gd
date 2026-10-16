extends SceneTree

const Pick = preload("res://scripts/core/place_candy_assist.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const B := CellModel.CellKind.BLANK
const M := CellModel.CellKind.MARK
const C := CellModel.CellKind.CANDY
# Tutorial board from RST-028: solution [1,3,0,2]
const REGIONS := ["ABCC", "AAAC", "ADDC", "ADDD"]
const SOLUTION := [1, 3, 0, 2]
var failures: Array[String] = []

func _init() -> void:
	var empty := _board([[B,B,B,B],[B,B,B,B],[B,B,B,B],[B,B,B,B]])
	var cell := Pick.pick_cell(empty, 4, REGIONS, SOLUTION)
	check(cell.size() == 2 and int(SOLUTION[cell[0]]) == cell[1], "always a solution cell")
	# Region B is the single cell (0,1): smallest region wins the fallback too.
	check(cell == [0, 1], "single-cell region picked first")
	# Wrong X on a solution cell is still pickable (try_candy accepts MARK).
	var marked := _board([[B,M,B,B],[B,B,B,B],[B,B,B,B],[B,B,B,B]])
	check(Pick.pick_cell(marked, 4, REGIONS, SOLUTION) == [0, 1], "marked solution cell pickable")
	var three := _board([[B,C,B,B],[B,B,B,C],[C,B,B,B],[B,B,B,B]])
	check(Pick.pick_cell(three, 4, REGIONS, SOLUTION) == [3, 2], "last candy")
	var full := _board([[B,C,B,B],[B,B,B,C],[C,B,B,B],[B,B,C,B]])
	check(Pick.pick_cell(full, 4, REGIONS, SOLUTION).is_empty(), "solved -> empty")
	if failures.is_empty():
		print("PLACE_CANDY_ASSIST_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _board(rows: Array) -> Array:
	var out: Array = []
	for r in rows: out.append((r as Array).duplicate())
	return out

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
