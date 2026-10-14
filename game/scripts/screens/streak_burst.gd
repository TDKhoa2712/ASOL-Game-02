# "+1 day" burst: glow, layered flame pop, expanding ring, spark explosion, count roll.
extends Control

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const SIDE := 170.0
const BOX := Vector2(320, 340)
const GLOW := Color(1.0, 0.54, 0.12, 0.35)
const RING := Color(1.0, 0.85, 0.4)

var ring_t := 0.0
var _moving := false

static func play(parent: Control, total: int) -> Control:
	var burst := new()
	burst._build(total)
	parent.add_child(burst)
	burst._start(total)
	return burst

func _build(total: int) -> void:
	name = "StreakBurst"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)
	size = BOX
	position = -BOX * 0.5
	pivot_offset = BOX * 0.5
	_moving = LayoutTokens.motion_enabled
	var flame := FlameFx.new(SIDE, 24)
	flame.position = Vector2((BOX.x - SIDE) * 0.5, 20)
	flame.pivot_offset = Vector2(SIDE * 0.5, SIDE * 0.5)
	flame.set_lit(true)
	add_child(flame)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(BOX.x, 110)
	label.position = Vector2(0, SIDE + 30)
	label.pivot_offset = label.size * 0.5
	label.add_theme_font_size_override("font_size", 92)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#B3260F"))
	label.add_theme_constant_override("outline_size", 16)
	var font := FontTokens.heading()
	if font != null: label.add_theme_font_override("font", font)
	label.text = str(maxi(total - 1, 0) if _moving else total)
	add_child(label)
	set_meta("label", label)
	set_meta("flame", flame)
	var sparks: CPUParticles2D = _make_sparks() if _moving else null
	if sparks != null: add_child(sparks)
	set_meta("sparks", sparks)

func _start(total: int) -> void:
	if not is_inside_tree():
		return
	if not _moving:
		get_tree().create_timer(1.2).timeout.connect(queue_free)
		return
	var flame: Control = get_meta("flame")
	var label: Label = get_meta("label")
	var sparks: CPUParticles2D = get_meta("sparks")
	sparks.emitting = true
	Vibration.pulse(Vibration.Strength.SOFT)
	flame.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(flame, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(_set_ring, 0.0, 1.0, 0.6)
	tw.tween_callback(func(): label.text = str(total); label.scale = Vector2(1.35, 1.35))
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(flame, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(0.35)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func _set_ring(t: float) -> void:
	ring_t = t
	queue_redraw()

func _draw() -> void:
	var center := Vector2(BOX.x * 0.5, 20 + SIDE * 0.55)
	draw_circle(center, SIDE * 0.75, GLOW)
	if _moving and ring_t > 0.0 and ring_t < 1.0:
		var ring := RING
		ring.a = 0.8 * (1.0 - ring_t)
		draw_arc(center, SIDE * 1.6 * ring_t, 0.0, TAU, 48, ring, 10.0)

func _make_sparks() -> CPUParticles2D:
	var s := CPUParticles2D.new()
	s.name = "Sparks"
	s.one_shot = true
	s.explosiveness = 1.0
	s.amount = 28
	s.lifetime = 0.8
	s.position = Vector2(BOX.x * 0.5, 20 + SIDE * 0.55)
	s.direction = Vector2(0, -1)
	s.spread = 180.0
	s.initial_velocity_min = 300.0
	s.initial_velocity_max = 520.0
	s.gravity = Vector2(0, 600)
	s.scale_amount_min = 4.0
	s.scale_amount_max = 8.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color("#FFF2A8"))
	ramp.set_color(1, Color(0.91, 0.21, 0.11, 0.0))
	s.color_ramp = ramp
	s.emitting = false
	return s
