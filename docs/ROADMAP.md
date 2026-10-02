# Kế hoạch thực hiện

> Cập nhật: 2026-10-03. Quyền thực hiện theo [AGENTS](../AGENTS.md).

## Giai đoạn hiện tại: Chỉnh lại Gameplay & UI

Căn chỉnh gameplay và giao diện theo nguồn tham khảo `extracted_reusable/` và layout cũ `archive/legacy_pre_rebuild/`. Plan: [Gameplay & UI Realignment](superpowers/plans/2026-10-02-gameplay-ui-realign.md).

### Thay đổi chính

| Thay đổi | Chi tiết |
|----------|----------|
| Bỏ auto-lock | Không lock cells khi đặt candy |
| CellKind 5-state | BLANK, MARK, CANDY, ERROR, GIVEN (bỏ LOCKED, WRONG→ERROR) |
| Undo X | Code hiện giữ Undo cho thao tác X gần nhất; cần chốt chênh lệch với RST-015 |
| Bật swipe | Paint/clear X trên nhiều ô |
| UI layout legacy | Programmatic build: TopBar, StatusRow, RuleCard, BoardCard, BottomDock |

**Đầu ra cần nghiệm thu:** Luồng 30 level 4×4, Hint, save/load, cử chỉ và giao diện trên thiết bị. Code nhánh realignment đã triển khai nhiều hạng mục; kết quả headless và QA xem [STATUS](STATUS.md).

## Giai đoạn trước: Rebuild (hoàn tất)

Rebuild hoàn chỉnh 10 modules với code viết mới, tham khảo hành vi từ `extracted_reusable/`. Tất cả module đã merge vào `dev` (PR #1–#10). Bank playtest hiện có 30 level 4×4; 5×5/6×6 chưa có nội dung tương ứng.

## Sau Chỉnh sửa: Playtest

- Phân phối build hạn chế
- Thu dữ liệu: thời gian giải, Hint, lỗi, bỏ cuộc, UX
- QA Android (iOS cần signing/Mac)
- Hiệu chỉnh difficulty, tutorial, feedback

## Sau Playtest: Quyết định phát hành

Chủ dự án quyết định: số level, nền tảng, Endless mode, tiêu chí phát hành.

## Ngoài phạm vi hiện tại

Endless UI, IAP, ads, analytics, account, cloud save, N > 6, S4/S5 rules, runtime level gen.
