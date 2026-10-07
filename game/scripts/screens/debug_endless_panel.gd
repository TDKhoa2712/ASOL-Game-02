# debug_endless_panel.gd
extends VBoxContainer

signal level_changed(level_data: Dictionary, label: String)

const EndlessConfigClass = preload("res://scripts/endless/endless_config.gd")
const EndlessProgressClass = preload("res://scripts/endless/endless_progress.gd")
const LevelSelectorClass = preload("res://scripts/endless/level_selector.gd")

var _bank: RefCounted = null
var _config: RefCounted = null
var _endless_rt: Variant = null

var _spin_level: SpinBox
var _info_label: Label
var _selected_level: Dictionary = {}
var _selected_label: String = ""

func _init() -> void:
	add_theme_constant_override("separation", 12)
	_build_ui()

func setup(bank: RefCounted, endless_rt: Variant = null) -> void:
	_bank = bank
	_endless_rt = endless_rt
	_config = endless_rt.config if (endless_rt != null and "config" in endless_rt) else EndlessConfigClass.default_config()
	if _endless_rt != null and _endless_rt.progress != null:
		_spin_level.value = _endless_rt.progress.get_level_num()
	else:
		_spin_level.value = 1
	_update_selection()

func get_selected_level() -> Dictionary: return _selected_level
func get_selected_label() -> String: return _selected_label

func _build_ui() -> void:
	var desc := Label.new()
	desc.text = "Chọn màn chơi Chế độ Vô tận (Endless Mode):"
	add_child(desc)

	var spin_row := HBoxContainer.new()
	spin_row.add_theme_constant_override("separation", 8)
	add_child(spin_row)

	var lbl := Label.new(); lbl.text = "Số level (Level #):"
	spin_row.add_child(lbl)

	_spin_level = SpinBox.new()
	_spin_level.min_value = 1
	_spin_level.max_value = 2000
	_spin_level.value = 1
	_spin_level.value_changed.connect(func(_v): _update_selection())
	spin_row.add_child(_spin_level)

	var quick_row := HBoxContainer.new()
	quick_row.add_theme_constant_override("separation", 6)
	add_child(quick_row)
	for step in [1, 5, 10, 50]:
		var btn := Button.new(); btn.text = "+%d" % step
		btn.pressed.connect(func(): _spin_level.value += step)
		quick_row.add_child(btn)
	var reset_btn := Button.new(); reset_btn.text = "Về Level 1"
	reset_btn.pressed.connect(func(): _spin_level.value = 1)
	quick_row.add_child(reset_btn)

	var info_panel := PanelContainer.new()
	_info_label = Label.new()
	_info_label.text = "Đang tải dữ liệu level..."
	info_panel.add_child(_info_label)
	add_child(info_panel)

func _update_selection() -> void:
	var lvl_num: int = int(_spin_level.value)
	var label := "Endless %d" % lvl_num
	if _bank == null:
		_info_label.text = "Chưa có bank dữ liệu"
		return

	var prog := EndlessProgressClass.new()
	prog.set_level_num(lvl_num)
	var cfg = _config if _config != null else EndlessConfigClass.default_config()
	var selector := LevelSelectorClass.new(_bank, cfg, prog)
	var lvl := selector.select_next_level()

	if lvl.is_empty():
		_info_label.text = "Không tìm thấy level phù hợp cho số level %d" % lvl_num
		_selected_level = {}
		_selected_label = ""
		return

	_selected_level = lvl.duplicate(true)
	_selected_level["id"] = label
	_selected_level["_endless_level_num"] = lvl_num
	_selected_label = label

	var sz: int = int(_selected_level.get("size", 4))
	var rank: int = int(_selected_level.get("rank", 1))
	var diff: String = str(_selected_level.get("difficulty", "normal"))
	var reg_cnt: int = _selected_level.get("regions", []).size()
	var giv_cnt: int = _selected_level.get("givens", []).size()

	_info_label.text = "Endless Level #%d | Size: %dx%d | Rank %d (%s)\nSố vùng: %d | Ô cho sẵn: %d" % [
		lvl_num, sz, sz, rank, diff, reg_cnt, giv_cnt
	]
	level_changed.emit(_selected_level, _selected_label)
