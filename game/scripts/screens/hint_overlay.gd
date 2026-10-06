# hint_overlay.gd
extends PanelContainer

signal dismissed()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _showing: bool = false
var _label_text: Label = null
var _label_unit: Label = null
var _close_btn: Button = null
var _tween: Tween = null

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	if _label_text != null:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE_WARM
	sb.set_corner_radius_all(Palette.CARD_CORNER)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	sb.shadow_color = Palette.CARD_SHADOW
	sb.shadow_size = 6
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	_label_unit = Label.new()
	_label_unit.add_theme_font_size_override("font_size", 28)
	_label_unit.add_theme_color_override("font_color", Palette.ACCENT_ORANGE)
	_label_unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_label_unit)

	_label_text = Label.new()
	_label_text.add_theme_font_size_override("font_size", 22)
	_label_text.add_theme_color_override("font_color", Palette.INK)
	_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_label_text)

	_close_btn = Button.new()
	_close_btn.text = tr("common.ok")
	_close_btn.custom_minimum_size = Vector2(100, 40)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_btn.pressed.connect(_on_close)
	vbox.add_child(_close_btn)

func show_hint(text: String, unit_label: String) -> void:
	_setup_ui()
	_label_text.text = text
	_label_unit.text = unit_label
	_showing = true
	visible = true
	modulate.a = 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()

func dismiss() -> void:
	if not _showing:
		return
	_showing = false
	visible = false
	dismissed.emit()

func is_showing() -> bool:
	return _showing

func _on_close() -> void:
	dismiss()
