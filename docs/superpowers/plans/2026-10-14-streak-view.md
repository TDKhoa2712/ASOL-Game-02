# Xem chuỗi ngày chơi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Viên lửa chuỗi ở giữa phía trên Home, bảng chuỗi khi chạm, và hiệu ứng +1 khi giữ chuỗi.

**Architecture:** Mở rộng `assist_rules.gd` (thêm `totalStreak`, `bestStreak`, `streak_view`) và `assist_inventory.gd` (signal `streak_extended`, `streak_view()`). UI tách thành `streak_chip.gd` (viên lửa + tự gắn vào Home), `streak_sheet.gd` (bảng), `streak_burst.gd` (hiệu ứng). Home nhận inventory qua `app_shell`; màn chơi chạy burst qua `puzzle_assist_controller.gd`.

**Tech Stack:** Godot 4.7 / GDScript, test headless `extends SceneTree`.

**Spec:** [2026-10-14-streak-view-design.md](../specs/2026-10-14-streak-view-design.md)

## Global Constraints

- `totalStreak` không reset khi nhận gói 7 ngày; lỡ ngày → 1; `bestStreak = max(bestStreak, totalStreak)`; thiếu trường → 0.
- `count` = `totalStreak` khi lần thắng gần nhất là hôm nay/hôm qua, ngược lại 0; `at_risk` = `count > 0` và chưa giữ hôm nay.
- Viên lửa canh giữa ngang, cùng hàng nút Trợ giúp/Cài đặt; cam khi đã giữ hôm nay, xám khi chưa; nhấp nháy khi at_risk (tắt khi `LayoutTokens.motion_enabled == false`); luôn hiện khi có inventory.
- Popup "Hết lượt" không hiển thị streak.
- Icon lửa vẽ mới; câu chữ gốc, không ký tự emoji/biểu tượng ngoài font (Web glyph test); đủ 7 cột locale `en,ja,vi,id,pt_BR,es,ko`.
- Không autoload; mỗi file ≤ 300 dòng; `app_shell.gd` đang đúng 300 dòng — chỉ sửa trên dòng có sẵn.
- Commit Conventional Commits, kết thúc `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Qua nửa đêm khi đang ở Home** → viên lửa chỉ cập nhật khi Home dựng lại; chấp nhận được, không crash. (Không test; ghi ở review.)
2. **Đồng hồ lùi (lastStreakDate ở tương lai)** → `count` = 0, không lỗi. (Test: Task 1 "future date view".)
3. **Lỡ ngày khi chuỗi đang là 1** → lần thắng mới vẫn phát `streak_extended(1)` và chạy burst. (Test: Task 1 inventory "restart from 1 emits".)
4. **Level custom/debug** → không burst, không đổi chuỗi. (Đã có `test_assist_flow` "custom win does not count"; Task 3 thêm assert không có node `StreakBurst`.)
5. **Chạm viên lửa khi chưa có inventory (test/tutorial)** → viên lửa ẩn, không lỗi. (Test: Task 2 "chip hidden without stock".)

---

## File Structure

| File | Loại | Trách nhiệm |
|---|---|---|
| `game/scripts/state/assist_rules.gd` | sửa | Trường mới, luật tổng/kỷ lục, `streak_view` |
| `game/scripts/state/assist_inventory.gd` | sửa | `signal streak_extended(total)`, `streak_view()` |
| `game/assets/ui/home/icon_flame.svg` | mới | Icon lửa trắng (tô bằng modulate) |
| `game/scripts/screens/streak_sheet.gd` | mới | Bảng chuỗi |
| `game/scripts/screens/streak_chip.gd` | mới | Viên lửa, `attach()` vào Home |
| `game/scripts/screens/streak_burst.gd` | mới | Hiệu ứng +1 |
| `game/scripts/screens/assist_dock.gd` | sửa | `show_toast(..., delay)` |
| `game/scripts/screens/puzzle_assist_controller.gd` | sửa | Burst + toast trễ |
| `game/scripts/screens/title_screen.gd` | sửa | Gắn viên lửa, bind trong `setup` |
| `game/scripts/screens/app_shell.gd` | sửa | Gán `assists` cho Home |
| `game/locale/strings.csv` | sửa | Key `streak.*` |
| `game/tests/test_assist_rules.gd`, `test_assist_inventory.gd` | sửa | Test luật/inventory |
| `game/tests/test_streak_ui.gd`, `test_streak_burst.gd` | mới | Test UI |

Chạy test: `godot --headless --path game --script res://tests/<file>.gd` (Godot 4.7.2 console exe; máy này không có `godot` trong PATH — dùng đường dẫn WinGet đầy đủ).

