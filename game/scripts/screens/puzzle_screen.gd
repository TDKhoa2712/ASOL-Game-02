# puzzle_screen.gd
extends Control

signal go_home()
signal level_done(won: bool)
signal options_pressed()

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const BoardSolver = preload("res://scripts/core/board_solver.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")

var runtime: Variant = null
var sfx: Variant = null
var config: Variant = null
var session: Variant = null
var _hint_click_count: int = 0

var board: PuzzleBoard
var hearts_display: Control
var hint_btn: Button
var restart_btn: Button
var home_btn: Button
var timer_label: Label
var level_label: Label
var help_btn: Button
var settings_btn: Button
var region_display: HBoxContainer
var rules_card: PanelContainer
var undo_btn: Button
var restart_confirm: ConfirmationDialog

func _ensure_nodes() -> void:
	if board != null:
		return
	var nodes: Dictionary = PuzzleLayout.build(self)
	board = nodes["board"]
	hearts_display = nodes["lives"]
	region_display = nodes["regions"]
	hint_btn = nodes["hint"]
	restart_btn = nodes["restart"]
	home_btn = nodes["back"]
	help_btn = nodes["help"]
	settings_btn = nodes["settings"]
	level_label = nodes["level"]
	rules_card = nodes["rules"]
	undo_btn = nodes["undo"]
	restart_confirm = nodes["confirm"]

func _ready() -> void:
	_ensure_nodes()
	_connect_ui()

func _connect_ui() -> void:
	_ensure_nodes()
	if hint_btn != null and not hint_btn.pressed.is_connected(_on_hint):
		hint_btn.pressed.connect(_on_hint)
	if restart_btn != null and not restart_btn.pressed.is_connected(_on_restart):
		restart_btn.pressed.connect(_on_restart)
	if undo_btn != null and not undo_btn.pressed.is_connected(_on_undo):
		undo_btn.pressed.connect(_on_undo)
	if restart_confirm != null and not restart_confirm.confirmed.is_connected(_confirm_restart):
		restart_confirm.confirmed.connect(_confirm_restart)
	if home_btn != null and not home_btn.pressed.is_connected(_on_home):
		home_btn.pressed.connect(_on_home)
	if help_btn != null and not help_btn.pressed.is_connected(_on_help):
		help_btn.pressed.connect(_on_help)
	if settings_btn != null and not settings_btn.pressed.is_connected(_on_settings):
		settings_btn.pressed.connect(_on_settings)
	if board != null:
		if not board.cell_tapped.is_connected(_on_board_tap):
			board.cell_tapped.connect(_on_board_tap)
		if not board.cell_double_tapped.is_connected(_on_board_double_tap):
			board.cell_double_tapped.connect(_on_board_double_tap)
		if not board.cell_swiped.is_connected(_on_board_swipe):
			board.cell_swiped.connect(_on_board_swipe)

func setup(rt: Variant, sfx_player: Variant, cfg: Variant = null) -> void:
	runtime = rt
	sfx = sfx_player
	config = cfg
	_hint_click_count = 0
	if runtime != null:
		if runtime.current_session != null:
			session = runtime.current_session
		elif runtime.has_pending_session():
			session = runtime.resume_level()
		else:
			session = runtime.start_level(runtime.current_level_label())
	_ensure_nodes()
	if board != null and session != null:
		if config != null:
			board.set_colorblind(config.get_option("colorblind"))
		board.configure(session)
	_connect_session()
	_connect_ui()
	_update_hearts()
	if level_label != null and session != null:
		level_label.text = str(session.level.get("id", runtime.current_level_label()))
	_update_timer(0.0)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.BOARD_OPEN)

func _connect_session() -> void:
	if session == null:
		return
	if not session.candy_found.is_connected(_on_candy_found):
		session.candy_found.connect(_on_candy_found)
	if not session.mistake_made.is_connected(_on_mistake):
		session.mistake_made.connect(_on_mistake)
	if not session.level_won.is_connected(_on_level_won):
		session.level_won.connect(_on_level_won)
	if not session.level_failed.is_connected(_on_level_failed):
		session.level_failed.connect(_on_level_failed)
	if not session.state_changed.is_connected(_on_session_state_changed):
		session.state_changed.connect(_on_session_state_changed)

func _on_session_state_changed() -> void:
	if runtime != null and session != null and runtime.sessions != null and session.phase == 0:
		runtime.sessions.save_session(session.to_save_data())

