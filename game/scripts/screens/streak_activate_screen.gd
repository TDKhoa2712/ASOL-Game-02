# Full-screen step after the first finished round of the day: the flame ignites with a flash and
# spark burst, the count pops, today's cell fills, then Continue rises in. Timed to the
# STREAK_ACTIVATE sound. Renders only what setup() receives; never reads or writes save.
extends Control

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const SunburstRays = preload("res://scripts/ui/sunburst_rays.gd")
const GlowBurst = preload("res://scripts/ui/glow_burst.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

signal continued()

const FLAME_SIZE := 520.0
const CENTER_UV := Vector2(0.5, 0.34)
const TITLE_COLOR := Color("#B8501F")
const COUNT_COLOR := Color("#FF7A1A")
const COUNT_SHADOW := Color("#C24A10")

var view: Dictionary = {}
var content: Control
var rays: Control
var glow: GlowBurst
var flash: ColorRect
var title_label: Label
var flame_holder: Control
var flame: FlameFx
var count_label: Label
var days_label: Label
var strip: StreakCycleStrip
var continue_btn: Button
var _timeline: Tween = null
var _pending_play := false
var _fx: Tween = null

func setup(v: Dictionary) -> void:
	view = v.duplicate(true)
	_ensure_nodes()
	count_label.text = str(int(view.get("count", 0)))
	flame.set_lit(true)
	strip.show_view(view)
	_pending_play = false
	if not LayoutTokens.motion_enabled:
		finish()
	elif is_inside_tree():
		_play()
	else:
		_pending_play = true  # the router sets screens up before adding them

func is_animating() -> bool:
	return _timeline != null and _timeline.is_valid() and _timeline.is_running()

# Jumps every element to its resting state (reduced motion, tests, skipped timeline).
func finish() -> void:
	for t in [_timeline, _fx]:
		if t != null and t.is_valid(): t.kill()
	_timeline = null; _fx = null
	for n in [title_label, count_label, flame_holder, continue_btn, rays]:
		n.scale = Vector2.ONE; n.rotation = 0.0; n.modulate.a = 1.0
	content.position = Vector2.ZERO
	glow.glow = 0.8; glow.burst = 0.0
	flash.modulate.a = 0.0
	if strip.today_index() >= 0:
		strip.fill_today_animated()

func _ready() -> void:
	_ensure_nodes()
	if _pending_play:
		_pending_play = false
		_play()

func _play() -> void:
	for n in [title_label, count_label, continue_btn, rays]:
		n.modulate.a = 0.0
	flame_holder.scale = Vector2(0.0, 0.2)
	count_label.scale = Vector2(0.2, 0.2)
	count_label.rotation = deg_to_rad(-12)
	title_label.scale = Vector2(0.8, 0.8)
	_center_pivots()
	var tw := create_tween()
	_timeline = tw
	# Ignition: flame bursts up, light floods in.
	tw.tween_interval(0.3)
	tw.tween_property(flame_holder, "scale", Vector2(1.25, 1.35), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(flame_holder, "scale", Vector2(0.92, 0.95), 0.25)
	tw.parallel().tween_method(_shake, 1.0, 0.0, 0.25)
	tw.parallel().tween_property(title_label, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(flame_holder, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	# Light runs on its own track so it never stretches the main beats.
	var fx := create_tween().set_parallel()
	fx.tween_property(glow, "glow", 1.25, 0.5).set_delay(0.3)
	fx.tween_property(glow, "burst", 1.0, 0.9).set_delay(0.45)
	fx.tween_property(rays, "modulate:a", 1.0, 0.8).set_delay(0.5)
	fx.tween_property(flash, "modulate:a", 0.9, 0.1).set_delay(0.5)
	fx.tween_property(flash, "modulate:a", 0.0, 0.6).set_delay(0.6)
	fx.tween_property(glow, "glow", 0.8, 0.6).set_delay(0.95)
	_fx = fx
	# Count pops at ~1.4 s.
	tw.tween_property(count_label, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(count_label, "scale", Vector2(1.35, 1.35), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(count_label, "rotation", deg_to_rad(4), 0.3)
	tw.tween_property(count_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(count_label, "rotation", 0.0, 0.3)
	# Today's cell fills at ~2.2 s, Continue rises at ~3 s.
	tw.tween_interval(0.2)
	tw.tween_callback(strip.fill_today_animated)
	tw.tween_interval(0.6)
	tw.tween_property(continue_btn, "modulate:a", 1.0, 0.3)
	tw.tween_callback(func(): TweenHelpers.pulse(continue_btn, 0.6))

func _shake(strength: float) -> void:
	content.position = Vector2(randf_range(-14, 14), randf_range(-10, 10)) * strength

func _center_pivots() -> void:
	for n in [title_label, count_label]:
		n.pivot_offset = n.size * 0.5
		if not n.resized.is_connected(_center_pivots): n.resized.connect(_center_pivots)
	flame_holder.pivot_offset = Vector2(FLAME_SIZE * 0.5, FLAME_SIZE * 0.97)

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(GradientBg.new(Palette.WIN_BG_CENTER, Palette.WIN_BG_MID, Palette.WIN_BG_EDGE, CENTER_UV))
	rays = SunburstRays.new(CENTER_UV)
	add_child(rays)
	glow = GlowBurst.new(FLAME_SIZE * 0.62)
	add_child(glow)
	resized.connect(func(): glow.position = size * CENTER_UV)
	glow.position = size * CENTER_UV
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 200; box.offset_bottom = -120; box.offset_left = 60; box.offset_right = -60
	box.add_theme_constant_override("separation", 12)
	content.add_child(box)
	title_label = _label(box, tr("streak.activate_title"), 84, TITLE_COLOR, FontTokens.heading())
	flame_holder = Control.new()
	flame_holder.custom_minimum_size = Vector2(FLAME_SIZE, FLAME_SIZE)
	flame_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	flame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(flame_holder)
	flame = FlameFx.new(FLAME_SIZE, 1)
	flame_holder.add_child(flame)
	count_label = _label(box, "0", 240, COUNT_COLOR, FontTokens.heading())
	count_label.add_theme_color_override("font_shadow_color", COUNT_SHADOW)
	count_label.add_theme_constant_override("shadow_offset_y", 14)
	count_label.add_theme_constant_override("shadow_offset_x", 0)
	days_label = _label(box, tr("streak.days"), 52, Palette.WIN_TEXT_SECONDARY, FontTokens.body_bold())
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(64)
	sb.border_width_bottom = 14; sb.border_color = Palette.WIN_CARD_SHADOW
	sb.set_content_margin_all(32)
	card.add_theme_stylebox_override("panel", sb)
	box.add_child(card)
	strip = StreakCycleStrip.new()
	card.add_child(strip)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	continue_btn = ActionButton.create(tr("common.continue"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 60, 160, 14)
	continue_btn.custom_minimum_size.x = 720
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)
	flash = ColorRect.new()
	flash.color = Palette.WIN_BG_MID
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	add_child(flash)

func _label(parent: Control, text: String, font_size: int, color: Color, font: Font) -> Label:
	var l := Label.new(); l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if font != null: l.add_theme_font_override("font", font)
	parent.add_child(l)
	return l
