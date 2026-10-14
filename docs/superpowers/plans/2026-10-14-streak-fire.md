# Chuỗi theo bàn hoàn thành + lửa "bốc" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tính ngày chuỗi khi một bàn kết thúc (thắng hoặc thua), và thay lửa một màu bằng lửa 3 lớp cháy liên tục, có tàn lửa và burst +1 hoành tráng.

**Architecture:** Đổi tên API ghi chuỗi thành `on_round_finished` (inventory + controller) và gọi ở cả nhánh thắng lẫn thua của `puzzle_screen`. Thêm `flame_fx.gd` (Control dùng chung: 3 lớp, flicker, `CPUParticles2D`), thay icon lửa trong `streak_chip.gd`, `streak_sheet.gd`; viết lại `streak_burst.gd` thành Control tự vẽ quầng sáng/vòng sáng + nổ tia lửa.

**Tech Stack:** Godot 4.7 / GDScript, `CPUParticles2D`, test headless `extends SceneTree`.

**Spec:** [2026-10-14-streak-fire-design.md](../specs/2026-10-14-streak-fire-design.md)

## Global Constraints

- Ngày chuỗi tính khi ≥1 bàn kết thúc (thắng hoặc thua); không tính custom/debug/tutorial; khôi phục bàn đã kết thúc không tính trùng.
- Lớp lửa: ngoài `#E8361C` scale 1.0, giữa `#FF8A1F` scale 0.78, lõi `#FFD84A` scale 0.5; xám `#B9B4AC` chỉ lớp ngoài.
- Tàn: Home 6, bảng 18, burst 24; tia nổ burst 28.
- Giảm chuyển động: không tween, không hạt, không vòng sáng.
- Mỗi file ≤ 300 dòng; `puzzle_screen.gd` hiện 299 dòng, `app_shell.gd` 300 (không sửa).
- Câu chữ gốc, 7 cột locale; không ký tự ngoài font.
- Commit Conventional Commits + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Bàn thua được khôi phục** (`_on_level_failed(false)` chạy lại khi mở app) → không tính trùng trong ngày. (Test: Task 1 "failed twice same day".)
2. **Rời màn khi burst/flicker đang chạy** → tween gắn với node nên chết theo node; không lỗi. (Test: Task 2/3 free node khi đang chạy.)
3. **`set_lit` gọi trước khi vào cây** → flicker bắt đầu khi vào cây. (Test: Task 2 "flicker starts on enter tree".)
4. **Hạt trên Web/mobile** → chỉ `CPUParticles2D`, không `GPUParticles2D`. (Test: Task 2 kiểm kiểu node.)
5. **Rò rỉ khi test thoát** → mọi node test phải nằm trong cây hoặc được free; `verify.py` coi dòng `ERROR:` là fail.

---

## File Structure

| File | Loại | Trách nhiệm |
|---|---|---|
| `game/scripts/state/assist_inventory.gd` | sửa | `on_level_won` → `on_round_finished` |
| `game/scripts/screens/puzzle_assist_controller.gd` | sửa | `on_level_won` → `on_round_finished` |
| `game/scripts/screens/puzzle_screen.gd` | sửa | Gọi `on_round_finished` ở thắng và thua |
| `game/locale/strings.csv` | sửa | `streak.at_risk`, `streak.start` |
| `game/scripts/screens/flame_fx.gd` | mới | Lửa 3 lớp + flicker + tàn |
| `game/scripts/screens/streak_chip.gd`, `streak_sheet.gd` | sửa | Dùng `FlameFx` |
| `game/scripts/screens/streak_burst.gd` | viết lại | Burst hoành tráng |
| Tests: `test_assist_inventory.gd`, `test_assist_flow.gd`, `test_streak_ui.gd`, `test_streak_burst.gd` (sửa), `test_flame_fx.gd` (mới) | | |
| `docs/DECISIONS.md`, `docs/STATUS.md` | sửa | RST-031 |

Chạy test: Godot 4.7.2 console exe (đường dẫn WinGet), `--headless --path game --script res://tests/<file>.gd`.

---

### Task 1: Tính chuỗi khi bàn kết thúc

