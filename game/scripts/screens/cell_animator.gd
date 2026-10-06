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

static func draw_hand_drawn_x(canvas: CanvasItem, rect: Rect2, is_error: bool, high_contrast: bool, progress: float = 1.0) -> void:
	if progress <= 0.0 or rect.size.x <= 0.0:
		return
	var stroke_col: Color = Palette.ERROR_RED if is_error else (Palette.MARK_STROKE if high_contrast else Palette.MARK_WHITE)
	var pad := rect.size.x * 0.28
	var w := maxf(4.0, rect.size.x * (0.12 if high_contrast else 0.09))
	var p1_start := rect.position + Vector2(pad, pad)
	var p1_end := rect.end - Vector2(pad, pad)
	var p2_start := Vector2(rect.end.x - pad, rect.position.y + pad)
	var p2_end := Vector2(rect.position.x + pad, rect.end.y - pad)
	var t1 := clampf(progress / 0.5, 0.0, 1.0)
	var t2 := clampf((progress - 0.5) / 0.5, 0.0, 1.0)
	var bow_mag := rect.size.x * 0.022
	if t1 > 0.0:
		_draw_curved_stroke(canvas, p1_start, p1_end, t1, stroke_col, w, bow_mag)
	if t2 > 0.0:
		_draw_curved_stroke(canvas, p2_start, p2_end, t2, stroke_col, w, -bow_mag)
	if is_error and progress >= 0.8:
		var badge_center := rect.position + rect.size * Vector2(0.78, 0.22)
		canvas.draw_circle(badge_center, rect.size.x * 0.09, Palette.TEXT_ON_ACCENT)
		canvas.draw_circle(badge_center, rect.size.x * 0.07, Palette.ERROR_RED)

static func _draw_curved_stroke(canvas: CanvasItem, start_pt: Vector2, end_pt: Vector2, t: float, color: Color, width: float, bow: float) -> void:
	var delta := end_pt - start_pt
	var normal := Vector2(-delta.y, delta.x).normalized()
	var steps := maxi(2, int(ceil(t * 8.0)))
	var pts := PackedVector2Array()
	pts.resize(steps + 1)
	for i in range(steps + 1):
		var s := t * float(i) / float(steps)
		var arc := sin(s * PI) * bow
		pts[i] = start_pt.lerp(end_pt, s) + normal * arc
	if pts.size() >= 2:
		canvas.draw_polyline(pts, color, width, true)
		canvas.draw_circle(pts[0], width * 0.5, color)
		canvas.draw_circle(pts[pts.size() - 1], width * 0.5, color)
