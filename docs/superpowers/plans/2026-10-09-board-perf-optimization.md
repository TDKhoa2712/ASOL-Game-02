# Plan: Board Rendering Performance Optimization v2

> **Spec:** [board-rendering-performance](../specs/2026-10-09-board-rendering-performance.md) (v2)
> **Ngày:** 2026-10-09 (revised after technical review)
> **Nhánh:** `perf/v1.0.1/board-render-batch`
> **Mục tiêu:** 60 FPS ổn định trên board 12×12, draw calls < 10

---

## Phase 1: Layered Rendering + Texture Cell BG 🔴 (Ưu tiên tuyệt đối)

### Step 1.1: Tạo white rounded-rect texture (runtime SVG)
- **File:** logic trong `puzzle_board_painter.gd` (static lazy init)
- Generate runtime từ SVG string, tương tự pattern `CellAnimator.get_mark_texture()`:
  ```gdscript
  static var _cell_bg_tex: Texture2D = null
  static func _get_cell_bg_tex() -> Texture2D:
      if _cell_bg_tex != null: return _cell_bg_tex
      var svg := '<svg width="128" height="128"><rect x="0" y="0" width="128" height="128" rx="18" ry="18" fill="#FFFFFF"/></svg>'
      var img := Image.new()
      img.load_svg_from_string(svg)
      _cell_bg_tex = ImageTexture.create_from_image(img)
      return _cell_bg_tex
  ```
- Chạy 1 lần (< 1ms), sắc nét mọi DPI, không cần thêm PNG asset vào repo
- Tạo thêm **hollow rounded-rect texture** cho border (xem Step 3.1)

### Step 1.2: Refactor puzzle_board_painter.gd — Multi-pass layered rendering
- **File:** `game/scripts/screens/puzzle_board_painter.gd` (hiện 97 LOC, budget lên ~250 LOC)
- Tách vòng lặp interleaved thành 6 passes:

```
static func draw(board: Variant) -> void:
    # Card background (giữ StyleBoxFlat — chỉ 1 draw call)
    _draw_card(board)

    # Pass 1: Cell backgrounds — draw_texture_rect × N² (1 batch)
    _draw_cell_backgrounds(board, rects, white_tex)

    # Pass 2: State overlays — draw_texture_rect × affected (1 batch)
    _draw_state_overlays(board, rects, white_tex)

    # Pass 3: Zone accessibility icons — draw_string × cells (1 font batch)
    _draw_zone_icons(board, rects)

    # Pass 4: Static candy & marks — draw_texture_rect (1-2 batches)
    _draw_static_content(board, rects)

    # Pass 5: Animating marks — vector draws (few cells, acceptable)
    _draw_animating_marks(board, rects)

    # Pass 6: Highlight borders — draw_texture_rect(border_tex) (1 batch)
    _draw_highlights(board, rects)
```

- Mỗi pass loop qua N² ô nhưng chỉ vẽ 1 loại → cùng texture state → Godot auto-batch
- `rects: Array` = pre-computed cell rects (tính 1 lần đầu pass, dùng lại cho tất cả passes)

### Step 1.3: draw_texture_rect thay draw_style_box cho cell BG
- Thay: `board.draw_style_box(_get_cell_sb(base_col, cr), cell_rect)`
- Bằng: `board.draw_texture_rect(white_tex, cell_rect, false, base_col)`
- `modulate = base_col` cho phép đổi màu zone tùy ý trên 1 texture duy nhất
- Xóa `_sb_cache` (không còn cần cho cell BG)

### Step 1.4: Guard entry animation transform
- Trong pass 1, chỉ gọi `draw_set_transform` khi `cell_entry_scale != 1.0`
- Khi entry wave xong (đa số thời gian chơi), pass 1 không bị phá batch

**Deliverable:** Board 12×12 giảm từ ~295 xuống ~6 draw calls.

---

## Phase 2: Tối ưu đánh dấu X khi swipe 🟡

### Step 2.1: Process-driven animation thay Tween storm
- **Giữ `_mark_anims: Dictionary` là instance var trên `puzzle_board.gd`** — KHÔNG chuyển sang static var trong painter (tránh state leak giữa tests/levels khi board.free() rồi tạo mới)
- Đổi value từ `float (progress)` sang `float (remaining_time)`:
  ```gdscript
  # puzzle_board.gd — play_mark_anims()
  func play_mark_anims(cells: Array) -> void:
      var dur := 0.10 if n >= 10 else 0.15
      for cell in cells:
          _mark_anims[Vector2i(int(cell[0]), int(cell[1]))] = dur
  ```
