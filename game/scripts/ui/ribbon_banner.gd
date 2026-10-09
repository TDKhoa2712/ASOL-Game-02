# ribbon_banner.gd — 3D ribbon with folded tails and text label for result screens.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _label: Label
var _style: String
var _tails: _RibbonTails

func _init(text: String, style: String = "win") -> void:
	_style = style
	custom_minimum_size = Vector2(560, 96)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var colors := _get_colors()

	# 1. Background layer: Tails and fold triangles
	_tails = _RibbonTails.new(colors.tail, colors.fold)
	_tails.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tails.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tails)

	# 2. Main center banner
	var banner := PanelContainer.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.offset_left = 32
	banner.offset_right = -32
	banner.offset_bottom = -12

	var b_style := StyleBoxFlat.new()
	b_style.bg_color = colors.bg
	b_style.set_corner_radius_all(18)
	b_style.shadow_color = colors.shadow
	b_style.shadow_size = 8
	b_style.shadow_offset = Vector2(0, 8)
	banner.add_theme_stylebox_override("panel", b_style)
	add_child(banner)

	# 3. Label inside banner
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 38)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", colors.text_shadow)
	_label.add_theme_constant_override("shadow_offset_y", 4)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var heading := FontTokens.heading()
	if heading != null:
		_label.add_theme_font_override("font", heading)
	banner.add_child(_label)

func _get_colors() -> Dictionary:
	if _style == "lose":
		return {
			"bg": Palette.LOSE_RIBBON_BG,
			"shadow": Palette.LOSE_RIBBON_SHADOW,
			"tail": Palette.LOSE_RIBBON_TAIL,
			"fold": Palette.LOSE_RIBBON_FOLD,
			"text_shadow": Palette.LOSE_RIBBON_TEXT_SHADOW,
		}
	return {
		"bg": Palette.WIN_RIBBON_BG,
		"shadow": Palette.WIN_RIBBON_SHADOW,
		"tail": Palette.WIN_RIBBON_TAIL,
		"fold": Palette.WIN_RIBBON_FOLD,
		"text_shadow": Palette.WIN_RIBBON_TEXT_SHADOW,
	}

func animate() -> void:
	if not LayoutTokens.motion_enabled:
		return
	pivot_offset = Vector2(size.x * 0.5, 0)
	position.y -= 180
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", position.y + 180, 0.6)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

class _RibbonTails extends Control:
	var _tail_color: Color
	var _fold_color: Color

	func _init(tail: Color, fold: Color) -> void:
		_tail_color = tail
		_fold_color = fold

	func _draw() -> void:
		var w := size.x
		var h := size.y - 12.0
		var tail_w := 64.0
		var tail_h := 68.0
		var notch := 24.0
		var fold_w := 32.0
		var fold_h := 16.0

		# Left tail (swallowtail cut on left)
		var left_poly: PackedVector2Array = [
			Vector2(0, 16),
			Vector2(tail_w + 32, 16),
			Vector2(tail_w + 32, 16 + tail_h),
			Vector2(0, 16 + tail_h),
			Vector2(notch, 16 + tail_h * 0.5),
		]
		draw_colored_polygon(left_poly, _tail_color)

		# Right tail (swallowtail cut on right)
		var right_poly: PackedVector2Array = [
			Vector2(w - tail_w - 32, 16),
			Vector2(w, 16),
			Vector2(w - notch, 16 + tail_h * 0.5),
			Vector2(w, 16 + tail_h),
			Vector2(w - tail_w - 32, 16 + tail_h),
		]
		draw_colored_polygon(right_poly, _tail_color)

		# Left fold triangle
		var left_fold: PackedVector2Array = [
			Vector2(32, h),
			Vector2(32 + fold_w, h),
			Vector2(32, h + fold_h),
		]
		draw_colored_polygon(left_fold, _fold_color)

		# Right fold triangle
		var right_fold: PackedVector2Array = [
			Vector2(w - 32, h),
			Vector2(w - 32 - fold_w, h),
			Vector2(w - 32, h + fold_h),
		]
		draw_colored_polygon(right_fold, _fold_color)
