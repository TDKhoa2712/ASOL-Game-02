# tween_helpers.gd — Shared animation utilities for screen transitions.
extends RefCounted

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

## Fade in + slide up from below.
static func rise_in(node: Control, delay: float, dist: float = 60.0) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.modulate.a = 0.0
	var start_y := node.position.y
	node.position.y = start_y + dist
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(node, "position:y", start_y, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Gentle scale pulse loop for primary buttons.
static func pulse(node: Control, delay: float = 1.8) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween().set_loops()
	tw.tween_interval(maxf(delay, 0.01))
	tw.tween_property(node, "scale", Vector2(1.03, 1.03), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)

## Float up/down with optional rotation.
static func bob(node: Control, amount: float = 8.0, period: float = 3.2, rot_deg: float = 0.0) -> void:
	if not LayoutTokens.motion_enabled:
		return
	node.pivot_offset = node.size / 2.0
	var base := node.position.y
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "position:y", base - amount, period / 2.0).set_trans(Tween.TRANS_SINE)
	if rot_deg != 0.0:
		tw.parallel().tween_property(node, "rotation_degrees", rot_deg, period / 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "position:y", base, period / 2.0).set_trans(Tween.TRANS_SINE)
	if rot_deg != 0.0:
		tw.parallel().tween_property(node, "rotation_degrees", -rot_deg, period / 2.0).set_trans(Tween.TRANS_SINE)
