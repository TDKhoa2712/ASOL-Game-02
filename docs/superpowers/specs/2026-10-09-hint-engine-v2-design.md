# Hint Engine v2 — Design Specification

**Dự án:** CanDoKu v1.0.1  
**Ngày:** 2026-10-09  
**Mục tiêu:** Nâng cấp hint engine từ progressive 2-stage đơn giản thành Explainable Logic Solver đầy đủ — dạy logic thay vì mớm đáp án.

---

## 1. Tổng quan & Triết lý

### 1.1 Hiện trạng

Hint engine hiện tại hoạt động theo mô hình 2-stage đơn giản:
1. Click 1: highlight toàn bộ unit (row/col/zone) — "Nhìn kỹ vùng này"
2. Click 2: highlight ô cụ thể — "Đặt candy ở đây"

**Vấn đề:**
- Không giải thích TẠI SAO ô đó là đáp án
- Không phát hiện khi player đánh X sai lên ô solution
- Không gợi ý đánh X loại trừ (chỉ gợi ý đặt candy)
- Không chống spam click khi animation đang chạy
- Không có DDA pre-fill cho player thua liên tiếp
- Chain contradiction không hiển thị quá trình suy luận

### 1.2 Mục tiêu v2

Biến hint engine thành **bộ máy suy luận có giải thích**, với nguyên tắc:

1. **Human-Like Reasoning:** Hint luôn dùng kỹ thuật đơn giản nhất có thể (elimination → single → lock → subset → chain)
2. **Min-Step Explanation:** Chain chọn chuỗi ngắn nhất (min depth)
3. **Correction First:** Phát hiện X sai trước khi gợi ý tiếp
4. **No Stale Hints:** Chỉ gợi ý khi có thông tin MỚI (`has_new` guard)
5. **Dual-Purpose:** Cùng engine dùng cho runtime hint VÀ offline level analysis

### 1.3 Phạm vi thay đổi

| Thành phần | Hành động | Lý do |
|---|---|---|
| `hint_engine.gd` | **MỚI** | Orchestrator thay thế logic trong `puzzle_screen._on_hint()` |
| `hint_mutex.gd` | **MỚI** | Chống spam, cooldown |
| `hint_highlight_layer.gd` | **MỚI** | Ghost cells + chain badges trên Control layer riêng (trong board_card) |
| `pre_candy_decider.gd` | **MỚI** | DDA pre-fill cho player thua liên tiếp |
| `solver_techniques.gd` | **SỬA NHẸ** | Bổ sung chain detail output (steps, contra_type, contra_index) |
| `board_solver.gd` | **SỬA NHẸ** | Thêm `find_mark_hint()`, `find_wrong_mark()` |
| `hint_overlay.gd` | **VIẾT LẠI** | Thêm Apply/Dismiss/Detail buttons, banner theo strategy |
| `puzzle_screen.gd` | **SỬA** | Đổi flow sang `hint_engine` + mutex |
| `puzzle_layout.gd` | **SỬA NHẸ** | Thêm hint_highlight_layer vào board_card |
| `play_session.gd` | **SỬA NHẸ** | Thêm `clear_mark()`, `apply_marks()` cho hint apply |
| `sfx_catalog.gd` | **SỬA NHẸ** | Thêm `HINT_APPLY`, `HINT_DISMISS`, `HINT_WRONG_MARK` |

---

## 2. Kiến trúc tổng thể

### 2.1 Sơ đồ luồng

```
Player nhấn Hint
    │
    ▼
HintMutex.try_acquire("hint")
    │ false → bỏ qua
    ▼ true
HintEngine.find_hint(board, size, regions, solution)
    │
    ├─► Bước 0: find_wrong_mark() — X đè lên solution?
    │     → trả WRONG_MARK
    │
    ├─► Bước 1: find_mark_hint() — có ô cần đánh X quanh candy?
    │     → trả MARK_NEIGHBORS  (has_new guard)
    │
    ├─► Bước 2: find_single_hint() — unit chỉ còn 1 ứng viên?
    │     → trả SINGLE_CANDIDATE + ô đặt candy
    │
    ├─► Bước 3: find_lock_hint() — zone↔line intersection?
    │     → trả LOCK_INTERSECTION + ô cần X (has_new guard)
    │
    ├─► Bước 4: find_subset_hint() — k zones khóa k lines?
    │     → trả LOCKED_SUBSET + ô cần X (has_new guard)
    │
    ├─► Bước 5: find_chain_hint() — contradiction chain?
    │     → trả CONTRA_CHAIN + chain_detail (has_new guard)
    │
    └─► Bước 6: fallback — reveal 1 candy từ solution
          → trả FALLBACK

    ▼
PuzzleScreen nhận HintResult
    │
    ├─► HintHighlightLayer hiển thị ghost cells + animations
    ├─► HintOverlay hiển thị banner + buttons (Apply/Dismiss/Detail)
    └─► SFX + Vibration
    
    ▼
Player chọn Apply / Dismiss
    │
    ├─► Apply: session thực thi nước đi, dọn layers
    └─► Dismiss: chỉ dọn layers
    
    ▼
HintMutex.release("hint") + cooldown 0.5s
```

### 2.2 Dependency graph

```
puzzle_screen.gd
    ├── hint_engine.gd (static, pure logic)
    │     ├── board_solver.gd (static, pure logic)
    │     │     └── solver_techniques.gd (static, pure logic)
    │     └── candy_rules.gd (static, pure logic)
    ├── hint_mutex.gd (instance, stateful)
    ├── hint_overlay.gd (Control node)
    └── hint_highlight_layer.gd (Control node, trong board_card)

pre_candy_decider.gd (static, pure logic)
    └── board_solver.gd
```

Không có autoload. `hint_mutex`, `hint_overlay`, `hint_highlight_layer` được tạo và inject qua `puzzle_layout.gd` → `puzzle_screen.setup()`.

---

## 3. HintResult — Cấu trúc dữ liệu chuẩn

Mọi hàm tìm hint đều trả về Dictionary theo schema sau:

