# Tutorial speech bubble placed between the rule cards and the board.
# It never sits over the board, and only its buttons take touches, so board
# taps and drags pass through untouched (RST-027).
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

signal primary_pressed()
signal skip_pressed()

const TEXT_SIZE := 26
const BUTTON_SIZE := 22
const MIN_HEIGHT := 112.0
const FADE_SEC := 0.15

var _label: Label
var _primary: Button
var _skip: Button
var _tween: Tween = null

func _init() -> void:
	name = "CoachBubble"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0, MIN_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Palette.BOARD_GOLD_EDGE
	sb.set_border_width_all(4)
	sb.border_width_bottom = 8
	sb.set_corner_radius_all(24)
	sb.content_margin_left = 20; sb.content_margin_right = 14
	sb.content_margin_top = 10; sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	_label = Label.new()
	_label.name = "CoachText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_label.add_theme_color_override("font_color", Palette.BOARD_NAVY)
	var bf := FontTokens.body_bold()
	if bf != null: _label.add_theme_font_override("font", bf)
	row.add_child(_label)
	var buttons := VBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	row.add_child(buttons)
	_primary = _make_button("CoachPrimary", Palette.BOARD_HINT_BG, Palette.BOARD_HINT_EDGE, Palette.BOARD_HINT_ICON)
	_primary.pressed.connect(func() -> void: primary_pressed.emit())
	buttons.add_child(_primary)
	_skip = _make_button("CoachSkip", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_NAVY_SOFT)
	_skip.text = tr("tutorial.skip")
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	buttons.add_child(_skip)
	modulate.a = 0.0

# text is already translated. An empty button_text hides the primary button.
func show_message(text: String, button_text: String = "", skippable: bool = false) -> void:
	_label.text = text
	_primary.visible = not button_text.is_empty()
	_primary.text = button_text
	_skip.visible = skippable
	_fade_to(1.0)

func clear() -> void:
	_primary.visible = false
	_skip.visible = false
	_fade_to(0.0)

func is_showing() -> bool:
	return modulate.a > 0.0 and not _label.text.is_empty()

func message() -> String:
	return _label.text

func _fade_to(alpha: float) -> void:
	if _tween != null: _tween.kill()
	if alpha == 0.0: _label.text = ""
	# The container owns position, so motion is a fade; reduced motion snaps.
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, FADE_SEC)

func _make_button(node_name: String, bg: Color, edge: Color, fg: Color) -> Button:
	var b := Button.new()
	b.name = node_name
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", BUTTON_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, fg)
	var bf := FontTokens.body_bold()
	if bf != null: b.add_theme_font_override("font", bf)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = edge
		sb.set_border_width_all(2)
		sb.border_width_bottom = 2 if state == "pressed" else 5
		sb.set_corner_radius_all(16)
		sb.content_margin_left = 14; sb.content_margin_right = 14
		b.add_theme_stylebox_override(state, sb)
	return b
