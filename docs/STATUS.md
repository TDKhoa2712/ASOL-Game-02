# Trạng thái dự án

Cập nhật 2026-09-28. Mục tiêu phiên này: tích hợp thiết kế giao diện Home theo HOME_UI_Redesign_Spec.md (phong cách Meow Doku) với bộ asset placeholder, ui_tokens, side-rail và cấu hình mở. Mục tiêu sản phẩm vẫn là nghiệm thu R1; bản đầu 24 level, Endless để sau. Không mở R2–R4.

## Nền hiện tại

- `dev` tại `2a9cc5a` đã tích hợp giao diện Home tái cấu trúc, bộ asset placeholder `res://assets/ui/home/`, tokens `ui_tokens.gd`, cấu hình `home_ui_config.json` và đặc tả `HOME_UI_Redesign_Spec.md`.
- Giao diện Home đã fast-forward từ `codex/home-ui-refinement` vào `dev` qua bốn commit (`f3f31c7`, `ca6f33c`, `8072a31`, `2a9cc5a`).
- Kiểm chứng trên `2a9cc5a`, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 11,44s; log tại `scratch/verification/20260928T141002.059730Z.txt`.
- Đã xuất ảnh chụp màn hình kiểm chứng tại `scratch/home_spec_verify/home.png` (bản mặc định) và `scratch/home_spec_all/home.png` (bản bật đầy đủ tính năng).
- Cải tổ đã được tích hợp từ `codex/pipeline-cleanup` vào dev. Tag `pre-reset-pipeline-2026-09-27` bảo toàn hồ sơ đã commit. [Cách tra lịch sử](HISTORY.md).
- `main` giữ mốc hiện có, không mặc định là bản phát hành. Không thay stash/remote hoặc tích hợp nhánh trong đợt này.

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
| Không thể push `dev`: repository chưa cấu hình Git remote và không có URL trong tài liệu | Chủ dự án | Cung cấp URL remote (và tên nếu không dùng `origin`); agent cấu hình rồi push `dev` và nhánh R1-E. Thử lại khi có endpoint |
| Nguồn lực iOS và người thử R2 | Chủ dự án | Xác nhận iPhone/Mac/signing trước R4 và người thử trước R2; không chặn công việc R1 độc lập |

Bước tiếp theo: chủ dự án duyệt trực quan bản UI đầu và yêu cầu vòng chỉnh tiếp; song song vẫn cần cấu hình remote để push `dev`, nghiệm thu trọn hành trình desktop và Android theo [kế hoạch R1](plans/R1-playable-loop.md). Không tuyên bố R1 hoàn thành hay đủ điều kiện phát hành.