**Files:**
- Modify: `game/scripts/state/assist_inventory.gd:34`, `game/scripts/screens/puzzle_assist_controller.gd:51,55`, `game/scripts/screens/puzzle_screen.gd:273-280`, `game/locale/strings.csv:140-141`
- Modify tests: `test_assist_inventory.gd`, `test_assist_flow.gd`, `test_streak_ui.gd`, `test_streak_burst.gd`

**Interfaces:**
- Produces: `AssistInventory.on_round_finished(today: String = "") -> Dictionary`; `PuzzleAssistController.on_round_finished(session: Variant, is_custom: bool) -> Dictionary`. Tên cũ bị xóa.

- [ ] **Step 1: Write the failing tests**

Đổi mọi lời gọi `on_level_won(` của inventory/controller trong 4 file test sang `on_round_finished(` (không đụng `test_demo_campaign.gd`, đó là API campaign runtime khác):

```bash
sed -i 's/\.on_level_won(/.on_round_finished(/' game/tests/test_assist_inventory.gd game/tests/test_assist_flow.gd game/tests/test_streak_ui.gd game/tests/test_streak_burst.gd
```

Trong `test_assist_flow.gd`, sau dòng `check(inv2.data.streakDays == 1, "resume won twice records once")` thêm:

```gdscript
	# A lost round also keeps the streak; restoring it does not count twice.
	var screen3 := PuzzleScreen.new()
	var inv3 := Inventory.new(dir + "_c")
	screen3.assists = inv3
	root.add_child(screen3)
	screen3.setup(null, null, null, LEVEL, false)
	screen3.assist_ctl.bind(inv3, screen3.hint_coordinator)
	screen3._is_custom = false
	screen3._on_level_failed(false)
	check(inv3.data.totalStreak == 1, "failed round counts for streak")
	screen3._on_level_failed(false)
	check(inv3.data.totalStreak == 1, "failed twice same day counts once")
	screen3.queue_free()
	inv3._store.remove_all()
```

- [ ] **Step 2: Run — expect FAIL**

`test_assist_inventory`, `test_assist_flow`, `test_streak_ui`, `test_streak_burst` → FAIL (`on_round_finished` không tồn tại).

- [ ] **Step 3: Implement**

- `assist_inventory.gd`: `func on_level_won(today: String = "") -> Dictionary:` → `func on_round_finished(today: String = "") -> Dictionary:` và thêm chú thích dòng trên: `# Any finished round (won or lost) keeps the streak; future modes call this too.`
- `puzzle_assist_controller.gd`: `func on_level_won(session: Variant, is_custom: bool) -> Dictionary:` → `func on_round_finished(session: Variant, is_custom: bool) -> Dictionary:`; dòng `var reward: Dictionary = inventory.on_level_won()` → `inventory.on_round_finished()`.
- `puzzle_screen.gd`:
  - `assist_ctl.on_level_won(session, _is_custom)` → `assist_ctl.on_round_finished(session, _is_custom)`.
  - `_on_level_failed`: chèn dòng mới `assist_ctl.on_round_finished(session, _is_custom)` ngay trước `if board != null: board.play_sad()` (không gộp bằng `;` vì `if` không thể đứng sau `;`). File lên đúng 300 dòng — vẫn trong giới hạn; kiểm `wc -l`.
- `strings.csv` thay 2 dòng:

```csv
streak.at_risk,Finish a level today to keep your streak before midnight,真夜中までにレベルを1つプレイし終えて記録をキープしよう,Chơi xong 1 màn hôm nay để giữ chuỗi trước nửa đêm,Mainkan satu level sampai selesai hari ini sebelum tengah malam agar rangkaian terjaga,Termine uma fase hoje antes da meia-noite para manter a sequência,Termina un nivel hoy antes de medianoche para mantener la racha,자정 전에 레벨 하나를 끝까지 플레이해서 기록을 지키세요
streak.start,Finish a level to start a streak,レベルを1つプレイし終えて連続記録を始めよう,Chơi xong 1 màn để bắt đầu chuỗi,Mainkan satu level sampai selesai untuk memulai rangkaian,Termine uma fase para começar uma sequência,Termina un nivel para empezar una racha,레벨 하나를 끝까지 플레이해서 연속 기록을 시작하세요
```

