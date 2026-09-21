# Hướng dẫn cho coding agent

1. Đọc [GDD/README.md](GDD/README.md) trước khi triển khai. Luật chuẩn nằm ở [GDD/02-luat-choi-va-trang-thai.md](GDD/02-luat-choi-va-trang-thai.md); các gói việc nằm ở [GDD/08-ke-hoach-trien-khai-cho-agent.md](GDD/08-ke-hoach-trien-khai-cho-agent.md).
2. Đọc các phản biện và kiến nghị kỹ thuật tại [design-reviews/README.md](design-reviews/README.md) trước khi bắt đầu các gói việc.
3. Khi nhận gói việc, nêu mã yêu cầu GDD và mã QA sẽ đáp ứng. Dùng `GDD/data/levels.sample.json` làm fixture ban đầu.
3. Nếu đổi luật, schema dữ liệu hoặc tiến trình mở khóa, cập nhật GDD, dữ liệu mẫu và kiểm thử liên quan trong cùng thay đổi. Không tự thay đổi âm thầm.
4. Chạy `python GDD/tools/validate_levels.py GDD/data/levels.sample.json` sau khi sửa dữ liệu level. Level dùng S3–S5 cần mở rộng validator trace trước khi phát hành.
5. Tạo asset và level gốc; không sao chép tên thương mại, ảnh, âm thanh, giao diện hoặc level của Meowdoku.

@C:\Users\khoat\.codex\RTK.md
