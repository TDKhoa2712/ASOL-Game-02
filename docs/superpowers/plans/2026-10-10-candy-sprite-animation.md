# Candy Sprite Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kẹo trên board là linh vật có biểu cảm, phát 5 animation sprite (`appear`, `idle`, `error`, `sad`, `win`) từ một atlas raster sinh offline, không thêm node per-cell.

**Architecture:** Một tool Godot headless ghép các mảnh SVG linh vật (cùng viewBox 320×260) thành atlas PNG + JSON. Runtime gồm `CandyAtlas` (cache static atlas/meta), `CandyAnimState` (state per-cell thuần, `advance()` báo khi khung đổi) và `CandyCellDrawer` (vẽ kẹo, tách khỏi `puzzle_board.gd` để giữ ≤ 300 dòng). Board chỉ `queue_redraw()` khi khung đổi.

**Tech Stack:** Godot 4.7 / GDScript, `Image.load_svg_from_string`, test dạng `extends SceneTree` chạy headless.

**Spec:** `docs/superpowers/specs/2026-10-10-candy-sprite-animation-design.md`

## Global Constraints

- Module GDScript ≤ 300 dòng; không autoload; logic thuần không phụ thuộc node.
- Nguyên gốc: không dùng pixel/tên/cấu trúc từ `extracted_reusable/`; không tên nào khớp regex clean-room trong AGENTS.md §3.
- Khung atlas 128×128, padding 2px; idle/sad 12fps, appear/error/win 30fps.
- `MAX_CONCURRENT_IDLE = 6`; idle chờ ngẫu nhiên tất định 4–7s mỗi ô.
- `LayoutTokens.motion_enabled == false` → không có animation, kẹo ở khung tĩnh.
- Thiếu atlas → board dùng texture tĩnh cũ (`_candy_tex`), không crash.
- Godot executable: `<godot>` (ví dụ `rtk godot`); mọi test chạy `<godot> --headless --path game --script res://tests/<file>.gd`.

## Review Focus

- Restore session (vào lại level đang chơi dở) → mọi kẹo đã có phải hiện ở idle khung 0, không phát `appear` — test trong Task 4 (`sync`).
- Mất tim ở tim cuối: `error` rồi ngay `sad` → `sad` phải thắng — test trong Task 2 (`_test_sad_overrides_error`).
- Board 12×12 đầy kẹo không bao giờ quá 6 ô idle cùng lúc — test trong Task 2 (`_test_idle_cap`).
- Reduced motion bật giữa chừng → `advance` trả false, không redraw — test trong Task 2 (`_test_motion_off`).
- Atlas thiếu hoặc JSON hỏng → `CandyAtlas.ensure_loaded()` trả false, board fallback — test trong Task 3 (`_test_bad_json`).

---

### Task 1: Tool sinh atlas linh vật

**Files:**
- Create: `game/tools/build_mascot_atlas.gd`
- Create (output): `game/assets/candy/anim/mascot_atlas.png`, `game/assets/candy/anim/mascot_atlas.json`

**Interfaces:**
- Produces: JSON schema `{"version":1,"frame_size":[128,128],"anims":{"<name>":{"fps":int,"loop":bool,"frames":[[x,y],...]}}}`; anim counts appear 12, idle 18, error 16, sad 16, win 20 (tổng 82, lưới 10 cột).

- [ ] **Step 1: Viết tool**

