extends HBoxContainer

signal loss_animation_finished()

const HeartIcon = preload("res://scripts/screens/heart_icon.gd")

func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	for index in range(3):
		var icon := HeartIcon.new()
		icon.name = "Heart%d" % index
		icon.break_finished.connect(_on_break_finished)
		add_child(icon)

func set_hearts(remaining: int, animate_loss: bool = false) -> void:
	for index in range(get_child_count()):
		get_child(index).set_alive(index < remaining, animate_loss)

func is_animating() -> bool:
	for icon in get_children():
		if icon.is_breaking(): return true
	return false

func _on_break_finished() -> void:
	if not is_animating(): loss_animation_finished.emit()
