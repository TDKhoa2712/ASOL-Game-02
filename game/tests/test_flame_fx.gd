extends SceneTree

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const FlameShapes = preload("res://scripts/screens/flame_shapes.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _initialize() -> void:
	await process_frame  # root joins the tree only after the first frame
	_check_shapes()
	LayoutTokens.motion_enabled = true
	var fx := FlameFx.new(64, 6)
	fx.set_lit(true)
	check(not fx.is_flickering(), "no motion before entering the tree")
	root.add_child(fx)
	check(fx.is_flickering(), "flicker starts on enter tree")
	check(fx.decorated, "licks and twinkles when count > 0")
	var polys := fx.layer_polygons()
	check(polys.size() == 3, "three layers")
	check(fx.layer_colors()[2] == FlameFx.LAYER_COLORS[2], "yellow core")
	check(_inside(polys, 64.0), "layers stay inside the box")
	var before: PackedVector2Array = polys[0]
	fx.advance(0.3)
	check(fx.layer_polygons()[0] != before, "outer layer morphs over time")
	fx.set_lit(false)
	check(fx.layer_polygons().size() == 1, "grey shows one silhouette")
	check(fx.layer_colors()[0] == FlameFx.OFF_COLOR, "grey color")
	check(not fx.is_flickering(), "grey is still")
	LayoutTokens.motion_enabled = false
	fx.set_lit(true)
	check(fx.layer_polygons().size() == 3, "reduced motion keeps colors")
	check(not fx.is_flickering(), "reduced motion: no motion")
	var bare := FlameFx.new(52, 0)
	check(not bare.decorated, "no decorations when count is 0")
	bare.free()
	fx.free()
	if failures.is_empty():
		print("FLAME_FX_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _check_shapes() -> void:
	var a := FlameShapes.sample(FlameShapes.OUTER_A, 6)
	var b := FlameShapes.sample(FlameShapes.OUTER_B, 6)
	check(a.size() == b.size() and a.size() > 12, "outer shapes sample to matching point counts")
	var mid := FlameShapes.blend(a, b, 0.5)
	check(mid[0].is_equal_approx((a[0] + b[0]) * 0.5), "blend halfway")
	check(Geometry2D.triangulate_polygon(a).size() > 0, "outer shape is a valid polygon")

func _inside(polys: Array, side: float) -> bool:
	for p in polys:
		for v in p:
			if v.x < -side * 0.1 or v.x > side * 1.1 or v.y < -side * 0.1 or v.y > side * 1.05:
				return false
	return true

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