```gdscript
# build_mascot_atlas.gd — Offline tool: composes the mascot SVG parts into a frame atlas.
# Run: <godot> --headless --path game --script res://tools/build_mascot_atlas.gd [-- --check]
extends SceneTree

const SRC := "res://assets/candy/"
const OUT_PNG := "res://assets/candy/anim/mascot_atlas.png"
const OUT_JSON := "res://assets/candy/anim/mascot_atlas.json"
const FRAME := 128
const PAD := 2
const COLS := 10
const SVG_SCALE := 0.175 # 640px-wide parts -> 112px
const BASE := Vector2i(112, 91)
const GROUND := 116 # y of mascot feet inside a frame
const WING_PIVOT_L := 0.29 # wing joint as fraction of BASE.x
const WING_PIVOT_R := 0.71
const ANIMS := [["appear", 12, 30, false], ["idle", 18, 12, false], ["error", 16, 30, false], ["sad", 16, 12, true], ["win", 20, 30, false]]

var _parts := {}

func _init() -> void:
	var check := OS.get_cmdline_user_args().has("--check")
	quit(_check() if check else _build())

func _build() -> int:
	for name in ["body", "body_sad", "wing_l", "wing_r", "wing_l_sad", "wing_r_sad", "leg_l", "leg_r", "shadow", "tear",
			"face_normal", "face_blink", "face_happy", "face_heart", "face_sad", "face_surprised"]:
		var img := Image.new()
		var scale := SVG_SCALE * (2.0 if name == "tear" else 1.0)
		if img.load_svg_from_string(FileAccess.get_file_as_string(SRC + name + ".svg"), scale) != OK:
			printerr("cannot load ", name); return 1
		img.convert(Image.FORMAT_RGBA8)
		_parts[name] = img
	var total := 0
	for a in ANIMS: total += a[1]
	var rows := int(ceil(float(total) / COLS))
	var atlas := Image.create(COLS * (FRAME + PAD), rows * (FRAME + PAD), false, Image.FORMAT_RGBA8)
	var meta := {"version": 1, "frame_size": [FRAME, FRAME], "anims": {}}
	var idx := 0
	for a in ANIMS:
		var frames := []
		for i in range(a[1]):
			var t := float(i) / float(max(1, a[1] - 1))
			var at := Vector2i((idx % COLS) * (FRAME + PAD), (idx / COLS) * (FRAME + PAD))
			atlas.blend_rect(_compose(_pose(a[0], t, i)), Rect2i(0, 0, FRAME, FRAME), at)
			frames.append([at.x, at.y]); idx += 1
		meta.anims[a[0]] = {"fps": a[2], "loop": a[3], "frames": frames}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_PNG.get_base_dir()))
	if atlas.save_png(OUT_PNG) != OK: printerr("save png failed"); return 1
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t")); f.close()
	print("MASCOT_ATLAS_BUILT ", atlas.get_size(), " frames=", total)
	return 0

func _pose(anim: String, t: float, i: int) -> Dictionary:
	var p := {"body": "body", "wing": "", "face": "face_normal", "sx": 1.0, "sy": 1.0, "sc": 1.0,
		"dx": 0.0, "dy": 0.0, "wing_s": 1.0, "tint": 0.0, "tear": -1.0}
	match anim:
		"appear":
			var k := 1.0 - pow(1.0 - t, 3.0)
			p.sc = 0.3 + 0.7 * k + 0.12 * sin(PI * k)
			p.sy = 1.0 - 0.12 * sin(PI * clampf((t - 0.6) / 0.4, 0.0, 1.0))
			p.sx = 2.0 - p.sy
			p.face = "face_surprised" if t < 0.6 else "face_normal"
		"idle":
			p.sy = 1.0 + 0.04 * sin(TAU * t); p.sx = 1.0 - 0.03 * sin(TAU * t)
			p.wing_s = 1.0 - 0.15 * absf(sin(TAU * t))
			p.face = "face_blink" if i == 8 or i == 9 else "face_normal"
		"error":
			p.dx = 6.0 * sin(TAU * 2.0 * t) * (1.0 - 0.5 * t)
			p.tint = 0.35 * sin(PI * t)
			p.face = "face_surprised"
		"sad":
			p.body = "body_sad"; p.wing = "_sad"; p.face = "face_sad"
			p.sy = 1.0 - 0.03 * sin(TAU * t); p.sx = 1.0 + 0.02 * sin(TAU * t)
			p.tear = t
		"win":
			p.dy = -22.0 * sin(PI * t)
			if t < 0.15 or t > 0.9: p.sy = 0.88; p.sx = 1.1
			p.wing_s = 1.0 - 0.3 * absf(sin(TAU * 2.0 * t))
			p.face = "face_happy" if t < 0.5 else "face_heart"
	return p

func _compose(p: Dictionary) -> Image:
	var m := Image.create(BASE.x, BASE.y, false, Image.FORMAT_RGBA8)
	_blend_wing(m, _parts["wing_l" + p.wing], WING_PIVOT_L, p.wing_s)
	_blend_wing(m, _parts["wing_r" + p.wing], WING_PIVOT_R, p.wing_s)
	for name in ["leg_l", "leg_r", p.body, p.face]:
		var src: Image = _parts[name]
		m.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)
	var w := maxi(1, int(BASE.x * p.sc * p.sx)); var h := maxi(1, int(BASE.y * p.sc * p.sy))
	m.resize(w, h, Image.INTERPOLATE_BILINEAR)
	if p.tint > 0.0: _tint(m, p.tint)
	var out := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	var sh: Image = _parts["shadow"].duplicate()
	var hop := 1.0 + p.dy / 44.0
	sh.resize(maxi(1, int(sh.get_width() * p.sc * hop)), maxi(1, int(sh.get_height() * p.sc * hop)))
	out.blend_rect(sh, Rect2i(Vector2i.ZERO, sh.get_size()), Vector2i((FRAME - sh.get_width()) / 2, GROUND - sh.get_height() + 6))
	var at := Vector2i(int((FRAME - w) / 2.0 + p.dx), int(GROUND - h + p.dy))
	out.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), at)
	if p.tear >= 0.0:
		var tear: Image = _parts["tear"]
		out.blend_rect(tear, Rect2i(Vector2i.ZERO, tear.get_size()), at + Vector2i(int(w * 0.40), int(h * 0.62 + 18.0 * p.tear)))
	return out

func _blend_wing(dst: Image, wing: Image, pivot: float, ws: float) -> void:
	var img := wing.duplicate()
	var w := maxi(1, int(img.get_width() * ws))
	img.resize(w, img.get_height(), Image.INTERPOLATE_BILINEAR)
	var px := BASE.x * pivot
	dst.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(px - px * ws), 0))

func _tint(img: Image, k: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0: img.set_pixel(x, y, Color(lerpf(c.r, 1.0, k), lerpf(c.g, 0.2, k), lerpf(c.b, 0.2, k), c.a))

func _check() -> int:
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT_JSON))
	var img := Image.load_from_file(ProjectSettings.globalize_path(OUT_PNG))
	if meta == null or img == null: printerr("atlas missing"); return 1
	for a in ANIMS:
		var info: Dictionary = meta.anims.get(a[0], {})
		if info.get("frames", []).size() != a[1]: printerr("bad count ", a[0]); return 1
		for fr in info.frames:
			if fr[0] + FRAME > img.get_width() or fr[1] + FRAME > img.get_height(): printerr("out of bounds ", a[0]); return 1
	print("MASCOT_ATLAS_CHECK_PASS")
	return 0
```

