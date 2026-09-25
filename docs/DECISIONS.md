# Quyết định điều hành hiện hành

## RST-002 — Duyệt cải tổ và mở R1

Ngày 2026-09-25. Chủ dự án xác nhận: giữ 24 level cho bản đầu, Endless để sau; tích hợp cải tổ về dev và kết thúc tạm ngưng để bắt đầu R1.

- Tích hợp nhánh refactor/project-reset vào dev bằng fast-forward sau kiểm chứng tài liệu.
- Triển khai R1 trên nhánh ngắn từ dev theo kế hoạch đã duyệt; một agent chính, không khởi động lại package cũ.
- Không thay luật, schema, tiêu chí QA hoặc loại iOS. Endless/meta/generator không thuộc bản đầu.
- RST-002 thay hiệu lực tạm ngưng của RST-001; nhận định lịch sử trong review vẫn giữ thời điểm khảo sát.

## RST-001 — Tạm ngưng, hợp nhất dev và cải tổ trên nhánh riêng

Ngày: 2026-09-24. Căn cứ: chủ dự án yêu cầu tạm ngưng công việc, gom code/nhánh về dev, cải tổ trên nhánh từ dev và xóa nhánh không cần thiết.

- Bảo toàn công việc tại dev `008f0d962d291ca6d5614f6613e8129b64673f41`. Nhánh `refactor/project-reset` dành cho cấu trúc, tổ chức, quy trình, rà thiết kế và kế hoạch.
- Tạm ngưng triển khai game/content/asset; không tự tiếp tục package cũ. Các state cũ giữ nguyên để bảo toàn lịch sử, không phải trạng thái điều hành hiện tại.
- Giao việc mới theo kết quả và phạm vi đã được giao, không bắt buộc ID package hay vòng start/verify/handoff/accept. Quy tắc hiện hành ở [AGENTS](../AGENTS.md).
- Kế hoạch cũ GDD 08 và quy định quy trình trong governance/work được thay thế bởi [ROADMAP](ROADMAP.md). Quyết định này chỉ có trên nhánh cải tổ cho đến khi tích hợp về dev.
- Các yêu cầu sản phẩm/QA của GDD vẫn giữ. Việc bỏ gate M0/M1 không tuyên bố QA thiết bị đã đạt và không giảm tiêu chí phát hành.
- Giữ main, dev và nhánh cải tổ; xóa tên các nhánh work đã được bảo toàn. Giữ stash và hồ sơ lịch sử; chưa cần xóa hoặc di chuyển hàng loạt tài liệu.

Những thay đổi luật, UX contract, schema và phạm vi sản phẩm sẽ được rà riêng trong R0. Chưa có quyết định thay đổi nào thuộc các phần này trong đợt hợp nhất nhánh.
