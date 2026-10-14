# win_next_preview.gd — Mini-board thumbnail and difficulty colour for the win screen "next up" card.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

static func build_mini_board(next_size: int) -> Control:
	var mini_host := Control.new()
	mini_host.custom_minimum_size = Vector2(148, 148)
	mini_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var mini_wrap := PanelContainer.new()
	mini_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mini_wrap.pivot_offset = Vector2(74, 74)
	mini_wrap.rotation = deg_to_rad(-6.0)
	var mg_style := StyleBoxFlat.new()
	mg_style.bg_color = Palette.WIN_NEXT_BOARD_BG; mg_style.set_corner_radius_all(28)
	mg_style.shadow_color = Palette.WIN_NEXT_BOARD_SHADOW; mg_style.shadow_size = 5; mg_style.shadow_offset = Vector2(0, 4)
	mini_wrap.add_theme_stylebox_override("panel", mg_style)
	mini_host.add_child(mini_wrap)

	var mini_center := CenterContainer.new()
	mini_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mini_center.mouse_filter = Control.MOUSE_FILTER_IGNORE; mini_wrap.add_child(mini_center)

	var mini_grid := GridContainer.new()
	var cols: int = clampi(next_size, 4, 12) if next_size > 0 else 4
	mini_grid.columns = cols
	var gap: int = 3 if cols <= 6 else 2
	mini_grid.add_theme_constant_override("h_separation", gap); mini_grid.add_theme_constant_override("v_separation", gap)
	var cell_side: float = maxf(6.0, floor((120.0 - (cols - 1) * gap) / float(cols)))
	var pcols: Array[Color] = [Color("#38BDF8"), Color("#FBBF24"), Color("#FB923C"), Color("#34D399"), Color("#F5E8C8")]
	var pattern: Array[int] = [4, 0, 4, 4, 4, 3, 1, 4, 4, 4, 1, 2, 2, 4, 4, 1]
	for ci in range(cols * cols):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(cell_side, cell_side)
		var cs := StyleBoxFlat.new()
		var col_idx: int = pattern[ci % 16] if cols == 4 else ((ci * 3 + 1) % 4)
		cs.bg_color = pcols[col_idx]; cs.set_corner_radius_all(maxi(2, int(cell_side * 0.25)))
		cell.add_theme_stylebox_override("panel", cs)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE; mini_grid.add_child(cell)
	mini_center.add_child(mini_grid)
	return mini_host

static func difficulty_color(d: String) -> Color:
	if d in ["tutorial", "easy"]: return Palette.WIN_DIFFICULTY_EASY
	if d == "medium": return Palette.WIN_DIFFICULTY_MEDIUM
	return Color("#BE185D") if d == "hard" else Palette.WIN_TEXT_SECONDARY

static func build_info(header_text: String, next_label: String, difficulty_text: String, difficulty: String, next_size: int) -> VBoxContainer:
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)

	var next_hdr := Label.new()
	next_hdr.name = "NextLabel"; next_hdr.text = header_text
	next_hdr.add_theme_font_size_override("font_size", 28); next_hdr.add_theme_color_override("font_color", Color("#64748B"))
	var bold := FontTokens.body_bold()
	if bold != null: next_hdr.add_theme_font_override("font", bold)
	info.add_child(next_hdr)

	var title := Label.new()
	title.name = "NextTitle"; title.text = next_label
	title.add_theme_font_size_override("font_size", 60); title.add_theme_color_override("font_color", Color("#1E293B"))
	var hfont := FontTokens.heading()
	if hfont != null: title.add_theme_font_override("font", hfont)
	info.add_child(title)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12); info.add_child(meta_row)

	var diff_lbl := Label.new()
	diff_lbl.name = "NextDiff"; diff_lbl.text = difficulty_text
	diff_lbl.add_theme_font_size_override("font_size", 26); diff_lbl.add_theme_color_override("font_color", Color.WHITE)
	if bold != null: diff_lbl.add_theme_font_override("font", bold)
	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = difficulty_color(difficulty); dp_style.set_corner_radius_all(999)
	dp_style.content_margin_left = 16; dp_style.content_margin_right = 16; dp_style.content_margin_top = 4; dp_style.content_margin_bottom = 4
	diff_lbl.add_theme_stylebox_override("normal", dp_style); meta_row.add_child(diff_lbl)

	var size_lbl := Label.new()
	size_lbl.name = "NextSize"
	size_lbl.text = "%dx%d" % [next_size, next_size] if next_size > 0 else ""
	size_lbl.add_theme_font_size_override("font_size", 28); size_lbl.add_theme_color_override("font_color", Color("#64748B"))
	if bold != null: size_lbl.add_theme_font_override("font", bold)
	meta_row.add_child(size_lbl)
	return info
