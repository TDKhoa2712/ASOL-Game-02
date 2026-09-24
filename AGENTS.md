# Hướng dẫn làm việc cho agent

Áp dụng trên nhánh cải tổ từ ngày 2026-09-24 theo yêu cầu của chủ dự án. Thay quy trình giao từng work package. Bản trước được bảo tồn tại commit `008f0d962d291ca6d5614f6613e8129b64673f41`.

## 1. Đọc và xác định phạm vi

- Đọc [trạng thái](docs/STATUS.md), [kế hoạch](docs/ROADMAP.md) và mục tiêu người dùng giao trước khi hành động.
- Hiện tạm ngưng triển khai game và package cũ. Chỉ thực hiện công việc cải tổ được giao; không tự chạy tiếp R1 hoặc các gói còn review/blocked.
- [GDD 02](GDD/02-luat-choi-va-trang-thai.md) giữ luật gameplay chuẩn; GDD sản phẩm và QA vẫn áp dụng. [Quyết định mới](docs/DECISIONS.md) xác định phần quy trình đã thay thế.
- Quy trình hiện hành nằm tại AGENTS; lịch thực hiện tại ROADMAP; tiến độ tại STATUS. Work package, state, handoff và kế hoạch M0–M3 là lịch sử, không cấp quyền làm việc mới.

## 2. Giao việc theo kết quả

- Người dùng giao mục tiêu/chặng; không bắt buộc mã package. Một agent chính chịu trách nhiệm khảo sát, triển khai, tích hợp, sửa regression và kiểm chứng trong mục tiêu đó.
- Tự chia bước kỹ thuật và sửa các file liên quan trực tiếp. Không bỏ lỗi liên quan chỉ vì file chưa được liệt kê trước.
- Không tự thêm mục tiêu, tính năng hoặc thay luật/schema/phạm vi phát hành. Các quyết định đó cần được người dùng giao hoặc chấp thuận và ghi vào DECISIONS; đồng bộ GDD, dữ liệu và test liên quan.
- Một luồng triển khai chính. Không tự tạo thêm agent hoặc worktree; chỉ dùng khi được yêu cầu hoặc có hướng dẫn áp dụng rõ ràng.
- Giữ nguyên thay đổi đang có của người dùng. Không xóa tài sản hay phát hành khi chưa được giao.

## 3. Nhánh và tích hợp

- `dev`: nền tích hợp chung. `main`: giữ mốc hiện có; không mặc định coi là bản phát hành đã nghiệm thu.
- `refactor/project-reset`: cải tổ cấu trúc tài liệu, tổ chức, thiết kế và kế hoạch. Không sửa gameplay trong giai đoạn tạm ngưng.
- Công việc sau này bắt đầu từ dev trên nhánh ngắn theo kết quả. Chỉ dọn nhánh khi commit đã được bảo toàn và worktree đã kiểm tra sạch.
- Không bắt buộc các lệnh start/inspect/verify/handoff/accept của pipeline cũ. Không sửa trạng thái lịch sử thành done để làm đẹp tiến độ.

## 4. Kiểm chứng theo thay đổi

- Tài liệu/quy trình: kiểm diff, liên kết, tính nhất quán và phạm vi; không yêu cầu chạy game để chứng minh sửa văn bản.
- Code: tái hiện vấn đề, chạy test liên quan trong lúc sửa; trước tích hợp chạy toàn bộ unit/contract test áp dụng, level validator và smoke luồng chính. Không bỏ test fail để lấy kết quả xanh.
- UI/input/điều hướng: chạy từ entry scene thật và quan sát thao tác/bố cục; headless không thay thế bằng chứng này.
- Ghi revision/build, lệnh, kết quả và giới hạn. Không dùng evidence cũ để tuyên bố build mới đạt. Thiếu thiết bị thì ghi chưa kiểm chứng và tiếp tục việc độc lập đã được giao.
- Bàn giao ngắn: kết quả người chơi nhận được, bằng chứng, lỗi còn chặn, bước kế tiếp. Không báo hoàn thành mục tiêu khi còn lỗi chặn mục tiêu.

## 5. Nội dung gốc

Asset, level, câu chữ và mã nguồn phải là tác phẩm gốc. Không sao chép tên thương mại, giao diện, âm thanh, nhân vật hoặc cấu trúc level từ Meowdoku hay game thương mại khác.
