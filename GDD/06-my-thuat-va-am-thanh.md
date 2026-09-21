# 06 — Mỹ thuật, hoạt ảnh và âm thanh

## 1. Hướng hình ảnh bản chính thức

Khu vườn tươi sáng, vui và có nhân vật mèo gốc. Mỗi vùng có màu/nền/họa tiết trong cùng bộ theme; **mèo trên ô đúng dùng hình mèo đang chọn**, không lấy màu lông hoặc giống theo ô. Bản đầu dùng mèo mặc định. Màu nhấn và hoạt ảnh khiến việc tìm mèo có phần thưởng cảm xúc, còn nền bàn, viền vùng, X/X đỏ phải đọc được trước trang trí. X đỏ là lỗi người chơi đã thử, **không** là vùng màu đỏ hay mèo màu đỏ.

| ID | Nguyên tắc |
| --- | --- |
| ART-01 | Vùng có màu nền sáng vừa phải, viền rõ, nhãn A–(N) và họa tiết riêng; tối đa 12 cặp màu/họa tiết. |
| ART-02 | Mèo đang chọn giữ ngoại hình riêng trên mọi ô `cat`; vùng được phân biệt bằng nền/viền/nhãn/họa tiết quanh mèo. Silhouette/icon vẫn đọc ở ô N=6; bản N=12 cần bộ icon và kích thước chạm thực tế được nghiệm thu lại. |
| ART-03 | `x` là nét X trung tính; `x_error` đỏ đậm **kèm dấu cảnh báo/viền khác** và dấu khóa thao tác, không truyền lỗi chỉ bằng màu. |
| ART-04 | Sticker/sparkle sprite 2D nằm ngoài vùng chạm bàn hoặc chỉ phủ ngắn, không che ô, vùng luật, tim hay điều hướng. |
| ART-05 | Asset có manifest nguồn gốc, giấy phép, file nguồn và bản xuất; không dùng ảnh/model/âm thanh của game tham chiếu. |
| ART-12 | Mỗi mèo mới có `appearanceId` ổn định, silhouette/chi tiết riêng và đủ clip `idle`/`jump`/`celebrate`/`sad` tương ứng trước khi bán. Màu vùng nằm ở bàn và chỉ báo tiến độ, độc lập với mèo. |
| ART-13 | Một bộ atlas/clip cho mỗi mèo; không xuất 6/12 bản atlas theo vùng. Căn khung và alpha phải khớp từng frame; mặt nạ chỉ dùng nếu cần biến thể ngoại hình, không dùng để tô mèo theo vùng. |

### Bảng màu định hướng

| Nhãn | Màu nhấn vùng gợi ý | Họa tiết hỗ trợ |
| --- | --- | --- |
| A | san hô `#D76F5D` | chấm |
| B | xanh ngọc `#328F83` | sọc ngang |
| C | vàng mật `#A97617` | gạch chéo |
| D | tím hoa `#8B6EB3` | ô vuông |
| E | xanh trời `#397FAC` | sóng |
| F | hồng mận `#AD6287` | vòng nhỏ |
| G–L | sáu màu/họa tiết bổ sung trước đợt N>6 | không lặp cặp màu/họa tiết |

Nền vùng là biến thể sáng nhạt của màu nhấn, không dùng mã màu vùng để tô mèo. Đây là token khởi đầu; QA kiểm tương phản chữ 4.5:1, icon/viền 3:1 và thử thang xám/chế độ hỗ trợ trước khi chốt. Palette 12 cần review bằng thiết bị và người chơi, không dựa vào mã hex tự chứng nhận khả năng phân biệt.

## 2. Hoạt ảnh có chủ đích

