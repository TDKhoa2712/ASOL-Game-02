+++
id = "M1-PLAN"
title = "Plan and register M1 MVP work packages"
kind = "governance"
phase = "M1"
status = "ready"
depends_on = ["M0-REPLAN"]
requirements = []
qa = []
read_first = [
  "GDD/README.md",
  "GDD/08-ke-hoach-trien-khai-cho-agent.md",
  "docs/governance/README.md",
  "work/packages/M0-GATE.md"
]
allowed_paths = [
  "work/packages/M1-*.md",
  "work/evidence/M1-PLAN/**",
  "work/handoffs/M1-PLAN.md"
]
deliverables = [
  "work/evidence/M1-PLAN/package-map.md"
]
out_of_scope = [
  "M1 implementation",
  "M0-A03 completion or acceptance",
  "M0-GATE completion or acceptance",
  "canonical gameplay or governance rule changes"
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
[[checks]]
id = "game_tests"
command = ["python", "-m", "unittest", "discover", "game/tests", "-p", "test_*.py"]
[[checks]]
id = "level_validator"
command = ["python", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]
+++

# M1-PLAN: Plan and register M1 MVP work packages

## 1. Mục tiêu và bối cảnh

Đối chiếu GDD và governance để chia M1 thành các hợp đồng nhỏ, có phạm vi, đầu ra, dependency và kiểm chứng rõ ràng trong khi M0-A03 chờ kiểm chứng thiết bị. DEC-018/M0-DEFER cho phép bắt đầu triển khai có điều kiện; việc lập kế hoạch này không mở M0-GATE.

## 2. Tiêu chí nghiệm thu

- [ ] Mỗi package M1 có ID, phạm vi, deliverable, dependency, acceptance criteria và checks phù hợp.
- [ ] Mọi package triển khai/content M1 phụ thuộc trực tiếp vào M0-DEFER; M1-GATE vẫn phụ thuộc M0-GATE và các package M1 tiền đề.
- [ ] Truy vết các yêu cầu và QA M1 theo GDD, không nhận yêu cầu thuộc M0 hoặc giai đoạn sau M1.
- [ ] `validate`, `doctor`, unit tests và level validator đều pass.
- [ ] Báo cáo handoff đầy đủ, không còn placeholder.

## 3. Lệnh kiểm chứng

Chạy `python tools/agent_pipeline.py verify M1-PLAN` sau khi đăng ký các package.

## 4. Rủi ro và trọng tâm review

Không chuyển M0-A03 hoặc M0-GATE sang `done`; không tạo code triển khai M1 trong package M1-PLAN. Kiểm tra dependency để quyền bắt đầu code không bị diễn giải thành nghiệm thu M0/M1.
