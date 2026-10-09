extends RefCounted

const HintEngine = preload("res://scripts/core/hint_engine.gd")
const HintMutex = preload("res://scripts/screens/hint_mutex.gd")
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var _mutex: HintMutex = HintMutex.new()
var _current_hint: Dictionary = {}
var _board: Variant = null
var _hint_overlay: HintOverlay = null
var _hint_highlight: HintHighlightLayer = null
var _sfx: Variant = null
var _session: Variant = null

func setup(board_node: Variant, overlay: HintOverlay, highlight: HintHighlightLayer, sfx_player: Variant) -> void:
	_board = board_node
	_hint_overlay = overlay
	_hint_highlight = highlight
	_sfx = sfx_player

func connect_signals() -> void:
	if _hint_overlay != null:
		if not _hint_overlay.hint_applied.is_connected(apply_hint):
			_hint_overlay.hint_applied.connect(apply_hint)
		if not _hint_overlay.hint_dismissed.is_connected(dismiss_hint):
			_hint_overlay.hint_dismissed.connect(dismiss_hint)
		if not _hint_overlay.detail_requested.is_connected(show_detail):
			_hint_overlay.detail_requested.connect(show_detail)
	if _hint_highlight != null and not _hint_highlight.dismiss_requested.is_connected(dismiss_hint):
		_hint_highlight.dismiss_requested.connect(dismiss_hint)

func request_hint(session: Variant) -> void:
	if session == null or session.phase != PlaySession.Phase.ACTIVE:
		return
	_session = session
	if is_hint_showing():
		dismiss_hint()
		return
	if not _mutex.try_acquire("hint"):
		return
	var lvl: Dictionary = session.level
	var hint: Dictionary = HintEngine.find_hint(
		session.board, int(lvl["size"]), lvl["regions"], lvl["solution"]
	)
	if not hint.get("found", false):
		_mutex.release("hint")
		return
	_current_hint = hint
	if _hint_highlight != null and _board != null:
		_hint_highlight.show_hint(hint, _board.get_cell_rect)
	if _hint_overlay != null:
		_hint_overlay.show_hint(hint)
	if hint.get("strategy") == "WRONG_MARK":
		if _sfx != null: _sfx.play(SfxCatalog.Effect.HINT_WRONG_MARK)
	else:
		if _sfx != null: _sfx.play(SfxCatalog.Effect.HINT_SHOW)
	if hint.get("strategy") != "WRONG_MARK":
		session.use_hint()

func apply_hint(session: Variant = null) -> void:
	if _current_hint.is_empty():
		return
	var hint := _current_hint
	dismiss_hint(false)
	var target_session = session if session != null else _session
	if target_session == null and _board != null and "_session" in _board:
		target_session = _board._session
	if target_session != null:
		var action: String = hint.get("action", "")
		match action:
			"CLEAR_MARK":
				var cell: Array = hint["target_cell"]
				target_session.clear_mark(cell[0], cell[1])
			"PLACE_MARKS":
				target_session.apply_marks(hint["eliminated_cells"])
			"PLACE_CANDY", "REVEAL":
				var cell: Array = hint["target_cell"]
				target_session.try_candy(cell[0], cell[1])
	if _sfx != null: _sfx.play(SfxCatalog.Effect.HINT_APPLY)
	Vibration.pulse(Vibration.Strength.SOFT)
	if _board != null: _board.redraw()

func dismiss_hint(play_sfx: bool = true) -> void:
	var was_showing := not _current_hint.is_empty() or (_hint_overlay != null and _hint_overlay.is_showing())
	_current_hint = {}
	if _hint_highlight != null: _hint_highlight.clear()
	if _hint_overlay != null: _hint_overlay.dismiss()
	if was_showing and play_sfx and _sfx != null:
		_sfx.play(SfxCatalog.Effect.HINT_DISMISS)
	_mutex.release("hint")

func show_detail() -> void:
	if _current_hint.is_empty() or _hint_highlight == null or _board == null:
		return
	var chain: Dictionary = _current_hint.get("chain_detail", {})
	if chain.is_empty():
		return
	_hint_highlight.show_chain_detail(chain, _board.get_cell_rect)

func force_release() -> void:
	_current_hint = {}
	if _hint_highlight != null: _hint_highlight.clear()
	if _hint_overlay != null: _hint_overlay.dismiss()
	_mutex.force_release()

func is_hint_showing() -> bool:
	return _hint_overlay != null and _hint_overlay.is_showing()
