+++
id = "M0-PREFLIGHT"
title = "M0 prototype readiness governance"
kind = "governance"
phase = "M0"
status = "ready"
depends_on = [
  "SETUP-001"
]
requirements = [
  "D-06",
  "TECH-13",
  "TECH-14",
  "TECH-19",
  "TECH-21"
]
qa = [
  "QA-12",
  "QA-26",
  "QA-27",
  "QA-30",
  "QA-43",
  "QA-44",
  "QA-45",
  "QA-50",
  "QA-54",
  "QA-55"
]
read_first = [
  "GDD/README.md",
  "GDD/05-kien-truc-va-du-lieu.md",
  "GDD/08-ke-hoach-trien-khai-cho-agent.md",
  "docs/governance/00-design-status.md",
  "docs/governance/06-design-freeze-checklist.md"
]
allowed_paths = [
  "docs/governance/**",
  "tools/agent_pipeline.py",
  "tools/tests/test_agent_pipeline.py",
  "work/packages/M0-A01.md",
  "work/packages/M0-A02.md",
  "work/packages/M0-A03.md",
  "work/packages/M0-GATE.md",
  "work/evidence/M0-PREFLIGHT/**",
  "work/handoffs/M0-PREFLIGHT.md"
]
deliverables = [
  "work/packages/M0-A01.md",
  "work/packages/M0-A02.md",
  "work/packages/M0-A03.md",
  "work/packages/M0-GATE.md"
]
out_of_scope = [
  "game runtime implementation",
  "production content",
  "gameplay rule changes",
  "asset production"
]
[[checks]]
id = "pipeline_tests"
command = ["python", "-m", "unittest", "discover", "tools/tests", "-p", "test_*.py"]
[[checks]]
id = "gdd_tests"
command = ["python", "-m", "unittest", "discover", "GDD/tools", "-p", "test_*.py"]
[[checks]]
id = "repository_doctor"
command = ["python", "tools/agent_pipeline.py", "doctor"]
+++

# M0-PREFLIGHT: M0 prototype readiness governance

## 1. Mục tiêu

Làm cho các hợp đồng M0 có thể thực thi và kiểm chứng trước khi bắt đầu prototype Godot, không thay đổi luật gameplay hoặc mở rộng phạm vi MVP.

## 2. Tiêu chí nghiệm thu (Acceptance Criteria)

- [ ] Pipeline phát hiện deliverable nằm ngoài `allowed_paths`.
- [ ] Mỗi package M0 có check liên quan trực tiếp đến đầu ra Godot/runtime hoặc bằng chứng nghiên cứu của package.
- [ ] `M0-A03` có thể tạo báo cáo spike trong phạm vi được phép.
- [ ] `M0-GATE` không yêu cầu QA chưa được package tiền đề bao phủ.
- [ ] Ngưỡng hiệu năng M0 thống nhất với `TECH-19` và ghi rõ artifact bằng chứng.
- [ ] DQ-002 được đóng bằng quyết định governance về frozen/tuneable và change-control.

