# puzzle_debug_bar.gd
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

var _screen: Variant = null
var _session: Variant = null
var _board: Variant = null

var _toggle_btn: Button
var _tools_container: GridContainer
var _solution_btn: Button
var _win_btn: Button
var _fail_btn: Button
var _solve_btn: Button

func _init() -> void:
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
	var sb := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", sb)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	_tools_container = GridContainer.new()
	_tools_container.columns = 2
	_tools_container.add_theme_constant_override("h_separation", 8)
	_tools_container.add_theme_constant_override("v_separation", 8)
	_tools_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tools_container.visible = false
	root_vbox.add_child(_tools_container)

	_solution_btn = _create_btn("Hien nghiem", _on_solution_pressed)
	_tools_container.add_child(_solution_btn)

	_win_btn = _create_btn("Thang", _on_win_pressed)
	_tools_container.add_child(_win_btn)

	_fail_btn = _create_btn("Thua", _on_fail_pressed)
	_tools_container.add_child(_fail_btn)

	_solve_btn = _create_btn("Tu giai", _on_solve_pressed)
	_tools_container.add_child(_solve_btn)

	_toggle_btn = Button.new()
	_toggle_btn.text = "Cheats"
	_toggle_btn.custom_minimum_size = Vector2(0, 48)
	_toggle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle_btn.add_theme_font_size_override("font_size", 22)
	_toggle_btn.add_theme_color_override("font_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Palette.BOARD_CHEATS_BG
	normal.set_corner_radius_all(14)
	normal.border_width_bottom = 4
	normal.border_color = Palette.BOARD_CHEATS_EDGE
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.BOARD_CHEATS_BG.lightened(0.06)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 1
	pressed.expand_margin_top = -3.0

	for s in ["normal", "focus", "disabled"]:
		_toggle_btn.add_theme_stylebox_override(s, normal)
	_toggle_btn.add_theme_stylebox_override("hover", hover)
	_toggle_btn.add_theme_stylebox_override("pressed", pressed)
	_toggle_btn.pressed.connect(_on_toggle_pressed)
	root_vbox.add_child(_toggle_btn)

func _create_btn(text: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 52)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BOARD_CHEATS_BG.darkened(0.18)
	sb.set_corner_radius_all(10)
	sb.border_width_bottom = 3
	sb.border_color = Palette.BOARD_CHEATS_EDGE
	for s in ["normal", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, sb)
	var hsb := sb.duplicate() as StyleBoxFlat
	hsb.bg_color = Palette.BOARD_CHEATS_BG.darkened(0.1)
	btn.add_theme_stylebox_override("hover", hsb)
	btn.pressed.connect(action)
	return btn

func _on_toggle_pressed() -> void:
	_tools_container.visible = not _tools_container.visible

func _sync_ui_state() -> void:
	if _solution_btn == null:
		return
	var showing: bool = _board != null and bool(_board.is_showing_solution())
	_solution_btn.text = "An nghiem" if showing else "Hien nghiem"

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
		_session.state_changed.emit()
		_session.phase = PlaySession.Phase.FAILED
		_session.level_failed.emit()

func _on_solve_pressed() -> void:
	if _session == null or _session.phase != PlaySession.Phase.ACTIVE:
		return
	var sol: Array = _session.level.get("solution", [])
	var sz: int = _session.board.size()
	for r in range(sz):
		for c in range(sz):
			_session.board[r][c] = CellModel.CellKind.BLANK
	for r in range(sz):
		if r < sol.size():
			var c: int = int(sol[r])
			_session.board[r][c] = CellModel.CellKind.CANDY
	_session.state_changed.emit()
	if _board != null:
		_board.redraw()
	_session.phase = PlaySession.Phase.WON
	_session.level_won.emit()
