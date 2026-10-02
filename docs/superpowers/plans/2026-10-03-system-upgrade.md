# System Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp CanDoKu với 7 modules mới tham khảo hành vi Meowdoku: canonical dedup, DDA, advanced solver, colorblind, puzzle snapshot, bank encryption, và bank mở rộng 5×5/6×6.

**Architecture:** 7 modules triển khai theo 5 phase, mỗi phase merge vào `dev` trước khi bắt đầu phase tiếp. Modules chỉ dùng Godot signals và dependency injection (không autoloads, không EventBus). Tất cả pure logic là static functions trên RefCounted, testable headless.

**Tech Stack:** Godot 4.x / GDScript, Python 3.10+ (build tools), SHA-256 (Godot HashingContext), CIELAB color math.

**Spec:** `docs/superpowers/specs/2026-10-03-system-upgrade-design.md`

## Global Constraints

- **Bản quyền:** Tham khảo hành vi từ `extracted_reusable/`, KHÔNG sao chép code/tên/enum. Tất cả tên phải nguyên gốc.
- **Clean-room gate mỗi commit:**
  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
  ```
  Expected: 0 matches.
- **Module ≤ 300 dòng.** Một file, một trách nhiệm.
- **Không autoloads.** Signals thay EventBus. Composition root via app_shell.
- **Phạm vi:** R1, N=4–6, S1–S3 (mở rộng đến S7 cho solver). Không mở R2–R4, Endless, IAP.
- **Test runner pattern:** `extends SceneTree`, `_init()` chạy test, `print("PASS_TOKEN")` hoặc `quit(1)`.
- **Headless test:** `godot --headless --path game --script res://tests/test_<name>.gd`
- **Full gate:** `python -B tools/verify.py --godot <executable>`
- **Commit message format:** Conventional Commits + `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`

## Dependency Graph — Parallelization Map

```
Phase 1 (sequential chain):
  Task 1 ──→ Task 2 ──→ Task 3 ──→ Task 4

Phase 2 (partial parallel):
  Task 5 ──→ Task 6     (sequential — Task 6 builds on Task 5's code)
  Task 7                 (PARALLEL with Tasks 5+6 — different files entirely)

Phase 3 (partial parallel):
  Task 8 ──→ Task 9     (sequential — Task 9 integrates Task 8)
  Task 10                (PARALLEL with Tasks 8+9 — Python tools + data only)

Phase 4:
  Task 11                (independent)

Phase 5:
  Task 12                (verification only — runs after all above)
```

**Agents can run in parallel:**
- Tasks 5+6 and Task 7 (Phase 2)
- Tasks 8+9 and Task 10 (Phase 3)

## Review Focus

1. **Empty bank rank lookup:** `bank_reader.get_level(size, rank+offset, index)` khi DDA offset dẫn tới rank không tồn tại trong bank — phải fallback rank gần nhất, không crash. Test trong Task 9 step 3.
2. **Session v3 backward compat:** `session_store.load_session()` với data thiếu `snapshot` field — phải fallback fetch từ bank, không reject session. Test trong Task 3 step 1.
3. **D4 transform + remap label determinism:** Hai region maps chỉ khác thứ tự label (ví dụ `"AABB"` vs label-swapped variant) — fingerprint phải bằng nhau. Test trong Task 1 step 1.
4. **Locked subsets k=2 false positive:** Hai zones có candidates trên đúng 2 rows NHƯNG không exclusive (zones khác cũng có candidate trên cùng rows) — không được eliminate. Test trong Task 5 step 1.
5. **Colorblind overlay on adjacent dark zones:** Hai dark zones kề nhau không được nhận cùng overlay icon. Test trong Task 7 step 1.

---

## Phase 1 — Nền tảng dữ liệu

### Task 1: Shape Fingerprint (`shape_fingerprint.gd`)

**Prerequisite:** None (first task)
**Branch:** `feat/shape-fingerprint`
**Files:**
- Create: `game/scripts/content/shape_fingerprint.gd`
- Create: `game/tests/test_shape_fingerprint.gd`

**Interfaces:**
- Consumes: `BoardTransform.transform_regions(regions: Array, n: int, t: int) -> Array` from `game/scripts/content/board_transform.gd:51`; `BoardTransform.TRANSFORM_COUNT` = 8 from `game/scripts/content/board_transform.gd:15`
- Produces: `ShapeFingerprint.compute(size: int, regions: Array) -> String` — returns `"4x4_<hex16>"` canonical ID

**Algorithm:**
1. Cho mỗi t trong 0..7 (D4 group): transform regions, remap labels scan-order (ô đầu tiên→"A", ô mới→"B"...), serialize bằng `"|".join()`
2. Chọn lexicographic min trong 8 serialized strings
3. SHA-256 hash → lấy 16 hex đầu → format `"{size}x{size}_{hex16}"`

- [ ] **Step 1: Create test file `game/tests/test_shape_fingerprint.gd`**

  Write this exact file:
  ```gdscript
  extends SceneTree

  const ShapeFingerprint = preload("res://scripts/content/shape_fingerprint.gd")
  const BoardTransform = preload("res://scripts/content/board_transform.gd")

  var _fails: Array[String] = []

  func _init() -> void:
  	_test_identity_fingerprint()
  	_test_d4_variants_same_fingerprint()
  	_test_different_topology_different_fingerprint()
  	_test_label_swap_same_fingerprint()
  	_test_format()
  	_test_5x5()
  	if _fails.is_empty():
  		print("SHAPE_FINGERPRINT_PASS")
  		quit(0)
  	else:
  		for f in _fails:
  			printerr(f)
  		quit(1)

  func _test_identity_fingerprint() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var fp := ShapeFingerprint.compute(4, regions)
  	_assert(fp.length() > 0, "fingerprint not empty")
  	var fp2 := ShapeFingerprint.compute(4, regions)
  	_assert(fp == fp2, "same input same fingerprint")

  func _test_d4_variants_same_fingerprint() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var base_fp := ShapeFingerprint.compute(4, regions)
  	for t in range(1, 8):
  		var transformed := BoardTransform.transform_regions(regions, 4, t)
  		var fp := ShapeFingerprint.compute(4, transformed)
  		_assert(fp == base_fp, "D4 variant t=%d must match base fingerprint" % t)

  func _test_different_topology_different_fingerprint() -> void:
  	var r1 := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var r2 := ["ABBC", "ABBC", "ADDC", "ADDC"]
  	_assert(ShapeFingerprint.compute(4, r1) != ShapeFingerprint.compute(4, r2), "different topology must differ")

  func _test_label_swap_same_fingerprint() -> void:
  	# Relabel A<->C in r1: same topology, different labels
  	var r1 := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var r_swap: Array = []
  	for row_str in r1:
  		var new_row := ""
  		for i in range(row_str.length()):
  			var ch: String = row_str[i]
  			if ch == "A":
  				new_row += "C"
  			elif ch == "C":
  				new_row += "A"
  			else:
  				new_row += ch
  		r_swap.append(new_row)
  	# r_swap = ["CCBB", "CBBB", "AABB", "AADB"] — same grid positions, labels swapped
  	_assert(ShapeFingerprint.compute(4, r1) == ShapeFingerprint.compute(4, r_swap), "label swap same fingerprint")

  func _test_format() -> void:
  	var fp := ShapeFingerprint.compute(4, ["AABB", "ABBB", "CCBB", "CCDB"])
  	_assert(fp.begins_with("4x4_"), "format starts with size prefix")
  	_assert(fp.length() == 4 + 1 + 16, "format: NxN_ + 16 hex chars = 21 total")

  func _test_5x5() -> void:
  	var r5 := ["AABBC", "ADBBC", "DDDEC", "DFEEC", "FFEEE"]
  	var fp := ShapeFingerprint.compute(5, r5)
  	_assert(fp.begins_with("5x5_"), "5x5 format")
  	_assert(fp.length() == 4 + 1 + 16, "5x5 length correct")

  func _assert(condition: bool, label: String) -> void:
  	if not condition:
  		_fails.append("FAIL: " + label)
  ```

- [ ] **Step 2: Run test — verify it fails**

  ```bash
  godot --headless --path game --script res://tests/test_shape_fingerprint.gd
  ```
  Expected: Script error — `shape_fingerprint.gd` not found. Exit code 1.

- [ ] **Step 3: Create `game/scripts/content/shape_fingerprint.gd`**

  Write this exact file:
  ```gdscript
  extends RefCounted

  const BoardTransform = preload("res://scripts/content/board_transform.gd")

  static func compute(size: int, regions: Array) -> String:
  	var smallest := ""
  	for t in range(BoardTransform.TRANSFORM_COUNT):
  		var transformed: Array = BoardTransform.transform_regions(regions, size, t)
  		var normalized := _remap_labels(transformed, size)
  		var serialized := "|".join(normalized)
  		if smallest.is_empty() or serialized < smallest:
  			smallest = serialized
  	var ctx := HashingContext.new()
  	ctx.start(HashingContext.HASH_SHA256)
  	ctx.update(smallest.to_utf8_buffer())
  	var hex := ctx.finish().hex_encode()
  	return "%dx%d_%s" % [size, size, hex.substr(0, 16)]

  static func _remap_labels(regions: Array, size: int) -> Array[String]:
  	var mapping: Dictionary = {}
  	var next_id: int = 0
  	var result: Array[String] = []
  	for r in range(size):
  		var row_str := str(regions[r])
  		var new_row := ""
  		for c in range(size):
  			var ch: String = row_str[c] if c < row_str.length() else ""
  			if not mapping.has(ch):
  				mapping[ch] = String.chr(65 + next_id)
  				next_id += 1
  			new_row += mapping[ch]
  		result.append(new_row)
  	return result
  ```

- [ ] **Step 4: Run test — verify it passes**

  ```bash
  godot --headless --path game --script res://tests/test_shape_fingerprint.gd
  ```
  Expected: `SHAPE_FINGERPRINT_PASS`, exit code 0.

- [ ] **Step 5: Run existing tests — no regressions**

  ```bash
  godot --headless --path game --script res://tests/test_board_solver.gd
  ```
  Expected: `CORE_BOARD_SOLVER_PASS`. (Shape fingerprint is independent, should not break anything.)

- [ ] **Step 6: Clean-room gate**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/content/shape_fingerprint.gd game/tests/test_shape_fingerprint.gd
  ```
  Expected: 0 matches.

- [ ] **Step 7: Commit**

  ```bash
  git add game/scripts/content/shape_fingerprint.gd game/tests/test_shape_fingerprint.gd
  git commit -m "$(cat <<'EOF'
  feat(content): add shape fingerprint — D4-canonical topology hash

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 2: Recent Shapes Queue in ProgressManager

