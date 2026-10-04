# Asset Backlog — Visual & Fonts

Danh sách sprites, icons, fonts cần bổ sung cho CanDoKu.
Mọi asset phải là tác phẩm gốc — không sao chép giao diện, nhân vật, tên thương mại từ reference.

## Chuẩn kỹ thuật chung

- Sprite: PNG @1x và @2x, hoặc SVG khi hình học đơn giản (icon)
- Palette thống nhất với `game/theme/`; kiểm tra colorblind (`test_colorblind.gd`)
- 9-patch cho mọi UI kéo giãn (dialog, toast, button)
- Đặt dưới `game/assets/` theo cấu trúc thư mục tương ứng

---

## A. Fonts (`game/assets/fonts/`)

Thư mục chưa tồn tại. Cần tạo mới.

| # | File | Vai trò | Yêu cầu |
|---|------|---------|---------|
| 1 | Font chính (sans) .ttf | Toàn bộ UI text | Regular + Bold, hỗ trợ Latin + Vietnamese đầy đủ. Gợi ý open-source: Inter, Nunito, Be Vietnam Pro |
| 2 | Font số/HUD .ttf | Số to ở progress/score | Monospace hoặc tabular figures, nét đậm |
| 3 | Các `.tres` FontFile | Cấu hình Godot | Khai báo subpixel, outline, size presets nhất quán |

---

## B. Title / Home Screen

Hiện dùng tạm `candy.svg` làm logo và 2 icon tròn.

| # | File | Vai trò | Kích thước gợi ý |
|---|------|---------|-------------------|
| 1 | `logo_candoku.png` (hoặc .svg) | Logo game gốc | @1x + @2x |
| 2 | `title_bg.png` (hoặc gradient) | Nền title riêng | full screen, tile hoặc stretch |
| 3 | `btn_play.png` | Nút Play nổi bật | ~300×80 @1x, 9-patch nếu text thay đổi |

---

## C. Puzzle Board

Icon tròn đã có: back, help, restart, settings, undo, hint.

| # | File | Vai trò | Ghi chú |
|---|------|---------|---------|
| 1 | Bộ candy sprites (4–6 hình) | Kẹo theo màu/hình cho N=4,5,6 | Phong cách nhất quán, dễ phân biệt khi colorblind |
| 2 | `heart_full.svg` + `heart_empty.svg` | Lives (nếu giữ cơ chế) | Hiện chỉ có `heart.svg` |
| 3 | `x_preview.svg` + `x_confirmed.svg` | 2 trạng thái dấu X | Nhánh hiện đang chỉnh double-tap X |
| 4 | `pencil_mark.svg` | Chế độ ghi chú (nếu có) | Nhỏ, nhẹ, semi-transparent |
| 5 | `cell_highlight.png` | Overlay cho hint + conflict | Có alpha, 2 màu (hint/conflict) |
| 6 | `region_border.png` | Đường kẻ dày phân vùng | Tileable, RegionPainter dùng |

---

## D. Toast / Feedback

| # | File | Vai trò |
|---|------|---------|
| 1 | `toast_bg_9patch.png` | Nền thông báo kéo giãn |
| 2 | `toast_arrow.png` | Mũi tên bong bóng chỉ ô |

---

## E. Win / Fail / Result Screen

| # | File | Vai trò |
|---|------|---------|
| 1 | `win_banner.png` | Banner thắng |
| 2 | `win_rays.png` | Ánh sáng toả (decoration) |
| 3 | `fail_banner.png` | Banner thua |
| 4 | `star_full.png` + `star_empty.png` | Chấm điểm sao |
| 5 | `btn_next.png` | Nút chơi level tiếp |
| 6 | `btn_retry.png` | Nút chơi lại |

---

## F. Settings / Options Screen

Có 4 icon SVG (audio/haptic/motion/large_text). Cần thêm:

| # | File | Vai trò |
|---|------|---------|
| 1 | `icon_music_on.svg` + `icon_music_off.svg` | Toggle nhạc |
| 2 | `icon_sound_on.svg` + `icon_sound_off.svg` | Toggle âm thanh |
| 3 | `icon_vibrate_on.svg` + `icon_vibrate_off.svg` | Toggle rung |
| 4 | `icon_colorblind.svg` | Chế độ colorblind |
| 5 | `switch_track.png` + `switch_knob.png` | Custom switch (nếu không dùng CheckButton mặc định) |

---

## G. Common UI

| # | File | Vai trò |
|---|------|---------|
| 1 | `dialog_frame_9patch.png` | Khung dialog chung |
| 2 | `btn_primary_9patch.png` | Nút chính |
| 3 | `btn_secondary_9patch.png` | Nút phụ |
| 4 | `btn_close.png` | Nút đóng |
| 5 | `bg_gradient.png` hoặc `bg_pattern.png` | Nền ứng dụng |

---

## H. Export / Platform

| # | File | Vai trò | Kích thước |
|---|------|---------|------------|
| 1 | `icon.svg` hoặc `icon_1024.png` | Biểu tượng app (hiện trỏ `candy.svg`) | 1024×1024 |
| 2 | `splash.png` | Ảnh splash khởi động | full screen |
| 3 | `boot_splash.png` | Nhiều tỉ lệ nếu publish mobile | theo platform |

---

## Checklist bàn giao mỗi asset

- [ ] Tên file đúng danh sách, snake_case
- [ ] Không sao chép giao diện/nhân vật/tên thương mại từ reference
- [ ] Palette khớp theme hiện tại; pass colorblind test
- [ ] PNG có @2x; SVG cho icon đơn giản
- [ ] 9-patch có margin đúng, test kéo giãn các hướng
- [ ] `.import` file được Godot tạo lại sau khi copy vào `game/assets/`
- [ ] Credit/nguồn ghi trong `docs/CREDITS.md` (nếu dùng asset free/purchased)
