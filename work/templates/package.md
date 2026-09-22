+++
id = "M0-A01"
title = "Package Title"
kind = "implementation"
phase = "M0"
status = "draft"
depends_on = []
requirements = []
qa = []
read_first = [
  "GDD/README.md"
]
allowed_paths = [
  "game/**",
  "work/evidence/M0-A01/**",
  "work/handoffs/M0-A01.md"
]
deliverables = [
  "game/project.godot"
]
out_of_scope = []
[[checks]]
id = "fixture"
command = ["python", "GDD/tools/validate_levels.py", "GDD/data/levels.sample.json"]
+++

# Package Title

## 1. Mục tiêu và bối cảnh

## 2. Tiêu chí nghiệm thu (Acceptance Criteria)

- [ ] Tiêu chí 1
- [ ] Tiêu chí 2

## 3. Lệnh kiểm chứng

```text
python GDD/tools/validate_levels.py GDD/data/levels.sample.json
```

## 4. Rủi ro và trọng tâm review
