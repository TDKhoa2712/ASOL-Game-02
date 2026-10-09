# language_select_dialog.gd
class_name LanguageSelectDialog
extends Control

signal language_selected(locale: String)
signal closed()

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LocaleResolver = preload("res://scripts/core/locale_resolver.gd")

var _current_locale: String = ""
var _options_container: VBoxContainer
var _buttons: Dictionary = {}

func _init(current_locale: String = "") -> void:
	_current_locale = current_locale

func _ready() -> void:
	_build_ui()

func setup(current_locale: String) -> void:
	_current_locale = current_locale
	_refresh_selection()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Palette.SCRIM
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.name = "LanguageCard"
	card.custom_minimum_size = Vector2(620, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Palette.SURFACE_WARM
	card_style.set_corner_radius_all(28)
	card_style.set_content_margin_all(24)
	card_style.shadow_color = Palette.CARD_SHADOW
	card_style.shadow_size = 16
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	card.add_child(stack)

	var title := Label.new()
	title.text = tr("settings.language")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK)
	var h_font := FontTokens.heading()
	if h_font != null:
		title.add_theme_font_override("font", h_font)
	stack.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)

	_options_container = VBoxContainer.new()
	_options_container.name = "OptionsContainer"
	_options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_options_container)

	_populate_options()

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = tr("settings.back")
	close_btn.custom_minimum_size = Vector2(180, 52)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 22)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Palette.CORAL
	close_style.set_corner_radius_all(14)
	close_style.set_content_margin_all(10)
	for st in ["normal", "hover", "pressed", "focus"]:
		close_btn.add_theme_stylebox_override(st, close_style)
	close_btn.add_theme_color_override("font_color", Palette.TEXT_ON_ACCENT)
	close_btn.pressed.connect(_on_close)
	stack.add_child(close_btn)

func _populate_options() -> void:
	_buttons.clear()
	var options := LocaleResolver.get_options_list()
	for opt in options:
		var loc: String = opt.locale
		var native_title: String = opt.native
		var btn := Button.new()
		btn.name = "LangBtn_" + loc
		btn.custom_minimum_size = Vector2(0, 54) # Safe vertical padding for CJK
		btn.add_theme_font_size_override("font_size", 22)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var b_font := FontTokens.body()
		if b_font != null:
			btn.add_theme_font_override("font", b_font)

		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Palette.SURFACE_TILE
		normal_style.set_corner_radius_all(14)
		normal_style.content_margin_left = 20
		normal_style.content_margin_right = 20
		normal_style.content_margin_top = 10
		normal_style.content_margin_bottom = 10

		var hover_style := normal_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Palette.SURFACE_HOVER

		var pressed_style := normal_style.duplicate() as StyleBoxFlat
		pressed_style.bg_color = Palette.SURFACE_PRESSED

		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		btn.add_theme_color_override("font_color", Palette.INK)

		btn.pressed.connect(func(): _on_option_selected(loc))
		_options_container.add_child(btn)
		_buttons[loc] = btn

	_refresh_selection()

func _refresh_selection() -> void:
	for loc in _buttons:
		var btn: Button = _buttons[loc]
		var native_title: String = LocaleResolver.get_native_name(loc)
		if loc == _current_locale:
			btn.text = "%s  ✓" % native_title
			btn.add_theme_color_override("font_color", Palette.ACCENT_ORANGE)
		else:
			btn.text = native_title
			btn.add_theme_color_override("font_color", Palette.INK)

func _on_option_selected(loc: String) -> void:
	_current_locale = loc
	_refresh_selection()
	language_selected.emit(loc)
	_on_close()

func _on_close() -> void:
	closed.emit()
	queue_free()
