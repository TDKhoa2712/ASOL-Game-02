extends PanelContainer

signal hint_applied()
signal hint_dismissed()
signal detail_requested()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const FitLabel = preload("res://scripts/ui/fit_label.gd")

var _showing: bool = false
var _label_icon: Label = null
var _label_text: Label = null
var _apply_btn: Button = null
var _dismiss_btn: Button = null
var _detail_btn: Button = null
var _tween: Tween = null

func _init() -> void:
	visible = false

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	if _label_text != null:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(32)
	sb.border_width_bottom = 5
	sb.border_color = Palette.BOARD_GOLD_EDGE
	sb.content_margin_left = 36.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 20.0
	sb.content_margin_bottom = 20.0
	sb.shadow_color = Palette.BOARD_SHADOW
	sb.shadow_size = 8
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var banner := HBoxContainer.new()
	banner.add_theme_constant_override("separation", 8)
	vbox.add_child(banner)

	_label_icon = Label.new()
	_label_icon.add_theme_font_size_override("font_size", 34)
	banner.add_child(_label_icon)

	# Text shrinks to fit so the card always stays inside its fixed slot above the board.
	var fit := FitLabel.new()
	fit.max_font_size = 38
	fit.min_font_size = 16
	fit.max_lines = 3
	_label_text = fit
	_label_text.add_theme_color_override("font_color", Palette.BOARD_NAVY)
	var bf := FontTokens.body_bold()
	if bf != null: _label_text.add_theme_font_override("font", bf)
	_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_child(_label_text)

	# Detail and close sit beside the text so the card stays as short as the rule row.
	var btn_row := banner

	# Big apply pill; the layout moves it into the dock area under the board.
	_apply_btn = Button.new()
	_apply_btn.name = "HintApplyBtn"
	_apply_btn.custom_minimum_size = Vector2(600, 120)
	_apply_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_button(_apply_btn, Palette.ACCENT_ORANGE, Palette.ACCENT_ORANGE.darkened(0.3), Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		_apply_btn.get_theme_stylebox(state).set_corner_radius_all(60)
	_apply_btn.add_theme_font_size_override("font_size", 46)
	_apply_btn.visible = false
	_apply_btn.pressed.connect(_on_apply)
	btn_row.add_child(_apply_btn)

	_detail_btn = Button.new()
	_detail_btn.text = tr("hint.detail")
	_detail_btn.custom_minimum_size = Vector2(120, 56)
	_style_button(_detail_btn, Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE)
	_detail_btn.pressed.connect(_on_detail)
	_detail_btn.visible = false
	btn_row.add_child(_detail_btn)

	_dismiss_btn = Button.new()
	_dismiss_btn.custom_minimum_size = Vector2(64, 64)
	_dismiss_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Solid blue so the close button reads clearly against the white card.
	_style_button(_dismiss_btn, Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, Color.WHITE)
	_dismiss_btn.add_theme_font_size_override("font_size", 34)
	_dismiss_btn.pressed.connect(_on_dismiss)
	btn_row.add_child(_dismiss_btn)

# Text buttons in the board's chunky 3D style (flat face, darker bottom edge).
static func _style_button(btn: Button, face: Color, edge: Color, ink: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = face
	normal.set_corner_radius_all(16)
	normal.border_width_bottom = 5
	normal.border_color = edge
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = face.lightened(0.06)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 1
	pressed.expand_margin_top = -4.0
	for state in ["normal", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(c, ink)
	btn.add_theme_font_size_override("font_size", 20)
	var bf := FontTokens.body_bold()
	if bf != null: btn.add_theme_font_override("font", bf)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func attach_apply_button(host: Control) -> void:
	_setup_ui()
	_apply_btn.reparent(host, false)

func show_hint(hint: Dictionary) -> void:
	_setup_ui()
	var strategy: String = hint.get("strategy", "")
	_label_icon.text = _icon_for(strategy)
	var raw_text: String = tr(hint.get("explanation_key", ""))
	var params: Array = hint.get("explanation_params", [])
	if not params.is_empty() and "%" in raw_text:
		_label_text.text = raw_text % params
	else:
		_label_text.text = raw_text
	_label_text.refit.call_deferred()  # setting text does not re-measure on its own
	_apply_btn.text = _apply_label_for(strategy)
	_dismiss_btn.text = "×"
	_detail_btn.text = tr("hint.detail")
	_detail_btn.visible = strategy == "CONTRA_CHAIN" and hint.has("chain_detail")
	_showing = true
	visible = true
	_apply_btn.visible = true
	modulate.a = 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()

func dismiss() -> void:
	if not _showing:
		return
	_showing = false
	visible = false
	if _apply_btn != null: _apply_btn.visible = false

func is_showing() -> bool:
	return _showing

func _on_apply() -> void:
	hint_applied.emit()

func _on_dismiss() -> void:
	hint_dismissed.emit()

func _on_detail() -> void:
	detail_requested.emit()

static func _icon_for(strategy: String) -> String:
	match strategy:
		"WRONG_MARK": return "⚠"
		"MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET": return "×"
		"SINGLE_CANDIDATE", "FALLBACK": return "★"
		"CONTRA_CHAIN": return "↔"
	return ""

func _apply_label_for(strategy: String) -> String:
	match strategy:
		"WRONG_MARK": return tr("hint.clear_mark")
		"SINGLE_CANDIDATE": return tr("hint.place_candy")
		"FALLBACK": return tr("hint.reveal")
	return tr("hint.mark_x")
