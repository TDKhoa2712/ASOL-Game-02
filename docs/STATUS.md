# Trạng thái dự án

Cập nhật: 2026-09-25. **Tạm ngưng mọi triển khai game, nội dung và asset; đang cải tổ tổ chức dự án.** Không tự khởi động lại các package cũ.

## Nền hiện tại

- `dev`: `008f0d962d291ca6d5614f6613e8129b64673f41`, chứa toàn bộ lịch sử các nhánh công việc và file đang làm được bảo toàn.
- Nhánh cải tổ: `refactor/project-reset`, tách từ dev; chưa đưa thay đổi quy trình trở lại dev.
- `main` giữ mốc cũ; không coi đây là bản phát hành đã nghiệm thu.
- Có client Godot và bốn level; chủ dự án xác nhận còn rời rạc và chưa ổn định. Không có build được chứng nhận chơi liền mạch trong đợt này.
- Không có remote được cấu hình. Hai stash cũ được giữ nguyên; file untracked trong đó trùng byte với nội dung đã lưu ở dev. Phần state M1-A07 trong stash là ảnh chụp cũ, không ghi đè trạng thái về sau.

## Công việc hiện tại

R0: gom nhánh, bảo toàn công việc, dọn nhánh đã hợp nhất, thay điểm vào tài liệu và thiết lập kế hoạch cải tổ. Chi tiết nhánh và cách khôi phục tại [biên bản hợp nhất](BRANCH-CONSOLIDATION.md).

## Các vấn đề được chuyển từ hồ sơ cũ

| Vấn đề | Cách xử lý kế tiếp |
| --- | --- |
| Luồng chơi bốn level chưa được chứng minh liền mạch | R1 sau khi chủ dự án cho tiếp tục triển khai |
| Evidence A12 ghi smoke `Status label is clipped` còn fail | Tái hiện cùng các lỗi UI/input trong R1; chưa sửa trong đợt này |
| Tutorial còn cần kiểm kết nối gesture/milestone thực tế | Kiểm tích hợp ở R1, người mới ở R2 |
| Thiếu kiểm thử thiết bị/asset đại diện và nguồn lực iOS | Lập danh sách người/thiết bị trong R0; giữ QA nền tảng ở R4 |
| Phạm vi 24 level và đề xuất Endless cần được phân biệt | Giữ GDD hiện hành; chỉ đổi phạm vi khi chủ dự án quyết định |

## Kiểm chứng và bước tiếp theo

Đợt này kiểm Git, bảo toàn file, diff tài liệu, đăng ký tài liệu và liên kết. Không chạy lại game, không kết luận gameplay đã ổn định từ thao tác gom nhánh.

Đã soạn [rà thiết kế và cấu trúc đích](reviews/05-design-and-structure-review.md) và [kế hoạch nghiệm thu R1](plans/R1-playable-loop.md), dựa trên khảo sát tĩnh tại `1600898`. Chưa chạy kiểm chứng gameplay mới.

Bước tiếp theo: chủ dự án review kế hoạch và lựa chọn phạm vi 24 level/Endless; tích hợp cải tổ về dev khi được giao. Khi chưa có quyết định thay đổi, GDD 24 level vẫn áp dụng. Chưa tuyên bố toàn bộ R0 hoàn tất, chưa bắt đầu R1 khi lệnh tạm ngưng còn hiệu lực.
