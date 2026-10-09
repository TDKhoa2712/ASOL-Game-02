# title_logo.gd — Animated "CanDoKu" wordmark: one sprite per glyph, wave + swirl spin + twinkles.
extends Control

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

const DIR := "res://assets/ui/home/logo/"
const SWIRL := "SWIRL"
const GLYPHS := ["letter_0_C", "letter_1_a", "letter_2_n", "letter_3_D", SWIRL, "letter_4_k", "letter_5_u"]
const TILTS := [-8.0, 4.0, -4.0, 6.0, 0.0, -6.0, 5.0]
const LETTER_SCALE := 1.3
const SWIRL_SIDE := 158.0
const OVERLAP := -16
const WAVE_PX := 16.0
const WAVE_HALF := 1.1
const WAVE_STAGGER := 0.12
const SWIRL_PERIOD := 6.0
# [anchor x (0..1), y px, side px, color, delay]
const TWINKLES := [[0.0, 10.0, 36.0, Color("#FFC93C"), 0.0], [0.99, 240.0, 44.0, Color("#FFC93C"), 0.8], [0.88, -14.0, 28.0, Color("#6FC3FF"), 1.3]]

var _row: HBoxContainer
var _glyphs: Array[TextureRect] = []
var _swirl: TextureRect = null

func _init() -> void:
	name = "CandyLogo"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(900, 300)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_row = HBoxContainer.new()
	_row.name = "Letters"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", OVERLAP)
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	for i in GLYPHS.size():
		_row.add_child(_make_slot(i))
	for t in TWINKLES:
		add_child(_make_twinkle(t))

func letter_count() -> int: return _glyphs.size()
func swirl() -> TextureRect: return _swirl

func _make_slot(i: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % i
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var img := TextureRect.new()
	img.name = "Img"
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GLYPHS[i] == SWIRL:
		img.texture = load(DIR + "swirl_candy.svg") as Texture2D
		img.size = Vector2.ONE * SWIRL_SIDE
		slot.custom_minimum_size = Vector2(SWIRL_SIDE + 8.0, 198.0 * LETTER_SCALE)
		img.position = Vector2(4.0, slot.custom_minimum_size.y - SWIRL_SIDE - 30.0)
		_swirl = img
	else:
		var tex := load(DIR + GLYPHS[i] + ".png") as Texture2D
		img.texture = tex
		img.size = tex.get_size() * LETTER_SCALE
		slot.custom_minimum_size = img.size
	img.pivot_offset = img.size * 0.5
	img.rotation_degrees = TILTS[i]
	slot.add_child(img)
	_glyphs.append(img)
	return slot

func _make_twinkle(t: Array) -> TextureRect:
	var star := TextureRect.new()
	star.texture = load(DIR + "sparkle.svg") as Texture2D
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.size = Vector2.ONE * float(t[2])
	star.pivot_offset = star.size * 0.5
	star.modulate = t[3]
	star.set_meta("anchor_x", t[0]); star.set_meta("y", t[1]); star.set_meta("delay", t[4])
	return star

func _ready() -> void:
	resized.connect(_place_twinkles)
	_place_twinkles()
	if not LayoutTokens.motion_enabled: return
	# Wait one frame so containers have laid out glyph positions.
	await get_tree().process_frame
	if not is_inside_tree(): return
	for i in _glyphs.size():
		_start_wave(_glyphs[i], i * WAVE_STAGGER)
	if _swirl != null:
		var sp := create_tween().set_loops()
		sp.tween_property(_swirl, "rotation", TAU, SWIRL_PERIOD).from(0.0)
	for child in get_children():
		if child is TextureRect: _start_twinkle(child)

func _start_wave(img: TextureRect, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree(): return
	var base := img.position.y
	var w := create_tween().set_loops()
	w.tween_property(img, "position:y", base - WAVE_PX, WAVE_HALF).set_trans(Tween.TRANS_SINE)
	w.tween_property(img, "position:y", base, WAVE_HALF).set_trans(Tween.TRANS_SINE)

func _start_twinkle(star: TextureRect) -> void:
	star.scale = Vector2.ONE * 0.4
	star.modulate.a = 0.3
	await get_tree().create_timer(float(star.get_meta("delay"))).timeout
	if not is_inside_tree(): return
	var tw := create_tween().set_loops()
	tw.tween_property(star, "scale", Vector2.ONE * 1.1, 0.9).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "modulate:a", 1.0, 0.9)
	tw.parallel().tween_property(star, "rotation_degrees", 45.0, 0.9).from(0.0)
	tw.tween_property(star, "scale", Vector2.ONE * 0.4, 0.9).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(star, "modulate:a", 0.3, 0.9)

func _place_twinkles() -> void:
	for child in get_children():
		if child is TextureRect and child.has_meta("anchor_x"):
			child.position = Vector2(size.x * float(child.get_meta("anchor_x")) - child.size.x * 0.5, float(child.get_meta("y")))
