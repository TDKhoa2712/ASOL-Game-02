# Trạng thái dự án

> Cập nhật: 2026-10-02

## Mục tiêu hiện tại: Rebuild cho playtest 30 level

**Plan:** [Master plan](superpowers/plans/2026-10-02-rebuild-master.md)
**Quyết định:** RST-012 (rebuild), RST-011 (30-level playtest)

### Tiến độ thiết kế

| Module | Plan | Status |
|--------|------|--------|
| M01 Core | [01-core.md](superpowers/plans/rebuild/01-core.md) | Hoàn tất (PR #1 merged) |
| M02 State | [02-state.md](superpowers/plans/rebuild/02-state.md) | Thiết kế xong |
| M03 Content | [03-content.md](superpowers/plans/rebuild/03-content.md) | Thiết kế xong |
| M04 Input | [04-input.md](superpowers/plans/rebuild/04-input.md) | Thiết kế xong |
| M05 Theme | [05-theme.md](superpowers/plans/rebuild/05-theme.md) | Hoàn tất (sẵn sàng PR) |
| M06 Feedback | [06-feedback.md](superpowers/plans/rebuild/06-feedback.md) | Thiết kế xong |
| M07 Campaign | [07-campaign.md](superpowers/plans/rebuild/07-campaign.md) | Thiết kế xong |
| M08 Screens | [08-screens.md](superpowers/plans/rebuild/08-screens.md) | Thiết kế xong |
| M09 Integration | [09-integration.md](superpowers/plans/rebuild/09-integration.md) | Thiết kế xong |
| M10 Content Gen | [10-content-gen.md](superpowers/plans/rebuild/10-content-gen.md) | Thiết kế xong |

### Tiến độ implement

**Wave 1 (M01 Core + M05 Theme): Hoàn tất.**
- **M01 Core:** Hoàn tất trên nhánh `feat/m01-core`, đã merge vào `dev` qua PR #1 (commit `6204da9`). Triển khai `cell_model.gd`, `candy_rules.gd`, `board_solver.gd`, test suite `test_candy_rules.gd` và `test_board_solver.gd`. Pass toàn bộ gate checks và clean-room checks.
- **M05 Theme:** Hoàn tất trên nhánh `feat/m05-theme` (rebased trên `dev` chứa M01). Triển khai `palette.gd` và `layout_tokens.gd` với đầy đủ trạng thái `GIVEN`/`LOCKED` và animation tokens. Godot `--check-only` exit 0, pass clean-room và không import từ `extracted_reusable`.
- **Sẵn sàng cho Wave 2:** Sau khi merge `feat/m05-theme`, Wave 2 (M02 State, M03 Content, M04 Input) có thể chạy song song.

```
Wave 1: M01 + M05           (Hoàn tất)
Wave 2: M02 + M03 + M04     (Sẵn sàng bắt đầu)
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

Không có blocker. Wave 1 hoàn thành, sẵn sàng mở Wave 2.
