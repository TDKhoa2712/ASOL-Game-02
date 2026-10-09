extends SceneTree

const TextScaler = preload("res://scripts/theme/text_scaler.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_scales_override_and_children()
	_test_disable_restores_base()
	_test_idempotent()
	_test_scales_theme_default_without_override()
	_test_tracks_code_resize()
	if _fails.is_empty():
		print("LARGE_TEXT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _tree() -> Control:
	var root := Control.new()
	var lbl := Label.new(); lbl.name = "L"; lbl.add_theme_font_size_override("font_size", 20); root.add_child(lbl)
	var box := VBoxContainer.new(); box.name = "Box"; root.add_child(box)
	var btn := Button.new(); btn.name = "B"; btn.add_theme_font_size_override("font_size", 40); box.add_child(btn)
	return root

func _size(n: Control) -> int:
	return n.get_theme_font_size("font_size")

func _test_scales_override_and_children() -> void:
	var r := _tree()
	TextScaler.apply(r, true)
	_assert(_size(r.get_node("L")) == int(round(20 * TextScaler.FACTOR)), "label scaled")
	_assert(_size(r.get_node("Box/B")) == int(round(40 * TextScaler.FACTOR)), "nested button scaled")
	r.free()

func _test_disable_restores_base() -> void:
	var r := _tree()
	TextScaler.apply(r, true); TextScaler.apply(r, false)
	_assert(_size(r.get_node("L")) == 20, "label restored")
	_assert(_size(r.get_node("Box/B")) == 40, "button restored")
	r.free()

func _test_idempotent() -> void:
	var r := _tree()
	TextScaler.apply(r, true); TextScaler.apply(r, true)
	_assert(_size(r.get_node("L")) == int(round(20 * TextScaler.FACTOR)), "no double scaling")
	r.free()

func _test_scales_theme_default_without_override() -> void:
	var lbl := Label.new()
	var base := _size(lbl)
	TextScaler.apply(lbl, true)
	_assert(_size(lbl) == int(round(base * TextScaler.FACTOR)), "default size scaled")
	TextScaler.apply(lbl, false)
	_assert(not lbl.has_theme_font_size_override("font_size"), "default override removed")
	lbl.free()

func _test_tracks_code_resize() -> void:
	var lbl := Label.new(); lbl.add_theme_font_size_override("font_size", 20)
	TextScaler.apply(lbl, true)
	lbl.add_theme_font_size_override("font_size", 30)
	TextScaler.apply(lbl, true)
	_assert(_size(lbl) == int(round(30 * TextScaler.FACTOR)), "new base picked up")
	lbl.free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)