---

### Task 1: Luật tổng chuỗi, kỷ lục, `streak_view`, signal

**Files:**
- Modify: `game/scripts/state/assist_rules.gd`
- Modify: `game/scripts/state/assist_inventory.gd`
- Test: `game/tests/test_assist_rules.gd`, `game/tests/test_assist_inventory.gd`

**Interfaces:**
- Produces:
  - `new_data()` thêm `"totalStreak": 0, "bestStreak": 0`
  - `static func streak_view(data: Dictionary, today_date: String) -> Dictionary` → `{"count": int, "best": int, "kept_today": bool, "at_risk": bool, "cycle_done": int}`
  - Inventory: `signal streak_extended(total: int)` (phát mỗi khi `on_level_won` ghi nhận một ngày mới), `func streak_view(today: String = "") -> Dictionary`

- [ ] **Step 1: Write the failing tests**

Trong `test_assist_rules.gd`, thêm `_test_total_and_view()` vào `_init` (sau `_test_streak()`) và hàm:

```gdscript
func _test_total_and_view() -> void:
	var d := Rules.new_data()
	check(d.totalStreak == 0 and d.bestStreak == 0, "start total/best 0")
	var cur := d
	for day in range(1, 10):
		cur = Rules.record_win(cur, "2026-05-%02d" % day).data
	check(cur.totalStreak == 9, "total keeps counting across the 7-day pack")
	check(cur.bestStreak == 9, "best follows total")
	check(cur.streakDays == 2, "cycle restarted after day 7")
	var v := Rules.streak_view(cur, "2026-05-09")
	check(v == {"count": 9, "best": 9, "kept_today": true, "at_risk": false, "cycle_done": 2}, "view kept today")
	v = Rules.streak_view(cur, "2026-05-10")
	check(v.count == 9 and not v.kept_today and v.at_risk, "view at risk next day")
	v = Rules.streak_view(cur, "2026-05-12")
	check(v.count == 0 and not v.at_risk and v.cycle_done == 0 and v.best == 9, "view broken streak")
	check(Rules.streak_view(cur, "2026-04-01").count == 0, "future date view")
	var restarted: Dictionary = Rules.record_win(cur, "2026-05-12").data
	check(restarted.totalStreak == 1 and restarted.bestStreak == 9, "missed day restarts total, keeps best")
	var s := Rules.sanitize({"totalStreak": 4, "bestStreak": 2})
	check(s.totalStreak == 4 and s.bestStreak == 4, "sanitize best >= total")
	check(Rules.sanitize({"totalStreak": -3}).totalStreak == 0, "sanitize negative total")
	check(Rules.streak_view(Rules.new_data(), "2026-05-01").count == 0, "fresh view zero")
```

Trong `test_assist_inventory.gd`, trước `DirAccess.remove_absolute(dir)` thêm:

```gdscript
	var sdir := dir + "_streak"
	var s_inv := Inventory.new(sdir)
	var totals: Array = []
	s_inv.streak_extended.connect(func(t): totals.append(t))
	s_inv.on_level_won("2026-06-01")
	s_inv.on_level_won("2026-06-01")
	s_inv.on_level_won("2026-06-03")
	check(totals == [1, 1], "restart from 1 emits; same day silent")
	check(s_inv.streak_view("2026-06-03").kept_today, "inventory view")
	s_inv._store.remove_all()
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `test_assist_rules.gd`, `test_assist_inventory.gd`
Expected: FAIL (`totalStreak` thiếu / `streak_view` không tồn tại).

- [ ] **Step 3: Implement**

`assist_rules.gd`:
- `new_data()` thêm `"totalStreak": 0, "bestStreak": 0`.
- `sanitize`: trước `return out` thêm

```gdscript
	out.totalStreak = _int_in(raw.get("totalStreak"), 0, 100000, 0)
	out.bestStreak = maxi(_int_in(raw.get("bestStreak"), 0, 100000, 0), out.totalStreak)
