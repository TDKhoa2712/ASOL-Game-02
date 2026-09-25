# Trạng thái dự án

Cập nhật: 2026-09-25. **Chủ dự án đã mở R1 và duyệt tích hợp cải tổ vào dev. Bản đầu giữ 24 level, Endless để sau.** Không khởi động lại package cũ.

## Nền hiện tại

- `dev`: `008f0d962d291ca6d5614f6613e8129b64673f41`, chứa toàn bộ lịch sử các nhánh công việc và file đang làm được bảo toàn.
- Nhánh cải tổ: `refactor/project-reset`; được duyệt fast-forward về dev theo RST-002. Mốc `008f0d9` ở trên là mốc bảo toàn trước cải tổ, không phải HEAD sau tích hợp.
- `main` giữ mốc cũ; không coi đây là bản phát hành đã nghiệm thu.
- Có client Godot và bốn level; chủ dự án xác nhận còn rời rạc và chưa ổn định. Không có build được chứng nhận chơi liền mạch trong đợt này.
- Không có remote được cấu hình. Hai stash cũ được giữ nguyên; file untracked trong đó trùng byte với nội dung đã lưu ở dev. Phần state M1-A07 trong stash là ảnh chụp cũ, không ghi đè trạng thái về sau.

## Công việc hiện tại

R0 đã được chủ dự án duyệt; tiến hành tích hợp và mở R1, bắt đầu bằng cô lập save test trước kiểm thử tích hợp. Chi tiết bảo toàn nhánh tại [biên bản hợp nhất](BRANCH-CONSOLIDATION.md).

## Các vấn đề được chuyển từ hồ sơ cũ

| Vấn đề | Cách xử lý kế tiếp |
| --- | --- |
| Luồng chơi bốn level chưa được chứng minh liền mạch | Mục tiêu R1 đang được giao |
| Evidence A12 ghi smoke `Status label is clipped` còn fail | Tái hiện cùng các lỗi UI/input trong R1; chưa sửa trong đợt này |
| Tutorial còn cần kiểm kết nối gesture/milestone thực tế | Kiểm tích hợp ở R1, người mới ở R2 |
| Thiếu kiểm thử thiết bị/asset đại diện và nguồn lực iOS | Lập danh sách người/thiết bị trong R0; giữ QA nền tảng ở R4 |
| Phạm vi sản phẩm | Đã chốt 24 level bản đầu, Endless để sau theo RST-002 |

## Kiểm chứng và bước tiếp theo

Đợt này kiểm Git, bảo toàn file, diff tài liệu, đăng ký tài liệu và liên kết. Không chạy lại game, không kết luận gameplay đã ổn định từ thao tác gom nhánh.

Đã soạn [rà thiết kế và cấu trúc đích](reviews/05-design-and-structure-review.md) và [kế hoạch nghiệm thu R1](plans/R1-playable-loop.md), dựa trên khảo sát tĩnh tại `1600898`. Chưa chạy kiểm chứng gameplay mới.

Bước tiếp theo: R1-A, cô lập save test và kiểm baseline an toàn; sau đó thống nhất tiến trình và save/resume. Chưa có bằng chứng đạt R1 hoặc đủ điều kiện phát hành.
