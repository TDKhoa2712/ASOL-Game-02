# Kho trợ giúp (Hint + Đặt kẹo) và streak ngày — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Giới hạn Hint bằng kho lưu bền, thêm trợ giúp Đặt kẹo, và phát lượt qua streak 7 ngày thắng level.

**Architecture:** Luật thuần nằm trong `assist_rules.gd` (static). `assist_inventory.gd` giữ trạng thái và lưu qua `DualSlotStore`. `place_candy_assist.gd` (static) chọn ô. Màn chơi nhận inventory qua injection từ `app_shell`. `puzzle_assist_controller.gd` nối nút, badge, popup và toast để `puzzle_screen.gd` (295 dòng) chỉ thêm vài dòng. Inventory `null` = hành vi cũ (không giới hạn), nên test cũ và màn tutorial không đổi.

**Tech Stack:** Godot 4 / GDScript, test headless `extends SceneTree`.

**Spec:** [2026-10-14-assist-inventory-design.md](../specs/2026-10-14-assist-inventory-design.md)

## Global Constraints

- Khởi đầu 3 Hint, 1 Đặt kẹo; giới hạn 10 mỗi loại; phần vượt bị bỏ.
- Hint trừ 1 khi gợi ý hiện ra (dù có Áp dụng hay không); `WRONG_MARK` miễn phí; không tìm thấy gợi ý → không trừ; kho 0 → popup, không chạy engine.
- Streak: một ngày tính khi thắng ≥1 level; lỡ ngày → `streakDays = 1`, xóa bộ đếm dùng; ngày lùi → bỏ qua; đủ 7 → phát gói, `streakDays = 0`, xóa bộ đếm.
- Gói: dùng 0–1 → 2; 2–4 → 3; ≥5 → 4 (riêng từng loại).
- Popup "Hết lượt" không hiển thị streak; nút quảng cáo đỏ ▶, badge góc ẩn; bấm → toast "Sắp có", không cộng lượt.
- Không autoload, không global bus, không SDK quảng cáo/analytics. Mỗi file ≤ 300 dòng.
- Clean-room: không dùng tên trong danh sách cấm của AGENTS.md §3 (ví dụ `GameState`, `SaveStore`, `EventBus`).
- Câu chữ gốc; thêm key vào `game/locale/strings.csv` cho đủ 7 cột `en,ja,vi,id,pt_BR,es,ko`.
- Commit theo Conventional Commits, kết thúc bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Session WON được khôi phục khi mở lại app** → `_on_level_won(false)` chạy lại; ghi streak phải idempotent trong ngày, không phát gói hai lần. (Test: Task 1 "same day twice", Task 6 "resume won twice".)
2. **Bấm Hint lần hai để đóng gợi ý đang hiện** → không được trừ thêm lượt. (Test: Task 4.)
3. **Level custom/debug và màn tutorial** → không tính streak, không trừ kho. (Test: Task 6 "custom win no streak"; tutorial dùng màn riêng, không inject inventory.)
4. **File lưu bị sửa tay với số âm, >10, hoặc kiểu sai** → kẹp về `[0, 10]`, ngày sai định dạng coi như chưa có. (Test: Task 1 sanitize, Task 2 corrupt.)
5. **Đặt kẹo khi session không ACTIVE (đang hold thắng/thua) hoặc bàn đã đủ kẹo** → không trừ lượt, không làm gì. (Test: Task 6.)

---

## File Structure

| File | Loại | Trách nhiệm |
|---|---|---|
| `game/scripts/state/assist_rules.gd` | mới | Luật thuần: dữ liệu mặc định, sanitize, trừ, cộng, streak, gói thưởng |
| `game/scripts/state/assist_inventory.gd` | mới | Trạng thái + lưu `user://…/assists.{a,b}.json`, signal `changed` |
| `game/scripts/core/place_candy_assist.gd` | mới | Chọn ô cho Đặt kẹo |
| `game/scripts/screens/puzzle_hint_coordinator.gd` | sửa | Chặn/trừ kho Hint, `place_candy()` |
| `game/scripts/screens/assist_dock.gd` | mới | Nút Đặt kẹo, badge, toast |
| `game/scripts/screens/assist_empty_popup.gd` | mới | Popup "Hết lượt" |
| `game/scripts/screens/puzzle_layout.gd` | sửa | Dùng `AssistDock` cho badge, thêm nút Đặt kẹo |
| `game/scripts/screens/puzzle_assist_controller.gd` | mới | Nối inventory ↔ nút/badge/popup/toast |
| `game/scripts/screens/puzzle_screen.gd` | sửa | Gọi controller |
| `game/scripts/screens/app_shell.gd` | sửa | Tạo inventory, inject vào màn chơi |
| `game/locale/strings.csv` | sửa | Key `assist.*` |
| `game/tests/test_assist_rules.gd`, `test_assist_inventory.gd`, `test_place_candy_assist.gd`, `test_assist_hint_gate.gd`, `test_assist_ui.gd`, `test_assist_flow.gd` | mới | Test |
| `game/tests/test_hint_overlay.gd` | sửa | Badge ẩn khi không có inventory (giữ nguyên ý) |
| `docs/DECISIONS.md`, `docs/STATUS.md` | sửa | RST-029, tiến độ |

Lệnh chạy test (từ repo root, `<godot>` = executable Godot của máy):

```bash
rtk godot --headless --path game --script res://tests/<file>.gd
```

---

### Task 1: Luật thuần `AssistRules`

**Files:**
- Create: `game/scripts/state/assist_rules.gd`
- Test: `game/tests/test_assist_rules.gd`

**Interfaces:**
- Produces:
  - `const CAP := 10`, `const CYCLE_DAYS := 7`, `const KINDS := ["hint", "place"]`
  - `static func new_data() -> Dictionary` → `{"version":1,"hint":3,"place":1,"streakDays":0,"lastStreakDate":"","usedHint":0,"usedPlace":0}`
  - `static func sanitize(raw: Variant) -> Dictionary`
  - `static func consume(data: Dictionary, kind: String) -> Dictionary` → `{"ok": bool, "data": Dictionary}`
  - `static func add(data: Dictionary, kind: String, amount: int) -> Dictionary` (trả data mới)
  - `static func reward_for(used: int) -> int`
  - `static func record_win(data: Dictionary, today: String) -> Dictionary` → `{"data": Dictionary, "reward": Dictionary}`; `reward` rỗng hoặc `{"hint": n, "place": m}` (số đã thực cộng sau khi cắt)
  - `static func day_gap(from_date: String, to_date: String) -> int` (ngày `YYYY-MM-DD`; trả `-999999` nếu sai định dạng)
  - `static func today() -> String`

- [ ] **Step 1: Write the failing test**

`game/tests/test_assist_rules.gd`:

