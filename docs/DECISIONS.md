# Quyết định điều hành hiện hành

## RST-019 — Bank đầy đủ và campaign chọn bằng file phát triển

Ngày 2026-10-05. Chủ dự án yêu cầu mở rộng theo quy mô tham khảo thành 998 level gốc, năm rank, đưa toàn bộ vào playlist và cho người phát triển đổi giữa chiến dịch đầy đủ với demo 30 màn qua file cấu hình.

- Ba bank v1 có lần lượt 36 level 4×4 (`12/10/8/3/3`), 49 level 5×5 (`12/10/8/9/10`) và 913 level 6×6 (`199/196/193/167/158`). Dùng luật S1–S3 và hình vùng, nghiệm, trace do CanDoKu sinh/kiểm độc lập.
- `full_998.json` giữ nguyên L01–L30 của `demo_30.json`, rồi phủ từng tham chiếu bank còn lại một lần. `active_campaign.json` có giá trị `full_998` mặc định hoặc `demo_30`; thay đổi có hiệu lực khi khởi động lại.
- Demo tiếp tục lưu progress và session tại `user://profile`; full campaign lưu tại `user://profile/full_998`. Settings cùng dùng `user://profile/config.json`.
- Giữ hình vùng, nghiệm, ô cho sẵn và index của 90 puzzle cũ. Theo quyết định bổ sung của chủ dự án, sửa trace và pace của 30 puzzle 5×5 cũ sau khi validator độc lập phát hiện trace không hợp lệ; điểm rating/profile dẫn xuất được tính lại. Ba cặp puzzle 5×5 cũ trùng hệt nhau được giữ vì yêu cầu giữ puzzle gốc; validator chỉ miễn trừ đúng ba cặp này và cấm mọi trùng lặp mới.
- Điểm độ khó theo solver tăng theo trung vị qua năm rank ở từng kích thước; nhãn này chưa thay cho thử nghiệm với người chơi. Chưa nghiệm thu giao diện hoặc thiết bị.

## RST-018 — Demo 30 màn tăng từ 4×4 đến 6×6

Ngày 2026-10-04. Chủ dự án chốt demo có 30 màn, chia đều ba kích thước:

- Playlist mặc định `game/data/campaigns/demo_30.json`: L01–L10 là 4×4, L11–L20 là 5×5, L21–L30 là 6×6.
- Mỗi nhóm gồm 5 màn Rank 1, 3 màn Rank 2, 2 màn Rank 3; giữ tutorial tại L01/L02. Khi tăng kích thước, bắt đầu lại ở Rank 1; DDA tiếp tục chọn rank trong bank cùng kích thước.
- Dùng bank và pace gốc hiện có; playlist `demo_cross.json` 45 màn tiếp tục phục vụ kiểm thử riêng.
- Tiến trình đã lưu giữ nguyên. Lượt đang chơi có snapshot giữ puzzle và pace cũ đến khi hoàn tất; màn tiếp theo dùng playlist mới. Đây là bản demo/playtest, chưa phải nghiệm thu phát hành.

## RST-017 — Giữ Undo X, thêm toggle trong cài đặt

Ngày 2026-10-04. Chủ dự án chốt: giữ Undo X (hoàn tác X-mark cuối) nhưng có thể bật/tắt qua mục cài đặt:

- `config_store.gd`: key `"undo_x"` mặc định `true`, lưu persistent cùng profile.
- `options_screen.gd`: tile "Hoàn tác X" trong nhóm WIDE_KEYS — cùng dạng wide toggle với high_contrast và colorblind.
- `app_shell.gd`: khi setting thay đổi, gọi `set_undo_visible(bool)` trên puzzle screen đang hiển thị.
- `puzzle_screen.gd`: `set_undo_visible(bool)` ẩn/hiện `undo_btn`.
- Thay yêu cầu "bỏ undo stack" trong RST-015; Undo X vẫn chỉ hoàn tác X-mark (không hoàn tác candy).

## RST-016 — Bỏ preview X khi chạm xuống

Ngày 2026-10-03. Chủ dự án yêu cầu thực hiện plan `2026-10-03-fix-doubletap-x-preview.md` để sửa nháy X khi chạm đôi:

