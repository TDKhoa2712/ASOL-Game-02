# Báo cáo bàn giao: SETUP-001

## Package
SETUP-001 (Tái cấu trúc repository và agent pipeline) — Thực hiện bởi: coding-agent

## Requirements
- Thiết lập phân tầng thẩm quyền 6 lớp: GDD canonical > docs/governance > work/packages > work/evidence & work/handoffs > docs/reviews > docs/archive.
- Xây dựng CLI pipeline zero-dependency tại `tools/agent_pipeline.py` hỗ trợ đầy đủ: `validate`, `doctor`, `list`, `trace`, `inspect`, `start`, `verify`, `handoff`, `accept`.
- Chuẩn hóa đường dẫn POSIX-relative, chống thoát thư mục repository, khóa phạm vi thay đổi theo `allowed_paths`.
- Kiểm tra link Markdown nội bộ, bảo vệ protected paths, ngăn chặn artifact rác (cache, snapshot Repomix).
- Khởi tạo hợp đồng seed packages M0 (`M0-A01` ở trạng thái `ready`, `M0-A02`, `M0-A03`, `M0-GATE` ở trạng thái `draft`).
- Di chuyển an toàn toàn bộ hồ sơ lịch sử, governance và review vào các thư mục phân định thẩm quyền rõ ràng.

## QA
- Bộ kiểm chứng GDD level validator: 5/5 fixtures hợp lệ, 0 duplicate geometry warnings.
- Toàn bộ 23 unit test GDD hiện có: PASS 100%.
- Toàn bộ 20 unit test pipeline mới tại `tools/tests/test_agent_pipeline.py`: PASS 100%.
- Lệnh `doctor` toàn diện: PASS, 0 issue.

## Changed files
- Entrypoints & Governance: `.gitignore`, `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/governance/README.md`, `docs/governance/document-register.toml`, `docs/governance/00-design-status.md` đến `06-design-freeze-checklist.md`.
- Reviews & Archive: `docs/reviews/01-mvp-game-design-review.md`, `docs/archive/reviews/*`, `docs/archive/agent-history/*`.
- Pipeline & Reports: `tools/__init__.py`, `tools/agent_pipeline.py`, `tools/tests/test_agent_pipeline.py`, `tools/reports/generate_game_design_report.py`, `docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx`.
- Work Contracts: `work/README.md`, `work/templates/*`, `work/packages/SETUP-001.md`, `M0-A01.md`, `M0-A02.md`, `M0-A03.md`, `M0-GATE.md`, `work/state/SETUP-001.toml`.
- Deleted root duplicate artifacts: `meowdoku-clone.xml`, root `Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx`.

## Validation
- `python GDD/tools/validate_levels.py GDD/data/levels.sample.json` -> 5 levels OK.
- `python -m unittest discover GDD/tools -p "test_*.py"` -> 23 tests OK.
- `python -m unittest discover tools/tests -p "test_*.py"` -> 20 tests OK.
- `python tools/agent_pipeline.py doctor` -> OK: repository contract is valid.

## Evidence
- `work/evidence/SETUP-001/verification.txt`

## Remaining risks
- Chưa khởi tạo game client (`game/` chưa tồn tại); việc bootstrap Godot 4.x và đo đạc trên thiết bị thật sẽ được thực hiện tại package `M0-A01`.
- Cần coordinator giao tiếp package `M0-A01` cho agent kế tiếp.

## Reviewer
Nghiệm thu hoàn tất bởi Coordinator / Reviewer.
