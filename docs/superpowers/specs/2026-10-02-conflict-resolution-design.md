# CanDoKu Rebuild — Conflict Resolution & Unified Design Spec

**Date:** 2026-10-02
**Purpose:** Giải quyết 10 xung đột giữa GDD, master plan và module plans. Thiết kế thống nhất làm cơ sở cho việc cập nhật tất cả tài liệu.

## Authority Hierarchy

| Source | Authority |
|---|---|
| GDD (02, 05, 10) | Game rules, player-facing behavior, reasoning model |
| Master plan | Implementation architecture, interface contracts |
| Module plans | Implementation details — must match both GDD and master |

## Resolution Decisions

### R01. Cell States — 5 states + given flag

**GDD hiện tại:** 4 states (empty/x/x_error/candy) + given flag
**Master plan:** 6 CellKind (BLANK/MARK/CANDY/WRONG/GIVEN/LOCKED)
**Quyết định:** GDD mở rộng thành **5 states** + given flag:

| GDD state | CellKind | Mô tả |
|---|---|---|
| `empty` | BLANK (0) | Ô trống |
| `x` | MARK (1) | Ghi chú X do player |
| `x_error` | WRONG (3) | X đỏ do TryCandy sai |
| `candy` | CANDY (2) | Kẹo tìm đúng |
| `locked` | LOCKED (5) | Auto-mark X do hệ thống (NEW) |
| (flag) | GIVEN (4) | Candy cho trước — code dùng CellKind riêng để đơn giản hóa logic |

**Session storage:** given cells lưu `"empty"` và ghép từ level data khi render (GDD giữ nguyên). `locked` cells lưu `"locked"` trong session.

### R02. TryCandy Validation — Solution-based

Đúng/sai dựa vào `solution[row] == col` (GDD 02 GR-15).
`detect_clash()` chỉ dùng cho:
- Giải thích lý do sai (GR-20)
- Auto-mark computation

### R03. Helper Semantics

```
is_empty(k) -> k == BLANK           # chỉ BLANK, không bao gồm MARK
is_available(k) -> k in {BLANK, MARK}  # player có thể tương tác
is_placed(k) -> k in {CANDY, GIVEN}    # có kẹo
is_candy(k) -> k in {CANDY, GIVEN}     # solver treats both as candy
is_locked(k) -> k in {GIVEN, LOCKED}   # immutable
is_cross(k) -> k in {MARK, WRONG, LOCKED}  # hiện dấu X
label(k) -> lowercase string          # "blank", "mark", etc.
```

### R04. Board Data Type — 2D Array

`board: Array` — NxN, mỗi phần tử là CellKind int. Truy cập: `board[row][col]`.
Bỏ Dictionary `cells` với key `"row,col"`. Tất cả module dùng Array.

### R05. GDD Terminology

| Dùng | Không dùng |
|---|---|
| `hearts` | lives |
| `mistake_count` | errors |
| `Phase.FAILED` | "Lost" |
| `Phase.WON` | "Won" → giữ |
| `Phase.ACTIVE` | "Playing" → giữ |

### R06. Auto-mark System (NEW in GDD)

Khi đặt candy đúng hoặc khi board init có givens:
1. Tính tất cả ô BLANK cùng row/col/zone/diagonal với candy
2. Đặt chúng thành LOCKED
3. LOCKED cells hiện dấu X mờ, player không xóa được
4. Undo candy → undo tất cả LOCKED trong cùng group

### R07. Grouped Undo (NEW in GDD)

ActionRecorder lưu groups: `[{row, col, before, after, source}]`
- Source.USER: player action (mark_x, try_candy)
- Source.SYSTEM: auto-mark locks

Candy + auto-marks = 1 undo group. Undo pop cả group.
GDD 02 GR-32 mở rộng: UndoX hoàn nguyên action X gần nhất HOẶC candy+locks gần nhất.

### R08. Solver Design — Reference-enhanced

**Technique mapping:**

| GDD | Reference | Mô tả | Playtest |
|---|---|---|---|
| S1 | R1 Mark | Loại trừ: row/col/zone/diagonal từ kẹo đã biết | ✓ (auto-mark, không step riêng) |
| S2 | R1 Placement | Naked single: 1 ứng viên trong unit | ✓ |
| S3 | R2 (4 modes) | Lock intersection: zone→row, zone→col, row→zone, col→zone | ✓ |
| S4 | R3/R4 | Subset locking (k units lock k units) | Future |
| S5 | R5 Chain | Contradiction/proof by contradiction | Future |