- Chạm xuống không hiện preview X; chạm đôi đặt kẹo không nháy X trước đó.
- Preview đánh/xóa X bắt đầu khi kéo, gồm ô đầu và các ô trung gian.
- Chạm đơn vẫn commit sau cửa sổ chạm đôi 350 ms; không thay đổi timing hoặc luật đặt kẹo.
- Thay yêu cầu preview ngay khi chạm xuống trong GDD 02; không thay các quyết định về Undo hoặc auto-lock.

## RST-015 — Chỉnh lại gameplay và giao diện theo nguồn tham khảo

Ngày 2026-10-02. Chủ dự án yêu cầu căn chỉnh lại cơ chế gameplay và giao diện sau khi rebuild đã hoàn tất:

- **Bỏ cơ chế auto-lock cells:** Đặt candy đúng không còn tự động lock ô cùng row/col/zone/diagonal. Ô vẫn tương tác được sau khi đặt candy — đúng hành vi nguồn tham khảo `extracted_reusable/`. Xóa `LOCKED` khỏi `CellKind` enum, xóa `compute_auto_marks`, `compute_all_auto_marks`, `_recompute_all_locks`.
- **Đổi WRONG → ERROR (vĩnh viễn):** Đặt sai → cell thành ERROR (X đỏ vĩnh viễn, không xóa được) thay vì WRONG. Đúng hành vi tham khảo: sai là vĩnh viễn.
- **Bỏ undo stack:** Tham khảo không có undo. X marks toggle trực tiếp bằng tap lại. Xóa `ActionRecorder` khỏi play session.
- **Bật swipe gesture:** Single tap = toggle X, double tap = place candy, swipe = paint/clear X trên nhiều ô — đúng 3 gesture của tham khảo.
- **Giao diện puzzle screen theo layout cũ:** Rebuild theo `archive/legacy_pre_rebuild/scripts/board_screen.gd`: TopBar (circular buttons) → StatusRow (region progress pill + hearts pill) → RuleCard (3x3 mini-grid icons) → BoardCard (shadow, rounded) → BottomDock (hint button). Programmatic build, cream background, warm aesthetic.
- **Giao diện title/result screens theo layout cũ:** Orange pill play button, candy logo, colored result backgrounds.
- **CellKind mới 5-state:** BLANK(0), MARK(1), CANDY(2), ERROR(3), GIVEN(4).
- Không đổi: luật puzzle (row/col/zone/no-touch), hint system, bank/pace/campaign, save schema version (v3), phạm vi 30 level playtest.
- Plan: [Gameplay & UI Realignment](superpowers/plans/2026-10-02-gameplay-ui-realign.md)

**Ghi nhận triển khai 2026-10-03:** Nhánh `feat/gameplay-ui-realign` hiện giữ Undo giới hạn cho X và có nút Undo trong layout, khác yêu cầu “bỏ undo stack” ở trên. Đây là chênh lệch giữa quyết định và code, chưa phải quyết định thay thế; theo dõi tại [STATUS](STATUS.md).

## RST-014 — Hoàn tất Module 10 (Content Generation) và phát hành 30 level playtest

Ngày 2026-10-02. Hoàn tất Module 10 (Content Generation) theo kế hoạch rebuild CanDoKu:
- **Dữ liệu level:** Sinh 30 levels 4×4 độc lập hình học, nghiệm duy nhất được chứng minh bằng logic giải S2/S3; phân bổ thành 12 level Rank 1 (tutorial/easy), 10 level Rank 2 (medium), và 8 level Rank 3 (medium khó hơn).
- **Format Bank v1:** Đóng gói thành `game/data/banks/bank_4x4.json` với schema v1 đầy đủ `seed`, `regions`, `solution`, `givens`, `steps`, `profile`, `rating`, `pidHash`, `logicTrace`.
- **Pace Sidecar:** Tự động sinh `game/data/banks/bank_4x4.pace.json` tính toán `rSeq` và `hintCosts` từ logic trace, khớp 100% với bank.
- **Campaign Playlist:** Hoàn thiện `game/data/campaigns/demo_30.json` với 30 levels L01–L30 theo đúng thứ tự thăng tiến.
- **Công cụ & Kiểm định:** Phát triển `convert_to_bank.py`, `generate_pace.py`, `build_playtest_bank.py`, validator độc lập `validate_content.py` kèm bộ unit test `test_validate_content.py`, tích hợp trực tiếp vào `tools/verify.py`.
- **Kiểm chứng:** Toàn bộ test suite Godot và Python đạt 100% PASS, vượt qua toàn bộ gate clean-room và không tạo asset trái phép.

