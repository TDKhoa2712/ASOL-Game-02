# debug_reset_bar.gd
extends VBoxContainer

signal progress_reset(mode: String)

const Palette = preload("res://scripts/theme/palette.gd")

var _campaign_rt: Variant = null
var _endless_rt: Variant = null
var _status_lbl: Label

func _init() -> void:
	add_theme_constant_override("separation", 6)
	_build_ui()

func setup(campaign_rt: Variant, endless_rt: Variant) -> void:
	_campaign_rt = campaign_rt
	_endless_rt = endless_rt

func _build_ui() -> void:
	var title := Label.new()
	title.text = "🔄 Đặt lại tiến trình chơi (Reset Progress):"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Palette.INK)
	add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var btn_camp := _create_btn("Reset Campaign", reset_campaign)
	row.add_child(btn_camp)

	var btn_end := _create_btn("Reset Endless", reset_endless)
	row.add_child(btn_end)

	var btn_all := _create_btn("Reset Cả hai", reset_all)
	row.add_child(btn_all)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_font_size_override("font_size", 24)
	_status_lbl.add_theme_color_override("font_color", Color(0.1, 0.7, 0.3))
	add_child(_status_lbl)

func _create_btn(text: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(170, 58)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(action)
	return btn

func reset_campaign() -> void:
	if _campaign_rt != null and _campaign_rt.progress != null:
		var order: Array = _campaign_rt.playlist_order() if _campaign_rt.has_method("playlist_order") else []
		var first: String = str(order[0]) if not order.is_empty() else "L01"
		var endless_data: Dictionary = _campaign_rt.progress.get_endless_data()
		_campaign_rt.progress.current = _campaign_rt.progress.new_progress(first)
		if not endless_data.is_empty():
			_campaign_rt.progress.set_endless_data(endless_data)
		_campaign_rt.progress.save()
		if _campaign_rt.sessions != null: _campaign_rt.sessions.clear()
		_campaign_rt.current_session = null
		if _campaign_rt.has_method("reload"): _campaign_rt.reload()
	_set_status("✓ Đã reset tiến trình Campaign!")
	progress_reset.emit("campaign")

func reset_endless() -> void:
	if _endless_rt != null:
		if _endless_rt.progress != null:
			_endless_rt.progress.set_level_num(1)
		if _endless_rt.progress_manager != null:
			_endless_rt.progress_manager.set_endless_data({})
			_endless_rt.progress_manager.save()
		if _endless_rt.sessions != null:
			_endless_rt.sessions.clear()
		_endless_rt.current_session = null
	_set_status("✓ Đã reset tiến trình Endless!")
	progress_reset.emit("endless")

func reset_all() -> void:
	reset_campaign()
	reset_endless()
	_set_status("✓ Đã reset toàn bộ tiến trình!")
	progress_reset.emit("all")

func _set_status(msg: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg
