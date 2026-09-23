# M0-A03 — Thiết kế và kế hoạch thử rendering

## Mục đích

Đo một workload 2D gần với màn puzzle trên Android và iPhone mục tiêu: bàn 6×6, sáu vùng có màu/nhãn/họa tiết, một bộ hình mèo dùng chung, động tác nhảy và sticker. Đối chiếu TECH-13/19/21, ART-01..13 và QA-26/27/30/50 với số đo thật. Mọi số desktop chỉ kiểm tra chức năng của prototype.

## Thiết kế

- Scene độc lập `mobile_rendering_spike.tscn` dùng viewport dọc đã khóa trong `game/project.godot`; không thay luật hay màn T01.
- Một atlas mẫu gốc gồm bốn frame đơn giản để thử nạp và phát clip; mọi sprite mèo trỏ về cùng texture. Nền vùng, nhãn và họa tiết được vẽ tách khỏi atlas. Sticker ngắn không che bàn hoặc điều hướng.
- Bàn 6×6 và điều khiển mẫu giữ vùng chạm trong safe area giả lập. Test desktop kiểm tra cấu trúc, texture dùng chung, clip, bounds và chạy headless; người kiểm tra xác nhận hình ảnh trên thiết bị thật.
- Báo cáo ghi model/OS, host/toolchain, cấu hình export, atlas, FPS, stall, RAM, VRAM, cold load, safe area và kết quả offline cho từng máy. Ô chưa đo ghi rõ `CHƯA ĐO`; không suy diễn từ headless.

## Thứ tự thực hiện

1. Ghi smoke test kỳ vọng scene và các bất biến rendering; chạy để thấy lỗi thiếu scene.
2. Tạo atlas mẫu nguyên gốc và scene/script tối thiểu cho test qua.
3. Chạy Godot headless smoke, toàn bộ unit test và level validator; kiểm tra render desktop.
4. Khảo sát khả năng export/cài/chạy Android và iOS, ghi lệnh cùng kết quả thật.
5. Điền review và evidence; chạy `agent_pipeline verify M0-A03` và chỉ handoff khi toàn bộ tiêu chí nghiệm thu có bằng chứng. Nếu thiếu thiết bị hoặc macOS/Xcode, đặt package `blocked` theo hợp đồng.

## Giới hạn

Atlas mẫu chỉ đại diện đường nạp/dùng lại resource. Chất lượng model/rig, clip sản xuất, chi phí texture thực và khả năng đạt ngưỡng hiệu năng chỉ có thể chốt bằng asset đại diện và thiết bị mục tiêu.