```gdscript
extends SceneTree

const Rules = preload("res://scripts/state/assist_rules.gd")
var failures: Array[String] = []

func _init() -> void:
	_test_defaults_and_sanitize()
	_test_consume_and_add()
	_test_reward_thresholds()
	_test_streak()
	if failures.is_empty():
		print("ASSIST_RULES_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

func _test_defaults_and_sanitize() -> void:
	var d := Rules.new_data()
	check(d.hint == 3 and d.place == 1, "start 3 hint 1 place")
	check(d.streakDays == 0 and d.lastStreakDate == "", "start streak empty")
	var s := Rules.sanitize({"hint": -4, "place": 99, "streakDays": 12, "lastStreakDate": "bad", "usedHint": "x"})
	check(s.hint == 0 and s.place == 10, "clamp counts to 0..10")
	check(s.streakDays == 0, "streak outside 0..6 resets")
	check(s.lastStreakDate == "", "invalid date dropped")
	check(s.usedHint == 0, "non-number used dropped")
	check(Rules.sanitize(null) == Rules.new_data(), "null -> defaults")
	check(Rules.sanitize({}) == Rules.new_data(), "empty -> defaults")

func _test_consume_and_add() -> void:
	var d := Rules.new_data()
	var r := Rules.consume(d, "place")
	check(r.ok and r.data.place == 0 and r.data.usedPlace == 1, "consume place")
	check(d.place == 1, "consume does not mutate input")
	check(not Rules.consume(r.data, "place").ok, "consume at 0 fails")
	check(Rules.add(d, "hint", 20).hint == 10, "add clamps at 10")
	check(not Rules.consume(d, "coins").ok, "unknown kind fails")

func _test_reward_thresholds() -> void:
	check(Rules.reward_for(0) == 2 and Rules.reward_for(1) == 2, "0-1 -> 2")
	check(Rules.reward_for(2) == 3 and Rules.reward_for(4) == 3, "2-4 -> 3")
	check(Rules.reward_for(5) == 4 and Rules.reward_for(40) == 4, ">=5 -> 4")

func _test_streak() -> void:
	check(Rules.day_gap("2026-12-31", "2027-01-01") == 1, "gap across year")
	check(Rules.day_gap("2026-02-28", "2026-03-01") == 1, "gap across month")
	var d := Rules.new_data()
	var r := Rules.record_win(d, "2026-10-01")
	check(r.data.streakDays == 1 and r.reward.is_empty(), "first win day 1")
	var same := Rules.record_win(r.data, "2026-10-01")
	check(same.data == r.data and same.reward.is_empty(), "same day twice no change")
	var back := Rules.record_win(r.data, "2026-09-20")
	check(back.data == r.data, "clock rollback ignored")
	var used: Dictionary = Rules.consume(r.data, "hint").data
	var missed := Rules.record_win(used, "2026-10-03")
	check(missed.data.streakDays == 1 and missed.data.usedHint == 0, "missed day resets streak and counters")
	# 7 consecutive days: hint used 5 times, place 0 times
	var cur := Rules.add(Rules.new_data(), "hint", 7)  # hint = 10
	cur = Rules.record_win(cur, "2026-10-01").data  # day 1 (a fresh start clears counters)
	for i in 5: cur = Rules.consume(cur, "hint").data  # hint = 5, usedHint = 5
	var reward := {}
	for day in range(2, 8):
		var res := Rules.record_win(cur, "2026-10-%02d" % day)
		cur = res.data
		if day < 7: check(res.reward.is_empty(), "no reward before day 7 (%d)" % day)
		else: reward = res.reward
	check(reward == {"hint": 4, "place": 2}, "day 7 reward by usage")
	check(cur.hint == 9 and cur.place == 3, "reward added")
	check(cur.streakDays == 0 and cur.usedHint == 0 and cur.usedPlace == 0, "cycle restarts")
	check(Rules.record_win(cur, "2026-10-08").data.streakDays == 1, "next day is day 1")
	# cap: place already 10 -> reward reports only what was added
	var full := Rules.add(Rules.new_data(), "place", 10)
	for day in range(1, 8): 
		var res2 := Rules.record_win(full, "2026-11-%02d" % day)
		full = res2.data
		if day == 7: check(res2.reward.place == 0 and full.place == 10, "reward clipped at cap")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_rules.gd`
Expected: FAIL — parse error, `assist_rules.gd` không tồn tại.

- [ ] **Step 3: Write minimal implementation**

`game/scripts/state/assist_rules.gd`:

```gdscript
# Pure rules for the assist stock (hint, place-candy) and the 7-day play streak.
extends RefCounted

const CAP := 10
const CYCLE_DAYS := 7
const KINDS := ["hint", "place"]
const USED_KEY := {"hint": "usedHint", "place": "usedPlace"}
const START := {"hint": 3, "place": 1}
const INVALID_GAP := -999999

static func new_data() -> Dictionary:
	return {"version": 1, "hint": START.hint, "place": START.place,
		"streakDays": 0, "lastStreakDate": "", "usedHint": 0, "usedPlace": 0}

static func sanitize(raw: Variant) -> Dictionary:
	var out := new_data()
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		return out
	for kind in KINDS:
		out[kind] = _int_in(raw.get(kind), 0, CAP, START[kind])
		out[USED_KEY[kind]] = _int_in(raw.get(USED_KEY[kind]), 0, 9999, 0)
	out.streakDays = _int_in(raw.get("streakDays"), 0, CYCLE_DAYS - 1, 0)
	var date := str(raw.get("lastStreakDate", ""))
	out.lastStreakDate = date if _unix(date) != INVALID_GAP else ""
	return out

static func consume(data: Dictionary, kind: String) -> Dictionary:
	if not KINDS.has(kind) or int(data.get(kind, 0)) <= 0:
		return {"ok": false, "data": data}
	var next := data.duplicate(true)
	next[kind] = int(next[kind]) - 1
	next[USED_KEY[kind]] = int(next[USED_KEY[kind]]) + 1
	return {"ok": true, "data": next}

static func add(data: Dictionary, kind: String, amount: int) -> Dictionary:
	var next := data.duplicate(true)
	if KINDS.has(kind):
		next[kind] = clampi(int(next.get(kind, 0)) + amount, 0, CAP)
	return next

static func reward_for(used: int) -> int:
	if used >= 5: return 4
	if used >= 2: return 3
	return 2

static func record_win(data: Dictionary, today_date: String) -> Dictionary:
	var last: String = data.get("lastStreakDate", "")
	var gap := day_gap(last, today_date) if last != "" else 2
	if gap == 0 or gap < 0:
		return {"data": data, "reward": {}}
	var next := data.duplicate(true)
	next.lastStreakDate = today_date
	if gap == 1:
		next.streakDays = int(next.streakDays) + 1
	else:
		next.streakDays = 1
		next.usedHint = 0
		next.usedPlace = 0
	if int(next.streakDays) < CYCLE_DAYS:
		return {"data": next, "reward": {}}
	var reward := {}
	for kind in KINDS:
		var before := int(next[kind])
		next = add(next, kind, reward_for(int(next[USED_KEY[kind]])))
		reward[kind] = int(next[kind]) - before
	next.streakDays = 0
	next.usedHint = 0
	next.usedPlace = 0
	return {"data": next, "reward": reward}

static func day_gap(from_date: String, to_date: String) -> int:
	var a := _unix(from_date)
	var b := _unix(to_date)
	if a == INVALID_GAP or b == INVALID_GAP:
		return INVALID_GAP
	return int(round(float(b - a) / 86400.0))

static func today() -> String:
	return Time.get_date_string_from_system()

static func _unix(date: String) -> int:
	if date.length() != 10 or date[4] != "-" or date[7] != "-":
		return INVALID_GAP
	var parts := date.split("-")
	for p in parts:
		if not p.is_valid_int(): return INVALID_GAP
	var m := int(parts[1]); var d := int(parts[2])
	if m < 1 or m > 12 or d < 1 or d > 31:
		return INVALID_GAP
	return Time.get_unix_time_from_datetime_string(date + "T00:00:00")

static func _int_in(value: Variant, lo: int, hi: int, fallback: int) -> int:
	if not (value is int or value is float):
		return fallback
	var v := int(value)
	if lo == 0 and hi == CYCLE_DAYS - 1 and (v < lo or v > hi):
		return fallback
	return clampi(v, lo, hi)
```

