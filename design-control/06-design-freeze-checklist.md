# Checklist GDD v1.0 Design Freeze

## 1. Ý nghĩa của Design Freeze

GDD v1.0 Design Freeze khóa **phạm vi MVP, luật gameplay, state model, schema dữ
liệu phát hành, tiến trình, ranh giới module và cổng nghiệm thu**. Design Freeze
không đồng nghĩa content complete hoặc release ready.

Các tham số được ghi rõ là **tuneable** có thể tiếp tục được đo ở M1. Mọi thay
đổi làm đổi luật, schema, tiến trình, điểm hoặc phạm vi MVP phải mở decision
change và tuân thủ yêu cầu đồng bộ của `AGENTS.md`.

## 2. Điều kiện bắt buộc — thẩm quyền và trạng thái

- [x] Có thứ tự ưu tiên canonical: GDD/02 → GDD/09 → GDD/README → GDD khác → review lịch sử.
- [x] Root README, GDD README và design status ghi cùng baseline v0.5.0.
- [ ] Không còn câu mô tả mèo tô/mã hóa theo màu vùng trong tài liệu hiện hành.
- [ ] Mọi review có trạng thái `resolved`, `deferred`, `rejected` hoặc `open` khớp GDD/09.
- [ ] Không còn link lịch sử sai workspace làm đường dẫn chính.
- [ ] Mọi câu hỏi có `blocking phase=Design Freeze` đã CLOSED hoặc DEFERRED bằng DEC có thẩm quyền.
- [ ] Có định nghĩa rõ danh sách frozen và tuneable được phê duyệt cho v1.0.

## 3. Điều kiện bắt buộc — phạm vi MVP

- [x] MVP được giới hạn ở 24 level tuyến tính, N=4–6, offline và không level select/replay.
- [x] DEC-013 chốt S3 bắt buộc cho order 19–24, schema v4; order 1–18 chỉ S1/S2.
- [ ] S4/S5, N>6, wallet, ads, rescue, collection, multi-cat cache và generator được đánh dấu POST-MVP/PARKED ở mọi kế hoạch liên quan.
- [ ] Package A/M0 và package B/Core có ranh giới đầu ra không chồng chéo hoặc mâu thuẫn.
- [ ] Mốc 10/20 được giữ là content requirement, không kéo thêm luật/meta vào MVP.

## 4. Điều kiện bắt buộc — luật và hợp đồng

- [x] GR-01..33 có nguồn chuẩn duy nhất ở GDD/02.
- [x] Schema level v4, fixture và validator thống nhất với S1/S2/S3 hiện hành.
- [x] Bốn trạng thái ô, given flag, tim, scorecard Result-only, Hint, thắng/thua, Retry/Restart và Undo X được mô tả.
- [x] Preview, committed action và save state được phân biệt trong đặc tả.
- [ ] Mọi giá trị provisional như 280 ms, 12 điểm, 100/25 và 0,7 giây được gắn nhãn tuneable cùng phase/owner.
- [ ] Có một trace matrix kiểm được cho `REV → DEC/D → GR/UX/LV/TECH/ART → QA`.

## 5. Điều kiện bắt buộc — acceptance criteria

- [ ] Có device/OS/renderer baseline cho M0.
- [ ] Có pass/fail threshold cho gesture misrecognition, accidental `TryCat` và task completion.
- [x] Có per-level content acceptance: đủ mèo với ≥1 tim, uniqueness, trace đúng band, không đoán, blind solve có biên bản thời gian/lỗi/Hint/điểm kẹt; campaign gate tách riêng.
- [ ] Sáu level release order 19–24 thật có S3 cần thiết, runtime Hint giải thích được và biên bản blind solve/playtest M2.
- [ ] Có protocol nghiệm thu grayscale, chữ lớn, reduced motion và screen reader.
- [ ] Có định nghĩa bằng chứng tối thiểu cho art originality/licensing manifest.
- [ ] Mọi QA bắt buộc của MVP có owner role, phase và loại bằng chứng.

## 6. Điều kiện bằng chứng M0 trước khi tuyên bố freeze

- [ ] Godot minor, renderer và toolchain Android/iOS đã được chốt bằng build thử.
- [ ] Interaction prototype replay được contract v2 cho QA-08..12/43..45/54..56 trên thiết bị mục tiêu.
- [ ] 280 ms/12 điểm được giữ hoặc thay bằng kết quả đo có decision record.
- [ ] Preview/rollback không tạo state trung gian bền vững hoặc nhân đôi `TryCat`.
- [ ] Atlas mèo mặc định có số đo FPS, stutter, RAM/VRAM và thời gian tải đạt budget đã chốt.
- [ ] Board N=6 đạt vùng chạm, safe area và chữ lớn trên device matrix.
- [ ] Vùng vẫn phân biệt được khi mọi cat dùng cùng mèo mặc định.

## 7. Hạng mục được phép còn mở sau freeze

Các mục dưới đây không chặn freeze nếu đã có DQ, owner, phase, evidence plan và
không âm thầm thay scope/rule/schema:

- [ ] Tune score 100/25 ở M1.
- [ ] Tune feedback timing ở M1.
- [ ] Nhịp khó/thời gian của 24 level.
- [ ] Cảm giác công bằng của 3 tim/Undo X/X đỏ.
- [ ] Tutorial Level 1/một Hint mỗi lượt/accessibility validation.
- [ ] Chi tiết motif/sticker level 10/20.
- [ ] Tên phát hành và art identity trước art cuối.

Nếu một kết quả M1 yêu cầu đổi luật, schema, tiến trình hoặc phạm vi, Design
Freeze phải được mở lại bằng DEC mới; không được xử lý như tuning thường.

## 8. Hạng mục không thuộc freeze MVP

- [x] S4/S5 được PARKED.
- [x] N=7–12 release được POST-MVP.
- [x] Wallet/vàng/cứu lượt/quảng cáo được POST-MVP.
- [x] Bộ sưu tập/chọn nhiều mèo được POST-MVP.
- [x] Generator/mốc 30/40 được POST-MVP.
- [x] Runtime 3D bake/phụ kiện tổ hợp được PARKED.

## 9. Kiểm tra hồ sơ trước ký freeze

- [ ] `00-design-status.md` không còn blocker mở.
- [ ] `01-open-questions.md` không còn câu hỏi `OPEN — BLOCKER`.
- [ ] `02-decision-log.md` chỉ chứa quyết định thực, có nguồn và trạng thái.
- [ ] `03-risk-register.md` có owner/phase cho mọi rủi ro High impact.
- [ ] `04-assumptions.md` không trình bày giả định như sự thật đã chứng minh.
- [ ] `05-research-backlog.md` không để POST-MVP/PARKED lọt vào gate MVP.
- [ ] Validator fixture và toàn bộ test hiện hành chạy qua.
- [ ] Không có thay đổi canonical không được ghi bằng DEC và truy vết sang QA.

## 10. Phê duyệt GDD v1.0

Chỉ tuyên bố **GDD v1.0 Design Freeze** khi mọi checkbox bắt buộc ở §2–6 và §9
đã hoàn thành. Hồ sơ phê duyệt phải ghi:

- Ngày freeze và commit/revision được xét.
- Design owner xác nhận scope/rules.
- Technical owner xác nhận M0 feasibility evidence.
- UX owner xác nhận interaction/accessibility gates.
- Puzzle/content owner xác nhận content acceptance framework.
- QA owner xác nhận traceability và evidence coverage.
- Danh sách tuneable M1 còn mở và điều kiện mở lại freeze.
