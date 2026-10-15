# game/scripts/screens/debug_streak_panel.gd
# Debug picker tab: fake date, streak/cycle edits, assist stock, previews, count toggle.
extends VBoxContainer

signal changed()

const Palette = preload("res://scripts/theme/palette.gd")
const Ops = preload("res://scripts/state/assist_debug_ops.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")
const Preview = preload("res://scripts/screens/debug_streak_preview.gd")
const NavController = preload("res://scripts/campaign/nav_controller.gd")

var _inv: Variant = null
var _date_lbl: Label
var _stock_lbl: Label
var _cycle_spin: SpinBox
var _toggle: CheckButton

func _init() -> void:
	add_theme_constant_override("separation", 10)
	_build_ui()

func setup(assists: Variant) -> void:
	_inv = assists
	if _inv != null and _inv.clock == null:
		_inv.clock = DayClock.new()
	_toggle.set_pressed_no_signal(_inv != null and _inv.debug_counts_custom)
	_refresh()

func date_text() -> String:
	if _inv == null:
		return "Ngày: —"
	var tag := " (giả, %+d)" % _inv.clock.offset_days if _inv.clock.is_faked() else " (thật)"
	return "Ngày: " + _inv.current_day() + tag

func _build_ui() -> void:
	_date_lbl = _label("DateLabel")
	var day := _row()
	_btn(day, "PlusDay", "+1 ngày", func(): _shift(1))
	_btn(day, "SkipDay", "Bỏ lỡ 1 ngày (+2)", func(): _shift(2))
	_btn(day, "RealDay", "Về ngày thật", _real_day)
	var cyc := _row()
	_cycle_spin = SpinBox.new()
	_cycle_spin.name = "CycleSpin"
	_cycle_spin.min_value = 0
	_cycle_spin.max_value = 6
	cyc.add_child(_cycle_spin)
	_btn(cyc, "CycleApply", "Đặt vị trí chu kỳ", func(): _edit(func(d): return Ops.set_cycle(d, int(_cycle_spin.value), _inv.current_day())))
	_btn(cyc, "ResetStreak", "Reset chuỗi", func(): _edit(func(d): return Ops.reset_streak(d)))
	_stock_lbl = _label("StockLabel")
	var stock := _row()
	_btn(stock, "HintPlus", "+ hint", func(): _edit(func(d): return Ops.nudge(d, "hint", 1)))
	_btn(stock, "HintMinus", "- hint", func(): _edit(func(d): return Ops.nudge(d, "hint", -1)))
	_btn(stock, "PlacePlus", "+ place", func(): _edit(func(d): return Ops.nudge(d, "place", 1)))
	_btn(stock, "PlaceMinus", "- place", func(): _edit(func(d): return Ops.nudge(d, "place", -1)))
	_btn(stock, "ResetStock", "Reset kho", func(): _edit(func(d): return Ops.reset_stock(d)))
	var prev := _row()
	_btn(prev, "PreviewStreak", "Xem màn Chuỗi", func(): Preview.open(self, NavController.Screen.STREAK))
	_btn(prev, "PreviewActivate", "Xem Kích hoạt", func(): Preview.open(self, NavController.Screen.STREAK_ACTIVATE))
	_btn(prev, "PreviewGift", "Xem Nhận quà", func(): Preview.open(self, NavController.Screen.STREAK_GIFT))
	_toggle = CheckButton.new()
	_toggle.name = "CountToggle"
	_toggle.text = "Level debug tính chuỗi (chỉ phiên này)"
	_toggle.add_theme_font_size_override("font_size", 24)
	_toggle.toggled.connect(_on_toggle)
	add_child(_toggle)

func _shift(days: int) -> void:
	if _inv == null:
		return
	_inv.clock.advance(days)
	_refresh()

func _real_day() -> void:
	if _inv == null:
		return
	_inv.clock.reset()
	_refresh()

func _edit(op: Callable) -> void:
	if _inv == null:
		return
	_inv.replace_data(op.call(_inv.data))
	_refresh()

func _on_toggle(on: bool) -> void:
	if _inv != null:
		_inv.debug_counts_custom = on

func _refresh() -> void:
	_date_lbl.text = date_text()
	if _inv != null:
		var v: Dictionary = _inv.streak_view()
		_stock_lbl.text = "Chuỗi %d (kỷ lục %d), chu kỳ %d/7 — hint %d, place %d" % [v.count, v.best, v.cycle_done, _inv.count("hint"), _inv.count("place")]
	changed.emit()

func _label(n: String) -> Label:
	var l := Label.new()
	l.name = n
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Palette.INK)
	add_child(l)
	return l

func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	add_child(r)
	return r

func _btn(parent: Container, n: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = n
	b.text = text
	b.custom_minimum_size.y = 56
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
