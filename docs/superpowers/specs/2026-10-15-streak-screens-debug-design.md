# Streak screens và debug Streak/Assist — Design

Ngày: 2026-10-15 · Nhánh nền: `feat/v1.0.1/assist-inventory`

## 1. Mục tiêu

Hoàn thiện trải nghiệm chuỗi ngày (streak) và assist inventory:

1. Màn **Kích hoạt chuỗi** riêng sau màn chơi kết thúc đầu tiên trong ngày.
2. Màn **Chuỗi** riêng khi nhấn nút lửa ở Home (thay popup `streak_sheet`).
3. **Debug** cho chuỗi/assist, và rà soát + sửa bug các tính năng debug hiện có.

## 2. Quyết định đã chốt với chủ dự án

| # | Quyết định |
|---|-----------|
| Q1 | Luồng màn đầu tiên trong ngày: **Kích hoạt chuỗi → (ngày 7: Nhận quà) → Win/Lose**. |
| Q2 | Mọi màn kết thúc (thắng hoặc thua) đều kích hoạt, giữ luật RST-032. Màn custom/tutorial vẫn bị loại trừ như RST-030. |
| Q3 | Bỏ hiệu ứng +1 trên bàn (`streak_burst`) và toast `assist.reward`; màn mới thay thế. |
| Q4 | Ngày 7: màn **Nhận quà riêng** nằm giữa màn Kích hoạt và Win/Lose, hiển thị số hint/place nhận được. |
| Q5 | "Frame" = 7 ô ngày của chu kỳ (đã đạt / hôm nay / còn lại). |
| Q6 | Màn Chuỗi: title phía trên, nút trở về, dải 7 ô, hộp quà ở cuối chuỗi. Bỏ chữ `streak.left`, `streak.kept` (và các câu trạng thái tương tự). |
| Q7 | Hộp quà là **animation** do chủ dự án cung cấp sau; hiện dùng placeholder thay thế được (một scene/slot duy nhất). |
| Q8 | Debug chuỗi/assist: giả ngày/nhảy ngày, chỉnh kho assist, xem trước các màn mới, công tắc "level debug được tính chuỗi" (mặc định tắt) trong menu debug. |
| Q9 | Debug khác: rà soát bug ở chọn level (picker, endless, reset) và tính năng debug trong màn chơi (thanh Cheats); lập danh sách để chủ dự án duyệt trước khi sửa. |
| Q11 | Khi mất chuỗi (lỡ ≥1 ngày), số chuỗi hiển thị về **0 ngay** (không chờ chơi màn mới); dòng "Kỷ lục: N" luôn hiện, giữ giá trị cao nhất từng đạt. |
| Q12 | Ngày giả và công tắc "level debug tính chuỗi" chỉ sống trong phiên, không ghi save. Xem trước màn dùng dữ liệu giả, không đổi save thật. |
| Q10 | Mọi nhánh con tạo từ `feat/v1.0.1/assist-inventory` và merge về nhánh này. |

## 3. Thiết kế

### 3.1 Thành phần dùng chung (Plan B)

- `screens/streak_cycle_strip.gd`: dải 7 ô nhận `streak_view` (`count`, `kept_today`, `cycle_done`), đánh dấu ô đã đạt / hôm nay / còn lại; ô 7 chứa slot hộp quà.
- `screens/gift_box_view.gd` (+ scene): slot hộp quà với API `play_idle()`, `play_open()`, signal `opened`. Placeholder vẽ bằng code/SVG nguyên gốc; khi có animation thật chỉ thay nội dung scene này.

### 3.2 Màn Chuỗi (Plan B)

- Thêm `NavController.Screen.STREAK`, scene `scenes/streak.tscn`, script `screens/streak_screen.gd`.
- Nội dung: title, nút back (về Home), ngọn lửa + số ngày (`flame_fx`), dải 7 ô, hộp quà, dòng "Kỷ lục: N" (Q11). `AssistRules.streak_view` trả `count = 0` khi khoảng cách từ `lastStreakDate` tới hôm nay ≥ 2 (áp dụng cả `streak_chip` ở Home); có test. Không có câu "Còn … ngày", "Hôm nay đã …".
- `streak_chip` khi nhấn → `nav.go_to(STREAK)` thay vì mở `streak_sheet`. Gỡ `streak_sheet.gd` và các key locale không còn dùng.

### 3.3 Màn Kích hoạt và Nhận quà (Plan A)

- `AssistInventory.on_round_finished` trả về (hoặc phát signal) kết quả gồm: `extended: bool`, `streak_view`, `reward: {hint, place}` (rỗng nếu không phải ngày 7).
- `app_shell._on_level_done`: nếu `extended` → đi `STREAK_ACTIVATE` (màn mới) → nếu có reward → `STREAK_GIFT` → rồi WIN hoặc FAIL như cũ, giữ nguyên tham số setup của Win/Fail.
- Màn Kích hoạt: lửa sáng lên, ô hôm nay được điền, nút Tiếp tục.
- Màn Nhận quà: `gift_box_view.play_open()`, hiển thị +hint/+place, nút Tiếp tục.
- Gỡ `StreakBurst` khỏi puzzle screen và toast reward khỏi `puzzle_assist_controller`.
- Cập nhật DECISIONS: sửa RST-031/RST-032 theo Q1–Q4.

### 3.4 Debug Streak/Assist (Plan C)

- Nguồn ngày inject được: `state/day_clock.gd` (instance, tạo ở `app_shell`, truyền vào inventory), có `today()` và `offset_days`. Không dùng autoload.
- Tab "Streak/Assist" trong debug picker (chỉ `OS.is_debug_build()`):
  - Ngày: +1 ngày, bỏ lỡ 1 ngày (+2), về ngày thật; hiển thị ngày giả hiện tại.
  - Đặt vị trí chu kỳ 0–6, reset chuỗi.
  - Kho: +/− hint, +/− place, reset kho.
  - Xem trước: mở màn Chuỗi, Kích hoạt, Nhận quà với dữ liệu giả, không ghi save.
  - Công tắc "Level debug tính chuỗi" (mặc định tắt, chỉ sống trong phiên).
- Offset ngày chỉ tồn tại trong phiên, không ghi vào save.

### 3.5 Rà soát và sửa debug (Plan D1/D2)

- D1 (chỉ đọc + chạy thử): rà `debug_level_picker`, `debug_endless_panel`, `debug_reset_bar`, `puzzle_debug_bar`, luồng `_debug_mode` trong `app_shell`. Xuất danh sách bug (bước tái hiện, kỳ vọng, thực tế, file:dòng) tại `scratch/verification/debug-audit-2026-10-15.md`. Dừng chờ duyệt.
- D2: sửa từng bug đã duyệt, TDD, mỗi bug một commit.

## 4. Kiểm thử

- TDD cho mọi plan; suite liên quan: `test_assist_*`, `test_streak_ui`, `test_screens`, `test_integration`, `test_debug_features`, `test_debug_level_picker`.
- Test mới: luồng nav Kích hoạt → Quà → Win/Fail; màn không hiện khi cùng ngày / màn custom; day_clock offset; công tắc debug tính chuỗi.
- Gate trước merge: `tools/clean_room.py`, `tools/verify.py`. Module ≤ 300 dòng.
- QA giao diện/thiết bị ghi vào STATUS là còn mở.

## 5. Ngoài phạm vi

Streak freeze, IAP/ads, đổi luật tính phần thưởng, bật debug trong bản release.
