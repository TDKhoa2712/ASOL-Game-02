extends Control

signal break_finished()

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FULL = preload("res://assets/ui/board/button_heart.png")
const EMPTY = preload("res://assets/ui/board/button_heart_empty.png")
const SHEET = preload("res://assets/ui/board/heart_sprite.png")
const DURATION := 0.72
const FRAME_ENDS := [0.06, 0.14, 0.22, 0.30, 0.40, 0.50, 0.60, DURATION]

var _alive := true
var _breaking := false
var _elapsed := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(36, 36)
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
	draw_texture_rect(FULL if _alive else EMPTY, Rect2(Vector2.ZERO, size), false)
	if not _breaking: return
	var frame := 0
	while frame < 7 and _elapsed >= FRAME_ENDS[frame]: frame += 1
	# The supplied sheet has uneven vertical spacing. Keep a common pivot,
	# retain the falling fragments, and exclude the other row of artwork.
	var source := Rect2((frame % 4) * 362, 150 if frame < 4 else 562, 362, 360 if frame < 4 else 460)
	var grow := 1.0 + 0.65 * clampf(_elapsed / 0.22, 0.0, 1.0)
	var pixel_scale := size.x * 0.61 / 330.0 * grow
	var fall := clampf((_elapsed - 0.22) / 0.60, 0.0, 1.0)
	var pivot := Vector2(size.x * 0.5, size.y * 0.54 + 50.0 * fall * fall)
	var target := Rect2(pivot - Vector2(194, 175) * pixel_scale, source.size * pixel_scale)
	var alpha := 1.0 - clampf((_elapsed - 0.54) / 0.18, 0.0, 1.0)
	draw_texture_rect_region(SHEET, target, source, Color(1, 1, 1, alpha))