**Prerequisite:** Task 1 merged
**Branch:** Same as Task 1 or continuing on same branch
**Files:**
- Modify: `game/scripts/state/progress_manager.gd` (78 lines currently)
- Modify: `game/tests/test_progress_manager.gd` (36 lines currently)

**Interfaces:**
- Consumes: `ShapeFingerprint.compute()` (for callers, not directly here)
- Produces: `ProgressManager.record_shape(shape_id: String) -> void`, `ProgressManager.has_recent_shape(shape_id: String) -> bool`

**Current state of `progress_manager.gd`:**
- Line 4: `const SCHEMA_VER := 2`
- Line 33-34: `func new_progress(first_level_id: String) -> Dictionary:` returns dict with keys: progressVersion, currentLevelId, completedLevelIds, results, tutorialSeenIds
- Line 53-58: `func puzzle_fingerprint(level: Dictionary) -> String:` — last public method before `_validate()`
- Line 60-66: `func _validate(data: Dictionary) -> bool:` — checks required keys but does NOT strip unknown keys
- Line 68-77: `func _migrate(data: Dictionary) -> Dictionary:` — handles v1→v2 migration

**Current state of `test_progress_manager.gd`:**
- Uses `check(condition, label)` pattern (not `_assert`)
- Creates dir with `OS.get_user_data_dir().path_join("m02_progress_%s" % Time.get_ticks_usec())`
- Single `_init()` runs all tests inline, prints `STATE_PROGRESS_PASS`

- [ ] **Step 1: Add failing tests to `game/tests/test_progress_manager.gd`**

  The existing test runs all tests inline in `_init()`. Add these lines BEFORE the `if failures.is_empty():` line (currently line 25):

  ```gdscript
  # --- Shape queue tests ---
  var shape_dir := OS.get_user_data_dir().path_join("m02_shapes_%s" % Time.get_ticks_usec())
  var shape_pm := Progress.new(shape_dir)
  shape_pm.current = shape_pm.new_progress("L01")
  check(not shape_pm.has_recent_shape("4x4_abc123"), "shape not found initially")
  shape_pm.record_shape("4x4_abc123")
  check(shape_pm.has_recent_shape("4x4_abc123"), "shape found after record")
  check(not shape_pm.has_recent_shape("4x4_xyz789"), "different shape not found")
  for i in range(55):
  	shape_pm.record_shape("shape_%d" % i)
  check(not shape_pm.has_recent_shape("4x4_abc123"), "original shape evicted after 55 inserts (cap 50)")
  check(shape_pm.has_recent_shape("shape_54"), "newest shape present")
  check(shape_pm.current.get("recentShapes", []).size() <= 50, "queue capped at 50")
  shape_pm._store.remove_all()
  DirAccess.remove_absolute(shape_dir)
  ```

  Use the Edit tool to insert BEFORE line 25 (`if failures.is_empty():`).

- [ ] **Step 2: Run test — verify it fails**

  ```bash
  godot --headless --path game --script res://tests/test_progress_manager.gd
  ```
  Expected: FAIL — `has_recent_shape` not a method.

- [ ] **Step 3: Add `RECENT_SHAPES_CAP` constant to `progress_manager.gd`**

  Edit `game/scripts/state/progress_manager.gd`. Insert after line 4 (`const SCHEMA_VER := 2`):
  ```gdscript
  const RECENT_SHAPES_CAP := 50
  ```

- [ ] **Step 4: Add `recentShapes` field to `new_progress()`**

  Edit line 34, replace:
  ```gdscript
  return {"progressVersion": SCHEMA_VER, "currentLevelId": first_level_id, "completedLevelIds": [], "results": {}, "tutorialSeenIds": []}
  ```
  With:
  ```gdscript
  return {"progressVersion": SCHEMA_VER, "currentLevelId": first_level_id, "completedLevelIds": [], "results": {}, "tutorialSeenIds": [], "recentShapes": []}
  ```

- [ ] **Step 5: Add `record_shape()` and `has_recent_shape()` methods**

  Insert after the `puzzle_fingerprint()` method (after line 58):
  ```gdscript

  func record_shape(shape_id: String) -> void:
  	if not current.has("recentShapes") or not current.recentShapes is Array:
  		current["recentShapes"] = []
  	current.recentShapes.append(shape_id)
  	while current.recentShapes.size() > RECENT_SHAPES_CAP:
  		current.recentShapes.pop_front()

  func has_recent_shape(shape_id: String) -> bool:
  	var shapes: Array = current.get("recentShapes", [])
  	return shapes.has(shape_id)
  ```

- [ ] **Step 6: Add migration fallback for `recentShapes`**

  In `_migrate()`, after line 76 (`return migrated`) in the v1 migration branch, add before the return:
  ```gdscript
  if not migrated.has("recentShapes"):
  	migrated["recentShapes"] = []
  ```

  Also add after line 70 (`return data`) — the v2 passthrough case:
  ```gdscript
  if not data.has("recentShapes"):
  	data["recentShapes"] = []
  ```

- [ ] **Step 7: Run test — verify it passes**

  ```bash
  godot --headless --path game --script res://tests/test_progress_manager.gd
  ```
  Expected: `STATE_PROGRESS_PASS`, exit code 0.

- [ ] **Step 8: Clean-room gate + commit**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/state/progress_manager.gd
  ```
  Expected: 0 matches.
  ```bash
  git add game/scripts/state/progress_manager.gd game/tests/test_progress_manager.gd
  git commit -m "$(cat <<'EOF'
  feat(state): add recent shapes queue to progress manager

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 3: Puzzle Snapshot Schema (session store)

**Prerequisite:** Task 2 merged
**Branch:** Same branch continuing
**Files:**
- Modify: `game/scripts/state/session_store.gd` (63 lines currently)
- Modify: `game/tests/test_session_store.gd` (36 lines currently)

**Interfaces:**
- Consumes: existing `SessionStore.save_session(data: Dictionary) -> bool`, `SessionStore.load_session(level_id, hash) -> Dictionary`
- Produces: `SessionStore` preserves `snapshot` Dictionary field through save/load cycle. No schema bump needed — `_valid_shape()` (line 44-59) validates known keys but does NOT strip unknown keys; `save_session()` (line 12-15) writes the full dict to JSON.

**Current `_valid_shape()` behavior (line 44-59):** Checks sessionVersion==3, levelId is String, puzzleHash is String, boardSize 4-6, cells array correct size, cell values in CELL_VALUES, numeric fields ≥0, status string. Does NOT iterate all keys or strip unknowns. Therefore `snapshot` as an additional Dictionary field will survive save/load as-is.

**Current test pattern (`test_session_store.gd`):** Uses `check(condition, label)` pattern. Single `_init()`. Creates store via `Session.new(dir)`. Prints `STATE_SESSION_PASS`.

- [ ] **Step 1: Add snapshot tests to `game/tests/test_session_store.gd`**

  Insert before line 24 (`if failures.is_empty():`):
  ```gdscript
  # --- Snapshot round-trip ---
  var snap_dir := OS.get_user_data_dir().path_join("m02_snap_%s" % Time.get_ticks_usec())
  var snap_store := Session.new(snap_dir)
  var snap_data := snap_store.new_session("L01", "hash_snap", 4)
  snap_data["snapshot"] = {
  	"level_id": "L01", "size": 4, "rank": 1,
  	"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
  	"solution": [1, 3, 0, 2], "givens": [],
  	"zone_colors": {"A": "#FF0000", "B": "#00FF00", "C": "#0000FF", "D": "#FFFF00"},
  	"zone_overlays": {}, "shape_hash": "4x4_abc123",
  	"transform_id": 0, "hearts_start": 3, "seed": 7,
  }
  check(snap_store.save_session(snap_data), "save with snapshot")
  var snap_loaded := snap_store.load_session("L01", "hash_snap")
  check(snap_loaded.get("ok"), "load with snapshot ok")
  check(snap_loaded.get("data", {}).has("snapshot"), "snapshot field preserved")
  check(snap_loaded.get("data", {}).get("snapshot", {}).get("level_id") == "L01", "snapshot level_id correct")
  check(snap_loaded.get("data", {}).get("snapshot", {}).get("regions", []).size() == 4, "snapshot regions correct")
  # --- Session without snapshot still loads ---
  var no_snap := snap_store.new_session("L02", "hash_no_snap", 4)
  check(snap_store.save_session(no_snap), "save without snapshot")
  var no_snap_loaded := snap_store.load_session("L02", "hash_no_snap")
  check(no_snap_loaded.get("ok"), "load without snapshot ok")
  check(not no_snap_loaded.get("data", {}).has("snapshot"), "no phantom snapshot")
  snap_store.clear()
  DirAccess.remove_absolute(snap_dir)
  ```

- [ ] **Step 2: Run test — verify behavior**

  ```bash
  godot --headless --path game --script res://tests/test_session_store.gd
  ```
  Expected outcome: These tests should PASS without any code changes because `_valid_shape()` does not strip unknown fields. If they pass, no code change needed for `session_store.gd`. If they fail, investigate `_valid_shape()` and fix.