- [ ] **Step 2: Chạy check khi chưa có atlas — phải fail**

Run: `<godot> --headless --path game --script res://tools/build_mascot_atlas.gd -- --check`
Expected: in `atlas missing`, exit 1.

- [ ] **Step 3: Sinh atlas**

Run: `<godot> --headless --path game --script res://tools/build_mascot_atlas.gd`
Expected: `MASCOT_ATLAS_BUILT (1300, 1170) frames=82`.

- [ ] **Step 4: Import + đặt nén VRAM**

Run: `<godot> --headless --path game --import`
Sau đó trong `game/assets/candy/anim/mascot_atlas.png.import` đặt `compress/mode=2` và `mipmaps/generate=false`, rồi chạy lại `--import`.

- [ ] **Step 5: Check + soi ảnh**

Run: `<godot> --headless --path game --script res://tools/build_mascot_atlas.gd -- --check`
Expected: `MASCOT_ATLAS_CHECK_PASS`. Mở `mascot_atlas.png` bằng Read để soi: linh vật nằm trọn trong khung, mặt đổi đúng anim, có nước mắt ở hàng `sad`. Chỉnh hằng số `GROUND`/`BASE`/vị trí tear nếu lệch, rồi build lại.

- [ ] **Step 6: Commit**

```bash
git add game/tools/build_mascot_atlas.gd game/assets/candy/anim/
git commit -m "feat(assets): add mascot sprite atlas generator and atlas"
```

---

### Task 2: CandyAnimState — state per-cell thuần

**Files:**
- Create: `game/scripts/screens/candy_anim_state.gd`
- Test: `game/tests/test_candy_anim_state.gd`

**Interfaces:**
- Consumes: meta dạng `{anim: {"fps": int, "loop": bool, "count": int}}` (Task 3 tạo từ JSON).
- Produces:
  - `func _init(meta: Dictionary)`
  - `var motion: bool = true`, `var idle_min := 4.0`, `var idle_max := 7.0`
  - `func rest(cell: Vector2i) -> void`
  - `func play(cell: Vector2i, anim: String, delay: float = 0.0) -> void`
  - `func play_all(anim: String, row_delay: float = 0.0) -> void`
  - `func clear() -> void`
  - `func frame_of(cell: Vector2i) -> Array` → `[anim: String, frame: int]` (ô lạ → `["idle", 0]`)
  - `func advance(delta: float, active: bool) -> bool` (true nếu có ô đổi khung)
  - `func idle_playing_count() -> int`

- [ ] **Step 1: Viết test fail**