```gdscript
# HintResult Dictionary schema
{
    "found": bool,              # true nếu tìm thấy gợi ý
    "strategy": String,         # "WRONG_MARK" | "MARK_NEIGHBORS" | "SINGLE_CANDIDATE"
                                # | "LOCK_INTERSECTION" | "LOCKED_SUBSET"
                                # | "CONTRA_CHAIN" | "FALLBACK"
    "action": String,           # "CLEAR_MARK" | "PLACE_MARKS" | "PLACE_CANDY" | "REVEAL"
    "target_cell": Array,       # [row, col] — ô chính cần thao tác
    "highlight_cells": Array,   # [[r,c], ...] — ô cần pulse vàng (giải thích unit)
    "eliminated_cells": Array,  # [[r,c], ...] — ô sẽ bị đánh X khi Apply
    "explanation_key": String,  # key localization: "hint.wrong_mark", "hint.single_row", ...
    "explanation_params": Array, # tham số điền vào text: [row_num, zone_name, ...]
    "unit_type": String,        # "row" | "col" | "zone" | "" — đơn vị suy luận chính
    "unit_id": Variant,         # int (row/col index) hoặc String (zone letter)
    "chain_detail": Dictionary, # chỉ có khi strategy == "CONTRA_CHAIN":
    # {
    #     "hypothesis_cell": [r, c],  # ô giả thuyết
    #     "depth": int,               # số bước lan truyền
    #     "steps": [[r,c], ...],      # ô bị ép theo thứ tự
    #     "contra_type": String,      # "row" | "col" | "zone"
    #     "contra_index": Variant,    # index/letter của unit bị cạn
    # }
}
```

---

## 4. Module mới: `hint_engine.gd`

**File:** `game/scripts/core/hint_engine.gd`  
**Kế thừa:** `RefCounted`  
**Kích thước mục tiêu:** ~250 dòng  
**Tính chất:** Static functions only, pure logic, không phụ thuộc Node

### 4.1 API chính

```gdscript
# Hàm duy nhất puzzle_screen cần gọi — tìm hint tốt nhất theo thứ bậc
static func find_hint(board: Array, size: int, regions: Array,
        solution: Array) -> Dictionary:
```

### 4.2 Thứ tự tìm kiếm (hierarchical pipeline)

#### Bước 0: Wrong Mark Detection

```gdscript
static func _find_wrong_mark(board: Array, size: int,
        solution: Array) -> Dictionary:
```

- Quét toàn bộ board: nếu `board[r][c] == MARK` và `solution[r] == c` → trả hint
- **Action:** `CLEAR_MARK` — Apply sẽ set `board[r][c] = BLANK`
- **highlight_cells:** chỉ ô sai `[[r, c]]`
- **explanation_key:** `"hint.wrong_mark"`
- Chỉ trả ô sai ĐẦU TIÊN tìm thấy (quét từ trên xuống, trái qua phải)

#### Bước 1: Mark Neighbors Hint

```gdscript
static func _find_mark_hint(board: Array, size: int,
        regions: Array) -> Dictionary:
```

- Duyệt mọi ô đã có candy (`is_placed`). Với mỗi candy tại (r, c):
  1. Thu thập ô BLANK trên cùng hàng r
  2. Thu thập ô BLANK trên cùng cột c
  3. Thu thập 8 ô kề BLANK
  4. Thu thập ô BLANK cùng zone (luôn bật, không A/B test)
  5. Gộp tất cả thành `to_mark[]`, loại trùng
- **has_new guard:** chỉ trả về nếu `to_mark` chứa ít nhất 1 ô BLANK (tức chưa bị mark). Nếu tất cả đã là MARK → bỏ qua candy này, duyệt candy tiếp
- **Action:** `PLACE_MARKS`
- **target_cell:** candy gốc (r, c) — để highlight giải thích
- **eliminated_cells:** `to_mark` — Apply sẽ set tất cả thành MARK
- **highlight_cells:** `[[r, c]]` (candy gốc) + `to_mark`
- **explanation_key:** `"hint.mark_neighbors"`

#### Bước 2: Single Candidate

Gọi `SolverTechniques._try_single_candidate()` (đã có, không đổi).

- Trước khi gọi, build work_board bằng `_build_work_board()` (xem mục 4.4)
- **Action:** `PLACE_CANDY`
- **target_cell:** ô duy nhất
- **highlight_cells:** toàn bộ ô trong unit (row/col/zone) để player thấy "chỉ còn 1 chỗ"
- **explanation_key:** `"hint.single_row"` / `"hint.single_col"` / `"hint.single_zone"` tùy `unit_type`
- **explanation_params:** `[unit_id]`

#### Bước 3: Lock Intersection

Gọi `SolverTechniques._try_lock_intersection()` trên work_board (đã có, không đổi).

- **has_new guard:** chỉ trả về nếu `eliminated[]` chứa ít nhất 1 ô BLANK trên board THỰC (không phải work_board). Nghĩa là: lọc bỏ những ô mà player đã mark X rồi
- **Action:** luôn `PLACE_MARKS` — R2 bản chất chỉ là loại trừ ô thừa, không đặt candy. Sau khi player Apply (đánh X), lần bấm Hint tiếp theo engine sẽ quay lại Bước 2 và phát hiện Single Candidate mới
- **eliminated_cells:** chỉ gồm ô BLANK trên board thực (đã lọc)
- **highlight_cells:** ô ứng viên trong zone gốc + ô bị loại
- **explanation_key:** `"hint.lock_zone_row"` / `"hint.lock_zone_col"` / `"hint.lock_row_zone"` / `"hint.lock_col_zone"` tùy mode

#### Bước 4: Locked Subsets

Gọi `SolverTechniques._try_locked_subsets()` trên work_board (đã có, không đổi).

- **has_new guard:** tương tự bước 3, lọc eliminated theo board thực
- **Action:** luôn `PLACE_MARKS` — R3/R4 bản chất chỉ là loại trừ, không đặt candy. Lần Hint tiếp theo sau khi Apply sẽ rơi vào Single Candidate nếu đủ thông tin
- **explanation_key:** `"hint.subset_pair"` / `"hint.subset_triple"` / `"hint.subset_quad"`
- **explanation_params:** `[subset_zones]` — danh sách zone letters trong subset