Sau đó `--import` để sinh `.translation`, rồi khôi phục các file chỉ đổi line ending (`git checkout -- game/assets/icons/ game/project.godot`).

- [ ] **Step 4: Run — expect PASS**

4 suite trên + `test_web_glyphs` → PASS.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/state/assist_inventory.gd game/scripts/screens/puzzle_assist_controller.gd game/scripts/screens/puzzle_screen.gd game/locale/strings.csv game/tests/test_assist_inventory.gd game/tests/test_assist_flow.gd game/tests/test_streak_ui.gd game/tests/test_streak_burst.gd
git commit -m "feat(streak): count a day once any round finishes, won or lost"
```

---

### Task 2: `FlameFx` và dùng trong viên lửa + bảng chuỗi

**Files:**
- Create: `game/scripts/screens/flame_fx.gd`
- Modify: `game/scripts/screens/streak_chip.gd` (icon → FlameFx), `game/scripts/screens/streak_sheet.gd` (flame → FlameFx)
- Test: `game/tests/test_flame_fx.gd` (mới), `game/tests/test_streak_ui.gd` (sửa assert màu)

**Interfaces:**
- Produces: `FlameFx.new(side: float, embers: int)`; `set_lit(on: bool)`; `var lit: bool`; `var layers: Array[TextureRect]`; `var embers_node: CPUParticles2D` (null nếu `embers == 0`); `func is_flickering() -> bool`; `const LAYER_COLORS`, `const OFF_COLOR`.
- Chip: `var flame` (FlameFx) thay `icon_rect`. Sheet: `var flame` là FlameFx.

- [ ] **Step 1: Write the failing test**

`game/tests/test_flame_fx.gd`:

```gdscript
extends SceneTree

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
var failures: Array[String] = []