```gdscript
# game/tests/test_candy_anim_state.gd
extends SceneTree

const CandyAnimState = preload("res://scripts/screens/candy_anim_state.gd")

var _fails: Array[String] = []
const META := {
	"appear": {"fps": 10, "loop": false, "count": 4},
	"idle": {"fps": 10, "loop": false, "count": 4},
	"error": {"fps": 10, "loop": false, "count": 4},
	"sad": {"fps": 10, "loop": true, "count": 4},
	"win": {"fps": 10, "loop": false, "count": 4},
}

func _init() -> void:
	_test_appear_then_rest()
	_test_no_change_returns_false()
	_test_idle_triggers_within_window()
	_test_idle_cap()
	_test_error_all_once()
	_test_sad_loops_and_overrides_error()
	_test_win_holds_last_and_staggers()
	_test_motion_off()
	if _fails.is_empty():
		print("CANDY_ANIM_STATE_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_appear_then_rest() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.frame_of(c) == ["appear", 0], "appear starts at frame 0")
	_assert(s.advance(0.15, true), "advance reports frame change")
	_assert(s.frame_of(c) == ["appear", 1], "appear frame 1 after 0.15s")
	s.advance(0.5, true)
	_assert(s.frame_of(c) == ["idle", 0], "appear finishes into idle rest")

func _test_no_change_returns_false() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(1, 1))
	_assert(not s.advance(0.01, true), "resting cell does not request redraw")

func _test_idle_triggers_within_window() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(2, 3)
	s.rest(c)
	var elapsed := 0.0
	while elapsed < 3.9:
		s.advance(0.1, true); elapsed += 0.1
	_assert(s.idle_playing_count() == 0, "idle not before 4s")
	var played := false
	while elapsed < 7.5:
		s.advance(0.05, true); elapsed += 0.05
		if s.frame_of(c)[1] > 0: played = true
	_assert(played, "idle plays within 4-7s window")

func _test_idle_cap() -> void:
	var s := CandyAnimState.new(META)
	s.idle_min = 0.1; s.idle_max = 0.1
	for r in 12:
		for c in 12: s.rest(Vector2i(r, c))
	var peak := 0
	for i in 40:
		s.advance(0.05, true); peak = maxi(peak, s.idle_playing_count())
	_assert(peak == CandyAnimState.MAX_CONCURRENT_IDLE, "idle capped at MAX_CONCURRENT_IDLE (peak=%d)" % peak)

func _test_error_all_once() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(0, 0)); s.rest(Vector2i(1, 2))
	s.play_all("error")
	_assert(s.frame_of(Vector2i(1, 2))[0] == "error", "play_all applies to every cell")
	s.advance(0.5, true)
	_assert(s.frame_of(Vector2i(1, 2)) == ["idle", 0], "error plays once then rests")

func _test_sad_loops_and_overrides_error() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.rest(c)
	s.play_all("error")
	s.play_all("sad")
	s.advance(2.05, true)
	_assert(s.frame_of(c)[0] == "sad", "sad keeps looping and overrides error")
	_assert(s.idle_playing_count() == 0, "sad cells never start idle")

func _test_win_holds_last_and_staggers() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(0, 0)); s.rest(Vector2i(3, 0))
	s.play_all("win", 0.1)
	s.advance(0.15, true)
	_assert(s.frame_of(Vector2i(0, 0))[1] > 0, "row 0 starts immediately")
	_assert(s.frame_of(Vector2i(3, 0)) == ["win", 0], "row 3 waits for stagger")
	for i in 40: s.advance(0.05, true)
	_assert(s.frame_of(Vector2i(3, 0)) == ["win", 3], "win holds last frame")
	_assert(not s.advance(1.0, true), "finished win does not redraw")

func _test_motion_off() -> void:
	var s := CandyAnimState.new(META)
	s.motion = false
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.frame_of(c) == ["idle", 0], "no motion: appear goes straight to rest")
	s.play_all("win")
	_assert(s.frame_of(c) == ["win", 3], "no motion: win shows final pose")
	_assert(not s.advance(1.0, false), "inactive advance never redraws")
```

- [ ] **Step 2: Chạy test — phải fail**

Run: `<godot> --headless --path game --script res://tests/test_candy_anim_state.gd`
Expected: lỗi parse/preload vì `candy_anim_state.gd` chưa tồn tại.

- [ ] **Step 3: Implement**

