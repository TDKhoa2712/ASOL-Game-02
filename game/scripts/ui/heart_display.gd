# heart_display.gd — Row of 3 animated hearts for result screens.
extends HBoxContainer

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _total: int = 3
var _filled: int = 0
var _style: String = "win"

func _init(total: int = 3, filled: int = 3, style: String = "win") -> void:
	_total = total
	_filled = clampi(filled, 0, total)
	_style = style
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 18)
	for i in range(_total):
		var is_middle := (i == 1)
		var size := 154.0 if is_middle else 126.0
		var heart := _create_heart(i, size, i < _filled)
		add_child(heart)

func _create_heart(index: int, heart_size: float, is_filled: bool) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(heart_size, heart_size)
	container.pivot_offset = Vector2(heart_size * 0.5, heart_size * 0.5)
	if index == 0:
		container.rotation_degrees = -8.0
		container.size_flags_vertical = Control.SIZE_SHRINK_END
	elif index == 2:
		container.rotation_degrees = 8.0
		container.size_flags_vertical = Control.SIZE_SHRINK_END
	else:
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var tex := TextureRect.new()
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _style == "lose":
		tex.texture = preload("res://assets/ui/result/heart_broken.svg")
	elif is_filled:
		tex.texture = preload("res://assets/ui/board/heart_icon.png")
	else:
		tex.texture = preload("res://assets/ui/board/heart_icon_empty.png")
		tex.modulate = Color(1.4, 1.4, 1.45, 0.95)
	container.add_child(tex)

	return container

func animate() -> void:
	if not LayoutTokens.motion_enabled:
		return
	for i in range(get_child_count()):
		var heart := get_child(i) as Control
		if heart == null:
			continue
		heart.scale = Vector2.ZERO
		heart.modulate.a = 0.0
		var delay: float = 0.55 + i * 0.25
		var tw := heart.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(heart, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(heart, "modulate:a", 1.0, 0.15)
		tw.tween_property(heart, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
		if i < _filled and _style == "win":
			_add_heartbeat(heart, delay + 2.0)

func _add_heartbeat(heart: Control, start_delay: float) -> void:
	var tw := heart.create_tween().set_loops()
	tw.tween_interval(start_delay)
	tw.tween_property(heart, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2(0.96, 0.96), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2(1.06, 1.06), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(heart, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.48)
