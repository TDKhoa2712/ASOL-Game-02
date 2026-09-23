# M0-A03 — Kết quả kiểm chứng mobile/rendering (đang chặn)

Ngày ghi nhận: 2026-09-24. Engine: Godot 4.7.2 stable, renderer `mobile` trong project. Mục tiêu Android do người giao việc cung cấp: **Xiaomi Redmi Note 13 Pro 5G, RAM 8 GB, lưu trữ 128 GB**. Phiên bản Android/HyperOS chưa được cung cấp. RAM 8 GB là cấu hình máy, **không phải ngân sách RAM/VRAM của game**.

## Ma trận thiết bị và host

| Mục | Android | iOS |
| --- | --- | --- |
| Thiết bị mục tiêu | Xiaomi Redmi Note 13 Pro 5G, 8/128 GB | CHƯA GÁN |
| OS/build | CHƯA XÁC NHẬN | CHƯA GÁN |
| Kết nối | Redmi thật chưa kết nối; `adb devices -l` chỉ thấy emulator | Không có iPhone/Mac/Xcode/signing trong host Windows hiện tại |
| Ngân sách RAM/VRAM/atlas/cache | CHƯA GÁN | CHƯA GÁN |
| Ngân sách cold load | TECH-13: <2 s sau startup; chưa đo | TECH-13: <2 s sau startup; chưa đo |
| Ngưỡng khung hình | TECH-19: ≥55 FPS, không stall >100 ms; chưa đo | TECH-19: ≥55 FPS, không stall >100 ms; chưa đo |

## Workload thử nghiệm đã dựng

- `game/scenes/mobile_rendering_spike.tscn`: bàn dọc 6×6, sáu nền/nhãn/họa tiết A–F, sáu hình mèo trên sáu vùng, nút thử mèo nhảy/sticker và cảnh báo X sai bằng chữ/dấu `!`. Hình mèo không bị tô theo vùng.
- `game/assets/spike/cat-probe-atlas.png`: atlas mẫu **512×128 RGBA**, bốn frame 128×128; file 2.422 byte, raw RGBA8 lý thuyết 262.144 byte (0,25 MiB) trước import/mipmap/buffer. Sáu `AtlasTexture` chia sẻ cùng một texture nguồn. Đây là hình thử tự tạo, không phải model/rig/clip sản xuất; kích thước file nén và phép tính raw không phải số VRAM đo thật.
- `game/tests/run_mobile_rendering_spike_smoke.gd`: PASS `M0_A03_RENDERING_SPIKE_PASS` trong Godot headless; kiểm kích thước/bounds logic, sáu nhãn, texture dùng chung, không tint mèo theo vùng và hai phản hồi.
- Ảnh `rendering-spike-desktop.png`: chụp bằng Godot Compatibility OpenGL trên NVIDIA GeForce RTX 4050 Laptop GPU, viewport logic 1080×1920. Ảnh xác nhận bố cục desktop của scene thử; không xác nhận safe area trên Redmi/iPhone.
- `game/tests/export_mobile_rendering_spike.py` tạm đổi main scene khi export riêng probe rồi khôi phục nguyên bytes `game/project.godot` trong `finally`. Bản APK probe chỉ dùng để kiểm trên emulator, không thay APK chính.
- Màn T01 và gesture contract M0-A02 vẫn là workload tương tác riêng. Scene này chỉ thử rendering, chưa nối action contract T01 vào bàn 6×6.

## Export và offline

| Kiểm tra | Quan sát |
| --- | --- |
| Android debug export | PASS bằng preset `Android M0 Debug`, ARM64, Godot 4.7.2; APK 28.324.252 byte tại `game/build/android/asol-game-02-debug.apk` (artifact local, không version-control). SHA-256 `ABDD7CAC2BC872BE0BAD2F2425BA0FD3AA2642EFD81F62D4E1DADB88BC3DABE6`. |
| Android manifest | `aapt2 dump permissions` liệt kê package `org.asol.game02` và không liệt kê quyền mạng. Đây là kiểm tra manifest, chưa phải chạy offline. `aapt2` cảnh báo thiếu resource themed icon của template, nhưng export exit 0. |
| Android install/run/offline trên Redmi | CHƯA ĐO: Redmi thật chưa kết nối. APK chính mở T01; APK probe riêng mở scene rendering. |
| iOS export/build/run/offline | CHƯA ĐO: Windows không có macOS/Xcode/signing và chưa gán iPhone. |

## Smoke test Android emulator (bằng chứng phụ)

- AVD `Pixel_8a`, Android 17 preview, x86_64 16 KB page image, 1080×2400, RAM emulator 4 GB; GPU ảo qua host NVIDIA. Đây **không phải** Redmi Note 13 Pro 5G hoặc iPhone.
- `adb shell svc wifi disable` và `svc data disable`; `dumpsys connectivity` báo `Active default network: none`; `settings get global wifi_on` và `mobile_data` đều là `0`.
- Cài APK chính bằng `adb install -r`: `Success`. `monkey -p org.asol.game02 1` mở app, PID `8399`; ảnh `emulator-offline-t01.png` cho thấy T01 hiển thị và không bị cắt. `adb shell input tap 230 940` làm X xuất hiện trong `emulator-offline-tap.png`.
- Cài APK probe bằng `adb install -r`: `Success`. Mở offline, PID `8872`; ảnh `emulator-offline-rendering-spike.png` cho thấy bàn 6×6, sáu vùng/nhãn/họa tiết và cùng mèo trên màn hình giả lập.
- Chạm nút thử mèo nhảy trên APK probe sau lần export cập nhật; `emulator-success-feedback.png` ghi được sticker “Hay lắm!” và pose nhảy. Smoke test xác nhận sticker tự ẩn sau 0,7 s. Chưa đo thời gian phản hồi thực hoặc frame stall.
- Đây là kiểm chứng tương thích/chạy offline ban đầu trên emulator. Không gán PASS QA-26/27/30/50 hoặc ngưỡng TECH-13/19/21 cho máy mục tiêu từ các ảnh và PID này.

## Số đo bắt buộc

| Metric | Redmi Note 13 Pro 5G | iPhone mục tiêu |
| --- | --- | --- |
| Cold load màn đầu sau startup, TECH-13 | CHƯA ĐO | CHƯA ĐO |
| FPS khi tương tác, TECH-19 | CHƯA ĐO | CHƯA ĐO |
| Frame stall khi mèo nhảy/sticker, TECH-19 | CHƯA ĐO | CHƯA ĐO |
| RAM peak / VRAM thực | CHƯA ĐO | CHƯA ĐO |
| Atlas load, first frame, cache | CHƯA ĐO | CHƯA ĐO |
| Safe area, cỡ chạm/đọc bàn 6×6, QA-27 | CHƯA KIỂM TRÊN MÁY | CHƯA KIỂM TRÊN MÁY |
| Offline play các level đầu, QA-26 | CHƯA KIỂM; project mới có T01 fixture | CHƯA KIỂM; project mới có T01 fixture |

## Ranh giới kết luận

Desktop smoke, screenshot và Android export xác nhận scene thử có thể nạp và đóng gói. **TECH-13/19/21 và QA-26/27/30/50 chưa đạt nghiệm thu** vì thiếu số đo trên thiết bị mục tiêu, atlas/clip đại diện sản xuất và môi trường iOS. Theo hợp đồng M0-A03, package phải giữ trạng thái `blocked` cho đến khi các bằng chứng đó được bổ sung.
