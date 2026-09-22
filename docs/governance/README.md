# Quy chuẩn quản trị tài liệu và quyết định kỹ thuật (Design Governance)

Tài liệu này xác lập cơ chế quản trị, thẩm quyền và quy tắc cập nhật tài liệu trong dự án ASOL-Game-02.

## 1. Thẩm quyền tài liệu (Document Authority Hierarchy)

Khi có mâu thuẫn hoặc cần ra quyết định kỹ thuật, áp dụng theo thứ tự ưu tiên giảm dần:

1. **CANONICAL (`GDD/`):** Tài liệu thiết kế chuẩn mực. Mọi quyết định gameplay, công thức điểm, quy tắc suy luận tuân thủ theo GDD.
2. **ACTIVE Governance (`docs/governance/`):** Nhật ký quyết định, thanh ghi rủi ro, phân loại tài liệu theo [`document-register.toml`](document-register.toml).
3. **Work Packages (`work/packages/`):** Hợp đồng kỹ thuật ràng buộc phạm vi và tiêu chí nghiệm thu của từng gói việc.
4. **Evidence & Handoffs (`work/evidence/`, `work/handoffs/`):** Bằng chứng thực thi và biên bản bàn giao có chữ ký nghiệm thu.
5. **Current Reviews (`docs/reviews/`):** Các đánh giá thiết kế hiện hành.
6. **Archive (`docs/archive/`):** Lịch sử thiết kế và tài liệu cũ; chỉ mang tính tham khảo lịch sử, không dùng làm căn cứ triển khai.

## 2. Phân loại trạng thái tài liệu

- `CANONICAL`: Nguồn chân lý chuẩn, bắt buộc tuân thủ.
- `ACTIVE`: Tài liệu quản trị hoặc hướng dẫn đang có hiệu lực.
- `PROPOSED`: Đề xuất đang xem xét hoặc tính năng nghiên cứu hậu MVP (Post-MVP).
- `SUPERSEDED`: Đã bị thay thế bởi phiên bản tài liệu mới hơn.
- `HISTORICAL`: Tài liệu lưu trữ lịch sử phát triển.

## 3. Quy trình thay đổi thiết kế

Mọi thay đổi liên quan đến luật gameplay, schema dữ liệu, cơ chế điểm hoặc phân bố độ khó phải:
1. Được phân công qua một work package loại `design-change` hoặc `governance`.
2. Cập nhật đồng thời GDD, test suite, validator và sample fixtures trong cùng một commit.
