# Kế hoạch thực hiện

> Cập nhật: 2026-10-02. Quyền thực hiện theo [AGENTS](../AGENTS.md).

## Giai đoạn hiện tại: Rebuild

Rebuild hoàn chỉnh CanDoKu từ thiết kế tham khảo `extracted_reusable/`. Code viết mới, clean-room. Plan: [Master plan](superpowers/plans/2026-10-02-rebuild-master.md).

### 10 modules, 6 waves

| Wave | Modules | Mục tiêu |
|------|---------|----------|
| 1 | M01 Core + M05 Theme | Domain logic 6-state, auto-mark, palette |
| 2 | M02 State + M03 Content + M04 Input | Persistence, bank/pace/transform, touch/undo |
| 3 | M06 Feedback + M07 Campaign | SFX rate limiting, campaign runtime + cursor |
| 4 | M08 Screens | UI screens with GIVEN/LOCKED rendering |
| 5 | M09 Integration | End-to-end wiring, clean-room check, full test |
| 6 | M10 Content Generation | 30 levels data, pace sidecars, campaign playlist |

**Kết quả:** Game chơi được 30 levels (auto-mark, undo, progressive hints, save/load).

## Sau Rebuild: Playtest

- Phân phối build hạn chế
- Thu dữ liệu: thời gian giải, Hint, lỗi, bỏ cuộc, UX
- QA Android (iOS cần signing/Mac)
- Hiệu chỉnh difficulty, tutorial, feedback

## Sau Playtest: Quyết định phát hành

Chủ dự án quyết định: số level, nền tảng, Endless mode, tiêu chí phát hành.

## Ngoài phạm vi hiện tại

Endless UI, IAP, ads, analytics, account, cloud save, N > 6, S4/S5 rules, runtime level gen.
