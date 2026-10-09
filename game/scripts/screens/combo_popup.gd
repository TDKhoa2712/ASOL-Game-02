# combo_popup.gd — one reusable sprite that pops the combo word art over the board.
extends Node2D

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const ATLAS: Texture2D = preload("res://assets/ui/combo/combo_atlas.png")
const FRAME := Vector2(512, 128)
const COLS := 2
const MAX_LEVEL := 12
const SPARKLE_LEVEL := 9
const LIFT := 40.0
const TILT_DEG := 6.0

var _sprite: Sprite2D
var _sparkles: CPUParticles2D
var _tween: Tween
var _level: int = 0

func _init() -> void:
	z_index = 20
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.region_enabled = true
	_sprite.visible = false
	add_child(_sprite)
	_sparkles = CPUParticles2D.new()
	_sparkles.emitting = false
	_sparkles.one_shot = true
	_sparkles.amount = 12
	_sparkles.lifetime = 0.6
	_sparkles.explosiveness = 1.0
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 120.0
	_sparkles.initial_velocity_max = 220.0
	_sparkles.gravity = Vector2(0, 320)
	_sparkles.scale_amount_min = 4.0
	_sparkles.scale_amount_max = 8.0
	_sparkles.color = Color(1.0, 0.86, 0.35)
	add_child(_sparkles)

static func frame_rect(level: int) -> Rect2:
	var index := clampi(level, 1, MAX_LEVEL) - 1
	return Rect2(Vector2(index % COLS, index / COLS) * FRAME, FRAME)

func sprite() -> Sprite2D: return _sprite
func current_level() -> int: return _level
func is_showing() -> bool: return _sprite.visible

func show_combo(level: int, at: Vector2, base_scale: float) -> void:
	if _tween != null: _tween.kill()
	_level = level
	position = at
	_sprite.region_rect = frame_rect(level)
	_sprite.position = Vector2.ZERO
	_sprite.modulate.a = 1.0
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * base_scale
	_sprite.visible = true
	_tween = create_tween()
	if LayoutTokens.motion_enabled:
		_sprite.scale = Vector2.ONE * base_scale * 0.3
		_sprite.rotation = deg_to_rad(TILT_DEG if level % 2 == 1 else -TILT_DEG)
		_tween.tween_property(_sprite, "scale", Vector2.ONE * base_scale * 1.15, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(_sprite, "rotation", 0.0, 0.2)
		_tween.tween_property(_sprite, "scale", Vector2.ONE * base_scale, 0.08)
		_tween.tween_interval(0.33)
		_tween.tween_property(_sprite, "position:y", -LIFT, 0.35).set_ease(Tween.EASE_IN)
		_tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.35)
		if level >= SPARKLE_LEVEL: _sparkles.restart()
	else:
		_tween.tween_interval(0.5)
		_tween.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(hide_combo)

func hide_combo() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_tween = null
	_sprite.visible = false
	_sparkles.emitting = false
