extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/title.tscn") as PackedScene
	var title: Control = packed.instantiate()
	root.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title._ensure_nodes()

	create_timer(0.05).timeout.connect(func():
		for node in title.find_children("*", "Control", true, false):
			var ms: Vector2 = node.get_combined_minimum_size()
			if ms.x > 600 or ms.y > 600:
				print("%s (%s): combined_min=%s custom_min=%s" % [node.name, node.get_class(), str(ms), str(node.custom_minimum_size)])
		quit()
	)