| ID | Sự kiện | Cách thể hiện |
| --- | --- | --- |
| ART-06 | Chạm/kéo X/clear | X đổi trong khung hình đầu, từng ô trên đường kéo đổi ngay; preview có thể hoàn tác sạch khi chạm đôi mà không nháy/giật |
| ART-07 | Mèo đúng | Mèo đang chọn bật/nhảy ngắn, chỉ báo vùng sáng lên ở hàng tiến độ, chữ “Hay lắm!” (`Nice!` trong bản dịch); lần đầu đạt nửa số mèo cần tìm hiện “Tuyệt!” (`Great!`) |
| ART-08 | Mèo sai | X đỏ/dấu cảnh báo và tim đổi cùng lúc; rung nhẹ nếu bật, không nhấp nháy mạnh |
| ART-09 | Thắng | Sticker chúc mừng gốc và mèo nhảy/đùa bằng sprite sheet 2D render từ model 3D gốc, nút Level tiếp theo dùng được ngay |
| ART-10 | Thua | Biểu cảm tiếc nhẹ, màn kết quả thua riêng; không dùng hiệu ứng trừng phạt/chói |
| ART-11 | Giảm chuyển động | Chữ/viền/sticker tĩnh thay cho nhảy, lắc, particle; không bỏ thông tin luật |

Hoạt ảnh trên bàn tối đa khoảng 0,7 giây và không khóa điều hướng. Màn thắng có thể chạy loop nhẹ nhưng dừng khi app nền/giảm chuyển động. Khi tính năng chọn mèo được bật, phản hồi đúng/thắng dùng clip của mèo đang chọn; mèo mặc định chỉ là fallback nếu gói asset lỗi tải. Sound đi kèm không phải nguồn thông tin duy nhất: tick X, mèo đúng vui ngắn, lỗi nhẹ, motif thắng dưới 2 giây; âm và rung có nút tắt riêng.

## 3. Pipeline model 3D → sprite 2D

Tạo **một model mèo mặc định gốc** trước, rig và clip `idle`, `jump`, `celebrate`, `sad`. Lưu file nguồn và, nếu hữu ích cho tái sử dụng, xuất glTF. Render mỗi clip với cùng góc máy/ánh sáng/nền trong suốt thành **một bộ frame của mèo mặc định**; không render lại cho từng vùng A–L. Runtime bản đầu chỉ phát sprite. Mèo nhỏ trên bàn dùng icon hoặc ít frame; màn thắng dùng clip dài hơn. Chốt kích thước frame, số frame, atlas và cách nén bằng đo trên thiết bị. 3D realtime hoặc bake clip lúc người chơi đổi mèo là spike tương lai theo TECH-21/QA-51.

Về sau, mèo được mua có thể dùng cùng rig/clip nếu dáng và chuyển động phù hợp, hoặc có clip riêng nếu đó là phần bản sắc của mèo. Mỗi mèo khác hình dáng cần bộ frame riêng; shader đổi màu không sinh được tai, đuôi, hoa văn hay động tác mới. Danh sách vườn xem icon gọn trước; khi chọn mới nạp clip lớn. Nền/viền/nhãn/họa tiết vùng luôn hiển thị được quanh mèo để puzzle vẫn đọc được.

M0 kiểm kích thước file, texture, RAM/VRAM, FPS, thời gian xuất hiện khung đầu và chất lượng cạnh/đổ bóng của sprite trên Android/iPhone mục tiêu. Chỉ thêm frame/particle khi số đo còn ngân sách. Không tải asset qua mạng trong bản đầu.

## 4. Danh mục bàn giao

| Nhóm | Bản đầu |
| --- | --- |
| Bàn | 6 màu nền/viền/họa tiết, nhãn vùng, trạng thái X và X đỏ, phiên bản thang xám |
| Mèo | Một model/rig gốc, một bộ sprite mèo mặc định cho idle/jump/celebrate/sad, icon tĩnh gọn; hàng tiến độ dùng nhãn/họa tiết vùng |
| UI | Home, Puzzle, Help, Settings, **hai màn kết quả riêng**, tim ở Puzzle, scorecard ở Result, sticker thắng, trạng thái cỡ chữ lớn |
| SFX/rung | X/clear, đúng, sai, thắng, thua; thiết lập tắt độc lập |
| Nguồn | File model/texture/animation/audio gốc, manifest quyền, thông số xuất và version asset |

Đợt N=12 thêm 12 màu/nhãn/họa tiết vùng, **không** nhân atlas hoạt ảnh theo 12 màu; kiểm lại board nhỏ, hàng tiến độ cuộn và performance. Không lặp màu đơn thuần để đủ 12; nhãn/họa tiết phải phân biệt khi không nhìn màu.
