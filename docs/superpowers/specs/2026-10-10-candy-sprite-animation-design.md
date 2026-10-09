# Candy sprite animation — Design

Ngày: 2026-10-10 · Trạng thái: chờ duyệt spec

## Mục tiêu

Kẹo trên board là linh vật của game (bộ mảnh SVG trong `game/assets/candy/`), có biểu cảm và chuyển động theo trạng thái gameplay, dùng một sprite atlas raster sinh offline, không làm giảm hiệu năng board kể cả 12×12.

Thành công khi:
- Có **một** atlas linh vật gồm 5 animation: `appear`, `idle`, `error`, `sad`, `win`. (Kẹo sai không nằm lại trên board — ô thành `ERROR`; kẹo đúng không xóa được — nên không có `remove` hay error-loop theo xung đột.)
- Board phát đúng animation theo bảng trigger bên dưới, cho mọi level (thay texture kẹo tĩnh theo level trên board).
- Board không redraw khi không có ô nào đổi khung; không thêm node per-cell.
- Reduced motion → mọi kẹo đứng yên ở khung 0 của trạng thái hiện tại.

## Ràng buộc

- Nguyên gốc: chỉ học cách tổ chức (atlas + JSON + trạng thái) từ `extracted_reusable/.../cat`; không dùng pixel, tên, cấu trúc file của bản tham khảo. Hình ảnh lấy từ mảnh SVG linh vật của dự án.
- Module GDScript ≤ 300 dòng, logic thuần static/stateless khi có thể, không autoload.
- TDD.

## Asset pipeline

`tools/build_candy_atlas.gd` — chạy `godot --headless --path game --script res://../tools/...` (hoặc đặt trong `game/tools/`), tất định:
- Ghép các mảnh: `shadow`, `wing_l/r` (hoặc `_sad`), `body` (hoặc `body_sad`), `face_*`, `tear` (sad).
- Mỗi khung áp transform per-part: scale X/Y (squash-stretch), offset Y (nảy), co giãn cánh theo trục X (vỗ cánh), offset X (lắc), modulate đỏ nhẹ (error). Không xoay (Image CPU không hỗ trợ xoay).
- Khung 128×128, lưới cột cố định, padding 2px; `Image.save_png`.
- Output: `game/assets/candy/anim/mascot_atlas.png` + `mascot_atlas.json`:

```json
{ "version": 1, "frame_size": [128, 128],
  "anims": { "idle": { "fps": 12, "loop": false, "frames": [[x, y], ...] }, ... } }
```

| Anim | Khung | fps | Loop | Nội dung |
|---|---|---|---|---|
| appear | 12 | 30 | không | rơi + squash, `face_surprised` → `face_normal` |
| idle | 18 | 12 | không | thở nhẹ, vỗ cánh, `face_blink` giữa chừng |
| error | 16 | 30 | không | lắc ngang, ửng đỏ, `face_surprised` |
| sad | 16 | 12 | có | `body_sad` + `wing_*_sad` + `face_sad`, `tear` rơi |
| win | 20 | 30 | không | nhảy + squash, `face_happy` → `face_heart` |

Import: VRAM compressed, mipmaps off. Tool có chế độ `--check` để verify JSON ↔ PNG.

## Runtime

- `game/scripts/screens/candy_atlas.gd` — load + cache (`static var`) atlas/JSON; `frame_rect(anim, frame) -> Rect2`.
- `game/scripts/screens/candy_anim_state.gd` — state per-cell thuần: `{anim, t, next_idle_at}`.
  - `play(cell, anim)`, `stop(cell)`, `advance(delta, motion_enabled) -> bool` (true nếu có khung đổi), `frame_of(cell) -> [anim, frame]`, `play_all(anim)`.
  - Chuỗi: appear → idle(rest); error một lượt → idle; sad loop đến khi `configure` lại (restart); win dừng khung cuối.
  - Idle: mỗi ô có `next_idle_at` ngẫu nhiên 4–7s (RNG seed theo cell để test được); tối đa `MAX_CONCURRENT_IDLE = 6` ô chạy idle cùng lúc.
- `puzzle_board.gd`: `_process` gọi `advance`; chỉ `queue_redraw()` khi trả true. `_draw_cell_candy` dùng `draw_texture_rect_region` với atlas. Fallback về texture tĩnh nếu thiếu atlas.

## Trigger

| Sự kiện | Ô | Anim |
|---|---|---|
| `play_candy_pop` | ô đặt | appear → idle |
| Given lúc vào level | ô given | idle (không appear) |
| Mất tim (còn tim) | mọi kẹo | error một lượt rồi idle |
| Hết tim → thua | mọi kẹo | sad loop (khóc) |
| `play_win_bounce` | mọi kẹo, stagger 40ms theo hàng | win |

## Hiệu năng

- 0 node mới; 1 texture dùng chung → batch được trên board 144 ô.
- Redraw chỉ khi khung đổi; idle/sad 12fps; giới hạn idle đồng thời.
- Board ẩn hoặc `motion_enabled=false` → `advance` trả false, không redraw.

## Test

- `game/tests/test_candy_anim_state.gd`: appear→idle, error một lượt (mất tim), sad loop, win dừng khung cuối + stagger, cap idle, reduced motion, advance trả false khi không đổi khung.
- `game/tests/test_candy_atlas.gd`: đủ 5 anim, rect nằm trong texture.
- Tool `--check`.
- Gate đầy đủ theo AGENTS.md (clean-room, verify.py).

## Ngoài phạm vi

Atlas cho các loại kẹo khác (`bonbon`, `lollipop`, ...), particle mới, âm thanh.


## Cập nhật 2026-10-10 — chuyển động hybrid

Để mượt ở mọi tốc độ màn hình, atlas chỉ còn giữ **hình dáng** (biểu cảm, vỗ cánh, thân/cánh buồn, nước mắt) ở vị trí cố định. Chuyển động thân (co giãn, nảy, nhảy, lắc, ửng đỏ) do `game/scripts/screens/mascot_motion.gd` tính liên tục theo `CandyAnimState.progress_of()` và được `candy_cell_drawer.gd` áp khi vẽ, neo tại chân; bóng đổ vẽ runtime và co lại khi nhảy. Board vẽ lại mỗi frame khi còn ô đang chạy, dừng hẳn khi mọi ô nghỉ. Linh vật vẽ ở `MASCOT_TEX_RATIO = 1.15` ô; idle chờ 2.5–5s.
