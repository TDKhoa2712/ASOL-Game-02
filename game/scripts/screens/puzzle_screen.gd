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
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")

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
var hint_overlay: HintOverlay

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
	hint_overlay = nodes.get("hint_overlay")

func _ready() -> void:
	_ensure_nodes()
	_connect_ui()

func _connect_ui() -> void:
	_ensure_nodes()
	_btn_conn(hint_btn, _on_hint)
	_btn_conn(restart_btn, _on_restart)
	_btn_conn(undo_btn, _on_undo)
	_btn_conn(home_btn, _on_home)
	_btn_conn(help_btn, _on_help)
	_btn_conn(settings_btn, _on_settings)
	if restart_confirm != null and not restart_confirm.confirmed.is_connected(_confirm_restart):
		restart_confirm.confirmed.connect(_confirm_restart)
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
		session = runtime.current_session if runtime.current_session != null else (runtime.resume_level() if runtime.has_pending_session() else runtime.start_level(runtime.current_level_label()))
	_ensure_nodes()
	if board != null and session != null:
		if config != null:
			board.set_colorblind(config.get_option("colorblind"))
			board.set_high_contrast(config.get_option("high_contrast"))
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
	_sig_conn(session.candy_found, _on_candy_found)
	_sig_conn(session.mistake_made, _on_mistake)
	_sig_conn(session.level_won, _on_level_won)
	_sig_conn(session.level_failed, _on_level_failed)
	_sig_conn(session.state_changed, _on_session_state_changed)

static func _sig_conn(sig: Signal, target: Callable) -> void:
	if not sig.is_connected(target):
		sig.connect(target)

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
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
		if board != null:
			board.clear_highlight()
		return
	var pace_data: Dictionary = runtime.current_pace()
	var costs: Array = pace_data.get("hintCosts", [1])
	var max_clicks: int = costs.size()
	if _hint_click_count >= max_clicks:
		return
	var lvl: Dictionary = session.level
	var hint: Dictionary = BoardSolver.progressive_hint(
		session.board, lvl["size"], lvl["regions"],
		lvl["solution"], _hint_click_count + 1
	)
	if not hint.get("found", true) or hint.get("stage") == "none":
		return
	_hint_click_count += 1
	session.use_hint()
	var hl: Array = hint.get("highlight", [])
	if board != null and not hl.is_empty():
		board.highlight_cells(hl)
	var explanation: String = str(hint.get("text", ""))
	var stage: String = str(hint.get("stage", ""))
	var unit_label: String = ""
	if stage == "unit":
		unit_label = "Xem kỹ khu vực này"
	elif stage == "cell":
		unit_label = "Đặt kẹo ở đây"
	if hint_overlay != null and explanation != "":
		hint_overlay.show_hint(explanation, unit_label)
	if sfx != null:
		sfx.play(SfxCatalog.Effect.HINT_SHOW)

func _on_restart() -> void:
	if board != null:
		board.settle_input()
	if restart_confirm != null:
		restart_confirm.popup_centered(Vector2i(650, 260))

func _confirm_restart() -> void:
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
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
	if undo_btn != null: undo_btn.visible = enabled

func set_high_contrast_and_redraw(enabled: bool) -> void:
	_ensure_nodes()
	if board != null:
		board.set_high_contrast(enabled)
		board.redraw()

func set_large_text(enabled: bool) -> void:
	_ensure_nodes()
	if level_label != null: level_label.add_theme_font_size_override("font_size", 50 if enabled else 40)

func _on_undo() -> void:
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
	if board != null:
		board.settle_input()
	if session != null:
		session.undo_mark()
		if board != null:
			board.clear_highlight()

func _on_home() -> void:
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
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
	if hint_overlay != null and hint_overlay.is_showing():
		hint_overlay.dismiss()
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

static func _btn_conn(btn: Button, target: Callable) -> void:
	if btn != null and not btn.pressed.is_connected(target):
		btn.pressed.connect(target)
