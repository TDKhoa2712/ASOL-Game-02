extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const RuleIcon = preload("res://scripts/screens/rule_icon.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const HeartsDisplay = preload("res://scripts/screens/hearts_display.gd")
const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const CandyCounterAnimator = preload("res://scripts/screens/candy_counter_animator.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")

const RULE_ICON_SIZE := 96
const RULE_FONT_SIZE := 21

static func build(root: Control) -> Dictionary:
	var background := GradientBg.new(Color("#FFFFFF"), Color("#FFF8DC"), Color("#FFE08A"), Vector2(0.5, 0.38))
	background.name = "Background"
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

	# 1. Top bar
	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.custom_minimum_size.y = 96
	top.add_theme_constant_override("separation", 12)
	stack.add_child(top)

	var back := _make_3d_btn("BackBtn", "res://assets/ui/board/icon_back.svg", Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, Color.WHITE, Vector2(88, 88), 22, 6, Vector2(40, 40))
	top.add_child(back)

	_add_spacer(top)

	var level_pill := PanelContainer.new()
	level_pill.name = "LevelPill"
	var lsb := _card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 999, 5, 28, 8)
	level_pill.add_theme_stylebox_override("panel", lsb)

	var level_box := HBoxContainer.new()
	level_box.alignment = BoxContainer.ALIGNMENT_CENTER
	level_box.add_theme_constant_override("separation", 8)
	level_pill.add_child(level_box)

	var level_caption := Label.new()
	level_caption.text = root.tr("puzzle.level_caption")
	level_caption.add_theme_font_size_override("font_size", 26)
	level_caption.add_theme_color_override("font_color", Palette.BOARD_NAVY_SOFT)
	var lf := FontTokens.heading()
	if lf != null: level_caption.add_theme_font_override("font", lf)
	level_box.add_child(level_caption)

	var level_value := Label.new()
	level_value.name = "LevelValue"
	level_value.text = "1"
	level_value.add_theme_font_size_override("font_size", 44)
	level_value.add_theme_color_override("font_color", Palette.BOARD_NAVY)
	var lvf := FontTokens.heading_regular()
	if lvf != null: level_value.add_theme_font_override("font", lvf)
	level_box.add_child(level_value)
	top.add_child(level_pill)
	_add_spacer(top)

	var help := _make_3d_btn("HelpBtn", "res://assets/ui/board/icon_help.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(88, 88), 22, 6, Vector2(38, 38))
	var restart := _make_3d_btn("RestartBtn", "res://assets/ui/board/icon_restart.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(88, 88), 22, 6, Vector2(38, 38))
	var settings := _make_3d_btn("SettingsBtn", "res://assets/ui/board/icon_settings.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(88, 88), 22, 6, Vector2(40, 40))
	top.add_child(help)
	top.add_child(restart)
	top.add_child(settings)

	# 2. Status row (Candy progress + Lives)
	var status := HBoxContainer.new()
	status.name = "StatusRow"
	status.add_theme_constant_override("separation", 16)
	stack.add_child(status)

	var region_pill := PanelContainer.new()
	region_pill.name = "RegionProgressPill"
	region_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_pill.add_theme_stylebox_override("panel", _card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 14, 8))
	status.add_child(region_pill)

	var region_row := HBoxContainer.new()
	region_row.name = "RegionIcons"
	region_row.alignment = BoxContainer.ALIGNMENT_CENTER
	region_row.add_theme_constant_override("separation", 10)
	region_pill.add_child(region_row)

	var lives_pill := PanelContainer.new()
	lives_pill.name = "LivesPill"
	lives_pill.add_theme_stylebox_override("panel", _card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 14, 8))
	status.add_child(lives_pill)

	var lives_row := HeartsDisplay.new()
	lives_row.name = "LifeIcons"
	lives_row.add_theme_constant_override("separation", 8)
	lives_pill.add_child(lives_row)

	# 3. Rule cards
	var rules := PanelContainer.new()
	rules.name = "RuleCard"
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.add_child(rules)

	var rule_row := HBoxContainer.new()
	rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rule_row.add_theme_constant_override("separation", 10)
	rule_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_child(rule_row)

	for item in [["rowcol", root.tr("puzzle.rule_row")], ["region", root.tr("puzzle.rule_region")], ["touch", root.tr("puzzle.rule_diagonal")]]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_stretch_ratio = 1.0
		card.add_theme_stylebox_override("panel", _card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 10, 12))
		var chbox := HBoxContainer.new()
		chbox.alignment = BoxContainer.ALIGNMENT_CENTER
		chbox.add_theme_constant_override("separation", 8)
		card.add_child(chbox)
		var rule_icon := RuleIcon.new(item[0])
		rule_icon.custom_minimum_size = Vector2(RULE_ICON_SIZE, RULE_ICON_SIZE)
		chbox.add_child(rule_icon)
		var caption := Label.new()
		caption.text = item[1]
		caption.add_theme_font_size_override("font_size", RULE_FONT_SIZE)
		caption.add_theme_color_override("font_color", Palette.BOARD_NAVY)
		var bf := FontTokens.body_bold()
		if bf != null: caption.add_theme_font_override("font", bf)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chbox.add_child(caption)
		rule_row.add_child(card)

	# 4. Board card
	var board_card := PanelContainer.new()
	board_card.name = "BoardCard"
	board_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.add_child(board_card)

	var board := PuzzleBoard.new()
	board.name = "Board"
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.add_child(board)

	var hint_highlight := HintHighlightLayer.new()
	hint_highlight.name = "HintHighlightLayer"
	hint_highlight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_highlight.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.add_child(hint_highlight)

	var hint_overlay := HintOverlay.new()
	hint_overlay.name = "HintOverlay"
	hint_overlay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_overlay.size_flags_vertical = Control.SIZE_SHRINK_END
	hint_overlay.custom_minimum_size = Vector2(500, 0)
	board_card.add_child(hint_overlay)

	# 5. Bottom dock
	var dock := HBoxContainer.new()
	dock.name = "BottomDock"
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 36)
	stack.add_child(dock)

	var undo := _make_3d_btn("UndoBtn", "res://assets/ui/board/icon_undo.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(104, 104), 28, 8, Vector2(50, 50))
	dock.add_child(undo)

	var hint := _make_3d_btn("HintBtn", "res://assets/ui/board/icon_hint.svg", Palette.BOARD_HINT_BG, Palette.BOARD_HINT_EDGE, Palette.BOARD_HINT_ICON, Vector2(104, 104), 28, 8, Vector2(50, 50))
	var badge := PanelContainer.new()
	badge.name = "Badge"
	badge.add_theme_stylebox_override("panel", _card_sb(Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, 999, 2, 8, 2))
	badge.position = Vector2(72, -8)
	badge.custom_minimum_size = Vector2(34, 34)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false  # Hints are unlimited; show only once a real hint quota exists.
	var bl := Label.new()
	bl.name = "HintCount"
	bl.text = "3"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bl.add_theme_font_size_override("font_size", 18)
	bl.add_theme_color_override("font_color", Color.WHITE)
	var hbf := FontTokens.body_bold()
	if hbf != null: bl.add_theme_font_override("font", hbf)
	badge.add_child(bl)
	hint.add_child(badge)
	dock.add_child(hint)

	var debug_bar = null
	if OS.is_debug_build():
		var dbg_cls = load("res://scripts/screens/puzzle_debug_bar.gd")
		if dbg_cls != null:
			debug_bar = dbg_cls.new()
			debug_bar.name = "DebugBar"
			stack.add_child(debug_bar)

	var confirm := ConfirmationDialog.new()
	confirm.name = "RestartConfirm"
	confirm.title = root.tr("puzzle.restart_title")
	confirm.dialog_text = root.tr("puzzle.restart_body")
	confirm.get_ok_button().text = root.tr("puzzle.restart_ok")
	confirm.get_cancel_button().text = root.tr("puzzle.restart_cancel")
	root.add_child(confirm)

	return {"board": board, "back": back, "help": help, "restart": restart,
		"settings": settings, "hint": hint, "undo": undo, "confirm": confirm, "level": level_value,
		"regions": region_row, "lives": lives_row, "rules": rules, "hint_overlay": hint_overlay,
		"hint_highlight": hint_highlight, "debug_bar": debug_bar}

static func refresh_status(session: Variant, regions_row: HBoxContainer, lives_row: HBoxContainer, animate_loss: bool = false, found_region: String = "") -> void:
	if session == null:
		return
	if not found_region.is_empty():
		CandyCounterAnimator.play_candy_found(session, regions_row, found_region)
	else:
		CandyCounterAnimator.sync_status(session, regions_row)
	lives_row.set_hearts(session.hearts, animate_loss)

static func _card_sb(bg: Color, edge: Color, radius: int, depth: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.set_corner_radius_all(radius); sb.border_width_bottom = depth; sb.border_color = edge
	sb.content_margin_left = pad_x; sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y; sb.content_margin_bottom = pad_y
	return sb

static func _make_3d_btn(node_name: String, icon_path: String, bg_col: Color, edge_col: Color, icon_col: Color, btn_size: Vector2, radius: int, depth: int, icon_size: Vector2) -> Button:
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

static func _add_spacer(parent: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

