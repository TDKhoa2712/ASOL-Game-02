# Hướng dẫn bắt buộc cho coding agent (AGENTS.md)

Tất cả coding agent khi làm việc trong repository này PHẢI tuân thủ các quy định sau:

## 1. Thứ tự thẩm quyền tài liệu (Authority)

1. **Thiết kế canonical:** [`GDD/`](GDD/README.md) (Luật gameplay chuẩn tại [`GDD/02-luat-choi-va-trang-thai.md`](GDD/02-luat-choi-va-trang-thai.md)).
2. **Quản trị và quy chuẩn:** [`docs/governance/`](docs/governance/README.md) và [`docs/governance/document-register.toml`](docs/governance/document-register.toml).
3. **Hợp đồng công việc:** [`work/packages/`](work/packages/).
4. **Bằng chứng thực thi:** [`work/evidence/`](work/evidence/) và [`work/handoffs/`](work/handoffs/).
5. **Review hiện hành:** [`docs/reviews/`](docs/reviews/).
6. **Lịch sử / Archive:** [`docs/archive/`](docs/archive/) (tuyệt đối không dùng làm requirement triển khai).

## 2. Chỉ thực hiện Work Package được giao (Assigned Package Only)

- Con người chỉ định chính xác một mã work package ID (ví dụ: `M0-A01`).
- Agent không được tự chọn hoặc nhận các work package khác ngoài ID được giao.

## 3. Lệnh bắt buộc trong quy trình (Required Commands)

1. **Xem chi tiết package trước khi sửa file:**
   ```text
   python tools/agent_pipeline.py inspect <package-id>
   ```
2. **Chạy kiểm chứng và ghi nhận evidence:**
   ```text
   python tools/agent_pipeline.py verify <package-id>
   ```
3. **Nộp bàn giao sau khi điền báo cáo:**
   ```text
   python tools/agent_pipeline.py handoff <package-id>
   ```

## 4. Bảo vệ phạm vi và đường dẫn cấm (Protected Changes)

- Chỉ chỉnh sửa các file thuộc phạm vi `allowed_paths` của work package được giao.
- Gói việc loại `implementation` **không được phép** sửa đổi `GDD/`, `docs/governance/`, `AGENTS.md` hoặc `tools/agent_pipeline.py`. Mọi thay đổi luật chơi, schema hoặc quy chuẩn quản trị bắt buộc phải thông qua package loại `design-change` hoặc `governance`.

## 5. Tác phẩm và nội dung gốc (Original Content)

- Toàn bộ asset (hình ảnh, âm thanh, UI), level design, dữ liệu và mã nguồn phải là tác phẩm gốc.
- Tuyệt đối không sao chép tên thương mại, giao diện, âm thanh, hình ảnh hay cấu trúc level từ Meowdoku hoặc bất kỳ game thương mại nào khác.

## 6. Kiểm chứng và bàn giao (Verification & Handoff)

- Phải kiểm tra toàn bộ unit test và level validator trước khi bàn giao.
- File bàn giao tại `work/handoffs/<package-id>.md` phải được điền đầy đủ tất cả các mục bắt buộc, không để lại placeholder `<...>` hay `TODO`.
