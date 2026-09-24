# M0-A03 — Kết quả kiểm chứng mobile/rendering (đang chặn)

Ngày ghi nhận: 2026-09-24. Engine: Godot 4.7.2 stable, renderer `mobile` trong project. Mục tiêu Android do người giao việc cung cấp: **Xiaomi Redmi Note 13 Pro 5G, RAM 8 GB, lưu trữ 128 GB**. Phiên bản Android/HyperOS chưa được cung cấp. RAM 8 GB là cấu hình máy, **không phải ngân sách RAM/VRAM của game**.

## Ma trận thiết bị và host

| Mục | Android | iOS |
| --- | --- | --- |
| Thiết bị mục tiêu | Xiaomi Redmi Note 13 Pro 5G, 8/128 GB | CHƯA GÁN |
| OS/build | CHƯA XÁC NHẬN | CHƯA GÁN |
| Kết nối | Redmi thật chưa kết nối; người dùng không bật được chế độ nhà phát triển/ADB nhưng có thể cài APK thủ công và gửi ảnh | Không có iPhone/Mac/Xcode/signing trong host Windows hiện tại |
| Ngân sách RAM/VRAM/atlas/cache | CHƯA GÁN | CHƯA GÁN |
| Ngân sách cold load | TECH-13: <2 s sau startup; chưa đo | TECH-13: <2 s sau startup; chưa đo |
| Ngưỡng khung hình | TECH-19: ≥55 FPS, không stall >100 ms; chưa đo | TECH-19: ≥55 FPS, không stall >100 ms; chưa đo |

## Workload thử nghiệm đã dựng

