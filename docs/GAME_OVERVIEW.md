# CanDoKu — Tổng quan game

> Cập nhật: 2026-10-09.

## 1. Sản phẩm

CanDoKu là game puzzle suy luận 2D, chơi dọc, một người, offline. Trên bàn `NxN`, người chơi tìm đúng một viên kẹo trong mỗi hàng, cột và vùng. Kẹo không chạm nhau theo đường chéo. Chơi bằng suy luận, không đoán.

- Luật chuẩn: [GDD 02](../GDD/02-luat-choi-va-trang-thai.md)
- Kiến trúc: [ARCHITECTURE](ARCHITECTURE.md)
- Trạng thái: [STATUS](STATUS.md)

## 2. Luật cốt lõi

Với bàn `NxN`:
1. Có đúng `N` viên kẹo.
2. Mỗi hàng, cột, vùng có đúng một kẹo.
3. Hai kẹo không chạm nhau theo đường chéo.
4. Level phải có đúng một nghiệm.

## 3. Trạng thái ô — 5 trạng thái

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
| Undo | Hoàn tác lần đánh/xóa X gần nhất (luôn hoạt động — RST-021) |
| Hint | Progressive reveal (click 1: unit, click 2+: cell) |
| Restart | Tạo lại lượt sau xác nhận |

## 5. Hệ thống chính

### Ghi chú X
Đặt kẹo đúng không tự khóa các ô khác. X do người chơi đánh có thể xóa; ERROR do thử sai là vĩnh viễn trong lượt.

### Progressive Hint
- Click 1: highlight toàn bộ unit (row/col/zone) chứa bước tiếp
- Click 2+: narrow xuống cell cụ thể
- Số clicks cần thiết lấy từ pace data (hintCosts)

### Undo X
Undo lưu thao tác X gần nhất (một ô hoặc một nét kéo). Luôn hoạt động cố định trong gameplay (RST-021).

### Bank + Transform
- Levels lưu trong rank-based banks (N=4–12)
- Transform x8 (4 rotations x 2 mirrors) nhân content
- Bank cursor wraps transform khi hết levels → vô hạn replay

### Chế độ chơi
- **Campaign:** Tuyến tính, hỗ trợ 30/100/998 levels, DDA điều chỉnh rank
- **Endless:** 4-tier selection pipeline, 36.500+ levels offline

## 6. Vòng lặp người chơi

```
Home → Campaign / Endless → Puzzle board
  → Mark X (eliminate) / Double-tap (try candy)
  → Correct candy → continue
  → Wrong candy → lose heart → continue or fail
  → All candies found → Win
  → No hearts left → Fail
Win → Next level / Home
Fail → Retry / Home
```

Ba tim. Thử sai = mất tim + ERROR state. Hết tim = Fail.

## 7. Thuật ngữ

| Thuật ngữ | Nghĩa |
|-----------|-------|
| Bank | File JSON chứa levels phân nhóm theo rank |
| Pace | Sidecar chứa hint economy (rSeq, hintCosts) |
| Playlist | Campaign file tham chiếu vào bank |
| Transform | Rotation/mirror variant của level (x8) |
| GIVEN | Pre-placed candy từ level data |
| ERROR | Ô thử kẹo sai, X đỏ không xóa được trong lượt |
| Progressive hint | Hint reveal theo stages (unit → cell) |
| DDA | Dynamic Difficulty Adjustment — tự động bù rank theo chuỗi thắng/thua |
