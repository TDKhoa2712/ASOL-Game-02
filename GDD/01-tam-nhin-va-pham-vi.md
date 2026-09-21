# 01 — Tầm nhìn và phạm vi

## 1. Sản phẩm

**Tên tạm:** Vườn Mèo. Game suy luận một người cho điện thoại dọc, chơi offline. Trên lưới N×N, người chơi tìm đúng một mèo trong mỗi hàng, cột và vùng màu; mèo không chạm nhau kể cả góc. Mỗi nước đặt mèo là một xác nhận có chủ ý bằng **hai chạm cùng ô**. Nhịp chơi ngắn, phản hồi sáng và vui, trong khi bàn cờ luôn dễ đọc.

**Trụ cột:** luật dễ nhớ; level có một nghiệm và trace suy luận; tương tác chỉ X và mèo; nhân vật mèo gốc cùng hoạt ảnh chúc mừng. Màu giúp nhận diện vùng và luôn có nhãn hoặc họa tiết hỗ trợ; hình mèo không mã hóa vùng.

Vòng lặp: `Mở game → vào level hiện tại → đánh/xóa X bằng chạm hoặc kéo → có thể Undo action X gần nhất → xác nhận mèo bằng hai chạm → thắng và xem scorecard → sang level kế`. Người chơi có thể Restart có xác nhận để bắt đầu lại cùng level. Thử sai tạo X đỏ khóa và mất tim; hết tim có màn thua và Retry miễn phí. Không có bản đồ/chương/chọn level đã qua trong bản đầu.

## 2. Phạm vi phát hành đầu

| Mảng | Bản đầu | Mở rộng có điều kiện |
| --- | --- | --- |
| Level | 24 level gốc liên tiếp, N=4–6, thứ tự `1..24` | N=7–12, thêm level ở cuối dãy |
| Suy luận | Level 1–18 dùng S1/S2; mỗi level 19–24 cần ít nhất một S3; trace máy kiểm và Hint giải thích S2/S3 | S4/S5 sau khi tool và UX chứng minh được |
| Ô | `empty`, `x`, `x_error`, `cat`; một chạm X/clear hiện ngay, rê tô/xóa X, hai chạm thử mèo; Undo một action X gần nhất; X đỏ khóa | Chế độ nhập hỗ trợ nếu playtest yêu cầu |
| Tiến trình | Chỉ level hiện tại, tự lưu offline, thắng tiến một level, Retry vô hạn | Đồng bộ tài khoản sau quyết định riêng |
| Điểm | `100 × số mèo đúng do người chơi đặt − 25 × lỗi`, sàn 0; chỉ hiện ở Result và không quy đổi | Mọi kinh tế cần quyết định sau MVP riêng |
| Hình ảnh | Vùng có 6 màu/nhãn/họa tiết; mọi ô mèo và hoạt ảnh dùng mèo mặc định từ sprite gốc, phản hồi “Nice/Great”, sticker thắng dựng bằng model 3D gốc | Tối đa 12 màu/họa tiết vùng; mèo được chọn và clip riêng theo gói asset |
| Meta | Một Hint miễn phí mỗi lượt; `NoHint` không tiêu thụ; không ví vàng, điểm danh, quảng cáo hay interface meta | Nguồn Hint từ điểm danh/quảng cáo và mọi kinh tế chỉ được nghiên cứu sau MVP |
| Vận hành | Android/iOS, tiếng Việt, offline, không quảng cáo/IAP/tài khoản/analytics mạng | Dịch vụ mạng chỉ sau đánh giá và quyết định phạm vi riêng |

`score` là chỉ số thành tích **của lượt hiện tại**, chỉ hiện ở Result. Mèo cho sẵn không cho điểm; mỗi mèo đúng chỉ được cộng 100 một lần vì cat đúng cố định. Mỗi lần thử sai trừ 25 điểm nhưng không dưới 0. X, thời gian và Hint không cộng/trừ điểm; X đỏ giữ lại để người chơi nhớ ô sai. Thắng lưu scorecard; thất bại hiển thị scorecard của lượt nhưng không cộng vào tiến trình. MVP không hứa hẹn quy đổi điểm, kinh tế vàng hoặc cứu lượt.

### Nhịp nội dung

| Khoảng level | Kích thước chính | Bài học | Mục tiêu playtest |
| --- | --- | --- | --- |
| 1 | 4×4 | Tutorial duy nhất: X/clear/kéo/chạm đôi, bốn luật, X đỏ và Hint | 1–3 phút |
| 2–4 | 4×4 | Áp dụng đầy đủ phạt tim; luyện hàng/cột/vùng và không chạm | 1–3 phút/level |
| 5–12 | 4×4–5×5 | Dùng mèo đã tìm để loại ô | 2–4 phút/level |
| 13–18 | 5×5–6×6 | Chuỗi S1/S2 dài hơn, ít mèo cho sẵn hơn | 3–6 phút/level |
| 19–24 | 5×5–6×6 | Mỗi level bắt buộc cần S3 ít nhất một lần | 3–6 phút/level |

Con số 24 và nhịp thời gian là cổng nội dung, không phải lý do hạ chuẩn. Level trùng lặp, khó đọc hoặc cần đoán phải được biên tập lại.
Level 10 và 20 là mốc nội dung có motif/sticker và nhịp suy luận riêng, được duyệt trước khi phát hành vì ID/puzzle đã phát hành không đổi. Generator sau MVP phục vụ level mới và các mốc tiếp theo.

## 3. Mở rộng N=12

Core/schema/validator hỗ trợ N=4–12 và nhãn vùng `A..L` ngay từ đầu. **Không dùng zoom/pan** trong thiết kế điều khiển: chúng xung đột với chạm đôi/rê X. N>6 chỉ phát hành khi bàn ở kích thước thực vẫn chạm chính xác, 12 màu/nhãn/họa tiết đọc được và solver/trace đạt ngân sách trên thiết bị mục tiêu. Nếu N=12 trên điện thoại dọc không đạt, giữ N=12 ở dữ liệu/thử nghiệm và giới hạn nội dung phát hành theo thiết bị phù hợp; không hạ trần schema âm thầm.

## 4. Cổng trải nghiệm

- Ít nhất 8/10 người mới hoàn thành hướng dẫn chạm/kéo/chạm đôi và hiểu X đỏ là một lần thử sai bị khóa.
- 100% level phát hành có vùng liên thông, nghiệm duy nhất và trace hợp lệ: order 1–18 không dùng S3, order 19–24 có ít nhất một S3 cần thiết. Một người giải không xem đáp án duyệt mỗi level và hoàn thành với ít nhất 1 tim.
- Thắng/thua/Back To Home/đóng app không đưa người chơi về level cũ hoặc vượt qua level chưa thắng.
- Bàn đọc được khi tắt âm, giảm chuyển động, ở thang xám và bằng trình đọc màn hình.
- Màu, sticker và sprite render từ model 3D đều là asset gốc; phản hồi vui không che bàn hoặc làm chậm thao tác kế.

Không sao chép level, nhân vật, icon, giao diện, âm thanh hoặc lời văn của Meowdoku. Tên phát hành cuối và art direction chi tiết được chốt trước khi tạo asset cuối.
