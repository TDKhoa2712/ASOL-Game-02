extends PanelContainer

signal hint_applied()
signal hint_dismissed()
signal detail_requested()

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

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

	var banner := HBoxContainer.new()
	banner.add_theme_constant_override("separation", 8)
	vbox.add_child(banner)

	_label_icon = Label.new()
	_label_icon.add_theme_font_size_override("font_size", 28)
	banner.add_child(_label_icon)

	_label_text = Label.new()
	_label_text.add_theme_font_size_override("font_size", 22)
	_label_text.add_theme_color_override("font_color", Palette.INK)
	_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_child(_label_text)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_apply_btn = Button.new()
	_apply_btn.custom_minimum_size = Vector2(120, 40)
	_apply_btn.pressed.connect(_on_apply)
	btn_row.add_child(_apply_btn)

	_detail_btn = Button.new()
	_detail_btn.text = tr("hint.detail")
	_detail_btn.custom_minimum_size = Vector2(100, 40)
	_detail_btn.pressed.connect(_on_detail)
	_detail_btn.visible = false
	btn_row.add_child(_detail_btn)

	_dismiss_btn = Button.new()
	_dismiss_btn.custom_minimum_size = Vector2(100, 40)
	_dismiss_btn.pressed.connect(_on_dismiss)
	btn_row.add_child(_dismiss_btn)

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
	_apply_btn.text = _apply_label_for(strategy)
	_dismiss_btn.text = "✕"
	_detail_btn.text = tr("hint.detail")
	_detail_btn.visible = strategy == "CONTRA_CHAIN" and hint.has("chain_detail")
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
		"MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET": return "✕"
		"SINGLE_CANDIDATE", "FALLBACK": return "🍬"
		"CONTRA_CHAIN": return "🔗"
	return ""

func _apply_label_for(strategy: String) -> String:
	match strategy:
		"WRONG_MARK": return tr("hint.clear_mark")
		"SINGLE_CANDIDATE": return tr("hint.place_candy")
		"FALLBACK": return tr("hint.reveal")
	return tr("hint.mark_x")
