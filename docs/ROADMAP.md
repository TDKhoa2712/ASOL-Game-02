# Kế hoạch thực hiện

> Cập nhật: 2026-10-09. Quyền thực hiện theo [AGENTS](../AGENTS.md).
> Quản lý version: [VERSIONING](VERSIONING.md).

## Giai đoạn hiện tại: Chuẩn bị phát hành v1.0.0

Rebuild hoàn tất, gameplay/UI realignment đã merge. Dự án đang ở giai đoạn QA, hoàn thiện tài nguyên và chuẩn bị đóng gói phát hành.

### Các track còn lại

| Track | Nội dung | Trạng thái |
|-------|----------|------------|
| Track D | Hoàn thiện tài nguyên (BGM OGG, font tiếng Việt, app icon) | Tồn đọng |
| Track E | QA cử chỉ, safe area, playtest thiết bị thật | Tồn đọng |
| Track F | Đóng gói APK/AAB, keystore, mã hóa bank | Tồn đọng |

Chi tiết: [REMAINING_TASKS](REMAINING_TASKS.md)

## Giai đoạn trước (hoàn tất)

### Rebuild (hoàn tất)
Rebuild 10 modules, tất cả đã merge vào `dev` (PR #1–#10).

### System Upgrade (hoàn tất)
Solver S4–S7, DDA, ShapeFingerprint, XOR Codec, bank sizes N=4–12.

### Gameplay & UI Realignment (hoàn tất)
CellKind 5 trạng thái, bỏ auto-lock, Undo X cố định (RST-021), swipe, dựng lại màn hình.

### Content & Endless (hoàn tất)
36.500+ levels offline, Campaign 30/100/998, Endless Mode 4-tier selection.

### Tối ưu hiệu năng (hoàn tất)
Solver bitmask S4–S6, Mark X GPU batching, O(1) hash set preview/highlight, Swipe guards 3-layer.

## Sau phát hành

- Playtest mù và hiệu chỉnh difficulty
- QA iOS (cần signing/Mac)
- Quyết định mở rộng: thêm tính năng, nền tảng mới
