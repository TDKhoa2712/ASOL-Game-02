# region_painter.gd
extends RefCounted

# Adjacent regions must stay at least this far apart in CIELAB (dE76).
const MIN_ADJACENT_CONTRAST := 20.0
# The first colors of the palette are the mockup's main theme; the rest are reserves
# used only when a board has more zones or no primary color keeps the contrast.
const PRIMARY_COLOR_COUNT := 9

# One shape per palette color (index + 1), so the same color always carries the same shape.
enum OverlayIcon { NONE, CIRCLE, SQUARE, TRIANGLE, DIAMOND, STAR, HEART, PLUS, DROP, RING, CRESCENT, HEXAGON, TRIANGLE_DOWN }

static func luminance(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b

# Greedy graph coloring of the region adjacency graph:
# 1. zones sorted by degree (most neighbors first),
# 2. zones never share a color while unused colors remain (uniqueness beats contrast),
# 3. among unused colors prefer those with dE >= MIN_ADJACENT_CONTRAST to every colored
#    neighbor, primary colors first, then the one maximizing min dE to neighbors.
static func assign_colors(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
	if palette.is_empty():
		return {}
	var grid := precompute_grid(size, zones)
	var adj := _build_adjacency(size, grid)
	var order := _degree_order(grid, adj)
	var primary: Array[Color] = palette.slice(0, maxi(PRIMARY_COLOR_COUNT, order.size()))
	var assigned: Dictionary = {}
	var used_colors: Array[Color] = []
	for z in order:
		var neighbor_colors := _neighbor_colors(z, adj, assigned)
		var col: Variant = _pick_color(primary, neighbor_colors, used_colors, true, false)
		if col == null:
			col = _pick_color(palette, neighbor_colors, used_colors, true, false)
		if col == null:
			col = _pick_color(palette, neighbor_colors, used_colors, false, false)
		if col == null:
			col = _pick_color(palette, neighbor_colors, used_colors, false, true)
		assigned[z] = col
		used_colors.append(col)
	if order.size() <= palette.size() and not _contrast_ok(assigned, adj):
		var exact := {}
		if _search_unique(order, 0, adj, palette, exact, [BACKTRACK_BUDGET]):
			return exact
	return assigned

# Greedy can paint itself into a corner when zones nearly exhaust the palette;
# depth-first search over unused colors (best contrast first) finds a unique, contrasting set.
const BACKTRACK_BUDGET := 20000

static func _search_unique(order: Array, i: int, adj: Dictionary, palette: Array[Color], assigned: Dictionary, budget: Array) -> bool:
	if i == order.size():
		return true
	budget[0] -= 1
	if budget[0] < 0:
		return false
	var z: String = order[i]
	var neighbor_colors := _neighbor_colors(z, adj, assigned)
	var used: Array = assigned.values()
	var candidates: Array = []
	for col in palette:
		if used.has(col):
			continue
		var min_d: float = 1000.0
		for n_col in neighbor_colors:
			min_d = minf(min_d, lab_distance(col, n_col))
		if min_d >= MIN_ADJACENT_CONTRAST:
			candidates.append([min_d, col])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for cand in candidates:
		assigned[z] = cand[1]
		if _search_unique(order, i + 1, adj, palette, assigned, budget):
			return true
		assigned.erase(z)
	return false

static func _contrast_ok(assigned: Dictionary, adj: Dictionary) -> bool:
	for z in assigned:
		for nbr in adj.get(z, []):
			if lab_distance(assigned[z], assigned[nbr]) < MIN_ADJACENT_CONTRAST:
				return false
	return true

# Returns the color maximizing min dE to neighbors, or null if none qualifies.
# strict rejects colors below MIN_ADJACENT_CONTRAST; allow_used admits colors already taken.
static func _pick_color(pool: Array, neighbor_colors: Array[Color], used_colors: Array[Color], strict: bool, allow_used: bool) -> Variant:
	var best: Variant = null
	var best_d: float = -1.0
	for col in pool:
		if not allow_used and used_colors.has(col):
			continue
		var min_d: float = 1000.0
		for n_col in neighbor_colors:
			min_d = minf(min_d, lab_distance(col, n_col))
		if strict and min_d < MIN_ADJACENT_CONTRAST:
			continue
		if min_d > best_d:
			best = col
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

# Colorblind mode: same colors as assign_colors, plus a shape on every zone keyed by its color.
static func assign_with_overlays(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
	var colors := assign_colors(size, zones, palette)
	var overlays: Dictionary = {}
	for z in colors:
		overlays[z] = icon_for_color(colors[z], palette)
	return {"colors": colors, "overlays": overlays}

static func icon_for_color(color: Color, palette: Array[Color]) -> int:
	var idx := palette.find(color)
	if idx < 0:
		return OverlayIcon.NONE
	return idx % (OverlayIcon.size() - 1) + 1

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
