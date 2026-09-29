# Trạng thái dự án

Cập nhật 2026-09-29. README đã viết lại, commit `745026e` và fast-forward vào `dev`; publish repository public `TDKhoa2712/CanDoKu` đang chờ chủ dự án xác thực GitHub. Code CanDoKu đã tích hợp local tại `93bc627` (RST-009). Mục tiêu sản phẩm tiếp theo vẫn là nghiệm thu R1; bản đầu 24 level, Endless để sau. Không mở R2–R4.

## README và publish repository — 2026-09-29

- Viết lại README: giới thiệu CanDoKu, luật/thao tác, phân biệt client bốn level với thiết kế 24 level, cách chạy/kiểm thử và hai tài liệu nền suy luận/sinh level. Không đổi code, asset hoặc luật.
- Chủ dự án chọn tài khoản `TDKhoa2712`, tên game hiện tại và public. Đích dự kiến `https://github.com/TDKhoa2712/CanDoKu`; chưa tạo/publish, local chưa có remote. Winget chờ tải đã dừng; MSI ký hợp lệ bởi GitHub tải được nhưng cài hệ thống lỗi 1603. Giải nén MSI vào `scratch/github-cli-msi/` thành công; CLI chưa có tài khoản đăng nhập. Đã khởi động device login và yêu cầu chủ dự án xác thực; không ghi token vào tài liệu.
- Kiểm trên nền `b99218d`, diff README/STATUS: `rtk git diff --check` PASS; PowerShell kiểm 14 liên kết README, không thiếu đích. README Git blob `2708f64b14298ab9f0d909418a03bc0bee173dfa`, được bảo toàn trong `745026e`. Quét lịch sử `dev` bằng `git log -G` không thấy mẫu GitHub token/private key; quét tên file `.env`, credentials, keystore/JKS/PEM không có kết quả. Đây là kiểm có giới hạn, không chứng nhận toàn bộ lịch sử không có thông tin nhạy cảm.
- Giữ các import có sẵn ngoài commit (bảy PNG ban đầu; ba SVG import xuất hiện thêm trong lúc làm được giữ nguyên). Lượt này chỉ sửa tài liệu, không chạy lại game/full suite (0 lượt); không có regression code mở lại hoặc hành trình GUI được kiểm thêm. Kết quả code tại `93bc627` ở mục bên dưới không phải chứng nhận R1 đã nghiệm thu. Thời gian chờ tập trung ở sandbox và chuẩn bị CLI/xác thực.

## Dọn và tích hợp CanDoKu — 2026-09-29

- Đã xóa 10 ảnh cũ và 10 import tương ứng sau kiểm không còn tham chiếu: atlas bitmap, bốn ảnh mèo/cá trên Board, avatar/logo Home và ba icon tiền/leaderboard/timer. Bản tracked khôi phục được từ revision nền. Xóa hai spec UI cũ theo trạng thái checkout người dùng; sửa chú thích trỏ tới spec đã bỏ. Bỏ các khối Home tiền/daily, avatar không có hành động, cấu hình leaderboard và theme JSON không có consumer. Giữ icon nút hiện hành, SVG, fixture, validator, migration và test.
- Trước tích hợp: **17/17 Godot suite, 8/8 Python game, 23/23 Python GDD, 7/7 runner, hai validator PASS**; [log](../scratch/verification/20260929T032029.887573Z.txt), exit 0, 8,80 giây, source SHA256 `a0b082fd8d53f4776a4d6cccd012d58b6cc2ff855339a68aef1182405014dffd`. Log ghi nền và diff thực tế; tài liệu trạng thái cập nhật sau kiểm, runtime không đổi.
- Capture GPU từ bootstrap với profile runtime riêng đã chạy lại Home/Settings/Puzzle/Win/Fail; đã xem Home sau dọn, không mất tên hoặc các nút hiện hành. Ảnh ở `scratch/candoku-ui/`. Gesture cửa sổ thật/Android/iOS chưa kiểm; giới hạn Computer Use như mục dưới. Không báo nghiệm thu R1.
- Bảy thay đổi import icon đang dùng của người dùng được giữ ngoài commit và mang theo checkout `dev`. Không push/phát hành.
- Sau merge trên `dev` tại `93bc627`: full runner **PASS**, exit 0, 8,05 giây; [log tích hợp](../scratch/verification/20260929T032353.149784Z.txt) ghi revision và working diff bảy import được giữ. 17 suite Godot, ba nhóm Python và hai validator đều PASS. Hai full run cho lượt dọn/tích hợp; không có regression mở lại. Thời gian chờ chủ yếu do shell sandbox lỗi khởi tạo và cấp quyền; không giảm QA. Cập nhật STATUS sau log chỉ là văn bản.

