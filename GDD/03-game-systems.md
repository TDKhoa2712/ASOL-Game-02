# GDD-03 — Game Systems

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-03 |
| Phiên bản | 1.0.0 |
| Trạng thái | Approved · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design |
| Liên quan | [GDD-01](01-game-overview.md), [GDD-02](02-core-gameplay.md), [GDD-04](04-ux-ui.md), [GDD-05](05-level-design.md), [GDD-07](07-audio.md), [GDD-08](08-technical-design.md), [GDD-10](10-reasoning-techniques.md) |

> **Tóm tắt:** Chương đặc tả các hệ thống bao quanh core loop: Hint, Undo, Combo, tiến trình campaign, DDA (`pace_adjuster`), Endless mode (đã build, đang tắt) và Assist inventory (Planned). Mỗi hệ thống theo khung Design intent → Quy tắc → Tham số → Edge cases.

## 1. Mục đích và phạm vi

Luật bàn chơi ở [GDD-02](02-core-gameplay.md). Chương này chỉ mô tả hệ thống hỗ trợ, thưởng và tiến trình. Trạng thái triển khai: Hint/Undo/Combo/Campaign/DDA **Live**; Endless **Off**; Assist inventory **Planned**.

## 2. Hint system

**Design intent:** Hint là giáo viên, không phải nút giải. Mỗi lần nhấn trả về *bước suy luận đơn giản nhất kế tiếp* kèm giải thích và highlight, để người chơi học kỹ thuật thay vì chỉ nhận đáp án (P1).

