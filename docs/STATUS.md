# Trạng thái dự án

Cập nhật: 2026-09-25. **Chủ dự án đã mở R1 và duyệt tích hợp cải tổ vào dev. Bản đầu giữ 24 level, Endless để sau.** Không khởi động lại package cũ.

## Nền hiện tại

- `dev`: `f8c4933`, đã fast-forward toàn bộ cải tổ và quyết định mở R1. Mốc bảo toàn trước cải tổ là `008f0d962d291ca6d5614f6613e8129b64673f41`.
- Nhánh triển khai hiện tại: `fix/r1-playable-loop`, tách từ dev. `refactor/project-reset` giữ mốc cải tổ đã tích hợp.
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

Đợt cải tổ chỉ kiểm tài liệu/Git. Khi mở R1 đã chạy baseline mới: 8/8 test Python game, 23/23 test GDD, hai validator đều đạt; 11/12 bộ Godot đạt. `run_board_scene_smoke` còn FAIL `Status label is clipped`. Chi tiết lệnh và giới hạn tại [nhật ký R1](plans/R1-progress.md).

Đã soạn [rà thiết kế và cấu trúc đích](reviews/05-design-and-structure-review.md) và [kế hoạch nghiệm thu R1](plans/R1-playable-loop.md), dựa trên khảo sát tĩnh tại `1600898`. R1-A đã cô lập profile và thay test gọi `_ready()` thủ công bằng scene tree thực.

Bước tiếp theo: R1-B thống nhất tiến trình, sau đó save/resume, tutorial và layout. Chưa có bằng chứng đạt R1, QA Android thật hoặc đủ điều kiện phát hành.
