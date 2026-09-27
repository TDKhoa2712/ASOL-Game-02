# Trạng thái dự án

Cập nhật 2026-09-27. Mục tiêu phiên này: cải tổ pipeline theo yêu cầu chủ dự án. Mục tiêu sản phẩm kế tiếp vẫn là nghiệm thu R1; bản đầu 24 level, Endless để sau. Không mở R2–R4.

## Nền hiện tại

- `dev` tại `8f2876d` đã có code R1 bốn level; ghi chú trước đây nói chưa tích hợp là lỗi thời. Việc có code trên dev không đồng nghĩa R1 đã nghiệm thu.
- Cải tổ nằm trên `codex/pipeline-cleanup`, từ cùng revision. Tag `pre-reset-pipeline-2026-09-27` bảo toàn hồ sơ đã commit. [Cách tra lịch sử](HISTORY.md).
- Có sửa sẵn chưa commit ở `game/scripts/board_view.gd`, hai config lạc tên, `project.xml` và bản nháp `refactor/AGENTS.md`; giữ nguyên, không đưa vào commit cải tổ. Test dưới đây chạy trên workspace gồm sửa sẵn đó, không chứng nhận riêng một checkout sạch tại HEAD.
- `main` giữ mốc hiện có, không mặc định là bản phát hành. Không thay stash/remote hoặc tích hợp nhánh trong đợt này.

## Kết quả pipeline

Rút gọn AGENTS/README/CONTRIBUTING; thống nhất hướng dẫn và phân công trong [kế hoạch](../refactor/pipeline-cleanup-plan.md). Thay bộ quản trị cũ bằng `tools/verify.py`; gỡ hồ sơ tracked đã được tag bảo toàn, sửa link lịch sử. Không sửa gameplay hoặc cấu hình Codex toàn máy.

Kiểm chứng mới ngày 2026-09-27, Godot `4.7.2.stable.official.ed1daf0bf`: **15/15 suite Godot, 8/8 Python game, 23/23 GDD, 7/7 runner PASS; hai validator PASS**. Full run cuối 8,16 giây. [Log đầy đủ](evidence/pipeline/2026-09-27-verification.txt) ghi revision `8f2876d` + working diff, version, fingerprint, từng lệnh/exit/duration. GUI/device: NOT RUN trong đợt pipeline.

Tự review phát hiện và sửa hai tình huống runner báo đạt sai (lỗi đọc metadata sau test, discovery có 0 test); regression đã thấy FAIL rồi PASS. Không giảm/bỏ suite. Tổng hai lượt full run; lượt thứ hai cần thiết sau sửa runner. Chưa có baseline thời gian làm/chờ pipeline cũ để tính mức tăng tốc. Ba mục tiêu tiếp theo đo thêm thời gian làm/chờ và regression mở lại theo AGENTS.

## R1 — đối chiếu việc kỹ thuật còn giá trị

Khảo sát cũ ở `1600898` được giữ trong tag; các dòng sau phân biệt bản sửa đã có với phần chưa nghiệm thu. [Nhật ký R1](plans/R1-progress.md) là bằng chứng lịch sử, không phải trạng thái hiện hành.

| Vấn đề cũ | Trạng thái và bước tiếp |
| --- | --- |
| Flow/runtime cùng giữ tiến trình; Win → Home → Play lệch level | R1 đã đưa tiến trình về runtime, integration PASS; còn kiểm hành trình bằng GUI/Android |
| Save lỗi IO nhưng vẫn thắng/xóa session | Có save-failure/recovery regression PASS; kiểm đóng/mở/background trên thiết bị |
| Resume trạng thái thua/cuối campaign | Có playable-flow PASS; replay từ L01 theo RST-003, không tự đổi luật hoàn thành |
| Tutorial chưa nối thao tác/target/miễn phạt | Integration PASS; thử gesture thật; RST-004 bỏ glow và gọi tọa độ |
| Help/Settings placeholder | Help đã có đường đi trong integration; Settings và accessibility vẫn cần hoàn thiện/kiểm ở R1-E, output audio/haptic ở R3 |
| Toolbar/Result bị cắt hoặc khó đọc | Board/UI smoke PASS hiện tại; ảnh render cũ đã xem, chưa thay thế GUI/thiết bị bản mới |
| Test dùng profile người chơi / lifecycle giả | Bootstrap-profile PASS; tiếp tục giữ profile cô lập |

## Blocker và phối hợp

| Việc / tác động | Người xử lý | Hành động tiếp và điều kiện thử lại |
| --- | --- | --- |
| Sandbox shell lỗi khởi tạo trong phiên này | Agent dùng cơ chế quyền hiện có; chủ dự án xử lý môi trường ứng dụng nếu cần | Lệnh ngoài sandbox đã chạy; không tiếp tục thăm dò cùng lỗi. Khi môi trường đổi mới kiểm lại sandbox. Lỗi GUI cũ chưa được kiểm lại trong đợt pipeline |
| R1 chưa có thao tác GUI/gesture trên build được chốt | Agent | Chốt Settings/accessibility còn thiếu, chạy entry scene với profile riêng, ghi hành trình và revision; nếu công cụ GUI lỗi thì giao kịch bản thao tác cụ thể cho chủ dự án |
| Android QA chưa đủ; lần kiểm 2026-09-25 chưa có thiết bị ADB | Chủ dự án + agent | Chủ dự án kết nối/ủy quyền thiết bị hoặc nhận build để thử; agent chuẩn bị fresh/resume/Win/Fail/retry/cuối campaign, ghi model/OS/build/kết quả. Chỉ kiểm lại ADB khi thiết bị sẵn sàng |
| Nguồn lực iOS và người thử R2 | Chủ dự án | Xác nhận iPhone/Mac/signing trước R4 và người thử trước R2; không chặn công việc R1 độc lập |

Bước tiếp theo: rà diff cải tổ để tích hợp vào dev khi được giao; sau đó tiếp tục phần R1-E còn thiếu theo [kế hoạch R1](plans/R1-playable-loop.md). Không tuyên bố R1 hoàn thành hay đủ điều kiện phát hành.
