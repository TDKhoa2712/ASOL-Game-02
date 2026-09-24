# M1-C01 — Level review

Ngày rà soát: 2026-09-24

## Phạm vi

Campaign gồm đúng bốn level gốc `L01`–`L04`, order 1–4. Fixture kỹ thuật `T01`, `E01`, `E02`, `S301` và `N12` không được đưa vào campaign.

## Kiểm tra tự động

- Canonical validator kiểm tra schema v4, ID/order, vùng liên thông, nghiệm duy nhất, givens khớp nghiệm và trace tuần tự.
- Bốn level đều dùng trace `S2`; không có bước `S3`, `S4` hoặc `S5`.
- Mỗi level có ít nhất hai hàng chưa có given để người chơi tự tìm mèo.
- Chuẩn hóa hình vùng trong cửa sổ campaign không phát hiện trùng hình.

| ID | Kích thước | Difficulty | Givens | Mèo người chơi tìm | Trace |
| --- | ---: | --- | ---: | ---: | --- |
| `L01` | 4×4 | tutorial | 0 | 4 | 4 bước S2 vùng |
| `L02` | 5×5 | easy | 1 | 4 | 3 bước S2 vùng, 1 bước S2 hàng |
| `L03` | 6×6 | easy | 1 | 5 | 5 bước S2 vùng |
| `L04` | 6×6 | medium | 1 | 5 | 4 bước S2 vùng, 1 bước S2 hàng |

## Tutorial Level 1

`L01` mang tag `tutorial` và được `tutorial_controller.gd` nhận diện theo ID `L01`. Level có bốn placement S2 liên tiếp sau trạng thái ban đầu, đủ không gian để tutorial dẫn qua các mốc T1–T6 mà không cần thêm schema content riêng. Tutorial chỉ được gắn cho `L01`; `L02`–`L04` không có tag tutorial.

## Editorial walkthrough

Trace của từng level đã được replay từ givens theo thứ tự trong JSON; mỗi placement đều khớp một ứng viên S2 duy nhất và kết thúc đủ N mèo. Replay không dùng nghiệm khai báo làm bằng chứng runtime, không thêm Hint, không tạo lỗi và giữ nguyên ba tim trong mô phỏng nội dung.

Thời gian và phản hồi của người chơi mới trên thiết bị thật không được suy diễn từ replay tự động; phần playtest, accessibility và đo thiết bị thuộc `M1-GATE`.

## Kết luận

Campaign đạt các kiểm tra dữ liệu của M1-C01: đúng bốn slot 1–4, nghiệm duy nhất, trace S2 hợp lệ, không trùng hình vùng và có Level 1 dành riêng cho tutorial.