**Solve loop (from reference):**
```
repeat:
    S1: auto-mark all known candy → update P
    S2: find naked single in any row/col/zone → place candy, loop
    S3: find lock intersection (4 modes) → eliminate cells, loop
    (S4/S5: future)
    if none: STUCK
until all candy placed or STUCK
```

**Key: S1 mark luôn chạy trước mỗi vòng** — đảm bảo maximum constraint propagation.

**S3 — 4 sub-modes (from reference R2):**
- S3a (zone→row): P(zone) ⊆ row → loại ô khác zone trong row
- S3b (zone→col): P(zone) ⊆ col → loại ô khác zone trong col
- S3c (row→zone): P(row) ⊆ zone → loại ô zone ở row khác
- S3d (col→zone): P(col) ⊆ zone → loại ô zone ở col khác

**compute_cell_ranks (from reference):**
Start empty board, solve loop tracking `current_max` technique.
Each S2 placement records `rank = current_max`, then reset to 1.
Unsolved cells get fallback rank 4.

**next_hint logic:**
1. Rebuild K from givens + found candy (ignore X/x_error per GDD)
2. Run S1 to build P
3. Try S2 → if found, return hint
4. Try S3 → if found, apply elimination and try S2 again
5. Return hint with unit_type/unit_id for progressive reveal

**Solution param usage:**
- Solver logic (S1/S2/S3) reasons from board state only
- solution used for: compute_cell_ranks, solve_sequence, safety assert
- NOT used to choose hint target

### R09. Progressive Hint (NEW in GDD)

Click 1: highlight unit (zone/row/col where hint was found)
Click 2+: narrow to specific cell
Cost from pace data hintCosts.

GDD 02 GR-21-24 mở rộng:
- GR-21: Mỗi lượt bắt đầu với budget hint (từ pace hintCosts)
- Hint progressive reveal qua nhiều click
- Mỗi click tiêu 1 unit từ budget

### R10. Event Contract — Godot Signals

```gdscript
# play_session.gd signals
signal candy_found(row: int, col: int, region: String)
signal mistake_made(row: int, col: int, reason: String)
signal heart_lost(remaining: int)
signal auto_marked(cells: Array)
signal level_won()
signal level_failed()
```

### R11. verify_level() Scope

| Layer | Function | Returns |
|---|---|---|
| Core (M01) | `candy_rules.verify_level()` | bool — structural: size, regions, solution, adjacency, zone uniqueness |
| Content (M03) | `level_validator.gd` | detailed — full schema v4, trace, givens, uniqueness |
| Pipeline (M10) | `validate_levels.py` | release gate — campaign 30 levels |

### R12. Bank Level Schema vs GDD Level v4

Bank levels (M03/M10) là **superset** của level v4:
- GDD v4 fields (bắt buộc): `schemaVersion`, `id`, `order`, `size`, `regions`, `solution`, `givens`, `difficulty`, `tags`, `logicTrace`
- Bank-only fields (pipeline metadata): `seed`, `steps`, `profile`, `rating`, `pidHash`

`bank_reader.get_level()` trả level v4 cho gameplay consumers. Bank-only fields chỉ dùng trong pipeline (generate, validate, dedup). `level_validator.check_bank_level()` kiểm tra bank-specific fields; `check()` kiểm tra v4.

M10 generator tạo raw levels → `convert_to_bank.py` đóng gói thành bank format. Generator script mới (`generate_bank.py`) thay thế legacy `generate_levels.py` với CLI `--size/--rank/--count/--output`.

### R13. Given Serialization Contract

| Phase | Representation |
|---|---|
| Runtime board | `CellKind.GIVEN` (int 4) |
| Session JSON | `"empty"` — given-ness inferred from `level.givens` |
| Init (new/restore) | Read `level.givens` → set `board[r][c] = GIVEN` → apply auto-marks |
| Save | GIVEN cells → write `"empty"` in cells array |

M04 `play_session._init()` places GIVEN from level data. `to_save_data()` maps GIVEN→"empty". `from_save_data()` restores GIVEN from level data.

### R14. Undo Stack (not single slot)