```gdscript
# candy_anim_state.gd — Pure per-cell animation state for board candies (no nodes).
extends RefCounted

const MAX_CONCURRENT_IDLE := 6

var motion: bool = true
var idle_min := 4.0
var idle_max := 7.0
var _meta: Dictionary
var _cells: Dictionary = {} # Vector2i -> {anim, t, playing, wait, done, cycle}

func _init(meta: Dictionary) -> void:
	_meta = meta

func clear() -> void:
	_cells.clear()

func rest(cell: Vector2i) -> void:
	var cycle: int = _cells[cell].cycle + 1 if _cells.has(cell) else 0
	_cells[cell] = {"anim": "idle", "t": 0.0, "playing": false, "wait": _idle_wait(cell, cycle), "done": false, "cycle": cycle}

func play(cell: Vector2i, anim: String, delay: float = 0.0) -> void:
	if not _meta.has(anim): return
	if not motion:
		if anim == "appear" or anim == "error": rest(cell)
		else: _cells[cell] = {"anim": anim, "t": 0.0, "playing": false, "wait": 0.0, "done": anim == "win", "cycle": 0}
		return
	_cells[cell] = {"anim": anim, "t": 0.0, "playing": delay <= 0.0, "wait": delay, "done": false, "cycle": 0}

func play_all(anim: String, row_delay: float = 0.0) -> void:
	for cell in _cells.keys():
		play(cell, anim, cell.x * row_delay)

func frame_of(cell: Vector2i) -> Array:
	if not _cells.has(cell): return ["idle", 0]
	var e: Dictionary = _cells[cell]
	return [e.anim, _frame(e)]

func idle_playing_count() -> int:
	var n := 0
	for e in _cells.values():
		if e.anim == "idle" and e.playing: n += 1
	return n

func advance(delta: float, active: bool) -> bool:
	if not active or not motion or _cells.is_empty(): return false
	var changed := false
	var idle_slots := MAX_CONCURRENT_IDLE - idle_playing_count()
	for cell in _cells.keys():
		var e: Dictionary = _cells[cell]
		var before := _frame(e)
		if not e.playing:
			if e.done or e.anim == "sad": continue
			e.wait -= delta
			if e.wait > 0.0: continue
			if e.anim == "idle":
				if idle_slots <= 0: continue
				idle_slots -= 1
			e.playing = true; e.t = 0.0
			changed = changed or _frame(e) != before
			continue
		e.t += delta
		var info: Dictionary = _meta[e.anim]
		if not info.loop and e.t * info.fps >= info.count:
			if e.anim == "win":
				e.playing = false; e.done = true
			else:
				rest(cell); changed = true; continue
		if _frame(e) != before: changed = true
	return changed

func _frame(e: Dictionary) -> int:
	var info: Dictionary = _meta[e.anim]
	if not e.playing: return info.count - 1 if e.done else 0
	var f := int(e.t * info.fps)
	return f % info.count if info.loop else mini(f, info.count - 1)

func _idle_wait(cell: Vector2i, cycle: int) -> float:
	var h := posmod(cell.x * 7919 + cell.y * 104729 + cycle * 1299709, 1000)
	return idle_min + (idle_max - idle_min) * float(h) / 1000.0
```

Lưu ý: `sad` khi `motion=false` được tạo với `playing=false`, `done=false` → `_frame` trả 0 (tư thế buồn tĩnh) và `advance` bỏ qua.

- [ ] **Step 4: Chạy test — phải pass**

Run: `<godot> --headless --path game --script res://tests/test_candy_anim_state.gd`
Expected: `CANDY_ANIM_STATE_PASS`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/candy_anim_state.gd game/tests/test_candy_anim_state.gd
git commit -m "feat(screens): add per-cell candy animation state"
```

---

### Task 3: CandyAtlas — load + cache atlas

**Files:**
- Create: `game/scripts/screens/candy_atlas.gd`
- Test: `game/tests/test_candy_atlas.gd`

**Interfaces:**
- Consumes: atlas PNG/JSON từ Task 1.
- Produces:
  - `static func ensure_loaded(png_path := PNG_PATH, json_path := JSON_PATH) -> bool`
  - `static func texture() -> Texture2D`
  - `static func meta() -> Dictionary` → `{anim: {"fps", "loop", "count"}}` (dùng cho `CandyAnimState.new`)
  - `static func frame_rect(anim: String, frame: int) -> Rect2` (anim/frame lạ → `Rect2()`)
  - `static func reset() -> void` (test only)

- [ ] **Step 1: Viết test fail**

```gdscript
# game/tests/test_candy_atlas.gd
extends SceneTree

