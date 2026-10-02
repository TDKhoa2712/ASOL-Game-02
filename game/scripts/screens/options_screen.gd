# options_screen.gd
extends Control

signal back_pressed()

const ConfigStore = preload("res://scripts/state/config_store.gd")
const PillToggle = preload("res://scripts/screens/pill_toggle.gd")
const Palette = preload("res://scripts/theme/palette.gd")

const LABELS := {
	"audio": "Âm thanh",
	"haptic": "Rung phản hồi",
	"reduced_motion": "Giảm chuyển động",
	"high_contrast": "Độ tương phản cao",
	"large_text": "Cỡ chữ lớn",
}

var _config: Variant = null
var _built: bool = false
var _layout_ready: bool = false

var back_btn: Button
var vbox: VBoxContainer

func _ensure_nodes() -> void:
	if _layout_ready:
		return
	_layout_ready = true
	var legacy_header := get_node_or_null("Header")
	var legacy_scroll := get_node_or_null("ScrollContainer")
	if legacy_header != null:
		legacy_header.hide()
	if legacy_scroll != null:
		legacy_scroll.hide()
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color("#F8F1EC")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, 38)
	add_child(safe)
	var center := CenterContainer.new()
	safe.add_child(center)
	var card := PanelContainer.new()
	card.name = "OptionsCard"
	card.custom_minimum_size.x = 760
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#FFFBF7")
	card_style.set_corner_radius_all(34)
	card_style.set_content_margin_all(32)
	card_style.shadow_color = Palette.CARD_SHADOW
	card_style.shadow_size = 16
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 20)
	card.add_child(stack)
	var title_bar := HBoxContainer.new()
	stack.add_child(title_bar)
	var title := Label.new()
	title.text = "CÀI ĐẶT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Palette.INK)
	title_bar.add_child(title)
	back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.custom_minimum_size = Vector2(64, 64)
	back_btn.icon = load("res://assets/ui/icons/icon_close.svg") as Texture2D
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.expand_icon = true
	back_btn.tooltip_text = "Đóng cài đặt"
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#FFF0E9")
	close_style.set_corner_radius_all(999)
	for state in ["normal", "hover", "pressed", "focus"]:
		back_btn.add_theme_stylebox_override(state, close_style)
	title_bar.add_child(back_btn)
	var subtitle := Label.new()
	subtitle.text = "Tùy chỉnh trải nghiệm chơi"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Palette.TEXT_STAT)
	stack.add_child(subtitle)
	vbox = VBoxContainer.new()
	vbox.name = "OptionsList"
	vbox.add_theme_constant_override("separation", 12)
	stack.add_child(vbox)

func _ready() -> void:
	_ensure_nodes()
	if back_btn != null and not back_btn.pressed.is_connected(_on_back):
		back_btn.pressed.connect(_on_back)
	_build_rows()

func setup(config: Variant) -> void:
	_config = config
	_built = false
	_ensure_nodes()
	_build_rows()

func _build_rows() -> void:
	if vbox == null or _config == null or _built:
		return
	for child in vbox.get_children():
		child.queue_free()
	for key in ConfigStore.EDITABLE_KEYS:
		var tile := PanelContainer.new()
		var tile_style := StyleBoxFlat.new()
		tile_style.bg_color = Color("#FFF6EE")
		tile_style.set_corner_radius_all(20)
		tile_style.content_margin_left = 18
		tile_style.content_margin_right = 18
		tile_style.content_margin_top = 12
		tile_style.content_margin_bottom = 12
		tile.add_theme_stylebox_override("panel", tile_style)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 56)
		row.add_theme_constant_override("separation", 16)
		var icon_path: String = {
			"audio": "res://assets/ui/icons/icon_sound.svg",
			"haptic": "res://assets/ui/icons/icon_haptic.svg",
			"reduced_motion": "res://assets/ui/icons/icon_motion.svg",
			"large_text": "res://assets/ui/icons/icon_text_size.svg",
		}.get(key, "")
		if icon_path != "":
			var icon := TextureRect.new()
			icon.texture = load(icon_path) as Texture2D
			icon.custom_minimum_size = Vector2(40, 40)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
		var lbl := Label.new()
		lbl.text = LABELS.get(key, key)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Palette.INK)
		row.add_child(lbl)

		var toggle := PillToggle.new()
		toggle.set_on(bool(_config.get_option(key)))
		toggle.toggled_value.connect(func(on: bool): _on_toggle(key, on))
		row.add_child(toggle)

		tile.add_child(row)
		vbox.add_child(tile)
	_built = true

func _on_toggle(key: String, on: bool) -> void:
	if _config != null:
		_config.set_option(key, on)

func _on_back() -> void:
	back_pressed.emit()
