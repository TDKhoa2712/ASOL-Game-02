+++
id = "M0-REPLAN"
title = "Re-sequence M0 for editor-first playable prototype"
kind = "governance"
phase = "M0"
status = "ready"
depends_on = [
  "M0-PREFLIGHT"
]
requirements = [
  "D-06",
  "TECH-13",
  "TECH-19"
]
qa = [
  "QA-26",
  "QA-30"
]
read_first = [
  "GDD/README.md",
  "GDD/05-kien-truc-va-du-lieu.md",
  "GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md",
  "docs/governance/README.md"
]
allowed_paths = [
  "work/packages/M0-A01.md",
  "work/packages/M0-A02.md",
  "work/packages/M0-A03.md",
  "work/packages/M0-GATE.md",
  "work/packages/M0-REPLAN.md",
  "docs/governance/**",
  "work/evidence/M0-REPLAN/**",
  "work/handoffs/M0-REPLAN.md"
]
deliverables = [
  "work/packages/M0-A01.md",
  "work/packages/M0-A02.md",
  "work/packages/M0-A03.md",
  "work/packages/M0-GATE.md",
  "work/evidence/M0-REPLAN/replan-summary.md"
]
out_of_scope = [
  "gameplay implementation",
  "production assets",
  "claiming unmeasured device performance",
  "changing canonical gameplay rules"
]
[[checks]]
id = "repository_validate"
command = ["python", "tools/agent_pipeline.py", "validate"]
[[checks]]
id = "repository_doctor"
command = ["python", "tools/agent_pipeline.py", "doctor"]
+++

# M0-REPLAN: Re-sequence M0 for editor-first playable prototype

## 1. Mục tiêu

Tách điều kiện tạo prototype chạy trong Godot Editor khỏi cổng xác nhận mobile trên thiết bị thật, nhưng không xóa hoặc hạ ngưỡng TECH-13/19 và QA mobile trước M0-GATE.

## 2. Tiêu chí nghiệm thu

- [ ] `M0-A01` chỉ chịu trách nhiệm bootstrap Godot, editor/headless runtime và host export baseline.
- [ ] `M0-A02` được đưa sang `ready` để tạo prototype tương tác chạy trong Godot Editor sau khi `M0-A01` được accept.
- [ ] `M0-A03` nhận toàn bộ device/performance validation còn thiếu và được đưa sang `ready`.
- [ ] `M0-GATE` vẫn chặn tuyên bố hoàn tất M0 nếu thiếu Android/iPhone thật, macOS/Xcode hoặc số đo TECH-13/19/21.
- [ ] Requirement/QA không bị mất khỏi chuỗi truy vết; chỉ được phân lại package phù hợp.
- [ ] Pipeline `validate` và `doctor` đều pass.
