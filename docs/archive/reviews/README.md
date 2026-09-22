> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# Design Reviews & Architecture Backlog

Thư mục này chứa các tài liệu rà soát, phản biện chuyên sâu và kiến nghị cải tiến về **Game Design**, **User Experience (UX)** và **Kiến trúc Kỹ thuật** cho dự án "Vườn Mèo".

## Mục đích cho các Agent

Trước khi bắt đầu bất kỳ gói việc nào trong [GDD/08](../GDD/08-ke-hoach-trien-khai-cho-agent.md), Agent đọc các review để nắm rủi ro. Review là bằng chứng lịch sử, không tự tạo luật. Resolution mới nhất nằm ở [MVP game-design review](../design-control/reviews/01-mvp-game-design-review.md), [GDD/09](../GDD/09-ra-soat-thiet-ke.md) và DEC-013..016; nếu nội dung cũ khác GDD v0.5.0 thì nội dung cũ đã bị supersede.

## Danh mục tài liệu

| Tài liệu | Ngày lập | Nội dung chính |
| :--- | :---: | :--- |
| [01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md](01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md) | 2026-09-18 | Rà soát toàn diện GDD v0.3: Độ trễ input 280ms (`REV-UX-01`), cơ chế phạt 3 tim & `x_error` (`REV-GD-01`), rủi ro SubViewport 3D trên mobile (`REV-TECH-01`), meta-game (`REV-GD-03`), v.v. |
| [02-danh-gia-ban-thiet-ke-v04.md](02-danh-gia-ban-thiet-ke-v04.md) | 2026-09-18 | Rà soát GDD v0.4 và quyết định sau góp ý ở GDD v0.4.2: vàng cứu lượt/mua mèo, quảng cáo thưởng khi thiếu vàng, Vườn mèo là danh sách bộ sưu tập, mèo hiển thị theo lựa chọn người chơi. |
| [01-mvp-game-design-review.md](../design-control/reviews/01-mvp-game-design-review.md) | 2026-09-21 | Review 15 vấn đề và bảng Resolution theo GDD v0.5.0: S3 bắt buộc 19–24, Restart/Undo X, một Hint/lượt, tutorial Level 1 và Pure MVP Isolation. |

## Quy tắc cho Agent khi cập nhật hoặc xử lý vấn đề
1. Khi một đề xuất được chốt, cập nhật mã tương ứng và dẫn DEC/GDD/QA; không sửa lịch sử thành luật mới.
2. Mọi thay đổi về luật, cơ chế hoặc schema phải tuân thủ [AGENTS.md](../AGENTS.md): cập nhật đồng thời GDD, `levels.sample.json`, validator/test và QA.
