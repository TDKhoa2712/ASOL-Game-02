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
