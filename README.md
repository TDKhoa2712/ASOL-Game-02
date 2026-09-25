# ASOL-Game-02 — Vườn Mèo

Dự án phát triển game giải đố logic "Vườn Mèo".

> **Trạng thái hiện tại:** Chủ dự án đã duyệt tích hợp cải tổ vào `dev` và mở R1 ngày 2026-09-25. Bản đầu giữ 24 level, Endless để sau. Client bốn level chưa được chứng nhận ổn định/liền mạch. Xem [STATUS](docs/STATUS.md).

---

## Cấu trúc Repository

- [`GDD/`](GDD/README.md): Nguồn thiết kế chuẩn (Canonical Game Design Document v0.5.0), dữ liệu mẫu (fixtures) và công cụ kiểm chứng logic level.
- [`game/`](game/project.godot): Client Godot, scene, script, dữ liệu và test.
- [`docs/ROADMAP.md`](docs/ROADMAP.md): Kế hoạch theo kết quả sản phẩm; [`STATUS`](docs/STATUS.md) là tiến độ hiện tại; [`DECISIONS`](docs/DECISIONS.md) ghi quyết định mới.
- [`docs/governance/`](docs/governance/README.md) và [`work/`](work/README.md): Hồ sơ cũ được giữ để truy vết, không điều hành công việc mới.
- [`tools/`](tools/agent_pipeline.py): Công cụ cũ vẫn được bảo tồn; pipeline package không còn là cổng bắt buộc.

---

## Lệnh Vận Hành Nhanh

Mở project hiện tại (cần Godot phù hợp với project):
```text
godot --editor --path game
```

Chạy game hiện tại; đây chưa phải bản đã nghiệm thu:
```text
godot --path game
```

Kiểm tra runtime hiện có:
```text
godot --headless --path game --script res://tests/run_mvp_runtime_tests.gd
```

Chạy kiểm thử GDD và level fixture:
```text
python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json
python -B GDD/tools/validate_levels.py game/data/campaign_m1.json
python -B -m unittest discover GDD/tools -p "test_*.py"
```

Các lệnh trên là những kiểm tra riêng lẻ, không đại diện toàn bộ QA hoặc chứng minh game chơi liền mạch. Kế hoạch kiểm tra tích hợp sẽ được chốt trong chặng R1 sau khi tiếp tục phát triển.

---

## Quy định Đóng góp và Phát triển

- Dành cho nhà phát triển và coding agent: đọc [`AGENTS.md`](AGENTS.md) và [`CONTRIBUTING.md`](CONTRIBUTING.md).
- Toàn bộ tài sản hình ảnh, âm thanh, cấp độ và mã nguồn phải là tác phẩm gốc, không sao chép từ bất kỳ tựa game thương mại nào.
