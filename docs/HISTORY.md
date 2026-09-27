# Tra cứu lịch sử trước khi dọn pipeline

Tag local `pre-reset-pipeline-2026-09-27` trỏ commit `8f2876d`. Nó giữ các file đã commit trước cải tổ, không giữ thay đổi chưa commit/untracked và chưa phải backup ngoài máy.

```text
rtk git show pre-reset-pipeline-2026-09-27:work/README.md
rtk git show pre-reset-pipeline-2026-09-27:docs/governance/02-decision-log.md
rtk git show pre-reset-pipeline-2026-09-27:docs/reviews/05-design-and-structure-review.md
```

Thay đường dẫn sau dấu `:` để đọc file khác. Hồ sơ gồm `work/`, `docs/governance/`, `docs/archive/`, `docs/BRANCH-CONSOLIDATION.md`, review 01/03/04/05, `tools/agent_pipeline.py` và test cũ. Chỉ khôi phục file cụ thể khi cần, tránh ghi đè thay đổi hiện có. Các nhận định trong đó thuộc revision/ngày cũ; tiến độ hiện tại chỉ ở [STATUS](STATUS.md).

Hai file cấu hình lạc tên và `project.xml`, `refactor/AGENTS.md` vốn untracked được giữ nguyên. Bản nháp AGENTS trong refactor không phải nguồn vận hành gốc. Phần sửa sẵn `game/scripts/board_view.gd` không thuộc commit cải tổ.