## RST-013 — Hoàn tất Module 9 (Integration) và lưu trữ mã nguồn cũ

Ngày 2026-10-02. Hoàn tất Module 9 (Integration & Verification) kết nối toàn bộ hệ thống rebuild từ M01 đến M08:
- **Lưu trữ mã cũ:** Di chuyển 20 script cũ từ `game/scripts/`, các scene cũ từ `game/scenes/` và 16 test suite cũ `run_*.gd` sang thư mục lưu trữ `archive/legacy_pre_rebuild/`.
- **Cấu hình dự án:** Cập nhật `game/project.godot` chuyển `run/main_scene` sang `res://scenes/main.tscn`.
- **Smoke test:** Cập nhật `test_runtime_smoke.py` tham chiếu tới bộ kiểm thử tích hợp `res://tests/test_integration.gd` với kết quả mong đợi `INTEGRATION_PASS`.
- **Kiểm thử tích hợp (M09):** Bổ sung test suite `test_integration.gd` kiểm chứng trọn vẹn luồng thực thi: khởi động AppShell và dependency injection, chuyển đổi màn hình Title → Puzzle → Win → Next, Puzzle → Fail → Retry, Options toggle audio/haptic, tự động lưu session sau thao tác, phục hồi session khi khởi động lại, và xử lý thông báo lỗi lưu dữ liệu.
- **Tuân thủ gate:** Clean-room đạt 0 match, không import `extracted_reusable`, không asset mới ngoài quy định, toàn bộ test suite headless của rebuild PASS 100% qua `tools/verify.py`.


## RST-012 — Rebuild hoàn chỉnh từ thiết kế tham khảo

Ngày 2026-10-02. Chủ dự án phê duyệt rebuild hoàn chỉnh game CanDoKu dựa trên phân tích và tối ưu hóa từ bộ tham khảo `extracted_reusable/` (~224 files, ~35,700 dòng).

- **Phạm vi:** Viết lại toàn bộ code game thành 10 modules mới, clean-room. Tham khảo hành vi, KHÔNG sao chép code/tên/enum từ reference.
- **Kiến trúc mới:** Bank + Pace + Playlist cho level system; CellKind 6-state (thêm GIVEN, LOCKED); Auto-mark system; Progressive hints; Command pattern grouped undo; SFX rate limiting; Transform x8.
- **Plan lịch sử:** master plan rebuild và 10 module plans đã được dọn khỏi working tree sau khi merge; xem [HISTORY](HISTORY.md) và Git history để tra cứu. Kế hoạch này từng mô tả interface contracts và 6 waves.
- **AGENTS.md** viết lại tối ưu cho multi-agent parallel execution.
- Không đổi mục tiêu sản phẩm (vẫn playtest 30 level theo RST-011), schema level v4, phạm vi N=4-6/S1-S3.
- Thay thế R1/R2/R3/R4 roadmap cũ bằng rebuild → playtest → quyết định phát hành.
- Code cũ (`puzzle_core.gd`, `interaction_session.gd`, `bootstrap.gd`, v.v.) được giữ tạm trong quá trình build, xóa sau khi module mới pass test (Module 9 Phase 4).

## RST-011 — Bản playtest 30 level trước phát hành

Ngày 2026-10-01. Chủ dự án xác nhận client hiện tại vẫn là campaign bốn level của R1; mốc nội dung tiếp theo là **bản playtest trước phát hành gồm 30 level gốc liên tiếp**, không phải bản phát hành chính thức.

