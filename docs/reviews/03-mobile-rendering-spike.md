# Review 03 — Mobile rendering spike (M0-A03)

**Trạng thái:** PROVISIONAL / BLOCKED, 2026-09-24. Không dùng review này làm bằng chứng M0-GATE đã đạt.

## Câu hỏi cần trả lời

Một bộ sprite mèo mặc định dùng chung trên sáu vùng có giữ bàn đọc được, tải trong ngân sách và duy trì TECH-13/19/21 trên Android/iPhone mục tiêu không?

## Quan sát hiện có

Prototype Godot 4.7.2 dựng bàn 6×6 dọc với sáu nền, nhãn A–F và sáu họa tiết khác nhau. Sáu `Sprite2D` dùng các `AtlasTexture` cùng trỏ tới một texture mèo mẫu; vùng không đổi màu mèo. Cảnh báo sai có dấu `!` và chữ, sticker nằm ngoài bàn và tự tắt sau khoảng 0,7 giây. Smoke test headless qua, ảnh desktop đã được xem, Android debug APK export thành công. APK chính T01 và APK probe đều cài/chạy offline trên Android emulator; ảnh emulator ghi cả [bàn 6×6](../../work/evidence/M0-A03/emulator-offline-rendering-spike.png) và [phản hồi mèo nhảy](../../work/evidence/M0-A03/emulator-success-feedback.png). Xem [báo cáo số đo](../../work/evidence/M0-A03/mobile-performance-results.md) và [ảnh desktop](../../work/evidence/M0-A03/rendering-spike-desktop.png).

Các quan sát đó chứng minh bố cục và đường nạp resource của probe trên desktop/emulator. Atlas mẫu 512×128 không đại diện cho bộ sprite render từ model gốc; màn T01 hiện là fixture 4×4, chưa có các level phát hành đầu. Không thể suy ra chất lượng sprite cuối, VRAM thật trên Redmi/iPhone hoặc QA-26 cho các level phát hành từ ảnh/manifest/emulator.

## Đối chiếu tiêu chí

| Tiêu chí | Trạng thái | Điều kiện còn thiếu |
| --- | --- | --- |
| ART-01/02/03/13, QA-50 về vùng và một ngoại hình mèo | Probe desktop đạt cấu trúc; mobile chưa nghiệm thu | Kiểm bằng mắt trên máy, atlas/clip đại diện, VRAM và stall thực |
| ART-04/06..11 về feedback, sticker, giảm chuyển động | Chỉ có feedback mẫu | Clip/sprite sản xuất, reduced motion, đo tương tác và kiểm không che UI trên máy |
| ART-05/12 về nguồn và clip | Atlas mẫu có generator và manifest; bộ asset phát hành chưa có | Model/rig/clip gốc, manifest nguồn và quyền của bộ cuối |
| TECH-13, QA-26 | Chưa nghiệm thu | Chạy offline và đo cold load các level đầu trên Android/iPhone |
| TECH-19/21, QA-30/50 | Chưa nghiệm thu | Chọn ngân sách RAM/VRAM/atlas, đo FPS, stall, load và cache trên hai máy |
| QA-27 | Chưa nghiệm thu | Kiểm safe area, cỡ chữ, vùng chạm và bàn 6×6 trên thiết bị nhỏ |

## Quyết định hiện tại

Giữ pipeline sprite 2D dùng chung theo GDD. Chưa khóa kích thước atlas, frame rate, nén hoặc cache. Xiaomi Redmi Note 13 Pro 5G (8/128 GB) là ứng viên Android do người giao việc nêu; cần xác nhận OS và kết nối ADB. iPhone mục tiêu, Mac/Xcode/signing và ngân sách bộ nhớ vẫn thiếu. M0-A03 và M0-GATE không được chuyển `done` dựa trên desktop/headless hoặc Android export đơn lẻ.
