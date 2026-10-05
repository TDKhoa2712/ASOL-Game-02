# game/scripts/feedback/tween_fx.gd
extends RefCounted

static func scale_pop(node: Control, duration: float = 0.25) -> Tween:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ZERO
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), duration * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func shake(node: Control, amplitude: float = 6.0, duration: float = 0.3) -> Tween:
	var origin_x: float = node.position.x
	var tw := node.create_tween()
	var steps: int = 6
	var step_dur: float = duration / float(steps)
	for i in range(steps):
		var offset: float = amplitude * (1.0 - float(i) / float(steps))
		var sign_val: float = -1.0 if i % 2 == 0 else 1.0
		tw.tween_property(node, "position:x", origin_x + offset * sign_val, step_dur)
	tw.tween_property(node, "position:x", origin_x, step_dur * 0.5)
	return tw

static func flash_color(node: Control, color: Color, duration: float = 0.2) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", color, duration * 0.4)
	tw.tween_property(node, "modulate", Color.WHITE, duration * 0.6)
	return tw

static func bounce(node: Control, scale_peak: float = 1.2, duration: float = 0.3) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * scale_peak, duration * 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.6) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func fade_in(node: Control, duration: float = 0.15) -> Tween:
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	return tw

static func fade_out(node: Control, duration: float = 0.15) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	return tw
