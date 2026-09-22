+++
id = "M0-GATE"
title = "M0 evidence review and milestone gate"
kind = "governance"
phase = "M0"
status = "draft"
depends_on = [
  "M0-A02",
  "M0-A03"
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
  "docs/governance/README.md"
]
allowed_paths = [
  "docs/governance/**",
  "work/evidence/M0-GATE/**",
  "work/handoffs/M0-GATE.md"
]
deliverables = [
  "docs/governance/06-design-freeze-checklist.md"
]
out_of_scope = [
  "M1 development"
]
[[checks]]
id = "gdd_validate"
command = ["python", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]
[[checks]]
id = "repository_validate"
command = ["python", "tools/agent_pipeline.py", "validate"]
[[checks]]
id = "repository_doctor"
command = ["python", "tools/agent_pipeline.py", "doctor"]
+++

# M0-GATE: M0 evidence review and milestone gate

## 1. Mục tiêu
Tổng hợp, đánh giá bằng chứng thực thi từ các gói việc M0 và quyết định chuyển giao sang giai đoạn M1.

## 2. Tiêu chí nghiệm thu (Acceptance Criteria)
- [ ] Toàn bộ gói việc tiền đề (M0-A01, M0-A02, M0-A03) đã nghiệm thu `done`.
- [ ] Báo cáo đo đạc hiệu năng và phản hồi điều khiển đạt yêu cầu.
- [ ] Không nhận bằng chứng QA-56 tại M0; Hint/session được nghiệm thu ở package E/M1 theo GDD 08.
- [ ] Biên bản Design Freeze Checklist được phê duyệt.