```

- `record_win`: trong nhánh `if gap == 1:` thêm `next.totalStreak = int(next.get("totalStreak", 0)) + 1`; trong nhánh `else:` thêm `next.totalStreak = 1`; ngay sau khối if/else thêm `next.bestStreak = maxi(int(next.get("bestStreak", 0)), int(next.totalStreak))`.
- Thêm:

```gdscript
static func streak_view(data: Dictionary, today_date: String) -> Dictionary:
	var last: String = data.get("lastStreakDate", "")
	var gap := day_gap(last, today_date) if last != "" else INVALID_GAP
	var alive := gap == 0 or gap == 1
	var count := int(data.get("totalStreak", 0)) if alive else 0
	return {"count": count, "best": int(data.get("bestStreak", 0)), "kept_today": gap == 0,
		"at_risk": count > 0 and gap != 0, "cycle_done": int(data.get("streakDays", 0)) if alive else 0}
```

`assist_inventory.gd`:
- Thêm `signal streak_extended(total: int)`.
- Trong `on_level_won`, sau `_commit(res.data, res.reward.keys())` thêm `streak_extended.emit(int(data.get("totalStreak", 0)))`.
- Thêm:

```gdscript
func streak_view(today: String = "") -> Dictionary:
	return AssistRules.streak_view(data, today if today != "" else AssistRules.today())
```

- [ ] **Step 4: Run tests — expect PASS**

`test_assist_rules.gd` → `ASSIST_RULES_PASS`; `test_assist_inventory.gd` → `ASSIST_INVENTORY_PASS`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/state/assist_rules.gd game/scripts/state/assist_inventory.gd game/tests/test_assist_rules.gd game/tests/test_assist_inventory.gd
git commit -m "feat(state): track total and best play streak with a view model"
```

---

### Task 2: Viên lửa + bảng chuỗi trên Home

**Files:**
- Create: `game/assets/ui/home/icon_flame.svg`
- Create: `game/scripts/screens/streak_sheet.gd`
- Create: `game/scripts/screens/streak_chip.gd`
- Modify: `game/scripts/screens/title_screen.gd` (preload, biến, sau dòng `frame.add_child(bottom_spacer)`, `setup`)
- Modify: `game/scripts/screens/app_shell.gd` (dòng `screen.call("setup", runtime, endless_runtime)` trong nhánh `"title"`)
- Modify: `game/locale/strings.csv`
- Test: `game/tests/test_streak_ui.gd`

**Interfaces:**
- Consumes: Task 1 `inventory.streak_view(today)`.
- Produces:
  - `StreakChip` (`extends Button`): `static func attach(screen: Control, safe: Control) -> Button`; `func bind(inv: Variant) -> void`; `func refresh(today: String = "") -> void`; `var sheet`; `var at_risk: bool`; `var count_label: Label`; `var icon_rect: TextureRect`; `const ON_COLOR`, `const OFF_COLOR`
  - `StreakSheet` (`extends Control`): `func open(view: Dictionary) -> void`; `func close() -> void`; `var count_label, best_label, left_label, status_label: Label`; `var cells: Array` (7 `PanelContainer`, ô đạt có meta `"done" = true`)
  - `title_screen.gd`: `var assists: Variant = null`, `var streak_chip: Button`

- [ ] **Step 1: Write the failing test**

`game/tests/test_streak_ui.gd`:

```gdscript
extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
const Rules = preload("res://scripts/state/assist_rules.gd")
const StreakChip = preload("res://scripts/screens/streak_chip.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var today := Rules.today()
	var yesterday := Time.get_date_string_from_unix_time(Rules._unix(today) - 86400)
	var dir := OS.get_user_data_dir().path_join("streak_ui_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.on_level_won(yesterday)  # streak 1, not kept today -> at risk

	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	title.assists = inv
	root.add_child(title)
	title.setup(null)
	var chip: Button = title.streak_chip
	check(chip != null and chip.visible, "chip on home")
	check(chip.get_parent() is CenterContainer, "chip centered horizontally")
	check(chip.count_label.text == "1", "chip shows count")
	check(chip.icon_rect.modulate == StreakChip.OFF_COLOR, "grey before today's win")
	check(chip.at_risk, "at risk flagged")
	chip.pressed.emit()
	var sheet: Control = chip.sheet
	check(sheet.visible, "sheet opens on tap")
	check(sheet.count_label.text == "1", "sheet count")
	check(sheet.cells.size() == 7, "seven cycle cells")
	check(sheet.cells.filter(func(c): return c.get_meta("done", false)).size() == 1, "one cell done")
	check(sheet.status_label.text == title.tr("streak.at_risk"), "at-risk status")
	sheet.close()
	check(not sheet.visible, "sheet closes")

	inv.on_level_won(today)
	chip.refresh()
	check(chip.count_label.text == "2" and chip.icon_rect.modulate == StreakChip.ON_COLOR, "orange after today's win")
	check(not chip.at_risk, "not at risk once kept")
	chip.pressed.emit()
	check(sheet.status_label.text == title.tr("streak.kept"), "kept status")
	check(sheet.best_label.text == title.tr("streak.best") % 2, "best line")

	var bare: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(bare)
	bare.setup(null)
	check(not bare.streak_chip.visible, "chip hidden without stock")

	title.queue_free(); bare.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_UI_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Nếu `TutorialScreen.attach(self, null)` trong `setup` phủ lớp tutorial hoặc lỗi với runtime null, đọc `game/scripts/screens/tutorial_screen.gd` `attach` và truyền `MockRuntime` giống `test_screens.gd` (ghi Ruling).

- [ ] **Step 2: Run — expect FAIL**

Run: `test_streak_ui.gd` → FAIL (`streak_chip.gd` không tồn tại).

- [ ] **Step 3: Implement**

`game/assets/ui/home/icon_flame.svg` (gốc, trắng):

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <path fill="#FFFFFF" d="M33 3c2 9-3 14-8 20-5 6-10 12-10 21 0 11 8 18 17 18s17-7 17-18c0-7-3-12-7-16 0 5-2 9-6 10 2-6 1-12-1-17-1-6 0-12-2-18z"/>
  <path fill="#FFFFFF" fill-opacity="0.55" d="M32 34c-4 4-7 8-7 13 0 5 3 8 7 8s7-3 7-8c0-3-2-6-4-8 0 3-1 5-3 5 1-4 1-7 0-10z"/>
</svg>
```

`game/scripts/screens/streak_sheet.gd`:

```gdscript
# Streak sheet: big flame, day count, best, 7-day pack progress and today's status.
extends Control

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const FLAME := "res://assets/ui/home/icon_flame.svg"
const GIFT := "res://assets/candy/candy_icon.png"
const ON_COLOR := Color("#FF7A1A")
const OFF_COLOR := Color("#B9B4AC")
const INK := Color("#23365E")

var flame: TextureRect
var count_label: Label
var days_label: Label
var best_label: Label
var left_label: Label
var status_label: Label
var close_btn: Button
var cells: Array = []

func _init() -> void:
	name = "StreakSheet"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: close())
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(36)
	sb.border_width_bottom = 8; sb.border_color = Color("#E2C46A")
	for side in ["left", "right", "top", "bottom"]: sb.set("content_margin_" + side, 36)
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	flame = _icon(FLAME, 132)
	col.add_child(_centered(flame))
	count_label = _label(96, FontTokens.heading()); col.add_child(count_label)
	days_label = _label(30, FontTokens.body_bold()); col.add_child(days_label)
	best_label = _label(26, FontTokens.body()); col.add_child(best_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in 7:
		var cell := _cell(i == 6)
		cells.append(cell); row.add_child(cell)
	col.add_child(row)
	left_label = _label(24, FontTokens.body()); col.add_child(left_label)
	status_label = _label(26, FontTokens.body_bold()); col.add_child(status_label)
	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.custom_minimum_size = Vector2(0, 84)
	close_btn.pressed.connect(close)
	col.add_child(close_btn)

func open(view: Dictionary) -> void:
	var kept: bool = view.get("kept_today", false)
	var count: int = int(view.get("count", 0))
	var done: int = int(view.get("cycle_done", 0))
	flame.modulate = ON_COLOR if kept else OFF_COLOR
	count_label.text = str(count)
	count_label.add_theme_color_override("font_color", ON_COLOR if kept else INK)
	days_label.text = tr("streak.days")
	best_label.text = tr("streak.best") % int(view.get("best", 0))
	left_label.text = tr("streak.left") % (7 - done)
	if kept: status_label.text = tr("streak.kept")
	elif count > 0: status_label.text = tr("streak.at_risk")
	else: status_label.text = tr("streak.start")
	for i in cells.size():
		var on := i < done
		var cell: PanelContainer = cells[i]
		cell.set_meta("done", on)
		(cell.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color("#FFE3CC") if on else Color("#EFEDEA")
		(cell.get_child(0).get_child(0) as TextureRect).modulate = ON_COLOR if on else Color(1, 1, 1, 0.9) if i == 6 else Color(0, 0, 0, 0)
	close_btn.text = tr("assist.close")
	visible = true

func close() -> void:
	visible = false

func _cell(is_gift: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(64, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#EFEDEA"); sb.set_corner_radius_all(32)
	cell.add_theme_stylebox_override("panel", sb)
	var icon := _icon(GIFT if is_gift else FLAME, 40)
	cell.add_child(_centered(icon))
	return cell

func _icon(path: String, side: int) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path): t.texture = load(path) as Texture2D
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _centered(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(child)
	return c

func _label(font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", INK)
	if font != null: l.add_theme_font_override("font", font)
	return l
```

Ghi chú: ô quà (i == 6) dùng icon kẹo gốc; khi chưa đạt hiển thị mờ trắng-tinh (`Color(1,1,1,0.9)` trên nền xám), khi đạt tô cam. Ô thường chưa đạt ẩn icon (alpha 0).

`game/scripts/screens/streak_chip.gd`:

```gdscript
# Home streak chip: flame + day count; grey until today's win, pulses when at risk.
extends Button

const StreakSheet = preload("res://scripts/screens/streak_sheet.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const ON_COLOR := StreakSheet.ON_COLOR
const OFF_COLOR := StreakSheet.OFF_COLOR
const ROW_HEIGHT := 84

var inventory: Variant = null
var sheet: StreakSheet = null
var at_risk := false
var count_label: Label
var icon_rect: TextureRect
var _pulse: Tween = null

static func attach(screen: Control, safe: Control) -> Button:
	var row := CenterContainer.new()
	row.name = "StreakChipRow"
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip := new()
	row.add_child(chip)
	safe.add_child(row)
	chip.sheet = StreakSheet.new()
	screen.add_child(chip.sheet)
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
	icon_rect = TextureRect.new()
	icon_rect.texture = load("res://assets/ui/home/icon_flame.svg") as Texture2D
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)
	count_label = Label.new()
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 36)
	var font := FontTokens.heading()
	if font != null: count_label.add_theme_font_override("font", font)
	row.add_child(count_label)
	pressed.connect(_on_pressed)

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
	icon_rect.modulate = color
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

func _on_pressed() -> void:
	if sheet != null and inventory != null:
		sheet.open(inventory.streak_view())
```