const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_loads_real_atlas()
	_test_bad_json()
	if _fails.is_empty():
		print("CANDY_ATLAS_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_loads_real_atlas() -> void:
	CandyAtlas.reset()
	_assert(CandyAtlas.ensure_loaded(), "mascot atlas loads")
	var meta := CandyAtlas.meta()
	var expected := {"appear": 12, "idle": 18, "error": 16, "sad": 16, "win": 20}
	for anim in expected:
		_assert(meta.has(anim) and meta[anim].count == expected[anim], "anim %s has %d frames" % [anim, expected[anim]])
	var size := CandyAtlas.texture().get_size()
	for anim in expected:
		for i in expected[anim]:
			var r := CandyAtlas.frame_rect(anim, i)
			_assert(r.size == Vector2(128, 128) and r.end.x <= size.x and r.end.y <= size.y, "%s[%d] inside texture" % [anim, i])
	_assert(CandyAtlas.frame_rect("nope", 0) == Rect2(), "unknown anim -> empty rect")
	_assert(CandyAtlas.frame_rect("idle", 99) == Rect2(), "frame out of range -> empty rect")

func _test_bad_json() -> void:
	CandyAtlas.reset()
	_assert(not CandyAtlas.ensure_loaded("res://assets/candy/anim/mascot_atlas.png", "res://missing.json"), "missing json -> false")
	CandyAtlas.reset()
```

- [ ] **Step 2: Chạy test — phải fail**

Run: `<godot> --headless --path game --script res://tests/test_candy_atlas.gd`
Expected: lỗi preload `candy_atlas.gd`.

- [ ] **Step 3: Implement**

```gdscript
# candy_atlas.gd — Loads and caches the mascot sprite atlas and its frame metadata.
extends RefCounted

const PNG_PATH := "res://assets/candy/anim/mascot_atlas.png"
const JSON_PATH := "res://assets/candy/anim/mascot_atlas.json"

static var _tex: Texture2D = null
static var _meta: Dictionary = {}
static var _frames: Dictionary = {}
static var _size := Vector2(128, 128)
static var _tried := false

static func reset() -> void:
	_tex = null; _meta = {}; _frames = {}; _tried = false

static func ensure_loaded(png_path := PNG_PATH, json_path := JSON_PATH) -> bool:
	if _tried: return _tex != null
	_tried = true
	if not ResourceLoader.exists(png_path) or not FileAccess.file_exists(json_path): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not data is Dictionary or not data.get("anims") is Dictionary: return false
	var fs: Array = data.get("frame_size", [128, 128])
	_size = Vector2(fs[0], fs[1])
	for anim in data.anims:
		var info: Dictionary = data.anims[anim]
		_frames[anim] = info.get("frames", [])
		_meta[anim] = {"fps": int(info.get("fps", 12)), "loop": bool(info.get("loop", false)), "count": _frames[anim].size()}
	_tex = load(png_path) as Texture2D
	if _tex == null: _meta = {}; _frames = {}
	return _tex != null

static func texture() -> Texture2D: return _tex
static func meta() -> Dictionary: return _meta

static func frame_rect(anim: String, frame: int) -> Rect2:
	var list: Array = _frames.get(anim, [])
	if frame < 0 or frame >= list.size(): return Rect2()
	return Rect2(Vector2(list[frame][0], list[frame][1]), _size)
```

- [ ] **Step 4: Chạy test — phải pass**

Run: `<godot> --headless --path game --script res://tests/test_candy_atlas.gd`
Expected: `CANDY_ATLAS_PASS`.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/screens/candy_atlas.gd game/tests/test_candy_atlas.gd
git commit -m "feat(screens): add cached mascot atlas loader"
```

---

### Task 4: Gắn animation vào board

**Files:**
- Create: `game/scripts/screens/candy_cell_drawer.gd`
- Modify: `game/scripts/screens/puzzle_board.gd` (khai báo var ~dòng 33, `configure` 51-70, `play_*` 103-105, `_process` 148, `_draw_cell_candy`/`_draw_candy_procedural` 263-279)
- Modify: `game/scripts/screens/puzzle_board_painter.gd:174` (truyền `r, c`)
- Test: `game/tests/test_board_candy_anim.gd`

**Interfaces:**
- Consumes: `CandyAtlas.ensure_loaded/meta/texture/frame_rect`, `CandyAnimState` API (Task 2–3).
- Produces: `PuzzleBoard.play_sad() -> void`, `PuzzleBoard.candy_frame(row: int, col: int) -> Array`, `CandyAnimState.sync(board: Array) -> void`.

- [ ] **Step 1: Viết test fail**

```gdscript
# game/tests/test_board_candy_anim.gd
extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _level() -> Dictionary:
	return {"id": "T04", "size": 4, "regions": ["AABB", "AABB", "CCDD", "CCDD"], "solution": [1, 3, 0, 2], "givens": [{"r": 0, "c": 1}]}

func _run() -> void:
	LayoutTokens.motion_enabled = true
	var board := PuzzleBoard.new()
	board.size = Vector2(400, 400)
	root.add_child(board)
	board.configure(PlaySession.new(_level()))
	await process_frame
	_assert(board.candy_frame(0, 1) == ["idle", 0], "given candy synced at idle rest without appear")
	board.play_candy_pop(1, 3)
	_assert(board.candy_frame(1, 3)[0] == "appear", "placed candy plays appear")
	board.play_sad()
	_assert(board.candy_frame(0, 1)[0] == "sad", "fail makes every candy sad")
	board.configure(PlaySession.new(_level()))
	_assert(board.candy_frame(0, 1) == ["idle", 0], "reconfigure resets to idle")
	if _fails.is_empty():
		print("BOARD_CANDY_ANIM_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)
```

- [ ] **Step 2: Chạy test — phải fail**

Run: `<godot> --headless --path game --script res://tests/test_board_candy_anim.gd`
Expected: lỗi `candy_frame` / `play_sad` không tồn tại.

- [ ] **Step 3: Thêm `sync` vào `CandyAnimState`** (sau `clear()`)

```gdscript
func sync(board: Array) -> void:
	_cells.clear()
	for r in board.size():
		for c in board[r].size():
			var k: int = int(board[r][c])
			if k == 2 or k == 4: rest(Vector2i(r, c)) # CellKind.CANDY / GIVEN
```

Và thêm test vào `test_candy_anim_state.gd` (thêm dòng `_test_sync_rests_placed_cells()` vào `_init`):

```gdscript
func _test_sync_rests_placed_cells() -> void:
	var s := CandyAnimState.new(META)
	s.sync([[0, 2], [4, 3]])
	_assert(s.frame_of(Vector2i(0, 1)) == ["idle", 0] and s.frame_of(Vector2i(1, 0)) == ["idle", 0], "sync rests candy+given")
	_assert(not s._cells.has(Vector2i(1, 1)), "sync skips ERROR cells")
```

- [ ] **Step 4: Tạo `candy_cell_drawer.gd`** (chuyển nguyên logic vẽ kẹo khỏi board)

```gdscript
# candy_cell_drawer.gd — Draws one board candy: animated mascot frame, static texture, or procedural fallback.
extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const CandyPalette = preload("res://scripts/theme/candy_palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")

static func draw(canvas: CanvasItem, rect: Rect2, is_given: bool, cs: float, static_tex: Texture2D, frame: Array) -> void:
	if is_given:
		canvas.draw_circle(rect.get_center(), rect.size.x * minf(LayoutTokens.GIVEN_HALO_RATIO * cs, 0.48), Color(CandyPalette.GIVEN_HALO, CandyPalette.GIVEN_HALO_OPACITY))
	var candy_size := rect.size * minf(LayoutTokens.CANDY_TEX_RATIO * cs, 0.95)
	var dst := Rect2(rect.position + (rect.size - candy_size) * 0.5, candy_size)
	var src := CandyAtlas.frame_rect(frame[0], frame[1]) if not frame.is_empty() else Rect2()
	if src.size.x > 0.0:
		canvas.draw_texture_rect_region(CandyAtlas.texture(), dst, src)
	elif static_tex != null:
		canvas.draw_texture_rect(static_tex, dst, false)
	else:
		_draw_procedural(canvas, rect)

static func _draw_procedural(canvas: CanvasItem, rect: Rect2) -> void:
	var center := rect.get_center(); var radius := rect.size.x * 0.25
	for dir in [-1.0, 1.0]:
		var poly := PackedVector2Array([center + Vector2(dir * radius * 0.65, 0), center + Vector2(dir * radius * 1.6, -radius * 0.65), center + Vector2(dir * radius * 1.6, radius * 0.65)])
		canvas.draw_colored_polygon(poly, Palette.CANDY_LIGHT); canvas.draw_polyline(poly, Palette.CANDY_OUTLINE, 2.0, true)
	canvas.draw_circle(center, radius, Palette.CANDY_BROWN)
	canvas.draw_arc(center, radius * 0.60, -PI * 0.8, PI * 0.25, 18, Palette.CANDY_LIGHT, radius * 0.22, true)
```

Trước khi viết, kiểm tra `puzzle_board.gd` preload `CandyPalette` từ đường dẫn nào và dùng đúng đường dẫn đó.

- [ ] **Step 5: Sửa `puzzle_board.gd`**

Thêm preload cạnh các preload hiện có:

```gdscript
const CandyAtlas = preload("res://scripts/screens/candy_atlas.gd")
const CandyAnimState = preload("res://scripts/screens/candy_anim_state.gd")
const CandyCellDrawer = preload("res://scripts/screens/candy_cell_drawer.gd")
```

Thêm var sau `var _candy_tex`:

```gdscript
var _candy_anim: Variant = null
```

Trong `configure`, ngay sau dòng gán `_candy_tex`:

```gdscript
	_candy_anim = CandyAnimState.new(CandyAtlas.meta()) if CandyAtlas.ensure_loaded() else null
	if _candy_anim != null: _candy_anim.motion = LayoutTokens.motion_enabled; _candy_anim.sync(_session.board)
```

Thay 3 dòng `play_*` (103-105):

```gdscript
func play_candy_pop(row: int, col: int) -> void:
	if _candy_anim != null: _candy_anim.play(Vector2i(row, col), "appear"); queue_redraw()
	else: CellAnimator.play_candy_pop(self, _cell_rect(row, col))
	candy_placed_anim.emit(row, col)
func play_error_shake() -> void: CellAnimator.play_error_shake(self); if _candy_anim != null: _candy_anim.play_all("error"); error_anim.emit(0, 0)
func play_win_bounce() -> void:
	if _candy_anim != null: _candy_anim.play_all("win", 0.04); queue_redraw()
	else: CellAnimator.play_win_bounce(self, _session, _cell_rect)
	win_anim.emit()
func play_sad() -> void: if _candy_anim != null: _candy_anim.play_all("sad"); queue_redraw()
func candy_frame(row: int, col: int) -> Array: return _candy_anim.frame_of(Vector2i(row, col)) if _candy_anim != null else []
```

Lưu ý GDScript: `if ...: a; b` trên một dòng thì `b` cũng thuộc `if`. Ở `play_error_shake`, viết tách dòng để `error_anim.emit` luôn chạy:

```gdscript
func play_error_shake() -> void:
	CellAnimator.play_error_shake(self)
	if _candy_anim != null: _candy_anim.play_all("error")
	error_anim.emit(0, 0)
```

Đầu `_process`:

```gdscript
	if _candy_anim != null and _candy_anim.advance(_delta, LayoutTokens.motion_enabled and is_visible_in_tree()): queue_redraw()
```

Thay toàn bộ `_draw_cell_candy` và `_draw_candy_procedural` (263-279) bằng:

```gdscript
func _draw_cell_candy(rect: Rect2, is_given: bool, r: int = -1, c: int = -1) -> void:
	CandyCellDrawer.draw(self, rect, is_given, _content_scale(), _candy_tex, candy_frame(r, c) if r >= 0 else [])
```

Xóa các preload trong board chỉ còn được dùng bởi code vừa chuyển đi (nếu có).

- [ ] **Step 6: Sửa painter** — `puzzle_board_painter.gd:174`:

```gdscript
				board._draw_cell_candy(cell_rect, k == CellModel.CellKind.GIVEN, r, c)
```

Grep các chỗ gọi `_draw_cell_candy` / `_draw_candy_procedural` khác (`rtk proxy rg -n "_draw_cell_candy|_draw_candy_procedural" game/`) và cập nhật cho khớp.

- [ ] **Step 7: Chạy test mới + suite liên quan**

Run:
```
<godot> --headless --path game --script res://tests/test_board_candy_anim.gd
<godot> --headless --path game --script res://tests/test_candy_anim_state.gd
<godot> --headless --path game --script res://tests/test_cell_animator.gd
<godot> --headless --path game --script res://tests/test_screens.gd
<godot> --headless --path game --script res://tests/test_integration.gd
```
Expected: tất cả PASS. Kiểm `(Get-Content game\scripts\screens\puzzle_board.gd).Count` ≤ 300.

- [ ] **Step 8: Commit**

```bash
git add game/scripts/screens/candy_cell_drawer.gd game/scripts/screens/candy_anim_state.gd game/scripts/screens/puzzle_board.gd game/scripts/screens/puzzle_board_painter.gd game/tests/test_board_candy_anim.gd game/tests/test_candy_anim_state.gd
git commit -m "feat(screens): animate board candies with mascot sprite atlas"
```

---

### Task 5: Trigger thua → sad, gate cuối

**Files:**
- Modify: `game/scripts/screens/puzzle_screen.gd` (`_on_level_failed`, ~dòng 258)
- Test: `game/tests/test_board_candy_anim.gd` (thêm case qua screen nếu `test_integration.gd` đã có harness dựng `PuzzleScreen`; nếu không, giữ test board ở Task 4)

**Interfaces:**
- Consumes: `PuzzleBoard.play_sad()` (Task 4).

- [ ] **Step 1: Viết test fail** — tìm harness dựng `PuzzleScreen` trong `game/tests/test_integration.gd` (`rtk proxy rg -n "PuzzleScreen|level_failed" game/tests/`). Thêm case: làm session thua (gây đủ lỗi để `level_failed` phát) rồi assert `screen.board.candy_frame(r, c)[0] == "sad"` cho một ô given.

- [ ] **Step 2: Chạy — phải fail** (frame vẫn là `error`/`idle`).

- [ ] **Step 3: Implement** — dòng đầu tiên của `_on_level_failed`:

```gdscript
	if board != null: board.play_sad()
```

- [ ] **Step 4: Chạy suite liên quan — phải pass**

Run: `<godot> --headless --path game --script res://tests/test_integration.gd`

- [ ] **Step 5: Full gate (AGENTS.md §3)**

```
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
rtk proxy rg -n "extracted_reusable" game/scripts/ game/tests/ game/tools/
rtk python -B tools/verify.py --godot <godot>
```
Expected: 2 lệnh rg không có match; verify pass.

- [ ] **Step 6: Commit + ghi STATUS**

Thêm một dòng vào `docs/STATUS.md` (mục tiến độ Track D/assets): "Mascot sprite animation trên board (appear/idle/error/sad/win) — headless pass, chưa QA thiết bị."

```bash
git add game/scripts/screens/puzzle_screen.gd game/tests/ docs/STATUS.md
git commit -m "feat(screens): show crying mascots when the level is lost"
```

- [ ] **Step 7: QA thủ công** — chạy game, kiểm 4×4 và một level lớn nhất có sẵn: kẹo nảy khi đặt, chớp mắt lệch nhịp, rung đỏ khi sai, khóc khi thua, nhảy lần lượt khi thắng; bật reduced motion → đứng yên.