func _initialize() -> void:
	await process_frame  # root joins the tree only after the first frame
	LayoutTokens.motion_enabled = true
	var fx := FlameFx.new(64, 6)
	fx.set_lit(true)
	check(not fx.is_flickering(), "no tween before entering the tree")
	root.add_child(fx)
	check(fx.is_flickering(), "flicker starts on enter tree")
	check(fx.layers.size() == 3, "three layers")
	check(fx.layers.all(func(l): return l.visible), "all layers lit")
	check(fx.layers[2].modulate == FlameFx.LAYER_COLORS[2], "yellow core")
	check(fx.embers_node is CPUParticles2D and fx.embers_node.emitting, "embers on")
	check(fx.embers_node.amount == 6, "ember count")
	fx.set_lit(false)
	check(fx.layers[0].visible and not fx.layers[1].visible and not fx.layers[2].visible, "grey shows one layer")
	check(fx.layers[0].modulate == FlameFx.OFF_COLOR, "grey color")
	check(not fx.is_flickering() and not fx.embers_node.emitting, "grey is still")
	LayoutTokens.motion_enabled = false
	fx.set_lit(true)
	check(fx.layers.all(func(l): return l.visible), "reduced motion keeps colors")
	check(not fx.is_flickering() and not fx.embers_node.emitting, "reduced motion: no tween, no embers")
	var bare := FlameFx.new(52, 0)
	check(bare.embers_node == null, "no embers when count is 0")
	bare.free()
	fx.free()
	if failures.is_empty():
		print("FLAME_FX_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Trong `test_streak_ui.gd`:
- `check(chip.icon_rect.modulate == StreakChip.OFF_COLOR, "grey before today's win")` → `check(not chip.flame.lit, "grey before today's play")`
- `check(chip.count_label.text == "2" and chip.icon_rect.modulate == StreakChip.ON_COLOR, "orange after today's win")` → `check(chip.count_label.text == "2" and chip.flame.lit, "lit after today's play")`

- [ ] **Step 2: Run — expect FAIL**

`test_flame_fx` → FAIL (file không tồn tại); `test_streak_ui` → FAIL (`flame` không có).

- [ ] **Step 3: Implement**

`game/scripts/screens/flame_fx.gd`:

```gdscript
# Layered flame (red shell, orange body, yellow core) that flickers and sheds embers while lit.
extends Control

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const ICON := "res://assets/ui/home/icon_flame.svg"
const LAYER_COLORS := [Color("#E8361C"), Color("#FF8A1F"), Color("#FFD84A")]
const LAYER_SCALES := [1.0, 0.78, 0.5]
const OFF_COLOR := Color("#B9B4AC")

var lit := false
var layers: Array[TextureRect] = []
var embers_node: CPUParticles2D = null
var _tweens: Array[Tween] = []

func _init(side: float = 64.0, embers: int = 0) -> void:
	name = "FlameFx"
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load(ICON) as Texture2D
	for i in 3:
		var s: float = side * float(LAYER_SCALES[i])
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.size = Vector2(s, s)
		t.position = Vector2((side - s) * 0.5, side - s)  # layers share the flame base
		t.pivot_offset = Vector2(s * 0.5, s)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		layers.append(t)
	if embers > 0:
		embers_node = _make_embers(side, embers)
		add_child(embers_node)
	set_lit(false)

func set_lit(on: bool) -> void:
	lit = on
	_stop_flicker()
	for i in layers.size():
		var t: TextureRect = layers[i]
		t.visible = on or i == 0
		t.modulate = LAYER_COLORS[i] if on else OFF_COLOR
	var moving := on and LayoutTokens.motion_enabled
	if embers_node != null:
		embers_node.emitting = moving
		embers_node.visible = moving
	if moving and is_inside_tree():
		_start_flicker()

func is_flickering() -> bool:
	return not _tweens.is_empty()

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE and lit and LayoutTokens.motion_enabled and _tweens.is_empty():
		_start_flicker()
	elif what == NOTIFICATION_EXIT_TREE:
		_stop_flicker()

func _start_flicker() -> void:
	for i in layers.size():
		var t: TextureRect = layers[i]
		var period := 0.32 + 0.08 * i + randf() * 0.07
		var lean := deg_to_rad(3.0 if i % 2 == 0 else -3.0)
		var tw := t.create_tween().set_loops()
		tw.tween_property(t, "scale", Vector2(0.97, 1.06 + 0.03 * i), period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "rotation", lean, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "modulate:a", 0.85, period)
		tw.tween_property(t, "scale", Vector2.ONE, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "rotation", 0.0, period).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(t, "modulate:a", 1.0, period)
		_tweens.append(tw)

func _stop_flicker() -> void:
	for tw in _tweens:
		if tw.is_valid(): tw.kill()
	_tweens.clear()
	for t in layers:
		t.scale = Vector2.ONE
		t.rotation = 0.0

static func _make_embers(side: float, amount: int) -> CPUParticles2D:
	var e := CPUParticles2D.new()
	e.name = "Embers"
	e.amount = amount
	e.lifetime = 0.9
	e.position = Vector2(side * 0.5, side * 0.7)
	e.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	e.emission_sphere_radius = side * 0.18
	e.direction = Vector2(0, -1)
	e.spread = 25.0
	e.gravity = Vector2(0, -side * 0.6)
	e.initial_velocity_min = side * 0.4
	e.initial_velocity_max = side * 0.9
	e.scale_amount_min = maxf(1.5, side * 0.04)
	e.scale_amount_max = maxf(2.5, side * 0.08)
	var ramp := Gradient.new()
	ramp.set_color(0, Color("#FFE27A"))
	ramp.set_color(1, Color(0.91, 0.21, 0.11, 0.0))
	e.color_ramp = ramp
	e.emitting = false
	return e
```

`streak_chip.gd`:
- Thêm `const FlameFx = preload("res://scripts/screens/flame_fx.gd")`.
- `var icon_rect: TextureRect` → `var flame: Control`.
- Thay khối tạo `icon_rect` (từ `icon_rect = TextureRect.new()` tới `row.add_child(icon_rect)`) bằng:

```gdscript
	flame = FlameFx.new(52, 6)
	row.add_child(flame)
```

- Trong `refresh`: thay `icon_rect.modulate = color` bằng `flame.set_lit(v.kept_today)`.

`streak_sheet.gd`:
- Thêm `const FlameFx = preload("res://scripts/screens/flame_fx.gd")`.
- `var flame: TextureRect` → `var flame: Control`.
- `flame = _icon(FLAME, 132)` → `flame = FlameFx.new(140, 18)`.
- Trong `open`: `flame.modulate = ON_COLOR if kept else OFF_COLOR` → `flame.set_lit(kept)`.

- [ ] **Step 4: Run — expect PASS**

`test_flame_fx` → `FLAME_FX_PASS`; `test_streak_ui`, `test_screens` → PASS; đầu ra không có dòng `ERROR:`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/flame_fx.gd game/scripts/screens/streak_chip.gd game/scripts/screens/streak_sheet.gd game/tests/test_flame_fx.gd game/tests/test_streak_ui.gd
git commit -m "feat(streak): layered flickering flame with rising embers"
```

---

### Task 3: Burst +1 hoành tráng

**Files:**
- Rewrite: `game/scripts/screens/streak_burst.gd`
- Modify test: `game/tests/test_streak_burst.gd`

**Interfaces:**
- Consumes: `FlameFx` (Task 2), `Vibration.pulse(Vibration.Strength.SOFT)`.
- Produces: giữ `static func play(parent: Control, total: int) -> Control`; node tên `StreakBurst`; meta `"label"` (Label), `"sparks"` (CPUParticles2D hoặc null khi giảm chuyển động); `var ring_t: float`.

- [ ] **Step 1: Write the failing test**

Trong `test_streak_burst.gd`, ngay sau assert `"reduced motion shows final count"` thêm:

```gdscript
	check(burst.get_meta("sparks") == null, "reduced motion: no sparks")
	check(burst.has_node("FlameFx"), "burst uses the layered flame")
	LayoutTokens.motion_enabled = true
	var big := StreakBurst.play(host, 5)
	var sparks: CPUParticles2D = big.get_meta("sparks")
	check(sparks != null and sparks.one_shot and sparks.emitting and sparks.amount == 28, "spark explosion")
	check((big.get_meta("label") as Label).text == "4", "count starts at N-1")
	big.free()
	LayoutTokens.motion_enabled = false
```

- [ ] **Step 2: Run — expect FAIL**

`test_streak_burst` → FAIL (meta `sparks` không có / không có FlameFx).

- [ ] **Step 3: Implement** — thay toàn bộ `streak_burst.gd`:

```gdscript
# "+1 day" burst: glow, layered flame pop, expanding ring, spark explosion, count roll.
extends Control

const FlameFx = preload("res://scripts/screens/flame_fx.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")
const SIDE := 170.0
const BOX := Vector2(320, 340)
const GLOW := Color(1.0, 0.54, 0.12, 0.35)
const RING := Color(1.0, 0.85, 0.4)

var ring_t := 0.0
var _moving := false

static func play(parent: Control, total: int) -> Control:
	var burst := new()
	burst._build(total)
	parent.add_child(burst)
	burst._start(total)
	return burst

func _build(total: int) -> void:
	name = "StreakBurst"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)
	size = BOX
	position = -BOX * 0.5
	pivot_offset = BOX * 0.5
	_moving = LayoutTokens.motion_enabled
	var flame := FlameFx.new(SIDE, 24)
	flame.position = Vector2((BOX.x - SIDE) * 0.5, 20)
	flame.pivot_offset = Vector2(SIDE * 0.5, SIDE * 0.5)
	flame.set_lit(true)
	add_child(flame)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(BOX.x, 110)
	label.position = Vector2(0, SIDE + 30)
	label.pivot_offset = label.size * 0.5
	label.add_theme_font_size_override("font_size", 92)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#B3260F"))
	label.add_theme_constant_override("outline_size", 16)
	var font := FontTokens.heading()
	if font != null: label.add_theme_font_override("font", font)
	label.text = str(maxi(total - 1, 0) if _moving else total)
	add_child(label)
	set_meta("label", label)
	set_meta("flame", flame)
	var sparks: CPUParticles2D = _make_sparks() if _moving else null
	if sparks != null: add_child(sparks)
	set_meta("sparks", sparks)

