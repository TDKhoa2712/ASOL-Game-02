extends SceneTree

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _initialize() -> void:
	await process_frame  # root joins the tree only after the first frame
	LayoutTokens.motion_enabled = true
	var fx := FlameFx.new(64, 6)
	fx.set_lit(true)
	check(not fx.is_flickering(), "no tween before entering the tree")
	root.add_child(fx)
	check(fx.is_flickering(), "flicker starts on enter tree")
	check(fx.layers.size() == 3, "three layers")
	check(fx.layers.all(func(l): return l.visible), "all layers lit")
	check(fx.layers[2].modulate == FlameFx.LAYER_COLORS[2], "yellow core")
	check(fx.embers_node is CPUParticles2D and fx.embers_node.emitting, "embers on")
	check(fx.embers_node.amount == 6, "ember count")
	fx.set_lit(false)
	check(fx.layers[0].visible and not fx.layers[1].visible and not fx.layers[2].visible, "grey shows one layer")
	check(fx.layers[0].modulate == FlameFx.OFF_COLOR, "grey color")
	check(not fx.is_flickering() and not fx.embers_node.emitting, "grey is still")
	LayoutTokens.motion_enabled = false
	fx.set_lit(true)
	check(fx.layers.all(func(l): return l.visible), "reduced motion keeps colors")
	check(not fx.is_flickering() and not fx.embers_node.emitting, "reduced motion: no tween, no embers")
	var bare := FlameFx.new(52, 0)
	check(bare.embers_node == null, "no embers when count is 0")
	bare.free()
	fx.free()
	if failures.is_empty():
		print("FLAME_FX_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