#### Bước 5: Contradiction Chain

Gọi `SolverTechniques._try_contradiction()` (SỬA để trả chain detail).

- **has_new guard:** eliminated chỉ gồm ô BLANK trên board thực
- **Action:** `PLACE_MARKS`
- **target_cell:** ô giả thuyết (sẽ bị X)
- **chain_detail:** xem mục 5 bên dưới
- **explanation_key:** `"hint.chain_short"` (depth ≤ 2) / `"hint.chain_long"` (depth > 2)

#### Bước 6: Fallback

- Tìm ô solution chưa có candy: `solution[r] == c` mà `board[r][c]` chưa placed
- Chọn ô đầu tiên theo thứ tự hàng
- **Action:** `REVEAL`
- **target_cell:** [r, c]
- **explanation_key:** `"hint.fallback"`

### 4.3 has_new guard — chi tiết

```gdscript
# Hàm helper dùng chung cho bước 1, 3, 4, 5
static func _filter_new_eliminations(eliminated: Array, board: Array) -> Array:
    var result: Array = []
    for cell in eliminated:
        if board[cell[0]][cell[1]] == CellModel.CellKind.BLANK:
            result.append(cell)
    return result
```

Nếu `_filter_new_eliminations()` trả mảng rỗng → bỏ qua bước này, duyệt bước tiếp. Nguyên tắc: **không gợi ý đánh X vào ô đã bị X rồi**.

### 4.4 Work board — bảo toàn dấu X hợp lệ của player

Hiện tại `BoardSolver._build_work_board()` chỉ copy ô Candy/Given và xóa sạch X của player. Điều này khiến engine không nhận biết tiến trình giải đã có.

**HintEngine phải dùng work_board riêng** giữ lại dấu X hợp lệ:

```gdscript
static func _build_hint_work_board(board: Array, size: int,
        regions: Array, solution: Array) -> Array:
    var work: Array = []
    for r in range(size):
        var row: Array = []
        for c in range(size):
            var cell: int = board[r][c]
            if CellModel.is_placed(cell):
                row.append(cell)
            elif cell == CellModel.CellKind.MARK and solution[r] != c:
                # Giữ lại dấu X hợp lệ (không đè lên ô solution)
                row.append(CellModel.CellKind.MARK)
            else:
                row.append(CellModel.CellKind.BLANK)
        work.append(row)
    SolverTechniques._apply_elimination(work, size, regions)
    return work
```

Quy tắc:
- `board[r][c] == MARK` và `solution[r] != c` → giữ MARK (player đánh đúng)
- `board[r][c] == MARK` và `solution[r] == c` → đã xử lý ở Bước 0 (wrong mark)
- Các ô Candy/Given → giữ nguyên
- Còn lại → BLANK, sau đó `_apply_elimination()` tự động mark thêm

Work board này được dùng cho Bước 2, 3, 4, 5. Bước 0 và 1 chạy trực tiếp trên board thực.

---

## 5. Sửa `solver_techniques.gd` — Chain Detail

### 5.1 Thay đổi `_try_contradiction()`

Hiện tại `_try_contradiction()` chỉ trả `{"found": true, "eliminated": [[r,c]]}`. Cần bổ sung chain detail:

```gdscript
static func _try_contradiction(board: Array, size: int, regions: Array,
        max_depth: int = 99) -> Dictionary:
    var best_result: Dictionary = {"found": false, "eliminated": []}
    var best_depth: int = size * size  # sentinel lớn
    
    for r in range(size):
        for c in range(size):
            if not _is_candidate(board, size, regions, r, c):
                continue
            var test_board := _clone_board(board, size)
            test_board[r][c] = CellModel.CellKind.CANDY
            var chain := _propagate_with_trace(test_board, size, regions, max_depth)
            if chain["contradiction"]:
                if chain["depth"] < best_depth:
                    best_depth = chain["depth"]
                    best_result = {
                        "found": true,
                        "eliminated": [[r, c]],
                        "technique": Technique.CONTRA_CHAIN,
                        "chain_detail": {
                            "hypothesis_cell": [r, c],
                            "depth": chain["depth"],
                            "steps": chain["steps"],
                            "contra_type": chain["contra_type"],
                            "contra_index": chain["contra_index"],
                        }
                    }
    return best_result
```

### 5.2 Hàm mới `_propagate_with_trace()`

Thay thế `_propagate_and_check()` bên trong `_try_contradiction()`. Kiểm tra mâu thuẫn **bên trong vòng lặp** để ngắt sớm (early return) và sử dụng `max_depth` để giới hạn:

```gdscript
static func _propagate_with_trace(board: Array, size: int,
        regions: Array, max_depth: int) -> Dictionary:
    var steps: Array = []  # [[r,c], ...] thứ tự ô bị ép đặt candy
    var depth: int = 0
    
    for _iteration in range(size * size):
        _apply_elimination(board, size, regions)
        
        # Kiểm tra mâu thuẫn SAU MỖI bước elimination
        var contra := _check_contradiction(board, size, regions)
        if contra["found"]:
            return {"contradiction": true, "depth": depth, "steps": steps,
                    "contra_type": contra["type"], "contra_index": contra["index"]}
        
        var s2 := _try_single_candidate(board, size, regions)
        if s2.get("found", false):
            var cell: Array = s2["cell"]
            board[cell[0]][cell[1]] = CellModel.CellKind.CANDY
            steps.append(cell)
            depth += 1
            if depth > max_depth:
                break  # quá sâu, dừng lan truyền
            continue
        break
    
    # Kiểm tra mâu thuẫn lần cuối sau khi vòng lặp kết thúc
    var final_contra := _check_contradiction(board, size, regions)
    if final_contra["found"]:
        return {"contradiction": true, "depth": depth, "steps": steps,
                "contra_type": final_contra["type"], "contra_index": final_contra["index"]}
    
    return {"contradiction": false, "depth": depth, "steps": steps,
            "contra_type": "", "contra_index": -1}

# Helper: kiểm tra unit nào bị cạn ứng viên
static func _check_contradiction(board: Array, size: int,
        regions: Array) -> Dictionary:
    for z in _zones(regions, size):
        if not _has_candy(board, size, regions, "zone", z):
            if _candidates_in_zone(board, size, regions, z).is_empty():
                return {"found": true, "type": "zone", "index": z}
    for r in range(size):
        if not _has_candy(board, size, regions, "row", r):
            if _candidates_in_row(board, size, regions, r).is_empty():
                return {"found": true, "type": "row", "index": r}
    for c in range(size):
        if not _has_candy(board, size, regions, "col", c):
            if _candidates_in_col(board, size, regions, c).is_empty():
                return {"found": true, "type": "col", "index": c}
    return {"found": false, "type": "", "index": -1}
```