Ghi chú: `record_win` với `gap < 0` (ngày lùi) hoặc `INVALID_GAP` đều bỏ qua. `lastStreakDate == ""` coi là lần đầu (gap 2 → day 1).

- [ ] **Step 4: Run test to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_assist_rules.gd`
Expected: `ASSIST_RULES_PASS`, exit 0.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/state/assist_rules.gd game/tests/test_assist_rules.gd
rtk git commit -m "feat(state): add pure assist stock and play-streak rules"
```

---

### Task 2: `AssistInventory` có trạng thái và lưu bền

**Files:**
- Create: `game/scripts/state/assist_inventory.gd`
- Test: `game/tests/test_assist_inventory.gd`

**Interfaces:**
- Consumes: `AssistRules` (Task 1), `DualSlotStore.new(dir, name)`, `read_json()`, `write_json(data)`, `inject_corrupt(text)`, `remove_all()`.
- Produces:
  - `signal changed(kind: String, count: int)`
  - `signal save_failed(reason: String)`
  - `func _init(profile_dir: String)` (đọc ngay; lỗi → mặc định)
  - `func count(kind: String) -> int`
  - `func try_consume(kind: String) -> bool`
  - `func grant(kind: String, amount: int) -> int` (trả số thực cộng; nguồn quảng cáo tương lai)
  - `func on_level_won(today: String = "") -> Dictionary` (gói thưởng hoặc `{}`)
  - `var data: Dictionary`

- [ ] **Step 1: Write the failing test**

`game/tests/test_assist_inventory.gd`:

```gdscript
extends SceneTree

const Inventory = preload("res://scripts/state/assist_inventory.gd")
var failures: Array[String] = []
var events: Array = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("assist_inv_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	check(inv.count("hint") == 3 and inv.count("place") == 1, "fresh defaults")
	inv.changed.connect(func(k, c): events.append([k, c]))
	check(inv.try_consume("place"), "consume place")
	check(not inv.try_consume("place"), "place empty")
	check(events == [["place", 0]], "changed emitted once")
	check(inv.grant("hint", 50) == 7 and inv.count("hint") == 10, "grant clipped")
	var reloaded := Inventory.new(dir)
	check(reloaded.count("hint") == 10 and reloaded.count("place") == 0, "persisted")
	check(reloaded.on_level_won("2026-10-01").is_empty(), "day 1 no reward")
	check(Inventory.new(dir).data.streakDays == 1, "streak persisted")
	reloaded._store.inject_corrupt("{oops")
	var recovered := Inventory.new(dir)
	check(recovered.count("hint") == 10, "recover from other slot")
	recovered._store.remove_all()
	check(Inventory.new(dir).count("hint") == 3, "missing files -> defaults")
	DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("ASSIST_INVENTORY_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_inventory.gd`
Expected: FAIL — `assist_inventory.gd` không tồn tại.

- [ ] **Step 3: Write minimal implementation**

`game/scripts/state/assist_inventory.gd`:

```gdscript
# Persistent assist stock (hint, place-candy) plus the play streak that refills it.
extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")
const AssistRules = preload("res://scripts/state/assist_rules.gd")

signal changed(kind: String, count: int)
signal save_failed(reason: String)

var data: Dictionary = AssistRules.new_data()
var _store: DualSlotStore

func _init(profile_dir: String) -> void:
	_store = DualSlotStore.new(profile_dir, "assists")
	var read := _store.read_json()
	data = AssistRules.sanitize(read.data if read.ok else {})

func count(kind: String) -> int:
	return int(data.get(kind, 0))

func try_consume(kind: String) -> bool:
	var res := AssistRules.consume(data, kind)
	if not res.ok:
		return false
	_commit(res.data, [kind])
	return true

func grant(kind: String, amount: int) -> int:
	var before := count(kind)
	_commit(AssistRules.add(data, kind, amount), [kind])
	return count(kind) - before

func on_level_won(today: String = "") -> Dictionary:
	var res := AssistRules.record_win(data, today if today != "" else AssistRules.today())
	if res.data == data:
		return {}
	_commit(res.data, res.reward.keys())
	return res.reward

func _commit(next: Dictionary, kinds: Array) -> void:
	data = next
	if not _store.write_json(data):
		save_failed.emit("write_failed")
	for kind in kinds:
		changed.emit(kind, count(kind))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_assist_inventory.gd`
Expected: `ASSIST_INVENTORY_PASS`.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/state/assist_inventory.gd game/tests/test_assist_inventory.gd
rtk git commit -m "feat(state): persist assist stock and play streak"
```

---

### Task 3: Chọn ô cho Đặt kẹo

**Files:**
- Create: `game/scripts/core/place_candy_assist.gd`
- Test: `game/tests/test_place_candy_assist.gd`

**Interfaces:**
- Consumes: `HintEngine._build_hint_work_board(board, size, regions, solution)`, `SolverTechniques._try_single_candidate(work, size, regions)` → `{"found", "cell": [r, c], ...}`, `CellModel.CellKind`, `CellModel.is_available(kind)`, `CandyRules.zone_of(regions, r, c)`.
- Produces: `static func pick_cell(board: Array, size: int, regions: Array, solution: Array) -> Array` → `[row, col]` hoặc `[]`.

Luật: (1) nếu suy luận ô duy nhất trả về một ô **trùng đáp án** và ô đó còn trống (BLANK/MARK) → chọn; (2) ngược lại, trong các hàng còn thiếu kẹo, chọn ô đáp án thuộc vùng có ít ô trống (BLANK/MARK) nhất; hòa → hàng nhỏ nhất (cột do đáp án quyết định); (3) không còn ô → `[]`.

- [ ] **Step 1: Write the failing test**

`game/tests/test_place_candy_assist.gd`:

```gdscript
extends SceneTree

