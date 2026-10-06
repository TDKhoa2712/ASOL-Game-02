# pill_toggle.gd
extends Button

signal toggled_value(on: bool)

const Palette = preload("res://scripts/theme/palette.gd")

const PILL_SIZE := Vector2(72, 38)
const FONT_SIZE_PILL := 13

var _on: bool = false
var _t: float = 0.0
var _tween: Tween
var icon_target: TextureRect = null

func _init() -> void:
	toggle_mode = true
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = PILL_SIZE + Vector2(8, 14)
	toggled.connect(_on_toggled)

func _ready() -> void:
	if icon_target == null and get_parent() != null:
		for child in get_parent().get_children():
			if child is TextureRect:
				icon_target = child
				break
	_t = 1.0 if _on else 0.0
	_update_icon_tint(_on)
	queue_redraw()

func set_on(value: bool) -> void:
	if _on != value:
		_on = value
		button_pressed = value
		_t = 1.0 if value else 0.0
		_update_icon_tint(value)
		queue_redraw()

func is_on() -> bool:
	return _on

func _on_toggled(pressed_val: bool) -> void:
	_on = pressed_val
	_update_icon_tint(pressed_val)
	toggled_value.emit(_on)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_t := 1.0 if pressed_val else 0.0
	_tween.tween_method(_set_t, _t, target_t, 0.15)

func _set_t(v: float) -> void:
	_t = v
	queue_redraw()

func _update_icon_tint(is_on_val: bool) -> void:
	if icon_target != null:
		icon_target.modulate = Color.WHITE if is_on_val else Color(0.75, 0.75, 0.75, 0.6)

func _draw() -> void:
	var r := Rect2((size - PILL_SIZE) * 0.5, PILL_SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.DIVIDER.lerp(Palette.BTN_PRIMARY, _t)
	sb.set_corner_radius_all(int(PILL_SIZE.y * 0.5))
	draw_style_box(sb, r)

	var pad := 3.0
	var d := PILL_SIZE.y - pad * 2.0
	var kx := lerpf(r.position.x + pad, r.end.x - pad - d, _t)
	draw_circle(Vector2(kx + d * 0.5, r.position.y + PILL_SIZE.y * 0.5), d * 0.5, Palette.TEXT_ON_ACCENT)

	var font: Font = null
	if ThemeDB.fallback_font != null:
		font = ThemeDB.fallback_font
	else:
		font = get_theme_default_font()
	if font != null:
		var txt := "ON" if _t >= 0.5 else "OFF"
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_PILL)
		var tx := (r.position.x + 9.0) if _t >= 0.5 else (r.end.x - 9.0 - ts.x)
		var baseline := r.position.y + PILL_SIZE.y * 0.5 + (font.get_ascent(FONT_SIZE_PILL) - font.get_descent(FONT_SIZE_PILL)) * 0.5
		draw_string(font, Vector2(tx, baseline), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_PILL, Palette.TEXT_ON_ACCENT)
