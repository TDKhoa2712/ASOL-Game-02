# Trạng thái dự án

Cập nhật: 2026-09-25. **Chủ dự án đã mở R1 và duyệt tích hợp cải tổ vào dev. Bản đầu giữ 24 level, Endless để sau.** Không khởi động lại package cũ.

## Nền hiện tại

- `dev`: `f8c4933`, đã fast-forward toàn bộ cải tổ và quyết định mở R1. Mốc bảo toàn trước cải tổ là `008f0d962d291ca6d5614f6613e8129b64673f41`.
- Nhánh triển khai hiện tại: `fix/r1-playable-loop`, tách từ dev. `refactor/project-reset` giữ mốc cải tổ đã tích hợp.
- `main` giữ mốc cũ; không coi đây là bản phát hành đã nghiệm thu.
- Có client Godot và bốn level. Nhánh R1 đã nối các luồng bằng kiểm thử tích hợp headless, nhưng chưa có build được chứng nhận chơi liền mạch trên thiết bị.
- Không có remote được cấu hình. Hai stash cũ được giữ nguyên; file untracked trong đó trùng byte với nội dung đã lưu ở dev. Phần state M1-A07 trong stash là ảnh chụp cũ, không ghi đè trạng thái về sau.

## Công việc hiện tại

R0 đã tích hợp vào dev; R1 đang thực hiện trên `fix/r1-playable-loop`. Đã cô lập profile test, nối Home/Puzzle/Result và save/retry, nối tutorial với phiên chơi, sửa clipping toolbar, thêm bốn luật và tiến độ vùng. Ảnh render từ entry scene phát hiện và đã sửa chữ Result trắng trên nền sáng. Chi tiết tại [nhật ký R1](plans/R1-progress.md). Chưa tích hợp code R1 vào dev.

## Các vấn đề được chuyển từ hồ sơ cũ

| Vấn đề | Cách xử lý kế tiếp |
| --- | --- |
| Luồng chơi bốn level chưa được chứng minh liền mạch | Mục tiêu R1 đang được giao |
| Evidence A12 ghi smoke `Status label is clipped` còn fail | Đã sửa trên nhánh R1; smoke hiện PASS trên viewport logic 1080×1920, còn chờ quan sát GUI/thiết bị |
| Tutorial còn cần kiểm kết nối gesture/milestone thực tế | Integration T1–T6 và trường hợp miễn phạt đã PASS headless; thử người mới ở R2 |
| Thiếu kiểm thử thiết bị/asset đại diện và nguồn lực iOS | Lập danh sách người/thiết bị trong R0; giữ QA nền tảng ở R4 |
| Phạm vi sản phẩm | Đã chốt 24 level bản đầu, Endless để sau theo RST-002 |

## Kiểm chứng và bước tiếp theo

Ngày 2026-09-25, trên nhánh R1: 15/15 bộ Godot PASS; 8/8 Python game và 23/23 GDD PASS; validator corpus bốn level và sample năm fixture PASS; `git diff --check` PASS. Lần đầu Python game suite lỗi do chưa đặt `GODOT_BIN`, sau đó chạy lại với Godot 4.7.2 và PASS. Bằng chứng/lệnh tại [nhật ký R1](plans/R1-progress.md).

Đã soạn [rà thiết kế và cấu trúc đích](reviews/05-design-and-structure-review.md) và [kế hoạch nghiệm thu R1](plans/R1-playable-loop.md), dựa trên khảo sát tĩnh tại `1600898`. R1-A đã cô lập profile và thay test gọi `_ready()` thủ công bằng scene tree thực.

Bước tiếp theo: thao tác tay từ entry scene GUI thật, kiểm chữ lớn/grayscale/reduced motion và Settings không còn placeholder, rồi QA Android offline. Đã quan sát bốn ảnh render Home/Puzzle/Win/Fail trên Windows; công cụ điều khiển Windows của phiên này lỗi khởi tạo nên chưa kiểm gesture trực tiếp. ADB có nhưng không có thiết bị kết nối. Chưa tuyên bố R1 hoàn thành hay đủ điều kiện phát hành.