**Phân loại depth:**
- `depth <= 2` → strategy `"CONTRA_CHAIN"` (explanation_key `"hint.chain_short"`)
- `depth > 2` → strategy `"CONTRA_CHAIN"` (explanation_key `"hint.chain_long"`)

Thuật toán ưu tiên chuỗi ngắn nhất (`best_depth`), hỗ trợ `max_depth` mặc định = 99 (quét đầy đủ).

**Lưu ý:** `_propagate_and_check()` hiện có vẫn giữ nguyên cho `replay_solve()` dùng. `_propagate_with_trace()` là hàm mới bổ sung, chỉ `_try_contradiction()` gọi.

---

## 6. Module mới: `hint_mutex.gd`

**File:** `game/scripts/screens/hint_mutex.gd`  
**Kế thừa:** `RefCounted`  
**Kích thước:** ~40 dòng

```gdscript
# hint_mutex.gd
extends RefCounted

var _active_id: String = ""
var _cooldown_until: int = 0  # msec timestamp

const COOLDOWN_MS: int = 500

func try_acquire(hint_id: String) -> bool:
    if _active_id != "":
        return false
    if Time.get_ticks_msec() < _cooldown_until:
        return false
    _active_id = hint_id
    return true

func release(hint_id: String) -> void:
    if _active_id == hint_id:
        _active_id = ""
        _cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS

func is_locked() -> bool:
    return _active_id != "" or Time.get_ticks_msec() < _cooldown_until

func force_release() -> void:
    _active_id = ""
    _cooldown_until = 0
```

**Cách dùng trong puzzle_screen:**
- `_on_hint()`: gọi `mutex.try_acquire("hint")` đầu tiên, false → return
- Sau khi Apply/Dismiss xong + animation hoàn tất: gọi `mutex.release("hint")`
- Khi restart/home: gọi `mutex.force_release()`

---

## 7. Module mới: `hint_highlight_layer.gd`

**File:** `game/scripts/screens/hint_highlight_layer.gd`  
**Kế thừa:** `Control` (nằm trong board_card, vẽ trên board)  
**Kích thước mục tiêu:** ~200 dòng

### 7.1 Trách nhiệm

- Vẽ highlight cells (pulse vàng) trên board mà KHÔNG sửa đổi board data
- Vẽ preview marks (X mờ) cho eliminated_cells
- Vẽ chain detail badges (?, 1, 2, x) cho contradiction chain
- Animation lifecycle: show → (player xem) → apply/dismiss → clear

### 7.2 PuzzleBoard — public accessor

Thêm hàm public vào `puzzle_board.gd` để tránh gọi private `_cell_rect`:

```gdscript
func get_cell_rect(row: int, col: int) -> Rect2:
    return _cell_rect(row, col)
```

### 7.3 API

```gdscript
# Hiển thị highlight cho hint result
func show_hint(hint: Dictionary, cell_rect_fn: Callable) -> void

# Hiển thị chain detail badges (khi player nhấn Detail)
func show_chain_detail(chain_detail: Dictionary, cell_rect_fn: Callable) -> void

# Xóa tất cả highlight, ẩn backdrop
func clear() -> void

# Kiểm tra đang hiển thị
func is_showing() -> bool
```

### 7.4 Backdrop — chặn input khi hint đang mở

Khi `show_hint()` được gọi, highlight layer phải bật một **backdrop** che toàn bộ board_card:

```gdscript
var _backdrop: ColorRect = null

func _ready() -> void:
    _backdrop = ColorRect.new()
    _backdrop.color = Color(0, 0, 0, 0.01)  # gần trong suốt, chỉ chặn input
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.visible = false
    _backdrop.gui_input.connect(_on_backdrop_input)
    add_child(_backdrop)

func _on_backdrop_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        dismiss_requested.emit()
        accept_event()
```

Signals:
```gdscript
signal dismiss_requested()  # backdrop tap → puzzle_screen calls _dismiss_hint()
```

Khi `show_hint()`: `_backdrop.visible = true`
Khi `clear()`: `_backdrop.visible = false`

Backdrop nằm dưới các vẽ highlight (draw order), nhưng `mouse_filter = STOP` chặn mọi touch đi qua board bên dưới. Player phải nhấn Apply/Dismiss/Detail trên HintOverlay, hoặc tap backdrop để dismiss.

### 7.5 Rendering

**Highlight cells (pulse vàng):**
- Duyệt `hint.highlight_cells`, với mỗi [r,c]:
  - Vẽ border vàng (`#F59E0B`) quanh cell rect, pulse alpha sine wave (0.5..1.0, 4.8 rad/s)
  - Nếu ô là `eliminated_cell`: vẽ X mờ bên trong (alpha 0.4) với stagger delay `index * 0.06s`

**Chain badges:**
- Badge hình tròn (radius = cell_size * 0.25) đặt tại center của cell
- Hypothesis cell: vòng đỏ `#EF4444` chứa chữ "?"
- Step cells: vòng amber `#F59E0B` chứa số thứ tự "1", "2", "3"
- Contradiction unit: toàn bộ ô trong unit bị cạn → vòng đỏ đậm `#DC2626` chứa "×"
- Animation: drop-in stagger (scale 0→1, delay += 0.05s mỗi badge)