`title_screen.gd`:
- Thêm `const StreakChip = preload("res://scripts/screens/streak_chip.gd")` sau `const LayoutTokens = ...`.
- Thêm `var assists: Variant = null; var streak_chip: Button = null` sau `var _play_label: Label = null`.
- Sau `frame.add_child(bottom_spacer)` thêm `streak_chip = StreakChip.attach(self, safe)` (cùng thụt lề). Chip phải được thêm SAU `frame` để nằm trên hàng nút mà không bị spacer của `top` chặn chạm.
- Trong `setup`, sau `_ensure_nodes()` thêm `streak_chip.bind(assists)`.
- `wc -l` ≤ 300.

`app_shell.gd` nhánh `"title"`: sửa dòng
`if screen.has_method("setup"): screen.call("setup", runtime, endless_runtime)` →
`if screen.has_method("setup"): screen.set("assists", assists); screen.call("setup", runtime, endless_runtime)`. Số dòng không đổi (300).

Thêm cuối `game/locale/strings.csv`:

```csv
streak.days,days in a row,日連続,ngày liên tiếp,hari berturut-turut,dias seguidos,días seguidos,일 연속
streak.best,Best: %d days,最高記録：%d日,Kỷ lục: %d ngày,Rekor: %d hari,Recorde: %d dias,Récord: %d días,최고 기록: %d일
streak.left,%d more days to the gift,ギフトまであと%d日,Còn %d ngày để nhận quà,%d hari lagi menuju hadiah,Faltam %d dias para o presente,Faltan %d días para el regalo,선물까지 %d일 남았어요
streak.kept,Streak kept for today,今日の連続記録をキープしました,Hôm nay đã giữ chuỗi,Rangkaian hari ini terjaga,Sequência mantida hoje,Racha mantenida hoy,오늘 연속 기록을 지켰어요
streak.at_risk,Clear a level today to keep your streak before midnight,真夜中までにレベルをクリアして記録をキープしよう,Thắng 1 màn hôm nay để giữ chuỗi trước nửa đêm,Selesaikan satu level hari ini sebelum tengah malam agar rangkaian terjaga,Conclua uma fase hoje antes da meia-noite para manter a sequência,Completa un nivel hoy antes de medianoche para mantener la racha,자정 전에 레벨 하나를 깨서 기록을 지키세요
streak.start,Clear a level to start a streak,レベルをクリアして連続記録を始めよう,Thắng 1 màn để bắt đầu chuỗi,Selesaikan satu level untuk memulai rangkaian,Conclua uma fase para começar uma sequência,Completa un nivel para empezar una racha,레벨을 깨서 연속 기록을 시작하세요
```

Sau khi sửa CSV/SVG: chạy `godot --headless --path game --import`; sau đó khôi phục các file chỉ đổi line ending (`git checkout -- game/assets/icons/ game/project.godot` nếu `git diff` rỗng nội dung) và commit `icon_flame.svg.import`.

- [ ] **Step 4: Run — expect PASS**

`test_streak_ui.gd` → `STREAK_UI_PASS`; `test_screens.gd`, `test_web_glyphs.gd`, `test_integration.gd` → PASS.

- [ ] **Step 5: Commit**

```bash
git add game/assets/ui/home/icon_flame.svg game/assets/ui/home/icon_flame.svg.import game/scripts/screens/streak_chip.gd game/scripts/screens/streak_sheet.gd game/scripts/screens/*.uid game/scripts/screens/title_screen.gd game/scripts/screens/app_shell.gd game/locale/strings.csv game/tests/test_streak_ui.gd game/tests/test_streak_ui.gd.uid
git commit -m "feat(home): add the centered streak chip and streak sheet"
```

---

### Task 3: Hiệu ứng +1 và toast gói trễ

**Files:**
- Create: `game/scripts/screens/streak_burst.gd`
- Modify: `game/scripts/screens/assist_dock.gd` (`show_toast`)
- Modify: `game/scripts/screens/puzzle_assist_controller.gd` (`bind`, `on_level_won`, hàm mới)
- Modify: `game/tests/test_assist_flow.gd` (assert không burst trên custom)
- Test: `game/tests/test_streak_burst.gd`

