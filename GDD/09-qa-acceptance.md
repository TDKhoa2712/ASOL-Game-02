# GDD-09 — QA và tiêu chí nghiệm thu

| Thuộc tính | Giá trị |
| --- | --- |
| Dự án | CanDoKu |
| Mã tài liệu | GDD-09 |
| Phiên bản | 1.0.0 |
| Trạng thái | Draft · Living document |
| Cập nhật | 2026-10-14 |
| Phụ trách | Game Design · QA |
| Liên quan | [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md), [GDD-04](04-ux-ui.md), [GDD-05](05-level-design.md), [GDD-08](08-technical-design.md), [GDD-10](10-reasoning-techniques.md), [GDD-11](11-level-generation.md) |

> **Tóm tắt:** Chương này định nghĩa chiến lược kiểm thử nhiều tầng của CanDoKu, bộ test case QA-xx truy ngược về yêu cầu GR/UX/LV/TECH/ART, các cổng nghiệm thu theo mốc (content, gameplay, device, release), kế hoạch playtest và thang mức độ lỗi. Headless PASS là điều kiện cần, không thay QA thiết bị và playtest.

## 1. Mục đích và phạm vi

- Áp dụng cho mọi thay đổi code, nội dung (bank, pace, playlist) và asset trước khi merge vào nhánh version `release/vX.Y.Z` hoặc phát hành.
- Mô tả **cái gì phải kiểm và tiêu chí đạt**. Kết quả chạy, revision và blocker ghi ở [STATUS](../docs/STATUS.md); log evidence lưu tại `scratch/verification/`.
- Hành vi chuẩn được kiểm là hành vi hiện hành của code (xem [GDD-02](02-core-gameplay.md), [GDD-03](03-game-systems.md)). Tính năng Planned (ví dụ assist inventory, Endless bật cho người chơi) chưa có test case nghiệm thu bắt buộc.

## 2. Chiến lược kiểm thử

### 2.1. Test pyramid

| Tầng | Công cụ / vị trí | Phạm vi | Tần suất |
| --- | --- | --- | --- |
| L1 — Unit/logic headless | `game/tests/test_*.gd` chạy `godot --headless --script` | Luật (`test_candy_rules`), solver (`test_board_solver`), hint (`test_hint_engine`), session (`test_play_session`), input (`test_touch_decoder`, `test_touch_guard`), state/save, DDA, Endless, tutorial | Mỗi commit liên quan |
| L2 — Integration headless | `test_integration`, `test_screens`, `test_campaign_runtime`, `test_endless_integration`, `test_puzzle_hint_coordinator`, `test_runtime_smoke.py` | Luồng màn hình, composition root, nối hint/undo/combo với session | Trước bàn giao |
| L3 — Data validators (Python) | `tools/validate_content.py`, `tools/validate_full_content.py`, `tools/playlist_checks.py`, `GDD/tools/validate_levels.py` | Schema bank/pace/playlist, uniqueness, trace, givens rỗng, coverage campaign | Mỗi thay đổi nội dung |
| L4 — Tool unit tests | `python -m unittest` trên `game/tests`, `GDD/tools`, `tools/tests` | Generator, converter, campaign builder, export settings | Trước bàn giao |
| L5 — Full gate | `tools/verify.py` | Tổng hợp L1–L4 + evidence log | Trước merge/bàn giao |
| L6 — Clean-room gate | `tools/clean_room.py` (được `tools/verify.py` gọi ở check `clean-room`) | Không tên/enum từ code tham khảo trong `game/scripts/` | Trước merge (tự động trong L5) |
| L7 — Manual device QA | Thiết bị Android/iOS thật, ma trận §6 | Gesture, safe area, hiệu năng, âm thanh/haptic, accessibility | Mỗi release candidate |
| L8 — Playtest | Người chơi chưa đọc GDD, §5 | Hiểu luật, cảm nhận độ khó, nhầm cử chỉ, retention ngắn hạn | Theo mốc |

Design intent: logic thuần (`static`, stateless) được phủ dày ở L1 để tầng UI chỉ cần kiểm nối dây. Mọi hành vi không thể kiểm headless (cảm giác chạm, nhịp animation, nghe voice combo) bắt buộc đi qua L7.