- Quyết định này thay mục tiêu kế hoạch “bản đầu 24 level” trong RST-002 và các tài liệu đang hoạt động. Các bằng chứng và ghi chép lịch sử tại revision cũ vẫn giữ nguyên ý nghĩa.
- Baseline đã duyệt tiếp tục áp dụng cho order 1–24: order 1–18 dùng S1/S2; từng order 19–24 cần S3. Sáu order 25–30 phải có profile nội dung được duyệt riêng sau dữ liệu playtest, nhưng vẫn giới hạn N=4–6 và S1–S3; không tự mở S4/S5, Endless hoặc sinh level runtime.
- Campaign 30 level phải qua validator/gate playtest có tên và phạm vi rõ, lượt giải mù, kiểm UI và thiết bị. Cờ `--release` 24-level hiện tại là gate legacy, không chứng nhận mốc mới.
- Sau playtest, chủ dự án mới quyết định số level, phạm vi nền tảng và tiêu chí của bản phát hành chính thức. Không dùng con số 30 để tuyên bố release-ready.
- Quyết định này không đổi schema level/save, luật chơi, kinh tế, dịch vụ mạng hoặc tự mở R2–R4.

## RST-010 — Cho phép pilot generator offline

Ngày 2026-09-29. Cho phép triển khai bộ generator/rating offline giới hạn N=4–6 để tạo ứng viên pilot và kiểm chứng thiết kế GDD 10/11.

- Công cụ chỉ ghi thư mục đầu ra mới, không sửa campaign hoặc chạy trong client; không mở Endless, runtime generation hay R2–R4.
- `MACHINE_VALIDATED` không đồng nghĩa production-ready. Difficulty chỉ là nhãn tạm đến khi có playtest mù, duyệt UI và hiệu chỉnh bằng người chơi mục tiêu.
- Profile đầu tạo tám ứng viên trải order 2–22, gồm tier B và I; dữ liệu pilot được giữ để tái lập và phục vụ vòng duyệt người, không tự nhập vào 24 level phát hành.

## RST-009 — Dọn tài nguyên thừa và tích hợp CanDoKu

Ngày 2026-09-29. Chủ dự án yêu cầu xóa phần không còn sử dụng và merge về `dev`.

- Bỏ ảnh mèo/cá, logo/avatar cũ, atlas bitmap và ảnh tiền/daily/leaderboard đã không còn tham chiếu; bỏ cặp import tương ứng. Bản nguồn tracked khôi phục được từ Git.
- Gỡ các khối Home tiền/daily/leaderboard đang tắt, nút avatar không có hành động và cấu hình đi kèm. Hai spec UI cũ đã được xóa; GDD 02/03/06 là chỉ dẫn hiện hành.
- Commit chọn file CanDoKu và phần dọn; giữ bảy sửa import icon nút đang dùng ngoài commit. Tích hợp local về `dev` sau kiểm chứng. R1/thiết bị chưa được coi hoàn tất.

## RST-008 — Chuyển đồng bộ CanDoKu trong GDD và mã nguồn

Ngày 2026-09-29. Chủ dự án xác nhận phạm vi **cả GDD và mã nguồn game**; thay phần giữ token cũ của RST-006.

- Hợp đồng hiện hành dùng `candy`, `TryCandy`, `try_candy`, `CandyFound`, `sourceCandy` và `tutorialCandyCell`; đồng bộ solver, Hint, tutorial, vector, validator và test.
- Session v3; hỗ trợ đọc v2 bằng converter cô lập, giữ nguyên dữ liệu lượt và ghi v3 ở lần lưu tiếp theo. Progress v2, level v4, ID, hash và app identifier không đổi. Tên hiển thị CanDoKu nhưng đường dẫn profile cũ được giữ.
- Dùng hình kẹo/tim gốc thay hình chủ đề cũ đang được tham chiếu. Asset cũ có sửa sẵn được bảo toàn, không còn dùng trong client. Không bật daily/tiền/leaderboard ngoài phạm vi.
- Hai spec UI và công cụ xuất báo cáo phải theo GDD hiện hành; lịch sử/evidence không được sửa thành kết quả mới. Đây không phải nghiệm thu R1, mobile hoặc phát hành.


## RST-007 — Tài liệu nền suy luận và sinh level

Ngày 2026-09-28. Chủ dự án yêu cầu một file đầy đủ về nguyên tắc suy luận và một file về sinh level/đánh giá độ khó để làm nền tạo nội dung về sau.