- [ ] **Step 3: Commit**

  ```bash
  git add game/tests/test_session_store.gd
  git commit -m "$(cat <<'EOF'
  test(state): verify session snapshot field preserved through save/load

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 4: Puzzle Snapshot in CampaignRuntime

**Prerequisite:** Tasks 1, 2, 3 merged
**Branch:** Same branch continuing
**Files:**
- Modify: `game/scripts/campaign/campaign_runtime.gd` (238 lines currently)
- Modify: `game/tests/test_campaign_runtime.gd` (190 lines currently)

**Interfaces:**
- Consumes:
  - `ShapeFingerprint.compute(size: int, regions: Array) -> String` from Task 1
  - `RegionPainter.assign_colors(size, zones, palette) -> Dictionary` from `game/scripts/content/region_painter.gd:4`
  - `Palette.ZONE_COLORS` from `game/scripts/theme/palette.gd`
  - `ProgressManager.record_shape(shape_id)` from Task 2
  - `SessionStore.save_session(data)` existing
  - `PlaySession.to_save_data() -> Dictionary` from `game/scripts/input/play_session.gd:152`
- Produces:
  - `CampaignRuntime.start_level()` now creates snapshot dict in saved session
  - `CampaignRuntime.restart_level()` reuses snapshot via `_current_snapshot`
  - `CampaignRuntime.resume_level()` restores `_current_snapshot` from loaded session
  - `CampaignRuntime.on_level_won()` records shape before clearing snapshot

**Current `campaign_runtime.gd` key locations:**
- Line 1-8: Preloads (BankReader, PaceReader, BoardTransform, ProgressManager, SessionStore, PlaySession)
- Line 25: `var _pending_win: Dictionary = {}`
- Line 68-80: `func start_level(label)` — fetches level, creates PlaySession, saves session
- Line 82-94: `func resume_level()` — loads session from store
- Line 96-115: `func on_level_won(label, score_data)` — advances progress, clears session
- Line 117-125: `func on_level_lost(label)` — saves failed status
- Line 133-134: `func restart_level()` — just calls `start_level(current_level_label())`
- Line 154-163: `func current_level_data()` — resolves entry, fetches level, sets id/hash
- Line 200-204: `func _resolve_playlist_entry(label)` — finds entry in _playlist
- Line 206-210: `func _fetch_level(size, rank, index, transform)` — gets from bank + optional transform

**Current test helper in `test_campaign_runtime.gd`:**
- Line 30-33: `func _runtime(tag)` — creates CampaignRuntime with fresh dir
- Line 35-38: `func _two_entries(runtime)` — duplicates first playlist entry as L02
- Line 178-185: `func _finish_level(runtime)` — starts level, solves it by trying all candy placements
- Line 187-189: `func _check(condition, label)` — records failure

- [ ] **Step 1: Add preloads to `campaign_runtime.gd`**

  Edit `game/scripts/campaign/campaign_runtime.gd`. Insert after line 8 (`const PlaySession = preload("res://scripts/input/play_session.gd")`):
  ```gdscript
  const ShapeFingerprint = preload("res://scripts/content/shape_fingerprint.gd")
  const RegionPainter = preload("res://scripts/content/region_painter.gd")
  const Palette = preload("res://scripts/theme/palette.gd")
  ```

- [ ] **Step 2: Add `_current_snapshot` variable**

  Insert after line 25 (`var _pending_win: Dictionary = {}`):
  ```gdscript
  var _current_snapshot: Dictionary = {}
  ```

- [ ] **Step 3: Rewrite `start_level()` to build snapshot**

  Replace the entire `start_level` method (lines 68-80) with:
  ```gdscript
  func start_level(label: String) -> PlaySession:
  	if label != current_level_label() or is_campaign_done():
  		return null
  	var level: Dictionary
  	var snapshot: Dictionary
  	if not _current_snapshot.is_empty() and _current_snapshot.get("level_id") == label:
  		snapshot = _current_snapshot
  		level = _build_level_from_snapshot(snapshot)
  	else:
  		level = current_level_data()
  		if level.is_empty():
  			return null
  		var entry := _resolve_playlist_entry(label)
  		var n: int = int(level.get("size", 4))
  		var regions: Array = level.get("regions", [])
  		var colors := RegionPainter.assign_colors(n, regions, Palette.ZONE_COLORS)
  		var color_hex: Dictionary = {}
  		for zone_key in colors:
  			color_hex[zone_key] = (colors[zone_key] as Color).to_html()
  		snapshot = {
  			"level_id": label,
  			"size": n,
  			"rank": int(entry.get("rank", 1)),
  			"bank_index": int(entry.get("index", 0)),
  			"transform_id": int(entry.get("transform", 0)),
  			"regions": regions.duplicate(true),
  			"solution": level.get("solution", []).duplicate(true),
  			"givens": level.get("givens", []).duplicate(true),
  			"zone_colors": color_hex,
  			"zone_overlays": {},
  			"hearts_start": 3,
  			"seed": int(level.get("seed", 0)),
  			"shape_hash": ShapeFingerprint.compute(n, regions),
  		}
  	_current_snapshot = snapshot
  	if not level.has("id"):
  		level = current_level_data()
  		if level.is_empty():
  			return null
  	var session := PlaySession.new(level)
  	var save_data := session.to_save_data()
  	save_data["snapshot"] = snapshot.duplicate(true)
  	if not sessions.save_session(save_data):
  		save_failed.emit("session_start")
  		return null
  	current_session = session
  	level_started.emit(label)
  	return session
  ```

- [ ] **Step 4: Add `_build_level_from_snapshot()` helper**

  Insert after `_fetch_level()` method (after line 210):
  ```gdscript

  func _build_level_from_snapshot(snap: Dictionary) -> Dictionary:
  	var level := {
  		"size": snap.get("size", 4),
  		"regions": snap.get("regions", []).duplicate(true),
  		"solution": snap.get("solution", []).duplicate(true),
  		"givens": snap.get("givens", []).duplicate(true),
  		"seed": snap.get("seed", 0),
  	}
  	level["id"] = snap.get("level_id", "")
  	return level
  ```

- [ ] **Step 5: Update `resume_level()` to restore snapshot**

  Replace `resume_level()` (lines 82-94) with:
  ```gdscript
  func resume_level() -> PlaySession:
  	var level := current_level_data()
  	if level.is_empty():
  		return null
  	var saved := sessions.load_session(current_level_label(), level.hash)
  	if not saved.ok:
  		if saved.recreate:
  			sessions.clear()
  		return null
  	if saved.data.has("snapshot") and saved.data.snapshot is Dictionary:
  		_current_snapshot = saved.data.snapshot.duplicate(true)
  	current_session = PlaySession.from_save_data(saved.data, level)
  	if saved.data.get("status") == "won" and saved.data.get("pendingScoreData") is Dictionary:
  		_pending_win = {"label": current_level_label(), "score": saved.data.pendingScoreData.duplicate(true)}
  	return current_session
  ```

- [ ] **Step 6: Update `on_level_won()` — record shape and clear snapshot**

  In `on_level_won()`, insert after line 108 (`var advanced := progress.advance_level(...)`) and before `_pending_win.clear()`:
  ```gdscript
  	if not _current_snapshot.is_empty() and _current_snapshot.has("shape_hash"):
  		progress.record_shape(_current_snapshot.shape_hash)
  ```

  And after `sessions.clear()` (line 111), add:
  ```gdscript
  	_current_snapshot = {}
  ```

- [ ] **Step 7: Add snapshot tests to `test_campaign_runtime.gd`**

  Insert a new test call in `_init()` after line 23 (`_test_tutorial()`):
  ```gdscript
  	_test_snapshot_creation()
  	_test_restart_reuses_snapshot()
  ```

  Add these methods before `_cleanup()`:
  ```gdscript
  func _test_snapshot_creation() -> void:
  	var runtime := _runtime("snapshot")
  	_check(runtime.boot().ok, "snapshot boot")
  	var session := runtime.start_level("L01")
  	_check(session != null, "snapshot start level")
  	var saved := runtime.sessions._store.read_json()
  	_check(saved.ok, "snapshot session saved")
  	_check(saved.data.has("snapshot"), "session has snapshot field")
  	var snap: Dictionary = saved.data.get("snapshot", {})
  	_check(snap.has("regions"), "snapshot has regions")
  	_check(snap.has("solution"), "snapshot has solution")
  	_check(snap.has("zone_colors"), "snapshot has zone_colors")
  	_check(snap.has("shape_hash"), "snapshot has shape_hash")
  	_check(str(snap.get("shape_hash", "")).begins_with("4x4_"), "shape_hash format")
  	_cleanup(runtime)

  func _test_restart_reuses_snapshot() -> void:
  	var runtime := _runtime("restart_snap")
  	_check(runtime.boot().ok, "restart_snap boot")
  	var s1 := runtime.start_level("L01")
  	_check(s1 != null, "restart_snap first start")
  	var saved1 := runtime.sessions._store.read_json()
  	var snap1: Dictionary = saved1.data.get("snapshot", {})
  	var colors1: Dictionary = snap1.get("zone_colors", {})
  	var regions1: Array = snap1.get("regions", [])
  	# Restart should reuse snapshot (same colors, same regions)
  	var s2 := runtime.restart_level()
  	_check(s2 != null, "restart_snap restart")
  	var saved2 := runtime.sessions._store.read_json()
  	var snap2: Dictionary = saved2.data.get("snapshot", {})
  	_check(snap2.get("regions", []) == regions1, "restart same regions")
  	_check(snap2.get("zone_colors", {}) == colors1, "restart same colors")
  	_check(snap2.get("solution", []) == snap1.get("solution", []), "restart same solution")
  	_cleanup(runtime)
  ```

- [ ] **Step 8: Run all campaign tests**

  ```bash
  godot --headless --path game --script res://tests/test_campaign_runtime.gd
  ```
  Expected: `CAMPAIGN_RUNTIME_PASS`, exit code 0.

- [ ] **Step 9: Run full regression suite**

  ```bash
  godot --headless --path game --script res://tests/test_board_solver.gd
  godot --headless --path game --script res://tests/test_play_session.gd
  godot --headless --path game --script res://tests/test_session_store.gd
  godot --headless --path game --script res://tests/test_progress_manager.gd
  ```
  Expected: All PASS.

- [ ] **Step 10: Clean-room gate**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/campaign/campaign_runtime.gd
  ```
  Expected: 0 matches.

- [ ] **Step 11: Verify line count**

  ```bash
  wc -l game/scripts/campaign/campaign_runtime.gd
  ```
  Must be ≤ 300 lines. If exceeding, extract `_build_level_from_snapshot` and snapshot-building logic into a helper file `game/scripts/campaign/snapshot_builder.gd`.

