# Lịch sử dự án

## 2026-10-02 — Chỉnh lại gameplay và giao diện (RST-015)

Sau rebuild, chủ dự án yêu cầu bỏ auto-lock, đổi WRONG→ERROR vĩnh viễn, bật swipe và chỉnh UI. Plan ban đầu cũng yêu cầu bỏ Undo. Nhánh realignment đã có các thay đổi gameplay/UI nhưng còn giữ Undo giới hạn cho X; xem [STATUS](STATUS.md) để biết chênh lệch cần chốt và kết quả kiểm chứng.

## 2026-10-02 — Rebuild hoàn tất (RST-012→RST-014)

Rebuild hoàn chỉnh 10 modules (M01-M10), 6 waves, tất cả merge vào `dev` (PR #1–#10). 30 levels playtest sinh bằng generator offline. Module plans đã hoàn tất và dọn dẹp.

## 2026-10-01 — Playtest 30 level (RST-011)

Xác nhận mục tiêu playtest 30 level thay vì 24 level. Cập nhật docs: ARCHITECTURE, TECH_STACK, GAME_OVERVIEW, STATUS.

## 2026-09-29 — Pilot generator (RST-010), cleanup (RST-009)

Generator offline N=4-6. Dọn assets không dùng. Đồng bộ CanDoKu (RST-008).

## 2026-09-28 — CanDoKu rebrand (RST-006, RST-007, RST-008)

Đổi tên CanDoKu, GDD 0.6.0, session v3, candy/TryCandy contract.

## 2026-09-27 — Pipeline reset (RST-005)

Tag `pre-reset-pipeline-2026-09-27` (commit `8f2876d`). Thay pipeline bằng `tools/verify.py`.

```text
# Tra cứu code trước reset:
git show pre-reset-pipeline-2026-09-27:<path>
```

## 2026-09-25 — R1 mở (RST-002, RST-003, RST-004)

Mở R1 campaign 4 level. Replay campaign MVP. Bỏ ô sáng tutorial.

## 2026-09-24 — Tạm ngưng và cải tổ (RST-001)

Gom code về dev, cải tổ trên `refactor/project-reset`.
