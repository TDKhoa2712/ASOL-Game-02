extends Control

signal break_finished()

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FULL = preload("res://assets/ui/board/heart.svg")
const EMPTY = preload("res://assets/ui/board/heart_off.svg")
const SHEET = preload("res://assets/ui/board/heart_sprite.png")
const DURATION := 0.80
const FRAME_ENDS := [0.08, 0.17, 0.26, 0.35, 0.45, 0.56, 0.67, DURATION]

var _alive := true
var _breaking := false
var _elapsed := 0.0

func _init() -> void:
	var hs: int = LayoutTokens.HEART_SIZE
	custom_minimum_size = Vector2(hs, hs)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	set_process(false)

func set_alive(alive: bool, animate: bool = false) -> void:
	if _alive == alive: return
	_alive = alive
	if not alive and animate and LayoutTokens.motion_enabled and is_inside_tree():
		_breaking = true
		_elapsed = 0.0
		set_process(true)
	else:
		_finish_break()
	queue_redraw()

func is_breaking() -> bool:
	return _breaking

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION or not LayoutTokens.motion_enabled:
		_finish_break()
	queue_redraw()

func _finish_break() -> void:
	var was_breaking := _breaking
	_breaking = false
	set_process(false)
	if was_breaking: break_finished.emit()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if not _breaking:
		draw_texture_rect(FULL if _alive else EMPTY, rect, false)
		return
	# Empty slot fades in underneath while the full heart squashes away.
	var t := _elapsed
	draw_texture_rect(EMPTY, rect, false, Color(1, 1, 1, clampf(t / 0.30, 0.0, 1.0)))
	var squash := 1.0 - _ease_out_back(clampf(t / 0.16, 0.0, 1.0)) * 0.15
	var full_alpha := 1.0 - clampf(t / 0.12, 0.0, 1.0)
	if full_alpha > 0.0:
		var fs := size * squash
		draw_texture_rect(FULL, Rect2((size - fs) * 0.5, fs), false, Color(1, 1, 1, full_alpha))
	# Cross-fade adjacent sheet frames so the 8-frame break reads as continuous.
	var frame := 0
	while frame < 7 and t >= FRAME_ENDS[frame]: frame += 1
	var start: float = 0.0 if frame == 0 else FRAME_ENDS[frame - 1]
	var blend := smoothstep(0.0, 1.0, (t - start) / maxf(FRAME_ENDS[frame] - start, 0.001))
	var grow := 1.0 + 0.55 * _ease_out_back(clampf(t / 0.24, 0.0, 1.0))
	var fall := smoothstep(0.0, 1.0, clampf((t - 0.22) / 0.50, 0.0, 1.0))
	var alpha := 1.0 - smoothstep(0.0, 1.0, clampf((t - 0.48) / 0.24, 0.0, 1.0))
	_draw_frame(frame, grow, fall, alpha * (1.0 - blend if frame < 7 else 1.0))
	if frame < 7: _draw_frame(frame + 1, grow, fall, alpha * blend)

func _draw_frame(frame: int, grow: float, fall: float, alpha: float) -> void:
	if alpha <= 0.0: return
	# The supplied sheet has uneven vertical spacing. Keep a common pivot,
	# retain the falling fragments, and exclude the other row of artwork.
	var source := Rect2((frame % 4) * 362, 150 if frame < 4 else 562, 362, 360 if frame < 4 else 460)
	var pixel_scale := size.x * 0.61 / 330.0 * grow
	var pivot := Vector2(size.x * 0.5, size.y * (0.54 + 1.0 * fall))
	var target := Rect2(pivot - Vector2(194, 175) * pixel_scale, source.size * pixel_scale)
	draw_texture_rect_region(SHEET, target, source, Color(1, 1, 1, alpha))

static func _ease_out_back(x: float) -> float:
	var c := 1.70158
	return 1.0 + (c + 1.0) * pow(x - 1.0, 3) + c * pow(x - 1.0, 2)
