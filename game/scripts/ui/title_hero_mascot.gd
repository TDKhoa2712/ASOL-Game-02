# title_hero_mascot.gd — Mascot, speech bubble, and ground shadow for Home screen.
extends VBoxContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const CandyCharacterScene = preload("res://scenes/components/candy_character.tscn")

var _bubble: PanelContainer
var bubble: PanelContainer:
	get: return _bubble
var mascot: CandyCharacter
var _candy_host: Control
var _text_lbl: Label
var _poke_count := 0
var _poke_token := 0

const IDLE_EXPRESSION := "wink"
const IDLE_TEXT_KEY := "title.mascot_bubble"
const RESET_DELAY := 2.6
# [expression, bubble text key, celebrate flip]
const REACTIONS := [["surprised", "title.mascot_poke_1", false], ["heart", "title.mascot_poke_2", false], ["happy", "title.mascot_poke_3", true]]

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
	_text_lbl = text_lbl
	text_lbl.text = _line(IDLE_TEXT_KEY)
	text_lbl.add_theme_font_size_override("font_size", 28)
	text_lbl.add_theme_color_override("font_color", Color("#23365E"))
	var bold := FontTokens.body_bold()
	if bold != null: text_lbl.add_theme_font_override("font", bold)
	_bubble.add_child(text_lbl)

	var tail := _TailTriangle.new()
	tail.custom_minimum_size = Vector2(28, 14)
	tail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble_wrapper.add_child(tail)

	# 2. Mascot Host container
	_candy_host = Control.new()
	_candy_host.custom_minimum_size = Vector2(480, 310)
	_candy_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_candy_host.name = "MascotHost"
	_candy_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_candy_host.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_candy_host.gui_input.connect(_on_host_input)
	add_child(_candy_host)

	mascot = CandyCharacterScene.instantiate()
	mascot.position = Vector2(240, 155)
	mascot.scale = Vector2(0.85, 0.85)
	mascot.expression = IDLE_EXPRESSION
	mascot.idle_style = "hop" if LayoutTokens.motion_enabled else "none"
	_candy_host.add_child(mascot)

func _ready() -> void:
	if not LayoutTokens.motion_enabled: return
	_bubble.pivot_offset = _bubble.size * 0.5
	var tw := _bubble.create_tween().set_loops()
	tw.tween_property(_bubble, "position:y", _bubble.position.y - 4.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_bubble, "position:y", _bubble.position.y, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func bubble_text() -> String: return _text_lbl.text

func _line(key: String) -> String:
	var t := tr(key)
	return "Giải đố cùng mình nhé!" if t == key and key == IDLE_TEXT_KEY else t

func _on_host_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		poke()
		accept_event()

## Tap reaction: cycles surprised → heart → celebrate flip, then settles back to idle.
func poke() -> int:
	var idx := _poke_count % REACTIONS.size()
	_poke_count += 1
	_poke_token += 1
	var r: Array = REACTIONS[idx]
	_text_lbl.text = _line(r[1])
	if mascot == null: return idx
	mascot.expression = r[0]
	if not is_inside_tree() or not LayoutTokens.motion_enabled: return idx
	if r[2]: mascot.celebrate()
	else: _squish()
	_pop_bubble()
	var token := _poke_token
	get_tree().create_timer(RESET_DELAY).timeout.connect(func(): _settle(token))
	return idx

func _squish() -> void:
	var base := mascot.scale
	var tw := mascot.create_tween()
	tw.tween_property(mascot, "scale", base * Vector2(1.18, 0.82), 0.08)
	tw.tween_property(mascot, "scale", base, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _pop_bubble() -> void:
	_bubble.pivot_offset = Vector2(_bubble.size.x * 0.5, _bubble.size.y)
	_bubble.scale = Vector2(0.85, 0.85)
	_bubble.create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _settle(token: int) -> void:
	if token != _poke_token or not is_instance_valid(mascot): return
	mascot.expression = IDLE_EXPRESSION
	_text_lbl.text = _line(IDLE_TEXT_KEY)
	_pop_bubble()

class _TailTriangle extends Control:
	func _draw() -> void:
		var pts: PackedVector2Array = [
			Vector2(0, 0),
			Vector2(size.x, 0),
			Vector2(size.x * 0.5, size.y),
		]
		draw_colored_polygon(pts, Color.WHITE)
