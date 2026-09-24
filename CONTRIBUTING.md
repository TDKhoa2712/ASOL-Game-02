# Hướng dẫn đóng góp (Contributing Guide)

Quy trình hiện hành nằm tại [AGENTS.md](AGENTS.md). Đọc [STATUS](docs/STATUS.md) trước khi làm việc; game đang tạm ngưng triển khai để cải tổ trên `refactor/project-reset` từ `dev`.

Giao việc theo kết quả trong [ROADMAP](docs/ROADMAP.md), không theo mã package. Hướng dẫn chạy nằm ở [README](README.md). Dùng commit rõ mục đích; kiểm chứng phù hợp trước khi bàn giao và tích hợp.

## Bản quy trình cũ — SUPERSEDED

Phần dưới giữ để truy vết; không áp dụng các yêu cầu package/allowed_paths/start/verify/handoff/accept cho công việc mới. Xem [RST-001](docs/DECISIONS.md).

## 1. Nguyên tắc làm việc với Work Package

1. **Giao việc:** Con người (Coordinator / Lead) giao chính xác một mã work package ID. Agent không được tự chọn hoặc nhận việc ngoài package được giao.
2. **Quy tắc phân nhánh:** Mỗi package thực thi trên nhánh Git riêng theo định dạng:
   ```text
   work/<lowercase-id>-<slugified-title>
   ```
   Ví dụ: `work/m0-a01-godot-toolchain-and-device-baseline`.
3. **Kiểm tra trước khi sửa:** Chạy `python tools/agent_pipeline.py inspect <package-id>` để xem phạm vi `allowed_paths`, deliverables, tài liệu cần đọc (`read_first`) và các lệnh kiểm chứng.
4. **Phạm vi thay đổi (`allowed_paths`):** Chỉ sửa các file nằm trong danh sách `allowed_paths`. Tuyệt đối không sửa file ngoài scope.
5. **Kiểm chứng (`verify`):** Chạy `python tools/agent_pipeline.py verify <package-id>`. Lệnh này chạy toàn bộ test, lưu bằng chứng gọn tại `work/evidence/<package-id>/verification.txt` và đối chiếu diff Git với scope.
6. **Bàn giao (`handoff`):** Tạo và điền đầy đủ báo cáo bàn giao tại `work/handoffs/<package-id>.md` trước khi chạy `python tools/agent_pipeline.py handoff <package-id>`.
7. **Nghiệm thu (`accept`):** Coordinator/Reviewer kiểm tra bằng chứng, handoff và diff, sau đó thực hiện `python tools/agent_pipeline.py accept <package-id>` để chuyển trạng thái sang `done`.

## 2. Vòng đời trạng thái Work Package

- `draft`: Package đang được soạn thảo trong backlog.
- `ready`: Package đã đủ thông tin, dependency đã hoàn tất và sẵn sàng được giao.
- `in_progress`: Agent đã nhận việc qua lệnh `start`.
- `blocked`: Công việc gặp trở ngại cần coordinator xử lý.
- `review`: Agent đã hoàn tất kiểm chứng và nộp handoff.
- `done`: Reviewer/Coordinator đã nghiệm thu thành công.

## 3. Quy ước Commit

- Sử dụng Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- Mỗi task hoặc work package có commit riêng biệt, rõ ràng và kèm test đã vượt qua.
