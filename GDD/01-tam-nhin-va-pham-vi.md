# 01 — CanDoKu: tầm nhìn và phạm vi

## 1. Lời hứa trải nghiệm

**“Tìm lại từng viên kẹo, bằng từng suy luận nhỏ.”**

Một giỏ kẹo bọc giấy bị nghiêng khi đi qua khu vườn. Kẹo rơi khuất trong các luống cây; người chơi nhìn sơ đồ vườn và lần lượt tìm lại chúng. Mỗi màn là một bố cục câu đố được biên tập: đúng một viên trong mỗi hàng, cột và luống; các viên không nằm ở ô chạm nhau. Đây là quy ước của trò chơi, không mô phỏng vật lý kẹo rơi.

CanDoKu dành cho người thích câu đố ngắn trên điện thoại, muốn cảm giác tự tìm ra lời giải và có thể dừng bất cứ lúc nào. Một lượt mục tiêu 1–6 phút tùy màn; chưa coi đây là số liệu playtest. Chơi dọc, một người, offline, tiếng Việt đầu tiên.

Ba trụ cột: **suy luận rõ ràng**, **thao tác có chủ ý**, **khu vườn dễ đọc và dễ chịu**. Kẹo được hé lộ là phần thưởng cho suy luận. Không giấu manh mối bằng bụi cây, độ sáng, vật thể nhỏ hoặc màu sắc khó phân biệt.

## 2. Vòng lặp

Home → tiếp tục màn hiện tại → đọc hàng/cột/luống → ghi X ở ô loại trừ → hai chạm tìm kẹo → xem phản hồi → tìm đủ → kết quả → màn kế.

- Kẹo đúng ở lại ô để làm chứng cứ; chỉ báo vùng đổi sang đã tìm.
- X thường là ghi chú của người chơi, có thể xóa hoặc Undo một action.
- X đỏ là lần tìm sai đã được hệ thống xác nhận; khóa trong lượt và mất một tim.
- Ba tim hết thì thua; thử lại miễn phí cùng màn. Không thời gian đếm ngược.
- Một Hint mỗi lượt giải thích suy luận, không tự tìm kẹo.
- Rời màn/app lưu lượt đã commit; quay lại tiếp tục đúng tiến trình.

Kẹo cho sẵn là viên đã được tìm trước khi vào màn, hiển thị từ đầu, không cho điểm. Mỗi viên tự tìm cộng 100, mỗi lỗi trừ 25; scorecard bằng `max(0,100×correctPlacedCount−25×mistakeCount)`, chỉ hiện tại kết quả. Không quy đổi kẹo hoặc điểm thành tiền.

## 3. Phạm vi bản đầu

| Có trong thiết kế đích | Giới hạn |
| --- | --- |
| 24 màn gốc liên tiếp, N=4–6 | Không sao chép cấu trúc level thương mại; không bản đồ hoặc chọn màn |
| S1 loại trừ, S2 ứng viên đơn, S3 giao thoa | 1–18 chỉ S1/S2; mỗi màn 19–24 cần S3 |
| Home, Puzzle, Help, Settings, Win, Fail | Settings giữ các tùy chọn âm/rung/giảm chuyển động/chữ lớn/tương phản |
| Tutorial ở màn 1 | Giữ quyết định gọi tọa độ, không glow ô tutorial |
| Một mẫu kẹo bọc giấy gốc | Không chọn loại kẹo, kho đồ, mua ngoại hình hoặc nhân vật nuôi |
| Vườn 2D, sáu kiểu nền vùng phân biệt | Trang trí ngoài lưới, không thêm chướng ngại hoặc luật bí mật |
| Save cục bộ, Retry, Undo X, Restart | Không tài khoản, cloud save hoặc mạng bắt buộc |
| Android và iOS | Phải kiểm thiết bị thật trước khi tuyên bố phát hành |

Endless, daily challenge, leaderboard, generator runtime, quảng cáo/IAP, điểm danh, vàng/cứu lượt và xây vườn không thuộc bản đầu. R1 tiếp tục là bản chơi liền mạch bốn level; hoàn thiện 24 level thuộc R3 đã có, không tự mở R2–R4.

## 4. Nhịp vườn và đường cong học

Các dải dưới là định hướng biên tập, không thêm chương hoặc trường schema.

| Màn | Bàn | Kỹ năng trọng tâm | Motif ngoài bàn / thời gian mục tiêu |
| --- | --- | --- | --- |
| 1 | 4×4 | X, xóa, kéo, chạm đôi, bốn luật và Hint | Lối vào vườn; 1–3 phút |
| 2–4 | 4×4 | Tự áp dụng luật với ba tim đầy đủ | Luống non; 1–3 phút/màn |
| 5–12 | 4×4–5×5 | S1/S2 qua nhiều hàng/cột/luống | Góc hoa; 2–4 phút/màn |
| 13–18 | 5×5–6×6 | Chuỗi S2 dài hơn, ít hỗ trợ hơn | Vườn rợp lá; 3–6 phút/màn |
| 19–24 | 5×5–6×6 | S3 giao thoa rồi S2 | Góc giỏ picnic; 3–6 phút/màn |

Màn 10 có motif hoa nở, màn 20 có motif giỏ picnic trong ảnh kết quả; không mở vật phẩm hoặc nhận tiền. Màn 24 khép lại chuyến tìm kẹo bằng giỏ đầy và thông báo hoàn tất. Không hứa nội dung “sắp ra mắt” khi chưa có kế hoạch.

## 5. Chất lượng và ranh giới

Ít nhất 8/10 người mới hoàn thành tutorial và hiểu X đỏ. Mọi level có vùng liên thông, nghiệm duy nhất, trace hợp lệ và một lượt giải không nhìn đáp án, còn ít nhất một tim. Bàn phải đọc được khi tắt âm, giảm chuyển động và ở thang xám; thao tác ngữ nghĩa cho trình đọc màn hình được nghiệm thu riêng.

Không đánh đồng nghiệm duy nhất với dễ hiểu; không dùng việc tìm sai để ép xem quảng cáo. Khi người chơi đoán liên tục, xem lại level, Hint và onboarding. Client phải dùng kẹo bọc giấy đồng nhất trong bàn, luật và tiến độ.

N=7–12 chỉ là khả năng dữ liệu để sau. Không zoom/pan vì xung đột với input X; chỉ mở bàn lớn sau QA kích thước chạm, đọc vùng và hiệu năng. Tên CanDoKu đã chốt trong dự án; logo và asset cuối phải là sản phẩm gốc.