### 2.2. Lệnh chuẩn

```bash
# Một suite
rtk godot --headless --path game --script res://tests/test_<ten>.gd

# Nội dung
rtk python -B tools/validate_content.py game/data/banks/bank_4x4.json --pace game/data/banks/bank_4x4.pace.json
rtk python -B tools/validate_content.py game/data/campaigns/demo_30.json --bank game/data/banks/bank_4x4.json --bank game/data/banks/bank_5x5.json --bank game/data/banks/bank_6x6.json
rtk python -B tools/validate_full_content.py --banks game/data/banks --playlist game/data/campaigns/full_998.json --demo game/data/campaigns/demo_30.json

# Full gate (bắt buộc trước merge)
rtk python -B tools/verify.py --godot <executable>
```

`verify.py` chạy: unittest của `game/tests`, `GDD/tools`, `tools/tests`; `validate_levels` trên sample; `validate_content` cho bank 4–6 cùng `demo_30`/`demo_cross`; `validate_full_content` cho `full_998`; toàn bộ suite Godot `test_*.gd` headless; ghi evidence log (revision, lệnh, exit code). Timeout mặc định 180 giây/check.

### 2.3. Quy tắc gate

| ID | Yêu cầu | Tiêu chí kiểm |
| --- | --- | --- |
| QA-61 | Clean-room gate | Hai lệnh `rg` của AGENTS §3 không có kết quả trong `game/scripts/` và `game/tests/`; `verify.py` PASS |
| QA-62 | Full gate trước merge | `verify.py` exit 0 trên revision được merge; FAIL do thay đổi chưa commit phải được tách và ghi rõ trong STATUS |
| QA-63 | Giới hạn module | Mọi file `game/scripts/**/*.gd` ≤ 300 dòng; không autoload; không global event bus |
| QA-64 | Evidence | Mỗi lần bàn giao có log trong `scratch/verification/` ghi revision, lệnh, kết quả, giới hạn |

## 3. Test case

Cột **Tầng** chỉ nơi kiểm chính (L1–L8 theo §2.1). Trạng thái thực thi từng ca theo dõi ở STATUS.

### 3.1. Level, solver, trace

| ID | Ca | Kết quả mong đợi | Tầng |
| --- | --- | --- | --- |
| QA-01 | Gate campaign `demo_30` | Đúng 30 mục; L01–L10 4×4, L11–L20 5×5, L21–L30 6×6; mọi tham chiếu `{size,rank,index}` tồn tại trong bank | L3 |
| QA-02 | Level có 0 hoặc ≥2 nghiệm | Validator chặn, báo ID/lý do; timeout solver không được xem là độc nhất | L3 |
| QA-03 | `solution` khai báo khác nghiệm độc lập | Chặn | L3 |
| QA-04 | Vùng không liên thông 4 hướng | Chặn, nêu nhãn vùng | L3 |
| QA-05 | Trace S2/S3 sai focus/đích/tập loại | Chặn tại bước lỗi; bước thiếu/thừa/no-op/lặp hoặc dựa trên nghiệm/X đều bị từ chối; trace đủ N kẹo | L3 |
| QA-06 | Hình vùng lặp trong cửa sổ 8 level liền kề (sau xoay/lật/đổi nhãn) | Chỉ `GDD/tools/validate_levels.py` kiểm (cảnh báo; chặn khi chạy `--release`). Validator playlist của game (`validate_content.py`, `playlist_checks.py`) chưa kiểm | L3 |
| QA-07 | Fixture `GDD/data/levels.sample.json` (T01/E01/E02/S301/N12) | Nghiệm/trace hợp lệ; S301 kiểm S3→S2; N12 kiểm nhãn A–L | L3/L4 |
| QA-32 | Schema sai: thừa/thiếu trường, bool giả int, ID trùng | Báo rõ, không chấp nhận âm thầm | L3 |
| QA-35 | Biên kích thước N=4..12 và N=13 | N=4–12 đọc/kiểm được; N=13 bị từ chối | L1/L3 |
| QA-49 | Level mốc L10, L20 của `demo_30` | Được biên tập duyệt nhịp; qua cùng cổng uniqueness/trace | L3 + review |
| QA-57 | Logic band `demo_30` | L01–L18 giải được bằng S1/S2; L19–L24 cần S3 (closure S2-only STUCK); L25–L30 chỉ dùng S1–S3. Kiểm closure S2-only cho `demo_30` **chưa tự động hóa** — review thủ công | L3 + review |
| QA-65 | Givens bị loại bỏ | `tools/validate_content.py` và `level_validator.gd` từ chối `givens` không rỗng; `pidHash` không phụ thuộc given. **Lỗi đã biết:** `GDD/tools/validate_levels.py` vẫn chấp nhận givens (và `GDD/tools/generate_levels.py` vẫn sinh được), chưa sửa | L1/L3 |
| QA-66 | Solver S4–S7 | Fixture dương/âm cho locked subset k=2,3 (chưa có fixture k≥4) và contradiction chain; không loại ô là nghiệm; `replay_solve` trả `profile` và `max_technique` đúng | L1 |
| QA-67 | Bank 4×4–6×6 (998 level) và `full_998` | `validate_full_content` PASS; mỗi bộ ba bank xuất hiện đúng một lần trong `full_998`. Bank 7×7–12×12 và typed bank **chưa** được tool này kiểm | L3 |