GDD "Undo hoàn nguyên action gần nhất" = undo pops **one group** per press. Implementation uses **stack** (MAX_DEPTH := 100) because:
- Grouped undo needs it (candy + auto-marks = 1 group)
- Multi-step undo improves player experience
- GDD wording "Undo một bước" = one group per press, not one total slot

Không có Redo. Stack persists in session via `ActionRecorder.to_save_data()`.

### R15. Double-tap Timing — 350 ms

GDD 02/05 nói 280 ms, plans nói 350 ms. GDD ghi "thông số cần playtest".
**Quyết định: 350 ms** — khớp với plans, forgiving hơn cho mobile. Cập nhật GDD 02, 03, 05 và `interactions.sample.json`.

### R16. M02 API — Reconcile with Master

Master contracts win. Reconcile:
- `SessionStore.load_session(level_id, expected_hash)` — cần params để verify hash (M02 plan đúng, master thiếu params)
- `DualSlotStore.read_json()` → trả `{ok, data, recovered, reason}` (M02 plan detail hơn, giữ)
- `ProgressManager.load()/save()` — master và plan đã khớp tên

### R17. M03 API — Return Types

- `level_validator.check()` → trả `{ok: bool, errors: Array[String]}` (plan đúng, master nói bool là quá đơn giản)
- `bank_reader.load_bank()` → trả `{ok: bool, errors: Array[String]}` (plan đúng)
- Cập nhật master contracts cho M03.

### R18. Phase.FAILED Everywhere

| Location | Current | Fix |
|---|---|---|
| Design spec R05 | FAILED | ✓ |
| Master plan | FAILED | ✓ |
| M04 play_session | **LOST** | → FAILED |
| M04 tests | "Lost" | → "failed" |
| GDD 02 | "Failed" | ✓ |
| GDD 05 session | "failed" | ✓ |
| M07 nav_controller | Screen.LOSE | giữ (screen name ≠ phase) |

### R19. Hint Flow — Separation of Concerns

```
M01 board_solver.progressive_hint(board, size, regions, solution, max_clicks)
    → returns {stage, highlight, text}
    → solver reasons from board, NOT from budget

M04 play_session.use_hint()
    → hints_used += 1 (session tracking, no budget enforcement)

M08 puzzle_screen._on_hint()
    → manages _hint_click_count (UI state, not persisted in session)
    → checks pace.hintCosts for budget
    → calls board_solver.progressive_hint(max_clicks=_hint_click_count)
    → resets on candy_found / restart
```

Budget enforcement = M08 (UI). Solver = stateless. Session = counter only.
`hints_used` in session = total hint clicks used (for scoring/analytics).
`_hint_click_count` in UI = current hint progressive reveal state (resets per hint target).

### R20. Test Fixture M01 — VALID

`regions=["AABB","ABBB","CCBB","CCDB"], solution=[1,3,0,2]`:
- Row 0 col 1 → `"AABB"[1]` = **A** (not B)
- Row 1 col 3 → `"ABBB"[3]` = B
- Row 2 col 0 → `"CCBB"[0]` = C
- Row 3 col 2 → `"CCDB"[2]` = D

Mỗi zone đúng 1 candy: A=1, B=1, C=1, D=1. **Fixture hợp lệ.**

### R21. Replay Campaign — Gated

`replay_campaign()` giữ trong API nhưng **chỉ available sau `campaign_complete`**. UI "Replay from L01" chỉ hiện trên result screen của level cuối. RST-003 (4-level test build) là ngoại lệ riêng, không áp dụng cho playtest 30.

### R22. Infinite Mode — Future Only

BankCursor class giữ (hạ tầng cho transform x8 content multiplication). Nhưng:
- Loại infinite-specific tests khỏi M07 R1 checklist
- Mark rõ `"(future)"` cho infinite sections
- Không implement infinite UI trong R1

### R23. Branch Naming — AGENTS.md Wins

Master plan preflight `codex/rebuild-module-NN` → sửa thành `<type>/<scope>-<mô-tả>` theo AGENTS.md. Ví dụ: `feat/m01-core`, `feat/m03-content`.

## Impact Summary (Round 2)

