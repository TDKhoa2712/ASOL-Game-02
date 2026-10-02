# region_painter.gd
extends RefCounted

static func assign_colors(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
	if palette.is_empty():
		return {}

	var grid := precompute_grid(size, zones)
	var adj := _build_adjacency(size, grid)
	var all_zones: Array = []
	for r in range(size):
		for c in range(size):
			var z: String = grid[r][c]
			if not all_zones.has(z):
				all_zones.append(z)

	# Sort zones by descending neighbor count (degree)
	all_zones.sort_custom(func(a: String, b: String) -> bool:
		var deg_a: int = adj.get(a, []).size()
		var deg_b: int = adj.get(b, []).size()
		return deg_a > deg_b
	)

	var assigned: Dictionary = {}

	for z in all_zones:
		var neighbor_colors: Array[Color] = []
		for nbr in adj.get(z, []):
			if assigned.has(nbr):
				neighbor_colors.append(assigned[nbr])

		var candidates: Array[Color] = []
		for col in palette:
			if not neighbor_colors.has(col):
				candidates.append(col)

		if candidates.is_empty():
			candidates = palette.duplicate()

		if neighbor_colors.is_empty():
			assigned[z] = candidates[0]
		else:
			var best_col: Color = candidates[0]
			var max_min_dist: float = -1.0
			for col in candidates:
				var min_d: float = INF
				for n_col in neighbor_colors:
					var d := lab_distance(col, n_col)
					if d < min_d:
						min_d = d
				if min_d > max_min_dist:
					max_min_dist = min_d
					best_col = col
			assigned[z] = best_col

	return assigned

static func precompute_grid(size: int, zones: Array) -> Array:
	var grid: Array = []
	for r in range(size):
		var row: Array = []
		var row_str: String = str(zones[r])
		for c in range(size):
			row.append(row_str[c])
		grid.append(row)
	return grid

static func lab_distance(a: Color, b: Color) -> float:
	var lab_a := to_lab(a)
	var lab_b := to_lab(b)
	var dL: float = lab_a[0] - lab_b[0]
	var da: float = lab_a[1] - lab_b[1]
	var db: float = lab_a[2] - lab_b[2]
	return sqrt(dL * dL + da * da + db * db)

static func to_lab(c: Color) -> Array:
	var r_lin := _linearize(c.r)
	var g_lin := _linearize(c.g)
	var b_lin := _linearize(c.b)

	var x := r_lin * 0.4124564 + g_lin * 0.3575761 + b_lin * 0.1804375
	var y := r_lin * 0.2126729 + g_lin * 0.7151522 + b_lin * 0.0721750
	var z := r_lin * 0.0193339 + g_lin * 0.1191920 + b_lin * 0.9503041

	var xr := x / 0.95047
	var yr := y / 1.00000
	var zr := z / 1.08883

	var fx := _lab_transfer(xr)
	var fy := _lab_transfer(yr)
	var fz := _lab_transfer(zr)

	var L := 116.0 * fy - 16.0
	var a := 500.0 * (fx - fy)
	var b := 200.0 * (fy - fz)
	return [L, a, b]

static func _build_adjacency(size: int, grid: Array) -> Dictionary:
	var adj: Dictionary = {}
	for r in range(size):
		for c in range(size):
			var z: String = grid[r][c]
			if not adj.has(z):
				adj[z] = []

	for r in range(size):
		for c in range(size):
			var z1: String = grid[r][c]
			for delta in [[1, 0], [0, 1]]:
				var nr: int = r + delta[0]
				var nc: int = c + delta[1]
				if nr < size and nc < size:
					var z2: String = grid[nr][nc]
					if z1 != z2:
						if not z2 in adj[z1]:
							adj[z1].append(z2)
						if not z1 in adj[z2]:
							adj[z2].append(z1)
	return adj

static func _linearize(v: float) -> float:
	if v <= 0.04045:
		return v / 12.92
	return pow((v + 0.055) / 1.055, 2.4)

static func _lab_transfer(t: float) -> float:
	var delta: float = 6.0 / 29.0
	var delta_cb: float = delta * delta * delta
	if t > delta_cb:
		return pow(t, 1.0 / 3.0)
	return (t / (3.0 * delta * delta)) + (4.0 / 29.0)