### 3.2. Board, cử chỉ, phiên chơi

| ID | Ca | Kết quả mong đợi | Tầng |
| --- | --- | --- | --- |
| QA-08 | Single tap trên BLANK, MARK, ERROR, CANDY | BLANK↔MARK sau khi hết cửa sổ 350 ms hoặc chạm kế; ERROR/CANDY bất biến; không đổi tim | L1/L7 |
| QA-09 | Double tap (≤350 ms, cùng ô) vào ô đúng | Một lệnh `try_candy`; kẹo đúng cố định; không ghi MARK trung gian | L1/L7 |
| QA-10 | Double tap vào ô sai | Ô thành ERROR, −1 tim, +1 mistake; shake + SFX + haptic; lý do lỗi không hiển thị | L1/L7 |
| QA-11 | Tap/double tap/kéo qua ERROR; sau đó Retry | ERROR không đổi, không mất tim thêm; Retry dựng lại level sạch | L1 |
| QA-12 | Hai tap khác ô, tap chậm hơn cửa sổ, ba tap nhanh, tap thứ hai thành kéo, app vào nền | Không gộp sai cử chỉ, không nhân đôi lỗi; tap đã nhấc được commit, nét chưa nhấc bị hủy | L1/L7 |
| QA-13 | Tap vào CANDY đã tìm | Không đổi trạng thái, không ảnh hưởng tim | L1 |
| QA-14 | Hết 3 tim → Fail → Retry | Màn Fail riêng; Retry mở cùng level với board, tim, mistake, thời gian reset | L2 |
| QA-15 | Đặt đủ N kẹo khi còn MARK/ERROR | Thắng ngay; ghi một result `{time_ms, mistakes, hints_used}`; current level tăng đúng 1 | L1/L2 |
| QA-17 | Input board ở trạng thái WON/FAILED | Bị chặn; không ghi kết quả hai lần | L1 |
| QA-43 | Kéo bắt đầu từ BLANK qua BLANK/MARK/ERROR/CANDY, đi nhanh và vòng ngược | Chỉ ô BLANK trên đường thành MARK, mỗi ô một lần; một batch undo | L1/L7 |
| QA-44 | Kéo bắt đầu từ MARK | Chỉ ô MARK trên đường thành BLANK; một batch | L1/L7 |
| QA-45 | Ngưỡng kéo 12 px, velocity gate 6000 px/s, hai ngón, bắt đầu/nhấc ngoài bàn | Không nhầm tap/drag/double; bỏ chuyển động vượt ngưỡng tốc độ; nét hợp lệ commit một lần | L1/L7 |
| QA-54 | Restart giữa lượt (hủy/xác nhận) | Hủy giữ nguyên state; xác nhận tạo lượt mới cùng level và xóa slot Undo | L2 |
| QA-55 | Undo sau tap X, sau stroke, sau hint đặt mark, sau `try_candy` | Hoàn nguyên đúng hành động X cuối (một slot); `try_candy` xóa slot; Undo lần hai không làm gì; không ảnh hưởng ERROR/tim; chỉ hoạt động ở phase ACTIVE | L1 |
| QA-68 | Combo | Chuỗi kẹo đúng liên tiếp tăng cấp tới trần 12; reset khi sai, khi nhấn Hint, khi hint đặt kẹo, restart, resume; phát voice + popup đúng cấp | L1/L7 |
| QA-69 | Mốc nửa bàn (ceil(N/2) kẹo) | Chỉ phát SFX `PROGRESS_COMPLETE`; không có text | L1 |

