# CanDoKu — Tổng quan game

> Cập nhật: 2026-10-02.

## 1. Sản phẩm

CanDoKu là game puzzle suy luận 2D, chơi dọc, một người, offline. Trên bàn `NxN`, người chơi tìm đúng một viên kẹo trong mỗi hàng, cột và vùng. Kẹo không chạm nhau theo đường chéo. Chơi bằng suy luận, không đoán.

- Luật chuẩn: [GDD 02](../GDD/02-luat-choi-va-trang-thai.md)
- Kiến trúc: [ARCHITECTURE](ARCHITECTURE.md)
- Rebuild plan: [Master plan](superpowers/plans/2026-10-02-rebuild-master.md)

## 2. Luật cốt lõi

Với bàn `NxN`:
1. Có đúng `N` viên kẹo.
2. Mỗi hàng, cột, vùng có đúng một kẹo.
3. Hai kẹo không chạm nhau theo đường chéo.
4. Level phải có đúng một nghiệm.

## 3. Trạng thái ô — 6 states

| State | Name | Ý nghĩa | Player editable |
|-------|------|---------|-----------------|
| 0 | BLANK | Chưa đánh dấu | Yes |
| 1 | MARK | X do player đặt | Yes |
| 2 | CANDY | Kẹo player tìm đúng | No |
| 3 | WRONG | Thử kẹo sai | No |
| 4 | GIVEN | Kẹo pre-placed từ level data | No |
| 5 | LOCKED | Auto-marked (bị loại bởi candy/given) | No |

## 4. Điều khiển

| Thao tác | Kết quả |
|----------|---------|
| Chạm đơn | Đặt/xóa X mark |
| Kéo | Đặt X qua nhiều ô (swipe interpolation) |
| Chạm đôi | Thử tìm kẹo |
| Undo | Hoàn tác action gần nhất (grouped: candy + auto-marks) |
| Hint | Progressive reveal (click 1: unit, click 2+: cell) |
| Restart | Tạo lại lượt sau xác nhận |

## 5. Hệ thống chính

### Auto-mark
Khi đặt candy đúng (hoặc level có GIVEN cells), hệ thống tự động lock tất cả ô cùng row/col/zone/diagonal. Cells bị lock hiển thị mờ với X xám nhạt. Player không cần mark thủ công.

### Progressive Hint
- Click 1: highlight toàn bộ unit (row/col/zone) chứa bước tiếp
- Click 2+: narrow xuống cell cụ thể
- Số clicks cần thiết lấy từ pace data (hintCosts)

### Grouped Undo
- Đặt candy + tất cả auto-marks = 1 nhóm undo
- Undo 1 lần = hoàn tác candy + tất cả locks liên quan
- Sau undo, recompute locks từ candies/givens còn lại

### Bank + Transform
- Levels lưu trong rank-based banks (bank_4x4.json)
- Transform x8 (4 rotations x 2 mirrors) nhân content
- Bank cursor wraps transform khi hết levels → vô hạn replay

## 6. Vòng lặp người chơi

```
Home → Play → Puzzle board
  → Mark X (eliminate) / Double-tap (try candy)
  → Correct candy → auto-mark locks → continue
  → Wrong candy → lose heart → continue or fail
  → All candies found → Win
  → No hearts left → Fail
Win → Next level / Home
Fail → Retry / Home
L30 Win → Replay from L01
```

Ba tim. Thử sai = mất tim + WRONG state. Hết tim = Fail.

## 7. Mục tiêu playtest 30 level

- 30 levels gốc (12 easy + 10 medium + 8 hard)
- N=4-6, S1-S3 reasoning
- Campaign tuyến tính L01→L30
- Tutorial ở L01
- Save/resume, settings persist

### Không thuộc playtest
Endless, daily, leaderboard, account, cloud save, ads, IAP, N>6, S4/S5.

## 8. Thuật ngữ

| Thuật ngữ | Nghĩa |
|-----------|-------|
| Bank | File JSON chứa levels phân nhóm theo rank |
| Pace | Sidecar chứa hint economy (rSeq, hintCosts) |
| Playlist | Campaign file tham chiếu vào bank |
| Transform | Rotation/mirror variant của level (x8) |
| Auto-mark | System tự lock cells sau candy/given placement |
| GIVEN | Pre-placed candy từ level data |
| LOCKED | Cell bị auto-mark, không tương tác được |
| Progressive hint | Hint reveal theo stages (unit → cell) |
| Grouped undo | Candy + auto-marks undo cùng lúc |
