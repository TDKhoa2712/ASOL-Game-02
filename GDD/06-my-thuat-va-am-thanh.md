# 06 — CanDoKu: mỹ thuật, hoạt ảnh và âm thanh

## 1. Hướng hình ảnh

Một khu vườn nhỏ trong ngày sáng dịu, với kẹo bọc giấy rơi khỏi giỏ picnic. Hình ảnh 2D mềm, viền rõ, màu kem và xanh lá làm nền; kẹo là điểm chú ý khi được tìm thấy. Bàn là sơ đồ luống vườn nhìn từ trên xuống, có ranh giới chính xác. Không dùng phối cảnh làm méo ô hoặc cây lá phủ đáp án.

Kẹo mặc định có thân tròn hơi dẹt, hai đầu giấy gói xoắn và một dấu xoắn nhỏ; silhouette nhận ra ở ô nhỏ. Một mẫu kẹo dùng chung mọi vùng, không gán hương vị/màu giấy gói thành quy tắc. Giấy gói kín giúp hình ảnh “nhặt lại kẹo” rõ nghĩa. Không cần nhân vật hoặc model/rig 3D trong bản đầu.

| ID | Nguyên tắc |
| --- | --- |
| ART-01 | Vùng có nền sáng, viền, nhãn A–F và họa tiết riêng; bàn N≤6 của bản đầu |
| ART-02 | Kẹo nằm gọn trong 60–70% cạnh ô; không che biên vùng, X hoặc tọa độ; cùng mẫu cho given và kẹo tự tìm |
| ART-03 | X thường nét trung tính; X đỏ có dấu cảnh báo/khóa ngoài màu; hai trạng thái phân biệt khi thang xám |
| ART-14 | LOCKED cell: X mờ (reduced opacity) với LOCKED_OVERLAY color tint, phân biệt rõ với X do người chơi; không tương tác được |
| ART-15 | GIVEN candy: cùng hình kẹo mặc định với halo/glow nhẹ để phân biệt với kẹo người chơi tự tìm |
| ART-04 | Lá/hoa/giỏ và sparkle ở ngoài vùng thao tác; không che luật, tim, nút hoặc lưới |
| ART-05 | Logo, kẹo, giỏ, nền, icon và âm thanh có nguồn gốc/giấy phép/file nguồn rõ |
| ART-12 | Không có gói ngoại hình bán hoặc bộ sưu tập; yêu cầu appearanceId/clip nhân vật cũ ngừng áp dụng cho bản đầu |
| ART-13 | Một bộ hình kẹo dùng chung; không nhân texture theo sáu vùng; alpha và pivot nhất quán |

## 2. Màu và luống

| Nhãn | Màu nhấn khởi điểm | Họa tiết |
| --- | --- | --- |
| A | San hô #D76F5D | Chấm |
| B | Xanh ngọc #328F83 | Sọc ngang |
| C | Vàng mật #A97617 | Gạch chéo |
| D | Tím hoa #8B6EB3 | Ô vuông |
| E | Xanh trời #397FAC | Sóng |
| F | Hồng mận #AD6287 | Vòng nhỏ |

Nền luống dùng biến thể nhạt; màu nhấn dùng ở biên và nhãn, không làm kẹo đổi màu. Nền chung kem #FFF7E8, chữ xanh đậm #243D32 là token khởi điểm, cần đo tương phản trên màu thực. Chữ đạt 4.5:1, dấu/viền quan trọng đạt 3:1 theo tiêu chí dự án. Họa tiết có độ tương phản thấp hơn dấu X nhưng phải phân biệt ở thang xám. Nhãn và đường viền không được mất khi luống đã tìm đủ kẹo.

Các motif theo dải màn chỉ thay viền trang trí/backdrop, không thay mapping A–F giữa các màn. N=7–12 chưa sản xuất asset; phải bổ sung sáu cặp màu/họa tiết và nghiệm thu riêng trước khi mở.

## 3. Phản hồi

| ID | Sự kiện | Thiết kế đích |
| --- | --- | --- |
| ART-06 | X/clear | Đổi ngay trong khung hình đầu; hủy preview sạch khi nhận chạm đôi |
| ART-07 | Tìm đúng | Kẹo hiện bằng scale nhẹ 160–220 ms rồi đứng yên; chỉ báo vùng và “Đã tìm k/N” cập nhật; chữ “Tìm thấy rồi!” tối đa 0,7 giây |
| ART-08 | Tìm sai | X đỏ + dấu cảnh báo và tim mất cùng transaction; phản hồi nhẹ tối đa 200 ms; không tạo hố đất hoặc làm bẩn bàn |
| ART-09 | Thắng | Giỏ kẹo và vài cánh hoa trên Result; nút Màn tiếp theo/Home dùng ngay, không chờ hoạt ảnh |
| ART-10 | Thua | Giỏ bên luống và lời động viên; màn riêng, nút Thử lại rõ; không biểu cảm trừng phạt |
| ART-11 | Giảm chuyển động | Hình tĩnh + thông báo chữ; tắt scale/particle/loop, giữ đầy đủ thông tin |

