# stat_card.gd — Stats display card (time, mistakes) for result screens.
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

func _init(stats: Array[Dictionary], shadow_color: Color = Color("#EFD27E")) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 96)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(28)
	style.shadow_color = shadow_color
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 7)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)

	var use_grid := stats.size() > 1
	var container: Control
	if use_grid:
		var grid := HBoxContainer.new()
		grid.add_theme_constant_override("separation", 16)
		container = grid
	else:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 16)
		container = hbox
	add_child(container)

	for i in range(stats.size()):
		var stat: Dictionary = stats[i]
		if i > 0 and use_grid:
			var sep := _DashedSeparator.new(Palette.WIN_DASHED_BORDER)
			container.add_child(sep)
		var item := _create_stat_item(stat)
		if use_grid:
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(item)

func _create_stat_item(stat: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(80, 80); icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var is_clock: bool = stat.get("icon", "") == "clock"
	var ib_style := StyleBoxFlat.new()
	ib_style.bg_color = Palette.WIN_STAT_ICON_BG_TIME if is_clock else Palette.WIN_STAT_ICON_BG_ERR
	ib_style.set_corner_radius_all(24)
	ib_style.shadow_color = Palette.WIN_STAT_ICON_SHADOW_TIME if is_clock else Palette.WIN_STAT_ICON_SHADOW_ERR
	ib_style.shadow_size = 4
	ib_style.shadow_offset = Vector2(0, 4)
	icon_box.add_theme_stylebox_override("panel", ib_style)
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_draw := _StatIcon.new(is_clock)
	icon_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon_draw)
	hbox.add_child(icon_box)

	var text_col := VBoxContainer.new()
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = str(stat.get("label", ""))
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color("#64748B"))
	var bold := FontTokens.body_bold()
	if bold != null:
		lbl.add_theme_font_override("font", bold)
	text_col.add_child(lbl)

	var val := Label.new()
	val.text = str(stat.get("value", ""))
	val.add_theme_font_size_override("font_size", 48)
	val.add_theme_color_override("font_color", Color("#1E293B"))
	var heading := FontTokens.heading()
	if heading != null:
		val.add_theme_font_override("font", heading)
	text_col.add_child(val)

	hbox.add_child(text_col)
	return hbox

func animate(delay: float = 1.1) -> void:
	if not LayoutTokens.motion_enabled:
		return
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.25)

class _DashedSeparator extends Control:
	var _col: Color

	func _init(col: Color) -> void:
		_col = col
		custom_minimum_size = Vector2(2, 0)
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var dash := 6.0
		var gap := 5.0
		var y := 4.0
		while y < size.y - 4.0:
			var end := minf(y + dash, size.y - 4.0)
			draw_line(Vector2(1, y), Vector2(1, end), _col, 2.0)
			y = end + gap

class _StatIcon extends Control:
	var _clock: bool = true

	func _init(is_clock: bool) -> void:
		_clock = is_clock

	func _draw() -> void:
		var center := size * 0.5
		if _clock:
			var col := Color("#2C78B8")
			draw_arc(center, 17.0, 0, TAU, 32, col, 3.5, true)
			draw_line(center, center + Vector2(0, -9.0), col, 3.5)
			draw_line(center, center + Vector2(6.0, 4.0), col, 3.5)
		else:
			var col := Color("#D04A2B")
			draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), col, 4.0, true)
			draw_line(center + Vector2(9.0, -9.0), center + Vector2(-9.0, 9.0), col, 4.0, true)