- Mở rộng GDD 10 và tạo GDD 11 mới chuyên về sinh level/độ khó. File 11 mới không khôi phục đề án meta/vàng/bộ sưu tập đã bỏ ở RST-006.
- Bao gồm kỹ thuật nâng cao, hợp đồng generator offline và phương pháp chấm khó để nghiên cứu; giữ riêng trạng thái đã hỗ trợ so với cần phát triển.
- Công thức rating-0/ngưỡng phân loại là đề xuất chưa hiệu chỉnh; không thay công thức điểm gameplay hoặc tự gắn nhãn độ khó là đã đo.
- Không đổi schema v4, luật, campaign 24 màn, quyền mở R2–R4 hoặc triển khai generator/Endless trong đợt tài liệu.

## RST-006 — CanDoKu và tinh gọn GDD

Ngày 2026-09-28. Chủ dự án yêu cầu làm lại GDD, đổi tên thành **CanDoKu**, chủ đề tìm kẹo bị đánh rơi trong vườn, tham khảo Meowdoku; đồng thời cho phép xóa/tinh gọn tài liệu trong GDD không còn nhiệm vụ.

- GDD 0.6.0 dùng sơ đồ luống vườn và kẹo cố định để trình bày nền suy luận hàng/cột/vùng/không chạm. Level, asset, logo, câu chữ và layout phải là tác phẩm gốc.
- Giữ 24 level, phạm vi R1, ba tim, điểm, Hint, cử chỉ và schema hiện hành. Không tự mở R2–R4 hoặc Endless/meta.
- Thiết kế hình ảnh chuyển sang kẹo/giỏ/vườn 2D với hiệu ứng nhỏ; bỏ yêu cầu bắt buộc model/rig/clip nhân vật cũ và bộ sưu tập cũ. GDD 06 là hướng sản xuất mới; chưa phải asset hoặc client đã triển khai.
- **Đã được RST-008 thay thế:** giữ token kỹ thuật cũ, level/schema/save/hash; lớp UI dùng kẹo/tìm kẹo. Không đổi app identifier hoặc đường dẫn save trong đợt này.
- Bỏ GDD 08/11/12 cũ; bản gốc khôi phục được từ `b335b1891d1b9927e3b55f2ec8945dda252c779f`. Giữ fixture, validator và test vì vẫn phục vụ hợp đồng đang dùng. GDD 09 thay review lỗi thời bằng rà soát CanDoKu; ROADMAP giữ kế hoạch, STATUS giữ tiến độ.
- Đây là đợt tài liệu; chưa đổi code/game assets, chưa chứng nhận QA hoặc phát hành. Ngoại lệ replay kiểm thử RST-003 và tutorial RST-004 vẫn áp dụng.

## RST-005 — Pipeline gọn theo mục tiêu

Ngày 2026-09-27, chủ dự án yêu cầu rà soát/chỉnh kế hoạch rồi triển khai cải tổ pipeline. Chọn một agent chính, một plan khi cần, một STATUS hiện hành; tự thực hiện bước kỹ thuật đã giao, không thêm vòng duyệt/hồ sơ lặp từ workflow. Thay pipeline quản trị bằng `tools/verify.py`; kiểm tra liên quan trong vòng sửa và đầy đủ cuối chặng, giữ nguyên yêu cầu GUI/thiết bị.

Hồ sơ tracked cũ bảo toàn tại `pre-reset-pipeline-2026-09-27` (`8f2876d`) trước khi bỏ khỏi checkout; cách tra ở [HISTORY](HISTORY.md). Giữ nguyên file untracked và sửa sẵn của người dùng. Không thay luật/schema/phạm vi phát hành; không tự sửa cấu hình agent toàn máy. Quyết định này thay yêu cầu giữ hồ sơ cũ trong working tree của RST-001; không sửa trạng thái lịch sử.


## RST-003 — Cho phép replay campaign trong MVP

Ngày 2026-09-25. Chủ dự án xác nhận: sau khi hoàn thành level hiện có, bản MVP phải cho quay về Home và chơi lại từ L01 để kiểm chứng; bản chính thức sau này không cho replay từ L01.

