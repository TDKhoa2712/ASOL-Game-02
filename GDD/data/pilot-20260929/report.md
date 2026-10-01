# Pilot sinh level CanDoKu

Kết quả máy: **COMPLETE**, 8/8 màn; 372 ứng viên; 0.359 giây.

Nhãn difficulty là tạm tính. Người chơi: NOT_RUN, 0 mẫu. UI/thiết bị: NOT_RUN.
Order là vị trí dự kiến để kiểm logic band; pilot không phải campaign phát hành.

| ID | Order | Cỡ | Given | Tier | S2 / S3 | Điểm | Min–max policy | Độ sâu | Nhãn tạm |
| --- | ---: | --- | ---: | --- | --- | ---: | --- | ---: | --- |
| P8A4308F75901 | 2 | 4×4 | 2 | B | 2 / 0 | 6 | 6–6 | 1 | easy |
| P0C5829821A43 | 4 | 4×4 | 2 | B | 2 / 0 | 7 | 6–7 | 2 | easy |
| P31F1D5747E5F | 7 | 5×5 | 2 | B | 3 / 0 | 10 | 9–10 | 3 | easy |
| P3F8E5A1C7489 | 10 | 5×5 | 2 | B | 3 / 0 | 8 | 8–8 | 1 | easy |
| P00679AB27553 | 14 | 6×6 | 2 | B | 4 / 0 | 13 | 11–13 | 3 | easy |
| P66FC3F6EFB0A | 18 | 6×6 | 1 | B | 5 / 0 | 17 | 15–17 | 4 | medium |
| P7845A479D6D9 | 19 | 5×5 | 1 | I | 4 / 1 | 18 | 17–18 | 5 | medium |
| P76EFA508F924 | 22 | 6×6 | 1 | I | 5 / 1 | 20 | 20–28 | 5 | medium |

## Phương pháp và giới hạn

Điểm = S2 + 4×S3 + 2×số trạng thái chỉ còn một hành động + độ sâu chứng cứ + ceil(số ô chứng cứ lớn nhất/6).
Duyệt S2 trước S3, gộp các kết luận giống nhau; phá hòa theo ít đơn vị/ô chứng cứ, loại nhiều ô rồi thứ tự cố định. Báo thêm hai policy theo tọa độ và tọa độ ngược. Không tuyên bố đường ngắn nhất.
Độ sâu lấy từ cạnh phụ thuộc chứng cứ từng bước, gồm các loại trừ cần để tái hiện đầy đủ kết luận S3. Given/topology là gốc 0. Đây là đồ thị chứng cứ đã chọn, không phải độ sâu tối thiểu toàn cục.
Ngưỡng easy ≤16 chỉ là giả thuyết; tier I luôn medium tạm. Điểm không dự đoán phút chơi.
Vùng được sinh bằng tăng trưởng qua cạnh và kiểm liên thông độc lập. Chưa tối ưu mỹ thuật hoặc nhánh hẹp; regionAreas/boundaryEdges chỉ hỗ trợ biên tập.
Loại trùng hình vùng trong toàn bộ batch và kho --exclude dưới xoay/lật/đổi nhãn; nghiêm hơn cửa sổ 8 màn.

## Ứng viên bị loại

- LOGIC_STUCK: 30
- MULTIPLE: 304
- RATING_RANGE: 29
- S3_NOT_REQUIRED: 1

## Lời giải dành riêng cho người điều phối

### P8A4308F75901

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. vùng B chỉ còn ô (1, 3); đặt kẹo.
2. vùng D chỉ còn ô (3, 4); đặt kẹo.

### P0C5829821A43

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. hàng 3 chỉ còn ô (3, 1); đặt kẹo.
2. vùng A chỉ còn ô (1, 2); đặt kẹo.

### P31F1D5747E5F

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. cột 2 chỉ còn ô (3, 2); đặt kẹo.
2. vùng D chỉ còn ô (4, 5); đặt kẹo.
3. hàng 2 chỉ còn ô (2, 4); đặt kẹo.

### P3F8E5A1C7489

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. vùng A chỉ còn ô (2, 1); đặt kẹo.
2. vùng E chỉ còn ô (4, 5); đặt kẹo.
3. cột 3 chỉ còn ô (3, 3); đặt kẹo.

### P00679AB27553

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. vùng C chỉ còn ô (2, 6); đặt kẹo.
2. hàng 4 chỉ còn ô (4, 5); đặt kẹo.
3. vùng D chỉ còn ô (6, 4); đặt kẹo.
4. vùng F chỉ còn ô (5, 1); đặt kẹo.

### P66FC3F6EFB0A

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. vùng C chỉ còn ô (3, 2); đặt kẹo.
2. hàng 1 chỉ còn ô (1, 1); đặt kẹo.
3. hàng 4 chỉ còn ô (4, 5); đặt kẹo.
4. vùng F chỉ còn ô (6, 6); đặt kẹo.
5. cột 3 chỉ còn ô (5, 3); đặt kẹo.

### P7845A479D6D9

Cờ cần review: không có cờ tự động; vẫn cần duyệt người.

1. Ứng viên của vùng D nằm trọn trong cột 5; loại các ô (1, 5), (5, 5) khỏi cột 5.
2. hàng 5 chỉ còn ô (5, 4); đặt kẹo.
3. vùng B chỉ còn ô (1, 3); đặt kẹo.
4. vùng A chỉ còn ô (2, 1); đặt kẹo.
5. vùng D chỉ còn ô (3, 5); đặt kẹo.

### P76EFA508F924

Cờ cần review: policySpread.

1. vùng D chỉ còn ô (3, 2); đặt kẹo.
2. Ứng viên của vùng C nằm trọn trong hàng 1; loại các ô (1, 1), (1, 4) khỏi hàng 1.
3. cột 4 chỉ còn ô (2, 4); đặt kẹo.
4. vùng C chỉ còn ô (1, 6); đặt kẹo.
5. cột 1 chỉ còn ô (6, 1); đặt kẹo.
6. hàng 4 chỉ còn ô (4, 5); đặt kẹo.

## Thử với người chơi

1. Thử sớm 3–5 người để tìm lỗi hiểu luật; chưa đủ hiệu chỉnh thang độ khó.
2. Hiệu chỉnh với ít nhất 10 người mục tiêu mỗi màn; dùng mã ẩn danh, đổi thứ tự màn giữa người chơi. Dạy S3 bằng ví dụ riêng trước khi thử nhóm S3 và ghi trình độ.
3. Ghi cả bỏ cuộc và có trợ giúp vào playtests.csv; thời gian chỉ tính lúc giải, ghi riêng thời gian nghỉ.
4. Báo tỷ lệ hoàn thành/trợ giúp, lỗi, median/p75 của nhóm hoàn thành không trợ giúp; nhóm còn lại báo riêng, không loại khỏi mẫu.
5. So thứ hạng máy với dữ liệu trong cùng nhóm kỹ năng; chỉnh ngưỡng bằng tập hiệu chỉnh và kiểm lại bằng level chưa dùng. Phiếu giấy không thay lượt chơi thật trong client.

Mỗi dòng CSV là một người–màn–lượt, ghi đúng revision và puzzleHash từ report.json. outcome: completed/abandoned; activeSeconds loại thời gian nghỉ; hints/mistakes là số thực đo. Không điền số 0 thay cho dữ liệu chưa đo. CSV mới chỉ có tiêu đề, chưa có kết quả người chơi.
