# 09 — Rà soát thiết kế 0.5.0

Luật chuẩn ở [02](02-luat-choi-va-trang-thai.md). Bảng này ghi quyết định sau đánh giá lần 1 (lịch sử: `git show pre-reset-pipeline-2026-09-27:docs/archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md`), đánh giá lần 2 (lịch sử: `git show pre-reset-pipeline-2026-09-27:docs/archive/reviews/02-danh-gia-ban-thiet-ke-v04.md`), MVP game-design review (lịch sử: `git show pre-reset-pipeline-2026-09-27:docs/reviews/01-mvp-game-design-review.md`) và phê duyệt ngày 2026-09-21. Nếu review gợi ý khác quyết định đã duyệt, bảng này và luật GR là phiên bản cần triển khai.

| Mã review | Quyết định | Tài liệu/QA liên quan |
| --- | --- | --- |
| REV-UX-01 | Một chạm đổi X **tức thì trên hình**; sau cửa sổ 280 ms mới commit. Giữ chạm/kéo đánh hoặc xóa X theo ô đầu, mỗi ô một lần. Hai chạm nhanh cùng ô hoàn tác preview và gọi một `TryCat`. | GR-09..14/29/30, UX-09..11/22/23, TECH-03/14, QA-08/09/12/43..45 |
| REV-GD-01 | MVP giữ **3 tim** và `x_error` khóa. Cho Undo đúng một action X gần nhất (một ô hoặc cả stroke), không qua `TryCat`, không Redo; Restart có xác nhận reset toàn lượt cùng level. | GR-13/16/17/19/31..33, QA-08/11/14/54/55 |
| REV-GD-02 / REV-ECO-01 | Score chỉ là scorecard ở Result, không hứa quy đổi. MVP không có wallet, vàng, cứu lượt, quảng cáo, điểm danh hoặc interface meta; luật 3 tim phải tự tạo thử thách hợp lý. | GR-17..19, D-05/08/09, QA-14..16 |
| REV-GD-03 | Generator offline theo seed/ràng buộc/trace sau MVP; biên tập duyệt level mới. Mốc 10/20 được làm thủ công trước release đầu vì ID/puzzle bất biến; generator hỗ trợ mốc mới như 30/40, không có luật thắng bí mật. | LV-07, [Kế hoạch 11](11-ke-hoach-meta-va-sinh-level.md), QA-48/49 |
| REV-TECH-01 | Chọn Godot 4.x/GDScript, tạo hoạt ảnh trong 3D rồi **render sprite sheet 2D cho runtime**. M0 đo atlas/FPS/RAM/VRAM. | TECH-18/19, ART-06..11, QA-30/34 |
| REV-TECH-02 | Ngưỡng chuyển kéo 12 điểm logic; chỉ ngón chính bắt đầu trong bàn, bỏ qua ngón phụ/chạm lòng bàn tay, nội suy đường kéo nhanh. | UX-22/23, TECH-03, QA-43..45 |
| REV-TECH-03 | Giữ trần schema N=12; release đầu N≤6. **Không zoom/pan**; N lớn chỉ mở sau thử kích thước thật trên máy mục tiêu. | LV-01, UX-18, TECH-19, QA-27/35 |
| REV-TECH-04 | S3 giao thoa là ACTIVE-MVP trong schema v4 và bắt buộc cho từng level 19–24; level 1–18 chỉ S1/S2. S4/S5 tiếp tục parked/research. | GR-07, LV-03/08, [Suy luận 10](10-nghien-cuu-quy-tac-suy-luan.md), QA-37/40/41/57 |
| REV-TECH-05 | Mọi ô `cat` và hoạt ảnh dùng mèo đang chọn; màu vùng ở bàn/hàng tiến độ, không tô lông mèo theo vùng. Dùng lại gói clip đang chọn trong phiên, nạp khi cần và giới hạn cache. Một render 3D bằng `UPDATE_ONCE` chỉ tạo ảnh tĩnh; bake animation là spike tương lai. | GR-01..08, TECH-18/20/21, ART-12/13, QA-50..52 |
| REV-GD-04 | Sau MVP, tim về 0 mở màn chờ cứu lượt: đủ vàng thì trả vàng, thiếu vàng có thể xem quảng cáo thưởng khi sẵn có, luôn có Retry miễn phí. Cứu thành công hồi 1 tim, xóa X đỏ cuối, giữ board và điểm phạt. Bản đầu vẫn theo GR-19. | [Kế hoạch 11](11-ke-hoach-meta-va-sinh-level.md), QA-47/53 |
| REV-META-01 | Vườn mèo chỉ là danh sách mèo đã mua bằng vàng để chọn mèo đang dùng. Không có Garden Lobby, petting, mèo tự về vườn sau level hoặc chọn theo mèo của ô đáp án. | [Kế hoạch 11](11-ke-hoach-meta-va-sinh-level.md), UX mở rộng, QA-52 |
| REV-GD-05 | Level 1 là tutorial duy nhất. Mỗi level có vùng luật bốn icon + chữ luôn nhìn thấy. Mỗi lượt có một Hint miễn phí; `NoHint` không tiêu thụ, Retry/Restart cấp lượt mới. | GR-21..24, UX-03/04/14, QA-20/22/33/56 |
| REV-GD-06 | Thắng khi đủ N mèo và còn ít nhất 1 tim. Mỗi level phải qua uniqueness/trace và một lượt giải mù hoàn thành với ≥1 tim; campaign còn có cổng 10 người/thiết bị/accessibility. | GR-25, LV-01..08, QA-01..07/27..29/57 |

## Trạng thái thực tế

- **Có:** GDD v0.5.0, schema level v4, fixture S2/S3 và N12 biên kỹ thuật, validator trace S2/S3, vector/test tham chiếu cử chỉ gồm Undo/Restart/Hint; đặc tả nghiên cứu S4/S5 và meta sau MVP.
- **Chưa có:** game chạy được, 24 level phát hành, asset/model/sprite, script tutorial gắn level thật, số đo Android/iOS và playtest. Đây là công việc M0–M3.
- **Rủi ro phải đo:** chạm đơn nhìn thấy X nhưng chạm đôi phải hoàn tác preview mượt; kéo qua đường nhanh phải phủ đủ ô, không nhận ngón phụ; N12 có schema nhưng có thể không đủ kích thước chạm ở màn nhỏ; atlas mèo và cache nhiều mèo có thể tốn RAM/VRAM. M0/M1 phải ghi số đo và video thao tác trên thiết bị thật.

## Ranh giới bản quyền và thay đổi

Giữ họ luật chung đã tham khảo; tên, màn, level, model, âm và sticker phải là tác phẩm gốc. Nếu đổi điểm, cử chỉ, schema hoặc tiến trình, sửa GDD/fixture/validator/QA trong cùng thay đổi; puzzle đã phát hành cần ID mới nếu đổi dữ liệu.

Bản 0.5.0 nâng schema lên v4 cho S3, chốt Undo/Restart/một Hint mỗi lượt và cô lập hoàn toàn meta khỏi MVP. Validator level không có trường mèo/vàng/quảng cáo/điểm danh; QA-46/47/52/53 chỉ là cổng nghiên cứu tương lai. Nếu sau MVP triển khai gói K, phải có quyết định phạm vi mới và thêm fixture/test cho session, progress và giao dịch cùng phiên bản save mới.
