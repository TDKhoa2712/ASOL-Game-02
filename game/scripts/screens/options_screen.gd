# options_screen.gd
extends Control

signal back_pressed()
signal restart_pressed()

const ConfigStore = preload("res://scripts/state/config_store.gd")
const PillToggle = preload("res://scripts/screens/pill_toggle.gd")
const Palette = preload("res://scripts/theme/palette.gd")

const LABELS := {
	"audio": "Âm thanh",
	"haptic": "Rung phản hồi",
	"reduced_motion": "Giảm chuyển động",
	"large_text": "Cỡ chữ lớn",
	"high_contrast": "Độ tương phản cao",
	"colorblind": "Hỗ trợ phân biệt màu",
	"undo_x": "Hoàn tác X",
}

const TILE_KEYS_GRID := ["audio", "haptic", "reduced_motion", "large_text"]
const WIDE_KEYS: Array[String] = ["high_contrast", "colorblind", "undo_x"]

var _config: Variant = null
var _built: bool = false
var _layout_ready: bool = false

var back_btn: Button
var restart_btn: Button
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
	card.name = "OptionsCard"
	card.custom_minimum_size = Vector2(720, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Palette.SURFACE_WARM
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
	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer_l)
	var title := Label.new()
	title.text = "CÀI ĐẶT"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Palette.INK)
	title_bar.add_child(title)
	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer_r)

	vbox = VBoxContainer.new()
	vbox.name = "OptionsList"
	vbox.add_theme_constant_override("separation", 14)
	stack.add_child(vbox)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	stack.add_child(btn_row)

	back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "Quay lại"
	back_btn.custom_minimum_size = Vector2(200, 56)
	back_btn.add_theme_font_size_override("font_size", 24)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Palette.CORAL
	back_style.set_corner_radius_all(16)
	back_style.set_content_margin_all(10)
	for state in ["normal", "hover", "pressed", "focus"]:
		back_btn.add_theme_stylebox_override(state, back_style)
	back_btn.add_theme_color_override("font_color", Palette.TEXT_ON_ACCENT)
	btn_row.add_child(back_btn)

	restart_btn = Button.new()
	restart_btn.name = "RestartBtn"
	restart_btn.text = "Bắt đầu lại"
	restart_btn.custom_minimum_size = Vector2(200, 56)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.visible = false
	var restart_style := StyleBoxFlat.new()
	restart_style.bg_color = Color.TRANSPARENT
	restart_style.border_color = Palette.INK_LIGHT
	restart_style.set_border_width_all(2)
	restart_style.set_corner_radius_all(16)
	restart_style.set_content_margin_all(10)
	for state in ["normal", "hover", "pressed", "focus"]:
		restart_btn.add_theme_stylebox_override(state, restart_style)
	restart_btn.add_theme_color_override("font_color", Palette.INK)
	btn_row.add_child(restart_btn)

func _ready() -> void:
	_ensure_nodes()
	if back_btn != null and not back_btn.pressed.is_connected(_on_back):
		back_btn.pressed.connect(_on_back)
	if restart_btn != null and not restart_btn.pressed.is_connected(_on_restart):
		restart_btn.pressed.connect(_on_restart)
	_build_rows()

func setup(config: Variant) -> void:
	_config = config
	_built = false
	_ensure_nodes()
	_build_rows()

func show_restart(visible_flag: bool) -> void:
	if restart_btn != null:
		restart_btn.visible = visible_flag

func _build_rows() -> void:
	if vbox == null or _config == null or _built:
		return
	for child in vbox.get_children():
		child.queue_free()

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	for key in TILE_KEYS_GRID:
		grid.add_child(_make_tile(key, true))

	for key in WIDE_KEYS:
		vbox.add_child(_make_tile(key, false))
	_built = true

func _make_tile(key: String, is_square: bool) -> PanelContainer:
	var tile := PanelContainer.new()
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Palette.SURFACE_TILE
	tile_style.set_corner_radius_all(20)
	tile_style.set_content_margin_all(14)
	tile.add_theme_stylebox_override("panel", tile_style)
	if is_square:
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var col: BoxContainer
	if is_square:
		col = VBoxContainer.new()
	else:
		col = HBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	if is_square:
		col.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_path: String = {
		"audio": "res://assets/ui/icons/icon_sound.svg",
		"haptic": "res://assets/ui/icons/icon_haptic.svg",
		"reduced_motion": "res://assets/ui/icons/icon_motion.svg",
		"large_text": "res://assets/ui/icons/icon_text_size.svg",
	}.get(key, "")

	var icon_tex: TextureRect = null
	if icon_path != "":
		icon_tex = TextureRect.new()
		icon_tex.texture = load(icon_path) as Texture2D
		icon_tex.custom_minimum_size = Vector2(36, 36)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(icon_tex)

	var lbl := Label.new()
	lbl.text = LABELS.get(key, key)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Palette.INK)
	if is_square:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	var toggle := PillToggle.new()
	toggle.set_on(bool(_config.get_option(key)))
	if icon_tex != null:
		toggle.icon_target = icon_tex
	toggle.toggled_value.connect(func(on: bool): _on_toggle(key, on))
	col.add_child(toggle)

	tile.add_child(col)
	return tile

func _on_toggle(key: String, on: bool) -> void:
	if _config != null:
		_config.set_option(key, on)

func _on_back() -> void:
	back_pressed.emit()

func _on_restart() -> void:
	restart_pressed.emit()
