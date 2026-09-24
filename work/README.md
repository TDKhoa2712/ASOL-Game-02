# Hồ sơ work package cũ — HISTORICAL

Từ ngày 2026-09-24, toàn bộ package/state/handoff/evidence cũ được giữ tại chỗ để bảo toàn liên kết và bằng chứng. Không nhận việc mới hoặc thay đổi trạng thái theo pipeline này. Các trạng thái bên dưới là ảnh chụp lịch sử, không biểu thị công việc đang chạy.

Quy trình mới: [AGENTS](../AGENTS.md). Tiến độ và công việc hiện tại: [STATUS](../docs/STATUS.md), [ROADMAP](../docs/ROADMAP.md). Asset brief là tài liệu tham khảo, không phải lệnh sản xuất asset trong thời gian tạm ngưng.

## Mô tả quy trình trước cải tổ (không còn áp dụng)

Thư mục `work/` quản lý toàn bộ các hợp đồng gói việc, trạng thái thực thi, biên bản bàn giao và bằng chứng kiểm chứng.

## Cấu trúc thư mục

- `packages/`: Hợp đồng gói việc (Work package contracts) định dạng Markdown với TOML front matter `+++`.
- `state/`: Trạng thái động của gói việc khi đang thực thi (mutable execution state).
- `handoffs/`: Báo cáo bàn giao kết quả của agent khi hoàn thành package.
- `evidence/`: Bằng chứng kiểm chứng tự động (`verification.txt`) sinh ra bởi pipeline.
- `templates/`: Bản mẫu chuẩn cho package (`package.md`) và handoff (`handoff.md`).

## Quy trình làm việc tiêu chuẩn

1. **Xem gói việc:** `python tools/agent_pipeline.py inspect <package-id>`
2. **Bắt đầu (Coordinator / Agent):** `python tools/agent_pipeline.py start <package-id> --agent <agent-name>`
3. **Kiểm chứng:** `python tools/agent_pipeline.py verify <package-id>`
4. **Bàn giao:** Điền báo cáo tại `work/handoffs/<package-id>.md` và chạy `python tools/agent_pipeline.py handoff <package-id>`
5. **Nghiệm thu (Reviewer):** `python tools/agent_pipeline.py accept <package-id>`