## CanDoKu — chuyển đồng bộ GDD và client (trước lượt dọn)

- RST-008: hợp đồng hiện hành dùng `candy`, `TryCandy`, `try_candy`, `CandyFound`, `sourceCandy`, `tutorialCandyCell`; đồng bộ solver, Hint, tutorial, vector và validator. Token cũ chỉ còn ở converter save v2/test compatibility, không có alias API cũ. Session v3 giữ tim, lỗi, Hint, thời gian, level/hash; đường dẫn profile Windows giữ nguyên. Level v4/progress v2 không đổi.
- App/export/Home dùng CanDoKu, hình kẹo/tim SVG gốc thay tài nguyên chủ đề cũ trong runtime/probe. Ảnh nguồn cũ và 11 sửa `.png.import` có sẵn được bảo toàn. Hai spec UI được tinh gọn theo GDD; công cụ báo cáo đọc GDD trực tiếp, kiểm cú pháp PASS, chưa tạo Word. Bỏ generator bitmap probe vì SVG là nguồn chỉnh trực tiếp; có thể khôi phục generator từ revision nền.
- **17/17 suite Godot, 8/8 Python game, 23/23 Python GDD, 7/7 Python runner, hai validator PASS.** Lệnh `rtk python -B tools/verify.py --godot <Godot 4.7.2>`; [log cuối](../scratch/verification/20260929T022900.292660Z.txt), exit 0, 7,78 giây. Revision nền như trên, source SHA256 `cd8db33aa16fd5cecade855d453eccc26854f8ef39b77dfeb0a198fce0fd6fb6`; log ghi working diff thực tế. Tài liệu bàn giao cập nhật sau log, runtime không đổi.
- Regression API/migration và tên Home đã thấy RED rồi GREEN. Ba full run: lượt đầu timeout do SVG probe chưa import; lượt hai lỗi so sánh Dictionary int/float trong test; lượt cuối PASS sau kiểm file bằng so sánh chuỗi byte chính xác. Probe riêng PASS sau import. Không bỏ test.
- Render Vulkan Mobile/GPU từ bootstrap thật với profile runtime cô lập: Home → Settings → Back → Puzzle → Settings → Back → Win → màn tiếp → Fail. Đã xem [Home](../scratch/candoku-ui/home.png), [Puzzle](../scratch/candoku-ui/puzzle.png), Settings và Result. Đây là capture harness phát signal/action, **không phải kiểm gesture bằng thao tác cửa sổ thật**. Computer Use lỗi `helper_unknown_error: setup refresh had errors`, reset/thử lại vẫn lỗi; không retry khi môi trường chưa đổi. Android/iOS NOT RUN.
- Tài liệu: 11 file GDD, 37 link cục bộ không thiếu đích, bảy khối JSON parse thành công; quét nguồn hiện hành không còn thuật ngữ cũ ngoài compatibility. `git diff --check` PASS. Các hash/số liệu bên dưới là lịch sử theo ngày, không dùng để chứng nhận build mới.

Chưa nghiệm thu R1 hoàn chỉnh hoặc phát hành: cần kiểm gesture thật và trọn hành trình bốn level. Campaign 24 màn, generator, rating engine và hiệu chỉnh độ khó vẫn chưa triển khai.

## Lịch sử: tài liệu nền suy luận và sinh level — 2026-09-28

