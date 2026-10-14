# Thiết kế: Kho trợ giúp (Hint + Đặt kẹo) và streak ngày

- Ngày: 2026-10-14
- Nhánh: `feat/v1.0.1/assist-inventory` (từ `release/v1.0.1`)
- Thay thế: đoạn "hint không giới hạn" trong DECISIONS RST-024
- Tham khảo hành vi: `docs_analysis/05_LIVEOPS_MONETIZATION_VA_AB_TESTING.md` (vòng nguồn → kho → tiêu thụ), không sao chép code/tên.

## 1. Mục tiêu

1. Giới hạn số lần dùng Hint bằng kho lưu xuyên suốt.
2. Thêm trợ giúp **Đặt kẹo**: dùng là đặt ngay một kẹo đúng.
3. Lượt trợ giúp nhận qua **streak ngày chơi**; quảng cáo là nguồn tương lai, lần này chỉ đặt chỗ UI (không SDK, không ads).

Ngoài phạm vi: tích hợp quảng cáo, IAP, analytics, hiển thị streak cho người chơi.

## 2. Luật

### 2.1 Kho
- Hai loại: `hint`, `place`. Khởi đầu: **3 Hint, 1 Đặt kẹo**.
- Giới hạn tích trữ: **10 mỗi loại**; phần cộng vượt giới hạn bị bỏ.
- Kho chung, lưu bền, không gắn với level.

### 2.2 Tiêu thụ Hint
- Trừ 1 lượt **ngay khi gợi ý hiện ra**, bất kể người chơi có bấm Áp dụng hay không.
- Gợi ý `WRONG_MARK` miễn phí.
- Engine không tìm được gợi ý → không trừ.
- Kho = 0 → mở popup "Hết lượt", không chạy engine.

### 2.3 Đặt kẹo
- Chọn ô: nếu Hint engine trả nước đặt kẹo (R1) thì dùng ô đó; ngược lại chọn ô đáp án còn trống thuộc vùng có ít ô trống nhất (hòa → hàng, rồi cột nhỏ nhất).
- Nếu ô đích đang có X (người chơi X nhầm ô nghiệm) → xóa X trước.
- Đặt kẹo đúng, reset combo (theo luật combo hiện có), phát `CANDY_YES`, trừ 1 lượt.
- Nếu là viên cuối → level thắng ngay theo luồng thắng thông thường.
- Kho = 0 → popup "Hết lượt". Chỉ hoạt động khi session ở phase ACTIVE.

### 2.4 Streak ngày
- Một ngày được tính khi người chơi **thắng ít nhất một level** trong ngày (ngày lịch thiết bị, `YYYY-MM-DD` local).
- `record_win(today)`:
  - `today == lastStreakDate` → không đổi.
  - `today` là ngày kế tiếp `lastStreakDate` → `streakDays += 1`.
  - `today < lastStreakDate` (đồng hồ lùi) → bỏ qua, không đổi gì.
  - Còn lại (lần đầu hoặc lỡ ≥1 ngày) → `streakDays = 1`, xóa `usedHint`, `usedPlace`.
  - Cập nhật `lastStreakDate = today` (trừ trường hợp bỏ qua).
- Đạt `streakDays == 7` → phát gói, sau đó `streakDays = 0`, `usedHint = usedPlace = 0` (chu kỳ mới; ngày kế tiếp tính là ngày 1).
- Mỗi lần trừ lượt (2.2, 2.3) tăng bộ đếm `usedHint`/`usedPlace` tương ứng.

### 2.5 Gói thưởng 7 ngày (tính riêng từng loại)

| Số lần dùng trong chu kỳ | Thưởng |
|---|---|
| 0–1 | 2 |
| 2–4 | 3 |
| ≥ 5 | 4 |

Cộng vào kho, cắt ở 10. Thông báo bằng toast trên màn thắng ("+N Hint, +M Đặt kẹo").

## 3. Kiến trúc

