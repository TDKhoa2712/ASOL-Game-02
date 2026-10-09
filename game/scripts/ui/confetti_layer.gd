# confetti_layer.gd — Falling confetti particles for win screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _count: int = 40
var _particles: Array[ColorRect] = []

func _init(count: int = 40) -> void:
	_count = count
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1

func start() -> void:
	if not LayoutTokens.motion_enabled:
		return
	var sw := size.x if size.x > 0 else 1080.0
	var sh := size.y if size.y > 0 else 1920.0
	for i in range(_count):
		var p := ColorRect.new()
		var w: float = 12.0 + fmod(_pseudo_random(i + 1) * 14.0, 14.0)
		var h: float = w * (2.2 if _pseudo_random(i + 50) > 0.5 else 1.2)
		p.custom_minimum_size = Vector2(w, h)
		p.size = Vector2(w, h)
		p.color = Palette.CONFETTI_COLORS[i % Palette.CONFETTI_COLORS.size()]
		p.position = Vector2(_pseudo_random(i + 3) * sw, -120.0)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_particles.append(p)
		var duration: float = 3.2 + _pseudo_random(i + 7) * 3.0
		var delay: float = _pseudo_random(i + 11) * 3.0
		var drift_x: float = (_pseudo_random(i + 20) - 0.5) * 160.0
		var tw := p.create_tween().set_loops()
		tw.tween_interval(delay)
		tw.tween_property(p, "position:y", sh + 120.0, duration).from(-120.0).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(p, "position:x", p.position.x + drift_x, duration).set_trans(Tween.TRANS_LINEAR)
		tw.parallel().tween_property(p, "rotation", TAU * 2.0, duration).from(0.0).set_trans(Tween.TRANS_LINEAR)

func _pseudo_random(seed_val: int) -> float:
	var x: float = sin(float(seed_val) * 9301.0 + 49297.0) * 233280.0
	return x - floorf(x)