| Document | Changes R12-R23 |
|---|---|
| Master plan | Branch naming, M02/M03 contracts, given serialization note, hint API |
| M04 plan | Phase.LOST→FAILED, errors→mistake_count, clash_label→reason |
| M07 plan | Replay gated, infinite tests removed from R1 |
| M03 plan | Bank→level v4 mapping note, validator scope clarification |
| M10 plan | Generator CLI note (new vs legacy) |
| GDD 02/03/05 | 280ms→350ms |
| interactions.sample.json | 280→350 |

## Resolution Decisions — Round 3 (C01–C26)

### R24. CandyRules API — Pure Logic, Session Owns State (C01)

**Xung đột:** Master dùng `attempt_candy(level, board, row, col)` trả `{valid, reason, auto_marks}`. M01 dùng `attempt_candy(board, regions, solution, hearts, mistake_count, row, col)` trả `{board, hearts, mistake_count, phase, events, reason, auto_marks}`.

**Quyết định:** M01 approach (functional pure). candy_rules nhận explicit params, trả full computed state. Đây là pure function (không mutation), play_session apply kết quả. Master contract CẬP NHẬT theo M01:
- `attempt_candy(board, regions, solution, hearts, mistake_count, row, col) -> Dictionary`
- Return: `{board, hearts, mistake_count, phase, events, reason, auto_marks}`
- Bỏ `check_win()` riêng — phase "won"/"failed" đã có trong return
- `detect_clash(regions, board, a, b)` — tham số regions tách khỏi level dict
- `compute_auto_marks(board, regions, candy_row, candy_col)` — tách khỏi level
- `compute_all_auto_marks(board, regions)` — tách khỏi level
- `can_place(board, regions, row, col)` — thuộc CandyRules (không phải BoardSolver)

### R25. BoardSolver API — Reconcile Master with M01 (C02)

**Quyết định:** M01 plan là chuẩn, master cập nhật:
- `next_hint(board, size, regions, solution)` — dùng `regions` không `zones`, return `explanation` không `reason`
- `progressive_hint(board, size, regions, solution, max_clicks)` — 5 params (M01), không 6 (master thừa `click`)
- `compute_cell_ranks(size, regions, solution, givens)` — 4 params (M01), không `(board, size, zones, solution)` (master)
- `can_place` thuộc **CandyRules** (M01), không BoardSolver (master)
- `solve_sequence(size, regions, solution)` — dùng `regions`

### R26. Hint Consumer M08 — Proper Flow (C03)

**Quyết định:** M08 đọc `hintCosts` từ pace (Array), tính `max_clicks` từ đó, truyền int vào `progressive_hint()`. HintResult từ solver trả `{stage, highlight, text}` — M08 dùng `stage` để quyết định `highlight_unit()` hay `highlight_cell()`. Fix M08:
- `progressive_hint()` nhận `max_clicks: int`, không phải Array hintCosts
- `highlight_unit(unit_type, unit_id)` — `unit_id` là String (zone label "A"-"L") hoặc int (row/col index). M08 cần xử lý cả hai
- NoHint: khi `progressive_hint()` trả `{found: false}`, disable hint button

### R27. Persistence API — M02 Plan Wins (C04)

**Quyết định:** Module plan M02 có thiết kế chi tiết hơn. Master contract cập nhật:
- `DualSlotStore`: `write_json(data)/read_json()` (không `save/load`), constructor `(directory, file_name)` không `(store)`
- `ProgressManager`: constructor `(profile_dir)`, `load()` trả `{ok, data, recovered, reason}`, `save()` trả bool, `advance_level(level_id, score_data, level_order)` trả `{ok, data}`
- `SessionStore`: constructor `(profile_dir)`, `clear()` (không `clear_session`), `has_pending` thêm vào M02 nếu chưa có
- `ConfigStore`: constructor `(profile_dir)`, dùng `DualSlotStore` internal

### R28. Config Keys — snake_case Everywhere (C05)

**Quyết định:** snake_case cho cả API và JSON:
- `reduced_motion`, `high_contrast`, `large_text` (master)
- M02 plan update: `reducedMotion` → `reduced_motion`, v.v.
- JSON keys = API keys = snake_case

### R29. PlaySession Signals — Master Contract (C06)

**Quyết định:** Master contract đầy đủ (đã đúng ở R10):
- `candy_found(row, col, region)` — 3 params. M04 cập nhật thêm `region`
- `heart_lost(remaining)` — thêm vào M04 plan
- M08 kết nối đúng signatures

