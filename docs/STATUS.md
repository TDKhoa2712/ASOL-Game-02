# Trạng thái dự án

Cập nhật 2026-09-28. Mục tiêu phiên này: hoàn thiện R1-E Settings/accessibility cơ bản sau khi cải tổ pipeline đã được tích hợp vào dev. Mục tiêu sản phẩm vẫn là nghiệm thu R1; bản đầu 24 level, Endless để sau. Không mở R2–R4.

## Nền hiện tại

- `dev` tại `501c797` đã có code R1 bốn level và đã tích hợp cải tổ pipeline.
- Cải tổ đã được tích hợp từ `codex/pipeline-cleanup` vào dev. Tag `pre-reset-pipeline-2026-09-27` bảo toàn hồ sơ đã commit. [Cách tra lịch sử](HISTORY.md).
- R1-E đang ở nhánh `codex/r1-e-settings`, nền `501c797`. Có sửa sẵn ngoài phạm vi ở `game/scripts/board_view.gd`, hai config lạc tên và bản nháp `refactor/AGENTS.md`; giữ nguyên, không đưa vào commit R1-E. Test dưới đây chạy trên workspace gồm sửa sẵn đó.
- `main` giữ mốc hiện có, không mặc định là bản phát hành. Không thay stash/remote hoặc tích hợp nhánh trong đợt này.

## Kết quả pipeline

Đã rút gọn AGENTS/README/CONTRIBUTING; thống nhất hướng dẫn và phân công trong [kế hoạch](../refactor/pipeline-cleanup-plan.md). Đã thay bộ quản trị cũ bằng `tools/verify.py`; gỡ hồ sơ tracked đã được tag bảo toàn, sửa link lịch sử. Không sửa gameplay hoặc cấu hình Codex toàn máy.

Kiểm chứng cải tổ ngày 2026-09-27, Godot `4.7.2.stable.official.ed1daf0bf`: **15/15 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 8,16 giây. [Bằng chứng pipeline](evidence/pipeline/2026-09-27-verification.txt) ghi revision `8f2876d` + diff cải tổ và sửa sẵn được nêu trong log. GUI/device: NOT RUN trong đợt pipeline.

Tự review phát hiện và sửa hai tình huống runner báo đạt sai (lỗi đọc metadata sau test, discovery có 0 test); regression đã thấy FAIL rồi PASS. Không giảm/bỏ suite. Tổng hai lượt full run; lượt thứ hai cần thiết sau sửa runner. Chưa có baseline thời gian làm/chờ pipeline cũ để tính mức tăng tốc. Ba mục tiêu tiếp theo đo thêm thời gian làm/chờ và regression mở lại theo AGENTS.

## R1 — đối chiếu việc kỹ thuật còn giá trị

Khảo sát cũ ở `1600898` được giữ trong tag; các dòng sau phân biệt bản sửa đã có với phần chưa nghiệm thu. [Nhật ký R1](plans/R1-progress.md) là bằng chứng lịch sử, không phải trạng thái hiện hành.

R1-E hiện tại, Godot `4.7.2.stable.official.ed1daf0bf`: **16/16 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 8,31 giây; [log](../scratch/verification/20260928T051618.801160Z.txt) ghi revision nền `501c797`, nhánh, working diff và fingerprint nguồn. Regression `run_settings_tests.gd` đã tái hiện FAIL rồi PASS: store cô lập, signal toggle thật, persistence, Back route, chữ lớn và tương phản trên board. GUI desktop từ entry scene đã kiểm Home → Settings → Back, Home → Puzzle → Settings → Back, bật/tắt Large Text, chạm/đánh X và chạm lại/xóa X; chưa chạy trọn bốn level hoặc Android.

Mục tiêu sau cải tổ #1: khoảng 5 phút từ patch regression đầu đến full run đầu; hai full run do self-review phát hiện thêm IO profile ở BoardScreen; một regression được mở lại; không có thời gian chờ nội bộ, Android vẫn chờ thiết bị.

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
| Nguồn lực iOS và người thử R2 | Chủ dự án | Xác nhận iPhone/Mac/signing trước R4 và người thử trước R2; không chặn công việc R1 độc lập |

Bước tiếp theo: bàn giao R1-E trên nhánh ngắn, sau đó nghiệm thu trọn hành trình desktop và Android theo [kế hoạch R1](plans/R1-playable-loop.md). Không tuyên bố R1 hoàn thành hay đủ điều kiện phát hành.