- Đã mở rộng [GDD 10](../GDD/10-nghien-cuu-quy-tac-suy-luan.md) thành mô hình/rules/chứng minh/Hint đầy đủ hơn, gồm kỹ thuật nâng cao có ranh giới hỗ trợ rõ; thêm [GDD 11 mới](../GDD/11-sinh-level-va-danh-gia-do-kho.md) về profile/seed, tạo vùng/givens, uniqueness, trace, difficulty vector, rating thử nghiệm, chống trùng, playtest và mẫu giao AI tạo ứng viên. Xem RST-007.
- Kiểm tài liệu: `rtk git diff --check` exit 0; đọc lại và quét 36 liên kết cục bộ trong sáu tài liệu liên quan, không đích thiếu; parse ba khối JSON mẫu thành công. Kiểm độc lập bằng JavaScript duyệt hoán vị S301: đúng một nghiệm [1,3,0,2], không single ban đầu, một bước S3 và bốn S2 đều đúng, giải đủ bốn viên. Hai ví dụ rating cho kết quả 23 và 10 như văn bản.
- Fingerprint nội dung qua `rtk git hash-object GDD/10-nghien-cuu-quy-tac-suy-luan.md GDD/11-sinh-level-va-danh-gia-do-kho.md`: GDD 10 = `06172790896bc574785dcf25182efcfb9617080d`; GDD 11 = `4889f0ca4fb7fdeec96ff5a8e997fd0da78e0bd5`. File 11 mới chưa tracked; chưa commit/merge/push. Fingerprint ở mục GDD 0.6.0 bên dưới là bằng chứng vòng sửa trước, không dùng thay fingerprint mới.
- Giới hạn: chưa triển khai generator/rating engine/luật mở rộng, chưa sinh campaign hoặc hiệu chỉnh difficulty với người thật. Không sửa code/data/assets; giữ thay đổi có sẵn. Full suite 0 lượt, GUI/device NOT_RUN vì chỉ sửa tài liệu.

## Lịch sử: đợt tài liệu GDD CanDoKu 0.6.0

- Đã viết lại tầm nhìn, hướng hình ảnh kẹo/giỏ/vườn, thống nhất luật/UX/level/kỹ thuật/suy luận và bổ sung QA chuyển chủ đề, tương thích save. Xem [GDD](../GDD/README.md), [rà soát](../GDD/09-ra-soat-thiet-ke.md) và RST-006 trong [DECISIONS](DECISIONS.md).
- Đã bỏ GDD 08/11/12 không còn nhiệm vụ trong phạm vi hiện hành; giữ fixture/tools/test. Bản cũ bảo toàn trong revision nền, không xóa game assets.
- Chưa triển khai CanDoKu trong client; tên/asset mèo hiện có không là thiết kế đích. Không đổi token/schema/save hoặc dữ liệu campaign. Các mục lịch sử bên dưới giữ bằng chứng của revision cũ, không chứng nhận CanDoKu đã đạt runtime/GUI.
- Kiểm chứng tài liệu: `rtk git diff --check` exit 0; quét 39 liên kết cục bộ trong 12 tài liệu GDD/README/DECISIONS, không đích bị thiếu; rà tham chiếu cũ và phạm vi. Fingerprint diff GDD qua `rtk proxy git diff -- GDD | rtk git hash-object --stdin` là `1dcaade7321574e509214a39dfb8eb19224230c5` trên nền nêu trên. Thay đổi `.png.import` có sẵn ngoài phạm vi được giữ nguyên. Không chạy full suite (0 lượt) hoặc game vì chỉ sửa văn bản; GUI/thiết bị CanDoKu chưa kiểm. Shell có lỗi khởi tạo với một số lệnh; lệnh fingerprint chỉ đọc đã chạy qua quyền được cấp. Không commit/merge/push trong đợt này.

## Nền client trước CanDoKu — kết quả lịch sử

- Nhánh `codex/board-ui-restyle` đã tái cấu trúc `game/scripts/board_screen.gd`, `game/scripts/board_view.gd`, bổ sung `game/scripts/ui_tokens.gd`, sinh bộ placeholder assets tại `game/assets/ui/board/` và đồng bộ `game/tests/run_board_scene_smoke.gd`.
- Kiểm chứng trên nhánh `codex/board-ui-restyle`, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 7,97s; log tại `scratch/verification/20260928T144437.830205Z.txt`.
- Đã xuất ảnh chụp màn hình kiểm chứng tại `scratch/board_restyle_verify/` bao gồm:
  - `puzzle.png`: Bố cục ban đầu màn 1 (4x4).
  - `gameplay_active.png`: Trạng thái đang chơi (đặt mèo, đánh dấu X, nút hoàn tác kích hoạt, đầu mèo tiến độ sáng).
  - `board_6x6_l03.png`: Bố cục màn 3 (6x6) hiển thị 6 đầu mèo tiến độ và lưới 6x6.
  - `result_win.png` & `result_fail.png`: Các màn hình kết thúc.
- `dev` giữ mốc `2a9cc5a` đã tích hợp Home UI. `main` giữ mốc hiện có, không mặc định là bản phát hành.

## Làm sạch Git/project

Nhánh `codex/git-project-cleanup` có mốc code và ignore sạch tại `607d872` (`3047ef9` bảo toàn màu vùng F, `607d872` ignore thư mục đính kèm Codex). Đã xóa năm nhánh local cũ đã nằm trọn trong `dev`; giữ `dev`, `main` và nhánh cleanup hiện hành. `git fsck --no-dangling` không báo lỗi; repository không có remote nên không push.

