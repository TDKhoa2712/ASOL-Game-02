# progress_bar.gd — Animated campaign progress bar widget matching mockup.
extends PanelContainer

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _done: int = 0
var _total: int = 30
var _count_label: Label
var _fill_rect: ColorRect
var _bar_bg: PanelContainer

func _init(done: int = 0, total: int = 30) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_done = maxi(0, done)
	_total = maxi(1, total)
	if _done > _total: _done = _total

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(28)
	style.shadow_color = Color("#EFD27E")
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 7)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	add_child(stack)

	var top_row := HBoxContainer.new()
	stack.add_child(top_row)

	var lbl := Label.new()
	lbl.text = tr("title.progress")
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color("#4F5D86"))
	var bold := FontTokens.body_bold()
	if bold != null: lbl.add_theme_font_override("font", bold)
	top_row.add_child(lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	_count_label = Label.new()
	_update_label()
	_count_label.add_theme_font_size_override("font_size", 32)
	_count_label.add_theme_color_override("font_color", Color("#23365E"))
	var heading := FontTokens.heading()
	if heading != null: _count_label.add_theme_font_override("font", heading)
	top_row.add_child(_count_label)

	_bar_bg = PanelContainer.new()
	_bar_bg.custom_minimum_size = Vector2(0, 32)
	_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Palette.HOME_PROGRESS_BG
	track_style.set_corner_radius_all(16)
	_bar_bg.add_theme_stylebox_override("panel", track_style)
	_bar_bg.clip_contents = true
	stack.add_child(_bar_bg)

	_fill_rect = ColorRect.new()
	_fill_rect.color = Palette.HOME_PROGRESS_FILL
	_fill_rect.custom_minimum_size = Vector2(0, 32)
	_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bg.add_child(_fill_rect)

func _update_label() -> void:
	if _count_label == null: return
	var loc := TranslationServer.get_locale()
	if loc.begins_with("vi"):
		_count_label.text = "%d / %d màn" % [_done, _total]
	else:
		_count_label.text = "%d / %d" % [_done, _total]

func set_progress(done: int, total: int) -> void:
	_done = maxi(0, done)
	_total = maxi(1, total)
	if _done > _total: _done = _total
	_update_label()
	_update_fill()

func _update_fill() -> void:
	if _fill_rect == null or _bar_bg == null: return
	var pct := float(_done) / float(_total)
	_fill_rect.size.x = _bar_bg.size.x * pct

func animate() -> void:
	if _fill_rect == null: return
	var pct := float(_done) / float(_total)
	if not LayoutTokens.motion_enabled:
		_fill_rect.scale.x = pct
		return
	_fill_rect.scale.x = 0.0
	_fill_rect.pivot_offset = Vector2.ZERO
	var tw := _fill_rect.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(_fill_rect, "scale:x", pct, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
