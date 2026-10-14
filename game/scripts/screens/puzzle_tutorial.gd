# Connects the tutorial guide and contextual tips to a puzzle screen.
# Reads session signals and board diffs, so the puzzle screen only has to call
# ensure() when it binds a session. No game rule lives here.
extends Node

const TutorialGuide = preload("res://scripts/campaign/tutorial_guide.gd")
const TutorialTips = preload("res://scripts/campaign/tutorial_tips.gd")
const CoachBubble = preload("res://scripts/screens/coach_bubble.gd")
const TutorialOverlay = preload("res://scripts/screens/tutorial_overlay.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

const PRACTICE_KEY := "_tutorial_practice"
const TIP_SEC := 4.0
const RULE_KEYS := ["rowcol", "region", "touch"]

var screen: Control = null
var guide: TutorialGuide = null
var label: String = ""
var session: Variant = null
var bubble: CoachBubble = null
var overlay: TutorialOverlay = null
var _board_before: Array = []
var _shown_id: String = ""
var _tip_left: float = 0.0
var _idle: float = 0.0
var _hint_was_showing: bool = false
var _last_change_frame: int = -1

# Called by the puzzle screen whenever it binds a session (setup, restart).
static func ensure(host: Control) -> Node:
	var node: Node = host.get_node_or_null("PuzzleTutorial")
	if node == null:
		node = (load("res://scripts/screens/puzzle_tutorial.gd") as GDScript).new()
		node.name = "PuzzleTutorial"
		node.screen = host
		host.add_child(node)
	node.bind(host.get("session"))
	return node

func bind(next_session: Variant) -> void:
	if next_session == null or next_session == session:
		return
	session = next_session
	_pick_guide()
	if guide == null:
		return
	if guide.has_level(label) and not session.protect_fn.is_valid():
		guide.protect(session, label)
	for pair in [[session.candy_found, _on_candy], [session.mistake_made, _on_mistake], [session.state_changed, _on_state], [session.protected_miss, _on_protected_miss]]:
		if not pair[0].is_connected(pair[1]): pair[0].connect(pair[1])
	if screen.undo_btn != null and not screen.undo_btn.pressed.is_connected(_on_undo):
		screen.undo_btn.pressed.connect(_on_undo)
	_board_before = session.board.duplicate(true)
	_shown_id = ""
	_ensure_ui()
	refresh()
	if session.phase == 0 and not guide.is_active(label, session.board):
		_show_tip(TutorialTips.tip_for("level_start", {"label": label, "size": int(session.level.get("size", 0))}, guide))

func _pick_guide() -> void:
	label = str(session.level.get("id", ""))
	if session.level.has(PRACTICE_KEY):
		label = str(session.level[PRACTICE_KEY])
		if guide == null: guide = TutorialGuide.new(null, true)
		return
	var rt: Variant = screen.get("runtime")
	guide = null if screen.get("_is_custom") or rt == null or not "tutorial" in rt else rt.tutorial

func _ensure_ui() -> void:
	if bubble == null:
		bubble = CoachBubble.new()
		bubble.visible = false
		var rules: Control = screen.rules_card
		rules.get_parent().add_child(bubble)
		rules.get_parent().move_child(bubble, rules.get_index() + 1)
		bubble.primary_pressed.connect(_on_primary)
		bubble.skip_pressed.connect(_on_skip)
	if overlay == null:
		overlay = TutorialOverlay.new()
		overlay.bind(screen.board.get_cell_rect)
		screen.board.get_parent().add_child(overlay)
	# Tutorial boards keep the bubble slot all level long so the board never jumps.
	bubble.visible = guide.has_level(label)

# Shows the step the guide derives from the current board.
func refresh() -> void:
	if guide == null or session == null:
		return
	var step: Dictionary = guide.current_step(label, session.board) if session.phase == 0 else {}
	var id: String = step.get("id", "")
	if id == _shown_id:
		return
	_shown_id = id
	if step.is_empty():
		if _tip_left <= 0.0 and bubble != null: bubble.clear()
		if overlay != null: overlay.clear()
		return
	_tip_left = 0.0
	bubble.show_message(_text(step), tr(step.button) if not step.button.is_empty() else "", step.skippable)
	overlay.show_marks(step.overlay, step.axis_rows, step.axis_cols)
	_pulse_rules(step.rules)
	if step.bounce_hint: _bounce(screen.hint_btn)
	if step.auto_ms > 0 and is_inside_tree():
		get_tree().create_timer(step.auto_ms / 1000.0).timeout.connect(_on_auto.bind(id))

func _text(step: Dictionary) -> String:
	return tr(step.text).format(step.args)

func _handle(event: String, cells: Array = []) -> void:
	if guide.handle(label, event, {"cells": cells}, session.board) or event == "candy":
		refresh()

func _on_primary() -> void:
	_handle("button")

func _on_skip() -> void:
	guide.skip()
	refresh()

func _on_auto(step_id: String) -> void:
	if step_id == _shown_id and session != null:
		_handle("timeout")

func _on_candy(row: int, col: int, _region: String) -> void:
	_board_before = session.board.duplicate(true)
	_handle("candy", [[row, col]])

func _on_state() -> void:
	_idle = 0.0
	_last_change_frame = Engine.get_process_frames()
	var marks: Array = []
	var clears: Array = []
	for r in range(session.board.size()):
		for c in range(session.board[r].size()):
			var was: int = _board_before[r][c] if r < _board_before.size() else CellModel.CellKind.BLANK
			var now: int = session.board[r][c]
			if was == CellModel.CellKind.BLANK and now == CellModel.CellKind.MARK: marks.append([r, c])
			elif was == CellModel.CellKind.MARK and now == CellModel.CellKind.BLANK: clears.append([r, c])
	_board_before = session.board.duplicate(true)
	if not marks.is_empty(): _handle("mark", marks)
	if not clears.is_empty(): _handle("clear", clears)
	if session.phase != 0: refresh()

func _on_mistake(_row: int, _col: int, _reason: String) -> void:
	_show_tip(TutorialTips.tip_for("mistake", {"hearts": session.hearts}, guide))

func _on_protected_miss(_row: int, _col: int) -> void:
	var step: Dictionary = guide.current_step(label, session.board)
	bubble.show_message(tr("tutorial.retry") + " " + (_text(step) if not step.is_empty() else ""), "", false)
	_shown_id = ""
	_tip_left = TIP_SEC

func _on_undo() -> void:
	if session != null and session.phase == 0 and session.mistake_count > 0 and _last_change_frame != Engine.get_process_frames():
		_show_tip(TutorialTips.tip_for("undo_blocked", {}, guide))

func _show_tip(tip: Dictionary) -> void:
	if tip.is_empty() or not guide.mark_seen(tip.id):
		return
	if tip.bounce_hint: _bounce(screen.hint_btn)
	if tip.text.is_empty():
		return
	if not bubble.visible:
		screen.rules_card.visible = false
		bubble.visible = true
	bubble.show_message(tr(tip.text).format(tip.args), "", false)
	_shown_id = ""
	_tip_left = TIP_SEC

func _end_tip() -> void:
	if not guide.has_level(label):
		bubble.clear()
		bubble.visible = false
		screen.rules_card.visible = true
	refresh()

func _process(delta: float) -> void:
	if guide == null or session == null or screen == null:
		return
	if _tip_left > 0.0:
		_tip_left -= delta
		if _tip_left <= 0.0: _end_tip()
	var showing: bool = screen.hint_coordinator.is_hint_showing()
	if _hint_was_showing and not showing: _handle("hint_closed")
	_hint_was_showing = showing
	if session.phase != 0 or showing or guide.is_active(label, session.board):
		_idle = 0.0
		return
	_idle += delta
	if _idle >= TutorialTips.IDLE_SECONDS:
		_idle = 0.0
		_show_tip(TutorialTips.tip_for("idle", {"hints_used": session.hints_used}, guide))

func _pulse_rules(keys: Array) -> void:
	var row: Node = screen.rules_card.get_child(0) if screen.rules_card.get_child_count() > 0 else null
	if row == null: return
	for i in range(mini(row.get_child_count(), RULE_KEYS.size())):
		if keys.has(RULE_KEYS[i]): _bounce(row.get_child(i), i * 0.18)

func _bounce(node: Control, delay: float = 0.0) -> void:
	if node == null or not LayoutTokens.motion_enabled or not node.is_inside_tree():
		return
	node.pivot_offset = node.size * 0.5
	var t := node.create_tween()
	t.tween_interval(delay)
	for _i in 2:
		t.tween_property(node, "scale", Vector2(1.08, 1.08), 0.14)
		t.tween_property(node, "scale", Vector2.ONE, 0.14)
