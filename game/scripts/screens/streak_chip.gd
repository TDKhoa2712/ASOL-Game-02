# Home streak chip: flame + day count; grey until today's play, pulses when at risk. Tap → streak screen (wired by title_screen).
extends Button

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const ON_COLOR := Color("#FF7A1A")
const OFF_COLOR := Color("#B9B4AC")
const ROW_HEIGHT := 84

var inventory: Variant = null
var at_risk := false
var count_label: Label
var flame: Control
var _pulse: Tween = null

static func attach(_screen: Control, safe: Control) -> Button:
	var row := CenterContainer.new()
	row.name = "StreakChipRow"
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip := new()
	row.add_child(chip)
	safe.add_child(row)
	return chip

func _init() -> void:
	name = "StreakChip"
	visible = false
	custom_minimum_size = Vector2(150, ROW_HEIGHT)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE; style.set_corner_radius_all(42)
	style.shadow_color = Color("#E2C46A"); style.shadow_size = 6; style.shadow_offset = Vector2(0, 6)
	for s in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(s, style)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)
	flame = FlameFx.new(52, 6)
	row.add_child(flame)
	count_label = Label.new()
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 36)
	var font := FontTokens.heading()
	if font != null: count_label.add_theme_font_override("font", font)
	row.add_child(count_label)

func bind(inv: Variant) -> void:
	inventory = inv
	visible = inventory != null
	refresh()

func refresh(today: String = "") -> void:
	if inventory == null:
		return
	var v: Dictionary = inventory.streak_view(today)
	var color: Color = ON_COLOR if v.kept_today else OFF_COLOR
	count_label.text = str(v.count)
	flame.set_lit(v.kept_today)
	count_label.add_theme_color_override("font_color", color.darkened(0.25))
	at_risk = v.at_risk
	_set_pulse(at_risk)

func _set_pulse(on: bool) -> void:
	if _pulse != null:
		_pulse.kill(); _pulse = null
	scale = Vector2.ONE
	if not on or not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	pivot_offset = custom_minimum_size * 0.5
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