| Module | Vị trí | Trách nhiệm |
|---|---|---|
| `assist_rules.gd` | `game/scripts/state/` | Static, thuần: `record_win(data, today)`, `reward_for(used)`, `grant(data, kind, n)`, so sánh ngày. Trả dữ liệu mới + gói đã phát. |
| `assist_inventory.gd` | `game/scripts/state/` | Có trạng thái: load/save qua `dual_slot_store`, `count(kind)`, `try_consume(kind) -> bool`, `on_level_won(today) -> Dictionary` (gói), signal `changed(kind, count)`. |
| `place_candy_assist.gd` | `game/scripts/core/` | Static: `pick_cell(board, size, regions, solution) -> Array` (rỗng nếu không còn ô). |
| `assist_empty_popup.gd` | `game/scripts/screens/` | Popup "Hết lượt": tiêu đề, mô tả cách nhận (chơi đủ 7 ngày), nút quảng cáo đỏ ▶ (badge góc ẩn), nút Đóng. Bấm nút đỏ → toast "Sắp có". |
| `puzzle_hint_coordinator.gd` | sửa | Kiểm/trừ kho trước khi hiện gợi ý; kho 0 → phát signal mở popup. |
| Dock màn chơi | sửa | Thêm nút Đặt kẹo cạnh Hint; bật badge số lượt cả hai nút, cập nhật theo signal `changed`. |
| `app_shell.gd` | sửa | Tạo `AssistInventory`, inject vào màn chơi; gọi `on_level_won(today)` khi thắng, chuyển gói cho màn thắng hiển thị toast. |

Không autoload, không global bus; dữ liệu đi qua injection và signal. Mỗi file ≤ 300 dòng.

### 3.1 Dữ liệu lưu

File riêng (ví dụ `user://assists.json`, dual-slot):

```json
{ "version": 1, "hint": 3, "place": 1,
  "streakDays": 0, "lastStreakDate": "",
  "usedHint": 0, "usedPlace": 0 }
```

Dữ liệu hỏng/thiếu → khôi phục từ slot còn lại; cả hai hỏng → giá trị khởi đầu. Số lượt luôn được kẹp vào `[0, 10]`.

## 4. Giao diện

- Dock: `Undo | Hint (badge) | Đặt kẹo (badge)`. Badge hiện số lượt còn lại, kể cả 0.
- Popup "Hết lượt": không hiển thị streak. Nút quảng cáo màu đỏ, biểu tượng ▶ ở giữa; badge góc (số lượt xem quảng cáo còn lại) **ẩn** cho tới khi có tính năng quảng cáo.
- Icon Đặt kẹo dùng asset gốc sẵn có (kẹo) nếu có; không thêm asset ngoài.
- Câu chữ tiếng Việt gốc, ngắn.

## 5. Kiểm thử (TDD)

- `test_assist_rules.gd`: ngày liên tiếp, cùng ngày, lỡ ngày reset bộ đếm, đồng hồ lùi bị bỏ qua, ngày 7 phát gói và bắt đầu chu kỳ mới, ngưỡng 0–1/2–4/≥5, cắt ở 10, qua tháng/năm.
- `test_assist_inventory.gd`: khởi đầu 3/1, `try_consume` tới 0 thì false, lưu/đọc lại, dữ liệu hỏng.
- `test_place_candy_assist.gd`: ưu tiên R1, fallback vùng ít ô trống, ô có X, bàn đã đầy.
- Tích hợp (`test_integration.gd`/`test_screens.gd`): Hint trừ khi hiện, `WRONG_MARK` không trừ, kho 0 mở popup, Đặt kẹo viên cuối thắng level, badge cập nhật.
- Gate đầy đủ theo AGENTS.md trước bàn giao.

## 6. Tài liệu

- DECISIONS: mục mới cho kho trợ giúp/streak; sửa RST-024 dẫn sang mục mới.
- STATUS: ghi tiến độ khi xong.