### 3.3. Hint, tutorial, màn kết quả

| ID | Ca | Kết quả mong đợi | Tầng |
| --- | --- | --- | --- |
| QA-18 | Có MARK đè ô nghiệm, xin Hint | Hint ưu tiên `WRONG_MARK` (đề nghị xóa mark đó) | L1 |
| QA-19 | Đặt kẹo khác thứ tự trace, xin Hint | Hint tính lại từ board hiện tại theo thứ tự chiến lược [GDD-03](03-game-systems.md); giải thích đúng đơn vị/ô | L1 |
| QA-20 | Xin Hint lặp, Dismiss, Apply | Hint không giới hạn; `hints_used` tăng mỗi lần hiển thị trừ `WRONG_MARK`; mutex 500 ms chặn bấm dồn; nhấn Hint khi overlay đang mở thì đóng overlay | L1/L2 |
| QA-21 | Tutorial bắt buộc làm xong rồi đóng/mở app | Không hiện lại; tiến độ lưu | L2 |
| QA-22 | Coach guide L01/L02 | Bước bỏ qua được (trừ bước đầu L01); tự bỏ qua khi người chơi đi trước | L1/L2 |
| QA-33 | Tutorial 8 bước trên bàn 4×4 cố định | Thứ tự place → regions → touch → rowcol → lone → hearts → last → done; mỗi bước nhận đúng cử chỉ yêu cầu; kết thúc có confetti | L1/L7 |
| QA-36 | Thắng, thua, reduced motion | Win: ribbon, hearts, Time + Mistakes, thẻ NEXT UP, Next Level/Play Again; Fail: ribbon, 0/3 tim, Time, Retry; reduced motion giữ đủ thông tin | L2/L7 |
| QA-56 | Hint đã dùng rồi reload/Back/Retry | `hints_used` được lưu trong session và reset khi Retry/Restart | L1 |
| QA-70 | Contextual tips (C-err, C-heart1, C-undo, C-s3, C-size5, C-idle) | Mỗi tip hiện đúng điều kiện, một lần, lưu `tutorialSeenIds` | L1 |
| QA-71 | Hint áp dụng (Apply) | `PLACE_MARKS` ghi một batch mark có thể Undo; `PLACE_CANDY`/`REVEAL` đi qua `try_candy` và reset combo | L1 |

### 3.4. Save, UX, thiết bị, phát hành

| ID | Ca | Kết quả mong đợi | Tầng |
| --- | --- | --- | --- |
| QA-23 | Home/Settings/Help/app nền giữa lượt | Resume đúng level, board, tim, `hints_used`, thời gian; slot Undo bị xóa | L2/L7 |
| QA-24 | Hỏng một slot save | `DualSlotStore` khôi phục từ slot còn lại; session hash lệch → tạo lại level | L1 |
| QA-25 | Thêm level cuối playlist; `puzzleHash` lệch | Level mới mở đúng; session không hợp lệ không làm tiến level | L1 |
| QA-26 | Chơi offline | Không cần mạng, tài khoản, quảng cáo | L7 |
| QA-27 | Bàn lớn nhất của campaign trên máy nhỏ, safe area | Ô và nút đủ vùng chạm; không bị che/cắt; không zoom/pan | L7 |
| QA-28 | Thang xám, colorblind, tắt âm/rung, reduced motion | Vùng/kẹo/ERROR/tim vẫn phân biệt; pattern colorblind hiện đúng | L1/L7 |
| QA-30 | Hiệu năng animation kẹo/combo trên máy thấp | Đạt ngân sách khung hình [GDD-08](08-technical-design.md); đo FPS/RAM/khựng | L7 |
| QA-31 | Ghi save thất bại, crash giữa ghi | Ghi atomic `.tmp`; không mất progress đã xác nhận | L1 |
| QA-34 | Asset và build Android/iOS | Mọi asset có nguồn gốc rõ; build offline; không chứa asset tham chiếu | L7 + review |
| QA-50 | Bộ sprite kẹo dùng chung mọi vùng | Vùng phân biệt bằng màu nền/pattern; không nhân asset theo màu | L7 |
| QA-72 | Localization 7 ngôn ngữ | Không thiếu key; font CJK fallback hiển thị đúng; chuỗi không tràn khung | L1/L7 |
| QA-73 | Feature flag | `ENABLE_ENDLESS=false` ẩn nút Endless ở Home; debug UI không có trong release build | L1/L7 |