- [ ] **Step 12: Commit**

  ```bash
  git add game/scripts/campaign/campaign_runtime.gd game/tests/test_campaign_runtime.gd
  git commit -m "$(cat <<'EOF'
  feat(campaign): puzzle snapshot for deterministic restart/resume

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

## Phase 2 — Solver & Accessibility

> **Parallelization:** Task 7 (Colorblind) can run in parallel with Tasks 5+6 (Solver). They touch completely different files:
> - Tasks 5+6: `game/scripts/core/board_solver.gd`, `game/tests/test_board_solver.gd`
> - Task 7: `game/scripts/content/region_painter.gd`, `game/scripts/state/config_store.gd`, `game/tests/test_colorblind.gd`

### Task 5: Locked Subsets (k=2–6) in Board Solver

**Prerequisite:** Phase 1 merged
**Branch:** `feat/solver-advanced` (can run parallel with Task 7's branch)
**Files:**
- Modify: `game/scripts/core/board_solver.gd` (295 lines currently)
- Modify: `game/tests/test_board_solver.gd` (101 lines currently)

**Interfaces:**
- Consumes:
  - `CandyRules.zone_of(regions, r, c) -> String` from `game/scripts/core/candy_rules.gd`
  - `CellModel.CellKind` enum from `game/scripts/core/cell_model.gd`
  - Existing private methods in board_solver.gd: `_zones()` (line 270), `_has_candy()` (line 264), `_candidates_in_zone()` (line 242), `_candidates_in_row()` (line 250), `_candidates_in_col()` (line 257), `_is_candidate()` (line 239), `_apply_elimination()` (line 140), `_empty_board()` (line 287)
- Produces:
  - `BoardSolver._gen_subsets(items: Array, k: int) -> Array` — returns Array of Array
  - `BoardSolver._try_locked_subsets(board: Array, size: int, regions: Array, max_k: int) -> Dictionary` — returns `{"found": bool, "eliminated": Array, "technique": int, "subset_zones": Array}`
  - Extended `Technique` enum: add `SUBSET_PAIR=4`, `SUBSET_TRIPLE=5`, `SUBSET_QUAD=6`, `CONTRA_CHAIN=7`
  - Updated `next_hint()` chain: S2 → S3 → S4-S6 → fallback

**Current Technique enum (line 7):**
```gdscript
enum Technique { ELIMINATION = 1, SINGLE_CANDIDATE = 2, LOCK_INTERSECTION = 3 }
```

**Current `next_hint()` flow (lines 9-45):** Tries S2, then S3, then returns `{found: false}`.

**Current `solve_sequence()` (lines 66-98):** Tries elimination → S2 → S3, with fallback candy placement.

- [ ] **Step 1: Add failing tests to `game/tests/test_board_solver.gd`**

  Add these test calls in `_init()` after line 17 (`_test_internal_exclusions_are_not_candidates()`):
  ```gdscript
  	_test_gen_subsets()
  	_test_locked_subset_returns_dict()
  	_test_locked_subset_no_crash_empty_board()
  ```

  Add these methods before `_empty_board()`:
  ```gdscript
  func _test_gen_subsets() -> void:
  	var items := ["A", "B", "C", "D"]
  	var pairs := BoardSolver._gen_subsets(items, 2)
  	_assert(pairs.size() == 6, "C(4,2) = 6 subsets, got %d" % pairs.size())
  	var triples := BoardSolver._gen_subsets(items, 3)
  	_assert(triples.size() == 4, "C(4,3) = 4 subsets, got %d" % triples.size())
  	var singles := BoardSolver._gen_subsets(items, 1)
  	_assert(singles.size() == 4, "C(4,1) = 4 subsets")
  	var empty := BoardSolver._gen_subsets(items, 0)
  	_assert(empty.size() == 0, "C(4,0) = 0 subsets")
  	var over := BoardSolver._gen_subsets(items, 5)
  	_assert(over.size() == 0, "C(4,5) = 0 subsets")

  func _test_locked_subset_returns_dict() -> void:
  	var board := _empty_board(4)
  	var regions := ["AABB", "AABB", "CCDD", "CCDD"]
  	board[0][0] = CellModel.CellKind.CANDY
  	board[1][3] = CellModel.CellKind.CANDY
  	BoardSolver._apply_elimination(board, 4, regions)
  	var result := BoardSolver._try_locked_subsets(board, 4, regions, 2)
  	_assert(result.has("found"), "subset returns found key")
  	_assert(result.has("eliminated"), "subset returns eliminated key")
  	if result.get("found", false):
  		for cell in result.get("eliminated", []):
  			_assert(cell is Array and cell.size() == 2, "eliminated cell is [r, c]")

  func _test_locked_subset_no_crash_empty_board() -> void:
  	var board := _empty_board(4)
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	BoardSolver._apply_elimination(board, 4, regions)
  	var result := BoardSolver._try_locked_subsets(board, 4, regions, 3)
  	_assert(result.has("found"), "subset on empty board returns found key")
  ```

- [ ] **Step 2: Run test — verify it fails**

  ```bash
  godot --headless --path game --script res://tests/test_board_solver.gd
  ```
  Expected: FAIL — `_gen_subsets` not defined.

- [ ] **Step 3: Update Technique enum**

  Edit `game/scripts/core/board_solver.gd` line 7. Replace:
  ```gdscript
  enum Technique { ELIMINATION = 1, SINGLE_CANDIDATE = 2, LOCK_INTERSECTION = 3 }
  ```
  With:
  ```gdscript
  enum Technique { ELIMINATION = 1, SINGLE_CANDIDATE = 2, LOCK_INTERSECTION = 3, SUBSET_PAIR = 4, SUBSET_TRIPLE = 5, SUBSET_QUAD = 6, CONTRA_CHAIN = 7 }
  ```

- [ ] **Step 4: Implement `_gen_subsets()`**

  Insert before `_empty_board()` (before line 287):
  ```gdscript
  static func _gen_subsets(items: Array, k: int) -> Array:
  	var result: Array = []
  	if k <= 0 or k > items.size():
  		return result
  	var indices: Array[int] = []
  	for i in range(k):
  		indices.append(i)
  	while true:
  		var subset: Array = []
  		for idx in indices:
  			subset.append(items[idx])
  		result.append(subset)
  		var i := k - 1
  		while i >= 0 and indices[i] == i + items.size() - k:
  			i -= 1
  		if i < 0:
  			break
  		indices[i] += 1
  		for j in range(i + 1, k):
  			indices[j] = indices[j - 1] + 1
  	return result

  ```

- [ ] **Step 5: Implement `_try_locked_subsets()`**

  Insert after `_gen_subsets()`:
  ```gdscript
  static func _try_locked_subsets(board: Array, size: int, regions: Array, max_k: int = 6) -> Dictionary:
  	var all_zones := _zones(regions, size)
  	var unplaced_zones: Array = []
  	for z in all_zones:
  		if not _has_candy(board, size, regions, "zone", z):
  			unplaced_zones.append(z)
  	if unplaced_zones.size() < 2:
  		return {"found": false, "eliminated": []}
  	var limit := mini(unplaced_zones.size() - 1, max_k)
  	for k in range(2, limit + 1):
  		var subsets := _gen_subsets(unplaced_zones, k)
  		for subset in subsets:
  			var candidate_rows: Dictionary = {}
  			var zone_cands: Dictionary = {}
  			for z in subset:
  				zone_cands[z] = _candidates_in_zone(board, size, regions, z)
  				for cell in zone_cands[z]:
  					candidate_rows[cell[0]] = true
  			if candidate_rows.size() == k:
  				var elim: Array = []
  				for row_idx in candidate_rows:
  					for c in range(size):
  						var z := CandyRules.zone_of(regions, row_idx, c)
  						if not subset.has(z) and _is_candidate(board, size, regions, row_idx, c):
  							elim.append([row_idx, c])
  				if not elim.is_empty():
  					var tech: int = Technique.SUBSET_PAIR if k == 2 else (Technique.SUBSET_TRIPLE if k == 3 else Technique.SUBSET_QUAD)
  					return {"found": true, "eliminated": elim, "technique": tech, "subset_zones": subset}
  			var candidate_cols: Dictionary = {}
  			for z in subset:
  				for cell in zone_cands[z]:
  					candidate_cols[cell[1]] = true
  			if candidate_cols.size() == k:
  				var elim: Array = []
  				for col_idx in candidate_cols:
  					for r in range(size):
  						var z := CandyRules.zone_of(regions, r, col_idx)
  						if not subset.has(z) and _is_candidate(board, size, regions, r, col_idx):
  							elim.append([r, col_idx])
  				if not elim.is_empty():
  					var tech: int = Technique.SUBSET_PAIR if k == 2 else (Technique.SUBSET_TRIPLE if k == 3 else Technique.SUBSET_QUAD)
  					return {"found": true, "eliminated": elim, "technique": tech, "subset_zones": subset}
  	return {"found": false, "eliminated": []}

  ```

- [ ] **Step 6: Wire subsets into `next_hint()`**

  In `next_hint()`, insert after the S3 block (after line 43, before `return {"found": false}`):
  ```gdscript
  	var s4: Dictionary = _try_locked_subsets(work_board, size, regions, 6)
  	if s4.get("found", false):
  		for cell in (s4["eliminated"] as Array):
  			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  		var s2_after_s4: Dictionary = _try_single_candidate(work_board, size, regions)
  		if s2_after_s4.get("found", false):
  			return {
  				"found": true,
  				"technique": s4.get("technique", Technique.SUBSET_PAIR),
  				"cell": s2_after_s4["cell"],
  				"unit_type": s2_after_s4["unit_type"],
  				"unit_id": s2_after_s4["unit_id"],
  				"explanation": "Locked subset revealed cell in " + str(s2_after_s4["unit_type"])
  			}
  		return {
  			"found": true,
  			"technique": s4.get("technique", Technique.SUBSET_PAIR),
  			"cell": (s4["eliminated"] as Array)[0],
  			"unit_type": "zone",
  			"unit_id": s4.get("subset_zones", [""])[0],
  			"explanation": "Locked subset eliminates candidates"
  		}

  ```

- [ ] **Step 7: Run tests**

  ```bash
  godot --headless --path game --script res://tests/test_board_solver.gd
  ```
  Expected: `CORE_BOARD_SOLVER_PASS`, exit code 0. All existing tests must still pass.

- [ ] **Step 8: Check line count**

  ```bash
  wc -l game/scripts/core/board_solver.gd
  ```
  Must be ≤ 300. If exceeding, extract `_gen_subsets` + `_try_locked_subsets` into `game/scripts/core/subset_solver.gd`.

- [ ] **Step 9: Commit**

  ```bash
  git add game/scripts/core/board_solver.gd game/tests/test_board_solver.gd
  git commit -m "$(cat <<'EOF'
  feat(core): add locked subsets (k=2-6) to board solver

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 6: Contradiction Chains + `replay_solve()`

**Prerequisite:** Task 5 merged (same file)
**Branch:** Same as Task 5
**Files:**
- Modify: `game/scripts/core/board_solver.gd`
- Modify: `game/tests/test_board_solver.gd`

**Interfaces:**
- Consumes: All existing solver internals + `_try_locked_subsets()` from Task 5
- Produces:
  - `BoardSolver._clone_board(board, size) -> Array`
  - `BoardSolver._propagate_and_check(board, size, regions, depth_left) -> bool`
  - `BoardSolver._try_contradiction(board, size, regions, max_depth) -> Dictionary` — `{"found": bool, "eliminated": Array, "technique": CONTRA_CHAIN}`
  - `BoardSolver.replay_solve(size, regions, solution, givens) -> Dictionary` — `{"solved": bool, "steps": int, "profile": Dictionary, "max_technique": int}`