### 7.6 Tích hợp layout

Trong `puzzle_layout.gd`, thêm `hint_highlight_layer` vào `board_card` SAU `board`, TRƯỚC `hint_overlay`:

```gdscript
var highlight_layer := HintHighlightLayer.new()
highlight_layer.name = "HintHighlightLayer"
highlight_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
board_card.add_child(highlight_layer)
# hint_overlay thêm sau → nằm trên highlight_layer
```

**Lưu ý:** `mouse_filter` mặc định là `PASS`. Khi hint đang hiển thị, backdrop bên trong (mục 7.4) sẽ `STOP` input. Khi hint không hiển thị, backdrop ẩn nên input đi qua board bình thường.

Z-order trong board_card:
1. `PuzzleBoard` (layer 0 — board chính)
2. `HintHighlightLayer` (layer 1 — backdrop + ghost cells + chain badges)
3. `HintOverlay` (layer 2 — banner + buttons)

---

## 8. Module viết lại: `hint_overlay.gd`

**File:** `game/scripts/screens/hint_overlay.gd`  
**Kế thừa:** `PanelContainer`  
**Kích thước mục tiêu:** ~120 dòng

### 8.1 Thay đổi so với hiện tại

Hiện tại chỉ có: text + OK button. Cần thay bằng:

**Layout mới:**
```
┌─────────────────────────────────────────┐
│  [Strategy Icon]  "Explanation text"    │  ← Banner
│                                         │
│  [Apply ✓]   [Detail 🔍]   [Dismiss ✕] │  ← Button row
└─────────────────────────────────────────┘
```

### 8.2 Signals

```gdscript
signal hint_applied()      # player nhấn Apply
signal hint_dismissed()    # player nhấn Dismiss hoặc tap ngoài
signal detail_requested()  # player nhấn Detail (chỉ hiện khi có chain)
```

### 8.3 API

```gdscript
# Hiển thị hint overlay với thông tin từ HintResult
func show_hint(hint: Dictionary) -> void

# Ẩn overlay
func dismiss() -> void

# Đang hiển thị?
func is_showing() -> bool
```

### 8.4 Hành vi theo strategy

| Strategy | Banner text | Apply label | Detail visible |
|---|---|---|---|
| `WRONG_MARK` | `tr("hint.wrong_mark")` | `tr("hint.clear_mark")` | false |
| `MARK_NEIGHBORS` | `tr("hint.mark_neighbors")` | `tr("hint.mark_x")` | false |
| `SINGLE_CANDIDATE` | `tr("hint.single_" + unit_type)` | `tr("hint.place_candy")` | false |
| `LOCK_INTERSECTION` | `tr("hint.lock_*")` | `tr("hint.mark_x")` | false |
| `LOCKED_SUBSET` | `tr("hint.subset_*")` | `tr("hint.mark_x")` | false |
| `CONTRA_CHAIN` | `tr("hint.chain_*")` | `tr("hint.mark_x")` | **true** |
| `FALLBACK` | `tr("hint.fallback")` | `tr("hint.reveal")` | false |

### 8.5 Strategy icon

Mỗi strategy có icon khác nhau bên trái banner text:
- `WRONG_MARK`: ⚠ (warning orange)
- `MARK_NEIGHBORS` / `LOCK_*` / `LOCKED_SUBSET`: ✕ (blue — gợi ý đánh X)
- `SINGLE_CANDIDATE` / `FALLBACK`: 🍬 (candy icon nhỏ — gợi ý đặt candy)
- `CONTRA_CHAIN`: 🔗 (chain icon — suy luận phức tạp)

Dùng Label với emoji hoặc TextureRect nhỏ — giữ đơn giản, không cần asset mới.

---

## 9. Sửa `puzzle_screen.gd` — Flow mới

### 9.1 Thêm dependencies

```gdscript
const HintEngine = preload("res://scripts/core/hint_engine.gd")
const HintMutex = preload("res://scripts/screens/hint_mutex.gd")
const HintHighlightLayer = preload("res://scripts/screens/hint_highlight_layer.gd")

var _hint_mutex: HintMutex = HintMutex.new()
var hint_highlight: HintHighlightLayer  # inject từ puzzle_layout
```

### 9.2 Hàm `_on_hint()` viết lại

```gdscript
func _on_hint() -> void:
    if session == null or session.phase != PlaySession.Phase.ACTIVE:
        return
    
    # Nếu đang hiển thị hint → dismiss
    if hint_overlay != null and hint_overlay.is_showing():
        _dismiss_hint()
        return
    
    # Mutex guard
    if not _hint_mutex.try_acquire("hint"):
        return
    
    # Tìm hint
    var lvl: Dictionary = session.level
    var hint: Dictionary = HintEngine.find_hint(
        session.board, lvl["size"], lvl["regions"], lvl["solution"]
    )
    
    if not hint.get("found", false):
        _hint_mutex.release("hint")
        return
    
    # Lưu hint hiện tại để Apply dùng
    _current_hint = hint
    
    # Hiển thị
    if hint_highlight != null:
        hint_highlight.show_hint(hint, board.get_cell_rect)
    if hint_overlay != null:
        hint_overlay.show_hint(hint)
    
    # SFX
    if hint.get("strategy") == "WRONG_MARK":
        if sfx != null: sfx.play(SfxCatalog.Effect.HINT_WRONG_MARK)
    else:
        if sfx != null: sfx.play(SfxCatalog.Effect.HINT_SHOW)
    
    # Track usage (chỉ count nếu không phải wrong mark correction)
    if hint.get("strategy") != "WRONG_MARK":
        session.use_hint()
```

### 9.3 Hàm `_apply_hint()` mới

