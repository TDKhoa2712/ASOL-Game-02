+++
id = "M1-GATE"
title = "M1 vertical-slice evidence and acceptance gate"
kind = "governance"
phase = "M1"
status = "ready"
depends_on = ["M0-GATE", "M1-A01", "M1-A02", "M1-A03", "M1-A04", "M1-A05", "M1-C01", "M1-A06"]
requirements = ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-07"]
qa = ["QA-08", "QA-09", "QA-10", "QA-11", "QA-12", "QA-14", "QA-15", "QA-16", "QA-17", "QA-18", "QA-19", "QA-20", "QA-21", "QA-22", "QA-23", "QA-24", "QA-25", "QA-27", "QA-28", "QA-29", "QA-31", "QA-33", "QA-36", "QA-37", "QA-40", "QA-41", "QA-43", "QA-44", "QA-45", "QA-54", "QA-55", "QA-56"]
read_first = ["GDD/README.md", "GDD/02-luat-choi-va-trang-thai.md", "GDD/08-ke-hoach-trien-khai-cho-agent.md", "GDD/07-kiem-thu-va-tieu-chi-nghiem-thu.md", "docs/governance/06-design-freeze-checklist.md"]
allowed_paths = ["work/evidence/M1-GATE/**", "work/handoffs/M1-GATE.md"]
deliverables = ["work/evidence/M1-GATE/vertical-slice-review.md"]
out_of_scope = ["M0-A03 or M0-GATE acceptance", "M2 24-level release and final art/audio", "post-MVP S4/S5, N>6 release, wallet, ads, collection, generator"]
[[checks]]
id = "repository_validate"
command = ["python", "tools/agent_pipeline.py", "validate"]
[[checks]]
id = "level_validator"
command = ["python", "GDD/tools/validate_levels.py", "game/data/campaign_m1.json"]
+++

# M1-GATE: M1 vertical-slice evidence and acceptance gate

## 1. Mục tiêu và bối cảnh

Tổng hợp bằng chứng vertical slice bốn level và quyết định chuyển sang M2.

## 2. Tiêu chí nghiệm thu

- [ ] M0-GATE và mọi package M1 tiền đề đã được accept; không lấy headless thay cho đo trên thiết bị.
- [ ] Bốn level gốc, tutorial Level 1, save, Hint một lần, Undo/Restart và các màn Result qua QA tương ứng.
- [ ] Ghi rõ thử người mới về cử chỉ, 3 tim/X đỏ/Undo, scorecard 100/25, feedback, accessibility và vấn đề còn mở; nếu cần đổi luật/schema mở decision change.

## 3. Lệnh kiểm chứng

- `python tools/agent_pipeline.py validate` (repository_validate).
- `python GDD/tools/validate_levels.py game/data/campaign_m1.json` (level_validator).

## 4. Rủi ro và trọng tâm review

Không coi 4 level là campaign release 24; art/audio cuối và full QA release ở M2.

