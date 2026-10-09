# title_hero_mascot.gd — Mascot, speech bubble, and ground shadow for Home screen.
extends VBoxContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _bubble: PanelContainer
var _mascot: TextureRect
var _shadow: _GroundShadow

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 1. Speech bubble
	var bubble_wrapper := VBoxContainer.new()
	bubble_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	bubble_wrapper.add_theme_constant_override("separation", 0)
	add_child(bubble_wrapper)

	_bubble = PanelContainer.new()
	_bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color.WHITE
	b_style.set_corner_radius_all(24)
	b_style.shadow_color = Color("#EFD27E")
	b_style.shadow_size = 7
	b_style.shadow_offset = Vector2(0, 6)
	b_style.content_margin_left = 32
	b_style.content_margin_right = 32
	b_style.content_margin_top = 14
	b_style.content_margin_bottom = 14
	_bubble.add_theme_stylebox_override("panel", b_style)
	bubble_wrapper.add_child(_bubble)

	var text_lbl := Label.new()
	var raw_text := tr("title.mascot_bubble")
	text_lbl.text = raw_text if raw_text != "title.mascot_bubble" else "Giải đố cùng mình nhé!"
	text_lbl.add_theme_font_size_override("font_size", 28)
	text_lbl.add_theme_color_override("font_color", Color("#23365E"))
	var bold := FontTokens.body_bold()
	if bold != null: text_lbl.add_theme_font_override("font", bold)
	_bubble.add_child(text_lbl)

	var tail := _TailTriangle.new()
	tail.custom_minimum_size = Vector2(28, 14)
	tail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble_wrapper.add_child(tail)

	# 2. Mascot & ground shadow container
	var mascot_box := VBoxContainer.new()
	mascot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mascot_box.add_theme_constant_override("separation", -8)
	add_child(mascot_box)

	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/home/mascot_home.svg") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(480, 310)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(_mascot)

	_shadow = _GroundShadow.new()
	_shadow.custom_minimum_size = Vector2(260, 36)
	_shadow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot_box.add_child(_shadow)

func _ready() -> void:
	if not LayoutTokens.motion_enabled: return
	_bubble.pivot_offset = _bubble.size * 0.5
	_mascot.pivot_offset = _mascot.size * 0.5
	var tw := _mascot.create_tween().set_loops()
	tw.tween_property(_mascot, "position:y", _mascot.position.y - 10.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_shadow, "scale", Vector2(0.92, 0.92), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_mascot, "position:y", _mascot.position.y, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(_shadow, "scale", Vector2(1.0, 1.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

class _TailTriangle extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = [
			Vector2(0, 0),
			Vector2(size.x, 0),
			Vector2(size.x * 0.5, size.y),
		]
		draw_colored_polygon(pts, Color.WHITE)

class _GroundShadow extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = []
		var count: int = 32
		var rx: float = size.x * 0.5
		var ry: float = size.y * 0.5
		var center := Vector2(rx, ry)
		for i in range(count):
			var a: float = (float(i) / float(count)) * TAU
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(0.78, 0.59, 0.16, 0.28))