func _process(delta: float) -> void:
	if session != null and session.phase == 0:
		session.elapsed_ms += int(delta * 1000.0)
		_update_timer(delta)

func _update_timer(_delta: float) -> void:
	if timer_label == null or session == null:
		return
	var total_secs: int = int(session.elapsed_ms / 1000.0)
	var mins: int = total_secs / 60
	var secs: int = total_secs % 60
	timer_label.text = "%02d:%02d" % [mins, secs]

func _update_hearts() -> void:
	if hearts_display == null or session == null:
		return
	PuzzleLayout.refresh_status(session, region_display, hearts_display)

func _on_board_tap(row: int, col: int) -> void:
	if session == null or session.phase != 0:
		return
	session.mark_x(row, col)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.MARK)
	Vibration.pulse(Vibration.Strength.SOFT)
	if board != null:
		board.clear_highlight()
		board.redraw()

func _on_board_double_tap(row: int, col: int) -> void:
	if session == null or session.phase != 0:
		return
	session.try_candy(row, col)
	if board != null:
		board.clear_highlight()
		board.redraw()

func _on_board_swipe(cells: Array) -> void:
	if session == null or session.phase != 0 or cells.is_empty():
		return
	var first: Array = cells[0]
	if first.size() < 2:
		return
	var first_kind: int = session.cell_at(int(first[0]), int(first[1]))
	if not CellModel.is_available(first_kind):
		return
	var paint_mark: bool = first_kind == CellModel.CellKind.BLANK
	session.mark_stroke(cells, paint_mark)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.MARK)
	if board != null:
		board.redraw()

func _on_hint() -> void:
	if session == null or runtime == null:
		return
	var pace_data: Dictionary = runtime.current_pace()
	var costs: Array = pace_data.get("hintCosts", [1])
	var max_clicks: int = costs.size()
	if _hint_click_count >= max_clicks:
		return
	var level: Dictionary = session.level
	var hint: Dictionary = BoardSolver.progressive_hint(
		session.board, level["size"], level["regions"],
		level["solution"], _hint_click_count + 1
	)
	if not hint.get("found", true) or hint.get("stage") == "none":
		return
	_hint_click_count += 1
	session.use_hint()
	var hl: Array = hint.get("highlight", [])
	if board != null and not hl.is_empty():
		board.highlight_cells(hl)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.HINT_SHOW)

func _on_restart() -> void:
	if board != null:
		board.settle_input()
	if restart_confirm != null:
		restart_confirm.popup_centered(Vector2i(650, 260))

func _confirm_restart() -> void:
	_hint_click_count = 0
	if runtime != null:
		session = runtime.restart_level()
		if board != null:
			if config != null:
				board.set_colorblind(config.get_option("colorblind"))
			board.configure(session)
		_connect_session()
		_update_hearts()
		if sfx != null:
			sfx.play(SfxCatalog.Effect.RESTART)

func set_undo_visible(enabled: bool) -> void:
	_ensure_nodes()
	if undo_btn != null:
		undo_btn.visible = enabled

func _on_undo() -> void:
	if board != null:
		board.settle_input()
	if session != null:
		session.undo_mark()
		if board != null:
			board.clear_highlight()

func _on_home() -> void:
	if board != null:
		board.settle_input()
	if runtime != null and session != null and runtime.sessions != null:
		runtime.sessions.save_session(session.to_save_data())
	go_home.emit()

func _on_help() -> void:
	if rules_card != null:
		rules_card.visible = not rules_card.visible

func _on_settings() -> void:
	options_pressed.emit()

func _on_candy_found(_row: int, _col: int, _region: String) -> void:
	if sfx != null:
		sfx.play(SfxCatalog.Effect.CANDY_YES)
	Vibration.pulse(Vibration.Strength.NORMAL)
	_hint_click_count = 0
	_update_hearts()
	if board != null:
		board.clear_highlight()
		board.redraw()

func _on_mistake(_row: int, _col: int, _clash: String) -> void:
	if sfx != null:
		sfx.play(SfxCatalog.Effect.CANDY_NO)
	Vibration.pulse(Vibration.Strength.FIRM)
	_update_hearts()
	if board != null:
		board.redraw()

func _on_level_won() -> void:
	if sfx != null:
		sfx.play(SfxCatalog.Effect.STAGE_CLEAR)
	level_done.emit(true)

func _on_level_failed() -> void:
	if sfx != null:
		sfx.play(SfxCatalog.Effect.STAGE_FAIL)
	level_done.emit(false)
