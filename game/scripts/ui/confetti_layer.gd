# confetti_layer.gd — Falling confetti particles for win screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _particles: CPUParticles2D
var _count: int = 40

func _init(count: int = 40) -> void:
	_count = count
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1

func start() -> void:
	if not LayoutTokens.motion_enabled:
		return
	if _particles != null:
		_particles.restart()
		return
	_particles = CPUParticles2D.new()
	_particles.amount = _count
	_particles.lifetime = 5.0
	_particles.preprocess = 1.0
	_particles.emitting = true
	if ResourceLoader.exists("res://assets/ui/result/square_confetti.svg"):
		_particles.texture = load("res://assets/ui/result/square_confetti.svg")
	var sw := size.x if size.x > 0 else 780.0
	_particles.position = Vector2(sw * 0.5, -30.0)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(sw * 0.5, 10.0)
	_particles.direction = Vector2(0, 1)
	_particles.spread = 25.0
	_particles.gravity = Vector2(0, 160)
	_particles.initial_velocity_min = 120.0
	_particles.initial_velocity_max = 260.0
	_particles.angular_velocity_min = -420.0
	_particles.angular_velocity_max = 420.0
	_particles.angle_min = 0.0
	_particles.angle_max = 360.0
	_particles.scale_amount_min = 1.2
	_particles.scale_amount_max = 2.6
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(Palette.CONFETTI_COLORS)
	var step := 1.0 / float(Palette.CONFETTI_COLORS.size() - 1)
	var offsets: PackedFloat32Array = []
	for i in range(Palette.CONFETTI_COLORS.size()):
		offsets.append(float(i) * step)
	ramp.offsets = offsets
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	_particles.color_initial_ramp = ramp
	add_child(_particles)