Đã gỡ build Android/toolchain cũ, cache Godot/Python, thư mục đính kèm, hai config sai tên, bản nháp AGENTS lỗi mã hóa, ảnh nháp trùng, script dùng một lần và log verification cũ không còn cần; giải phóng khoảng 242 MB. Giữ `.codegraph/`, `.claude/settings.local.json`, ảnh UI cuối và các log đang được STATUS tham chiếu. Working tree không còn file tracked/untracked tồn đọng.

Kiểm chứng trên `607d872`, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 7,53 giây; [log](../scratch/verification/20260928T084349.521716Z.txt) ghi source SHA256 `0362557a397af1b26fe5ffac56e9157a9a0708f60f857a4b772cb231c2b8916f` và working tree sạch. Có hai full run (baseline và sau cleanup), không có regression mở lại, không có thời gian chờ; khoảng 10 phút từ khảo sát đến nghiệm thu. Không chạy GUI vì đợt này không đổi UI/input/điều hướng.

## Kết quả pipeline

Đã rút gọn AGENTS/README/CONTRIBUTING và thống nhất hướng dẫn trong AGENTS. Đã thay bộ quản trị cũ bằng `tools/verify.py`; gỡ hồ sơ tracked đã được tag bảo toàn, sửa link lịch sử. Không sửa gameplay hoặc cấu hình Codex toàn máy.

Kiểm chứng cải tổ ngày 2026-09-27, Godot `4.7.2.stable.official.ed1daf0bf`: **15/15 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 8,16 giây. [Bằng chứng pipeline](evidence/pipeline/2026-09-27-verification.txt) ghi revision `8f2876d` + diff cải tổ và sửa sẵn được nêu trong log. GUI/device: NOT RUN trong đợt pipeline.

Tự review phát hiện và sửa hai tình huống runner báo đạt sai (lỗi đọc metadata sau test, discovery có 0 test); regression đã thấy FAIL rồi PASS. Không giảm/bỏ suite. Tổng hai lượt full run; lượt thứ hai cần thiết sau sửa runner. Chưa có baseline thời gian làm/chờ pipeline cũ để tính mức tăng tốc. Ba mục tiêu tiếp theo đo thêm thời gian làm/chờ và regression mở lại theo AGENTS.

## R1 — đối chiếu việc kỹ thuật còn giá trị

Khảo sát cũ ở `1600898` được giữ trong tag; các dòng sau phân biệt bản sửa đã có với phần chưa nghiệm thu. [Nhật ký R1](plans/R1-progress.md) là bằng chứng lịch sử, không phải trạng thái hiện hành.

R1-E hiện tại, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run sau tích hợp trên `dev` 7,59 giây; [log](../scratch/verification/20260928T052302.150584Z.txt) ghi revision `a1e8a9f`, working diff và fingerprint nguồn. Regression `run_settings_tests.gd` đã tái hiện FAIL rồi PASS: store cô lập, signal toggle thật, persistence, Back route, chữ lớn và tương phản trên board. GUI desktop từ entry scene đã kiểm Home → Settings → Back, Home → Puzzle → Settings → Back, bật/tắt Large Text, chạm/đánh X và chạm lại/xóa X; chưa chạy trọn bốn level hoặc Android.

UI tham chiếu đầu tại `c1ebc9d`, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối sau fast-forward trên `dev` 7,80 giây; [log](../scratch/verification/20260928T082752.922347Z.txt) ghi revision `c1ebc9d`, source SHA256 `1d0c2c0fd5fb0a2e1f4f4cb9a6260eb671e9f040a9df9c5be620e36743864e7f` và working diff ngoài phạm vi được giữ nguyên. Regression UI đã thấy FAIL rồi PASS cho backdrop/thẻ Home, modal Settings, card layout Board và supporting copy trong HeroCard.

GUI desktop đã render bằng GPU từ entry scene thật ở viewport logic 1080×1920: Home → Settings → Back, Home → Puzzle → Settings → Back, sau đó Win/Fail trong capture harness. Đã quan sát Home có khoảng trắng, card nổi và nút bo tròn; Board giữ đủ luật/bảng/toolbar không cắt; Settings là modal kem có dimmer, năm toggle và Back hoạt động. Ảnh kiểm tại `scratch/ui-reference-style-final/`; chưa kiểm thiết bị Android, safe area có tai thỏ/thanh điều hướng thật hoặc toàn bộ bốn level.

