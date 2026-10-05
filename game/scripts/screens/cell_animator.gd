# cell_animator.gd
extends RefCounted

const TweenFx = preload("res://scripts/feedback/tween_fx.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")

static func play_candy_pop(board: Control, rect: Rect2) -> void:
	if rect.size.x <= 0:
		return
	var dummy := ColorRect.new()
	dummy.color = Color(Palette.CANDY_BROWN, 0.4)
	dummy.position = rect.position
	dummy.size = rect.size
	dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(dummy)
	var tw := TweenFx.scale_pop(dummy, 0.25)
	tw.finished.connect(func(): dummy.queue_free())

static func play_error_shake(board: Control) -> void:
	TweenFx.shake(board, 4.0, 0.25)

static func play_win_bounce(board: Control, session: Variant, cell_rect_fn: Callable) -> void:
	if session == null:
		return
	var n: int = int(session.level.get("size", 0))
	var delay: float = 0.0
	for r in range(n):
		for c in range(n):
			if CellModel.is_placed(session.board[r][c]):
				var rect: Rect2 = cell_rect_fn.call(r, c)
				if rect.size.x <= 0:
					continue
				var dummy := ColorRect.new()
				dummy.color = Color(Palette.CANDY_BROWN, 0.3)
				dummy.position = rect.position
				dummy.size = rect.size
				dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
				board.add_child(dummy)
				var tw := dummy.create_tween()
				tw.tween_interval(delay)
				tw.tween_callback(func():
					dummy.pivot_offset = dummy.size * 0.5
				)
				tw.tween_property(dummy, "scale", Vector2(1.15, 1.15), 0.15) \
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				tw.tween_property(dummy, "scale", Vector2.ONE, 0.15) \
					.set_ease(Tween.EASE_IN_OUT)
				tw.finished.connect(func(): dummy.queue_free())
				delay += 0.08