### 3.5. ID đã hủy

| ID | Lý do |
| --- | --- |
| QA-16 | Score không hiển thị cho người chơi |
| QA-29 | Screen reader trên board chưa thuộc phạm vi v1 (Backlog) |
| QA-37, QA-40, QA-41 | Gộp vào QA-05, QA-19, QA-66 |
| QA-38, QA-39, QA-42 | Cổng nghiên cứu S4/S5/N12 cũ; thay bằng QA-35, QA-66 |
| QA-46, QA-47, QA-48, QA-51, QA-52, QA-53 | Kinh tế, bộ sưu tập, generator cũ ngoài phạm vi |
| QA-58, QA-59 | Auto-mark và grouped undo không có trong thiết kế hiện hành |
| QA-60 | Progressive hint nhiều bước không có trong thiết kế hiện hành |
| QA-CD-01..06 | Nghiệm thu chuyển chủ đề đã kết thúc; nội dung còn hiệu lực chuyển vào QA-34, QA-50 |

Không tái sử dụng các ID trên.

## 4. Cổng nghiệm thu theo mốc

| Gate | Điều kiện đạt | QA bắt buộc |
| --- | --- | --- |
| G1 — Content | Mọi bank/pace/playlist qua validator; givens rỗng; logic band `demo_30`; coverage `full_998` | QA-01..07, 32, 35, 49, 57, 65..67 |
| G2 — Gameplay (headless) | Toàn bộ suite Godot và unittest PASS qua `verify.py`; clean-room sạch | QA-08..15, 17..25, 31, 33, 36, 43..45, 54..56, 61..64, 68..71 |
| G3 — Device | Ma trận §6 đã chạy trên ít nhất một máy mỗi hàng Bắt buộc; không còn lỗi S1/S2 mở | QA-12, 26..28, 30, 43..45, 50, 72 |
| G4 — Playtest | Đạt chỉ tiêu §5.2 | Ghi biên bản playtest |
| G5 — Release | G1–G4 đạt; banks đã XOR-encode; keystore/signing; debug ẩn; asset có quyền; build APK/AAB và iOS từ preset Release | QA-34, 73 + checklist phát hành |

Một gate chỉ được báo đạt khi có evidence (revision, lệnh, kết quả). Headless PASS không thay G3/G4.

## 5. Playtest

### 5.1. Kế hoạch

| Hạng mục | Quy định |
| --- | --- |
| Đối tượng | ≥10 người chưa đọc GDD, phân bố người chơi puzzle casual và người chưa chơi thể loại logic grid |
| Thiết bị | Điện thoại thật, build Release hoặc Debug ẩn debug UI |
| Nội dung | Tutorial bắt buộc + L01–L30 của campaign hoạt động |
| Phương pháp | Quan sát im lặng, không gợi ý; think-aloud sau phiên; ghi cục bộ, không analytics mạng |
| Pilot sớm | 3–5 người để bắt lỗi hiểu luật/input trước vòng chính |

### 5.2. Chỉ số và ngưỡng

