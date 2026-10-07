# puzzle_debug_bar.gd
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _screen: Variant = null
var _session: Variant = null
var _board: Variant = null

var _toggle_btn: Button
var _tools_row: HBoxContainer
var _solution_btn: Button
var _win_btn: Button
var _fail_btn: Button
var _solve_btn: Button

func _init() -> void:
	custom_minimum_size = Vector2(0, 68)
	_build_ui()

func setup(screen: Variant, session: Variant, board: Variant) -> void:
	_screen = screen
	_session = session
	_board = board
	_sync_ui_state()

func update_session(session: Variant) -> void:
	_session = session
	_sync_ui_state()

func _build_ui() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(10)
	add_theme_stylebox_override("panel", sb)

	var root_hbox := HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 10)
	root_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root_hbox)

	_toggle_btn = Button.new()
	_toggle_btn.text = "🛠 Cheats"
	_toggle_btn.custom_minimum_size = Vector2(140, 54)
	_toggle_btn.add_theme_font_size_override("font_size", 26)
	_toggle_btn.pressed.connect(_on_toggle_pressed)
	root_hbox.add_child(_toggle_btn)

	_tools_row = HBoxContainer.new()
	_tools_row.add_theme_constant_override("separation", 10)
	_tools_row.visible = false
	root_hbox.add_child(_tools_row)

	_solution_btn = _create_btn("👁 Hiện nghiệm", _on_solution_pressed)
	_tools_row.add_child(_solution_btn)

	_win_btn = _create_btn("✓ Thắng", _on_win_pressed)
	_tools_row.add_child(_win_btn)

	_fail_btn = _create_btn("✕ Thua", _on_fail_pressed)
	_tools_row.add_child(_fail_btn)

	_solve_btn = _create_btn("⏩ Tự giải", _on_solve_pressed)
	_tools_row.add_child(_solve_btn)

func _create_btn(text: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 54)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(action)
	return btn

func _on_toggle_pressed() -> void:
	_tools_row.visible = not _tools_row.visible

func _sync_ui_state() -> void:
	if _board != null and _solution_btn != null:
		_solution_btn.text = "Ẩn nghiệm" if _board.is_showing_solution() else "👁 Hiện nghiệm"

func _on_solution_pressed() -> void:
	if _board != null:
		var nxt: bool = not _board.is_showing_solution()
		_board.set_show_solution(nxt)
		_sync_ui_state()

func _on_win_pressed() -> void:
	if _session != null and _session.phase == PlaySession.Phase.ACTIVE:
		_session.phase = PlaySession.Phase.WON
		_session.level_won.emit()

func _on_fail_pressed() -> void:
	if _session != null and _session.phase == PlaySession.Phase.ACTIVE:
		_session.hearts = 0
		_session.phase = PlaySession.Phase.FAILED
		_session.level_failed.emit()

func _on_solve_pressed() -> void:
	if _session == null or _session.phase != PlaySession.Phase.ACTIVE:
		return
	var sol: Array = _session.level.get("solution", [])
	var sz: int = _session.board.size()
	for r in range(sz):
		if r < sol.size():
			var c: int = int(sol[r])
			if _session.board[r][c] != CellModel.CellKind.GIVEN:
				_session.board[r][c] = CellModel.CellKind.CANDY
	_session.state_changed.emit()
	if _board != null:
		_board.redraw()
	_session.phase = PlaySession.Phase.WON
	_session.level_won.emit()
