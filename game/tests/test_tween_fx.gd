# game/tests/test_tween_fx.gd
extends SceneTree

const TweenFx = preload("res://scripts/feedback/tween_fx.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_scale_pop_returns_tween()
	_test_shake_returns_tween()
	_test_flash_color_returns_tween()
	_test_bounce_returns_tween()
	_test_fade_in_returns_tween()
	_test_fade_out_returns_tween()
	_test_all_static_methods_exist()
	if _fails.is_empty():
		print("FEEDBACK_TWEEN_FX_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_scale_pop_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.scale_pop(c, 0.01)
	_assert(tw != null, "scale_pop returns a Tween")
	_assert(tw is Tween, "scale_pop returns Tween type")
	tw.kill()
	c.queue_free()

func _test_shake_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.shake(c, 4.0, 0.01)
	_assert(tw != null, "shake returns a Tween")
	tw.kill()
	c.queue_free()

func _test_flash_color_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.flash_color(c, Color.RED, 0.01)
	_assert(tw != null, "flash_color returns a Tween")
	tw.kill()
	c.queue_free()

func _test_bounce_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.bounce(c, 1.2, 0.01)
	_assert(tw != null, "bounce returns a Tween")
	tw.kill()
	c.queue_free()

func _test_fade_in_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	c.modulate.a = 0.0
	var tw := TweenFx.fade_in(c, 0.01)
	_assert(tw != null, "fade_in returns a Tween")
	tw.kill()
	c.queue_free()

func _test_fade_out_returns_tween() -> void:
	var c := Control.new()
	root.add_child(c)
	var tw := TweenFx.fade_out(c, 0.01)
	_assert(tw != null, "fade_out returns a Tween")
	tw.kill()
	c.queue_free()

func _test_all_static_methods_exist() -> void:
	var inst := TweenFx.new()
	_assert(inst.has_method("scale_pop"), "has scale_pop")
	_assert(inst.has_method("shake"), "has shake")
	_assert(inst.has_method("flash_color"), "has flash_color")
	_assert(inst.has_method("bounce"), "has bounce")
	_assert(inst.has_method("fade_in"), "has fade_in")
	_assert(inst.has_method("fade_out"), "has fade_out")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
