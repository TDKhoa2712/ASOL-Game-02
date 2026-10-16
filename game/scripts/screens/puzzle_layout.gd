extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const RuleIcon = preload("res://scripts/screens/rule_icon.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")
const AssistDock = preload("res://scripts/screens/assist_dock.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const HeartsDisplay = preload("res://scripts/screens/hearts_display.gd")
const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const CandyCounterAnimator = preload("res://scripts/screens/candy_counter_animator.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const FitLabel = preload("res://scripts/ui/fit_label.gd")
const BoardButtons = preload("res://scripts/ui/board_buttons.gd")

const RULE_ICON_SIZE := 84
const RULE_FONT_SIZE := 28  # upper bound; captions shrink to fit two lines
# Fixed height of the rule/hint slot: whatever shows there, the board never moves.
const RULE_SLOT_HEIGHT := 210
const TOP_BTN_SIZE := 108
const DOCK_BTN_SIZE := 120
# Empty band under the dock: lifts the dock off the screen edge and reserves room for a future banner ad.
const AD_SLOT_HEIGHT := 120
const DOCK_DROP := 70

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
	top.custom_minimum_size.y = TOP_BTN_SIZE + 8
	top.add_theme_constant_override("separation", 12)
	stack.add_child(top)

	var back := BoardButtons.make_3d_btn("BackBtn", "res://assets/ui/board/icon_back.svg", Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, Color.WHITE, Vector2(TOP_BTN_SIZE, TOP_BTN_SIZE), 26, 7, Vector2(50, 50))
	top.add_child(back)

	_add_spacer(top)
	# Narrower left gap nudges the level pill toward the back button.
	top.get_child(top.get_child_count() - 1).size_flags_stretch_ratio = 0.4

	var level_pill := PanelContainer.new()
	level_pill.name = "LevelPill"
	var lsb := BoardButtons.card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 999, 5, 28, 8)
	level_pill.add_theme_stylebox_override("panel", lsb)

	var level_box := HBoxContainer.new()
	level_box.alignment = BoxContainer.ALIGNMENT_CENTER
	level_box.add_theme_constant_override("separation", 8)
	level_pill.add_child(level_box)

	var level_caption := Label.new()
	level_caption.text = root.tr("puzzle.level_caption")
	level_caption.add_theme_font_size_override("font_size", 32)
	level_caption.add_theme_color_override("font_color", Palette.BOARD_NAVY_SOFT)
	var lf := FontTokens.heading()
	if lf != null: level_caption.add_theme_font_override("font", lf)
	level_box.add_child(level_caption)

	var level_value := Label.new()
	level_value.name = "LevelValue"
	level_value.text = "1"
	level_value.add_theme_font_size_override("font_size", 54)
	level_value.add_theme_color_override("font_color", Palette.BOARD_NAVY)
	var lvf := FontTokens.heading_regular()
	if lvf != null: level_value.add_theme_font_override("font", lvf)
	level_box.add_child(level_value)
	top.add_child(level_pill)
	_add_spacer(top)

	var help := BoardButtons.make_3d_btn("HelpBtn", "res://assets/ui/board/icon_help.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(TOP_BTN_SIZE, TOP_BTN_SIZE), 26, 7, Vector2(48, 48))
	var restart := BoardButtons.make_3d_btn("RestartBtn", "res://assets/ui/board/icon_restart.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(TOP_BTN_SIZE, TOP_BTN_SIZE), 26, 7, Vector2(48, 48))
	var settings := BoardButtons.make_3d_btn("SettingsBtn", "res://assets/ui/board/icon_settings.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(TOP_BTN_SIZE, TOP_BTN_SIZE), 26, 7, Vector2(50, 50))
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
	region_pill.add_theme_stylebox_override("panel", BoardButtons.card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 14, 8))
	status.add_child(region_pill)

	var region_row := HBoxContainer.new()
	region_row.name = "RegionIcons"
	region_row.alignment = BoxContainer.ALIGNMENT_CENTER
	region_row.add_theme_constant_override("separation", 10)
	region_pill.add_child(region_row)

	var lives_pill := PanelContainer.new()
	lives_pill.name = "LivesPill"
	lives_pill.add_theme_stylebox_override("panel", BoardButtons.card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 14, 8))
	status.add_child(lives_pill)

	var lives_row := HeartsDisplay.new()
	lives_row.name = "LifeIcons"
	lives_row.add_theme_constant_override("separation", 8)
	lives_pill.add_child(lives_row)

	# 3. Rule cards
	# The hint card overlaps the rule cards so it never covers the board.
	var rule_slot := _overlap_slot("RuleSlot")
	rule_slot.custom_minimum_size.y = RULE_SLOT_HEIGHT
	stack.add_child(rule_slot)
	var rules := PanelContainer.new()
	rules.name = "RuleCard"
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	rule_slot.add_child(rules)
	rules.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var rule_row := HBoxContainer.new()
	rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rule_row.add_theme_constant_override("separation", 10)
	rule_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_child(rule_row)

	for item in [["rowcol", root.tr("puzzle.rule_row")], ["region", root.tr("puzzle.rule_region")], ["touch", root.tr("puzzle.rule_diagonal")]]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_stretch_ratio = 1.0
		card.add_theme_stylebox_override("panel", BoardButtons.card_sb(Color.WHITE, Palette.BOARD_GOLD_EDGE, 20, 5, 10, 12))
		var chbox := VBoxContainer.new()
		chbox.alignment = BoxContainer.ALIGNMENT_CENTER
		chbox.add_theme_constant_override("separation", 6)
		card.add_child(chbox)
		var rule_icon := RuleIcon.new(item[0])
		rule_icon.custom_minimum_size = Vector2(RULE_ICON_SIZE, RULE_ICON_SIZE)
		rule_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chbox.add_child(rule_icon)
		var caption := FitLabel.new()
		caption.max_font_size = RULE_FONT_SIZE
		caption.text = item[1]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.custom_minimum_size.y = RULE_FONT_SIZE * 2.8  # room for two lines, so cards stay level
		caption.add_theme_color_override("font_color", Palette.BOARD_NAVY)
		var bf := FontTokens.body_bold()
		if bf != null: caption.add_theme_font_override("font", bf)
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chbox.add_child(caption)
		rule_row.add_child(card)

	# 4. Board card
	var board_card := PanelContainer.new()
	board_card.name = "BoardCard"
	# Square card sized to its width; the leftover height goes to the dock area.
	board_card.resized.connect(func(): board_card.custom_minimum_size.y = board_card.size.x)
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
	rule_slot.add_child(hint_overlay)
	hint_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 5. Bottom dock, centred in the gap under the board
	var dock_area := _overlap_slot("DockArea")
	dock_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Bias the dock below the gap's centre, away from the board.
	(dock_area.get_theme_stylebox("panel") as StyleBoxEmpty).content_margin_top = DOCK_DROP
	stack.add_child(dock_area)
	var dock := HBoxContainer.new()
	dock.name = "BottomDock"
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dock.add_theme_constant_override("separation", 56)
	dock_area.add_child(dock)
	hint_overlay.attach_apply_button(dock_area)

	var undo := BoardButtons.make_3d_btn("UndoBtn", "res://assets/ui/board/icon_undo.svg", Color.WHITE, Palette.BOARD_BTN_EDGE, Palette.BOARD_BLUE_EDGE, Vector2(DOCK_BTN_SIZE, DOCK_BTN_SIZE), 30, 8, Vector2(58, 58))
	dock.add_child(undo)

	var hint := BoardButtons.make_3d_btn("HintBtn", "res://assets/ui/board/icon_hint.svg", Palette.BOARD_HINT_BG, Palette.BOARD_HINT_EDGE, Palette.BOARD_HINT_ICON, Vector2(DOCK_BTN_SIZE, DOCK_BTN_SIZE), 30, 8, Vector2(58, 58))
	AssistDock.attach_badge(hint, "HintCount")
	dock.add_child(hint)
	var place := AssistDock.make_place_button()
	dock.add_child(place)

	var ad_slot := Control.new()
	ad_slot.name = "AdSlot"
	ad_slot.custom_minimum_size.y = AD_SLOT_HEIGHT
	ad_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(ad_slot)

	var debug_bar = null
	if OS.is_debug_build():
		var dbg_cls = load("res://scripts/screens/puzzle_debug_bar.gd")
		if dbg_cls != null:
			debug_bar = dbg_cls.new()
			debug_bar.name = "DebugBar"
			debug_bar.size_flags_vertical = Control.SIZE_SHRINK_END
			debug_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			safe.add_child(debug_bar)

	var confirm := ConfirmationDialog.new()
	confirm.name = "RestartConfirm"
	confirm.title = root.tr("puzzle.restart_title")
	confirm.dialog_text = root.tr("puzzle.restart_body")
	confirm.get_ok_button().text = root.tr("puzzle.restart_ok")
	confirm.get_cancel_button().text = root.tr("puzzle.restart_cancel")
	root.add_child(confirm)

	return {"board": board, "back": back, "help": help, "restart": restart,
		"settings": settings, "hint": hint, "place": place, "undo": undo, "confirm": confirm, "level": level_value,
		"regions": region_row, "lives": lives_row, "rules": rules, "hint_overlay": hint_overlay,
		"hint_highlight": hint_highlight, "debug_bar": debug_bar, "ad_slot": ad_slot, "dock_area": dock_area}

static func refresh_status(session: Variant, regions_row: HBoxContainer, lives_row: HBoxContainer, animate_loss: bool = false, found_region: String = "") -> void:
	if session == null:
		return
	if not found_region.is_empty():
		CandyCounterAnimator.play_candy_found(session, regions_row, found_region)
	else:
		CandyCounterAnimator.sync_status(session, regions_row)
	lives_row.set_hearts(session.hearts, animate_loss)

static func _overlap_slot(node_name: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.name = node_name
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	return slot

static func _add_spacer(parent: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