### R30. Content API — M03 Plan Wins (C07)

**Quyết định:** M03 return types chi tiết hơn. Master cập nhật:
- `load_bank(size) -> Dictionary {ok, errors}` (không `bool`)
- `load_pace(size) -> Dictionary {ok, errors}` (không `bool`)
- `validate_against_bank(bank, size) -> Array[String]` (M03 thêm size param)
- `assign_colors(size, zones, palette) -> Dictionary` (M03 design, không master's `(zone_grid, zone_count)`)

### R31. M07 Contract in Master — Add (C08)

**Quyết định:** Thêm M07 contracts vào master plan:
```
# campaign_runtime.gd
func _init(bank: BankReader, pace: PaceReader, progress: ProgressManager, session_store: SessionStore)
func boot() -> Dictionary  # {ok, level, pace_entry, error}
func current_level() -> Dictionary
func current_pace() -> Dictionary
func advance(score_data: Dictionary) -> Dictionary  # {ok, next_level, campaign_complete}
func replay_campaign() -> void  # only after campaign_complete
signal campaign_complete()
```

### R32. Undo on Wrong Try — Clears Stack (C09)

**Quyết định:** GDD 02 GR-33 rõ ràng: "TryCandy sai xóa stack". Đây là ranh giới:
- Thử sai → WRONG cell cố định, giảm tim, **xóa toàn bộ undo stack**
- Không record sai vào stack, không cho undo sai
- M04 plan cập nhật: `try_candy()` khi sai → `recorder.clear()`
- Test: sau thử sai, `can_undo()` = false

### R33. Undo Stack — Runtime-only, Not Persisted (C10)

**Quyết định:** GDD TECH-08: "Preview/khe Undo không lưu. Back To Home/app đóng xóa khe."
- `ActionRecorder.to_save_data()` và `from_save_data()` → **XÓA** khỏi M04 plan
- Session JSON không chứa recorder stack
- Khi restore session, stack rỗng (player không thể undo actions từ phiên trước)
- GDD QA-55 "Undo không đổi candy" → cập nhật: Undo CAN revert correct candy (grouped undo), nhưng CANNOT modify candy directly without undo. Phân biệt: grouped undo ≠ trực tiếp sửa candy

### R34. Double-tap Confirmation — At Release, Not Begin (C11)

**Quyết định:** GDD yêu cầu lần chạm thứ hai không kéo mới TryCandy. Emit at second-down (begin) là sai vì drag detection chưa xong.
- M04 `touch_decoder.begin()`: nếu detect double-tap, **đợi** — flag `_pending_double_tap`
- `finish()`: nếu `_pending_double_tap` và không drag → emit `cell_double_tapped`
- `move()`: nếu `_pending_double_tap` và vượt ngưỡng kéo → cancel double-tap, commit first tap, start drag
- Test bổ sung: tap→second-down→drag→release → KHÔNG TryCandy

### R35. Session Schema — GDD05 is Authority (C12)

**Quyết định:** GDD05 session v3 là chuẩn:
- `tutorialSeenIds` ở root (GDD05), không trong `tutorialState` (M02). M02 cập nhật
- `cells` là flat Array N² strings (GDD05), không `{}` (M02). M02 cập nhật
- `status` field bắt buộc: `"playing"` | `"failed"` (GDD05). M02 thêm vào session schema
- M02 `new_session()` phải output đúng schema GDD05

### R36. PlaySession ↔ Session v3 Adapter (C13)

**Quyết định:** M04 `to_save_data()` phải output session v3 format:
- `board` (NxN CellKind) → `cells` (flat Array strings): BLANK→"empty", MARK→"x", CANDY→"candy", WRONG→"x_error", GIVEN→"empty", LOCKED→"locked"
- `mistake_count` → `mistake_count` (same)
- `elapsed_ms` → `elapsedMs` (JSON convention)
- `phase` → `status`: ACTIVE→"playing", FAILED→"failed" (WON không lưu session)
- `hearts`, `hints_used`, `puzzleHash`, `levelId` → direct mapping
- Undo stack KHÔNG lưu (R33)
- Auto-marks KHÔNG lưu riêng — recompute from candy+givens khi restore

### R37. Hint Budget — Progressive is Standard (C14)

**Quyết định:** Progressive hint budget từ pace là chuẩn (đã thiết kế trong R09). Fix GDD remnants:
- GR-24 bỏ `hintCount=1` — budget đến từ pace `hintCosts`, mỗi click tiêu 1 unit
- GDD lifecycle "cấp lại một Hint" → "cấp lại budget hint đầy" (Retry/Restart)
- GDD README D-05 đã đúng: progressive reveal
- QA-14/56 "một Hint/lượt" → cập nhật: budget-based progressive hint
- NoHint: solver không tìm được hint hợp lệ, không tiêu budget

### R38. Bank Levels — ID from Playlist, Not Bank (C15)

**Quyết định:** Bank levels là raw puzzle data, KHÔNG có `id/order/difficulty/tags/schemaVersion`. Các fields đó đến từ **playlist**:
- `demo_30.json` playlist entry: `{label, size, rank, index, difficulty}`
- `bank_reader.get_level()` trả bank-level fields (regions, solution, givens, logicTrace, seed, steps, profile, rating, pidHash)
- Campaign runtime tổng hợp: bank data + playlist metadata → level dict cho gameplay
- Level ID = playlist label (L01, L02, ...)
- `puzzleHash` tính từ bank data, không phụ thuộc ID
- Converter M10 không cần thêm v4 fields vào bank

### R39. Fixture M03 — Invalid, Replace (C16)

**Quyết định:** Fixture `regions=["DDAC","BCDD","DDCD","DDDC"]`, `solution=[1,3,0,2]`:
- Row 0 col 1 → D, Row 1 col 3 → D → hai candy trong zone D → **VI PHẠM**
- **Thay bằng** fixture đã validate: `regions=["AABB","ABBB","CCBB","CCDB"], solution=[1,3,0,2]` (fixture M01 hợp lệ)
- M03 test `_sample_bank_level()` đã dùng fixture đúng — OK
- Bank schema example trong M03 cần update

### R40. logicTrace — Required for Release, Optional During Dev (C17)

**Quyết định:**
- `level_validator.check()`: logicTrace **optional** — cho phép dev/testing không có trace
- `level_validator.check_bank_level()`: logicTrace **required** — bank levels cần proof
- Release/playtest gate (M10 validate): trace bắt buộc, validate đầy đủ S2/S3 steps
- M03 plan remove "logicTrace optional" từ check_bank_level, giữ "optional" ở check()

### R41. CLI Generator — Use Actual Tool (C18)

**Quyết định:** M10 CLI commands cập nhật theo tool thật:
- Generator: `python -B GDD/tools/generate_levels.py --profile <file> --out <dir> --exclude <file>` (actual CLI)
- Output: thư mục chứa `{levels: [...]}` JSON files
- Converter: `python -B GDD/tools/convert_to_bank.py` đọc `levels` envelope, không list trực tiếp
- M10 Step 1-2 commands sửa lại

### R42. Pace rSeq — Extract from Trace (C19)

**Quyết định:** `generate_pace.py` phải xử lý trace dicts, không int:
- Mỗi trace step có `rule: "S2"|"S3"` → map S2→1, S3→2
- `rSeq` = Array[int] từ trace steps
- Nếu trace rỗng: fallback `rSeq = [1] * steps`
- `hintCosts[i] = max(1, rSeq[i])` — S3 steps cost 2 clicks
- Fix code: `r_seq = [{"S2":1,"S3":2}.get(step.get("rule","S2"), 1) for step in trace]`

### R43. Bank Count — Single Manifest (C20)

**Quyết định:** Playlist demo_30.json là nguồn duy nhất:
- 12 easy (rank 1) + 10 medium (rank 2) + 8 hard (rank 3) = 30 (playlist đã định)
- Generator phải sinh ít nhất: 12 rank1, 10 rank2, 8 rank3
- M10 Step 1 cập nhật: 12/10/8 (không 15/10/5)
- Không sinh thừa không cần thiết cho playtest

### R44. Difficulty Labels — GDD Scope (C21)

**Quyết định:** Playtest dùng tutorial/easy/medium (GDD-approved). "hard" yêu cầu S3 proof verified:
- L01-L02: `"tutorial"` (guided, rank 1)
- L03-L12: `"easy"` (rank 1, S2-only)
- L13-L22: `"medium"` (rank 2, S2-heavy, some early S3)
- L23-L30: `"medium"` (rank 3, nhưng chưa có profile25-30 verified S3 → không dùng "hard")
- "hard" chỉ dùng khi có profile được duyệt + S3 proof verified

### R45. CLI Validator — Document Actual (C22)

**Quyết định:** M10 validate commands sửa theo tool thật:
- `python -B GDD/tools/validate_levels.py <file>` — positional arg, đọc `{levels: [...]}` envelope
- `--release` flag cho release gate checks
- Bank/pace/playlist validation cần adapter script mới hoặc extension
- Gate 30-level cần tool mới, không reuse gate 24-level

### R46. Replay Campaign30 — Disabled (C23)

**Quyết định:** Playtest 30 không có replay. Đã resolved ở R21 nhưng cần fix thêm:
- M08 result_screen: `replay_pressed` signal giữ, nhưng button **ẩn** cho campaign30
- M09 integration test case13 (replay): chỉ apply cho fixture-4 test, mark `(skip for campaign30)`
- M10 "Thắng L30 → replay campaign" → sửa thành "Thắng L30 → hiện hoàn thành nội dung"

### R47. Test Discovery — Add Runners or Fix verify.py (C24)

**Quyết định:** Tạo `run_*.gd` wrapper cho mỗi test file:
- `game/tests/run_candy_rules.gd` → extends SceneTree, runs test_candy_rules logic
- Hoặc: update `verify.py` discovery pattern để cũng tìm `test_*.gd`
- Ưu tiên: update verify.py (ít file hơn, DRY)

### R48. File Size Limit — M08 Split (C25)

**Quyết định:** AGENTS yêu cầu ≤300 dòng/file. M08 ước 350 dòng → cần tách:
- `puzzle_screen.gd` (~200 dòng): toolbar, timer, session signals, hint/undo/restart buttons
- `puzzle_board.gd` (~200 dòng): board rendering, cell drawing, touch delegation
- `puzzle_input.gd` (~100 dòng): input → session delegation, progressive hint state
- M08 plan cập nhật: 3 files thay 2 cho gameplay

### R49. Pre-M10 Fixtures — Test-provided (C26)

**Quyết định:** M03/M07/M09 tests dùng **test fixtures** nhỏ (1-3 levels), không phụ thuộc M10:
- M03 test: `_sample_bank_level()` tự tạo valid bank dict inline
- M07 test: tiny campaign 3-level fixture inline
- M09 integration: fixture từ M03 test data, không từ M10 generated banks
- M10 sinh 30-level bank là production content, không cần cho unit/integration tests

## Impact Summary — Round 3

| Document | Changes R24-R49 |
|---|---|
| Master plan contracts | Full rewrite M01-M03 contracts, add M07 contract, fix API signatures |
| M01 plan | No change needed (M01 is source of truth) |
| M02 plan | Config keys snake_case, tutorialSeenIds at root, cells flat Array, add status |
| M03 plan | Fix bank example fixture, logicTrace required for bank, assign_colors params |
| M04 plan | Remove recorder persist, add heart_lost signal, candy_found 3 params, double-tap at release |
| M08 plan | Split puzzle files ≤300, fix hint consumer flow, hide replay for campaign30 |
| M10 plan | Fix CLI commands, bank counts 12/10/8, difficulty labels, pace rSeq from trace |
| GDD 02 | Fix GR-24 hint budget, lifecycle hint text |
| GDD 05 | Confirm session schema (already correct) |
| GDD 07 | Update QA-55 undo, QA-14/56 hint |
| verify.py | Update discovery to include test_*.gd |

## Impact Summary

| Document | Changes |
|---|---|
| GDD 02 | +locked state, +auto-mark GR, +grouped undo, +progressive hint |
| GDD 05 | +rebuild module architecture, +event signals, +session locked field |
| GDD 01 | +auto-mark in loop, +locked mention |
| GDD 03 | +auto-mark animation, +locked rendering, +progressive hint UX |
| GDD 04 | minor — bank/pace/transform refs |
| GDD 06 | +locked visual, +auto-mark animation timing, +SFX rate limiting |
| GDD 07 | +test strategy for rebuild modules |
| GDD README | D-03→5 states, D-04→grouped undo, D-05→progressive hint |
| Master plan | Fix is_empty, hearts terminology, solver contracts |
| 01-core | Array board, solution-check TryCandy, enhanced solver, GDD terms |
| Other plans | Terminology alignment |
