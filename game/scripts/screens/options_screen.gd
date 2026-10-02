# options_screen.gd
extends Control

signal back_pressed()

const ConfigStore = preload("res://scripts/state/config_store.gd")
const PillToggle = preload("res://scripts/screens/pill_toggle.gd")

const LABELS := {
	"audio": "Âm thanh",
	"haptic": "Rung phản hồi",
	"reduced_motion": "Giảm chuyển động",
	"high_contrast": "Độ tương phản cao",
	"large_text": "Cỡ chữ lớn",
}

var _config: Variant = null
var _built: bool = false

var back_btn: Button
var vbox: VBoxContainer

func _ensure_nodes() -> void:
	if back_btn == null:
		back_btn = get_node_or_null("Header/BackBtn") as Button
	if vbox == null:
		vbox = get_node_or_null("ScrollContainer/VBox") as VBoxContainer

func _ready() -> void:
	_ensure_nodes()
	if back_btn != null and not back_btn.pressed.is_connected(_on_back):
		back_btn.pressed.connect(_on_back)
	_build_rows()

func setup(config: Variant) -> void:
	_config = config
	_built = false
	_ensure_nodes()
	_build_rows()

func _build_rows() -> void:
	if vbox == null or _config == null or _built:
		return
	for child in vbox.get_children():
		child.queue_free()
	for key in ConfigStore.EDITABLE_KEYS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 44)
		var lbl := Label.new()
		lbl.text = LABELS.get(key, key)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		var toggle := PillToggle.new()
		toggle.set_on(bool(_config.get_option(key)))
		toggle.toggled_value.connect(func(on: bool): _on_toggle(key, on))
		row.add_child(toggle)

		vbox.add_child(row)
	_built = true

func _on_toggle(key: String, on: bool) -> void:
	if _config != null:
		_config.set_option(key, on)

func _on_back() -> void:
	back_pressed.emit()
