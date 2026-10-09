# Combo feedback — design

Ngày: 2026-10-10 · Nhánh: `feat/v1.0.1/combo-feedback` (từ `release/v1.0.1`)

## Mục tiêu

Thưởng cho chuỗi đặt kẹo đúng liên tiếp bằng voice SFX (12 cấp, có sẵn trong
`game/assets/audio/sfx/sfx-combo/`) và một chữ nghệ thuật tương ứng có animation,
không làm giảm hiệu năng (không cấp phát node/texture khi đang chơi).

## Luật combo (đã chốt với người dùng)

- Mỗi lần **người chơi** đặt kẹo đúng: `streak += 1`; cấp hiển thị = `min(streak, 12)`.
- Đặt sai → `streak = 0`.
- Áp dụng hint → `streak = 0`; kẹo do hint đặt **không** cộng combo.
- Đánh X, bỏ X, undo: không ảnh hưởng.
- Level mới / restart → `streak = 0` (combo không giữ qua level).
- Hệ quả: campaign 4×4–6×6 tối đa cấp 6; cấp 7–12 chỉ xuất hiện ở bàn ≥7×7.

Thứ tự cấp: 1 nice, 2 great, 3 sweet, 4 awesome, 5 excellent, 6 amazing,
7 delicious, 8 incredible, 9 fantastic, 10 divine, 11 unstoppable, 12 legendary.

## Thành phần

| Đơn vị | Vị trí | Trách nhiệm |
|---|---|---|
| ComboTracker | `game/scripts/feedback/combo_tracker.gd` | Đếm streak thuần (`on_correct() -> int`, `break_streak()`, `reset()`), không UI |
| SfxCatalog | `game/scripts/feedback/sfx_catalog.gd` | Thêm `COMBO_1..COMBO_12` dạng `"type": "file"` |
| Combo atlas tool | `game/tools/build_combo_atlas.gd` | Offline: render 12 chữ → `assets/ui/combo/combo_atlas.png` + `.json`; `--check` xác nhận atlas khớp |
| ComboPopup | `game/scripts/screens/combo_popup.gd` | Một `Sprite2D` tái sử dụng + một `CPUParticles2D`; chạy animation |
| PuzzleScreen | `game/scripts/screens/puzzle_screen.gd` | Nối signal session → tracker → sfx + popup |

## Luồng dữ liệu

`candy_found` (do người chơi) → `tracker.on_correct()` → `sfx.play(COMBO_n)` thay cho
`CANDY_YES` → `popup.show_combo(n, vị trí ô)`.
`mistake_made` hoặc hint được áp dụng → `tracker.break_streak()`. Trong lúc hint đặt
kẹo, screen bật cờ bỏ qua để `candy_found` đó không cộng combo.

## Ảnh chữ

- Font: Nunito Bold (OFL, có trong repo). Viền nâu đậm, gradient dọc, bóng đổ.
- 3 tầng màu: 1–4 pastel (hồng/bạc hà), 5–8 rực (cam/tím), 9–12 vàng kim.
- Nội dung chữ là tiếng Anh in hoa kèm "!", khớp với voice; là tác phẩm gốc.
- Một atlas PNG duy nhất, frame cố định; rect từng chữ lưu trong JSON.

## Animation (~0.9 s, một Tween)

Pop scale 0.3 → 1.15 → 1.0 kèm xoay ±6°, giữ 0.35 s, bay lên ~40 px và fade.
Cấp ≥ 9: bắn một lượt ~12 hạt lấp lánh. Combo mới kill tween cũ và chạy lại.
Vị trí: phía trên ô vừa đặt, kẹp trong biên board. Reduced-motion: không pop,
không hạt, không di chuyển — chỉ hiện và fade.

## Hiệu năng

- 12 stream ogg nạp một lần trong `SfxPlayer._ready` (~450 KB), dùng pool voice có sẵn.
- Một texture atlas, preload; popup và particles tạo một lần khi vào màn chơi.
- Không có `_process`; chỉ Tween khi có sự kiện.

## Kiểm thử

- `test_combo_tracker.gd`: tăng, kẹp 12, mất khi sai/hint, reset.
- `test_feedback.gd`: catalog có đủ 12 effect, file tồn tại.
- Test popup: gọi `show_combo` chọn đúng rect, reduced-motion không đổi scale.
- `build_combo_atlas.gd --check`; full gate `tools/verify.py`.
- QA thủ công trên thiết bị: nghe/nhìn, không giật khung.