```gdscript
func _apply_hint() -> void:
    if _current_hint == null:
        return
    var hint: Dictionary = _current_hint
    var action: String = hint.get("action", "")
    
    match action:
        "CLEAR_MARK":
            # Wrong mark — xóa X
            var cell: Array = hint["target_cell"]
            session.clear_mark(cell[0], cell[1])
        "PLACE_MARKS":
            # Đánh X hàng loạt
            session.apply_marks(hint["eliminated_cells"])
        "PLACE_CANDY":
            # Đặt candy
            var cell: Array = hint["target_cell"]
            session.try_candy(cell[0], cell[1])
        "REVEAL":
            # Fallback — đặt candy từ solution
            var cell: Array = hint["target_cell"]
            session.try_candy(cell[0], cell[1])
    
    _dismiss_hint()
    if sfx != null: sfx.play(SfxCatalog.Effect.HINT_APPLY)
    Vibration.pulse(Vibration.Strength.SOFT)
    if board != null: board.redraw()
```

### 9.4 Hàm `_dismiss_hint()` mới

```gdscript
func _dismiss_hint() -> void:
    _current_hint = null
    if hint_highlight != null: hint_highlight.clear()
    if hint_overlay != null: hint_overlay.dismiss()
    if sfx != null: sfx.play(SfxCatalog.Effect.BTN_PRESS)
    _hint_mutex.release("hint")
```

### 9.5 Hàm `_on_hint_detail()` mới

```gdscript
func _on_hint_detail() -> void:
    if _current_hint == null or hint_highlight == null:
        return
    var chain: Dictionary = _current_hint.get("chain_detail", {})
    if chain.is_empty():
        return
    hint_highlight.show_chain_detail(chain, board.get_cell_rect)
```

### 9.6 Signal connections

Trong `_connect_ui()`, thêm:
```gdscript
if hint_overlay != null:
    _sig_conn(hint_overlay.hint_applied, _apply_hint)
    _sig_conn(hint_overlay.hint_dismissed, _dismiss_hint)
    _sig_conn(hint_overlay.detail_requested, _on_hint_detail)
if hint_highlight != null:
    _sig_conn(hint_highlight.dismiss_requested, _dismiss_hint)
```

### 9.7 Xóa code cũ

- Xóa biến `_hint_click_count` — không cần nữa vì hint v2 luôn cho kết quả cụ thể trong 1 lần
- Xóa import `BoardSolver` trong puzzle_screen (chuyển sang `HintEngine`)
- Xóa logic progressive_hint cũ trong `_on_hint()`

---

## 10. Sửa `play_session.gd` — Thêm hint apply methods

### 10.1 Hàm mới `clear_mark()`

```gdscript
func clear_mark(row: int, col: int) -> void:
    if phase != Phase.ACTIVE:
        return
    if row < 0 or row >= board.size() or col < 0 or col >= board.size():
        return
    if board[row][col] == CellModel.CellKind.MARK:
        _undo_cells = [[row, col, CellModel.CellKind.MARK]]
        board[row][col] = CellModel.CellKind.BLANK
        state_changed.emit()
```

### 10.2 Hàm mới `apply_marks()`

```gdscript
func apply_marks(cells: Array) -> void:
    if phase != Phase.ACTIVE:
        return
    var before: Array = []
    for cell in cells:
        var r: int = int(cell[0])
        var c: int = int(cell[1])
        if r >= 0 and r < board.size() and c >= 0 and c < board.size():
            if board[r][c] == CellModel.CellKind.BLANK:
                before.append([r, c, CellModel.CellKind.BLANK])
                board[r][c] = CellModel.CellKind.MARK
    if not before.is_empty():
        _undo_cells = before
        state_changed.emit()
```

---

## 11. Module mới: `pre_candy_decider.gd`

**File:** `game/scripts/core/pre_candy_decider.gd`  
**Kế thừa:** `RefCounted`  
**Kích thước:** ~80 dòng  
**Tính chất:** Static functions, pure logic

### 11.1 Mục đích & Phạm vi

Khi player thua liên tiếp hoặc gặp level cực khó, hệ thống điền sẵn 1 candy vào bàn cờ ở vị trí "nút thắt cổ chai" để giảm độ khó.

**Phạm vi kích hoạt:**
- **Endless / Practice:** mặc định BẬT
- **Campaign (30 level playtest):** mặc định TẮT (`enable_dda_prefill = false`) để bảo toàn nhịp độ thiết kế chuẩn
- Cờ `enable_dda_prefill` do runtime truyền vào, không hardcode

**Nguyên tắc không mutate:**
- `apply_prefill()` trả bản COPY (`level.duplicate(true)`), KHÔNG sửa level gốc trong bank
- Mảng givens gốc trong bộ nhớ bank luôn giữ nguyên

### 11.2 API

```gdscript
enum Trigger {
    HARD_NEXT = 1,        # vừa qua level khó
    CONSECUTIVE_FAIL = 2, # thua ≥2 lần liên tiếp cùng level
    DEMOTE = 3,           # bị hạ bậc/rank
}

# Quyết định có nên pre-fill candy không
static func should_prefill(trigger: int, fail_streak: int) -> bool:
    match trigger:
        Trigger.CONSECUTIVE_FAIL:
            return fail_streak >= 2
        Trigger.HARD_NEXT, Trigger.DEMOTE:
            return true
    return false

# Chọn ô tốt nhất để pre-fill
static func choose_prefill_cell(size: int, regions: Array,
        solution: Array, givens: Array) -> Array:
    var ranks: Array = BoardSolver.compute_cell_ranks(size, regions, solution, givens)
    var best_rank: int = 0
    var best_cell: Array = []
    for r in range(size):
        var c: int = int(solution[r])
        if ranks[r][c] > best_rank:
            best_rank = ranks[r][c]
            best_cell = [r, c]
    return best_cell  # [row, col] hoặc [] nếu không có

# Áp dụng pre-fill vào level data
static func apply_prefill(level: Dictionary) -> Dictionary:
    var modified: Dictionary = level.duplicate(true)
    var cell: Array = choose_prefill_cell(
        int(level["size"]), level["regions"],
        level["solution"], level.get("givens", [])
    )
    if not cell.is_empty():
        var givens: Array = modified.get("givens", []).duplicate(true)
        givens.append({"r": cell[0], "c": cell[1]})
        modified["givens"] = givens
    return modified
```

### 11.3 Tích hợp

Trong runtime (EndlessRuntime / PracticeRuntime), khi chuẩn bị start level:

```gdscript
# Chỉ khi chế độ cho phép DDA
if enable_dda_prefill and PreCandyDecider.should_prefill(trigger, fail_streak):
    level_data = PreCandyDecider.apply_prefill(level_data)
    # level_data là bản copy, bank gốc không bị sửa
```

Cụ thể: gọi trước khi `PlaySession.new(level_data)`. Không sửa `PlaySession` — pre-fill candy xuất hiện như given bình thường.

**CampaignRuntime KHÔNG gọi** `PreCandyDecider` — 30 level playtest giữ nguyên nhịp độ thiết kế.

---

## 12. Sửa `sfx_catalog.gd` — Thêm effects

Thêm vào enum `Effect`:

```gdscript
HINT_APPLY,      # áp dụng gợi ý (positive chime)
HINT_DISMISS,    # hủy gợi ý (soft close)
HINT_WRONG_MARK, # phát hiện đánh sai (warning tone)
```

Thêm presets tương ứng:

```gdscript
Effect.HINT_APPLY: {
    "freq": 523.0, "end_freq": 784.0, "duration": 0.12, "volume": 0.28,
    "wave": PcmSynth.Wave.TRIANGLE, "attack": 0.01, "decay": 0.03,
    "release": 0.04, "sustain": 0.3, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
},
Effect.HINT_DISMISS: {
    "freq": 440.0, "end_freq": 350.0, "duration": 0.08, "volume": 0.18,
    "wave": PcmSynth.Wave.SINE, "attack": 0.01, "decay": 0.02,
    "release": 0.03, "sustain": 0.2,
},
Effect.HINT_WRONG_MARK: {
    "freq": 300.0, "end_freq": 200.0, "duration": 0.15, "volume": 0.30,
    "wave": PcmSynth.Wave.SQUARE, "attack": 0.005, "decay": 0.04,
    "release": 0.05, "sustain": 0.25,
},
```

Thêm vào `SHARED_UI_EFFECTS`:
```gdscript
const SHARED_UI_EFFECTS := [..., Effect.HINT_APPLY, Effect.HINT_DISMISS, Effect.HINT_WRONG_MARK]
```

---

## 13. Localization Keys

Thêm vào file localization (`vi` và `en`):

```
hint.wrong_mark = "Ô này đang bị đánh X sai! Candy cần đặt ở đây." / "This cell is incorrectly marked! A candy belongs here."
hint.mark_neighbors = "Đánh X loại trừ các ô xung quanh candy này." / "Mark X to eliminate cells around this candy."
hint.single_row = "Hàng được đánh dấu chỉ còn duy nhất 1 ô có thể đặt candy." / "The highlighted row has only one possible cell for a candy."
hint.single_col = "Cột được đánh dấu chỉ còn duy nhất 1 ô có thể đặt candy." / "The highlighted column has only one possible cell for a candy."
hint.single_zone = "Vùng được đánh dấu chỉ còn duy nhất 1 ô có thể đặt candy." / "The highlighted zone has only one possible cell for a candy."
hint.lock_zone_row = "Candy của vùng nhấp nháy chỉ có thể nằm trên hàng này. Loại trừ các ô khác." / "This zone's candy must be on this row. Eliminate the other cells."
hint.lock_zone_col = "Candy của vùng nhấp nháy chỉ có thể nằm trên cột này. Loại trừ các ô khác." / "This zone's candy must be on this column. Eliminate the other cells."
hint.lock_row_zone = "Hàng này chỉ có ứng viên trong vùng nhấp nháy. Loại trừ các ô khác trong vùng." / "This row only has candidates in the highlighted zone. Eliminate other cells in the zone."
hint.lock_col_zone = "Cột này chỉ có ứng viên trong vùng nhấp nháy. Loại trừ các ô khác trong vùng." / "This column only has candidates in the highlighted zone. Eliminate other cells in the zone."
hint.subset_pair = "Hai vùng nhấp nháy khóa chéo — loại trừ các ô thừa." / "Two highlighted zones lock each other — eliminate extra cells."
hint.subset_triple = "Ba vùng nhấp nháy khóa chéo — loại trừ các ô thừa." / "Three highlighted zones lock each other — eliminate extra cells."
hint.subset_quad = "Bốn vùng nhấp nháy khóa chéo — loại trừ các ô thừa." / "Four highlighted zones lock each other — eliminate extra cells."
hint.chain_short = "Giả sử đặt candy ở ô này → dẫn đến mâu thuẫn! Phải đánh X." / "If a candy were here → contradiction! Must mark X."
hint.chain_long = "Chuỗi suy luận dài: giả sử đặt candy → mâu thuẫn! Nhấn Chi Tiết để xem." / "Long deduction chain: placing candy here → contradiction! Tap Detail to see."
hint.fallback = "Gợi ý: đặt candy vào ô này." / "Hint: place a candy here."
hint.clear_mark = "Xóa X" / "Clear X"
hint.mark_x = "Đánh X" / "Mark X"
hint.place_candy = "Đặt Candy" / "Place Candy"
hint.reveal = "Mở" / "Reveal"
hint.detail = "Chi Tiết" / "Detail"

**Nguyên tắc localization zone:** Bàn cờ CanDoKu chỉ hiển thị màu sắc, KHÔNG in chữ A/B/C lên ô. Do đó tất cả câu thông báo dùng "vùng được đánh dấu" / "vùng nhấp nháy" kết hợp hiệu ứng pulse trên HintHighlightLayer để player nhận diện bằng mắt thay vì đọc ký hiệu.
```

---

## 14. Testing Strategy

### 14.1 Unit tests cho `hint_engine.gd`

**File:** `game/tests/test_hint_engine.gd`

