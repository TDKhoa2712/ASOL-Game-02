+++
id = "M0-DEFER"
title = "Defer device validation for M1 build"
kind = "governance"
phase = "M0"
status = "ready"
depends_on = ["M0-A02", "M0-REPLAN"]
requirements = []
qa = []
read_first = [
  "GDD/README.md",
  "GDD/08-ke-hoach-trien-khai-cho-agent.md",
  "docs/governance/README.md",
  "work/packages/M0-GATE.md",
  "work/packages/M1-PLAN.md"
]
allowed_paths = [
  "GDD/08-ke-hoach-trien-khai-cho-agent.md",
  "docs/governance/02-decision-log.md",
  "work/packages/M0-DEFER.md",
  "work/packages/M1-*.md",
  "work/evidence/M0-DEFER/**",
  "work/handoffs/M0-DEFER.md"
]
deliverables = [
  "work/evidence/M0-DEFER/dependency-review.md"
]
out_of_scope = [
  "M0-A03 or M0-GATE acceptance",
  "M1 code or content implementation",
  "removing mobile, iOS, performance or release QA requirements",
  "changing gameplay rules, schema, score or MVP scope"
]
[[checks]]
id = "repository_validate"
command = ["python", "tools/agent_pipeline.py", "validate"]
[[checks]]
id = "repository_doctor"
command = ["python", "tools/agent_pipeline.py", "doctor"]
[[checks]]
id = "pipeline_tests"
command = ["python", "-m", "unittest", "discover", "tools/tests", "-p", "test_*.py"]
[[checks]]
id = "gdd_tests"
command = ["python", "-m", "unittest", "discover", "GDD/tools", "-p", "test_*.py"]
+++

# M0-DEFER: Defer device validation for M1 build

## 1. Mục tiêu

Cho phép triển khai có điều kiện các package M1 trong lúc M0-A03 chờ thiết bị và iOS. Giữ nguyên cổng nghiệm thu M0 và M1; không coi phép đo probe hoặc headless là bằng chứng thay thế QA trên thiết bị.

## 2. Tiêu chí nghiệm thu

- [ ] Có quyết định governance và cập nhật GDD 08 phân biệt quyền bắt đầu triển khai M1 với việc nghiệm thu M0/M1.
- [ ] Mọi package triển khai/content M1 phụ thuộc M0-DEFER; các dependency nội bộ M1 giữ nguyên.
- [ ] M0-GATE vẫn phụ thuộc M0-A03 và M1-GATE vẫn phụ thuộc M0-GATE.
- [ ] Báo cáo dependency liệt kê đầy đủ package bị chặn, package được mở và điều kiện thiết bị còn thiếu.
- [ ] `validate`, `doctor` và toàn bộ check của package qua; không sửa code, content hay kết quả nghiệm thu M0-A03.

## 3. Rủi ro và trọng tâm review

Triển khai M1 khi chưa có số đo iOS/atlas cuối có thể cần sửa UI, asset hoặc budget sau này. Reviewer cần xác nhận rủi ro này được giữ ở gate nghiệm thu và không bị diễn giải là M0 đã đạt.
