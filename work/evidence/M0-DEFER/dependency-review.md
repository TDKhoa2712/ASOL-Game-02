# M0-DEFER — rà dependency và quyết định mở triển khai M1

Ngày rà: 2026-09-24. Quyết định thẩm quyền: `DEC-018` trong `docs/governance/02-decision-log.md` và chú thích GDD 08. M0-A01/M0-A02 đã `done`; M0-A03 vẫn `blocked` vì thiếu kiểm chứng iOS, atlas/ngân sách đại diện và các phép đo cần thiết. Ảnh probe Redmi bổ sung nằm ở commit M0-A03 `bdf8e8b`; một lần đo mẫu không thay nghiệm thu M0.

## Nút chặn trước thay đổi

`M0-A03 → M0-GATE → mọi package M1 triển khai/content → M1-GATE`. M0-GATE yêu cầu M0-A03 `done` và đủ bằng chứng Android/iPhone thật. Vì pipeline chỉ cho start khi dependency `done`, việc thiếu iOS chặn cả core/loader dù phần logic có thể kiểm chứng độc lập.

## Dependency sau thay đổi

| Package | Trước | Sau | Ý nghĩa |
| --- | --- | --- | --- |
| M0-DEFER | Chưa có | M0-A02, M0-REPLAN | Quyết định governance cho phép xây dựng có điều kiện; không nhận QA thiết bị |
| M1-A01 | M0-GATE | M0-DEFER | Core/score có thể bắt đầu sau M0-DEFER |
| M1-A02 | M0-GATE | M0-DEFER | Loader/schema/S3 có thể bắt đầu sau M0-DEFER |
| M1-C01 | M0-GATE, M1-A02 | M0-DEFER, M1-A02 | Nội dung gốc chờ loader |
| M1-A03 | M0-GATE, M1-A01, M1-A02 | M0-DEFER, M1-A01, M1-A02 | Save chờ core và loader |
| M1-A04 | M0-GATE, M1-A01, M1-A02, M1-A03 | M0-DEFER, M1-A01, M1-A02, M1-A03 | Hint chờ state/session |
| M1-A05 | M0-GATE, M1-A01, M1-A02, M1-A03, M1-A04 | M0-DEFER, M1-A01, M1-A02, M1-A03, M1-A04 | UI dùng probe/art tạm, không khẳng định mobile QA |
| M1-A06 | M0-GATE, M1-A03, M1-A04, M1-A05, M1-C01 | M0-DEFER, M1-A03, M1-A04, M1-A05, M1-C01 | Tutorial chờ UI và Level 1 thật |
| M0-GATE | M0-A02, M0-A03 | **Không đổi** | Vẫn chờ nghiệm thu M0-A03 |
| M1-GATE | M0-GATE và toàn bộ package M1 | **Không đổi** | Không thể nghiệm thu vertical slice khi M0-GATE chưa đạt |

Sau khi M0-DEFER được accept, **chỉ M1-A01 và M1-A02** có đủ dependency để start ngay. Các package M1 còn lại vẫn đi theo thứ tự nội bộ. M1-PLAN hiện ở `review`; nội dung hợp đồng, bản đồ package và handoff của nó được cập nhật theo DEC-018 để reviewer không dùng dependency cũ. Việc thay đổi package M1 không tự accept M1-PLAN.

## Ranh giới giữ nguyên

- `M0-A03` vẫn `blocked`; không sửa hợp đồng, state hoặc số đo của package đó trong M0-DEFER.
- `M0-GATE` vẫn yêu cầu Android/iPhone mục tiêu, OS, build/run iOS trên macOS/Xcode và số đo TECH-13/19/21/QA-50; không thay bằng emulator, headless hoặc một ảnh Redmi.
- `M1-GATE` vẫn chờ `M0-GATE` và các package M1 `done`; M2/M3/release không được mở từ ngoại lệ này.
- Core/loader có thể kiểm chứng logic ngay; UI/art có thể cần chỉnh lại khi atlas sản xuất, RAM/VRAM, safe area và thiết bị iOS được đo. Mọi handoff M1 phải nêu rủi ro mở này.
- M1-A05 chỉ nghiệm thu phần implementation và test bố cục/accessibility trong scene; các kiểm chứng safe area, vùng chạm, chữ lớn, thang xám, reduced motion và đọc màn hình trên Android/iPhone mục tiêu được ghi rõ tại M1-GATE. Không đánh dấu các QA đó pass từ editor/headless.
