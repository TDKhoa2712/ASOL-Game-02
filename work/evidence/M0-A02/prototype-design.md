# M0-A02 Playable Interaction Prototype — Design Specification

## Intent

Tạo prototype T01 có thể mở và chơi trực tiếp bằng Godot 4.7.2 Editor. Prototype chứng minh interaction contract v2 cho tap, double-tap, drag, locked cells, Undo, Restart và lifecycle mà không phụ thuộc APK, thiết bị thật hoặc production assets.

## Selected architecture

Tách model, gesture và view để cùng một logic có thể được replay headless và điều khiển bằng input thật:

1. `InteractionSession` là model GDScript thuần, giữ cells, hearts, mistake count, hint count, events và một undo diff.
2. `GestureEngine` nhận pointer down/move/up theo logical coordinates, quản lý preview, pending tap 280 ms, touch slop 12 px, primary pointer và stroke interpolation.
3. `BoardView` là custom `Control`, ánh xạ pointer vào ô và vẽ board/state bằng primitive vector nguyên gốc.
4. `BoardScreen` nối status, Undo, Restart confirmation và session/gesture/view.
5. `bootstrap.tscn` tiếp tục là main scene để giữ baseline A01, nhưng instantiate `board.tscn` nên Run Project mở prototype ngay.

Script board nguyên khối bị loại vì khó replay contract/lifecycle một cách xác định. Kiến trúc node-per-cell bị loại vì tạo nhiều signal/state phân tán không cần thiết cho bàn 4×4 prototype.

## Runtime data

- T01 được mirror vào `game/data/t01.json` với size, regions, givens và solution canonical.
- Interaction contract v2 được mirror vào `game/tests/fixtures/interactions.v2.json`.
- Python sync test so sánh các mirror với GDD canonical để phát hiện drift.
- Runtime không đọc file ngoài `res://`, nên project chạy độc lập trong Godot Editor.

## Session semantics

- Cell không phải given có `empty`, `x`, `x_error` hoặc `cat`.
- Given được kiểm tra từ level data và bất biến.
- `MarkX`, `ClearX` và `MarkStroke` lưu đúng một undo diff thực tế.
- `TryCat` xóa khe Undo trước khi chấm đúng/sai.
- Thử đúng đặt `cat`; thử sai đặt `x_error`, giảm một tim và tăng một lỗi.
- Undo không thay đổi cat, x_error, hearts, mistake count hoặc hint count.
- Restart/Retry reset attempt; Back/Home, CloseApp, Won và Failed xóa Undo.
- Model hỗ trợ toàn bộ session vectors của contract v2, kể cả Hint lifecycle, dù UI prototype chỉ cần nút Undo và Restart.

## Gesture semantics

- Pointer down trên empty/x đổi preview trong khung hình hiện tại.
- Pointer up không kéo mở pending window 280 ms.
- Pointer down thứ hai cùng ô trong window có thể trở thành double tap; preview đầu được rollback trước một `TryCat`.
- Pointer khác ô flush tap trước thành action độc lập.
- Di chuyển lớn hơn 12 logical px chuyển thành stroke với mode lấy từ trạng thái trước preview.
- Stroke nội suy mọi ô giao nhau, mỗi ô xử lý tối đa một lần và bỏ qua state không khớp mode.
- Chỉ primary pointer sở hữu board; contact phụ không tạo stroke.
- Background flush pending released tap nhưng hủy press/stroke chưa release.

## Visual and interaction design

- Bàn T01 4×4 đặt giữa viewport portrait, cell đủ lớn để click/touch trong Editor.
- Vùng dùng nền sáng, viền, nhãn A–D và pattern đơn giản; không truyền thông tin chỉ bằng màu.
- `x` dùng nét trung tính; `x_error` dùng X đỏ, viền cảnh báo và dấu khóa.
- Cat/given dùng icon mèo vector nguyên gốc vẽ bằng tai tam giác, đầu tròn và mắt; một ngoại hình dùng cho mọi vùng.
- Thanh trên hiển thị ba tim và hướng dẫn trạng thái ngắn.
- Undo luôn nhìn thấy nhưng disabled khi khe rỗng.
- Restart mở hộp xác nhận; Cancel giữ nguyên, Confirm tạo attempt mới.
- Không audio, SFX, production asset, animation polish hoặc claim hiệu năng mobile.

## Automated verification

- Canonical Python interaction contract tiếp tục pass.
- Fixture sync test bảo đảm T01/interaction mirror không lệch GDD.
- Godot headless runner replay toàn bộ `cases` và `sessionCases`, so sánh cells, hearts, actions/events và undo availability.
- Scene smoke runner instantiate board, kiểm node/UI chính, gọi Undo/Restart paths và xác nhận không có runtime error.
- Existing five A01 baseline tests tiếp tục pass.

## Manual acceptance

Mở `game/project.godot` bằng Godot 4.7.2 và Run Project:

- click một lần để đánh/xóa X;
- double-click cùng ô để thử mèo;
- drag để đánh/xóa stroke;
- quan sát locked cat/given/x_error;
- dùng Undo;
- mở Restart, thử Cancel rồi Confirm.

## Non-goals

- Không tạo level production hoặc thay đổi GDD.
- Không thêm production art/audio/SFX.
- Không build APK hay yêu cầu thiết bị thật.
- Không đo hoặc tuyên bố TECH-13/19/21.