| Chỉ số | Cách đo | Ngưỡng mục tiêu |
| --- | --- | --- |
| Hiểu luật sau tutorial | Giải được L01 không cần hỏi | ≥8/10 người |
| Nhầm cử chỉ | Double tap vô ý hoặc tap thành kéo / tổng thao tác | <3% |
| Thời gian mỗi level | Median và p75 theo kích thước | Khớp mục tiêu [GDD-05](05-level-design.md) |
| Completion | Hoàn thành không bỏ cuộc tới L30 | Ghi theo level |
| Mistakes, hints_used | Phân bố theo level | Phát hiện spike |
| Nhận diện vùng | Lần nhầm vùng do màu | Ghi định tính |
| Cảm nhận | Thang 1–5: vui, công bằng, độ khó | Median ≥4 cho "công bằng" |

Nếu tỷ lệ nhầm cử chỉ ≥3%, chỉnh cửa sổ double tap/ngưỡng kéo/feedback rồi chạy lại QA-08..12, 43..45. Nếu một level có spike thời gian hoặc hint, chuyển cho biên tập level theo [GDD-11 §8](11-level-generation.md#8-hiệu-chỉnh-bằng-người-chơi).

## 6. Ma trận thiết bị

| Hạng | Thiết bị đại diện | Mục đích | Mức |
| --- | --- | --- | --- |
| Android thấp | RAM 2–3 GB, màn ≤6", GPU entry-level | Hiệu năng, bàn lớn trên màn nhỏ | Bắt buộc |
| Android trung | RAM 4–6 GB, màn 6–6.7" có notch/punch-hole | Safe area, gesture | Bắt buộc |
| Android tablet | 8–11" | Layout portrait tỉ lệ rộng | Khuyến nghị |
| iPhone nhỏ | Màn ~4.7" | Vùng chạm, chữ lớn | Bắt buộc khi phát hành iOS |
| iPhone hiện đại | Dynamic Island / notch | Safe area, haptic | Bắt buộc khi phát hành iOS |
| Web | Chrome desktop/mobile | Smoke test preset Web | Khuyến nghị |

Mỗi hàng ghi model, OS, build revision và kết quả trong log QA.

## 7. Mức độ lỗi

| Mức | Định nghĩa | Ví dụ | Chính sách |
| --- | --- | --- | --- |
| S1 — Blocker | Crash, mất save, không thể hoàn thành level, level sai luật/nhiều nghiệm | Crash khi resume; progress bị xóa | Chặn mọi gate; sửa ngay |
| S2 — Critical | Sai luật/feedback ảnh hưởng kết quả, input nhận sai có hệ thống | Mất tim khi tap ERROR; double tap ghi nhận nhầm | Chặn G2/G3/G5 |
| S3 — Major | Sai hiển thị/âm thanh rõ rệt, hint giải thích sai nhưng không phá luật | Popup combo sai cấp; chữ tràn khung | Chặn G5 trừ khi có quyết định waiver |
| S4 — Minor | Lỗi thẩm mỹ, chính tả, timing nhỏ | Lệch 1–2 px; dịch chưa tự nhiên | Không chặn; xếp Backlog |

## 8. Câu hỏi mở và rủi ro

| ID | Vấn đề | Tác động | Hướng xử lý |
| --- | --- | --- | --- |
| R-09-01 | Logic band QA-57 hiện là yêu cầu biên tập; chưa validator nào kiểm closure S2-only cho `demo_30` | Có thể lọt level sai band | Bổ sung check vào `validate_content` hoặc ghi rõ vào STATUS |
| R-09-02 | Chưa có thiết bị iOS cố định cho QA | G3 iOS chưa thể đạt | Quyết định phạm vi nền tảng cho bản đầu |
| R-09-03 | Campaign hoạt động là `campaign_100` (tới 12×12) trong khi playtest chuẩn dùng 30 level đầu | Kết quả playtest không phủ bàn lớn | Lên vòng playtest riêng cho N≥7 |

## Lịch sử thay đổi

| Phiên bản | Ngày | Thay đổi |
| --- | --- | --- |
| 1.0.0 | 2026-10-14 | Viết lại theo chuẩn GDD; hợp nhất GDD 07 cũ, cập nhật QA theo hành vi code (bỏ givens, auto-mark, progressive hint, hiển thị score), thêm test pyramid, gate theo mốc, ma trận thiết bị, mức độ lỗi |
