+++
id = "SETUP-001"
title = "Repository restructure and agent pipeline"
kind = "governance"
phase = "SETUP"
status = "ready"
depends_on = []
requirements = []
qa = []
read_first = [
  "GDD/README.md",
  "docs/governance/README.md"
]
allowed_paths = [
  ".gitignore",
  "README.md",
  "AGENTS.md",
  "CONTRIBUTING.md",
  "GDD/**",
  "docs/**",
  "work/**",
  "tools/**",
  "meowdoku-clone.xml",
  "Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx"
]
deliverables = [
  "tools/agent_pipeline.py",
  "docs/governance/document-register.toml"
]
out_of_scope = [
  "game/**",
  "game implementation",
  "commercial assets"
]
[[checks]]
id = "gdd_validate"
command = ["python", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]

[[checks]]
id = "gdd_tests"
command = ["python", "-m", "unittest", "discover", "GDD/tools", "-p", "test_*.py"]

[[checks]]
id = "pipeline_tests"
command = ["python", "-m", "unittest", "discover", "tools/tests", "-p", "test_*.py"]

[[checks]]
id = "doctor"
command = ["python", "tools/agent_pipeline.py", "doctor"]
+++

# SETUP-001: Tái cấu trúc repository và agent pipeline

## 1. Mục tiêu
Thiết lập cấu trúc repository chuẩn mực, quản trị tài liệu rõ ràng và pipeline work package zero-dependency.

## 2. Tiêu chí nghiệm thu (Acceptance Criteria)
- [ ] Pipeline zero-dependency tại `tools/agent_pipeline.py` vượt qua toàn bộ test.
- [ ] GDD fixtures và unit test tiếp tục chạy đạt 100%.
- [ ] Entrypoints và governance docs được thiết lập đầy đủ.
- [ ] Không còn cache, repomix snapshot hoặc báo cáo trùng lặp trong repository.
- [ ] Gói việc seed `M0-A01` sẵn sàng ở trạng thái `ready`.