**Interfaces:**
- Consumes: Task 1 `inventory.streak_extended(total)`; Task 2 `StreakSheet.ON_COLOR`.
- Produces:
  - `StreakBurst.play(parent: Control, total: int) -> Control` (node `StreakBurst`, `get_meta("label")` là Label)
  - `AssistDock.show_toast(parent: Control, text: String, delay: float = 0.0) -> Label`
  - Controller: `var burst_played: bool`

- [ ] **Step 1: Write the failing test**

`game/tests/test_streak_burst.gd`:

```gdscript
extends SceneTree

const StreakBurst = preload("res://scripts/screens/streak_burst.gd")
const Controller = preload("res://scripts/screens/puzzle_assist_controller.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var host := Control.new()
	root.add_child(host)
	var burst := StreakBurst.play(host, 12)
	check(burst.name == "StreakBurst" and burst.get_parent() == host, "burst added")
	check((burst.get_meta("label") as Label).text == "12", "reduced motion shows final count")

	var dir := OS.get_user_data_dir().path_join("streak_burst_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	var screen := Control.new()
	root.add_child(screen)
	var ctl := Controller.new()
	ctl.setup(screen, Button.new(), Button.new())
	ctl.bind(inv, null)
	ctl.on_level_won(PlaySession.new(LEVEL), false)
	check(ctl.burst_played and screen.get_node_or_null("StreakBurst") != null, "first win of the day bursts")
	screen.get_node("StreakBurst").free()
	ctl.on_level_won(PlaySession.new(LEVEL), false)
	check(not ctl.burst_played and screen.get_node_or_null("StreakBurst") == null, "second win same day: no burst")
	ctl.on_level_won(PlaySession.new(LEVEL), true)
	check(screen.get_node_or_null("StreakBurst") == null, "custom win: no burst")
	host.queue_free(); screen.queue_free()
	inv._store.remove_all()
	if failures.is_empty():
		print("STREAK_BURST_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Trong `test_assist_flow.gd`, sau assert `"custom win does not count for streak"` thêm:

```gdscript
	check(screen.get_node_or_null("StreakBurst") == null, "custom win shows no burst")
```

- [ ] **Step 2: Run — expect FAIL**

Run: `test_streak_burst.gd` → FAIL (`streak_burst.gd` không tồn tại).

- [ ] **Step 3: Implement**

`game/scripts/screens/streak_burst.gd`:

```gdscript
# "+1 day" burst on the board: the flame pops and the count ticks to the new total.
extends RefCounted

