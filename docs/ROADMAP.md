# Kế hoạch thực hiện mới

Kế hoạch theo kết quả sản phẩm, thay thứ tự package/gate M0–M3. Trạng thái chỉ duy trì tại [STATUS](STATUS.md); quyền thực hiện theo [AGENTS](../AGENTS.md). Đề xuất nền được lưu tại [tag lịch sử](HISTORY.md).

## R0 — Cải tổ trước khi tiếp tục phát triển

1. Gom công việc hiện có về dev và bảo toàn file/stash/lịch sử; chỉ xóa nhánh đã hợp nhất.
2. Thực hiện mọi thay đổi cải tổ trên `refactor/project-reset`. Dừng nhận việc theo package cũ; dùng một mục tiêu hiện tại và một bước kế tiếp.
3. Rà thiết kế sản phẩm, UX, kiến trúc và nội dung: phân biệt quyết định đang áp dụng, đề xuất cần chủ dự án quyết định và nghiên cứu để sau. Không tự thay luật/điểm/schema hoặc bỏ iOS.
4. Chốt cấu trúc đích dựa trên nhu cầu thực tế. Trước mắt giữ code/data/assets và đường dẫn evidence; tài liệu vận hành gồm AGENTS, README, ROADMAP, STATUS, DECISIONS. Không di chuyển hàng loạt để làm đẹp cây thư mục.
5. Lập kế hoạch chi tiết R1 sau khi khảo sát, với luồng nghiệm thu, rủi ro và bộ kiểm tra; chuẩn bị danh sách nguồn lực Android/iOS và người chơi thử.
6. Review thay đổi tổ chức và thiết kế, tích hợp về dev khi được giao. Chỉ tiếp tục triển khai game sau khi chủ dự án kết thúc tạm ngưng.

R0 hoàn thành khi có một nguồn hướng dẫn thống nhất, thiết kế/phạm vi đã rõ, kế hoạch R1 có thể thực thi và điểm còn chờ người quyết định được nêu cụ thể. Gom nhánh không đồng nghĩa R0 đã hoàn tất toàn bộ.

## R1 — Một bản chơi liền mạch bốn level

Chi tiết: [kế hoạch R1](plans/R1-playable-loop.md), căn cứ kiến trúc trong kế hoạch R1 và [khảo sát lịch sử](HISTORY.md). Thứ tự: cô lập test → thống nhất tiến trình → bảo toàn save → nối tutorial/input → kiểm layout và hành trình thật. Đã được mở theo RST-002; hiện tập trung nghiệm thu các phần còn thiếu trong STATUS.

Hoàn thiện xuyên scene/controller/runtime: Home → Puzzle → Win/Fail → Next/Retry/Home; save/resume, tutorial, Hint, Undo, Restart đúng luật trên cùng build. Sửa lỗi input, chuyển scene và bố cục chặn thao tác trong cùng mục tiêu.

Nghiệm thu từ entry scene thật: lượt mới qua bốn level; thua/retry; đóng/mở giữa level; quay Home/resume; kết thúc level cuối. Chạy unit/contract, validator, kiểm hình ảnh/thao tác và Android thực tế. Ghi riêng phạm vi đã kiểm, không lấy test module thay bằng chứng trải nghiệm.

## R2 — Người mới tự hiểu và chơi được

Thử sớm với 3–5 người để tìm lỗi hiểu thao tác, sau đó nghiệm thu theo GDD: ít nhất 8/10 người mới hoàn thành hướng dẫn và hiểu X đỏ. Sửa input/tutorial/feedback theo bằng chứng; thay luật nếu cần phải có quyết định riêng.

## R3 — Nội dung và hình thức bản đầu

24 level gốc, order 1–18 S1/S2, 19–24 cần S3; nghiệm duy nhất, trace hợp lệ, lượt giải không xem đáp án. Tích hợp nội dung theo nhóm nhỏ vào campaign. Chốt asset đại diện và đo trước khi sản xuất hàng loạt; hoàn thiện Help/Settings, audio, reduced motion và accessibility theo GDD.

## R4 — Build đủ điều kiện phát hành

QA trên Android/iOS với asset/workload đại diện: offline, tải, frame time, bộ nhớ, safe area, accessibility, vòng đời app và bảo toàn save. Không còn crash, mất tiến trình, sai luật hoặc chặn campaign. Chủ dự án quyết định phát hành. Thiếu iOS phải ghi bị chặn; Android-first cần quyết định phạm vi riêng.

## Nhịp làm việc

Một kết quả chính đang làm; agent tự chia bước và tích hợp đến cùng trong quyền đã giao. Báo cáo build/revision, hành vi đã đạt, bằng chứng, lỗi chặn và bước kế tiếp. Đo thời gian tới build chơi được, thời gian chờ, regression sau tích hợp và hành trình đã kiểm. Chưa hứa lịch ngày cho cả dự án khi chưa có baseline R1 và lịch thiết bị/người chơi.

## Vận hành agent sau cải tổ 2026-09-27

Áp dụng [AGENTS](../AGENTS.md). Pipeline là công cụ hỗ trợ R1, không là chặng sản phẩm mới. Chỉ yêu cầu người dùng xử lý quyết định/thiết bị/quyền truy cập còn thiếu; tiếp tục phần độc lập trong quyền đã giao.
