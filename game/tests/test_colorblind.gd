extends SceneTree

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
