# Trạng thái dự án

> Cập nhật: 2026-10-03

## Mục tiêu hiện tại: Chỉnh lại gameplay và giao diện

**Quyết định:** RST-015 (gameplay/UI realignment)
**Plan:** [Gameplay & UI Realignment](superpowers/plans/2026-10-02-gameplay-ui-realign.md)

### Trạng thái trên nhánh `feat/gameplay-ui-realign`

Các commit `8181021`–`9edafd4` đã đưa CellKind về 5 trạng thái, bỏ auto-lock, giữ ERROR vĩnh viễn, nối swipe để đánh/xóa X và dựng lại các màn hình. Gameplay UI hiện dùng `puzzle_layout.gd`; nhánh này **chưa merge vào `dev`**. Code còn Undo cho thao tác X gần nhất, trong khi RST-015 và plan yêu cầu bỏ Undo. Chênh lệch này cần quyết định sản phẩm trước khi nghiệm thu gameplay.

### Tiến độ chỉnh sửa

| Task | Nội dung | Status |
|------|----------|--------|
| T1–T2 | CellKind 5 trạng thái, bỏ auto-lock | Có trong code nhánh; cần gate cuối |
| T3, T6 | PlaySession và handler | Một phần: vẫn có Undo X |
| T4–T5 | Swipe và board rendering | Có trong code nhánh; cần QA gesture |
| T7–T8 | Layout puzzle và palette | Có trong code nhánh; cần QA màn hình |
| T9–T10 | Test và rà tham chiếu cũ | Chưa xác nhận full gate trên working tree hiện tại |
| T11–T12 | Title và result screens | Có trong code nhánh; cần QA màn hình |
| T13 | Final verification | Chưa xác nhận full gate/thiết bị |

## Giai đoạn trước: Rebuild (hoàn tất)

Rebuild 10 modules hoàn tất, tất cả đã merge vào `dev` (PR #1–#10). Đã sinh bank và playlist **30 level 4×4**; chưa có bank 5×5/6×6 và chưa có nghiệm thu playtest mù hoặc thiết bị.

```
Wave 1: M01 + M05           (đã merge)
Wave 2: M02 + M03 + M04     (đã merge)
Wave 3: M06 + M07           (đã merge)
Wave 4: M08                 (đã merge)
Wave 5: M09                 (đã merge)
Wave 6: M10                 (đã merge)
```

## System Upgrade (hoàn tất — merged vào `dev` 2026-10-03)

7 modules nâng cấp từ nhánh `feat/solver-advanced` và 4 follow-up branches đã merge vào `dev`:

| Module | Nội dung | Status |
|--------|----------|--------|
| ShapeFingerprint | Canonical region hash cho snapshot dedup | Merged |
| ProgressManager | recentShapes tracking (tránh lặp) | Merged |
| SessionStore | Snapshot lưu/phục hồi giữa session | Merged |
| CampaignRuntime | Snapshot round-trip + pace_adjuster DDA | Merged |
| BoardSolver S4-S7 | SUBSET_PAIR, SUBSET_TRIPLE, SUBSET_QUAD, CONTRA_CHAIN | Merged |
| RegionPainter | assign_with_overlays(), overlay_tint(), colorblind support | Merged |
| PaceAdjuster (DDA) | Dynamic difficulty, win/loss streaks | Merged |
| BankCodec/BankReader | XOR encode/decode bank files | Merged |
| snapshot_builder.gd | Extracted từ campaign_runtime (F1) | Merged |
| Colorblind rendering | puzzle_board.gd + puzzle_screen.gd wired (F2) | Merged |
| Solver S4+ test | 5×5 pentomino xác nhận SUBSET_PAIR (F3) | Merged |
| Bank generation tooling | argparse + --size cho generate_levels/build_playtest/generate_pace (F4) | Merged |

**Gate trước merge:** 12/12 Godot test suites PASS, clean-room 0 match, tất cả modules ≤ 300 dòng.

**Việc còn mở (deferred):**
- DDA `rank_offset` được tính nhưng chưa được campaign_runtime áp dụng khi chọn rank level
- Colorblind overlay: ThemeDB.fallback_font có thể thiếu glyph unicode trên một số thiết bị (cần manual QA)
- Snapshot thiếu fields `rating`/`solve_profile` từ spec (chưa có consumer)
- Chưa có bank 5×5/6×6 (tooling sẵn sàng; generation là bước riêng)

### Last-Mile Task 1: DDA rank_offset wired into campaign (đã merge vào `dev` 2026-10-03)

CampaignRuntime đã áp dụng DDA khi chọn rank từ bank và pace, fallback về rank playlist nếu rank/index điều chỉnh thiếu dữ liệu. Puzzle đang chơi được ghim bằng snapshot để restart và resume không đổi level khi streak đổi.

### Last-Mile Task 2: Colorblind toggle in options screen (đã merge vào `dev` 2026-10-03)

- Thêm toggle "Hỗ trợ phân biệt màu" (`colorblind`) vào `options_screen.gd` thông qua `WIDE_KEYS`.
- `app_shell.gd`: xử lý thiết lập `colorblind` trong `_apply_setting()`, tự động đồng bộ và vẽ lại bàn cờ qua `_refresh_puzzle_colorblind()`.
- Flow options -> puzzle tạo lại màn hình mới và áp dụng `set_colorblind()` trước `configure()`.
- Test suite: `test_screens.gd` (PASS), `test_colorblind.gd` (PASS), `test_config_store.gd` (PASS), `test_integration.gd` (PASS).

### Last-Mile Task 3: Bank 5×5 generated (đã merge vào `dev` 2026-10-03)

- `bank_5x5.json`: 30 levels (12 rank 1, 10 rank 2, 8 rank 3), validated by `validate_content.py`.
- `bank_5x5.pace.json`: pace sidecar generated.
- Campaign `demo_30.json` unchanged — pending product decision on 5×5 placement.

## Baseline

- `dev` (HEAD 2026-10-03): rebuild 10 modules + system upgrade 7 modules + 4 follow-ups
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`

## Việc cần chốt và kiểm chứng

- **Undo X so với RST-015:** ảnh hưởng hợp đồng gameplay và tài liệu. Chủ dự án chốt giữ Undo giới hạn hay bỏ; sau quyết định, đồng bộ code/test/docs và chạy gate lại. Thử lại nghiệm thu gameplay khi đã chốt.
- **Full gate:** trên HEAD `9edafd4` cùng working tree chưa sạch, chạy `rtk python -B tools/verify.py --godot <Godot 4.7.2>` ngày 2026-10-03: **FAIL**. 13 suite Godot, validator bank/pace/playlist và test Python GDD/tools, tools/tests pass; Python `game/tests` fail vì `test_interaction_fixture_sync.py` còn đọc `game/data/t01.json` đã bị xóa; runner còn kiểm `game/data/campaign_m1.json` đã bị xóa. Log: `scratch/verification/20261002T170324.499222Z.txt` (UTC, Git ignore). Người thực hiện nhánh cần đồng bộ runner/test fixture với dữ liệu hiện hành, chạy lại full gate trên inputs ổn định. Chỉ thử merge khi gate pass.
- **QA UI/thiết bị:** chưa chạy trong lượt rà tài liệu. Người thực hiện nhánh kiểm gesture/UI từ entry scene và trên Android; chủ dự án duyệt kết quả playtest. Chỉ đánh dấu đạt khi có bằng chứng theo revision. iOS còn cần môi trường build/signing.
