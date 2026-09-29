extends Control


const GestureEngineScript = preload("res://scripts/gesture_engine.gd")
const BoardViewScript = preload("res://scripts/board_view.gd")
const SettingsScript = preload("res://scripts/settings.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const UiTokens = preload("res://scripts/ui_tokens.gd")
const BackdropScript = preload("res://scripts/pastel_backdrop.gd")

const LEVEL_PATH := "res://data/t01.json"
const CONTRACT_PATH := "res://tests/fixtures/interactions.v2.json"

const ICON_BACK_PATH := "res://assets/ui/board/icon_back.png"
const ICON_SETTINGS_PATH := "res://assets/ui/board/icon_settings.png"
const ICON_HELP_PATH := "res://assets/ui/board/icon_help.png"
const ICON_UNDO_PATH := "res://assets/ui/board/icon_undo.png"
const ICON_HINT_PATH := "res://assets/ui/board/icon_hint.png"
const ICON_RESTART_PATH := "res://assets/ui/board/icon_restart.png"
const CANDY_PROGRESS_PATH := "res://assets/ui/board/candy.svg"
const LIFE_HEART_PATH := "res://assets/ui/board/heart.svg"
const CANDY_SMALL_PATH := "res://assets/ui/board/candy.svg"
const PLAY_BADGE_PATH := "res://assets/ui/board/icon_play_badge.png"


var configured_level: Dictionary = {}
var configured_contract: Dictionary = {}
var configured_engine
var runtime_controller
var level: Dictionary = {}
var contract: Dictionary = {}
var engine
var settings: SettingsScript

var hearts_label: Label
var status_label: Label
var tutorial_label: Label
var undo_button: Button
var hint_button: Button
var hint_label: Label
var close_hint_button: Button
var region_labels: Dictionary = {}
var region_icons: Array[TextureRect] = []
var life_icons: Array[TextureRect] = []
var restart_dialog: ConfirmationDialog
var board_view
var last_terminal_event := ""
var hint_explanation_closed := false

# Cache textures
var _icon_back_tex: Texture2D
var _icon_settings_tex: Texture2D
var _icon_help_tex: Texture2D
var _icon_undo_tex: Texture2D
var _icon_hint_tex: Texture2D
var _icon_restart_tex: Texture2D
var _candy_progress_tex: Texture2D
var _life_heart_tex: Texture2D
var _candy_small_tex: Texture2D
var _play_badge_tex: Texture2D

var _rule_labels: Array[Label] = []
var _level_num_label: Label
var _level_title_label: Label


class RuleIcon3x3 extends Control:
	var pattern: String = ""
	var candy_tex: Texture2D = null

	func _init(pat: String, candy_texture: Texture2D = null) -> void:
		pattern = pat.replace(" ", "").replace("/", "")
		candy_tex = candy_texture
		custom_minimum_size = Vector2(58, 58)

	func _draw() -> void:
		var w := size.x
		var gap := 2.5
		var cell_w := (w - gap * 2.0) / 3.0
		var radius := 4
		for r in range(3):
			for c in range(3):
				var idx := r * 3 + c
				var ch := pattern[idx] if idx < pattern.length() else "."
				var cell_rect := Rect2(Vector2(c * (cell_w + gap), r * (cell_w + gap)), Vector2(cell_w, cell_w))
				var s := StyleBoxFlat.new()
				s.set_corner_radius_all(radius)
				if ch == "X":
					s.bg_color = UiTokens.ICON_BROWN
					draw_style_box(s, cell_rect)
					var p := cell_w * 0.22
					draw_line(cell_rect.position + Vector2(p, p), cell_rect.end - Vector2(p, p), Color.WHITE, 2.5)
					draw_line(cell_rect.position + Vector2(cell_w - p, p), cell_rect.position + Vector2(p, cell_w - p), Color.WHITE, 2.5)
				elif ch == "C":
					s.bg_color = UiTokens.BOARD_TILE
					draw_style_box(s, cell_rect)
					if candy_tex != null:
						draw_texture_rect(candy_tex, cell_rect.grow(-1.5), false)
					else:
						draw_circle(cell_rect.get_center(), cell_w * 0.35, Color("#A56643"))
				else:
					s.bg_color = UiTokens.RULE_CELL_EMPTY
					draw_style_box(s, cell_rect)


func _font_size(base: float) -> int:
	if settings != null and settings.is_large_text():
		return int(base * 1.3)
	return int(base)


func _text_color(primary: Color, secondary: Color) -> Color:
	if settings != null and settings.is_high_contrast():
		return Color.BLACK
	return primary


func configure(level_data: Dictionary, engine_instance = null, runtime = null, contract_data: Dictionary = {}, settings_instance = null) -> void:
	configured_level = level_data.duplicate(true)
	configured_engine = engine_instance
	runtime_controller = runtime
	configured_contract = contract_data.duplicate(true)
	settings = settings_instance


func _ready() -> void:
	_load_textures()
	level = configured_level if not configured_level.is_empty() else _read_json(LEVEL_PATH)
	contract = configured_contract if not configured_contract.is_empty() else _read_json(CONTRACT_PATH)
	engine = configured_engine if configured_engine != null else GestureEngineScript.new(level, contract)
	engine.session.changed.connect(_refresh)
	engine.changed.connect(_refresh)
	_build_interface()
	_refresh()


func _load_textures() -> void:
	if ResourceLoader.exists(ICON_BACK_PATH):
		_icon_back_tex = load(ICON_BACK_PATH)
	if ResourceLoader.exists(ICON_SETTINGS_PATH):
		_icon_settings_tex = load(ICON_SETTINGS_PATH)
	if ResourceLoader.exists(ICON_HELP_PATH):
		_icon_help_tex = load(ICON_HELP_PATH)
	if ResourceLoader.exists(ICON_UNDO_PATH):
		_icon_undo_tex = load(ICON_UNDO_PATH)
	if ResourceLoader.exists(ICON_HINT_PATH):
		_icon_hint_tex = load(ICON_HINT_PATH)
	if ResourceLoader.exists(ICON_RESTART_PATH):
		_icon_restart_tex = load(ICON_RESTART_PATH)
	if ResourceLoader.exists(CANDY_PROGRESS_PATH):
		_candy_progress_tex = load(CANDY_PROGRESS_PATH)
	if ResourceLoader.exists(LIFE_HEART_PATH):
		_life_heart_tex = load(LIFE_HEART_PATH)
	if ResourceLoader.exists(CANDY_SMALL_PATH):
		_candy_small_tex = load(CANDY_SMALL_PATH)
	if ResourceLoader.exists(PLAY_BADGE_PATH):
		_play_badge_tex = load(PLAY_BADGE_PATH)


func get_session():
	return engine.session if engine != null else null


func undo_last_x() -> void:
	_settle_input()
	engine.session.apply_action({"type": "UndoX"})


func request_restart() -> void:
	_settle_input()
	restart_dialog.popup_centered(Vector2i(650, 260))


func cancel_restart() -> void:
	restart_dialog.hide()


func confirm_restart() -> void:
	engine.cancel_all()
	engine.session.apply_action({"type": "RestartLevel"})
	restart_dialog.hide()


func _settle_input() -> void:
	if engine.active_pointer != -1:
		engine.cancel_active()
	if engine.pending_tap:
		engine.flush_pending()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Plain cream background matching reference design (#F8F1EC)
	var bg_rect := ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = UiTokens.BOARD_BG
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# Safe area margin
	var safe := MarginContainer.new()
	safe.name = "Safe"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 38)
	safe.add_theme_constant_override("margin_right", 38)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 36)
	add_child(safe)

	var root_stack := VBoxContainer.new()
	root_stack.name = "Root"
	root_stack.add_theme_constant_override("separation", 18)
	safe.add_child(root_stack)

	# 1. TopBar (in HeaderCard container for compatibility)
	var header_card := Control.new()
	header_card.name = "HeaderCard"
	header_card.custom_minimum_size = Vector2(0, 96)
	root_stack.add_child(header_card)

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 16)
	header_card.add_child(top_bar)

	# Back button (circular white, replaces Về Home)
	var back_btn := _make_circle_button("HomeButton", _icon_back_tex, Vector2(88, 88))
	back_btn.pressed.connect(_on_home_pressed)
	top_bar.add_child(back_btn)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer_l)

	# Stats column in center: "Màn" on top, level number below
	var stat_col := VBoxContainer.new()
	stat_col.name = "StatCol"
	stat_col.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_col.add_theme_constant_override("separation", -4)
	top_bar.add_child(stat_col)

	_level_title_label = Label.new()
	_level_title_label.name = "LevelTitle"
	_level_title_label.text = "Màn"
	_level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_title_label.add_theme_font_size_override("font_size", _font_size(24))
	_level_title_label.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_STAT, UiTokens.TEXT_STAT))
	stat_col.add_child(_level_title_label)

	_level_num_label = Label.new()
	_level_num_label.name = "LevelNumber"
	var raw_id := str(level.get("id", "01"))
	_level_num_label.text = raw_id.replace("L", "").replace("T", "").lstrip("0")
	if _level_num_label.text.is_empty():
		_level_num_label.text = raw_id
	_level_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_num_label.add_theme_font_size_override("font_size", _font_size(44))
	_level_num_label.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_STAT, UiTokens.TEXT_STAT))
	stat_col.add_child(_level_num_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer_r)

	# Help button (circular white '?')
	var help_btn := _make_circle_button("HelpButton", _icon_help_tex, Vector2(88, 88))
	help_btn.pressed.connect(_on_help_pressed)
	top_bar.add_child(help_btn)

	# Restart button (circular white, positioned to the right of Help button)
	var restart_btn := _make_circle_button("RestartButton", _icon_restart_tex, Vector2(88, 88))
	restart_btn.pressed.connect(request_restart)
	top_bar.add_child(restart_btn)

	# Settings button (circular white)
	var settings_btn := _make_circle_button("SettingsButton", _icon_settings_tex, Vector2(88, 88))
	settings_btn.pressed.connect(_on_settings_pressed)
	top_bar.add_child(settings_btn)

	# 2. StatusRow: Pill tiến độ vùng + Pill lượt sai (kích thước nhỏ gọn)
	var status_row := HBoxContainer.new()
	status_row.name = "StatusRow"
	status_row.add_theme_constant_override("separation", 16)
	root_stack.add_child(status_row)

	# Region progress pill (compact)
	var region_pill := PanelContainer.new()
	region_pill.name = "RegionProgressPill"
	region_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color.WHITE
	r_style.set_corner_radius_all(UiTokens.PILL_RADIUS)
	r_style.shadow_color = UiTokens.SHADOW_SOFT
	r_style.shadow_size = 8
	r_style.shadow_offset = Vector2(0, 3)
	r_style.content_margin_left = 18.0
	r_style.content_margin_right = 18.0
	r_style.content_margin_top = 8.0
	r_style.content_margin_bottom = 8.0
	region_pill.add_theme_stylebox_override("panel", r_style)
	status_row.add_child(region_pill)

	var region_hbox := HBoxContainer.new()
	region_hbox.name = "RegionProgress"
	region_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	region_hbox.add_theme_constant_override("separation", 10)
	region_pill.add_child(region_hbox)

	region_labels.clear()
	region_icons.clear()
	var region_count := int(level.get("size", 4))
	for index in range(region_count):
		var region_id := char(65 + index)
		var candy_icon := TextureRect.new()
		candy_icon.name = "Region%s" % region_id
		candy_icon.texture = _candy_progress_tex
		candy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		candy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		candy_icon.custom_minimum_size = Vector2(34, 34)
		var color := UiTokens.REGION_PALETTE[index % UiTokens.REGION_PALETTE.size()]
		candy_icon.modulate = color.lerp(Color.WHITE, 0.35)
		candy_icon.modulate.a = 0.65
		region_hbox.add_child(candy_icon)
		region_icons.append(candy_icon)
		# Invisible label child to preserve text query compatibility
		var slot_lbl := Label.new()
		slot_lbl.name = "RegionLabel%s" % region_id
		slot_lbl.text = "○  %s" % region_id
		slot_lbl.visible = false
		candy_icon.add_child(slot_lbl)
		region_labels[region_id] = slot_lbl

	# Lives pill (Hearts compact)
	var lives_pill := PanelContainer.new()
	lives_pill.name = "LivesPill"
	var l_style := StyleBoxFlat.new()
	l_style.bg_color = Color.WHITE
	l_style.set_corner_radius_all(UiTokens.PILL_RADIUS)
	l_style.shadow_color = UiTokens.SHADOW_SOFT
	l_style.shadow_size = 8
	l_style.shadow_offset = Vector2(0, 3)
	l_style.content_margin_left = 16.0
	l_style.content_margin_right = 16.0
	l_style.content_margin_top = 8.0
	l_style.content_margin_bottom = 8.0
	lives_pill.add_theme_stylebox_override("panel", l_style)
	status_row.add_child(lives_pill)

	var lives_hbox := HBoxContainer.new()
	lives_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lives_hbox.add_theme_constant_override("separation", 6)
	lives_pill.add_child(lives_hbox)

	life_icons.clear()
	for i in range(3):
		var heart := TextureRect.new()
		heart.name = "Heart%d" % i
		heart.texture = _life_heart_tex
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(36, 30)
		lives_hbox.add_child(heart)
		life_icons.append(heart)

	# Label preserved for accessibility & tests
	hearts_label = Label.new()
	hearts_label.name = "HeartsLabel"
	hearts_label.visible = false
	hearts_label.add_theme_font_size_override("font_size", _font_size(28))
	lives_pill.add_child(hearts_label)

	# 3. RulesCard: 2x2 grid with 3x3 thumbnails and text
	var rule_card := PanelContainer.new()
	rule_card.name = "RuleCard"
	rule_card.add_theme_stylebox_override("panel", UiTokens.make_card_style(Color.WHITE, 26, 0.12))
	root_stack.add_child(rule_card)

	var rules := GridContainer.new()
	rules.name = "RuleStrip"
	rules.columns = 2
	rules.add_theme_constant_override("h_separation", 14)
	rules.add_theme_constant_override("v_separation", 10)
	rule_card.add_child(rules)

	var rule_defs: Array[Dictionary] = [
		{"text": "1 kẹo mỗi hàng", "pattern": ".../XCX/..."},
		{"text": "1 kẹo mỗi cột", "pattern": ".X./.C./.X."},
		{"text": "1 kẹo mỗi vùng", "pattern": "XXX/XC./X.."},
		{"text": "Kẹo không chạm góc", "pattern": "XXX/XCX/XXX"}
	]

	_rule_labels.clear()
	for r_def in rule_defs:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile_style := StyleBoxFlat.new()
		tile_style.bg_color = UiTokens.BOARD_TILE
		tile_style.set_corner_radius_all(14)
		tile_style.content_margin_left = 10.0
		tile_style.content_margin_right = 10.0
		tile_style.content_margin_top = 8.0
		tile_style.content_margin_bottom = 8.0
		tile.add_theme_stylebox_override("panel", tile_style)
		tile.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_RULE, UiTokens.TEXT_RULE))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		tile.add_child(hbox)

		var icon3x3 := RuleIcon3x3.new(r_def["pattern"], _candy_small_tex)
		hbox.add_child(icon3x3)

		var lbl := Label.new()
		lbl.text = r_def["text"]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", _font_size(20))
		lbl.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_RULE, UiTokens.TEXT_RULE))
		hbox.add_child(lbl)
		_rule_labels.append(lbl)

		rules.add_child(tile)

	# Tutorial / Toast Label
	tutorial_label = Label.new()
	tutorial_label.name = "TutorialLabel"
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_font_size_override("font_size", _font_size(22))
	tutorial_label.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_STAT, UiTokens.TEXT_STAT))
	root_stack.add_child(tutorial_label)

	# 4. Board Area (CenterContainer / BoardCard)
	var board_card := PanelContainer.new()
	board_card.name = "BoardCard"
	board_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var b_card_style := StyleBoxFlat.new()
	b_card_style.bg_color = Color.WHITE
	b_card_style.set_corner_radius_all(32)
	b_card_style.shadow_color = UiTokens.SHADOW_SOFT
	b_card_style.shadow_size = 14
	b_card_style.shadow_offset = Vector2(0, 6)
	b_card_style.content_margin_left = 12.0
	b_card_style.content_margin_right = 12.0
	b_card_style.content_margin_top = 12.0
	b_card_style.content_margin_bottom = 12.0
	board_card.add_theme_stylebox_override("panel", b_card_style)
	root_stack.add_child(board_card)

	var board_center := CenterContainer.new()
	board_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.add_child(board_center)

	board_view = BoardViewScript.new()
	board_view.name = "BoardView"
	board_view.configure(engine, level)
	board_center.add_child(board_view)

	# Hint / status toasts
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", _font_size(22))
	status_label.add_theme_color_override("font_color", _text_color(UiTokens.TEXT_STAT, UiTokens.TEXT_STAT))
	root_stack.add_child(status_label)

	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", _font_size(21))
	hint_label.add_theme_color_override("font_color", _text_color(UiTokens.INK, UiTokens.INK))
	root_stack.add_child(hint_label)

	close_hint_button = Button.new()
	close_hint_button.name = "CloseHintButton"
	close_hint_button.text = "Đóng gợi ý"
	close_hint_button.visible = false
	close_hint_button.add_theme_stylebox_override("normal", UiTokens.make_pill_style(Color.WHITE, UiTokens.SHADOW_SOFT, 6, Vector2(0, 2)))
	close_hint_button.add_theme_color_override("font_color", UiTokens.INK)
	close_hint_button.pressed.connect(_on_close_hint_pressed)
	root_stack.add_child(close_hint_button)

	# 5. BottomBar: 3 circular buttons with soft shadow (Hoàn tác, Gợi ý, Chơi lại)
	var bottom_dock := PanelContainer.new()
	bottom_dock.name = "BottomDock"
	var dock_style := StyleBoxEmpty.new()
	bottom_dock.add_theme_stylebox_override("panel", dock_style)
	root_stack.add_child(bottom_dock)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 52)
	bottom_dock.add_child(actions)

	undo_button = _make_circle_button("UndoButton", _icon_undo_tex, Vector2(110, 110))
	undo_button.pressed.connect(undo_last_x)
	actions.add_child(undo_button)

	hint_button = _make_circle_button("HintButton", _icon_hint_tex, Vector2(110, 110))
	hint_button.pressed.connect(_on_hint_pressed)
	# Play badge on Hint button
	if _play_badge_tex != null:
		var badge_panel := PanelContainer.new()
		badge_panel.name = "PlayBadge"
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = UiTokens.BADGE_AD
		b_style.set_corner_radius_all(999)
		badge_panel.add_theme_stylebox_override("panel", b_style)
		badge_panel.custom_minimum_size = Vector2(34, 34)
		badge_panel.position = Vector2(74, 0)
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var badge_center := CenterContainer.new()
		badge_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_child(badge_center)

		var badge_icon := TextureRect.new()
		badge_icon.texture = _play_badge_tex
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.custom_minimum_size = Vector2(18, 18)
		badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_center.add_child(badge_icon)

		hint_button.add_child(badge_panel)
	actions.add_child(hint_button)

	# Restart confirmation dialog
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.name = "RestartDialog"
	restart_dialog.title = "Chơi lại màn %s?" % str(level.get("id", ""))
	restart_dialog.dialog_text = "Toàn bộ đánh dấu và số lỗi trong lượt hiện tại sẽ được xóa."
	restart_dialog.get_ok_button().text = "Chơi lại"
	restart_dialog.get_cancel_button().text = "Giữ nguyên"
	restart_dialog.confirmed.connect(confirm_restart)
	restart_dialog.canceled.connect(cancel_restart)
	add_child(restart_dialog)