### 2.1 Quy tắc

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-22 | `hint_engine.gd` tính lại từ trạng thái bàn hiện tại và trả hint đầu tiên theo thứ tự chiến lược ở §2.2 | Không dùng con trỏ trace; bước đã hoàn thành bị bỏ qua |
| GR-38 | `puzzle_hint_coordinator` điều phối: engine → `hint_highlight_layer` (spotlight scrim + highlight) + `hint_overlay` (text + nút Apply / Dismiss / Detail); `hint_mutex` chặn kích hoạt lại | SFX `HINT_SHOW`, `HINT_APPLY`, `HINT_DISMISS`, `HINT_WRONG_MARK` |
| GR-43 | Hint không giới hạn số lần; không có badge số lượng; `hintCosts` trong pace chỉ được validate, không tiêu | Nhấn Hint liên tục luôn trả hint |
| GR-44 | Apply thực thi action: đặt/xóa X, hoặc đặt kẹo qua `try_candy` (PLACE_CANDY/REVEAL); Dismiss đóng không đổi bàn | Mark batch từ Apply là một action Undo |
| GR-45 | `hints_used` tăng mỗi lần hiện hint, trừ WRONG_MARK | Ghi vào kết quả thắng |
| GR-46 | Nhấn Hint khi overlay đang hiện → đóng overlay | Không sinh hint mới |
| GR-47 | Mỗi lần nhấn Hint reset combo ([§4](#4-combo)) | Combo về 0 |

### 2.2 Thứ tự chiến lược

| # | Chiến lược | Phát hiện | Action khi Apply | Ghi chú |
| --- | --- | --- | --- | --- |
| 1 | `WRONG_MARK` | X đặt trên ô nghiệm | Xóa X | Không tính `hints_used` |
| 2 | `MARK_NEIGHBORS` | Ô quanh kẹo đã đặt (hàng/cột/vùng/chéo) chưa X | Đặt X | |
| 3 | `SINGLE_CANDIDATE` | Hàng/cột/vùng chỉ còn một ứng viên (S2) | Đặt kẹo | |
| 4 | `LOCK_INTERSECTION` | Ứng viên vùng nằm gọn trong một hàng/cột hoặc ngược lại (S3) | Đặt X | |
| 5 | `LOCKED_SUBSET` | Cặp / bộ ba / bộ bốn khóa (S4–S6) | Đặt X | |
| 6 | `CONTRA_CHAIN` | Chuỗi mâu thuẫn ngắn/dài (S7) | Đặt X | Có nút Detail hiển thị chuỗi |
| 7 | `FALLBACK` | Không kỹ thuật nào áp dụng | Reveal (đặt kẹo) | |

Định nghĩa kỹ thuật ở [GDD-10](10-reasoning-techniques.md).

### 2.3 Tham số

| Tham số | Giá trị | File nguồn |
| --- | --- | --- |
| Cooldown mutex | 500 ms | `screens/hint_mutex.gd` |
| Giới hạn hint/lượt | Không giới hạn | `screens/puzzle_hint_coordinator.gd` |
| Thứ tự chiến lược | §2.2 | `core/hint_engine.gd` |

### 2.4 Edge cases

| Tình huống | Hành vi |
| --- | --- |
| Nhấn Hint hai lần trong 500 ms | Lần sau bị mutex bỏ qua |
| Bàn ở `WON`/`FAILED` | Hint không hoạt động |
| Người chơi đổi bàn sau khi hint hiện rồi mới Apply | Hint tính trên trạng thái lúc hiện; ô không còn hợp lệ bị bỏ qua |
| Tip `C-idle` (30 s không thao tác, 0 hint) | Nút Hint nảy gợi ý ([GDD-04](04-ux-ui.md)) |

## 3. Undo

**Design intent:** cho phép sửa nhanh một thao tác X lỡ tay (P2) nhưng không cho "rút lại" lần thử kẹo — quyết định thử kẹo phải có trọng lượng.

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-32 | Undo có **một slot**: hoàn nguyên action X gần nhất — một tap, một stroke, hoặc một batch X từ Hint Apply. Không có stack, không Redo | Nhấn Undo lần hai liên tiếp không đổi bàn |
| GR-33 | Slot bị xóa khi: `try_candy` (đúng hoặc sai), sau khi Undo, Retry/Restart, lượt mới/resume. Kẹo và X đỏ không undo được. Chỉ hoạt động ở `ACTIVE` | Undo sau double-tap không đổi bàn |
| GR-48 | Nút Undo luôn hiện, không có toggle cài đặt (RST-021) | Settings không có mục Undo |

| Tham số | Giá trị | File nguồn |
| --- | --- | --- |
| Độ sâu Undo | 1 action | `core/` play session |

Edge case: nhấn Undo sau lỗi kẹo kích hoạt tip `C-undo` một lần để giải thích X đỏ không undo được.

## 4. Combo

**Design intent:** khuếch đại khoảnh khắc suy luận đúng bằng phản hồi "candy" tăng dần, thưởng cho chuỗi tự lực (RST-026).

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-49 | Combo đếm số kẹo đúng **do người chơi đặt** liên tiếp; mỗi kẹo đúng phát voice `COMBO_<level>` + popup word-art trên ô | Level 1 = "nice" … 12 = "legendary" |
| GR-50 | Combo reset khi: lỗi, nhấn Hint, kẹo do Hint đặt, Restart/Retry, session mới hoặc resume | Kẹo kế tiếp phát level 1 |

| Tham số | Giá trị | File nguồn |
| --- | --- | --- |
| Level tối đa | 12 | `feedback/combo_tracker.gd` |
| Voice lines | 12 file: nice, great, sweet, awesome, excellent, amazing, delicious, incredible, fantastic, divine, unstoppable, legendary | `feedback/sfx_catalog.gd` |
| Level đạt được ở 4×4–6×6 | ≤ 6 (giới hạn bởi N) | — |

Edge case: kẹo đúng thứ N vừa tăng combo vừa kích hoạt Win; popup không chặn chuyển màn. Audio chi tiết ở [GDD-07](07-audio.md).

## 5. Campaign progression

**Design intent:** một con đường tuyến tính, không quyết định thừa: người chơi chỉ cần nhấn Play.

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-51 | Campaign là playlist tuyến tính; chỉ mở level kế khi thắng level hiện tại (GR-26, GR-28) | Không level picker ngoài debug |
| GR-52 | Campaign đang chạy được chọn bởi `game/data/campaigns/active_campaign.json` (hiện: `campaign_100`) | Đổi file → đổi playlist, không sửa code (RST-019) |
| GR-53 | Khi hoàn tất playlist, nút Home thành Replay; nhấn sẽ reset progress về level đầu (giữ `tutorialSeenIds` theo progress mới) | `replay_campaign()` chỉ chạy khi campaign đã xong; lỗi lưu → giữ progress cũ |
| GR-54 | Mỗi entry playlist `{label,size,rank,index,difficulty}` trỏ vào bank; hiển thị qua biến đổi ×8 | Validator playlist ([GDD-05](05-level-design.md)) |

| Playlist | Số level | Vai trò |
| --- | --- | --- |
| `campaign_100` | 100 (4×4:3, 5×5:5, 6×6:8, 7×7:11, 8×8:13, 9×9:14, 10×10:14, 11×11:16, 12×12:16) | **Active** |
| `demo_30` | 30 (L01–10 4×4, L11–20 5×5, L21–30 6×6) | Playtest |
| `advanced` | 80 (≥ 7×7) | Dự phòng |
| `full_998` | 998 | Kiểm nội dung |
| `demo_cross` | 45 | Test |

## 6. DDA — pace adjuster

**Design intent:** nâng độ khó nhẹ khi người chơi thắng gọn liên tiếp, hạ khi thua liên tiếp, nhưng giới hạn trần theo vị trí trong campaign để không nhảy vọt sớm.

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-55 | Clean win (0 hint, 0 lỗi) liên tiếp ≥ 2 → level kế dùng rank +1 | Trong trần rank |
| GR-56 | Trần rank: 2 đến level 15, 3 đến level 30, 5 sau đó | |
| GR-57 | ≥ 2 lần thua liên tiếp → rank −1, tối đa một lần mỗi level | Rank tối thiểu 1 |

| Tham số | Giá trị | File nguồn |
| --- | --- | --- |
| Clean-win streak | 2 | `campaign/pace_adjuster.gd` |
| Fail streak | 2 | `campaign/pace_adjuster.gd` |
| Rank cap | 2 / 3 / 5 theo mốc 15 / 30 | `campaign/pace_adjuster.gd` |
| Nhánh retry-streak | Dormant (`was_retry` luôn false) | `campaign/pace_adjuster.gd` |

Không có prefill givens khi thua (không có PreCandyDecider).

## 7. Endless mode

> **Trạng thái: Off.** Đã build đầy đủ; `ENABLE_ENDLESS=false` trong `core/game_features.gd`, nút Endless ở Home bị ẩn, chỉ truy cập qua debug panel.

**Design intent:** sau campaign, cung cấp dòng level vô tận có độ khó thích ứng theo kỹ năng, dùng toàn bộ 36.573 level.

### 7.1 Quy tắc

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| GR-58 | Kích thước theo lịch: L1–10 `[4,4,4,5,5,5,6,6,6,6]`, L11–20 `[7,7,8,8,9,9,10,10,11,12]`, sau đó lặp `[8,10,11,9,10,12,9,10,11,12]` | |
| GR-59 | `strategy` 1–7 (khởi đầu 3) ánh xạ sang rank/tier; thắng 0 hint dưới par → +1 (max 7); thua → −1 (min 1) | |
| GR-60 | Tier đặc biệt: milestone (level 10, 20, 30…), super_hard (từ level 35, chu kỳ 10), single_region bổ sung; sp_tt và onefish tắt | `data/endless_config.json` |
| GR-61 | Pool: regular, lkstyle (≥ 7), gc, lk_modified (mỗi 4 level) | |
| GR-62 | Fallback khi pool cạn: bỏ tier → rank khác → size kề → single_region → regular | Luôn trả level |
| GR-63 | Chống lặp: nhớ 50 `pidHash` gần nhất | |

### 7.2 Tham số

| Tham số | Giá trị | File nguồn |
| --- | --- | --- |
| Feature flag | `ENABLE_ENDLESS=false` | `core/game_features.gd` |
| Tier config | milestone on; super_hard on (min 35, period 10); single_region_supp on; sp_tt off; onefish off | `data/endless_config.json` |
| Strategy khởi đầu / min / max | 3 / 1 / 7 | `endless/` |
| `recent_hashes` | 50 | `endless/` |
| Providers | onefish, single_region, sp_tt, special, super_hard | `endless/` |

Progress Endless lưu: `level_num`, `strategy`, streaks, tổng, `best_by_size`, cursors, `recent_hashes` ([GDD-08](08-technical-design.md)).

## 8. Planned — Assist inventory và play streak

> **Trạng thái: Planned.** Đang thiết kế trên nhánh `feat/v1.0.1/assist-inventory`; chưa có trong build. Thiết kế chốt sẽ cập nhật chương này khi merge.

Phạm vi dự kiến: kho assist (stock) cho Hint và assist "đặt kẹo" (chọn ô cho người chơi), badge số lượng và popup hết stock; play streak theo ngày chơi để bổ sung stock. Không gắn tiền thật/quảng cáo (OV-04). Khi triển khai, GR-43 (Hint không giới hạn) sẽ cần quyết định thay thế trong DECISIONS.

## 9. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| OQ-03-1 | Hint không giới hạn có thể làm giảm cảm giác thành tựu | KPI-06/07 | Đo playtest; Assist inventory là phương án |
| OQ-03-2 | `hintCosts` tồn tại trong data nhưng không dùng | Dữ liệu thừa | Dùng cho Assist inventory hoặc bỏ |
| OQ-03-3 | DDA tăng rank có thể vượt kỳ vọng ở bàn lớn | Fail rate tăng | Theo dõi KPI-04 |

## 10. ID đã hủy

| ID | Lý do |
| --- | --- |
| GR-21, GR-23, GR-24, GR-37 | Hint budget / progressive reveal — thay bởi GR-43..46 (xem [GDD-02 §13](02-core-gameplay.md#13-id-đã-hủy)) |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất phần hệ thống từ GDD 02/05, GAME_OVERVIEW, DECISIONS; Undo một slot, Hint không giới hạn, Endless Off, Assist Planned. |
