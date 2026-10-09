# Board Rendering Performance — Spec v2

> **Ngày:** 2026-10-09 (v2 — revised after review)
> **Mục tiêu:** 60 FPS ổn định khi render board N=4–12 trên thiết bị di động tầm trung, loại bỏ jank khi đánh dấu X hàng loạt.

---

## 1. Phân tích hiện trạng (CanDoKu)

### 1.1 Rendering pipeline hiện tại

**File chính:** `game/scripts/screens/puzzle_board_painter.gd`

Quy trình vẽ mỗi frame (`_draw`) — **per-cell interleaved loop**:
```
for r in range(count):
    for c in range(count):
        draw_style_box(cell_bg)     # Texture state A (StyleBoxFlat → TYPE_POLYGON)
        draw_string(zone_icon)      # Texture state B (Font glyph)
        draw_style_box(overlay)     # Texture state A again
        draw_texture_rect(candy)    # Texture state C (candy.png)
        draw_polyline(x_mark)       # Texture state D (no texture)
        draw_style_box(border)      # Texture state A again
```

**Hai vấn đề cốt lõi:**
1. `StyleBoxFlat` sinh `TYPE_POLYGON` → Godot GLES3 **không bao giờ batch polygon**
2. Vẽ **xen kẽ texture states** per-cell → engine flush batch mỗi lần chuyển state → **kể cả thay StyleBoxFlat bằng draw_rect, batching vẫn bị vỡ** nếu giữ interleaved loop

### 1.2 Các bottleneck được xác định

| # | Vấn đề | Tác động | Mức nghiêm trọng |
|---|--------|----------|-------------------|
| **B1** | **StyleBoxFlat → TYPE_POLYGON không batch.** Board 12×12 = 144 ô × 2 layer = ~**288 draw calls** chỉ cho cell BG. | Tụt FPS | 🔴 Critical |
| **B2** | **Interleaved rendering** — vẽ BG→icon→candy→mark→border per-cell. Mỗi chuyển texture state = 1 batch flush. Kể cả fix B1, vẫn ~200+ draw calls. | Draw calls không giảm | 🔴 Critical |
| **B3** | **Tween storm khi swipe** — mỗi ô tạo 1 Tween + lambda `queue_redraw()`. Swipe 10 ô = 10 Tweens + 10 closures + GC pressure. | Jank khi swipe | 🟡 High |
| **B4** | **draw_hand_drawn_x vector mỗi frame** — `PackedVector2Array` alloc + `draw_polyline` + `draw_circle` × 2 nét × 10 ô = 60 unbatchable draw commands. | CPU+GPU spike khi swipe animate | 🟡 High |
| **B5** | **`_draw_border` tạo StyleBoxFlat.new() mỗi frame** (puzzle_board.gd:251). | GC pressure + draw call | 🟡 Medium |
| **B6** | **`_cell_rect()` tính lại mỗi call** — không cache per-frame. | CPU minor | 🟢 Low |
| **B7** | **`draw_set_transform` per-cell** cho entry animation — phá batch. | Chỉ ~0.84s | 🟢 Low |

### 1.3 So sánh với game tham khảo (Meowdoku)

| Kỹ thuật | Meowdoku | CanDoKu hiện tại |
|----------|----------|-----------------|
| Cell BG | Node tree: `ColorRect` + SDF shader per-cell → **1 draw call** (shared material) | Immediate mode: `StyleBoxFlat` per-cell → **N² draw calls** |
| Bo góc | `cell_bg_round.gdshader` SDF + `fwidth()` AA | `StyleBoxFlat.set_corner_radius_all()` |
| Render order | Node tree tự sort → implicit layering | Interleaved per-cell loop → no batching |
| X mark animation | Sprite texture (`icon_mark_white.png`) + scale/alpha tween | CPU vector drawing (`draw_polyline` + `draw_circle`) per frame |
| Border highlight | Shader `board_pattern_highlight.gdshader` | `StyleBoxFlat.new()` per frame |

### 1.4 Tại sao SDF shader trên parent Control không khả thi

Plan v1 đề xuất gán `ShaderMaterial` lên `puzzle_board` Control node. **Không khả thi vì:**
- Godot 4: 1 CanvasItem = 1 material cho **toàn bộ** `_draw()` commands
- UV sẽ bao trùm toàn board (0.0→1.0), không per-cell
- Shader sẽ cắt góc mọi thứ: card BG, zone icons, candy textures, X marks, borders