- [ ] **Step 1: Add failing tests**

  Append to `game/tests/test_board_solver.gd` `_init()`:
  ```gdscript
  	_test_contradiction_returns_dict()
  	_test_clone_board()
  	_test_replay_solve_standard()
  ```

  Add methods:
  ```gdscript
  func _test_contradiction_returns_dict() -> void:
  	var board := _empty_board(4)
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var result := BoardSolver._try_contradiction(board, 4, regions, 2)
  	_assert(result.has("found"), "contradiction returns found key")
  	_assert(result.has("eliminated"), "contradiction returns eliminated key")

  func _test_clone_board() -> void:
  	var board := _empty_board(4)
  	board[0][0] = CellModel.CellKind.CANDY
  	var clone := BoardSolver._clone_board(board, 4)
  	clone[1][1] = CellModel.CellKind.MARK
  	_assert(board[1][1] == CellModel.CellKind.BLANK, "clone does not affect original")
  	_assert(clone[0][0] == CellModel.CellKind.CANDY, "clone preserves existing")

  func _test_replay_solve_standard() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var solution := [1, 3, 0, 2]
  	var result := BoardSolver.replay_solve(4, regions, solution, [])
  	_assert(result.get("solved", false), "replay solves standard 4x4")
  	_assert(result.get("steps", 0) == 4, "4 steps for 4x4 (one candy per row)")
  	_assert(result.has("profile"), "replay has profile")
  	_assert(result.get("max_technique", 0) >= 1, "some technique used")
  ```

- [ ] **Step 2: Run test — verify it fails**

  Expected: FAIL — `_try_contradiction`, `_clone_board`, `replay_solve` not defined.

- [ ] **Step 3: Implement `_clone_board()`, `_propagate_and_check()`, `_try_contradiction()`**

  Add to `board_solver.gd` after `_try_locked_subsets()`:
  ```gdscript
  static func _clone_board(board: Array, size: int) -> Array:
  	var clone: Array = []
  	for r in range(size):
  		clone.append(board[r].duplicate())
  	return clone

  static func _propagate_and_check(board: Array, size: int, regions: Array, _depth_left: int) -> bool:
  	for _iteration in range(size * size):
  		_apply_elimination(board, size, regions)
  		var s2 := _try_single_candidate(board, size, regions)
  		if s2.get("found", false):
  			board[s2["cell"][0]][s2["cell"][1]] = CellModel.CellKind.CANDY
  			continue
  		var s3 := _try_lock_intersection(board, size, regions)
  		if s3.get("found", false):
  			for cell in (s3["eliminated"] as Array):
  				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  			continue
  		break
  	for z in _zones(regions, size):
  		if not _has_candy(board, size, regions, "zone", z):
  			if _candidates_in_zone(board, size, regions, z).is_empty():
  				return true
  	for r in range(size):
  		if not _has_candy(board, size, regions, "row", r):
  			if _candidates_in_row(board, size, regions, r).is_empty():
  				return true
  	for c in range(size):
  		if not _has_candy(board, size, regions, "col", c):
  			if _candidates_in_col(board, size, regions, c).is_empty():
  				return true
  	return false

  static func _try_contradiction(board: Array, size: int, regions: Array, max_depth: int = 2) -> Dictionary:
  	for r in range(size):
  		for c in range(size):
  			if not _is_candidate(board, size, regions, r, c):
  				continue
  			var test_board := _clone_board(board, size)
  			test_board[r][c] = CellModel.CellKind.CANDY
  			if _propagate_and_check(test_board, size, regions, max_depth):
  				return {"found": true, "eliminated": [[r, c]], "technique": Technique.CONTRA_CHAIN}
  	return {"found": false, "eliminated": []}

  ```

- [ ] **Step 4: Implement `replay_solve()`**

  Add as a PUBLIC static method after `compute_cell_ranks()`:
  ```gdscript
  static func replay_solve(size: int, regions: Array, solution: Array, givens: Array) -> Dictionary:
  	var board := _empty_board(size)
  	for g in givens:
  		var gr: int = int(g.get("r", g.get("row", -1))) if g is Dictionary else int(g[0])
  		var gc: int = int(g.get("c", g.get("col", -1))) if g is Dictionary else int(g[1])
  		if gr >= 0 and gr < size and gc >= 0 and gc < size:
  			board[gr][gc] = CellModel.CellKind.GIVEN
  	var profile := {"s1": 0, "s2": 0, "s3": 0, "s4": 0, "s5": 0, "s6": 0, "s7": 0}
  	var max_tech: int = 0
  	var steps: int = 0
  	var placed_count: int = givens.size()
  	for _outer in range(size * size):
  		if placed_count >= size:
  			break
  		_apply_elimination(board, size, regions)
  		profile["s1"] += 1
  		var s2 := _try_single_candidate(board, size, regions)
  		if s2.get("found", false):
  			board[s2["cell"][0]][s2["cell"][1]] = CellModel.CellKind.CANDY
  			profile["s2"] += 1
  			max_tech = maxi(max_tech, Technique.SINGLE_CANDIDATE)
  			steps += 1
  			placed_count += 1
  			continue
  		var s3 := _try_lock_intersection(board, size, regions)
  		if s3.get("found", false):
  			for cell in (s3["eliminated"] as Array):
  				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  			profile["s3"] += 1
  			max_tech = maxi(max_tech, Technique.LOCK_INTERSECTION)
  			continue
  		var s4 := _try_locked_subsets(board, size, regions, 6)
  		if s4.get("found", false):
  			for cell in (s4["eliminated"] as Array):
  				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  			var tech_key := "s4" if s4.get("technique") == Technique.SUBSET_PAIR else ("s5" if s4.get("technique") == Technique.SUBSET_TRIPLE else "s6")
  			profile[tech_key] += 1
  			max_tech = maxi(max_tech, int(s4.get("technique", Technique.SUBSET_PAIR)))
  			continue
  		var s7 := _try_contradiction(board, size, regions, 2)
  		if s7.get("found", false):
  			for cell in (s7["eliminated"] as Array):
  				board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  			profile["s7"] += 1
  			max_tech = maxi(max_tech, Technique.CONTRA_CHAIN)
  			continue
  		break
  	return {"solved": placed_count >= size, "steps": steps, "profile": profile, "max_technique": max_tech}

  ```

- [ ] **Step 5: Wire contradiction into `next_hint()` chain**

  In `next_hint()`, after the S4 block added in Task 5, insert before `return {"found": false}`:
  ```gdscript
  	var s7: Dictionary = _try_contradiction(work_board, size, regions, 2)
  	if s7.get("found", false):
  		for cell in (s7["eliminated"] as Array):
  			work_board[cell[0]][cell[1]] = CellModel.CellKind.MARK
  		var s2_after_s7: Dictionary = _try_single_candidate(work_board, size, regions)
  		if s2_after_s7.get("found", false):
  			return {
  				"found": true,
  				"technique": Technique.CONTRA_CHAIN,
  				"cell": s2_after_s7["cell"],
  				"unit_type": s2_after_s7["unit_type"],
  				"unit_id": s2_after_s7["unit_id"],
  				"explanation": "Contradiction chain revealed cell"
  			}
  		return {
  			"found": true,
  			"technique": Technique.CONTRA_CHAIN,
  			"cell": (s7["eliminated"] as Array)[0],
  			"unit_type": "zone",
  			"unit_id": "",
  			"explanation": "Contradiction chain eliminates candidate"
  		}

  ```

- [ ] **Step 6: Run tests**

  ```bash
  godot --headless --path game --script res://tests/test_board_solver.gd
  ```
  Expected: `CORE_BOARD_SOLVER_PASS`.

- [ ] **Step 7: Check line count — CRITICAL**

  ```bash
  wc -l game/scripts/core/board_solver.gd
  ```
  After Tasks 5+6, this file will be ~450+ lines, exceeding the 300-line limit. **You MUST split it.** Extract into:
  - `game/scripts/core/board_solver.gd` — keeps public API: `next_hint()`, `progressive_hint()`, `solve_sequence()`, `compute_cell_ranks()`, `replay_solve()`, `_build_work_board()`, `_empty_board()`, delegates to solver_techniques
  - `game/scripts/core/solver_techniques.gd` — all private technique functions: `_try_single_candidate()`, `_try_lock_intersection()`, `_try_locked_subsets()`, `_gen_subsets()`, `_try_contradiction()`, `_propagate_and_check()`, `_clone_board()`, `_apply_elimination()`, `_is_candidate()`, `_candidates_in_*()`, `_has_candy()`, `_zones()`, `_unit_cells()`

  After split, update preloads in `board_solver.gd`:
  ```gdscript
  const SolverTechniques = preload("res://scripts/core/solver_techniques.gd")
  ```
  And delegate calls: `SolverTechniques._try_single_candidate(...)` etc.

  Re-run tests after split to confirm no regressions.

- [ ] **Step 8: Clean-room gate + commit**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/core/board_solver.gd game/scripts/core/solver_techniques.gd
  ```
  ```bash
  git add game/scripts/core/board_solver.gd game/scripts/core/solver_techniques.gd game/tests/test_board_solver.gd
  git commit -m "$(cat <<'EOF'
  feat(core): add contradiction chains, replay_solve, split solver

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 7: Colorblind Mode (PARALLEL with Tasks 5+6)

**Prerequisite:** Phase 1 merged (does NOT depend on Tasks 5+6)
**Branch:** `feat/colorblind-mode` (parallel with solver branch)
**Files:**
- Modify: `game/scripts/content/region_painter.gd` (132 lines currently)
- Modify: `game/scripts/state/config_store.gd` (65 lines currently)
- Create: `game/tests/test_colorblind.gd`

**Interfaces:**
- Consumes:
  - `RegionPainter.precompute_grid(size, zones) -> Array` (line 58)
  - `RegionPainter._build_adjacency(size, grid) -> Dictionary` (line 98)
  - `RegionPainter.lab_distance(a, b) -> float` (line 68)
  - `Palette.ZONE_COLORS: Array[Color]` from `game/scripts/theme/palette.gd`
- Produces:
  - `RegionPainter.OverlayIcon` enum: `{ NONE, STAR, DIAMOND, HEART, TRIANGLE, CROSS, DOT }`
  - `RegionPainter.luminance(c: Color) -> float`
  - `RegionPainter.assign_with_overlays(size: int, zones: Array, palette: Array[Color]) -> Dictionary` returning `{"colors": Dictionary, "overlays": Dictionary}`
  - `RegionPainter.overlay_tint(base_color: Color, is_dark: bool) -> Color`
  - `ConfigStore` gains `"colorblind"` in DEFAULTS (default: false) and EDITABLE_KEYS

**Current `region_painter.gd` structure:**
- Line 1-2: extends RefCounted
- Line 4-56: `assign_colors()` — graph coloring with CIELAB max-distance
- Line 58-66: `precompute_grid()`
- Line 68-74: `lab_distance()`
- Line 76-96: `to_lab()`
- Line 98-119: `_build_adjacency()`
- Line 121-131: `_linearize()`, `_lab_transfer()`

