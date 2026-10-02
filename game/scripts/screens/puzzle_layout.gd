extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const RuleIcon = preload("res://scripts/screens/rule_icon.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")

static func build(root: Control) -> Dictionary:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Palette.BOARD_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		safe.add_theme_constant_override("margin_" + side, 38)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 36)
	root.add_child(safe)
	var stack := VBoxContainer.new()
	stack.name = "Root"
	stack.add_theme_constant_override("separation", 18)
	safe.add_child(stack)

	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.custom_minimum_size.y = 96
	top.add_theme_constant_override("separation", 12)
	stack.add_child(top)
	var back := _circle("BackBtn", "res://assets/ui/board/icon_back.png", 88)
	top.add_child(back)
	_add_spacer(top)
	var stats := VBoxContainer.new()
	stats.name = "StatCol"
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(stats)
	var level_caption := _label("Màn", 24, Palette.TEXT_STAT)
	level_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(level_caption)
	var level_value := _label("1", 40, Palette.INK)
	level_value.name = "LevelValue"
	level_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_child(level_value)
	_add_spacer(top)
	var help := _circle("HelpBtn", "res://assets/ui/board/icon_help.png", 88)
	var restart := _circle("RestartBtn", "res://assets/ui/board/icon_restart.png", 88)
	var settings := _circle("SettingsBtn", "res://assets/ui/board/icon_settings.png", 88)
	top.add_child(help)
	top.add_child(restart)
	top.add_child(settings)

	var status := HBoxContainer.new()
	status.name = "StatusRow"
	status.add_theme_constant_override("separation", 16)
	stack.add_child(status)
	var region_pill := _panel("RegionProgressPill", Palette.PILL_RADIUS, Palette.SHADOW_SOFT)
	region_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(region_pill)
	var region_row := HBoxContainer.new()
	region_row.name = "RegionIcons"
	region_row.alignment = BoxContainer.ALIGNMENT_CENTER
	region_row.add_theme_constant_override("separation", 10)
	region_pill.add_child(region_row)
	var lives_pill := _panel("LivesPill", Palette.PILL_RADIUS, Palette.SHADOW_SOFT)
	status.add_child(lives_pill)
	var lives_row := HBoxContainer.new()
	lives_row.name = "LifeIcons"
	lives_row.add_theme_constant_override("separation", 6)
	lives_pill.add_child(lives_row)

	var rules := _panel("RuleCard", Palette.CARD_CORNER, Palette.SHADOW_SOFT)
	stack.add_child(rules)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 14)
	rules.add_child(grid)
	var candy_texture := load("res://assets/ui/board/candy.svg") as Texture2D
	var rule_data := [
		["X.X/.C./.X.", "1 kẹo mỗi hàng"],
		[".X./..C/..X", "1 kẹo mỗi cột"],
		["X../XC./...", "1 kẹo mỗi vùng"],
		["X.X/.C./X.X", "Kẹo không chạm chéo"],
	]
	for rule in rule_data:
		var tile := HBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_constant_override("separation", 8)
		grid.add_child(tile)
		tile.add_child(RuleIcon.new(rule[0], candy_texture))
		var caption := _label(rule[1], 20, Palette.TEXT_RULE)
		caption.custom_minimum_size.x = 200
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.add_child(caption)

	var board_card := _panel("BoardCard", Palette.BOARD_CARD_CORNER, Palette.CARD_SHADOW)
	board_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(board_card)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.add_child(center)
	var board := PuzzleBoard.new()
	board.name = "Board"
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(board)

	var dock := HBoxContainer.new()
	dock.name = "BottomDock"
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(dock)
	var hint := _circle("HintBtn", "res://assets/ui/board/icon_hint.png", 110)
	dock.add_child(hint)
	return {"board": board, "back": back, "help": help, "restart": restart,
		"settings": settings, "hint": hint, "level": level_value,
		"regions": region_row, "lives": lives_row, "rules": rules}

static func refresh_status(session: Variant, regions_row: HBoxContainer, lives_row: HBoxContainer) -> void:
	if session == null:
		return
	for container in [regions_row, lives_row]:
		for child in container.get_children():
			container.remove_child(child)
			child.free()
	var size: int = int(session.level.get("size", 0))
	var regions: Array = session.level.get("regions", [])
	var found: Dictionary = {}
	for row in range(size):
		for col in range(size):
			if CellModel.is_placed(session.board[row][col]):
				found[CandyRules.zone_of(regions, row, col)] = true
	var candy_texture := load("res://assets/ui/board/candy.svg") as Texture2D
	var zone_colors: Dictionary = RegionPainter.assign_colors(size, regions, Palette.ZONE_COLORS)
	for index in range(size):
		var icon := TextureRect.new()
		icon.texture = candy_texture
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var zone_id: String = char(65 + index)
		icon.modulate = zone_colors.get(zone_id, Palette.ZONE_COLORS[index]) if found.has(zone_id) else Color(1, 1, 1, 0.25)
		regions_row.add_child(icon)
	var heart_texture := load("res://assets/ui/board/heart.svg") as Texture2D
	for index in range(3):
		var icon := TextureRect.new()
		icon.texture = heart_texture
		icon.custom_minimum_size = Vector2(42, 42)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.WHITE if index < session.hearts else Color(1, 1, 1, 0.25)
		lives_row.add_child(icon)

static func _panel(node_name: String, radius: int, shadow: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PILL_BG
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(16)
	style.shadow_color = shadow
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel

static func _circle(node_name: String, icon_path: String, diameter: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2.ONE * diameter
	button.flat = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(999)
	style.shadow_color = Palette.SHADOW_SOFT
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.icon = load(icon_path) as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	return button

static func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

static func _add_spacer(parent: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
