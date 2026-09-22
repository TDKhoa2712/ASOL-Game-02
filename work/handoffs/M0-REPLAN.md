# Báo cáo bàn giao: M0-REPLAN

## Package

M0-REPLAN — Re-sequence M0 for editor-first playable prototype

## Requirements

- D-06
- TECH-13
- TECH-19

## QA

- QA-26
- QA-30

## Changed files

- `work/packages/M0-REPLAN.md`
- `work/packages/M0-A01.md`
- `work/packages/M0-A02.md`
- `work/packages/M0-A03.md`
- `work/packages/M0-GATE.md`
- `tools/tests/test_agent_pipeline.py`
- `work/evidence/M0-REPLAN/replan-spec.md`
- `work/evidence/M0-REPLAN/replan-plan.md`
- `work/evidence/M0-REPLAN/replan-summary.md`
- `work/evidence/M0-REPLAN/verification.txt`
- `work/handoffs/M0-REPLAN.md`

## Validation

- Contract assertion RED trước khi sửa và GREEN sau khi phân lại package.
- 5/5 level fixtures validate.
- 23/23 GDD unit tests pass.
- 22/22 pipeline unit tests pass.
- `python tools/agent_pipeline.py validate`: pass.
- `python tools/agent_pipeline.py doctor`: pass.
- `python tools/agent_pipeline.py verify M0-REPLAN`: pass; cả hai package checks exit 0.
- `git diff --check`: pass tại điểm kiểm tra contract.
- Whole-branch review: pass cho requirement loss, dependency ordering, false completion, prototype blocking và gate weakening.

## Evidence

- `work/evidence/M0-REPLAN/replan-spec.md`: thiết kế editor-first đã được phê duyệt.
- `work/evidence/M0-REPLAN/replan-plan.md`: kế hoạch và checklist thực thi.
- `work/evidence/M0-REPLAN/replan-summary.md`: bảng phân công trước/sau và chuỗi truy vết.
- `work/evidence/M0-REPLAN/verification.txt`: output xác minh do pipeline tạo.

## Remaining risks

- State M0-A01 vẫn phản ánh lần chạy bị blocked theo contract cũ; sau khi M0-REPLAN được accept, M0-A01 phải được resume qua pipeline, verify và handoff theo contract mới.
- M0-A02 mới ở catalog `ready`; prototype gameplay chưa được triển khai trong package governance này.
- Android/iPhone thật, macOS/Xcode, signing và các số đo TECH-13/19/21 vẫn chưa có; M0-A03 và M0-GATE tiếp tục chặn mọi tuyên bố hoàn tất mobile.
- Regression assertion seed được đổi đúng một kỳ vọng từ M0-A02 `draft` sang `ready`; pipeline implementation không thay đổi.

## Reviewer

Reviewer/coordinator cần xác nhận requirement/QA không bị mất, dependency A01 → A02 → A03 không tạo vòng, A02 có thể nghiệm thu bằng Godot Editor, và M0-GATE vẫn từ chối khi thiếu evidence mobile thật. Sau khi accept M0-REPLAN, con người giao chính xác M0-A01 để tiếp tục.
