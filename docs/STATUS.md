# Trạng thái dự án

> Cập nhật: 2026-10-02

## Mục tiêu hiện tại: Rebuild cho playtest 30 level

**Plan:** [Master plan](superpowers/plans/2026-10-02-rebuild-master.md)
**Quyết định:** RST-012 (rebuild), RST-011 (30-level playtest)

### Tiến độ thiết kế

| Module | Plan | Status |
|--------|------|--------|
| M01 Core | [01-core.md](superpowers/plans/rebuild/01-core.md) | Hoàn tất (PR #1 merged) |
| M02 State | [02-state.md](superpowers/plans/rebuild/02-state.md) | Hoàn tất, chờ review PR |
| M03 Content | [03-content.md](superpowers/plans/rebuild/03-content.md) | Thiết kế xong |
| M04 Input | [04-input.md](superpowers/plans/rebuild/04-input.md) | Thiết kế xong |
| M05 Theme | [05-theme.md](superpowers/plans/rebuild/05-theme.md) | Hoàn tất (PR #2 đang mở) |
| M06 Feedback | [06-feedback.md](superpowers/plans/rebuild/06-feedback.md) | Thiết kế xong |
| M07 Campaign | [07-campaign.md](superpowers/plans/rebuild/07-campaign.md) | Thiết kế xong |
| M08 Screens | [08-screens.md](superpowers/plans/rebuild/08-screens.md) | Thiết kế xong |
| M09 Integration | [09-integration.md](superpowers/plans/rebuild/09-integration.md) | Thiết kế xong |
| M10 Content Gen | [10-content-gen.md](superpowers/plans/rebuild/10-content-gen.md) | Thiết kế xong |

### Tiến độ implement

**Wave 1 (M01 Core + M05 Theme):** Hoàn tất; M01 và M05 đã merge vào `dev`.
- **M01 Core:** Hoàn tất trên nhánh `feat/m01-core`, đã merge vào `dev` qua PR #1 (commit `6204da9`). Triển khai `cell_model.gd`, `candy_rules.gd`, `board_solver.gd`, test suite `test_candy_rules.gd` và `test_board_solver.gd`. Pass toàn bộ gate checks và clean-room checks.
- **M05 Theme:** Triển khai `palette.gd` và `layout_tokens.gd` trên `feat/m05-theme` với đầy đủ trạng thái `GIVEN`/`LOCKED` và animation tokens. Godot `--check-only` cho cả hai file exit 0; clean-room và kiểm tra import `extracted_reusable` không có match. Full gate `rtk python -B tools/verify.py --godot <executable>` PASS tại revision `b17896b` (log `scratch/verification/20261002T082451.027046Z.txt`). Sau khi M01 merge, commit `b17896b` đã đồng bộ fixture cử chỉ 350 ms và test discovery để khôi phục full gate. M05 không có test riêng; tích hợp giao diện thuộc M08.
- **M02 State:** Hoàn tất trên nhánh `feat/m02-state` (commit `c3c2a82`). Triển khai lưu JSON A/B, tiến độ campaign, session và cấu hình; thêm bốn test `test_dual_slot_store.gd`, `test_progress_manager.gd`, `test_session_store.gd`, `test_config_store.gd`. Clean-room và kiểm tra import `extracted_reusable` không có match. Full headless verification PASS tại revision `c3c2a82` (log `scratch/verification/20261002T085549.012717Z.txt`). Chờ review PR vào `dev`.

```
Wave 1: M01 + M05           (đã merge)
Wave 2: M02 + M03 + M04     (M02 chờ review PR)
Wave 3: M06 + M07           (cần Wave 2)
Wave 4: M08                 (cần Wave 1-3)
Wave 5: M09                 (integration)
Wave 6: M10                 (content generation)
```

## Baseline

- Client R1: campaign 4 level trên dev branch
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`

## Blockers

Không có blocker kỹ thuật. M02 chờ review PR vào `dev`.