const StreakSheet = preload("res://scripts/screens/streak_sheet.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

static func play(parent: Control, total: int) -> Control:
	var box := VBoxContainer.new()
	box.name = "StreakBurst"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(240, 260)
	box.position -= box.custom_minimum_size * 0.5
	box.pivot_offset = box.custom_minimum_size * 0.5
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/home/icon_flame.svg") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(150, 150)
	icon.modulate = StreakSheet.ON_COLOR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 84)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", StreakSheet.ON_COLOR.darkened(0.35))
	label.add_theme_constant_override("outline_size", 14)
	var font := FontTokens.heading()
	if font != null: label.add_theme_font_override("font", font)
	box.add_child(label)
	box.set_meta("label", label)
	parent.add_child(box)
	if not LayoutTokens.motion_enabled or not parent.is_inside_tree():
		label.text = str(total)
		return box
	label.text = str(maxi(total - 1, 0))
	box.scale = Vector2(0.4, 0.4)
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): label.text = str(total))
	tw.tween_property(box, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(0.5)
	tw.tween_property(box, "modulate:a", 0.0, 0.3)
	tw.tween_callback(box.queue_free)
	return box
```

`assist_dock.gd` — đổi chữ ký và phần tween của `show_toast`:

```gdscript
static func show_toast(parent: Control, text: String, delay: float = 0.0) -> Label:
```

và thay khối `if parent.is_inside_tree():` bằng:

```gdscript
	if parent.is_inside_tree():
		var tw := toast.create_tween()
		if delay > 0.0:
			toast.modulate.a = 0.0
			tw.tween_interval(delay)
			tw.tween_property(toast, "modulate:a", 1.0, 0.15)
		tw.tween_interval(1.6)
		tw.tween_property(toast, "modulate:a", 0.0, 0.4)
		tw.tween_callback(toast.queue_free)
```

`puzzle_assist_controller.gd`:
- Thêm `const StreakBurst = preload("res://scripts/screens/streak_burst.gd")` và `var burst_played := false`.
- Trong `bind`, sau khối nối `inventory.changed` thêm:

```gdscript
	if not inventory.streak_extended.is_connected(_on_streak_extended):
		inventory.streak_extended.connect(_on_streak_extended)
```

- `on_level_won`: ngay sau dòng guard `if inventory == null or is_custom or session == null: return {}` thêm `burst_played = false`; đổi dòng toast thành
  `AssistDock.show_toast(_screen, _screen.tr("assist.reward") % [int(reward.get("hint", 0)), int(reward.get("place", 0))], 0.9 if burst_played else 0.0)`.
- Thêm:

```gdscript
func _on_streak_extended(total: int) -> void:
	burst_played = true
	if _screen != null: StreakBurst.play(_screen, total)
```

Ghi chú: `coordinator == null` trong test — `bind` đã kiểm `coordinator != null` trước khi dùng.

- [ ] **Step 4: Run — expect PASS**

`test_streak_burst.gd` → `STREAK_BURST_PASS`; `test_assist_flow.gd`, `test_assist_ui.gd` → PASS.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/streak_burst.gd game/scripts/screens/streak_burst.gd.uid game/scripts/screens/assist_dock.gd game/scripts/screens/puzzle_assist_controller.gd game/tests/test_streak_burst.gd game/tests/test_streak_burst.gd.uid game/tests/test_assist_flow.gd
git commit -m "feat(puzzle): burst the streak flame on the first win of the day"
```

---

### Task 4: Tài liệu và full gate

**Files:**
- Modify: `docs/DECISIONS.md` (thêm RST-030 trên RST-029)
- Modify: `docs/STATUS.md` (thêm dòng vào mục "Kho trợ giúp và streak")

- [ ] **Step 1: DECISIONS** — thêm ngay dưới `> Quản lý version: ...`:

```markdown
## RST-030 — Xem chuỗi ngày chơi trên Home

Ngày 2026-10-14. Bổ sung RST-029. Đặc tả: [streak view](superpowers/specs/2026-10-14-streak-view-design.md).

- **Viên lửa** ở giữa phía trên Home: số ngày liên tiếp (`totalStreak`, không reset khi nhận gói 7 ngày); cam khi đã giữ hôm nay, xám khi chưa, nhấp nháy khi sắp mất.
- **Bảng chuỗi** khi chạm: số ngày, kỷ lục (`bestStreak`), 7 ô chu kỳ với ô quà, trạng thái hôm nay.
- **Hiệu ứng +1** trên bàn chơi ở lần thắng đầu tiên trong ngày; toast gói 7 ngày hiện sau.
- Popup "Hết lượt" vẫn không hiển thị streak.
```

- [ ] **Step 2: STATUS** — trong mục `## Kho trợ giúp và streak (2026-10-14, ...)`, thêm dòng đầu:
`- Home có viên lửa chuỗi ở giữa phía trên, bảng chuỗi và hiệu ứng +1 (RST-030).`

- [ ] **Step 3: Full gate**

```bash
# clean-room: tìm tên cấm và extracted_reusable trong game/scripts, game/tests -> không có kết quả
python -B tools/verify.py --godot <godot>
```

Expected: verify exit 0. Nếu lần đầu báo "source inputs changed" do Godot ghi lại line ending của `project.godot`/`.import` (nội dung không đổi), chạy lại một lần; sau cùng khôi phục các file đó.

- [ ] **Step 4: Commit**

```bash
git add docs/DECISIONS.md docs/STATUS.md
git commit -m "docs(streak): record the home streak view decision"
```
