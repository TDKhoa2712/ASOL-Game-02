# ASOL-Game-02 — Vườn Mèo

Dự án phát triển game giải đố logic "Vườn Mèo".

> **Trạng thái hiện tại:** Dự án đang ở giai đoạn tiền sản xuất (Pre-production). Repository chứa toàn bộ tài liệu thiết kế chuẩn (GDD), quy chuẩn quản trị (Governance), pipeline quản lý công việc và bộ test kiểm chứng; **chưa có client game chạy được**. Thư mục mã nguồn `game/` sẽ được khởi tạo trong gói việc M0 baseline.

---

## Cấu trúc Repository

- [`GDD/`](GDD/README.md): Nguồn thiết kế chuẩn (Canonical Game Design Document v0.5.0), dữ liệu mẫu (fixtures) và công cụ kiểm chứng logic level.
- [`docs/governance/`](docs/governance/README.md): Hệ thống quản trị, thẩm quyền tài liệu ([`document-register.toml`](docs/governance/document-register.toml)) và nhật ký quyết định kỹ thuật.
- [`work/`](work/README.md): Hợp đồng công việc ([`work/packages/`](work/packages/)), trạng thái vòng đời thực thi, báo cáo bàn giao và bằng chứng kiểm chứng.
- [`tools/`](tools/agent_pipeline.py): Bộ công cụ CLI zero-dependency (`tools/agent_pipeline.py`), sinh báo cáo và kiểm thử tự động.

---

## Lệnh Vận Hành Nhanh

Kiểm tra tính toàn vẹn của repository:
```text
python tools/agent_pipeline.py doctor
```

Xem danh sách work package:
```text
python tools/agent_pipeline.py list
```

Xem chi tiết gói việc M0 baseline:
```text
python tools/agent_pipeline.py inspect M0-A01
```

Chạy kiểm thử GDD và level fixture:
```text
python GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -m unittest discover GDD/tools -p "test_*.py"
```

Chạy kiểm thử toàn bộ pipeline:
```text
python -m unittest discover tools/tests -p "test_*.py"
```

---

## Quy định Đóng góp và Phát triển

- Dành cho nhà phát triển và coding agent: đọc [`AGENTS.md`](AGENTS.md) và [`CONTRIBUTING.md`](CONTRIBUTING.md).
- Toàn bộ tài sản hình ảnh, âm thanh, cấp độ và mã nguồn phải là tác phẩm gốc, không sao chép từ bất kỳ tựa game thương mại nào.