- `_process(delta)` trừ dần remaining_time, xóa ô ≤ 0, gọi `queue_redraw()` đúng **1 lần**:
  ```gdscript
  if not _mark_anims.is_empty():
      for key in _mark_anims.keys():
          _mark_anims[key] -= delta
          if _mark_anims[key] <= 0.0: _mark_anims.erase(key)
      queue_redraw()
  ```
- Xóa toàn bộ `create_tween()` + lambda callbacks + `_mark_tweens` dict (dòng 135–142)
- `has_mark_anim(r, c)` giữ nguyên trên puzzle_board.gd (khớp contract test_screens.gd)
- **LOC impact:** puzzle_board.gd giảm ~20 LOC (xóa tween logic) → ~280 LOC

### Step 2.2: Fast-path texture cho swipe marks
- Khi swipe ≥ 3 ô: dùng `draw_texture_rect(mark_tex)` + scale pop (từ `CellAnimator.get_mark_texture()`)
- Khi tap 1 ô: giữ hand-drawn vector animation (visual polish, chỉ 1-3 ô)
- Trong pass 4 (static content), marks đã settle dùng cached texture → batch cùng candy

### Step 2.3: Xóa mutation trong _draw()
- Hiện tại `_draw()` erase entries từ `_mark_anims` dict (puzzle_board_painter.gd:77)
- Chuyển cleanup sang `tick_marks()` trong `_process` — `_draw()` chỉ đọc, không ghi

---

## Phase 3: Border cache + Rect cache 🟢

### Step 3.1: Thay _draw_border bằng hollow rounded-rect texture
- **File:** `game/scripts/screens/puzzle_board.gd` dòng 250–253
- `draw_rect(filled=false)` trong Godot 4 vẽ viền **góc vuông** — không khớp cell bo tròn 14%
- **Giải pháp:** Tạo thêm 1 hollow rounded-rect texture (viền bo góc rỗng, trắng) bằng SVG runtime:
  ```gdscript
  # SVG viền bo góc rỗng
  var svg := '<svg width="128" height="128"><rect x="3" y="3" width="122" height="122" rx="16" ry="16" fill="none" stroke="#FFFFFF" stroke-width="6"/></svg>'
  ```
- Khi vẽ: `draw_texture_rect(border_tex, rect, false, border_color)` — batch cùng pass 6
- **Fallback:** Nếu không cần bo góc border, cache 1 `StyleBoxFlat` duy nhất (cùng color+cr cho toàn board) — GC pressure = 0

### Step 3.2: Cache cell rects (instance var, không static)
- Thêm vào `puzzle_board.gd`:
  ```gdscript
  var _cached_rects: Array = []  # Array[Array[Rect2]]
  ```
- Invalidate trong `configure()` và khi `size` thay đổi
- Painter đọc `board._cached_rects[r][c]` thay vì gọi `board._cell_rect(r, c)`
- **Không dùng static var** cho cache — tránh state leak giữa test runs

---

## Thứ tự thực hiện

```
Phase 1 (1.1→1.2→1.3→1.4) → Phase 2 (2.1→2.2→2.3) → Phase 3 (3.1→3.2)
```

Phase 1 = ~90% improvement (draw calls). Phase 2 = triệt tiêu swipe jank. Phase 3 = polish.

## LOC Budget

| File | Hiện tại | Sau refactor | Ngưỡng |
|------|---------|-------------|--------|
| puzzle_board.gd | 299 | ~280 (xóa tween logic dòng 135–142, giữ _mark_anims instance var) | 300 |
| puzzle_board_painter.gd | 97 | ~220 (thêm layered passes + anim) | 300 |
| cell_animator.gd | 114 | ~120 (minor changes) | 300 |

## Gate

- [ ] Board 4×4, 6×6, 12×12 render đúng visual (bo góc, màu zone, overlay state)
- [ ] Colorblind overlays (★, ◆, ●) hiển thị đúng vị trí
- [ ] Mark X animation: tap = hand-drawn, swipe = texture pop
- [ ] Entry wave animation không regression
- [ ] High contrast mode + border highlights hoạt động đúng
- [ ] Godot editor profiler: verify draw calls < 10 cho board 12×12 static
- [ ] Swipe 10 ô liên tục trên 12×12: không jank visible
- [ ] Headless test suite pass
- [ ] Clean-room check pass (không tên từ reference)
- [ ] Tất cả files ≤ 300 LOC