- `game/scenes/mobile_rendering_spike.tscn`: bàn dọc 6×6, sáu nền/nhãn/họa tiết A–F, sáu hình mèo trên sáu vùng, nút thử mèo nhảy/sticker và cảnh báo X sai bằng chữ/dấu `!`. Hình mèo không bị tô theo vùng.
- `game/assets/spike/cat-probe-atlas.png`: atlas mẫu **512×128 RGBA**, bốn frame 128×128; file 2.422 byte, raw RGBA8 lý thuyết 262.144 byte (0,25 MiB) trước import/mipmap/buffer. Sáu `AtlasTexture` chia sẻ cùng một texture nguồn. Đây là hình thử tự tạo, không phải model/rig/clip sản xuất; kích thước file nén và phép tính raw không phải số VRAM đo thật.
- `game/tests/run_mobile_rendering_spike_smoke.gd`: PASS `M0_A03_RENDERING_SPIKE_PASS` trong Godot headless; kiểm kích thước/bounds logic, sáu nhãn, texture dùng chung, không tint mèo theo vùng và hai phản hồi.
- Ảnh `rendering-spike-desktop.png`: chụp bằng Godot Compatibility OpenGL trên NVIDIA GeForce RTX 4050 Laptop GPU, viewport logic 1080×1920. Ảnh xác nhận bố cục desktop của scene thử; không xác nhận safe area trên Redmi/iPhone.
- `game/tests/export_mobile_rendering_spike.py` tạm đổi main scene khi export riêng probe rồi khôi phục nguyên bytes `game/project.godot` trong `finally`. Bản APK probe dành cho emulator và thử thủ công trên Redmi; không thay APK chính.
- Bản probe có nút `Đo 20 giây`. Sau 2 giây làm nóng, `_process(delta)` đếm số khung, thời gian trung bình, khung chậm >100 ms và thời gian khung tệ nhất. Cứ 120 khung mẫu, probe kích hoạt phản hồi mèo nhảy/sticker. Kết quả hiển thị trên màn hình để chụp ảnh khi không có ADB. Bộ đếm này chỉ phản ánh workload probe và lịch gọi `_process`; nó không thay trace frame time/cold load của các level phát hành.
- `RAM Godot` và `video` trên màn hình lấy từ monitor `MEMORY_STATIC` và `RENDER_VIDEO_MEM_USED` của Godot. Đây là số engine báo cáo, không phải tổng RAM/VRAM của thiết bị; monitor không có số liệu sẽ hiện `không có dữ liệu`. Tham chiếu [Godot Performance monitors](https://docs.godotengine.org/en/4.7/classes/class_performance.html).
- Màn T01 và gesture contract M0-A02 vẫn là workload tương tác riêng. Scene này chỉ thử rendering, chưa nối action contract T01 vào bàn 6×6.

## Export và offline

| Kiểm tra | Quan sát |
| --- | --- |
| Android debug export | PASS bằng preset `Android M0 Debug`, ARM64, Godot 4.7.2; APK 28.324.252 byte tại `game/build/android/asol-game-02-debug.apk` (artifact local, không version-control). SHA-256 `ABDD7CAC2BC872BE0BAD2F2425BA0FD3AA2642EFD81F62D4E1DADB88BC3DABE6`. |
| Android manifest | `aapt2 dump permissions` liệt kê package `org.asol.game02` và không liệt kê quyền mạng. Đây là kiểm tra manifest, chưa phải chạy offline. `aapt2` cảnh báo thiếu resource themed icon của template, nhưng export exit 0. |
| Android install/run/offline trên Redmi | Người dùng đã cài/chạy APK probe trên Redmi Note 13 Pro 5G và báo ứng dụng vẫn chạy khi tắt Wi-Fi và dữ liệu di động. Có ảnh kết quả probe trên máy thật; chưa có ảnh trạng thái mạng/offline hoặc bài chơi các level phát hành. |
| iOS export/build/run/offline | CHƯA ĐO: Windows không có macOS/Xcode/signing và chưa gán iPhone. |

APK probe đo thủ công: `game/build/android/mobile-rendering-spike-debug.apk`, 28.324.252 byte, SHA-256 `7E227945112FEA59EE46E7C5915C6A801BA1AE3A4760EA54FA1F7605FFBEA424` (artifact local, không version-control). Lần export mới đã khôi phục `game/project.godot` về nội dung gốc.

## Smoke test Android emulator (bằng chứng phụ)

- AVD `Pixel_8a`, Android 17 preview, x86_64 16 KB page image, 1080×2400, RAM emulator 4 GB; GPU ảo qua host NVIDIA. Đây **không phải** Redmi Note 13 Pro 5G hoặc iPhone.
- `adb shell svc wifi disable` và `svc data disable`; `dumpsys connectivity` báo `Active default network: none`; `settings get global wifi_on` và `mobile_data` đều là `0`.
- Cài APK chính bằng `adb install -r`: `Success`. `monkey -p org.asol.game02 1` mở app, PID `8399`; ảnh `emulator-offline-t01.png` cho thấy T01 hiển thị và không bị cắt. `adb shell input tap 230 940` làm X xuất hiện trong `emulator-offline-tap.png`.
- Cài APK probe bằng `adb install -r`: `Success`. Mở offline, PID `8872`; ảnh `emulator-offline-rendering-spike.png` cho thấy bàn 6×6, sáu vùng/nhãn/họa tiết và cùng mèo trên màn hình giả lập.
- Chạm nút thử mèo nhảy trên APK probe sau lần export cập nhật; `emulator-success-feedback.png` ghi được sticker “Hay lắm!” và pose nhảy. Smoke test xác nhận sticker tự ẩn sau 0,7 s. Chưa đo thời gian phản hồi thực hoặc frame stall.
- Đây là kiểm chứng tương thích/chạy offline ban đầu trên emulator. Không gán PASS QA-26/27/30/50 hoặc ngưỡng TECH-13/19/21 cho máy mục tiêu từ các ảnh và PID này.
- Bản probe có nút đo đã cài bằng `adb install -r` (`Success`) và mở trên cùng AVD. [Ảnh trước đo](emulator-manual-measure-before.png) cho thấy nút và dòng hướng dẫn nằm trong màn hình. [Ảnh sau đo](emulator-manual-measure-result.png) hiện `Hoàn tất`: 56,4 FPS trung bình, khung tệ nhất 133,3 ms, 2 khung >100 ms, Godot static memory 39,7 MB và video memory 29,0 MB. Đây là kiểm tra đường thu thập/hiển thị trên emulator, không phải số đo Redmi hoặc iPhone. Số liệu còn cho thấy ngay workload mẫu này đã có stall trên emulator, nên không thể tuyên bố TECH-19 đạt.

## Quan sát trên Redmi Note 13 Pro 5G

- Người dùng cung cấp [ảnh kết quả đo 20 giây](redmi-note-13-pro-5g/két-qua-do-20-giay.jpg) từ APK probe trên Redmi Note 13 Pro 5G, 8/128 GB. File JPEG 280.302 byte, SHA-256 `FDA1DF06ECB24588F4F03E6C9E3D6C51D57A5F3C74FD44C491913100B510437A`. Ảnh cho thấy bàn A–F, nút và hai dòng kết quả đều hiển thị trong khung hình, không thấy bị cắt. Chưa biết phiên bản Android/HyperOS, chế độ tiết kiệm pin và tần số màn hình.
- Một lần đo hiện trên ảnh: **60,0 FPS trung bình; khung tệ nhất 16,7 ms; 0 khung >100 ms; Godot static memory 49,3 MB; video memory 48,9 MB**. Đây là số do probe tự báo cáo cho atlas mẫu và phản hồi thử, không phải profiler RAM/VRAM toàn máy hoặc workload sản xuất. Chưa có các lần lặp để đánh giá dao động.
- Người dùng báo ứng dụng vẫn chạy khi không có Wi-Fi và dữ liệu di động. Ghi nhận là **báo cáo thử thủ công**; ảnh kết quả không thể hiện trạng thái kết nối. Chưa có kiểm chứng offline các level đầu vì project hiện chỉ có T01 fixture.

## Số đo bắt buộc

| Metric | Redmi Note 13 Pro 5G | iPhone mục tiêu |
| --- | --- | --- |
| Cold load màn đầu sau startup, TECH-13 | CHƯA ĐO | CHƯA ĐO |
| FPS khi tương tác, TECH-19 | Probe mẫu: 60,0 FPS một lần đo; workload sản xuất CHƯA ĐO | CHƯA ĐO |
| Frame stall khi mèo nhảy/sticker, TECH-19 | Probe mẫu: tệ nhất 16,7 ms, 0 khung >100 ms; chưa có trace/lần lặp | CHƯA ĐO |
| RAM peak / VRAM thực | Monitor Godot: static 49,3 MB, video 48,9 MB; tổng RAM/VRAM thực CHƯA ĐO | CHƯA ĐO |
| Atlas load, first frame, cache | CHƯA ĐO | CHƯA ĐO |
| Safe area, cỡ chạm/đọc bàn 6×6, QA-27 | Ảnh Redmi cho thấy bàn/nút/kết quả không bị cắt; cỡ chạm và safe area theo OS CHƯA KIỂM ĐẦY ĐỦ | CHƯA KIỂM TRÊN MÁY |
| Offline play các level đầu, QA-26 | Người dùng báo APK probe chạy offline; level đầu CHƯA KIỂM, project mới có T01 fixture | CHƯA KIỂM; project mới có T01 fixture |

## Thử thủ công trên Redmi khi không có ADB

1. Chuyển `game/build/android/mobile-rendering-spike-debug.apk` sang Redmi Note 13 Pro 5G; mở file trên điện thoại và cho phép ứng dụng đang mở file cài ứng dụng nếu hệ thống hỏi. Đây là APK debug probe độc lập, mở thẳng bàn 6×6.
2. Mở APK, kiểm xem toàn bộ bàn A–F, nút và dòng kết quả có đọc được, không bị che/cắt; chụp một ảnh màn hình. Ghi phiên bản Android/HyperOS trong phần thông tin thiết bị.
3. Chạm `Đo 20 giây`, để màn hình sáng và không chuyển ứng dụng cho đến khi hiện `Hoàn tất`; chụp ảnh kết quả. Nên lặp lại ba lần sau khi đóng/mở app để thấy dao động. Gửi ảnh cùng thông tin có bật tiết kiệm pin/tần số màn hình nào không.
4. Tắt Wi-Fi và dữ liệu di động, mở lại APK, kiểm bàn hiện đầy đủ và chụp ảnh. Nếu bị hệ thống chặn cài hoặc mở, ghi nguyên văn thông báo.

Ảnh người dùng đã gửi là bằng chứng kiểm bố cục và số đo probe trên Redmi. Báo cáo offline là xác nhận thủ công từ người dùng. Chúng chưa xác nhận TECH-13 cold load, profiler RAM/VRAM chuẩn, gameplay của các level phát hành hoặc iOS.

## Ranh giới kết luận

Desktop smoke, Android export và ảnh Redmi xác nhận scene probe có thể nạp, đóng gói và hiển thị trên Android mục tiêu. **TECH-13/19/21 và QA-26/27/30/50 chưa đạt nghiệm thu đầy đủ** vì còn thiếu cold load, workload/asset đại diện sản xuất, các phép đo lặp/profiler và môi trường iOS. Theo hợp đồng M0-A03, package phải giữ trạng thái `blocked` cho đến khi các bằng chứng đó được bổ sung.
