# language_select_dialog.gd
class_name LanguageSelectDialog
extends Control

signal language_selected(locale: String)
signal closed()

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LocaleResolver = preload("res://scripts/core/locale_resolver.gd")
const OverlayStyle = preload("res://scripts/theme/overlay_style.gd")

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
	card.custom_minimum_size = Vector2(OverlayStyle.CARD_WIDTH, 0)
	card.add_theme_stylebox_override("panel", OverlayStyle.card(32, 32))
	center.add_child(card)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	card.add_child(stack)

	var title := Label.new()
	title.text = tr("settings.language")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", OverlayStyle.TITLE_FONT)
	title.add_theme_color_override("font_color", Palette.INK)
	var h_font := FontTokens.heading()
	if h_font != null:
		title.add_theme_font_override("font", h_font)
	stack.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)

	_options_container = VBoxContainer.new()
	_options_container.name = "OptionsContainer"
	_options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_container.add_theme_constant_override("separation", 12)
	scroll.add_child(_options_container)

	_populate_options()

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = tr("settings.back")
	close_btn.custom_minimum_size = Vector2(280, OverlayStyle.BUTTON_HEIGHT)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", OverlayStyle.BODY_FONT)
	OverlayStyle.paint_button(close_btn, OverlayStyle.SELECTED_BG, Palette.TEXT_ON_ACCENT)
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
		btn.custom_minimum_size = Vector2(0, OverlayStyle.BUTTON_HEIGHT) # Safe vertical padding for CJK
		btn.add_theme_font_size_override("font_size", OverlayStyle.BODY_FONT)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var b_font := FontTokens.body()
		if b_font != null:
			btn.add_theme_font_override("font", b_font)


		btn.pressed.connect(func(): _on_option_selected(loc))
		_options_container.add_child(btn)
		_buttons[loc] = btn

	_refresh_selection()

func _refresh_selection() -> void:
	for loc in _buttons:
		var btn: Button = _buttons[loc]
		var native_title: String = LocaleResolver.get_native_name(loc)
		# The current language is a filled row, not just tinted text.
		if loc == _current_locale:
			btn.text = "%s  ✓" % native_title
			OverlayStyle.paint_option(btn, true)
		else:
			btn.text = native_title
			OverlayStyle.paint_option(btn, false)

func _on_option_selected(loc: String) -> void:
	_current_locale = loc
	_refresh_selection()
	language_selected.emit(loc)
	_on_close()

func _on_close() -> void:
	closed.emit()
	queue_free()
