# Báo cáo bàn giao: M0-PREFLIGHT

## Package

M0-PREFLIGHT — M0 prototype readiness governance. Thực hiện bởi Codex trên nhánh `work/m0-preflight-m0-prototype-readiness-governance`.

## Requirements

- D-06: giữ Godot 4.x/GDScript và runtime sprite 2D làm baseline.
- TECH-13/14: biến toolchain, input timing và runtime response thành đầu ra/check có thể kiểm chứng.
- TECH-19/21: thống nhất ngưỡng FPS ≥55, stutter ≤100 ms và yêu cầu công bố ngân sách tải/RAM/VRAM.
- Không thay đổi luật gameplay, schema level hoặc phạm vi MVP.

## QA

- QA-12, QA-43, QA-44, QA-45, QA-54, QA-55 được giao cho runtime interaction package M0-A02.
- QA-26 được giữ tại toolchain/offline baseline M0-A01.
- QA-27, QA-30 và QA-50 được giao cho mobile rendering spike M0-A03.
- QA-56 được loại khỏi M0-GATE vì thuộc Hint/session package E/M1, không có implementation tiền đề trong M0.

## Changed files

- Pipeline: `tools/agent_pipeline.py`, `tools/tests/test_agent_pipeline.py`.
- M0 contracts: `work/packages/M0-A01.md`, `M0-A02.md`, `M0-A03.md`, `M0-GATE.md`.
- Governance: `docs/governance/00-design-status.md`, `01-open-questions.md`, `02-decision-log.md`, `03-risk-register.md`, `05-research-backlog.md`, `06-design-freeze-checklist.md`.
- Package bootstrap/state/evidence: `work/packages/M0-PREFLIGHT.md`, `work/state/M0-PREFLIGHT.toml`, `work/evidence/M0-PREFLIGHT/verification.txt`.

## Validation

- `python -B GDD/tools/validate_levels.py GDD/data/levels.sample.json`: 5/5 fixture hợp lệ, 0 duplicate geometry warning; output lưu tại `level-validator.txt`.
- `python -B -m unittest discover GDD/tools -p test_*.py`: 23 test pass.
- Pipeline `verify` ban đầu ghi 21 test; sau review, `python -B -m unittest discover tools/tests -p test_*.py` ghi 22 test pass, gồm regression test UTF-8.
- `python tools/agent_pipeline.py validate`: pass.
- `python tools/agent_pipeline.py doctor`: pass.
- `python tools/agent_pipeline.py verify M0-PREFLIGHT` với bytecode cache tắt: pass và ghi evidence.

## Evidence

- `work/evidence/M0-PREFLIGHT/verification.txt`.
- `work/evidence/M0-PREFLIGHT/level-validator.txt`.
- `work/evidence/M0-PREFLIGHT/review-verification.txt`.
- Test hồi quy mới chứng minh catalog từ chối deliverable nằm ngoài `allowed_paths` bằng mã `DELIVERABLE_OUT_OF_SCOPE`.
- Các contract M0 giờ khai báo Godot headless/runtime smoke checks và artifact evidence cụ thể.

## Remaining risks

- Godot, Blender và Gradle chưa được tìm thấy trên PATH của máy hiện tại; Android SDK/ADB và JDK 21 đã có. M0-A01 cần cài/khóa Godot minor version và export templates trước khi verify.
- Chưa có bằng chứng máy macOS/Xcode, iPhone mục tiêu hoặc phép đo thiết bị thật; M0-A01 phải chuyển blocked nếu không có môi trường iOS thay vì handoff như đã đạt.
- Design Freeze vẫn chưa sẵn sàng: còn bằng chứng M0, ranh giới package B/Core, trace matrix QA và bằng chứng content/runtime Hint S3.
- M0-A01 nay phụ thuộc M0-PREFLIGHT; pipeline sẽ không cho start trước khi Coordinator accept package này.
- Nhánh `main` vẫn chưa chứa commit hoàn tất SETUP-001; Coordinator cần tích hợp baseline hoặc chủ động duy trì chuỗi nhánh trước khi bắt đầu M0-A01.

## Reviewer

Chờ Coordinator/Reviewer kiểm tra evidence, diff và thực hiện `accept M0-PREFLIGHT`.