**Meowdoku** dùng được SDF shader vì mỗi cell là node riêng (`CellView > ColorRect`) với material riêng. CanDoKu dùng immediate mode `_draw()` nên không áp dụng trực tiếp.

---

## 2. Giải pháp đề xuất (Revised)

### P1: Texture-based Rounded Rect + Layered Rendering 🔴

**Giải quyết B1 + B2 cùng lúc.**

**2.1 — White rounded-rect texture:**
- Tạo 1 texture trắng bo góc (128×128px, SVG → `ImageTexture` at runtime, hoặc pre-baked PNG)
- Dùng `draw_texture_rect(white_cell_tex, cell_rect, false, base_col)` — modulate = zone color
- 144 ô cùng 1 Texture ID → Godot auto-batch → **1 draw call** cho toàn bộ cell BG

**2.2 — Multi-pass layered rendering:**
Cấu trúc lại `puzzle_board_painter.gd` thành passes:

```
Pass 1: Cell backgrounds     → draw_texture_rect × N² (1 draw call — same texture)
Pass 2: State overlays       → draw_texture_rect × affected cells (1 draw call)
Pass 3: Zone icons (a11y)    → draw_string × cells with icons (1 draw call — font batch)
Pass 4: Static marks & candy → draw_texture_rect × placed cells (1–2 draw calls per texture)
Pass 5: Animating marks      → draw_hand_drawn_x × few cells (nhỏ, chấp nhận được)
Pass 6: Highlight borders    → draw_texture_rect(border_tex) × highlighted cells
```

**Kết quả:** ~6 draw calls thay vì ~295 cho board 12×12.

### P2: Tối ưu đánh dấu X khi swipe 🟡

**Giải quyết B3 + B4.**

**2.3 — Process-driven animation thay Tween storm:**
- Giữ `_mark_anims: Dictionary` là instance var trên `puzzle_board.gd` (tránh static state leak)
- `_process(delta)` cập nhật progress per-cell dựa trên `Time.get_ticks_msec() - start_time`
- Gọi `queue_redraw()` đúng **1 lần** cuối `_process` nếu có animation đang chạy

**2.4 — Fast-path texture cho swipe marks:**
- Khi player tap 1 ô: giữ hand-drawn vector animation (1-3 ô, chấp nhận draw cost)
- Khi player swipe (≥ 3 ô): switch sang `draw_texture_rect(mark_tex, rect, false)` + scale pop
- Tiết kiệm ~60 vector draw commands cho swipe 10 ô

### P3: Border cache + rect cache 🟢

**Giải quyết B5 + B6.**

- Thay `_draw_border` (`StyleBoxFlat.new()`) → `draw_texture_rect(border_tex, rect, false, border_color)` (hollow rounded-rect texture)
- Cache `_cell_rects: Array[Array]` — invalidate khi `configure()` hoặc `size` thay đổi

---

## 3. Ước lượng tác động

| Board size | Hiện tại (ước tính) | Sau P1 (layered + texture) | Sau P1+P2+P3 |
|-----------|--------------------|-----------------------------|--------------|
| 4×4 | ~35 | ~6 | ~4 |
| 6×6 | ~75 | ~6 | ~4 |
| 8×8 | ~135 | ~6 | ~4 |
| 10×10 | ~205 | ~6 | ~4 |
| 12×12 | ~295 | ~6 | ~4 |

---

## 4. Rủi ro và ràng buộc

- **puzzle_board.gd = 299 LOC** (sát ngưỡng 300). Logic mới PHẢI đặt trong `puzzle_board_painter.gd` (97 LOC) và `cell_animator.gd` (114 LOC)
- **Entry animation** dùng `draw_set_transform` per-cell — phá batch trong ~0.84s, chấp nhận được
- **`draw_rect(filled=false)`** cho border — cần verify trên Godot 4.7 rằng nó vẽ outline đúng cách
- **Rounded-rect texture quality** — cần test nhiều DPI, tránh mờ/vỡ pixel ở cell nhỏ (12×12 board)
- **Không có Godot profiler headless** — cần editor profiler hoặc thiết bị thực để verify draw call count
- **Constraint:** Module ≤ 300 LOC, không autoloads, asset nguyên gốc
