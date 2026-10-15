# Day-7 step: the gift box drops in, shakes, bursts open with confetti, then the hint and
# candy-drop rewards fly out. Timed to the STREAK_GIFT sound.
# Renders only what setup() receives; never reads or writes save (debug previews reuse it).
extends Control

const GradientBg = preload("res://scripts/ui/gradient_bg.gd")
const SunburstRays = preload("res://scripts/ui/sunburst_rays.gd")
const GlowBurst = preload("res://scripts/ui/glow_burst.gd")
const ConfettiLayer = preload("res://scripts/ui/confetti_layer.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const TweenHelpers = preload("res://scripts/ui/tween_helpers.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

signal continued()

const BOX_SIZE := 500.0
const CENTER_UV := Vector2(0.5, 0.38)
const TITLE_COLOR := Color("#C02C52")
const BG_MID := Color("#FFF1F4")
const BG_EDGE := Color("#FFD6A8")
const HINT_ICON := "res://assets/ui/board/icon_hint.svg"
const PLACE_ICON := "res://assets/candy/candy_icon.png"

var reward: Dictionary = {}
var rays: Control
var glow: GlowBurst
var confetti: ConfettiLayer
var title_label: Label
var gift: GiftBoxView
var hint_card: PanelContainer
var place_card: PanelContainer
var hint_label: Label
var place_label: Label
var continue_btn: Button
var _timeline: Tween = null
var _pending_play := false
var _fx: Tween = null

func setup(r: Dictionary) -> void:
	reward = r.duplicate(true)
	_ensure_nodes()
	hint_label.text = tr("streak.gift_hint") % maxi(0, int(reward.get("hint", 0)))
	place_label.text = tr("streak.gift_place") % maxi(0, int(reward.get("place", 0)))
	_pending_play = false
	if not LayoutTokens.motion_enabled:
		finish()
	elif is_inside_tree():
		_play()
	else:
		_pending_play = true  # the router sets screens up before adding them

func is_animating() -> bool:
	return _timeline != null and _timeline.is_valid() and _timeline.is_running()

func finish() -> void:
	for t in [_timeline, _fx]:
		if t != null and t.is_valid(): t.kill()
	_timeline = null; _fx = null
	gift.position.y = 0.0
	if not gift.is_open:
		gift.finish_open()
	for n in [title_label, hint_card, place_card, continue_btn, rays]:
		n.modulate.a = 1.0; n.scale = Vector2.ONE
	glow.glow = 0.9; glow.burst = 0.0

func _ready() -> void:
	_ensure_nodes()
	if _pending_play:
		_pending_play = false
		_play()

func _play() -> void:
	for n in [title_label, hint_card, place_card, continue_btn, rays]:
		n.modulate.a = 0.0
	title_label.scale = Vector2(0.4, 0.4)
	for c in [hint_card, place_card]: c.scale = Vector2(0.2, 0.2)
	gift.play_idle()
	gift.position.y = -1400.0
	var tw := create_tween()
	_timeline = tw
	# Drop and land with a squash (~0.54 s).
	tw.tween_property(gift, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(gift, "squash", 1.0, 0.08)
	tw.tween_property(gift, "squash", -0.4, 0.14)
	tw.tween_property(gift, "squash", 0.0, 0.18)
	# Shake starts ~1.2 s; the lid pops ~1.86 s.
	tw.tween_interval(0.3)
	tw.tween_callback(gift.play_open)
	tw.tween_interval(GiftBoxView.SHAKE_TIME + 0.05)
	tw.tween_callback(_burst)
	tw.tween_interval(0.55)
	# Title ~2.5 s, rewards ~3.0 s, Continue ~3.9 s.
	tw.tween_property(title_label, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for c in [hint_card, place_card]:
		tw.tween_property(c, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(c, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	tw.tween_property(continue_btn, "modulate:a", 1.0, 0.3)
	tw.tween_callback(func(): TweenHelpers.pulse(continue_btn, 0.6))

# Light and confetti run on their own track so they never stretch the main beats.
func _burst() -> void:
	confetti.start()
	_fx = create_tween().set_parallel()
	_fx.tween_property(glow, "glow", 1.3, 0.25)
	_fx.tween_property(glow, "burst", 1.0, 0.9)
	_fx.tween_property(rays, "modulate:a", 1.0, 0.6)
	_fx.tween_property(glow, "glow", 0.9, 0.4).set_delay(0.25)

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(GradientBg.new(Color.WHITE, BG_MID, BG_EDGE, CENTER_UV))
	rays = SunburstRays.new(CENTER_UV)
	add_child(rays)
	glow = GlowBurst.new(BOX_SIZE * 0.7)
	add_child(glow)
	resized.connect(func(): glow.position = size * CENTER_UV)
	glow.position = size * CENTER_UV
	confetti = ConfettiLayer.new(60)
	add_child(confetti)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 220; box.offset_bottom = -120; box.offset_left = 60; box.offset_right = -60
	box.add_theme_constant_override("separation", 40)
	add_child(box)
	title_label = Label.new(); title_label.text = tr("streak.gift_title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 92)
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	title_label.add_theme_color_override("font_shadow_color", Color.WHITE)
	title_label.add_theme_constant_override("shadow_offset_y", 8)
	if FontTokens.heading() != null: title_label.add_theme_font_override("font", FontTokens.heading())
	title_label.resized.connect(func(): title_label.pivot_offset = title_label.size * 0.5)
	box.add_child(title_label)
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(BOX_SIZE, BOX_SIZE)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(slot)
	gift = GiftBoxView.create()
	gift.custom_minimum_size = Vector2(BOX_SIZE, BOX_SIZE)
	gift.size = Vector2(BOX_SIZE, BOX_SIZE)
	slot.add_child(gift)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	box.add_child(row)
	hint_card = _card(row, HINT_ICON, Palette.BOARD_HINT_BG, Palette.WIN_STAT_ICON_SHADOW_TIME)
	hint_label = hint_card.get_meta("label")
	place_card = _card(row, PLACE_ICON, Palette.WIN_STAT_ICON_BG_ERR, Palette.WIN_STAT_ICON_SHADOW_ERR)
	place_label = place_card.get_meta("label")
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	continue_btn = ActionButton.create(tr("common.continue"), Palette.WIN_BUTTON_BG, Palette.WIN_BUTTON_SHADOW, Palette.WIN_BUTTON_TEXT_SHADOW, 60, 160, 14)
	continue_btn.custom_minimum_size.x = 720
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)

func _card(parent: Control, icon_path: String, icon_bg: Color, edge: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(64)
	sb.border_width_bottom = 14; sb.border_color = edge
	sb.set_content_margin_all(36)
	card.add_theme_stylebox_override("panel", sb)
	card.resized.connect(func(): card.pivot_offset = card.size * 0.5)
	parent.add_child(card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	card.add_child(col)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(150, 150)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = icon_bg; bsb.set_corner_radius_all(75); bsb.set_content_margin_all(28)
	badge.add_theme_stylebox_override("panel", bsb)
	col.add_child(badge)
	var icon := TextureRect.new()
	if ResourceLoader.exists(icon_path): icon.texture = load(icon_path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_path == HINT_ICON: icon.modulate = Palette.BOARD_HINT_ICON
	badge.add_child(icon)
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 48)
	l.add_theme_color_override("font_color", Palette.WIN_TEXT_PRIMARY)
	if FontTokens.body_bold() != null: l.add_theme_font_override("font", FontTokens.body_bold())
	col.add_child(l)
	card.set_meta("label", l)
	return card
