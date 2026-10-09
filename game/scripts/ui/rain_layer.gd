# rain_layer.gd — CPUParticles2D rain under a cloud for lose screen.
extends Node2D

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _particles: CPUParticles2D

func _init(spread_width: float = 84.0) -> void:
	_particles = CPUParticles2D.new()
	_particles.amount = 26
	_particles.lifetime = 0.9
	_particles.emitting = LayoutTokens.motion_enabled
	if ResourceLoader.exists("res://assets/ui/result/raindrop.svg"):
		_particles.texture = load("res://assets/ui/result/raindrop.svg")
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(spread_width * 0.5, 2.0)
	_particles.direction = Vector2(0, 1)
	_particles.spread = 0.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 220.0
	_particles.initial_velocity_max = 260.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	_particles.color_ramp = fade
	add_child(_particles)

func start() -> void:
	if LayoutTokens.motion_enabled:
		_particles.emitting = true

func stop() -> void:
	_particles.emitting = false