func _make_circle_button(node_name: String, icon_tex: Texture2D, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.custom_minimum_size = btn_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var norm_style := UiTokens.make_circle_button_style(Color.WHITE, 0.18)
	var hover_style := UiTokens.make_circle_button_style(Color("#FFFDFB"), 0.24)
	var pressed_style := UiTokens.make_circle_button_style(Color("#F5EFEA"), 0.12)
	var disabled_style := UiTokens.make_circle_button_style(Color("#F0EBE6"), 0.05)

	btn.add_theme_stylebox_override("normal", norm_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	var center_box := CenterContainer.new()
	center_box.name = "IconCenter"
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(center_box)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon_tex
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_size := btn_size * 0.54
	icon_rect.custom_minimum_size = icon_size
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_box.add_child(icon_rect)

	return btn


## Helper cho phép thay đổi texture icon của nút bất cứ lúc nào
func set_button_icon(btn: Button, new_texture: Texture2D) -> void:
	if btn == null:
		return
	var icon_rect: TextureRect = btn.find_child("Icon", true, false)
	if icon_rect != null:
		icon_rect.texture = new_texture


func _refresh() -> void:
	if hearts_label == null:
		return
	var state: Dictionary = engine.session.public_state()
	var hearts_count: int = int(state["hearts"])
	hearts_label.text = "Lượt sai còn lại: %d / 3" % hearts_count

	# Update 3 heart life icons
	for i in range(life_icons.size()):
		if i < hearts_count:
			life_icons[i].modulate = Color.WHITE
		else:
			life_icons[i].modulate = Color(0.7, 0.7, 0.7, 0.25)

	undo_button.disabled = not bool(state["undoAvailable"])
	undo_button.modulate.a = 1.0 if bool(state["undoAvailable"]) else 0.45

	hint_button.disabled = int(state["hintCount"]) > 0
	hint_button.modulate.a = 0.45 if int(state["hintCount"]) > 0 else 1.0

	var events: Array = state["events"]
	var latest := str(events[-1]) if not events.is_empty() else "Sẵn sàng"
	status_label.text = _status_text(latest)
	_refresh_region_progress()

	if runtime_controller != null and level.get("id") == "L01":
		var step: String = runtime_controller.tutorial_controller.current_step(runtime_controller.tutorial_state)
		var x_cell_text := _tutorial_cell_text(runtime_controller.tutorial_state.get("tutorialHighlight", []))
		var candy_cell_text := _tutorial_cell_text(runtime_controller.tutorial_state.get("tutorialCandyCell", []))
		tutorial_label.text = {
			"T1": "Hướng dẫn: chạm ô %s để đánh X." % x_cell_text,
			"T2": "Chạm lại ô %s để xóa X." % x_cell_text,
			"T3": "Kéo qua ít nhất hai ô để đánh dấu nhiều X.",
			"T4": "Chạm đôi ô %s để xác nhận kẹo." % candy_cell_text,
			"T5": "Mở Trợ giúp để xem bốn luật và ví dụ X đỏ.",
			"T6": "Mở Gợi ý để xem cách suy luận.",
		}.get(step, "")

	if hint_label != null and latest == "HintShown" and runtime_controller != null and not hint_explanation_closed:
		hint_label.text = _hint_text(runtime_controller.last_hint)
		close_hint_button.visible = true

	if runtime_controller != null and int(state["hintCount"]) > 0 and level.get("id") == "L01":
		var step: String = runtime_controller.tutorial_controller.current_step(runtime_controller.tutorial_state)
		if step == "T6" and not close_hint_button.visible and not hint_explanation_closed:
			hint_label.text = "Gợi ý đã dùng trong lượt này. Đóng phần giải thích để tiếp tục."
			close_hint_button.visible = true

	board_view.queue_redraw()


func _tutorial_cell_text(cell: Array) -> String:
	if cell.size() != 2:
		return "được chỉ định"
	return "(%d,%d)" % [int(cell[0]) + 1, int(cell[1]) + 1]


func _refresh_region_progress() -> void:
	var found: Dictionary = {}
	for row in range(int(level["size"])):
		for column in range(int(level["size"])):
			var cell := [row, column]
			if engine.session.is_given(cell) or engine.session.cell_state(cell) == "candy":
				found[str(level["regions"][row]).substr(column, 1)] = true

	var region_count := int(level["size"])
	for index in range(region_count):
		var region_id := char(65 + index)
		var complete: bool = found.has(region_id)
		if index < region_icons.size():
			var icon := region_icons[index]
			var color: Color = UiTokens.REGION_PALETTE[index % UiTokens.REGION_PALETTE.size()]
			if complete:
				icon.modulate = color
			else:
				icon.modulate = color.lerp(Color.WHITE, 0.40)
				icon.modulate.a = 0.55
		if region_labels.has(region_id):
			var slot: Label = region_labels[region_id]
			slot.text = "%s  %s" % ["●" if complete else "○", region_id]


func _status_text(event_name: String) -> String:
	return {
		"Sẵn sàng": "",
		"MarkX": "Đã đánh dấu X",
		"ClearX": "Đã xóa X",
		"MarkStroke": "Đã cập nhật dải ô",
		"CandyFound": "Đúng rồi!",
		"Mistake": "Ô này chưa đúng",
		"UndoApplied": "Đã hoàn tác",
		"UndoUnavailable": "Không có bước X để hoàn tác",
		"Restarted": "Đã bắt đầu lại",
		"LevelWon": "Hoàn thành %s!" % str(level.get("id", "")),
		"LevelFailed": "Đã hết lượt sai",
	}.get(event_name, "")


func _on_hint_pressed() -> void:
	if runtime_controller == null:
		return
	var result: Dictionary = runtime_controller.use_hint()
	if result.get("ok", false):
		hint_explanation_closed = false
		hint_label.text = _hint_text(result.get("evidence", {}))
	else:
		hint_label.text = "Chưa có gợi ý mới trong trạng thái hiện tại."
	_refresh()


func _on_close_hint_pressed() -> void:
	hint_explanation_closed = true
	close_hint_button.visible = false
	hint_label.text = ""
	if runtime_controller != null and level.get("id") == "L01" and engine.session.hint_count > 0:
		runtime_controller.process_tutorial_action({"type": "CloseHint", "valid": true})
	_refresh()


func _on_home_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "return_home")


func _on_help_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "open_help")


func _on_settings_pressed() -> void:
	_settle_input()
	if runtime_controller != null:
		if not runtime_controller.save_current_session():
			return
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "mvp_bootstrap", "open_settings")


func _hint_text(evidence: Dictionary) -> String:
	if evidence.is_empty():
		return "Đã nhận gợi ý."
	var cell: Array = evidence.get("cell", [])
	if not cell.is_empty():
		return "Gợi ý %s tại ô (%d, %d)" % [str(evidence.get("rule", "")), int(cell[0]) + 1, int(cell[1]) + 1]
	return "Gợi ý %s: loại %d ô ứng viên." % [str(evidence.get("rule", "")), evidence.get("eliminateCells", []).size()]


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "Invalid JSON object: %s" % path)
	return parsed
