class_name PillSwitch
extends Button

@export var on_color := Color("5DBB74")
@export var off_color := Color("C9B8AD")
@export var knob_color := Color.WHITE
@export var pill_size := Vector2(64, 30)
@export var on_text := "ON"
@export var off_text := "OFF"
@export var font_size_px := 12
@export var icon_target: TextureRect
@export var icon_on_color := Color("6D4A45")
@export var icon_off_color := Color("B9A79C")

var _t: float = 0.0 # 0 = OFF, 1 = ON
var _tween: Tween


func _init() -> void:
	toggle_mode = true
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = pill_size + Vector2(8, 14)


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = pill_size + Vector2(8, 14)
	if icon_target == null and get_parent() != null:
		for child in get_parent().get_children():
			if child is TextureRect:
				icon_target = child
				break
	_t = 1.0 if button_pressed else 0.0
	_update_icon_tint(button_pressed)
	toggled.connect(_on_toggled)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _on_toggled(pressed_val: bool) -> void:
	_update_icon_tint(pressed_val)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_t := 1.0 if pressed_val else 0.0
	_tween.tween_method(_set_t, _t, target_t, 0.15)


func _set_t(v: float) -> void:
	_t = v
	queue_redraw()


func _update_icon_tint(is_on: bool) -> void:
	if icon_target != null:
		icon_target.modulate = icon_on_color if is_on else icon_off_color


func sync_state() -> void:
	_t = 1.0 if button_pressed else 0.0
	_update_icon_tint(button_pressed)
	queue_redraw()


func _draw() -> void:
	var r := Rect2((size - pill_size) * 0.5, pill_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = off_color.lerp(on_color, _t)
	sb.set_corner_radius_all(int(pill_size.y * 0.5))
	draw_style_box(sb, r)

	var pad := 3.0
	var d := pill_size.y - pad * 2.0
	var kx := lerpf(r.position.x + pad, r.end.x - pad - d, _t)
	draw_circle(Vector2(kx + d * 0.5, r.position.y + pill_size.y * 0.5), d * 0.5, knob_color)

	var font: Font = null
	if ThemeDB.fallback_font != null:
		font = ThemeDB.fallback_font
	else:
		font = get_theme_default_font()

	if font != null:
		var txt := on_text if _t >= 0.5 else off_text
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_px)
		var tx := (r.position.x + 9.0) if _t >= 0.5 else (r.end.x - 9.0 - ts.x)
		var baseline := r.position.y + pill_size.y * 0.5 + (font.get_ascent(font_size_px) - font.get_descent(font_size_px)) * 0.5
		draw_string(font, Vector2(tx, baseline), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_px, Color.WHITE)