func _start(total: int) -> void:
	if not is_inside_tree():
		return
	if not _moving:
		get_tree().create_timer(1.2).timeout.connect(queue_free)
		return
	var flame: Control = get_meta("flame")
	var label: Label = get_meta("label")
	var sparks: CPUParticles2D = get_meta("sparks")
	sparks.emitting = true
	Vibration.pulse(Vibration.Strength.SOFT)
	flame.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(flame, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(_set_ring, 0.0, 1.0, 0.6)
	tw.tween_callback(func(): label.text = str(total); label.scale = Vector2(1.35, 1.35))
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(flame, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(0.35)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func _set_ring(t: float) -> void:
	ring_t = t
	queue_redraw()

func _draw() -> void:
	var center := Vector2(BOX.x * 0.5, 20 + SIDE * 0.55)
	draw_circle(center, SIDE * 0.75, GLOW)
	if _moving and ring_t > 0.0 and ring_t < 1.0:
		var ring := RING
		ring.a = 0.8 * (1.0 - ring_t)
		draw_arc(center, SIDE * 1.6 * ring_t, 0.0, TAU, 48, ring, 10.0)

func _make_sparks() -> CPUParticles2D:
	var s := CPUParticles2D.new()
	s.name = "Sparks"
	s.one_shot = true
	s.explosiveness = 1.0
	s.amount = 28
	s.lifetime = 0.8
	s.position = Vector2(BOX.x * 0.5, 20 + SIDE * 0.55)
	s.direction = Vector2(0, -1)
	s.spread = 180.0
	s.initial_velocity_min = 300.0
	s.initial_velocity_max = 520.0
	s.gravity = Vector2(0, 600)
	s.scale_amount_min = 4.0
	s.scale_amount_max = 8.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color("#FFF2A8"))
	ramp.set_color(1, Color(0.91, 0.21, 0.11, 0.0))
	s.color_ramp = ramp
	s.emitting = false
	return s
```

Ghi chú: test gọi `play` trên `host` đã ở trong cây → `_start` chạy thật; test `big.free()` ngay sau để không tween treo.

- [ ] **Step 4: Run — expect PASS**

`test_streak_burst`, `test_assist_flow`, `test_flame_fx` → PASS; không có dòng `ERROR:`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/streak_burst.gd game/tests/test_streak_burst.gd
git commit -m "feat(streak): grand +1 burst with glow, ring and spark explosion"
```

---

### Task 4: Tài liệu và full gate

- [ ] **Step 1: DECISIONS** — thêm dưới `> Quản lý version: ...`:

```markdown
## RST-031 — Chuỗi tính theo bàn chơi hoàn thành; lửa nhiều lớp

Ngày 2026-10-14. Sửa RST-029 (luật ngày) và RST-030 (hiển thị). Đặc tả: [streak fire](superpowers/specs/2026-10-14-streak-fire-design.md).

- **Luật:** một ngày được tính khi ≥1 bàn chơi kết thúc (thắng hoặc thua); áp cho tổng chuỗi, kỷ lục và gói 7 ngày. Chế độ chơi mới gọi `on_round_finished` khi một bàn kết thúc.
- **Lửa:** 3 lớp đỏ/cam/vàng cháy liên tục, có tàn lửa bay lên; xám một lớp khi hôm nay chưa chơi.
- **Burst +1:** quầng sáng, lửa bung, vòng sáng lan, nổ tia lửa, số nảy, rung nhẹ; chạy cả khi thua.
```

Trong RST-029 sửa `ngày tính khi thắng ≥1 level` → `ngày tính khi ≥1 bàn kết thúc (RST-031)`.

- [ ] **Step 2: STATUS** — trong mục `## Kho trợ giúp và streak ...` thêm dòng đầu:
`- Chuỗi tính khi một bàn kết thúc (thắng hoặc thua); lửa 3 lớp có tàn và burst +1 (RST-031).`

- [ ] **Step 3: Full gate** — clean-room search (không kết quả) và `python -B tools/verify.py --godot <godot>` → exit 0. Nếu báo "source inputs changed" vì Godot ghi lại line ending, chạy lại; sau cùng khôi phục `project.godot`/`.import` chỉ đổi line ending.

- [ ] **Step 4: Commit**

```bash
git add docs/DECISIONS.md docs/STATUS.md
git commit -m "docs(streak): record round-based streak and layered fire"
```
