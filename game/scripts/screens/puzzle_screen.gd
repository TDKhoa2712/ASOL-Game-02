# puzzle_screen.gd
extends Control

signal go_home()
signal level_done(won: bool)

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const BoardSolver = preload("res://scripts/core/board_solver.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")

var runtime: Variant = null
var sfx: Variant = null
var session: Variant = null
var _hint_click_count: int = 0

var board: PuzzleBoard
var hearts_display: Control
var hint_btn: Button
var undo_btn: Button
var restart_btn: Button
var home_btn: Button
var timer_label: Label

func _ensure_nodes() -> void:
	if board == null:
		board = get_node_or_null("Board") as PuzzleBoard
	if hearts_display == null:
		hearts_display = get_node_or_null("Toolbar/Hearts") as Control
	if hint_btn == null:
		hint_btn = get_node_or_null("Toolbar/HintBtn") as Button
	if undo_btn == null:
		undo_btn = get_node_or_null("Toolbar/UndoBtn") as Button
	if restart_btn == null:
		restart_btn = get_node_or_null("Toolbar/RestartBtn") as Button
	if home_btn == null:
		home_btn = get_node_or_null("Toolbar/HomeBtn") as Button
	if timer_label == null:
		timer_label = get_node_or_null("Toolbar/Timer") as Label

func _ready() -> void:
	_ensure_nodes()
	_connect_ui()

func _connect_ui() -> void:
	_ensure_nodes()
	if hint_btn != null and not hint_btn.pressed.is_connected(_on_hint):
		hint_btn.pressed.connect(_on_hint)
	if undo_btn != null and not undo_btn.pressed.is_connected(_on_undo):
		undo_btn.pressed.connect(_on_undo)
	if restart_btn != null and not restart_btn.pressed.is_connected(_on_restart):
		restart_btn.pressed.connect(_on_restart)
	if home_btn != null and not home_btn.pressed.is_connected(_on_home):
		home_btn.pressed.connect(_on_home)
	if board != null:
		if not board.cell_tapped.is_connected(_on_board_tap):
			board.cell_tapped.connect(_on_board_tap)
		if not board.cell_double_tapped.is_connected(_on_board_double_tap):
			board.cell_double_tapped.connect(_on_board_double_tap)

func setup(rt: Variant, sfx_player: Variant) -> void:
	runtime = rt
	sfx = sfx_player
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
		board.configure(session)
	_connect_session()
	_connect_ui()
	_update_hearts()
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
	if not session.auto_marked.is_connected(_on_auto_marked):
		session.auto_marked.connect(_on_auto_marked)
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
	if hearts_display is Label:
		hearts_display.text = "♥ %d" % [session.hearts]
	else:
		var count: int = hearts_display.get_child_count()
		for i in range(count):
			var child := hearts_display.get_child(i)
			if child is CanvasItem:
				child.modulate = Color.WHITE if i < session.hearts else Color(1.0, 1.0, 1.0, 0.25)

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

func _on_undo() -> void:
	if session == null or session.phase != 0:
		return
	if session.undo():
		if sfx != null:
			sfx.play(SfxCatalog.Effect.UNDO)
		Vibration.pulse(Vibration.Strength.SOFT)
		if board != null:
			board.clear_highlight()
			board.redraw()

func _on_restart() -> void:
	_hint_click_count = 0
	if runtime != null:
		session = runtime.restart_level()
		if board != null:
			board.configure(session)
		_connect_session()
		_update_hearts()
		if sfx != null:
			sfx.play(SfxCatalog.Effect.RESTART)

func _on_home() -> void:
	if runtime != null and session != null and runtime.sessions != null:
		runtime.sessions.save_session(session.to_save_data())
	go_home.emit()

func _on_candy_found(_row: int, _col: int, _region: String) -> void:
	if sfx != null:
		sfx.play(SfxCatalog.Effect.CANDY_YES)
	Vibration.pulse(Vibration.Strength.NORMAL)
	_hint_click_count = 0
	if board != null:
		board.clear_highlight()
		board.redraw()

func _on_auto_marked(cells: Array) -> void:
	if board != null:
		board.animate_locks(cells)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.LOCK_CELL)

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
