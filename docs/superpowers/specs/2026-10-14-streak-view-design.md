# Thiết kế: Xem chuỗi ngày chơi (kiểu viên lửa)

- Ngày: 2026-10-14
- Nhánh: `feat/v1.0.1/assist-inventory` (dùng chung dữ liệu streak của [assist inventory](2026-10-14-assist-inventory-design.md))
- Phong cách: viên lửa + số ngày, lấy cảm hứng chung từ chuỗi ngày của mạng xã hội; icon, câu chữ, bố cục là bản gốc, không dùng tài sản/nhận diện của TikTok.

## 1. Mục tiêu

Cho người chơi thấy chuỗi ngày liên tiếp đã thắng ít nhất một màn, kỷ lục, tiến độ tới gói quà 7 ngày, và cảnh báo khi sắp mất chuỗi.

Ngoài phạm vi: popup "Hết lượt" vẫn không hiển thị streak (RST-029); lịch tháng; thông báo đẩy.

## 2. Dữ liệu

Thêm vào file `assists` (không migrate; thiếu → 0):

| Trường | Ý nghĩa |
|---|---|
| `totalStreak` | Số ngày liên tiếp đã thắng ≥1 màn; không reset khi nhận gói 7 ngày |
| `bestStreak` | Kỷ lục `totalStreak` |

Sanitize: số nguyên ≥ 0 (giới hạn 100000); `bestStreak = max(bestStreak, totalStreak)`.

`record_win(data, today)` (bổ sung luật của RST-029):
- Cùng ngày / ngày lùi → không đổi (như cũ).
- Ngày kế tiếp → `totalStreak += 1`.
- Lần đầu hoặc lỡ ngày → `totalStreak = 1`.
- Luôn `bestStreak = max(bestStreak, totalStreak)`.
- Phát gói 7 ngày không đổi `totalStreak`.

`streak_view(data, today) -> Dictionary`:

| Khóa | Giá trị |
|---|---|
| `count` | `totalStreak` nếu `lastStreakDate` là hôm nay hoặc hôm qua; ngược lại 0 |
| `best` | `bestStreak` |
| `kept_today` | `lastStreakDate == today` |
| `at_risk` | `count > 0` và chưa `kept_today` |
| `cycle_done` | số ô chu kỳ đã đạt: `streakDays` nếu chuỗi còn sống, ngược lại 0 (0–6) |

## 3. Giao diện

### 3.1 Viên lửa trên Home
- Canh giữa theo chiều ngang, cùng hàng với nút Trợ giúp/Cài đặt; không phụ thuộc nút debug.
- Viên bo tròn: icon lửa + `count`.
- Màu: cam khi `kept_today`; xám khi chưa.
- `at_risk`: viên nhấp nháy nhẹ (scale/alpha lặp); tắt khi giảm chuyển động (`LayoutTokens.motion_enabled == false`).
- Chạm → mở bảng chuỗi. Hiện cả khi `count == 0`.

### 3.2 Bảng chuỗi
- Lửa lớn (cam/xám), số `count`, "ngày liên tiếp", "Kỷ lục: N ngày".
- Hàng 7 ô: `cycle_done` ô có lửa, các ô còn lại trống, ô thứ 7 là hộp quà; dòng "Còn K ngày để nhận quà" (K = 7 − `cycle_done`).
- Trạng thái: `kept_today` → "✓ Hôm nay đã giữ chuỗi"; `at_risk` → "Thắng 1 màn hôm nay để giữ chuỗi trước nửa đêm"; `count == 0` → "Thắng 1 màn để bắt đầu chuỗi".
- Nút Đóng; chạm nền tối cũng đóng.

### 3.3 Hiệu ứng +1
- Chỉ khi một lần thắng làm tăng hoặc bắt đầu chuỗi (lần thắng đầu trong ngày, màn không custom).
- Trên bàn chơi trong lúc giữ kết quả thắng: lửa bung to, số đổi từ `count − 1` sang `count`. Có gói 7 ngày thì toast gói hiện sau hiệu ứng.
- Giảm chuyển động: hiển thị tĩnh số mới, không tween.

### 3.4 Icon
`game/assets/ui/home/icon_flame.svg` vẽ mới (gốc), một màu trắng để tô màu bằng `modulate`.

## 4. Kiến trúc

| Module | Trách nhiệm |
|---|---|
| `assist_rules.gd` | Thêm trường, luật `record_win`, `streak_view` |
| `assist_inventory.gd` | `signal streak_extended(total: int)`; `streak_view(today := "")` |
| `streak_chip.gd` (screens) | Viên lửa; `bind(inventory)`; `signal pressed_chip()` |
| `streak_sheet.gd` (screens) | Bảng chuỗi; `open(view: Dictionary)` |
| `streak_burst.gd` (screens) | Hiệu ứng +1; `play(parent, total)` |
| `puzzle_assist_controller.gd` | Nghe `streak_extended` → `StreakBurst.play` |
| `title_screen.gd` | Thêm viên lửa + bảng chuỗi (vài dòng; ≤ 300) |
| `app_shell.gd` | Gán `assists` cho Home trên cùng dòng gọi `setup` (giữ ≤ 300) |

## 5. Kiểm thử

- Luật: tổng tăng theo ngày, lỡ ngày về 1, gói 7 ngày không reset tổng, kỷ lục, sanitize, `streak_view` (hôm nay/hôm qua/đứt, at_risk, cycle_done).
- Inventory: `streak_extended` chỉ phát khi tổng đổi.
- UI: màu theo trạng thái, nhấp nháy khi at_risk, nội dung bảng, viên lửa canh giữa, burst chỉ chạy ở lần thắng đầu ngày.
- Full gate theo AGENTS.md.
