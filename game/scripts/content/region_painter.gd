# region_painter.gd
extends RefCounted

# Adjacent regions must stay at least this far apart in CIELAB (dE76).
const MIN_ADJACENT_CONTRAST := 20.0
# The first colors of the palette are the mockup's main theme; the rest are reserves
# used only when a board has more zones or no primary color keeps the contrast.
const PRIMARY_COLOR_COUNT := 9

enum OverlayIcon { NONE, STAR, DIAMOND, HEART, TRIANGLE, CROSS, DOT }

static func luminance(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b

# Greedy graph coloring of the region adjacency graph:
# 1. zones sorted by degree (most neighbors first),
# 2. a color is acceptable only if its dE to every colored neighbor >= MIN_ADJACENT_CONTRAST,
# 3. among acceptable colors pick the one maximizing min dE to neighbors (unused colors first).
static func assign_colors(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
	if palette.is_empty():
		return {}
	var grid := precompute_grid(size, zones)
	var adj := _build_adjacency(size, grid)
	var order := _degree_order(grid, adj)
	var pool: Array[Color] = palette.slice(0, maxi(PRIMARY_COLOR_COUNT, order.size()))
	var assigned: Dictionary = {}
	var used_colors: Array[Color] = []
	for z in order:
		var neighbor_colors := _neighbor_colors(z, adj, assigned)
		var col: Variant = _pick_color(pool, neighbor_colors, used_colors, true)
		if col == null and pool.size() < palette.size():
			col = _pick_color(palette, neighbor_colors, used_colors, true)
		if col == null:
			col = _pick_color(palette, neighbor_colors, used_colors, false)
		assigned[z] = col
		used_colors.append(col)
	return assigned

# Returns the color maximizing min dE to neighbors; unused colors win ties of acceptability.
# With strict=true, colors below MIN_ADJACENT_CONTRAST are rejected (returns null if none).
static func _pick_color(pool: Array, neighbor_colors: Array[Color], used_colors: Array[Color], strict: bool) -> Variant:
	var best: Variant = null
	var best_unused := false
	var best_d: float = -1.0
	for col in pool:
		var min_d: float = 1000.0
		for n_col in neighbor_colors:
			min_d = minf(min_d, lab_distance(col, n_col))
		if strict and min_d < MIN_ADJACENT_CONTRAST:
			continue
		var unused: bool = not used_colors.has(col)
		if best == null or (unused and not best_unused) or (unused == best_unused and min_d > best_d):
			best = col
			best_unused = unused
			best_d = min_d
	return best

static func _neighbor_colors(z: String, adj: Dictionary, assigned: Dictionary) -> Array[Color]:
	var out: Array[Color] = []
	for nbr in adj.get(z, []):
		if assigned.has(nbr):
			out.append(assigned[nbr])
	return out

# Zones by descending degree; ties keep reading order so results are deterministic.
static func _degree_order(grid: Array, adj: Dictionary) -> Array:
	var order: Array = []
	for row in grid:
		for z in row:
			if not order.has(z):
				order.append(z)
	var first_seen := {}
	for i in range(order.size()):
		first_seen[order[i]] = i
	order.sort_custom(func(a: String, b: String) -> bool:
		var da: int = adj.get(a, []).size()
		var db: int = adj.get(b, []).size()
		return da > db if da != db else first_seen[a] < first_seen[b]
	)
	return order

# Colorblind mode: same colors as assign_colors, plus patterns on the darker half of zones
# (adjacent patterned zones never share a pattern).
static func assign_with_overlays(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
	var colors := assign_colors(size, zones, palette)
	if colors.is_empty():
		return {"colors": {}, "overlays": {}}
	var grid := precompute_grid(size, zones)
	var adj := _build_adjacency(size, grid)
	var by_dark: Array = colors.keys()
	by_dark.sort_custom(func(a: String, b: String) -> bool:
		var la := luminance(colors[a])
		var lb := luminance(colors[b])
		return la < lb if la != lb else a < b
	)
	var n_pattern := ceili(by_dark.size() / 2.0)
	var icons := [OverlayIcon.STAR, OverlayIcon.DIAMOND, OverlayIcon.HEART, OverlayIcon.TRIANGLE, OverlayIcon.CROSS, OverlayIcon.DOT]
	var overlays: Dictionary = {}
	for z in by_dark:
		overlays[z] = OverlayIcon.NONE
	for i in range(n_pattern):
		var z: String = by_dark[i]
		var taken: Array = []
		for nbr in adj.get(z, []):
			if overlays[nbr] != OverlayIcon.NONE:
				taken.append(overlays[nbr])
		var chosen: int = icons[i % icons.size()]
		for icon in icons:
			if not taken.has(icon):
				chosen = icon
				break
		overlays[z] = chosen
	return {"colors": colors, "overlays": overlays}

static func overlay_tint(base_color: Color, is_dark: bool) -> Color:
	if is_dark:
		var h := base_color.h
		var s := minf(base_color.s + 0.15, 1.0)
		var v := maxf(base_color.v - 0.1, 0.0)
		return Color.from_hsv(h, s, v, base_color.a)
	else:
		return base_color.lightened(0.3)

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