const Pick = preload("res://scripts/core/place_candy_assist.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const B := CellModel.CellKind.BLANK
const M := CellModel.CellKind.MARK
const C := CellModel.CellKind.CANDY
# Tutorial board from RST-028: solution [1,3,0,2]
const REGIONS := ["ABCC", "AAAC", "ADDC", "ADDD"]
const SOLUTION := [1, 3, 0, 2]
var failures: Array[String] = []

func _init() -> void:
	var empty := _board([[B,B,B,B],[B,B,B,B],[B,B,B,B],[B,B,B,B]])
	var cell := Pick.pick_cell(empty, 4, REGIONS, SOLUTION)
	check(cell.size() == 2 and int(SOLUTION[cell[0]]) == cell[1], "always a solution cell")
	# Region B is the single cell (0,1): smallest region wins the fallback too.
	check(cell == [0, 1], "single-cell region picked first")
	# Wrong X on a solution cell is still pickable (try_candy accepts MARK).
	var marked := _board([[B,M,B,B],[B,B,B,B],[B,B,B,B],[B,B,B,B]])
	check(Pick.pick_cell(marked, 4, REGIONS, SOLUTION) == [0, 1], "marked solution cell pickable")
	var three := _board([[B,C,B,B],[B,B,B,C],[C,B,B,B],[B,B,B,B]])
	check(Pick.pick_cell(three, 4, REGIONS, SOLUTION) == [3, 2], "last candy")
	var full := _board([[B,C,B,B],[B,B,B,C],[C,B,B,B],[B,B,C,B]])
	check(Pick.pick_cell(full, 4, REGIONS, SOLUTION).is_empty(), "solved -> empty")
	if failures.is_empty():
		print("PLACE_CANDY_ASSIST_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _board(rows: Array) -> Array:
	var out: Array = []
	for r in rows: out.append((r as Array).duplicate())
	return out

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_place_candy_assist.gd`
Expected: FAIL — file không tồn tại.

- [ ] **Step 3: Write minimal implementation**

`game/scripts/core/place_candy_assist.gd`:

```gdscript
# Chooses the cell the place-candy assist fills: a deduced single first,
# otherwise the solution cell of the region with the fewest open cells.
extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const HintEngine = preload("res://scripts/core/hint_engine.gd")
const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")

static func pick_cell(board: Array, size: int, regions: Array, solution: Array) -> Array:
	var work := HintEngine._build_hint_work_board(board, size, regions, solution)
	var single := SolverTechniques._try_single_candidate(work, size, regions)
	if single.get("found", false):
		var cell: Array = single["cell"]
		var r := int(cell[0]); var c := int(cell[1])
		if r < solution.size() and int(solution[r]) == c and CellModel.is_available(board[r][c]):
			return [r, c]
	var best: Array = []
	var best_open := 1 << 30
	for r in range(mini(size, solution.size())):
		var c := int(solution[r])
		if not CellModel.is_available(board[r][c]):
			continue
		var open := _open_cells(board, size, regions, CandyRules.zone_of(regions, r, c))
		if open < best_open:
			best_open = open
			best = [r, c]
	return best

static func _open_cells(board: Array, size: int, regions: Array, zone: String) -> int:
	var n := 0
	for r in range(size):
		for c in range(size):
			if CandyRules.zone_of(regions, r, c) == zone and CellModel.is_available(board[r][c]):
				n += 1
	return n
```

- [ ] **Step 4: Run test to verify it passes**

Run: `rtk godot --headless --path game --script res://tests/test_place_candy_assist.gd`
Expected: `PLACE_CANDY_ASSIST_PASS`. Nếu `_build_hint_work_board` đổi chữ ký, đọc `game/scripts/core/hint_engine.gd:142` và chỉnh lời gọi; không đổi engine.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/core/place_candy_assist.gd game/tests/test_place_candy_assist.gd
rtk git commit -m "feat(core): pick the cell for the place-candy assist"
```

---

### Task 4: Coordinator chặn và trừ kho Hint, thêm `place_candy`

**Files:**
- Modify: `game/scripts/screens/puzzle_hint_coordinator.gd` (biến đầu file; `request_hint` dòng 38–64; thêm hàm mới sau `apply_hint`)
- Test: `game/tests/test_assist_hint_gate.gd`

**Interfaces:**
- Consumes: `AssistInventory.count/try_consume` (Task 2), `PlaySession` (`phase`, `board`, `level`, `try_candy`, `mark_x`).
- Produces trên coordinator:
  - `signal stock_empty(kind: String)`
  - `var inventory: Variant = null` (null = không giới hạn)
  - `func place_candy(session: Variant, cell: Array) -> void` (đặt kẹo với cờ `_applying` để combo reset)

- [ ] **Step 1: Write the failing test**

`game/tests/test_assist_hint_gate.gd`:

```gdscript
extends SceneTree

const Coordinator = preload("res://scripts/screens/puzzle_hint_coordinator.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	var dir := OS.get_user_data_dir().path_join("assist_gate_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	var coord := Coordinator.new()
	coord.inventory = inv
	var empties: Array = []
	coord.stock_empty.connect(func(kind): empties.append(kind))
	var session := PlaySession.new(LEVEL)
	coord.request_hint(session)
	check(inv.count("hint") == 2, "showing a hint costs one")
	check(session.hints_used == 1, "session still counts hint")
	coord.force_release()
	# Wrong X on a solution cell -> WRONG_MARK hint is free
	session.mark_x(0, 1)
	coord.request_hint(session)
	check(inv.count("hint") == 2, "wrong-mark hint is free")
	coord.force_release()
	session.mark_x(0, 1)
	# Pressing hint again while showing only dismisses (no extra cost)
	coord.request_hint(session)
	coord.request_hint(session)
	check(inv.count("hint") == 1, "toggle-close does not charge")
	coord.force_release()
	inv.try_consume("hint")
	coord.request_hint(session)
	check(empties == ["hint"] and inv.count("hint") == 0, "empty stock emits stock_empty")
	check(not coord.is_hint_showing(), "no hint shown when empty")
	# place_candy marks the candy as assist-placed
	var flags: Array = []
	session.candy_found.connect(func(_r, _c, _z): flags.append(coord.is_applying()))
	coord.place_candy(session, [0, 1])
	check(session.cell_at(0, 1) == CellModel.CellKind.CANDY, "candy placed")
	check(flags == [true], "placed while applying (combo resets)")
	check(not coord.is_applying(), "flag cleared")
	# No inventory -> unlimited, no signal
	var free_coord := Coordinator.new()
	free_coord.stock_empty.connect(func(kind): empties.append("free"))
	free_coord.request_hint(PlaySession.new(LEVEL))
	check(not empties.has("free"), "null inventory never empty")
	inv._store.remove_all(); DirAccess.remove_absolute(dir)
	if failures.is_empty():
		print("ASSIST_HINT_GATE_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Ghi chú: coordinator không có overlay trong test này, nên `is_hint_showing()` dựa vào `_hint_overlay` sẽ luôn false. Bước 3 thêm `_current_hint` vào kiểm tra đang hiện để toggle-close hoạt động cả khi không có overlay.

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_hint_gate.gd`
Expected: FAIL — `inventory`/`stock_empty`/`place_candy` chưa tồn tại.

- [ ] **Step 3: Implement**

Thêm sau `var _session: Variant = null`:

```gdscript
# Assist stock; null keeps hints unlimited (tutorial, tests).
var inventory: Variant = null
signal stock_empty(kind: String)
```

Trong `request_hint`, thay khối từ `if is_hint_showing():` đến `if not _mutex.try_acquire("hint"):` bằng:

```gdscript
	if is_hint_showing() or not _current_hint.is_empty():
		dismiss_hint()
		return
	if inventory != null and inventory.count("hint") <= 0:
		stock_empty.emit("hint")
		return
	if not _mutex.try_acquire("hint"):
		return
```

Thay dòng cuối của `request_hint`:

```gdscript
	if hint.get("strategy") != "WRONG_MARK":
		session.use_hint()
		if inventory != null: inventory.try_consume("hint")
```

Thêm sau `apply_hint`:

```gdscript
func place_candy(session: Variant, cell: Array) -> void:
	if session == null or cell.size() != 2:
		return
	dismiss_hint(false)
	_applying = true
	session.try_candy(int(cell[0]), int(cell[1]))
	_applying = false
	if _sfx != null: _sfx.play(SfxCatalog.Effect.HINT_APPLY)
	Vibration.pulse(Vibration.Strength.SOFT)
	if _board != null: _board.redraw()
```

- [ ] **Step 4: Run tests**

Run: `rtk godot --headless --path game --script res://tests/test_assist_hint_gate.gd`
Expected: `ASSIST_HINT_GATE_PASS`.
Run lại suite hint cũ: `rtk godot --headless --path game --script res://tests/test_hint_overlay.gd` → PASS.

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/puzzle_hint_coordinator.gd game/tests/test_assist_hint_gate.gd
rtk git commit -m "feat(hint): charge the hint stock when a hint is shown"
```

---

### Task 5: UI — nút Đặt kẹo, badge, toast, popup "Hết lượt", chuỗi locale

**Files:**
- Create: `game/scripts/screens/assist_dock.gd`
- Create: `game/scripts/screens/assist_empty_popup.gd`
- Modify: `game/scripts/screens/puzzle_layout.gd:189-209` (khối badge Hint) và dict trả về
- Modify: `game/locale/strings.csv` (thêm cuối file)
- Modify: `game/tests/test_hint_overlay.gd:95-100` (đổi tên test, giữ assert)
- Test: `game/tests/test_assist_ui.gd`

**Interfaces:**
- Consumes: `PuzzleLayout._make_3d_btn(...)`, `PuzzleLayout._card_sb(...)`, `Palette`, `FontTokens.body_bold()`.
- Produces:
  - `AssistDock.attach_badge(btn: Button, label_name: String) -> void` (badge ẩn, node `Badge/<label_name>`)
  - `AssistDock.set_badge(btn: Button, value: int) -> void` (hiện badge với số)
  - `AssistDock.make_place_button() -> Button` (tên `PlaceBtn`, icon `res://assets/candy/candy_icon.png`, có badge `PlaceCount`)
  - `AssistDock.show_toast(parent: Control, text: String) -> Label` (tự xóa sau 2 s)
  - `AssistEmptyPopup` (`extends Control`): `func open(kind: String)`, `func close()`, `signal ad_pressed()`, biến `title_label: Label`, `body_label: Label`, `ad_btn: Button`, `ad_badge: Label` (luôn ẩn), `close_btn: Button`
  - `PuzzleLayout.build()` trả thêm key `"place"`

- [ ] **Step 1: Write the failing test**

`game/tests/test_assist_ui.gd`:

```gdscript
extends SceneTree

const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")
const AssistDock = preload("res://scripts/screens/assist_dock.gd")
const EmptyPopup = preload("res://scripts/screens/assist_empty_popup.gd")
var failures: Array[String] = []

func _init() -> void:
	var root := Control.new()
	var n: Dictionary = PuzzleLayout.build(root)
	var place: Button = n.get("place")
	check(place != null and place.name == "PlaceBtn", "place button built")
	check(place.get_parent() == n["hint"].get_parent(), "place sits in the dock")
	check(place.get_index() == n["hint"].get_index() + 1, "place right of hint")
	var hb: Control = n["hint"].get_node("Badge")
	check(not hb.visible, "hint badge hidden until bound")
	AssistDock.set_badge(n["hint"], 0)
	check(hb.visible and n["hint"].get_node("Badge/HintCount").text == "0", "badge shows zero")
	AssistDock.set_badge(place, 4)
	check(place.get_node("Badge/PlaceCount").text == "4", "place badge")
	var popup := EmptyPopup.new()
	root.add_child(popup)
	check(not popup.visible, "popup starts hidden")
	popup.open("place")
	check(popup.visible, "popup opens")
	check(not popup.ad_badge.visible, "ad badge hidden until ads exist")
	var text := popup.title_label.text + popup.body_label.text
	check(not text.to_lower().contains("streak") and not text.contains("chuỗi"), "no streak shown")
	var hits: Array = []
	popup.ad_pressed.connect(func(): hits.append(1))
	popup.ad_btn.pressed.emit()
	check(hits == [1], "ad button emits")
	popup.close_btn.pressed.emit()
	check(not popup.visible, "close hides")
	root.free()
	if failures.is_empty():
		print("ASSIST_UI_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_ui.gd`
Expected: FAIL — `assist_dock.gd` không tồn tại.

- [ ] **Step 3: Implement**

`game/scripts/screens/assist_dock.gd`:

```gdscript
# Dock pieces for the assists: count badges, the place-candy button, a short toast.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const PLACE_ICON := "res://assets/candy/candy_icon.png"

static func attach_badge(btn: Button, label_name: String) -> void:
	var PuzzleLayout = load("res://scripts/screens/puzzle_layout.gd")
	var badge := PanelContainer.new()
	badge.name = "Badge"
	badge.add_theme_stylebox_override("panel", PuzzleLayout._card_sb(Palette.BOARD_BLUE, Palette.BOARD_BLUE_EDGE, 999, 2, 8, 2))
	badge.position = Vector2(72, -8)
	badge.custom_minimum_size = Vector2(34, 34)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false  # Shown once an assist stock is bound.
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	var font := FontTokens.body_bold()
	if font != null: label.add_theme_font_override("font", font)
	badge.add_child(label)
	btn.add_child(badge)

static func set_badge(btn: Button, value: int) -> void:
	var badge := btn.get_node_or_null("Badge") as Control
	if badge == null or badge.get_child_count() == 0:
		return
	(badge.get_child(0) as Label).text = str(value)
	badge.visible = true

static func make_place_button() -> Button:
	var PuzzleLayout = load("res://scripts/screens/puzzle_layout.gd")
	var btn: Button = PuzzleLayout._make_3d_btn("PlaceBtn", PLACE_ICON, Color.WHITE, Palette.BOARD_BTN_EDGE, Color.WHITE, Vector2(104, 104), 28, 8, Vector2(60, 60))
	attach_badge(btn, "PlaceCount")
	return btn

static func show_toast(parent: Control, text: String) -> Label:
	var toast := Label.new()
	toast.name = "AssistToast"
	toast.text = text
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 30)
	toast.add_theme_color_override("font_color", Color.WHITE)
	toast.add_theme_color_override("font_outline_color", Palette.BOARD_HINT_EDGE)
	toast.add_theme_constant_override("outline_size", 10)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position.y += 220
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(toast)
	if parent.is_inside_tree():
		var tw := toast.create_tween()
		tw.tween_interval(1.6)
		tw.tween_property(toast, "modulate:a", 0.0, 0.4)
		tw.tween_callback(toast.queue_free)
	return toast
```

`load()` thay vì `preload()` cho `puzzle_layout.gd` để tránh vòng preload (layout preload dock).

`game/scripts/screens/assist_empty_popup.gd`:

```gdscript
# "Out of assists" sheet. Shows how to earn more; the ad button is a placeholder.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

signal ad_pressed()

var title_label: Label
var body_label: Label
var ad_btn: Button
var ad_badge: Label
var close_btn: Button

func _init() -> void:
	name = "AssistEmptyPopup"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE; sb.set_corner_radius_all(32)
	sb.border_width_bottom = 8; sb.border_color = Palette.BOARD_HINT_EDGE
	sb.content_margin_left = 36; sb.content_margin_right = 36
	sb.content_margin_top = 32; sb.content_margin_bottom = 32
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	card.add_child(col)
	title_label = _label("Title", 38, FontTokens.heading())
	body_label = _label("Body", 26, FontTokens.body_bold())
	col.add_child(title_label)
	col.add_child(body_label)
	col.add_child(_ad_button())
	close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = tr("assist.close")
	close_btn.custom_minimum_size = Vector2(0, 88)
	close_btn.pressed.connect(close)
	col.add_child(close_btn)

func open(kind: String) -> void:
	title_label.text = tr("assist.empty_title_" + kind)
	body_label.text = tr("assist.empty_body")
	visible = true

func close() -> void:
	visible = false

func _label(node_name: String, font_size: int, font: Font) -> Label:
	var l := Label.new()
	l.name = node_name
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("#23365E"))
	if font != null: l.add_theme_font_override("font", font)
	return l

func _ad_button() -> Control:
	var wrap := CenterContainer.new()
	var btn := Button.new()
	btn.name = "AdBtn"
	ad_btn = btn
	btn.custom_minimum_size = Vector2(150, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.ERROR_RED; sb.set_corner_radius_all(40)
	sb.border_width_bottom = 8; sb.border_color = Palette.ERROR_RED.darkened(0.35)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state, sb)
	btn.text = "▶"
	btn.add_theme_font_size_override("font_size", 72)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(func(): ad_pressed.emit())
	ad_badge = Label.new()
	ad_badge.name = "AdBadge"
	ad_badge.visible = false  # Remaining ad views; shown once rewarded ads exist.
	ad_badge.position = Vector2(112, -10)
	btn.add_child(ad_badge)
	wrap.add_child(btn)
	return wrap
```

Ghi chú: nếu font `▶` không render trên Web (xem chú thích ở `help_screen.gd:125`), vẽ tam giác bằng `Polygon2D` trong `AdBtn` thay vì `text`.

Trong `puzzle_layout.gd`:
- Thêm `const AssistDock = preload("res://scripts/screens/assist_dock.gd")` cạnh các preload khác.
- Thay toàn bộ khối từ `var badge := PanelContainer.new()` tới `hint.add_child(badge)` bằng `AssistDock.attach_badge(hint, "HintCount")`.
- Sau `dock.add_child(hint)` thêm:

```gdscript
	var place := AssistDock.make_place_button()
	dock.add_child(place)
```

- Thêm `"place": place,` vào dict trả về.
- Kiểm tra `wc -l` ≤ 300.

Trong `game/tests/test_hint_overlay.gd`, đổi tên `_test_hint_badge_hidden_without_limit` → `_test_hint_badge_hidden_until_bound` (và lời gọi), đổi nhãn assert thành `"hint badge hidden until a stock is bound"`.

Thêm cuối `game/locale/strings.csv`:

```csv
assist.empty_title_hint,Out of hints,ヒントがありません,Hết lượt gợi ý,Petunjuk habis,Sem dicas,Sin pistas,힌트가 없어요
assist.empty_title_place,Out of candy drops,キャンディ配置がありません,Hết lượt đặt kẹo,Taruh permen habis,Sem doces extras,Sin caramelos extra,사탕 놓기가 없어요
assist.empty_body,Finish a level on 7 different days in a row to earn a new pack.,7日連続でレベルをクリアすると新しいパックがもらえます。,Hoàn thành một màn mỗi ngày trong 7 ngày liên tiếp để nhận gói mới.,Selesaikan satu level setiap hari selama 7 hari berturut-turut untuk paket baru.,Conclua uma fase por dia durante 7 dias seguidos para ganhar um novo pacote.,Completa un nivel al día durante 7 días seguidos para ganar un paquete nuevo.,7일 연속으로 매일 한 레벨을 깨면 새 꾸러미를 받아요.
assist.close,Close,閉じる,Đóng,Tutup,Fechar,Cerrar,닫기
assist.coming_soon,Coming soon,近日公開,Sắp có,Segera hadir,Em breve,Próximamente,곧 만나요
assist.reward,+%d hints  +%d candy drops,ヒント+%d　キャンディ配置+%d,+%d gợi ý  +%d đặt kẹo,+%d petunjuk  +%d taruh permen,+%d dicas  +%d doces extras,+%d pistas  +%d caramelos extra,힌트 +%d  사탕 놓기 +%d
```

Sau khi sửa CSV, chạy `rtk godot --headless --path game --import` để sinh lại `.translation`.

- [ ] **Step 4: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_assist_ui.gd       # ASSIST_UI_PASS
rtk godot --headless --path game --script res://tests/test_hint_overlay.gd    # PASS
rtk godot --headless --path game --script res://tests/test_screens.gd         # PASS
```

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/assist_dock.gd game/scripts/screens/assist_empty_popup.gd game/scripts/screens/puzzle_layout.gd game/locale/ game/tests/test_assist_ui.gd game/tests/test_hint_overlay.gd
rtk git commit -m "feat(ui): add place-candy button, assist badges and out-of-stock popup"
```

---

### Task 6: Nối vào màn chơi và app shell

**Files:**
- Create: `game/scripts/screens/puzzle_assist_controller.gd`
- Modify: `game/scripts/screens/puzzle_screen.gd` (`_ensure_nodes`, `_connect_ui`, `setup`, `_on_level_won`)
- Modify: `game/scripts/screens/app_shell.gd` (preload, biến, `_ready`, nhánh `"puzzle"`)
- Test: `game/tests/test_assist_flow.gd`

**Interfaces:**
- Consumes: Task 2 `AssistInventory`, Task 3 `PlaceCandyAssist.pick_cell`, Task 4 `coordinator.inventory/stock_empty/place_candy`, Task 5 `AssistDock.set_badge/show_toast`, `AssistEmptyPopup.open/ad_pressed`, `PuzzleLayout.build()["place"]`.
- Produces:
  - `PuzzleAssistController`: `func setup(screen: Control, hint_btn: Button, place_btn: Button) -> void`, `func bind(inventory: Variant, coordinator: Variant) -> void`, `func on_place(session: Variant, coordinator: Variant) -> void`, `func on_level_won(session: Variant, is_custom: bool) -> Dictionary`, `var popup`.
  - `puzzle_screen.gd`: `var assists: Variant = null` (app_shell gán trước `setup`), `var place_btn: Button`, `var assist_ctl`.

- [ ] **Step 1: Write the failing test**

`game/tests/test_assist_flow.gd`:

```gdscript
extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const Inventory = preload("res://scripts/state/assist_inventory.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const LEVEL := {"id": "T1", "size": 4, "regions": ["ABCC", "AAAC", "ADDC", "ADDD"], "solution": [1, 3, 0, 2]}
var failures: Array[String] = []

func _init() -> void:
	PuzzleScreen.hold_results = false
	var dir := OS.get_user_data_dir().path_join("assist_flow_%s" % Time.get_ticks_usec())
	var inv := Inventory.new(dir)
	inv.grant("place", 9)  # place = 10
	var screen := PuzzleScreen.new()
	screen.assists = inv
	root.add_child(screen)
	screen.setup(null, null, null, LEVEL, false)
	check(screen.place_btn.get_node("Badge/PlaceCount").text == "10", "place badge bound")
	check(screen.hint_btn.get_node("Badge").visible, "hint badge visible when bound")
	for i in 3:
		screen.place_btn.pressed.emit()
	check(screen.session.remaining_candies() == 1 and inv.count("place") == 7, "three placed, three charged")
	screen.place_btn.pressed.emit()
	check(screen.session.phase == 1, "last candy wins the level")
	check(inv.count("place") == 6, "last candy charged once")
	screen.place_btn.pressed.emit()
	check(inv.count("place") == 6, "no charge after win")
	check(inv.data.streakDays == 0, "custom win does not count for streak")
	# Empty stock opens popup
	var screen2 := PuzzleScreen.new()
	var inv2 := Inventory.new(dir + "_b")
	inv2.try_consume("place")
	screen2.assists = inv2
	root.add_child(screen2)
	screen2.setup(null, null, null, LEVEL, false)
	screen2.place_btn.pressed.emit()
	check(screen2.assist_ctl.popup.visible, "empty place opens popup")
	check(screen2.session.remaining_candies() == 4, "nothing placed when empty")
	# Campaign-style win records streak once even if won handler runs twice
	screen2.assist_ctl.on_level_won(screen2.session, false)
	screen2.assist_ctl.on_level_won(screen2.session, false)
	check(inv2.data.streakDays == 1, "resume won twice records once")
	screen.queue_free(); screen2.queue_free()
	inv._store.remove_all(); inv2._store.remove_all()
	if failures.is_empty():
		print("ASSIST_FLOW_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
```

Nếu `PuzzleScreen.new()` không dựng được node ngoài scene (kiểm tra cách `test_screens.gd` tạo màn chơi), dùng đúng cách đó, ví dụ `load("res://scenes/puzzle.tscn").instantiate()`.

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk godot --headless --path game --script res://tests/test_assist_flow.gd`
Expected: FAIL — `assists`/`place_btn` không tồn tại.

- [ ] **Step 3: Implement**

`game/scripts/screens/puzzle_assist_controller.gd`:

```gdscript
# Binds the assist stock to the puzzle dock: badges, place-candy, empty popup, rewards.
extends RefCounted

const AssistDock = preload("res://scripts/screens/assist_dock.gd")
const AssistEmptyPopup = preload("res://scripts/screens/assist_empty_popup.gd")
const PlaceCandyAssist = preload("res://scripts/core/place_candy_assist.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var inventory: Variant = null
var popup: AssistEmptyPopup = null
var _screen: Control = null
var _hint_btn: Button = null
var _place_btn: Button = null

func setup(screen: Control, hint_btn: Button, place_btn: Button) -> void:
	_screen = screen; _hint_btn = hint_btn; _place_btn = place_btn
	if popup == null:
		popup = AssistEmptyPopup.new()
		screen.add_child(popup)
		popup.ad_pressed.connect(func(): AssistDock.show_toast(_screen, _screen.tr("assist.coming_soon")))

func bind(inv: Variant, coordinator: Variant) -> void:
	inventory = inv
	if _place_btn != null: _place_btn.visible = inventory != null
	if coordinator != null: coordinator.inventory = inventory
	if inventory == null:
		return
	if coordinator != null and not coordinator.stock_empty.is_connected(popup.open):
		coordinator.stock_empty.connect(popup.open)
	if not inventory.changed.is_connected(_on_changed):
		inventory.changed.connect(_on_changed)
	_on_changed("hint", inventory.count("hint"))
	_on_changed("place", inventory.count("place"))

func on_place(session: Variant, coordinator: Variant) -> void:
	if inventory == null or session == null or session.phase != PlaySession.Phase.ACTIVE:
		return
	if inventory.count("place") <= 0:
		popup.open("place")
		return
	var lvl: Dictionary = session.level
	var cell := PlaceCandyAssist.pick_cell(session.board, int(lvl["size"]), lvl["regions"], lvl["solution"])
	if cell.is_empty() or not inventory.try_consume("place"):
		return
	coordinator.place_candy(session, cell)

func on_level_won(session: Variant, is_custom: bool) -> Dictionary:
	if inventory == null or is_custom or session == null:
		return {}
	var reward: Dictionary = inventory.on_level_won()
	if not reward.is_empty() and _screen != null:
		AssistDock.show_toast(_screen, _screen.tr("assist.reward") % [int(reward.get("hint", 0)), int(reward.get("place", 0))])
	return reward

func _on_changed(kind: String, count: int) -> void:
	var btn := _hint_btn if kind == "hint" else _place_btn
	if btn != null: AssistDock.set_badge(btn, count)
```

Trong `puzzle_screen.gd` (giữ ≤ 300 dòng; gộp khai báo bằng `;` như file đang làm):
- Thêm `const PuzzleAssistController = preload("res://scripts/screens/puzzle_assist_controller.gd")` cạnh preload `PuzzleHintCoordinator` — gộp lên cùng dòng khai báo `var combo := ComboFeedback.new()` dưới dạng biến: `var combo := ComboFeedback.new(); var assist_ctl := PuzzleAssistController.new(); var assists: Variant = null; var place_btn: Button`.
- `_ensure_nodes`: sửa dòng `hint_btn = n["hint"]; …` thành `hint_btn = n["hint"]; place_btn = n.get("place"); restart_btn = n["restart"]; home_btn = n["back"]`; sau `hint_coordinator.setup(...)` thêm `assist_ctl.setup(self, hint_btn, place_btn)`.
- `_connect_ui`: sửa `_btn_conn(hint_btn, _on_hint)` thành `_btn_conn(hint_btn, _on_hint); _btn_conn(place_btn, _on_place)`.
- `setup`: sửa `if board != null: combo.bind(board, sfx)` thành `if board != null: combo.bind(board, sfx); assist_ctl.bind(assists, hint_coordinator)` — chú ý: trong GDScript, `;` sau `if x:` đưa cả hai lệnh vào thân `if`; đây là ý muốn (board luôn có sau `_ensure_nodes`).
- Thêm hàm sau `_on_hint`:

```gdscript
func _on_place() -> void:
	combo.reset(); assist_ctl.on_place(session, hint_coordinator)
```

- `_on_level_won`: ngay đầu hàm thêm `assist_ctl.on_level_won(session, _is_custom)` (gộp vào dòng `if board != null:` không được — thêm thành dòng riêng; bù bằng cách gộp `board.play_win_bounce()` lên dòng `if board != null: board.play_win_bounce()`).
- Chạy `wc -l game/scripts/screens/puzzle_screen.gd` → ≤ 300.

Ghi chú `combo.reset()` trong `_on_place`: kẹo đặt bằng trợ giúp reset combo qua `is_applying()` rồi; `reset()` ở đây khớp `_on_hint`.

Trong `app_shell.gd` (299 dòng, phải giữ ≤ 300):
- Gộp preload vào dòng `const ProgressManager = preload(...)`: `const ProgressManager = preload("res://scripts/state/progress_manager.gd"); const AssistInventory = preload("res://scripts/state/assist_inventory.gd")`.
- Dòng 37: `var profile_dir: String = "user://profile"; var assists: Variant = null`.
- Trong `_ready`, ngay sau dòng `if config == null: …` thêm một dòng: `if assists == null: assists = AssistInventory.new(profile_dir); assists.save_failed.connect(_on_save_failed)`.
- Nhánh `"puzzle"`: sửa dòng `if screen.has_method("setup"): screen.call("setup", …)` thành `if screen.has_method("setup"): screen.set("assists", assists); screen.call("setup", …)` (giữ nguyên tham số).
- Chạy `wc -l game/scripts/screens/app_shell.gd` → ≤ 300. Nếu `_on_save_failed` có chữ ký khác `(reason: String)`, đọc `app_shell.gd:297` và nối tương ứng.

- [ ] **Step 4: Run tests**

```bash
rtk godot --headless --path game --script res://tests/test_assist_flow.gd   # ASSIST_FLOW_PASS
rtk godot --headless --path game --script res://tests/test_screens.gd       # PASS
rtk godot --headless --path game --script res://tests/test_integration.gd   # PASS
rtk godot --headless --path game --script res://tests/test_combo_screen.gd  # PASS
```

- [ ] **Step 5: Commit**

```bash
rtk git add game/scripts/screens/puzzle_assist_controller.gd game/scripts/screens/puzzle_screen.gd game/scripts/screens/app_shell.gd game/tests/test_assist_flow.gd
rtk git commit -m "feat(puzzle): wire assist stock, place-candy and streak rewards into play"
```

---

### Task 7: Tài liệu và full gate

**Files:**
- Modify: `docs/DECISIONS.md` (thêm RST-029 trên RST-028; sửa câu badge trong RST-024)
- Modify: `docs/STATUS.md` (mục mới đầu danh sách tiến độ)
- Create: `scratch/verification/2026-10-14-assist-inventory.md`

- [ ] **Step 1: DECISIONS**

Thêm ngay dưới `> Quản lý version: ...`:

```markdown
## RST-029 — Kho trợ giúp (Hint + Đặt kẹo) và streak 7 ngày

Ngày 2026-10-14. Thay câu "hint không giới hạn" của RST-024. Đặc tả: [assist inventory](superpowers/specs/2026-10-14-assist-inventory-design.md).

- **Kho:** Hint và Đặt kẹo lưu bền, khởi đầu 3/1, tối đa 10 mỗi loại.
- **Hint:** trừ 1 khi gợi ý hiện ra; `WRONG_MARK` miễn phí; hết lượt → popup.
- **Đặt kẹo:** đặt ngay một kẹo đúng (ưu tiên ô suy luận duy nhất, sau đó vùng ít ô trống nhất); viên cuối thắng level; reset combo.
- **Streak:** ngày tính khi thắng ≥1 level (không tính level custom/tutorial); lỡ ngày → về ngày 1; đủ 7 ngày → gói theo mức dùng (0–1 → 2, 2–4 → 3, ≥5 → 4 mỗi loại).
- **Quảng cáo:** chỉ có nút đỏ ▶ giữ chỗ trong popup, chưa cộng lượt; badge góc ẩn tới khi có tính năng.
```

Trong RST-024 đổi câu `Badge số lượt trên nút Hint ẩn vì hint không giới hạn; chỉ hiện khi có quota thật.` thành `Badge số lượt trên nút Hint hiển thị theo kho trợ giúp (RST-029).`

- [ ] **Step 2: STATUS**

Thêm trên mục `## Bỏ given toàn hệ thống`:

```markdown
## Kho trợ giúp và streak (2026-10-14, `feat/v1.0.1/assist-inventory`)

- Hint giới hạn theo kho; thêm trợ giúp Đặt kẹo; streak 7 ngày thắng level phát gói theo mức dùng (RST-029).
- Kiểm chứng: suite `test_assist_*`, `test_place_candy_assist`, full `tools/verify.py`. Chưa QA thiết bị cho popup/toast.
- Còn mở: nguồn quảng cáo có thưởng (chờ quyết định SDK).
```

- [ ] **Step 3: Full gate**

```bash
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/
rtk python -B tools/verify.py --godot <godot>
```

Expected: hai lệnh `rg` không có kết quả; `verify.py` pass toàn bộ. Ghi revision (`rtk git rev-parse --short HEAD`), lệnh, kết quả và giới hạn ("headless, chưa QA thiết bị") vào `scratch/verification/2026-10-14-assist-inventory.md`.

- [ ] **Step 4: Commit**

```bash
rtk git add docs/DECISIONS.md docs/STATUS.md scratch/verification/2026-10-14-assist-inventory.md
rtk git commit -m "docs(assist): record assist stock decision and verification"
```
