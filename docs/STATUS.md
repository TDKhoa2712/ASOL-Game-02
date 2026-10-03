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

## Baseline

- `dev` (`f54c4ab`): rebuild 10 modules và campaign 30 level 4×4
- Reference: `extracted_reusable/` (~224 files)
- Tag bảo toàn: `pre-reset-pipeline-2026-09-27`

## Việc cần chốt và kiểm chứng

- **Undo X so với RST-015:** ảnh hưởng hợp đồng gameplay và tài liệu. Chủ dự án chốt giữ Undo giới hạn hay bỏ; sau quyết định, đồng bộ code/test/docs và chạy gate lại. Thử lại nghiệm thu gameplay khi đã chốt.
- **Full gate:** trên HEAD `9edafd4` cùng working tree chưa sạch, chạy `rtk python -B tools/verify.py --godot <Godot 4.7.2>` ngày 2026-10-03: **FAIL**. 13 suite Godot, validator bank/pace/playlist và test Python GDD/tools, tools/tests pass; Python `game/tests` fail vì `test_interaction_fixture_sync.py` còn đọc `game/data/t01.json` đã bị xóa; runner còn kiểm `game/data/campaign_m1.json` đã bị xóa. Log: `scratch/verification/20261002T170324.499222Z.txt` (UTC, Git ignore). Người thực hiện nhánh cần đồng bộ runner/test fixture với dữ liệu hiện hành, chạy lại full gate trên inputs ổn định. Chỉ thử merge khi gate pass.
- **QA UI/thiết bị:** chưa chạy trong lượt rà tài liệu. Người thực hiện nhánh kiểm gesture/UI từ entry scene và trên Android; chủ dự án duyệt kết quả playtest. Chỉ đánh dấu đạt khi có bằng chứng theo revision. iOS còn cần môi trường build/signing.