**Current `config_store.gd`:**
- Line 6: `const DEFAULTS := {"audio": true, "haptic": true, "reduced_motion": false, "high_contrast": false, "large_text": false}`
- Line 7: `const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reduced_motion", "high_contrast", "large_text"]`

- [ ] **Step 1: Create test file `game/tests/test_colorblind.gd`**

  Write this exact file:
  ```gdscript
  extends SceneTree

  const RegionPainter = preload("res://scripts/content/region_painter.gd")
  const Palette = preload("res://scripts/theme/palette.gd")

  var _fails: Array[String] = []

  func _init() -> void:
  	_test_assign_with_overlays_basic()
  	_test_dark_zones_get_overlay()
  	_test_no_adjacent_same_overlay()
  	_test_overlay_tint_dark()
  	_test_overlay_tint_light()
  	_test_luminance_range()
  	if _fails.is_empty():
  		print("COLORBLIND_PASS")
  		quit(0)
  	else:
  		for f in _fails:
  			printerr(f)
  		quit(1)

  func _test_assign_with_overlays_basic() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
  	_assert(result.has("colors"), "result has colors")
  	_assert(result.has("overlays"), "result has overlays")
  	_assert(result.colors.size() == 4, "4 zone colors for ABCD")
  	_assert(result.overlays.size() == 4, "4 zone overlays for ABCD")
  	for z in result.colors:
  		_assert(result.colors[z] is Color, "color for zone %s is Color" % z)
  	for z in result.overlays:
  		_assert(result.overlays[z] is int, "overlay for zone %s is int" % z)

  func _test_dark_zones_get_overlay() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
  	var has_overlay := false
  	var has_none := false
  	for z in result.overlays:
  		if result.overlays[z] != RegionPainter.OverlayIcon.NONE:
  			has_overlay = true
  		else:
  			has_none = true
  	_assert(has_overlay, "some zones have overlay (dark pool)")
  	_assert(has_none, "some zones have no overlay (light pool)")

  func _test_no_adjacent_same_overlay() -> void:
  	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
  	var result := RegionPainter.assign_with_overlays(4, regions, Palette.ZONE_COLORS)
  	var grid := RegionPainter.precompute_grid(4, regions)
  	for r in range(4):
  		for c in range(4):
  			var z1: String = grid[r][c]
  			for d in [[0, 1], [1, 0]]:
  				var nr := r + d[0]
  				var nc := c + d[1]
  				if nr < 4 and nc < 4:
  					var z2: String = grid[nr][nc]
  					if z1 != z2:
  						var o1: int = result.overlays[z1]
  						var o2: int = result.overlays[z2]
  						if o1 != RegionPainter.OverlayIcon.NONE and o2 != RegionPainter.OverlayIcon.NONE:
  							_assert(o1 != o2, "adjacent dark zones %s,%s must have different overlay" % [z1, z2])

  func _test_overlay_tint_dark() -> void:
  	var base := Color(0.2, 0.1, 0.3)
  	var tint := RegionPainter.overlay_tint(base, true)
  	_assert(tint != base, "dark tint differs from base")
  	var dist := RegionPainter.lab_distance(base, tint)
  	_assert(dist > 3.0, "dark overlay tint has visible ΔE (got %.1f)" % dist)

  func _test_overlay_tint_light() -> void:
  	var base := Color(0.8, 0.9, 0.7)
  	var tint := RegionPainter.overlay_tint(base, false)
  	_assert(tint != base, "light tint differs from base")

  func _test_luminance_range() -> void:
  	_assert(RegionPainter.luminance(Color.BLACK) < 0.01, "black luminance near 0")
  	_assert(RegionPainter.luminance(Color.WHITE) > 0.99, "white luminance near 1")
  	_assert(RegionPainter.luminance(Color(0.5, 0.5, 0.5)) > 0.3, "gray luminance mid-range")

  func _assert(condition: bool, label: String) -> void:
  	if not condition:
  		_fails.append("FAIL: " + label)
  ```

- [ ] **Step 2: Run test — verify it fails**

  ```bash
  godot --headless --path game --script res://tests/test_colorblind.gd
  ```
  Expected: FAIL — `assign_with_overlays` not defined.

- [ ] **Step 3: Add `OverlayIcon` enum and `luminance()` to `region_painter.gd`**

  Insert after line 2 (`extends RefCounted`):
  ```gdscript

  enum OverlayIcon { NONE, STAR, DIAMOND, HEART, TRIANGLE, CROSS, DOT }

  static func luminance(c: Color) -> float:
  	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b

  ```

- [ ] **Step 4: Add `assign_with_overlays()` method**

  Insert after `assign_colors()` (after line 56):
  ```gdscript

  static func assign_with_overlays(size: int, zones: Array, palette: Array[Color]) -> Dictionary:
  	if palette.is_empty():
  		return {"colors": {}, "overlays": {}}
  	var grid := precompute_grid(size, zones)
  	var adj := _build_adjacency(size, grid)
  	var all_zones: Array = []
  	for r in range(size):
  		for c in range(size):
  			var z: String = grid[r][c]
  			if not all_zones.has(z):
  				all_zones.append(z)
  	var sorted_palette := palette.duplicate()
  	sorted_palette.sort_custom(func(a: Color, b: Color) -> bool: return luminance(a) < luminance(b))
  	var n_pattern := ceili(size / 2.0)
  	var dark_pool: Array[Color] = []
  	var light_pool: Array[Color] = []
  	for i in range(sorted_palette.size()):
  		if i < n_pattern:
  			dark_pool.append(sorted_palette[i])
  		else:
  			light_pool.append(sorted_palette[i])
  	if light_pool.is_empty():
  		light_pool = dark_pool.duplicate()
  	all_zones.sort_custom(func(a: String, b: String) -> bool:
  		return adj.get(a, []).size() > adj.get(b, []).size()
  	)
  	var colors: Dictionary = {}
  	var overlays: Dictionary = {}
  	var dark_assigned: int = 0
  	var overlay_icons := [OverlayIcon.STAR, OverlayIcon.DIAMOND, OverlayIcon.HEART, OverlayIcon.TRIANGLE, OverlayIcon.CROSS, OverlayIcon.DOT]
  	for z in all_zones:
  		var neighbor_colors: Array[Color] = []
  		for nbr in adj.get(z, []):
  			if colors.has(nbr):
  				neighbor_colors.append(colors[nbr])
  		var pool: Array[Color] = dark_pool if dark_assigned < n_pattern else light_pool
  		var candidates: Array[Color] = []
  		for col in pool:
  			if not neighbor_colors.has(col):
  				candidates.append(col)
  		if candidates.is_empty():
  			candidates = pool.duplicate()
  		var best_col: Color = candidates[0]
  		if not neighbor_colors.is_empty():
  			var max_min_dist: float = -1.0
  			for col in candidates:
  				var min_d: float = INF
  				for n_col in neighbor_colors:
  					min_d = minf(min_d, lab_distance(col, n_col))
  				if min_d > max_min_dist:
  					max_min_dist = min_d
  					best_col = col
  		colors[z] = best_col
  		if dark_assigned < n_pattern:
  			var neighbor_overlays: Array = []
  			for nbr in adj.get(z, []):
  				if overlays.has(nbr) and overlays[nbr] != OverlayIcon.NONE:
  					neighbor_overlays.append(overlays[nbr])
  			var chosen_icon: int = OverlayIcon.NONE
  			for icon in overlay_icons:
  				if not neighbor_overlays.has(icon):
  					chosen_icon = icon
  					break
  			if chosen_icon == OverlayIcon.NONE:
  				chosen_icon = overlay_icons[dark_assigned % overlay_icons.size()]
  			overlays[z] = chosen_icon
  			dark_assigned += 1
  		else:
  			overlays[z] = OverlayIcon.NONE
  	return {"colors": colors, "overlays": overlays}

  ```

- [ ] **Step 5: Add `overlay_tint()` method**

  Insert after `assign_with_overlays()`:
  ```gdscript
  static func overlay_tint(base_color: Color, is_dark: bool) -> Color:
  	if is_dark:
  		var h := base_color.h
  		var s := minf(base_color.s + 0.15, 1.0)
  		var v := maxf(base_color.v - 0.1, 0.0)
  		return Color.from_hsv(h, s, v, base_color.a)
  	else:
  		return base_color.lightened(0.3)

  ```

- [ ] **Step 6: Add colorblind setting to `config_store.gd`**

  Edit `game/scripts/state/config_store.gd` line 6, replace:
  ```gdscript
  const DEFAULTS := {"audio": true, "haptic": true, "reduced_motion": false, "high_contrast": false, "large_text": false}
  ```
  With:
  ```gdscript
  const DEFAULTS := {"audio": true, "haptic": true, "reduced_motion": false, "high_contrast": false, "large_text": false, "colorblind": false}
  ```

  Edit line 7, replace:
  ```gdscript
  const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reduced_motion", "high_contrast", "large_text"]
  ```
  With:
  ```gdscript
  const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reduced_motion", "high_contrast", "large_text", "colorblind"]
  ```

- [ ] **Step 7: Run colorblind tests**

  ```bash
  godot --headless --path game --script res://tests/test_colorblind.gd
  ```
  Expected: `COLORBLIND_PASS`.

- [ ] **Step 8: Run config_store regression test**

  ```bash
  godot --headless --path game --script res://tests/test_config_store.gd
  ```
  Expected: PASS.

- [ ] **Step 9: Check line count on region_painter.gd**

  ```bash
  wc -l game/scripts/content/region_painter.gd
  ```
  Must be ≤ 300.

- [ ] **Step 10: Clean-room gate + commit**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/content/region_painter.gd game/scripts/state/config_store.gd
  ```
  Expected: 0 matches.
  ```bash
  git add game/scripts/content/region_painter.gd game/scripts/state/config_store.gd game/tests/test_colorblind.gd
  git commit -m "$(cat <<'EOF'
  feat(content): colorblind mode — overlay icons and high-contrast assignment

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

## Phase 3 — Content & DDA

> **Parallelization:** Task 10 (Bank expansion — Python tooling only) can run in parallel with Tasks 8+9 (Pace Adjuster — GDScript only). They touch completely different files.

### Task 8: Pace Adjuster (DDA)