```
test_wrong_mark_detected:
    Board 5×5, solution[2] = 3, board[2][3] = MARK
    → strategy == "WRONG_MARK", target_cell == [2, 3]

test_wrong_mark_skipped_when_none:
    Board 5×5, không có MARK trên solution
    → bước 0 bỏ qua, hint từ bước 1+

test_mark_hint_finds_new_marks:
    Board 5×5, candy tại [0, 2], các ô [0,0], [0,1], [1,1], [1,2], [1,3] chưa mark
    → strategy == "MARK_NEIGHBORS", eliminated_cells chứa các ô trên

test_mark_hint_skips_when_all_marked:
    Board 5×5, candy tại [0, 2], tất cả ô row 0 + col 2 + neighbors đã MARK
    → bước 1 bỏ qua

test_has_new_guard_filters_existing_marks:
    Board có lock_intersection trả eliminated = [[1,3], [1,4]]
    board[1][3] đã là MARK, board[1][4] là BLANK
    → eliminated_cells chỉ chứa [[1,4]]

test_has_new_guard_rejects_all_stale:
    Board có lock_intersection trả eliminated = [[1,3]]
    board[1][3] đã là MARK
    → bỏ qua lock_intersection, duyệt bước tiếp

test_chain_returns_detail:
    Board cần contradiction chain
    → chain_detail có hypothesis_cell, depth, steps, contra_type

test_chain_chooses_min_depth:
    Board có 2 contradiction chains, depth 1 và depth 3
    → chọn depth 1

test_single_candidate_explanation:
    Board 5×5 có single trong row 3
    → explanation_key == "hint.single_row", unit_type == "row", unit_id == 3

test_fallback_when_stuck:
    Board bế tắc (không chain nào hoạt động)
    → strategy == "FALLBACK"
```

### 14.2 Unit tests cho `hint_mutex.gd`

```
test_acquire_release_cycle:
    acquire("hint") → true
    acquire("hint") → false (đang bận)
    release("hint")
    acquire("hint") → true

test_cooldown:
    acquire + release
    immediately acquire → false (cooldown)
    after 500ms → true

test_force_release:
    acquire("hint")
    force_release()
    acquire("hint") → true (bỏ qua cooldown)
```

### 14.3 Unit tests cho `pre_candy_decider.gd`

```
test_should_prefill_consecutive_fail:
    fail_streak=1 → false
    fail_streak=2 → true

test_choose_prefill_cell_picks_hardest:
    Level 5×5 với ranks: [1, 1, 3, 2, 1]
    → chọn ô rank 3 (row 2)

test_apply_prefill_adds_given:
    Level 5×5 với givens=[]
    → modified.givens.size() == 1
```

### 14.4 Integration tests

```
test_full_hint_flow_on_5x5:
    Tạo PlaySession với level 5×5 trống
    Gọi HintEngine.find_hint() lặp lại
    Mỗi lần apply hint result
    → giải xong board HOẶC fallback

test_hint_overlay_shows_correct_buttons:
    CONTRA_CHAIN hint → detail button visible
    SINGLE_CANDIDATE hint → detail button hidden

test_mutex_prevents_double_hint:
    Gọi _on_hint() 2 lần liên tiếp
    → lần 2 bị chặn
```

---

## 15. Migration & Backward Compatibility

### 15.1 `board_solver.gd` vẫn hoạt động

- `solve_sequence()`, `replay_solve()`, `compute_cell_ranks()` KHÔNG thay đổi signature
- `next_hint()` và `progressive_hint()` giữ nguyên nhưng **deprecated** — puzzle_screen không gọi nữa
- Level generation pipeline (`convert_extracted_bank.py`, `validate_content.py`) vẫn dùng `replay_solve()` qua GDScript → không ảnh hưởng

### 15.2 Session save format

- Không đổi schema `sessionVersion: 3` — hint state không persist giữa sessions
- `hints_used` counter vẫn hoạt động như cũ

### 15.3 Clean-room compliance

- Tất cả code là nguyên gốc, không sao chép từ nguồn tham khảo
- Tên file/class/function khác hoàn toàn với nguồn tham khảo: `HintEngine`, `PreCandyDecider`, `CellKind` — không trùng bất kỳ identifier nào
- Kiến trúc lấy cảm hứng nhưng implementation phù hợp CanDoKu patterns (RefCounted thay Node, signals thay global bus, static functions)
- **Gate bắt buộc trước merge:** chạy `rg -n` với danh sách từ khóa cấm trong `game/scripts/` — xem AGENTS.md §3 "Clean-room" — phải trả về 0 kết quả

---

## 16. File tạo & sửa — Tổng kết

| # | File | Action | LOC ước tính |
|---|---|---|---|
| 1 | `game/scripts/core/hint_engine.gd` | Tạo mới | ~250 |
| 2 | `game/scripts/screens/hint_mutex.gd` | Tạo mới | ~40 |
| 3 | `game/scripts/screens/hint_highlight_layer.gd` | Tạo mới | ~200 |
| 4 | `game/scripts/core/pre_candy_decider.gd` | Tạo mới | ~80 |
| 5 | `game/scripts/core/solver_techniques.gd` | Sửa | +50 (thêm `_propagate_with_trace`, sửa `_try_contradiction`) |
| 6 | `game/scripts/screens/hint_overlay.gd` | Viết lại | ~120 (thay 80 hiện tại) |
| 7 | `game/scripts/screens/puzzle_screen.gd` | Sửa | ±40 (đổi _on_hint, thêm _apply/_dismiss/_detail) |
| 8 | `game/scripts/screens/puzzle_layout.gd` | Sửa nhẹ | +8 (thêm highlight_layer vào board_card) |
| 9 | `game/scripts/input/play_session.gd` | Sửa nhẹ | +25 (thêm clear_mark, apply_marks) |
| 10 | `game/scripts/screens/puzzle_board.gd` | Sửa nhẹ | +4 (thêm `get_cell_rect` public wrapper) |
| 11 | `game/scripts/feedback/sfx_catalog.gd` | Sửa nhẹ | +15 (3 effects mới) |
| 12 | `game/tests/test_hint_engine.gd` | Tạo mới | ~200 |
| 13 | `game/tests/test_hint_mutex.gd` | Tạo mới | ~60 |
| 14 | `game/tests/test_pre_candy_decider.gd` | Tạo mới | ~80 |

**Tổng: ~1174 dòng code mới/sửa, 4 file mới + 7 file sửa + 3 file test mới.**