Kẹo đã tìm luôn ở lại ô. Mốc “Giỏi lắm!” chỉ phát một lần khi đạt ít nhất nửa số kẹo cần tự tìm; kẹo cuối ưu tiên thắng. Có thể dùng giỏ đầy ở màn 30 của campaign playtest nhưng không thêm màn phải chờ. Hiệu ứng không tự cộng điểm, mất tim, lưu game hoặc xác định thắng.

Hệ thống âm thanh dùng **procedural PCM synthesis** (`pcm_synth.gd`) — tạo âm từ sóng cơ bản (sine, square, triangle, sawtooth), ADSR envelope, pitch curves, noise mixing, low-pass filter, pencil scratch và melody. Không phụ thuộc file audio ngoài cho SFX. `sfx_catalog.gd` định nghĩa 22 hiệu ứng âm thanh:

| Nhóm | Hiệu ứng |
| --- | --- |
| Board | MARK, UNMARK, LOCK_TICK |
| Gameplay | CANDY_YES, CANDY_NO, STAGE_CLEAR, STAGE_FAIL |
| Hint | HINT_SHOW, HINT_APPLY, HINT_DISMISS, HINT_WRONG_MARK |
| UI | BTN_PRESS, BOARD_OPEN |
| Khác | Các presets synth/melody/pencil bổ sung |

`sfx_player.gd` dùng pool 8 AudioStreamPlayer voices với rate limiting (min_interval mỗi hiệu ứng) để tránh spam khi nhiều ô locked xuất hiện liên tiếp. Auto-bind UI buttons cho SFX. `bgm_player.gd` phát nhạc nền WAV với loop fix và mute support.

Rung haptic qua `vibration.gd`: SOFT (15ms), NORMAL (30ms), FIRM (60ms). Âm và rung tắt riêng; phản hồi vẫn hiểu khi tắt cả hai. App nền dừng âm/animation và không tự phát lại toàn bộ hiệu ứng khi resume.

Animation qua `tween_fx.gd`: scale_pop, shake, flash_color, bounce, fade_in, fade_out. `cell_animator.gd` quản lý cell state transitions với pre-baked mark textures. `board_entry_wave.gd` tạo board reveal animation.

### Typography

Font đã chuyển sang **BeVietnamPro** (Bold/Regular) cho heading và **Nunito** (Regular/SemiBold/Bold) cho body text (`font_tokens.gd`). BeVietnamPro hỗ trợ đầy đủ tiếng Việt có dấu.

## 4. Bàn giao asset và pipeline

| Nhóm | Asset cần có | Nghiệm thu |
| --- | --- | --- |
| Nhận diện | Logo chữ CanDoKu, icon app kẹo gốc | Đọc được nhỏ, không dùng bố cục/icon thương mại tham chiếu |
| Gameplay | Kẹo ô, icon kẹo nhỏ, X, X đỏ/cảnh báo, tim đầy/rỗng, dấu đã tìm | Bốn trạng thái và given đọc rõ N=6, thang xám |
| Vườn | Nền kem, viền cây, sáu nền/biên/họa tiết vùng, giỏ thường/đầy | Không tiết lộ đáp án hoặc che vùng chạm |
| UI | Home/Back/Help/Settings/Undo/Restart/Hint và các trạng thái disabled | Vùng chạm ≥44×44 điểm logic; chữ lớn và safe area |
| Result | Hình thắng/thua riêng, motif hoa màn 10 và picnic màn 20 | Nút luôn thao tác được, giảm chuyển động đầy đủ |
| SFX | X/clear/đúng/sai/thắng/thua | Âm lượng nhất quán, không clipping, không là kênh thông tin duy nhất |
| Nguồn | File thiết kế, bản xuất, manifest nguồn/giấy phép/version/kích thước | Mỗi asset truy được tác giả/công cụ và quyền sử dụng |

Ưu tiên hình 2D gốc và tween đơn giản; SVG phù hợp icon, PNG nền trong cho raster. Không bắt buộc sprite sheet nếu tween đủ. Có thể render kẹo từ model gốc khi art thực tế cần, nhưng runtime vẫn 2D; không có phụ thuộc model/rig/clip kẹo. Đây là thay đổi art direction có chủ ý so với v0.5.

Chốt kích thước xuất qua thử N=6 và màn Result trước khi làm toàn bộ asset. Dùng chung resource giữa các ô, chỉ nạp asset cần màn hiện tại, có hình dự phòng nếu tải lỗi. Đo texture thực trong RAM/VRAM, tốc độ nạp và frame time trên Android/iPhone mục tiêu; không lấy kích thước PNG nén làm mức dùng bộ nhớ. Asset cũ đã được thay và không còn tham chiếu có thể dọn theo yêu cầu chủ dự án; bản gốc được bảo toàn trong lịch sử Git.
