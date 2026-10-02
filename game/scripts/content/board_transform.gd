# board_transform.gd
extends RefCounted

enum Transform {
	IDENTITY,       # 0: original
	ROTATE_90,      # 1: rotate 90° CW
	ROTATE_180,     # 2: rotate 180°
	ROTATE_270,     # 3: rotate 270° CW
	MIRROR_H,       # 4: mirror horizontal
	MIRROR_H_R90,   # 5: mirror + rotate 90°
	MIRROR_H_R180,  # 6: mirror + rotate 180°
	MIRROR_H_R270,  # 7: mirror + rotate 270°
}

const TRANSFORM_COUNT := 8

static func apply(level: Dictionary, t: int) -> Dictionary:
	var out: Dictionary = level.duplicate(true)
	var n: int = 0
	if out.has("size"):
		n = int(out["size"])
	elif out.has("regions") and out["regions"] is Array:
		n = out["regions"].size()

	if n <= 0:
		return out

	if out.has("regions") and out["regions"] is Array:
		out["regions"] = transform_regions(out["regions"], n, t)
	if out.has("solution") and out["solution"] is Array:
		out["solution"] = transform_solution(out["solution"], n, t)
	if out.has("givens") and out["givens"] is Array:
		out["givens"] = transform_givens(out["givens"], n, t)
	if out.has("logicTrace") and out["logicTrace"] is Array:
		var new_trace: Array = []
		for step in out["logicTrace"]:
			if step is Dictionary:
				var step_copy: Dictionary = step.duplicate(true)
				if step_copy.has("conclusion") and step_copy["conclusion"] is Dictionary:
					var conc: Dictionary = step_copy["conclusion"]
					if conc.has("r") and conc.has("c"):
						var p := transform_cell(int(conc["r"]), int(conc["c"]), n, t)
						conc["r"] = p[0]
						conc["c"] = p[1]
				new_trace.append(step_copy)
			else:
				new_trace.append(step)
		out["logicTrace"] = new_trace
	return out

static func transform_regions(regions: Array, n: int, t: int) -> Array:
	var grid: Array = []
	for r in range(n):
		var row: Array = []
		row.resize(n)
		grid.append(row)

	for r in range(n):
		var row_str: String = str(regions[r])
		for c in range(n):
			var ch: String = row_str[c]
			var p := transform_cell(r, c, n, t)
			grid[p[0]][p[1]] = ch

	var result: Array = []
	for r in range(n):
		result.append("".join(grid[r]))
	return result

static func transform_solution(solution: Array, arg2: Variant, arg3: Variant = null, arg4: Variant = null) -> Array:
	var n: int = 0
	var t: int = 0
	if (arg2 is int or arg2 is float) and (arg3 is int or arg3 is float):
		n = int(arg2)
		t = int(arg3)
	elif arg2 is Array and arg3 is Array and (arg4 is int or arg4 is float):
		n = int(arg4)
		var reg_before: Array = arg2
		var reg_after: Array = arg3
		for cand_t in range(TRANSFORM_COUNT):
			if transform_regions(reg_before, n, cand_t) == reg_after:
				t = cand_t
				break
	else:
		return solution.duplicate()

	var new_sol: Array = []
	new_sol.resize(n)
	for r in range(mini(n, solution.size())):
		var c: int = int(solution[r])
		var p := transform_cell(r, c, n, t)
		var nr: int = p[0]
		var nc: int = p[1]
		if nr >= 0 and nr < n:
			new_sol[nr] = nc
	return new_sol

static func transform_cell(r: int, c: int, n: int, t: int) -> Array:
	return _compose(r, c, n, t)

static func transform_givens(givens: Array, n: int, t: int) -> Array:
	var result: Array = []
	for g in givens:
		if not (g is Dictionary):
			continue
		var r: int = int(g.get("r", g.get("row", 0)))
		var c: int = int(g.get("c", g.get("col", 0)))
		var p := transform_cell(r, c, n, t)
		var new_g: Dictionary = g.duplicate()
		if new_g.has("r"):
			new_g["r"] = p[0]
		if new_g.has("row"):
			new_g["row"] = p[0]
		if new_g.has("c"):
			new_g["c"] = p[1]
		if new_g.has("col"):
			new_g["col"] = p[1]
		result.append(new_g)
	return result

static func _rotate_90(r: int, c: int, n: int) -> Array:
	return [c, n - 1 - r]

static func _mirror_h(r: int, c: int, n: int) -> Array:
	return [r, n - 1 - c]

static func _compose(r: int, c: int, n: int, t: int) -> Array:
	var rr := r
	var cc := c
	var t_idx := posmod(t, TRANSFORM_COUNT)
	if t_idx >= 4:
		var m := _mirror_h(rr, cc, n)
		rr = m[0]
		cc = m[1]
	var rot := t_idx % 4
	for _i in range(rot):
		var p := _rotate_90(rr, cc, n)
		rr = p[0]
		cc = p[1]
	return [rr, cc]
