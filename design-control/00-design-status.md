# Trạng thái thiết kế

**Ngày chụp trạng thái:** 2026-09-21  
**GDD hiện hành:** v0.5.0, ngày 2026-09-21  
**Pha hiện tại:** xác nhận Game Design / Product Design / Technical Design trước production  
**Cổng mục tiêu:** đủ điều kiện vào M0 và tiến tới GDD v1.0 Design Freeze  
**Trạng thái Design Freeze:** **CHƯA SẴN SÀNG**

Thư mục này là lớp quản trị và truy vết. Nó không thay thế luật chuẩn ở
[`GDD/02-luat-choi-va-trang-thai.md`](../GDD/02-luat-choi-va-trang-thai.md),
quyết định review ở [`GDD/09-ra-soat-thiet-ke.md`](../GDD/09-ra-soat-thiet-ke.md),
hoặc các GDD hiện hành.

## 1. Thẩm quyền tài liệu

Áp dụng thứ tự:

1. `GDD/02` cho luật gameplay hiện hành.
2. `GDD/09` cho quyết định đã giải quyết từ review.
3. `GDD/README` cho quyết định cấp cao.
4. Các GDD hiện hành khác.
5. `design-reviews/` làm bằng chứng lịch sử, không tự tạo luật.
6. `design-control/` theo dõi trạng thái; không phải nguồn luật mới.

## 2. Bằng chứng hiện có

- Có GDD v0.5.0, schema level v4, năm fixture kỹ thuật và validator S2/S3.
- `T01`, `E01`, `E02`, `N12`, `S301` qua validator; không thuộc campaign phát hành.
- 20 validator tests và 3 interaction tests đang qua; contract v2 chứa 16 gesture vectors và 14 session vectors.
- Chưa có game Godot chạy được, campaign 24 level, asset hoàn chỉnh, script tutorial gắn level thật, đo thiết bị hoặc playtest.
- Python interaction reducer là mô hình tham chiếu, chưa chứng minh hành vi runtime Godot.

## 3. Khu vực ổn định

| Khu vực | Trạng thái | Mã chính |
| --- | --- | --- |
| MVP 24 level tuyến tính, N=4–6, không chọn/chơi lại level | Ổn định | D-01, GR-26..28 |
| Luật một mèo mỗi hàng/cột/vùng, không chạm chéo, nghiệm duy nhất | Ổn định | GR-01..05 |
| Bốn trạng thái ô và ngữ nghĩa tap/drag/double-tap | Ổn định về ngữ nghĩa | D-03/04, GR-08..16/29/30 |
| 3 tim, `x_error` khóa, Retry/Restart miễn phí; Undo một action X | Ổn định cho MVP | D-04/08, GR-13/16/17/19/31..33 |
| Một Hint/lượt; tutorial chỉ Level 1; scorecard Result-only | Ổn định cho MVP | D-05, GR-18/21..25, DEC-015/016 |
| Logic band: 1–18 S1/S2, 19–24 bắt buộc S3 | Ổn định về scope/schema | D-02, LV-08, DEC-013 |
| Godot 4.x, runtime 2D sprite từ nguồn 3D gốc | Ổn định về hướng kiến trúc | D-06, TECH-18/19 |
| Offline, tiếng Việt đầu tiên, không SDK mạng/quảng cáo trong MVP | Ổn định | D-07, TECH-11 |
| Mèo mặc định dùng chung; vùng không mã hóa bằng màu lông mèo | Ổn định | REV-TECH-05, ART-02/12/13 |

## 4. Khu vực tạm thời

| Khu vực | Giá trị hiện tại | Điểm chốt |
| --- | --- | --- |
| Cửa sổ chạm đôi | 280 ms | M0, DQ-004 |
| Ngưỡng kéo | 12 điểm logic | M0, DQ-004 |
| Hệ số scorecard | `100 × cat đúng − 25 × lỗi`, sàn 0; chỉ Result | M1 tuning; vai trò đã chốt DEC-016 |
| Thời lượng feedback | khoảng 0,7 giây | M0/M1 |
| Godot minor/renderer/thiết bị mục tiêu | Chưa chọn | M0, DQ-003 |
| Atlas, nén và ngân sách RAM/VRAM | Chưa chọn | M0, DQ-005 |
| Nhịp khó và thời gian 24 level | Mục tiêu biên tập; acceptance đã định nghĩa | M1/M2, DQ-008 |
| Tên phát hành/logo/art identity | Tên tạm | Trước art cuối, DQ-010 |

## 5. Khu vực nghiên cứu

- Chất lượng runtime Hint S3 và sáu level gốc 19–24 thực sự cần S3.
- Khả năng tạo 18 level S1/S2 và 6 level S3 hấp dẫn trong band đã chốt.
- Khả năng đọc vùng khi mọi cat dùng cùng một ngoại hình.
- Cảm giác chơi với 3 tim, Undo X một bước và X đỏ khóa.
- Khả năng vận hành N=7–12 không zoom/pan sau MVP.

## 6. Khu vực hoãn

- S4/S5.
- N=7–12 trong nội dung phát hành.
- Ví vàng, cứu lượt, quảng cáo thưởng.
- Mua/chọn mèo và quản lý nhiều gói mèo.
- Generator offline và mốc 30/40.
- Runtime render/bake 3D cho animation hoặc tổ hợp phụ kiện.

## 7. Blocker của Design Freeze

1. `DQ-002` và danh sách frozen/tuneable chưa được owner phê duyệt chính thức.
2. Chưa có bằng chứng M0 trên thiết bị cho input, atlas, bố cục, accessibility và baseline toolchain.
3. Chưa có sáu level release order 19–24 thật cùng runtime Hint S3 và bằng chứng blind solve/playtest M2.
4. Ranh giới package A/M0 và package B/Core cần được xác nhận khi tạo project Godot.
5. Chuỗi truy vết đã có DEC-013..016 nhưng owner/phase/evidence cho toàn bộ QA vẫn cần ma trận ký duyệt.

## 8. Hạng mục M0

- Chốt Godot minor, renderer, Android/iPhone mục tiêu và môi trường iOS.
- Đo preview X, double-tap, drag, multi-touch, background và UI scale.
- Chốt hoặc điều chỉnh 280 ms/12 điểm bằng bằng chứng.
- Đo atlas mèo mặc định: FPS, stutter, RAM/VRAM và tải.
- Kiểm bố cục N=6, vùng chạm 44×44, safe area và chữ lớn.
- Replay interaction vectors trên runtime thay vì chỉ Python reducer.

## 9. Hạng mục M1

- Xác nhận 3 tim/Undo X/X đỏ có công bằng và phù hợp tông game.
- Xác nhận scorecard 100/25 ở Result có giá trị với người chơi.
- Thử tutorial T1–T6 ở Level 1, một Hint/lượt, accessibility và reduced motion.
- Chứng minh logic band S1/S2 + S3 tạo đủ nhịp 24 level; xác nhận độ khó/thời gian.
- Biên tập và thử bốn level phát hành đầu, sau đó mốc 10/20.

## 10. Sau MVP

- N=7–12 và S4–S5 nếu qua cổng riêng.
- Vàng, cứu lượt, quảng cáo/điểm danh cấp Hint, bộ sưu tập mèo.
- Generator offline và level/mốc mới sau 24.
- Cache nhiều mèo hoặc runtime bake 3D nếu có bằng chứng nhu cầu.