**Prerequisite:** Phase 2 merged
**Branch:** `feat/pace-adjuster` (can run parallel with Task 10's branch)
**Files:**
- Create: `game/scripts/campaign/pace_adjuster.gd`
- Create: `game/tests/test_pace_adjuster.gd`

**Interfaces:**
- Produces:
  - `PaceAdjuster.record_result(won: bool, hints_used: int, mistakes: int, was_retry: bool) -> void`
  - `PaceAdjuster.rank_offset(level_order: int, base_rank: int) -> int`
  - `PaceAdjuster.on_level_start() -> void`
  - `PaceAdjuster.to_dict() -> Dictionary`
  - `PaceAdjuster.from_dict(data: Dictionary) -> void`
  - Signal: `adjusted(reason: String, offset: int)`

**DDA rules (from spec):**
- Promotion: `_clean_streak >= 2` → offset +1, capped at `max_rank - base_rank`
- Demotion: `_fail_streak >= 2 AND !_demoted_this_level` → offset -1
- Retry demotion: `_retry_streak >= 2 AND !_demoted_this_level` → offset -1
- Max rank: 2 for level≤15, 3 for level≤30, 4 for level>30
- Demote guard: once per level (reset by `on_level_start()`)
- Clean win = won AND hints_used==0 AND mistakes==0

- [ ] **Step 1: Create test file `game/tests/test_pace_adjuster.gd`**

  Write this exact file:
  ```gdscript
  extends SceneTree

  const PaceAdjuster = preload("res://scripts/campaign/pace_adjuster.gd")

  var _fails: Array[String] = []

  func _init() -> void:
  	_test_no_offset_default()
  	_test_clean_streak_promotes()
  	_test_dirty_win_no_promote()
  	_test_fail_streak_demotes()
  	_test_retry_streak_demotes()
  	_test_demote_guard()
  	_test_rank_cap_low_level()
  	_test_rank_cap_high_level()
  	_test_round_trip()
  	if _fails.is_empty():
  		print("PACE_ADJUSTER_PASS")
  		quit(0)
  	else:
  		for f in _fails:
  			printerr(f)
  		quit(1)

  func _test_no_offset_default() -> void:
  	var pa := PaceAdjuster.new()
  	_assert(pa.rank_offset(1, 1) == 0, "no offset initially")

  func _test_clean_streak_promotes() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 0, 0, false)
  	pa.record_result(true, 0, 0, false)
  	_assert(pa.rank_offset(25, 1) == 1, "2 clean wins on level 25 base_rank 1 → +1")

  func _test_dirty_win_no_promote() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 1, 0, false)
  	pa.record_result(true, 0, 0, false)
  	_assert(pa.rank_offset(25, 1) == 0, "dirty win breaks clean streak → no promote")

  func _test_fail_streak_demotes() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(false, 0, 0, false)
  	pa.record_result(false, 0, 0, false)
  	_assert(pa.rank_offset(25, 2) == -1, "2 fails → -1")

  func _test_retry_streak_demotes() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 1, 0, true)
  	pa.record_result(true, 0, 0, true)
  	_assert(pa.rank_offset(25, 2) == -1, "2 retries → -1")

  func _test_demote_guard() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(false, 0, 0, false)
  	pa.record_result(false, 0, 0, false)
  	_assert(pa.rank_offset(25, 2) == -1, "first call demotes")
  	_assert(pa.rank_offset(25, 2) == 0, "second call guarded — no double demote")
  	pa.on_level_start()
  	pa.record_result(false, 0, 0, false)
  	pa.record_result(false, 0, 0, false)
  	_assert(pa.rank_offset(25, 2) == -1, "after on_level_start guard resets")

  func _test_rank_cap_low_level() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 0, 0, false)
  	pa.record_result(true, 0, 0, false)
  	_assert(pa.rank_offset(10, 2) == 0, "level 10 max_rank 2, base_rank 2 → no room to promote")

  func _test_rank_cap_high_level() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 0, 0, false)
  	pa.record_result(true, 0, 0, false)
  	_assert(pa.rank_offset(25, 2) == 1, "level 25 max_rank 3, base_rank 2 → +1")

  func _test_round_trip() -> void:
  	var pa := PaceAdjuster.new()
  	pa.record_result(true, 0, 0, false)
  	pa.record_result(true, 0, 0, false)
  	var d := pa.to_dict()
  	var pa2 := PaceAdjuster.new()
  	pa2.from_dict(d)
  	_assert(pa2.rank_offset(25, 1) == pa.rank_offset(25, 1), "round trip preserves offset behavior")

  func _assert(condition: bool, label: String) -> void:
  	if not condition:
  		_fails.append("FAIL: " + label)
  ```

- [ ] **Step 2: Run test — verify it fails**

  Expected: Script error — `pace_adjuster.gd` not found.

- [ ] **Step 3: Create `game/scripts/campaign/pace_adjuster.gd`**

  Write this exact file:
  ```gdscript
  extends RefCounted

  signal adjusted(reason: String, offset: int)

  var _clean_streak: int = 0
  var _fail_streak: int = 0
  var _retry_streak: int = 0
  var _demoted_this_level: bool = false

  func record_result(won: bool, hints_used: int, mistakes: int, was_retry: bool) -> void:
  	if won:
  		_fail_streak = 0
  		if hints_used == 0 and mistakes == 0:
  			_clean_streak += 1
  		else:
  			_clean_streak = 0
  	else:
  		_clean_streak = 0
  		_fail_streak += 1
  	if was_retry:
  		_retry_streak += 1
  	else:
  		_retry_streak = 0

  func rank_offset(level_order: int, base_rank: int) -> int:
  	var max_rank: int = 2 if level_order <= 15 else (3 if level_order <= 30 else 4)
  	if _clean_streak >= 2:
  		return maxi(0, mini(1, max_rank - base_rank))
  	if _fail_streak >= 2 and not _demoted_this_level:
  		_demoted_this_level = true
  		adjusted.emit("fail_streak", -1)
  		return -1
  	if _retry_streak >= 2 and not _demoted_this_level:
  		_demoted_this_level = true
  		adjusted.emit("retry_streak", -1)
  		return -1
  	return 0

  func on_level_start() -> void:
  	_demoted_this_level = false

  func to_dict() -> Dictionary:
  	return {"clean_streak": _clean_streak, "fail_streak": _fail_streak, "retry_streak": _retry_streak}

  func from_dict(data: Dictionary) -> void:
  	_clean_streak = int(data.get("clean_streak", 0))
  	_fail_streak = int(data.get("fail_streak", 0))
  	_retry_streak = int(data.get("retry_streak", 0))
  	_demoted_this_level = false
  ```

- [ ] **Step 4: Run test — verify it passes**

  ```bash
  godot --headless --path game --script res://tests/test_pace_adjuster.gd
  ```
  Expected: `PACE_ADJUSTER_PASS`.

- [ ] **Step 5: Clean-room gate + commit**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/campaign/pace_adjuster.gd
  ```
  ```bash
  git add game/scripts/campaign/pace_adjuster.gd game/tests/test_pace_adjuster.gd
  git commit -m "$(cat <<'EOF'
  feat(campaign): pace adjuster — DDA rank offset based on win/loss streaks

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 9: Integrate DDA into CampaignRuntime

**Prerequisite:** Task 8 merged
**Branch:** Same as Task 8
**Files:**
- Modify: `game/scripts/campaign/campaign_runtime.gd`
- Modify: `game/tests/test_campaign_runtime.gd`

**Interfaces:**
- Consumes: `PaceAdjuster` from Task 8
- Produces: `CampaignRuntime.pace_adjuster` property

**Integration points in `campaign_runtime.gd`:**
- After preloads: add `const PaceAdjuster = preload("res://scripts/campaign/pace_adjuster.gd")`
- After `_current_snapshot` var: add `var pace_adjuster: PaceAdjuster = PaceAdjuster.new()`
- In `boot()`: after `progress.load()` succeeds (line 54), restore DDA state
- In `start_level()`: call `pace_adjuster.on_level_start()`
- In `on_level_won()`: call `pace_adjuster.record_result(true, ...)` and persist
- In `on_level_lost()`: call `pace_adjuster.record_result(false, ...)` and persist

- [ ] **Step 1: Add failing test**

  In `test_campaign_runtime.gd` `_init()`, add:
  ```gdscript
  	_test_dda_integration()
  ```

  Add method:
  ```gdscript
  func _test_dda_integration() -> void:
  	var runtime := _runtime("dda")
  	_check(runtime.boot().ok, "dda boot")
  	_check(runtime.pace_adjuster != null, "pace_adjuster initialized")
  	_check(runtime.pace_adjuster.rank_offset(1, 1) == 0, "initial offset 0")
  	_cleanup(runtime)
  ```

- [ ] **Step 2: Run test — verify it fails**

  Expected: FAIL — `pace_adjuster` not a property.

- [ ] **Step 3: Add PaceAdjuster to campaign_runtime.gd**

  Add preload after the ShapeFingerprint/RegionPainter/Palette preloads:
  ```gdscript
  const PaceAdjuster = preload("res://scripts/campaign/pace_adjuster.gd")
  ```

  Add property after `var _current_snapshot`:
  ```gdscript
  var pace_adjuster: PaceAdjuster = PaceAdjuster.new()
  ```

  In `boot()`, after the progress load succeeds and before `if not playlist_order().has(...)`, add:
  ```gdscript
  	if progress.current.has("dda") and progress.current.dda is Dictionary:
  		pace_adjuster.from_dict(progress.current.dda)
  ```

  In `start_level()`, at the beginning (after the guard checks), add:
  ```gdscript
  	pace_adjuster.on_level_start()
  ```

  In `on_level_won()`, after `var advanced := progress.advance_level(...)` and before `_pending_win.clear()`:
  ```gdscript
  	pace_adjuster.record_result(true, int(score_data.get("hints_used", 0)), int(score_data.get("mistakes", 0)), false)
  	progress.current["dda"] = pace_adjuster.to_dict()
  ```

  In `on_level_lost()`, after `level_lost.emit(label)`:
  ```gdscript
  	pace_adjuster.record_result(false, 0, 0, false)
  	progress.current["dda"] = pace_adjuster.to_dict()
  ```

- [ ] **Step 4: Run tests**

  ```bash
  godot --headless --path game --script res://tests/test_campaign_runtime.gd
  ```
  Expected: `CAMPAIGN_RUNTIME_PASS`.

- [ ] **Step 5: Commit**

  ```bash
  git add game/scripts/campaign/campaign_runtime.gd game/tests/test_campaign_runtime.gd
  git commit -m "$(cat <<'EOF'
  feat(campaign): integrate pace adjuster DDA into campaign runtime

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 10: Bank mở rộng 5×5, 6×6 (PARALLEL with Tasks 8+9)

**Prerequisite:** Phase 2 merged (needs advanced solver for accurate rating)
**Branch:** `feat/bank-expansion` (parallel with pace-adjuster branch)
**Files:**
- Create: `game/data/banks/bank_5x5.json`
- Create: `game/data/banks/bank_6x6.json`
- Possibly modify Python tools in `GDD/tools/`

**Interfaces:**
- Consumes: Python tools `GDD/tools/generate_levels.py`, `GDD/tools/build_playtest_bank.py`, `GDD/tools/generate_pace.py`
- Produces: Bank files at `game/data/banks/bank_5x5.json` and `game/data/banks/bank_6x6.json` loadable by `BankReader.load_bank(5)` and `BankReader.load_bank(6)`

**IMPORTANT:** This task involves running Python generation tools whose exact CLI may differ from what's documented. Read each tool's `--help` first.

- [ ] **Step 1: Check existing generation tools**

  ```bash
  python -B GDD/tools/generate_levels.py --help
  python -B GDD/tools/build_playtest_bank.py --help
  python -B GDD/tools/generate_pace.py --help
  ```
  Read the output to understand exact CLI arguments.

- [ ] **Step 2: Generate 5×5 levels**

  ```bash
  python -B GDD/tools/generate_levels.py --size 5 --count 30 --seed 50000 --output GDD/tools/output_5x5/
  ```
  Adjust command based on Step 1 findings. Target: 30 levels across ranks 1-3.

- [ ] **Step 3: Build bank 5×5**

  ```bash
  python -B GDD/tools/build_playtest_bank.py --size 5 --input GDD/tools/output_5x5/ --output game/data/banks/bank_5x5.json
  ```

- [ ] **Step 4: Generate pace sidecar 5×5**

  ```bash
  python -B GDD/tools/generate_pace.py --bank game/data/banks/bank_5x5.json --output game/data/banks/bank_5x5.pace.json
  ```

- [ ] **Step 5: Repeat for 6×6**

  ```bash
  python -B GDD/tools/generate_levels.py --size 6 --count 20 --seed 60000 --output GDD/tools/output_6x6/
  python -B GDD/tools/build_playtest_bank.py --size 6 --input GDD/tools/output_6x6/ --output game/data/banks/bank_6x6.json
  python -B GDD/tools/generate_pace.py --bank game/data/banks/bank_6x6.json --output game/data/banks/bank_6x6.pace.json
  ```

- [ ] **Step 6: Validate all banks**

  ```bash
  python -B tools/validate_content.py
  ```
  Expected: 0 errors for all bank sizes.

- [ ] **Step 7: Commit**

  ```bash
  git add game/data/banks/bank_5x5.json game/data/banks/bank_6x6.json
  git commit -m "$(cat <<'EOF'
  feat(content): add bank 5x5 and 6x6

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

## Phase 4 — Release Hardening

### Task 11: Bank Codec (XOR Encryption)

**Prerequisite:** Phase 3 merged
**Branch:** `feat/bank-codec`
**Files:**
- Create: `game/scripts/content/bank_codec.gd`
- Modify: `game/scripts/content/bank_reader.gd` (123 lines currently)
- Create: `game/tests/test_bank_codec.gd`
- Create: `tools/encode_banks.py`

**Interfaces:**
- Produces: `BankCodec.xor_transform(data: PackedByteArray, key: String) -> PackedByteArray`

**Current `bank_reader.gd` `_parse_bank()` (lines 77-92):**
```gdscript
func _parse_bank(path: String) -> Dictionary:
	# ... opens file, reads text, parses JSON ...
	var text := file.get_as_text()   # LINE 83 — this is what we change
```

- [ ] **Step 1: Create test file `game/tests/test_bank_codec.gd`**

  Write this exact file:
  ```gdscript
  extends SceneTree

  const BankCodec = preload("res://scripts/content/bank_codec.gd")

  var _fails: Array[String] = []

  func _init() -> void:
  	_test_round_trip()
  	_test_wrong_key_garbage()
  	_test_empty_data()
  	_test_symmetric()
  	if _fails.is_empty():
  		print("BANK_CODEC_PASS")
  		quit(0)
  	else:
  		for f in _fails:
  			printerr(f)
  		quit(1)

  func _test_round_trip() -> void:
  	var original := '{"bankVersion": 1, "size": 4}'.to_utf8_buffer()
  	var key := "candoku-2026-bank-key"
  	var encoded := BankCodec.xor_transform(original, key)
  	_assert(encoded != original, "encoded differs from original")
  	var decoded := BankCodec.xor_transform(encoded, key)
  	_assert(decoded == original, "decode matches original")

  func _test_wrong_key_garbage() -> void:
  	var original := '{"test": true}'.to_utf8_buffer()
  	var encoded := BankCodec.xor_transform(original, "correct-key")
  	var decoded := BankCodec.xor_transform(encoded, "wrong-key")
  	_assert(decoded != original, "wrong key produces garbage")

  func _test_empty_data() -> void:
  	var empty := PackedByteArray()
  	var result := BankCodec.xor_transform(empty, "key")
  	_assert(result.size() == 0, "empty in empty out")

  func _test_symmetric() -> void:
  	var data := "Hello World 12345 !@#$%".to_utf8_buffer()
  	var key := "test-key-abc"
  	var a := BankCodec.xor_transform(data, key)
  	var b := BankCodec.xor_transform(a, key)
  	_assert(b == data, "double transform = identity")

  func _assert(condition: bool, label: String) -> void:
  	if not condition:
  		_fails.append("FAIL: " + label)
  ```

- [ ] **Step 2: Run test — verify it fails**

  Expected: `bank_codec.gd` not found.

- [ ] **Step 3: Create `game/scripts/content/bank_codec.gd`**

  ```gdscript
  extends RefCounted

  static func xor_transform(data: PackedByteArray, key: String) -> PackedByteArray:
  	if data.is_empty() or key.is_empty():
  		return data.duplicate()
  	var key_bytes := key.to_utf8_buffer()
  	var key_len := key_bytes.size()
  	var result := data.duplicate()
  	for i in range(result.size()):
  		result[i] = result[i] ^ key_bytes[i % key_len]
  	return result
  ```

- [ ] **Step 4: Run test — verify it passes**

  ```bash
  godot --headless --path game --script res://tests/test_bank_codec.gd
  ```
  Expected: `BANK_CODEC_PASS`.

- [ ] **Step 5: Update `bank_reader.gd` for runtime decoding**

  Add preload after line 4 (`const LevelValidator`):
  ```gdscript
  const BankCodec = preload("res://scripts/content/bank_codec.gd")
  ```

  Add constant after `BANK_VERSION`:
  ```gdscript
  const _CODEC_KEY := "candoku-2026-bank-key"
  ```

  In `_parse_bank()`, replace line 83 (`var text := file.get_as_text()`) with:
  ```gdscript
  	var text: String
  	if OS.has_feature("editor"):
  		text = file.get_as_text()
  	else:
  		var raw := file.get_buffer(file.get_length())
  		var decoded := BankCodec.xor_transform(raw, _CODEC_KEY)
  		text = decoded.get_string_from_utf8()
  ```

- [ ] **Step 6: Run existing bank_reader tests (editor mode reads plain)**

  ```bash
  godot --headless --path game --script res://tests/test_bank_reader.gd
  ```
  Expected: PASS — editor mode uses `file.get_as_text()` as before.

- [ ] **Step 7: Create `tools/encode_banks.py`**

  ```python
  #!/usr/bin/env python3
  """Encode bank JSON files with XOR for release builds."""
  import argparse
  import pathlib

  KEY = b"candoku-2026-bank-key"

  def xor_transform(data: bytes) -> bytes:
      key_len = len(KEY)
      return bytes(b ^ KEY[i % key_len] for i, b in enumerate(data))

  def main():
      parser = argparse.ArgumentParser(description="Encode bank files for release")
      parser.add_argument("--input", required=True, help="Directory with plain bank JSON files")
      parser.add_argument("--output", required=True, help="Directory for encoded files")
      args = parser.parse_args()
      src = pathlib.Path(args.input)
      dst = pathlib.Path(args.output)
      dst.mkdir(parents=True, exist_ok=True)
      for f in sorted(src.glob("*.json")):
          encoded = xor_transform(f.read_bytes())
          (dst / f.name).write_bytes(encoded)
          print(f"Encoded {f.name} -> {dst / f.name}")

  if __name__ == "__main__":
      main()
  ```

- [ ] **Step 8: Commit**

  ```bash
  git add game/scripts/content/bank_codec.gd game/scripts/content/bank_reader.gd game/tests/test_bank_codec.gd tools/encode_banks.py
  git commit -m "$(cat <<'EOF'
  feat(content): bank codec XOR encryption for release builds

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

---

## Phase 5 — Polish & Playtest

### Task 12: Full Gate + Final Verification

**Prerequisite:** All tasks 1-11 merged
**Branch:** Same integration branch
**Files:** No new files — verification only

- [ ] **Step 1: Run ALL Godot test suites**

  Run each test file one by one. Expected output token for each:

  | Test file | Expected output |
  |-----------|----------------|
  | `test_shape_fingerprint.gd` | `SHAPE_FINGERPRINT_PASS` |
  | `test_board_solver.gd` | `CORE_BOARD_SOLVER_PASS` |
  | `test_candy_rules.gd` | `CORE_CANDY_RULES_PASS` |
  | `test_play_session.gd` | `INPUT_PLAY_SESSION_PASS` |
  | `test_campaign_runtime.gd` | `CAMPAIGN_RUNTIME_PASS` |
  | `test_session_store.gd` | `STATE_SESSION_PASS` |
  | `test_progress_manager.gd` | `STATE_PROGRESS_PASS` |
  | `test_bank_reader.gd` | Expected PASS token |
  | `test_bank_codec.gd` | `BANK_CODEC_PASS` |
  | `test_colorblind.gd` | `COLORBLIND_PASS` |
  | `test_pace_adjuster.gd` | `PACE_ADJUSTER_PASS` |
  | `test_dual_slot_store.gd` | Expected PASS token |
  | `test_config_store.gd` | Expected PASS token |
  | `test_touch_decoder.gd` | Expected PASS token |
  | `test_feedback.gd` | Expected PASS token |
  | `test_screens.gd` | Expected PASS token |
  | `test_integration.gd` | Expected PASS token |

- [ ] **Step 2: Run Python validators**

  ```bash
  python -B tools/validate_content.py
  python -B tools/verify.py --godot <godot_path>
  ```
  Expected: All PASS.

- [ ] **Step 3: Clean-room gate — full scan**

  ```bash
  rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
  ```
  Expected: 0 matches.

  ```bash
  rg -n "extracted_reusable" game/scripts/ game/tests/
  ```
  Expected: 0 matches.

- [ ] **Step 4: Line count audit**

  ```bash
  wc -l game/scripts/**/*.gd | sort -rn | head -20
  ```
  Verify: NO file exceeds 300 lines.

- [ ] **Step 5: Update `docs/STATUS.md`**

  Add section documenting completed system upgrade phases and remaining items (device QA, playtest).
