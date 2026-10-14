# Layered flame (red shell, orange body, yellow core) that flickers and sheds embers while lit.
extends Control

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const ICON := "res://assets/ui/home/icon_flame.svg"
const LAYER_COLORS := [Color("#E8361C"), Color("#FF8A1F"), Color("#FFD84A")]
const LAYER_SCALES := [1.0, 0.78, 0.5]
const OFF_COLOR := Color("#B9B4AC")

var lit := false
var layers: Array[TextureRect] = []
var embers_node: CPUParticles2D = null
var _tweens: Array[Tween] = []

func _init(side: float = 64.0, embers: int = 0) -> void:
	name = "FlameFx"
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load(ICON) as Texture2D
	for i in 3:
		var s: float = side * float(LAYER_SCALES[i])
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.size = Vector2(s, s)
		t.position = Vector2((side - s) * 0.5, side - s)  # layers share the flame base
		t.pivot_offset = Vector2(s * 0.5, s)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		layers.append(t)
	if embers > 0:
		embers_node = _make_embers(side, embers)
		add_child(embers_node)
	set_lit(false)

func set_lit(on: bool) -> void:
	lit = on
	_stop_flicker()
	for i in layers.size():
		var t: TextureRect = layers[i]
		t.visible = on or i == 0
		t.modulate = LAYER_COLORS[i] if on else OFF_COLOR
	var moving := on and LayoutTokens.motion_enabled
	if embers_node != null:
		embers_node.emitting = moving
		embers_node.visible = moving
	if moving and is_inside_tree():
		_start_flicker()

func is_flickering() -> bool:
	return not _tweens.is_empty()

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE and lit and LayoutTokens.motion_enabled and _tweens.is_empty():
		_start_flicker()
	elif what == NOTIFICATION_EXIT_TREE:
		_stop_flicker()

func _start_flicker() -> void:
	for i in layers.size():
		var t: TextureRect = layers[i]
		var period := 0.32 + 0.08 * i + randf() * 0.07
		var lean := deg_to_rad(3.0 if i % 2 == 0 else -3.0)
		var tw := create_tween().set_loops()  # owned by the flame: children are not in the tree yet at ENTER_TREE
		tw.tween_property(t, "scale", Vector2(0.97, 1.06 + 0.03 * i), period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "rotation", lean, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "modulate:a", 0.85, period)
		tw.tween_property(t, "scale", Vector2.ONE, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "rotation", 0.0, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "modulate:a", 1.0, period)
		_tweens.append(tw)

func _stop_flicker() -> void:
	for tw in _tweens:
		if tw.is_valid(): tw.kill()
	_tweens.clear()
	for t in layers:
		t.scale = Vector2.ONE
		t.rotation = 0.0

static func _make_embers(side: float, amount: int) -> CPUParticles2D:
	var e := CPUParticles2D.new()
	e.name = "Embers"
	e.amount = amount
	e.lifetime = 0.9
	e.position = Vector2(side * 0.5, side * 0.7)
	e.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	e.emission_sphere_radius = side * 0.18
	e.direction = Vector2(0, -1)
	e.spread = 25.0
	e.gravity = Vector2(0, -side * 0.6)
	e.initial_velocity_min = side * 0.4
	e.initial_velocity_max = side * 0.9
	e.scale_amount_min = maxf(1.5, side * 0.04)
	e.scale_amount_max = maxf(2.5, side * 0.08)
	var ramp := Gradient.new()
	ramp.set_color(0, Color("#FFE27A"))
	ramp.set_color(1, Color(0.91, 0.21, 0.11, 0.0))
	e.color_ramp = ramp
	e.emitting = false
	return e
