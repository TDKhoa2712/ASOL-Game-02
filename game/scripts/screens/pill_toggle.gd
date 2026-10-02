# pill_toggle.gd
extends Button

signal toggled_value(on: bool)

const Palette = preload("res://scripts/theme/palette.gd")

var _on: bool = false

func _init() -> void:
	toggle_mode = true
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(72, 44)
	toggled.connect(_on_toggled)

func _ready() -> void:
	queue_redraw()

func set_on(value: bool) -> void:
	if _on != value:
		_on = value
		button_pressed = value
		queue_redraw()

func is_on() -> bool:
	return _on

func _on_toggled(pressed_val: bool) -> void:
	_on = pressed_val
	toggled_value.emit(_on)
	queue_redraw()

func _draw() -> void:
	var pill_size := Vector2(66, 38)
	var r := Rect2((size - pill_size) * 0.5, pill_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BTN_PRIMARY if _on else Palette.DIVIDER
	sb.set_corner_radius_all(int(pill_size.y * 0.5))
	draw_style_box(sb, r)

	var pad := 3.0
	var knob_diam := pill_size.y - pad * 2.0
	var radius := knob_diam * 0.5
	var cx := (r.end.x - pad - radius) if _on else (r.position.x + pad + radius)
	var cy := r.position.y + pill_size.y * 0.5
	draw_circle(Vector2(cx, cy), radius, Color.WHITE)
