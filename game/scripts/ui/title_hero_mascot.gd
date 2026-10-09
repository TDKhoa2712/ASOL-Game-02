# title_hero_mascot.gd — Mascot and speech bubble hero component for Home screen.
extends VBoxContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _bubble: PanelContainer
var _mascot: TextureRect

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
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
	b_style.set_corner_radius_all(20)
	b_style.shadow_color = Palette.HOME_CARD_SHADOW
	b_style.shadow_size = 6
	b_style.shadow_offset = Vector2(0, 5)
	b_style.content_margin_left = 24
	b_style.content_margin_right = 24
	b_style.content_margin_top = 10
	b_style.content_margin_bottom = 10
	_bubble.add_theme_stylebox_override("panel", b_style)
	bubble_wrapper.add_child(_bubble)

	var text_lbl := Label.new()
	var raw_text := tr("title.mascot_bubble")
	text_lbl.text = raw_text if raw_text != "title.mascot_bubble" else "Giải đố cùng mình nhé!"
	text_lbl.add_theme_font_size_override("font_size", 22)
	text_lbl.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	var bold := FontTokens.body_bold()
	if bold != null: text_lbl.add_theme_font_override("font", bold)
	_bubble.add_child(text_lbl)

	var tail := _TailTriangle.new()
	tail.custom_minimum_size = Vector2(24, 12)
	tail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble_wrapper.add_child(tail)

	# 2. Mascot
	_mascot = TextureRect.new()
	_mascot.texture = load("res://assets/ui/home/mascot_home.svg") as Texture2D
	_mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot.custom_minimum_size = Vector2(400, 250)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_mascot)

func _ready() -> void:
	if not LayoutTokens.motion_enabled: return
	_bubble.pivot_offset = _bubble.size * 0.5
	_mascot.pivot_offset = _mascot.size * 0.5
	var tw := _mascot.create_tween().set_loops()
	tw.tween_property(_mascot, "position:y", _mascot.position.y - 8.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_mascot, "position:y", _mascot.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

class _TailTriangle extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = [
			Vector2(0, 0),
			Vector2(size.x, 0),
			Vector2(size.x * 0.5, size.y),
		]
		draw_colored_polygon(pts, Color.WHITE)
