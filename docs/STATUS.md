# Trạng thái dự án

> Cập nhật: 2026-10-02

## Mục tiêu hiện tại: Rebuild cho playtest 30 level

**Plan:** [Master plan](superpowers/plans/2026-10-02-rebuild-master.md)
**Quyết định:** RST-012 (rebuild), RST-011 (30-level playtest)

### Tiến độ thiết kế

| Module | Plan | Status |
|--------|------|--------|
| M01 Core | [01-core.md](superpowers/plans/rebuild/01-core.md) | Hoàn tất (PR #1 merged) |
| M02 State | [02-state.md](superpowers/plans/rebuild/02-state.md) | Hoàn tất (PR #4 merged) |
| M03 Content | [03-content.md](superpowers/plans/rebuild/03-content.md) | Hoàn tất (PR #3 merged) |
| M04 Input | [04-input.md](superpowers/plans/rebuild/04-input.md) | Hoàn tất (PR #5 merged) |
| M05 Theme | [05-theme.md](superpowers/plans/rebuild/05-theme.md) | Hoàn tất (PR #2 merged) |
| M06 Feedback | [06-feedback.md](superpowers/plans/rebuild/06-feedback.md) | Hoàn tất (PR #6 đang mở) |
| M07 Campaign | [07-campaign.md](superpowers/plans/rebuild/07-campaign.md) | Hoàn tất (PR #7 merged) |
| M08 Screens | [08-screens.md](superpowers/plans/rebuild/08-screens.md) | Hoàn tất (PR #8 merged) |
| M09 Integration | [09-integration.md](superpowers/plans/rebuild/09-integration.md) | Hoàn tất |
| M10 Content Gen | [10-content-gen.md](superpowers/plans/rebuild/10-content-gen.md) | Hoàn tất |

### Tiến độ implement

**Wave 1 (M01 Core + M05 Theme):** Hoàn tất (M01 và M05 đã merge vào `dev`).
- **M01 Core:** Hoàn tất trên nhánh `feat/m01-core`, đã merge vào `dev` qua PR #1 (commit `6204da9`). Triển khai `cell_model.gd`, `candy_rules.gd`, `board_solver.gd`, test suite `test_candy_rules.gd` và `test_board_solver.gd`. Pass toàn bộ gate checks và clean-room checks.
- **M05 Theme:** Đã merge vào `dev` qua PR #2 (commit `0df7bae`). Triển khai `palette.gd` và `layout_tokens.gd` với đầy đủ trạng thái `GIVEN`/`LOCKED` và animation tokens.

**Wave 2 (M02 State + M03 Content + M04 Input):** Hoàn tất (M02, M03, M04 đã merge vào `dev`).
- **M02 State:** Hoàn tất trên nhánh `feat/m02-state` (commit `c3c2a82`). Triển khai lưu JSON A/B, tiến độ campaign, session và cấu hình; thêm bốn test `test_dual_slot_store.gd`, `test_progress_manager.gd`, `test_session_store.gd`, `test_config_store.gd`. Clean-room và kiểm tra import `extracted_reusable` không có match. Full headless verification PASS tại revision `c3c2a82` (log `scratch/verification/20261002T085549.012717Z.txt`). PR #4 đã merge vào `dev`.
- **M03 Content:** Hoàn tất trên nhánh `feat/m03-content` (commit `19df517`). Triển khai `level_validator.gd`, `board_transform.gd`, `bank_reader.gd`, `pace_reader.gd`, `region_painter.gd`, test suite `test_bank_reader.gd` và dữ liệu mẫu `bank_4x4.json`, `bank_4x4.pace.json`, `demo_30.json`. Pass toàn bộ gate checks, clean-room checks (0 match), không import `extracted_reusable`. Full headless verification PASS tại revision `19df517` (log `scratch/verification/20261002T084522.409699Z.txt`). PR #3 đã merge vào `dev`.
- **M04 Input:** Hoàn tất trên nhánh `feat/m04-input` (commit `5f4e5ae`). Triển khai `touch_decoder.gd`, `action_recorder.gd`, `play_session.gd`, test suite `test_play_session.gd` và `test_touch_decoder.gd`. Pass toàn bộ gate checks, clean-room checks (0 match), không import `extracted_reusable`. Full headless verification PASS (log `scratch/verification/20261002T091947.967716Z.txt`). PR #5 đã merge vào `dev`.

**Wave 3 (M06 Feedback + M07 Campaign):**
- **M06 Feedback:** Hoàn tất trên nhánh `feat/m06-feedback` (commit `1c04935`). Triển khai `sfx_catalog.gd`, `sfx_player.gd`, `bgm_player.gd`, `vibration.gd`, test suite `test_feedback.gd`. Pass toàn bộ gate checks, clean-room checks (0 match), không import `extracted_reusable`. Full headless verification PASS tại revision `1c04935` (log `scratch/verification/20261002T093716.426350Z.txt`). PR #6 đã merge vào `dev`.
- **M07 Campaign:** Hoàn tất trên nhánh `feat/m07-campaign`, đã merge vào `dev` qua PR #7 (commit `051554d`). Bốn script campaign và `test_campaign_runtime.gd` đạt module test, clean-room checks và full headless verification.

**Wave 4 (M08 Screens):**
- **M08 Screens:** Hoàn tất trên nhánh `feat/m08-screens`, đã merge vào `dev` qua PR #8 (commit `d3b96e3`). Triển khai `app_shell.gd`, `puzzle_board.gd`, `puzzle_screen.gd`, `title_screen.gd`, `result_screen.gd`, `options_screen.gd`, `pill_toggle.gd`, 6 scene `.tscn` (`main.tscn`, `title.tscn`, `puzzle.tscn`, `win.tscn`, `fail.tscn`, `options.tscn`), và test suite `test_screens.gd`.

**Wave 5 (M09 Integration):**
- **M09 Integration:** Hoàn tất trên nhánh `feat/m09-integration`. Kết nối end-to-end toàn bộ modules M01-M08, thêm `test_integration.gd` kiểm thử toàn bộ luồng giao diện, lưu trữ, điều hướng và cài đặt. Cập nhật `project.godot` chuyển `run/main_scene` sang `main.tscn`. Lưu trữ an toàn 20 script cũ, các scene cũ và 16 test cũ `run_*.gd` vào `archive/legacy_pre_rebuild/`. Cập nhật `test_runtime_smoke.py` chạy qua `test_integration.gd`. Pass 100% full headless verification suite.

**Wave 6 (M10 Content Gen):**
- **M10 Content Gen:** Hoàn tất trên nhánh `feat/m10-content-gen`. Sinh 30 level 4x4 machine-validated với logic S2/S3 (12 rank 1, 10 rank 2, 8 rank 3), đóng gói `bank_4x4.json`, sinh pace sidecar `bank_4x4.pace.json`, và hoàn thiện playlist chiến dịch `demo_30.json` (L01-L30). Bổ sung công cụ `convert_to_bank.py`, `generate_pace.py`, `build_playtest_bank.py`, validator nội dung `validate_content.py` và test suite `test_validate_content.py`. Tích hợp kiểm thử nội dung vào `verify.py`. Đạt 100% full headless verification suite.

```
Wave 1: M01 + M05           (đã merge)
Wave 2: M02 + M03 + M04     (đã merge)
Wave 3: M06 + M07           (đã merge)
Wave 4: M08                 (đã merge)
Wave 5: M09                 (đã merge)
Wave 6: M10                 (hoàn tất)
```

## Baseline

- Client R1: campaign 4 level trên dev branch
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`

## Blockers

Không có blocker kỹ thuật. M06 chờ review PR #6 vào `dev`.

