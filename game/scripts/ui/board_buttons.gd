extends RefCounted

# Chunky 3D board-style buttons and rounded cards shared by the puzzle screen.

static func card_sb(bg: Color, edge: Color, radius: int, depth: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.set_corner_radius_all(radius); sb.border_width_bottom = depth; sb.border_color = edge
	sb.content_margin_left = pad_x; sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y; sb.content_margin_bottom = pad_y
	return sb

static func make_3d_btn(node_name: String, icon_path: String, bg_col: Color, edge_col: Color, icon_col: Color, btn_size: Vector2, radius: int, depth: int, icon_size: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name; btn.custom_minimum_size = btn_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col; normal.set_corner_radius_all(radius)
	normal.border_width_bottom = depth; normal.border_color = edge_col
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.06)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 1; pressed.expand_margin_top = float(-(depth - 1))

	for state in ["normal", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)

	var center := CenterContainer.new()
	center.name = "IconCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(center)

	var icon := TextureRect.new()
	icon.name = "Icon"
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path) as Texture2D
	icon.modulate = icon_col; icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = icon_size; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(icon)

	btn.button_down.connect(func(): icon.position.y += float(depth - 1); icon.modulate = icon_col.darkened(0.1))
	btn.button_up.connect(func(): icon.position.y -= float(depth - 1); icon.modulate = icon_col)
	return btn
