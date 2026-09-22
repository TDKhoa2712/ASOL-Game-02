# Quy trình quản lý gói việc (Work Package Pipeline)

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
