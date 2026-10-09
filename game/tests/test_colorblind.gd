extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const Palette = preload("res://scripts/theme/palette.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_assign_with_overlays_basic()
	_test_dark_zones_get_overlay()
	_test_no_adjacent_same_overlay()
	_test_all_zones_unique_color()
	_test_overlay_tint_dark()
	_test_overlay_tint_light()
	_test_luminance_range()
	_test_colorblind_keeps_same_colors()
	_test_highest_degree_zone_colored_first()
	_test_small_boards_use_primary_colors()
	_test_plain_cells_without_colorblind()
	if _fails.is_empty():
		print("COLORBLIND_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_assign_with_overlays_basic() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
	_assert(result.has("colors"), "result has colors")
	_assert(result.has("overlays"), "result has overlays")
	_assert(result.colors.size() == 4, "4 zone colors for ABCD")
	_assert(result.overlays.size() == 4, "4 zone overlays for ABCD")
	for z in result.colors:
		_assert(result.colors[z] is Color, "color for zone %s is Color" % z)
	for z in result.overlays:
		_assert(result.overlays[z] is int, "overlay for zone %s is int" % z)

func _test_dark_zones_get_overlay() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
	var has_overlay := false
	var has_none := false
	for z in result.overlays:
		if result.overlays[z] != RegionPainter.OverlayIcon.NONE:
			has_overlay = true
		else:
			has_none = true
	_assert(has_overlay, "some zones have overlay (dark pool)")
	_assert(has_none, "some zones have no overlay (light pool)")

func _test_no_adjacent_same_overlay() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
	var grid := RegionPainter.precompute_grid(4, regions)
	for r in range(4):
		for c in range(4):
			var z1: String = grid[r][c]
			for d in [[0, 1], [1, 0]]:
				var nr: int = r + d[0]
				var nc: int = c + d[1]
				if nr < 4 and nc < 4:
					var z2: String = grid[nr][nc]
					if z1 != z2:
						var o1: int = result.overlays[z1]
						var o2: int = result.overlays[z2]
						if o1 != RegionPainter.OverlayIcon.NONE and o2 != RegionPainter.OverlayIcon.NONE:
							_assert(o1 != o2, "adjacent dark zones %s,%s must have different overlay" % [z1, z2])

func _test_all_zones_unique_color() -> void:
	var cases := [
		["AABB", "ABBB", "CCBB", "CCDB"],
		["AABBB", "AABCB", "DDCCB", "DDEEB", "DDEEB"],
		["AABBCC", "AABBCC", "ADDBEC", "DDDBEE", "DFFBEE", "FFFBEE"],
	]
	for regions in cases:
		var n: int = regions.size()
		var result := RegionPainter.assign_colors(n, regions, Palette.ZONE_COLORS)
		var seen: Array[Color] = []
		for z in result:
			var c: Color = result[z]
			_assert(not seen.has(c), "N=%d zone %s color must be unique" % [n, z])
			seen.append(c)
		var result2 := RegionPainter.assign_with_overlays(n, regions, Palette.ZONE_COLORS)
		var seen2: Array[Color] = []
		for z in result2.colors:
			var c: Color = result2.colors[z]
			_assert(not seen2.has(c), "N=%d overlay zone %s color must be unique" % [n, z])
			seen2.append(c)

func _test_overlay_tint_dark() -> void:
	var base := Color(0.2, 0.1, 0.3)
	var tint := RegionPainter.overlay_tint(base, true)
	_assert(tint != base, "dark tint differs from base")
	var dist := RegionPainter.lab_distance(base, tint)
	_assert(dist > 3.0, "dark overlay tint has visible ΔE (got %.1f)" % dist)

func _test_overlay_tint_light() -> void:
	var base := Color(0.8, 0.9, 0.7)
	var tint := RegionPainter.overlay_tint(base, false)
	_assert(tint != base, "light tint differs from base")

func _test_luminance_range() -> void:
	_assert(RegionPainter.luminance(Color.BLACK) < 0.01, "black luminance near 0")
	_assert(RegionPainter.luminance(Color.WHITE) > 0.99, "white luminance near 1")
	_assert(RegionPainter.luminance(Color(0.5, 0.5, 0.5)) > 0.3, "gray luminance mid-range")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)

const LEVEL_5 := {"id": "T", "size": 5, "regions": ["AABBB", "AABCB", "DDCCB", "DDEEB", "DDEEB"], "solution": [0, 3, 1, 4, 2], "givens": []}

func _test_colorblind_keeps_same_colors() -> void:
	var regions: Array = LEVEL_5["regions"]
	var plain := RegionPainter.assign_colors(5, regions, Palette.ZONE_COLORS)
	var cb := RegionPainter.assign_with_overlays(5, regions, Palette.ZONE_COLORS)
	for z in plain:
		_assert(cb.colors[z] == plain[z], "colorblind keeps zone %s color, only adds pattern" % z)

func _test_highest_degree_zone_colored_first() -> void:
	# Degree ordering: the zone with most neighbors is colored first, so it gets palette[0].
	var regions: Array = LEVEL_5["regions"]
	var grid := RegionPainter.precompute_grid(5, regions)
	var adj := RegionPainter._build_adjacency(5, grid)
	var top := ""
	for z in ["A", "B", "C", "D", "E"]:
		if top == "" or adj[z].size() > adj[top].size():
			top = z
	var colors := RegionPainter.assign_colors(5, regions, Palette.ZONE_COLORS)
	_assert(colors[top] == Palette.ZONE_COLORS[0], "highest-degree zone %s gets first palette color" % top)

func _test_small_boards_use_primary_colors() -> void:
	var regions: Array = LEVEL_5["regions"]
	var colors := RegionPainter.assign_colors(5, regions, Palette.ZONE_COLORS)
	var primary := Palette.ZONE_COLORS.slice(0, RegionPainter.PRIMARY_COLOR_COUNT)
	for z in colors:
		_assert(primary.has(colors[z]), "zone %s uses a primary mockup color" % z)

func _test_plain_cells_without_colorblind() -> void:
	var board := PuzzleBoard.new()
	board.set_colorblind(false)
	board.configure(PlaySession.new(LEVEL_5.duplicate(true)), false)
	_assert(board._zone_overlays.is_empty(), "no patterns when colorblind is off")
	board.set_colorblind(true)
	board.configure(PlaySession.new(LEVEL_5.duplicate(true)), false)
	_assert(not board._zone_overlays.is_empty(), "patterns appear when colorblind is on")
	board.free()
