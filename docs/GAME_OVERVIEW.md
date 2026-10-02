# CanDoKu — Tổng quan game

> Cập nhật: 2026-10-03.

## 1. Sản phẩm

CanDoKu là game puzzle suy luận 2D, chơi dọc, một người, offline. Trên bàn `NxN`, người chơi tìm đúng một viên kẹo trong mỗi hàng, cột và vùng. Kẹo không chạm nhau theo đường chéo. Chơi bằng suy luận, không đoán.

- Luật chuẩn: [GDD 02](../GDD/02-luat-choi-va-trang-thai.md)
- Kiến trúc: [ARCHITECTURE](ARCHITECTURE.md)
- Plan hiện tại: [Gameplay & UI Realignment](superpowers/plans/2026-10-02-gameplay-ui-realign.md)

## 2. Luật cốt lõi

Với bàn `NxN`:
1. Có đúng `N` viên kẹo.
2. Mỗi hàng, cột, vùng có đúng một kẹo.
3. Hai kẹo không chạm nhau theo đường chéo.
4. Level phải có đúng một nghiệm.

## 3. Trạng thái ô — 5 trạng thái trên nhánh realignment

| State | Name | Ý nghĩa | Player editable |
|-------|------|---------|-----------------|
| 0 | BLANK | Chưa đánh dấu | Yes |
| 1 | MARK | X do player đặt | Yes |
| 2 | CANDY | Kẹo player tìm đúng | No |
| 3 | ERROR | Thử kẹo sai, X đỏ không xóa được | No |
| 4 | GIVEN | Kẹo pre-placed từ level data | No |

## 4. Điều khiển

| Thao tác | Kết quả |
|----------|---------|
| Chạm đơn | Đặt/xóa X mark |
| Kéo | Đặt hoặc xóa X qua nhiều ô (swipe interpolation) |
| Chạm đôi | Thử tìm kẹo |
| Undo | Hoàn tác lần đánh/xóa X gần nhất; không hoàn tác kẹo hoặc lỗi |
| Hint | Progressive reveal (click 1: unit, click 2+: cell) |
| Restart | Tạo lại lượt sau xác nhận |

## 5. Hệ thống chính

### Ghi chú X
Đặt kẹo đúng không tự khóa các ô khác. X do người chơi đánh có thể xóa; ERROR do thử sai là vĩnh viễn trong lượt.

### Progressive Hint
- Click 1: highlight toàn bộ unit (row/col/zone) chứa bước tiếp
- Click 2+: narrow xuống cell cụ thể
- Số clicks cần thiết lấy từ pace data (hintCosts)

### Undo hiện có trên nhánh
Undo chỉ lưu thao tác X gần nhất (một ô hoặc một nét kéo). RST-015 và plan ban đầu yêu cầu bỏ Undo; xem chênh lệch chưa chốt trong [STATUS](STATUS.md).

### Bank + Transform
- Levels lưu trong rank-based banks (bank_4x4.json)
- Transform x8 (4 rotations x 2 mirrors) nhân content
- Bank cursor wraps transform khi hết levels → vô hạn replay

## 6. Vòng lặp người chơi

```
Home → Play → Puzzle board
  → Mark X (eliminate) / Double-tap (try candy)
  → Correct candy → continue
  → Wrong candy → lose heart → continue or fail
  → All candies found → Win
  → No hearts left → Fail
Win → Next level / Home
Fail → Retry / Home
L30 Win → Replay from L01
```

Ba tim. Thử sai = mất tim + ERROR state. Hết tim = Fail.

## 7. Mục tiêu playtest 30 level

- 30 level 4×4 đã sinh: 12 rank 1, 10 rank 2, 8 rank 3; nhãn khó chưa được playtest mù hiệu chỉnh
- N=4–6, S1–S3 là giới hạn thiết kế; bank hiện có chỉ 4×4
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
| GIVEN | Pre-placed candy từ level data |
| ERROR | Ô thử kẹo sai, X đỏ không xóa được trong lượt |
| Progressive hint | Hint reveal theo stages (unit → cell) |
| Undo mark | Hoàn tác thao tác X gần nhất trên nhánh hiện tại |