- Home giữ nút chính hoạt động sau khi campaign hoàn tất và đổi nhãn thành `Chơi lại từ L01`.
- Kết quả L01–L03 giữ nút chính `Tiếp tục` để sang level kế tiếp. Chỉ sau khi thắng L04, nút chính trên Result đổi thành `Chơi lại từ L01` và mở lượt L01 mới trực tiếp; nút Home vẫn còn.
- Replay tạo session mới từ L01 nhưng không ghi đè `currentLevelId` hoàn thành hoặc danh sách level đã hoàn thành. Trong vòng replay, thắng L01–L03 vẫn tiếp tục tuần tự; chỉ kết quả L04 mới quay lại L01.
- Cờ `MVP_ALLOW_CAMPAIGN_REPLAY` trong bootstrap hiện bật để kiểm thử; trước bản chính thức phải tắt cờ và kiểm lại màn hoàn tất.
- Quyết định này chỉ mở đường kiểm chứng MVP, không thay đổi luật, save schema, phạm vi 24 level hoặc Endless.

## RST-004 — Bỏ ô sáng trong tutorial MVP

Ngày 2026-09-25. Chủ dự án chốt bỏ hoàn toàn viền sáng chỉ ô trên bàn tutorial.

- T1/T2 gọi rõ ô `(2,2)` bằng tọa độ hiển thị cho người chơi; T4 gọi rõ tọa độ kẹo suy ra từ level.
- Ô tutorial được chỉ định vẫn giữ cơ chế miễn phạt ở các bước áp dụng, nhưng không còn hiệu ứng sáng.
- Quyết định không đổi luật, save schema hoặc dữ liệu level.

## RST-002 — Duyệt cải tổ và mở R1

Ngày 2026-09-25. Chủ dự án xác nhận: giữ 24 level cho bản đầu, Endless để sau; tích hợp cải tổ về dev và kết thúc tạm ngưng để bắt đầu R1.

- Tích hợp nhánh refactor/project-reset vào dev bằng fast-forward sau kiểm chứng tài liệu.
- Triển khai R1 trên nhánh ngắn từ dev theo kế hoạch đã duyệt; một agent chính, không khởi động lại package cũ.
- Không thay luật, schema, tiêu chí QA hoặc loại iOS. Endless/meta/generator không thuộc bản đầu.
- RST-002 thay hiệu lực tạm ngưng của RST-001; nhận định lịch sử trong review vẫn giữ thời điểm khảo sát.

## RST-001 — Tạm ngưng, hợp nhất dev và cải tổ trên nhánh riêng

Ngày: 2026-09-24. Căn cứ: chủ dự án yêu cầu tạm ngưng công việc, gom code/nhánh về dev, cải tổ trên nhánh từ dev và xóa nhánh không cần thiết.

- Bảo toàn công việc tại dev `008f0d962d291ca6d5614f6613e8129b64673f41`. Nhánh `refactor/project-reset` dành cho cấu trúc, tổ chức, quy trình, rà thiết kế và kế hoạch.
- Tạm ngưng triển khai game/content/asset; không tự tiếp tục package cũ. Các state cũ giữ nguyên để bảo toàn lịch sử, không phải trạng thái điều hành hiện tại.
- Giao việc mới theo kết quả và phạm vi đã được giao, không bắt buộc ID package hay vòng start/verify/handoff/accept. Quy tắc hiện hành ở [AGENTS](../AGENTS.md).
- Kế hoạch cũ GDD 08 và quy định quy trình trong governance/work được thay thế bởi [ROADMAP](ROADMAP.md). Quyết định này chỉ có trên nhánh cải tổ cho đến khi tích hợp về dev.
- Các yêu cầu sản phẩm/QA của GDD vẫn giữ. Việc bỏ gate M0/M1 không tuyên bố QA thiết bị đã đạt và không giảm tiêu chí phát hành.
- Giữ main, dev và nhánh cải tổ; xóa tên các nhánh work đã được bảo toàn. Giữ stash và hồ sơ lịch sử; chưa cần xóa hoặc di chuyển hàng loạt tài liệu.

Những thay đổi luật, UX contract, schema và phạm vi sản phẩm sẽ được rà riêng trong R0. Chưa có quyết định thay đổi nào thuộc các phần này trong đợt hợp nhất nhánh.
