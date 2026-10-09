extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const ZoneShape = preload("res://scripts/screens/zone_shape.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_assign_with_overlays_basic()
	_test_every_zone_gets_shape()
	_test_shape_follows_color()
	_test_shapes_all_distinct()
	_test_shape_points_drawable()
	_test_all_zones_unique_color()
	_test_luminance_range()
	_test_colorblind_keeps_same_colors()
	_test_highest_degree_zone_colored_first()
	_test_small_boards_use_primary_colors()
	_test_plain_cells_without_colorblind()
	_test_toggle_mid_game()
	_test_bank_levels_never_repeat_colors()
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

func _test_every_zone_gets_shape() -> void:
	var regions := ["AABBCC", "AABBCC", "ADDBEC", "DDDBEE", "DFFBEE", "FFFBEE"]
	var result := RegionPainter.assign_with_overlays(6, regions, Palette.ZONE_COLORS)
	for z in result.overlays:
		_assert(result.overlays[z] != RegionPainter.OverlayIcon.NONE, "zone %s has a shape" % z)

func _test_shape_follows_color() -> void:
	# Same color always means same shape, on any board.
	for regions in [["AABB", "ABBB", "CCBB", "CCDB"], ["AABBB", "AABCB", "DDCCB", "DDEEB", "DDEEB"]]:
		var n: int = regions.size()
		var result := RegionPainter.assign_with_overlays(n, regions, Palette.ZONE_COLORS)
		for z in result.colors:
			_assert(result.overlays[z] == RegionPainter.icon_for_color(result.colors[z], Palette.ZONE_COLORS), "zone %s shape matches its color" % z)

func _test_shapes_all_distinct() -> void:
	var seen: Array = []
	for col in Palette.ZONE_COLORS:
		var icon := RegionPainter.icon_for_color(col, Palette.ZONE_COLORS)
		_assert(icon != RegionPainter.OverlayIcon.NONE, "palette color has a shape")
		_assert(not seen.has(icon), "palette colors never share a shape")
		seen.append(icon)

func _test_shape_points_drawable() -> void:
	for icon in range(1, RegionPainter.OverlayIcon.size()):
		var polys: Array = ZoneShape.polygons(icon, Vector2(50, 50), 20.0)
		_assert(not polys.is_empty(), "shape %d has polygons" % icon)
		for poly in polys:
			_assert(poly.size() >= 3 and not Geometry2D.triangulate_polygon(poly).is_empty(), "shape %d polygon triangulates" % icon)

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

func _test_toggle_mid_game() -> void:
	# The options toggle only calls set_colorblind on a board that is already configured.
	var board := PuzzleBoard.new()
	board.configure(PlaySession.new(LEVEL_5.duplicate(true)), false)
	board.set_colorblind(true)
	_assert(not board._zone_overlays.is_empty(), "turning colorblind on mid-game shows shapes")
	board.set_colorblind(false)
	_assert(board._zone_overlays.is_empty(), "turning colorblind off mid-game hides shapes")
	board.free()

func _test_bank_levels_never_repeat_colors() -> void:
	# Every bank level has at most as many zones as palette colors, so no two zones may share one.
	var bad := 0
	for n in range(4, 13):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/banks/bank_%dx%d.json" % [n, n]))
		if data == null: continue
		for rank in data.ranks:
			for lvl in data.ranks[rank]:
				var colors := RegionPainter.assign_colors(n, lvl.regions, Palette.ZONE_COLORS)
				var seen: Array = []
				for z in colors:
					if seen.has(colors[z]):
						bad += 1
						if bad <= 3: _fails.append("FAIL: %dx%d seed %s repeats a zone color" % [n, n, str(lvl.get("seed", "?"))])
						break
					seen.append(colors[z])
	_assert(bad == 0, "%d bank levels repeat a zone color" % bad)