Mục tiêu sau cải tổ #2: khoảng 20 phút từ regression RED đầu đến full run tích hợp; bốn full run do một regression HeroCard mở lại sau commit trung gian; không có thời gian chờ nội bộ. Nhánh task được fast-forward, không có merge commit; không push/phát hành.

Mục tiêu sau cải tổ #1: khoảng 5 phút từ patch regression đầu đến full run đầu; bốn full run tổng cộng (hai vòng implementation/self-review, một trước và một sau tích hợp); một regression được mở lại; không có thời gian chờ nội bộ, Android vẫn chờ thiết bị.

| Vấn đề cũ | Trạng thái và bước tiếp |
| --- | --- |
| Flow/runtime cùng giữ tiến trình; Win → Home → Play lệch level | R1 đã đưa tiến trình về runtime, integration PASS; còn kiểm hành trình bằng GUI/Android |
| Save lỗi IO nhưng vẫn thắng/xóa session | Có save-failure/recovery regression PASS; kiểm đóng/mở/background trên thiết bị |
| Resume trạng thái thua/cuối campaign | Có playable-flow PASS; replay từ L01 theo RST-003, không tự đổi luật hoàn thành |
| Tutorial chưa nối thao tác/target/miễn phạt | Integration PASS; thử gesture thật; RST-004 bỏ glow và gọi tọa độ |
| Help/Settings placeholder | Help đã có đường đi trong integration; Settings **(R1-E)** có store cô lập, năm toggle, persistence và Back route; Large Text/High Contrast áp dụng trên board, test và GUI desktop PASS. Audio/haptic/reduced motion và accessibility hoàn chỉnh thuộc R3 theo ROADMAP |
| Toolbar/Result bị cắt hoặc khó đọc | Board/UI smoke PASS; GUI desktop 433×798 với Large Text đã quan sát không chặn thao tác trong hành trình Settings/Puzzle. Chưa thay thế nghiệm thu trọn campaign hoặc thiết bị |
| Test dùng profile người chơi / lifecycle giả | Bootstrap-profile PASS; tiếp tục giữ profile cô lập |

## Blocker và phối hợp

| Việc / tác động | Người xử lý | Hành động tiếp và điều kiện thử lại |
| --- | --- | --- |
| Sandbox shell lỗi khởi tạo trong phiên này | Agent dùng cơ chế quyền hiện có; chủ dự án xử lý môi trường ứng dụng nếu cần | Lệnh ngoài sandbox đã chạy; không tiếp tục thăm dò cùng lỗi. Khi môi trường đổi mới kiểm lại sandbox. Lỗi GUI cũ chưa được kiểm lại trong đợt pipeline |
| R1 chưa có đủ hành trình GUI/gesture trên build được chốt | Agent | Đã kiểm Settings, Back route và tap/xóa X từ entry scene desktop; tiếp tục fresh → bốn level, Fail/Retry, Home/resume và cuối campaign trên revision bàn giao |
| Android QA chưa đủ; lần kiểm 2026-09-25 chưa có thiết bị ADB | Chủ dự án + agent | Chủ dự án kết nối/ủy quyền thiết bị hoặc nhận build để thử; agent chuẩn bị fresh/resume/Win/Fail/retry/cuối campaign, ghi model/OS/build/kết quả. Chỉ kiểm lại ADB khi thiết bị sẵn sàng |
| Chưa publish repo public `TDKhoa2712/CanDoKu`: chờ xác thực GitHub, local chưa có remote | Chủ dự án + agent | Chủ dự án hoàn tất device login bằng tài khoản TDKhoa2712; agent kiểm tài khoản rồi tạo repo/push dev khi đăng nhập thành công. Nếu mã hết hạn, tạo device login mới. Không tự push nhánh khác hoặc tạo release |
| Nguồn lực iOS và người thử R2 | Chủ dự án | Xác nhận iPhone/Mac/signing trước R4 và người thử trước R2; không chặn công việc R1 độc lập |

Bước tiếp theo: agent kiểm gesture thật và nghiệm thu hành trình R1 trên CanDoKu khi GUI/thiết bị sẵn sàng; chủ dự án phối hợp môi trường desktop/Android/iOS và remote. Chỉ thử lại Computer Use khi lỗi khởi tạo môi trường đã được xử lý. Không tuyên bố R1 hoàn thành hoặc đủ điều kiện phát hành từ headless và ảnh capture.
