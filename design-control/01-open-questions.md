# Câu hỏi thiết kế đang mở

Chỉ đóng một câu hỏi khi có quyết định được ghi trong
[`02-decision-log.md`](02-decision-log.md) hoặc khi nó được hủy/defer rõ ràng.
Giả thuyết hiện tại không phải quyết định.

## DQ-001 — S3 có thuộc MVP không? — CLOSED

- **DQ-ID:** DQ-001
- **Question:** Câu hỏi lịch sử: GDD v1.0 có khóa MVP ở baseline S1/S2 cũ hay đưa S3 vào release đầu?
- **Category:** Scope / puzzle rules
- **Why it matters:** S3 kéo theo schema, fixture, validator, hint, tutorial, content và QA mới.
- **Resolution:** DEC-013 chọn S3 bắt buộc cho từng order 19–24; order 1–18 chỉ S1/S2; schema v4. S4/S5 parked.
- **Options:** (A) MVP chỉ S1/S2; (B) S3 là change request có cổng trước M2; (C) đưa S3 thành yêu cầu MVP.
- **Known evidence:** Fixture S301 và validator/test S3 v4/release band đang qua.
- **Missing evidence:** Runtime Hint S3, sáu level release thật và playtest M2; đây là implementation evidence, không mở lại quyết định scope.
- **Related GDD IDs:** DEC-013, D-02, GR-07, LV-03/08, QA-37/40/41/57.
- **Blocking phase:** M2 content complete.
- **Status:** CLOSED — DEC-013.

## DQ-002 — Design Freeze khóa những gì?

- **DQ-ID:** DQ-002
- **Question:** Những trường nào là luật bị khóa, những trường nào vẫn được tune ở M0/M1, và thay đổi nào bắt buộc mở lại freeze?
- **Category:** Governance
- **Why it matters:** Nếu không phân biệt, 280 ms, điểm 100/25 hoặc S3 có thể bị hiểu sai là bất biến.
- **Current hypothesis:** Khóa scope/luật/schema/tiến trình; để tham số cảm giác và cân bằng ở trạng thái tuneable có kiểm soát.
- **Options:** (A) Freeze toàn bộ; (B) Freeze core, giữ danh sách tuneable; (C) hoãn freeze tới sau M1.
- **Known evidence:** AGENTS yêu cầu thay luật/schema/tiến trình phải cập nhật đồng bộ.
- **Missing evidence:** Tiêu chí phê duyệt và change-control chính thức.
- **Related GDD IDs:** D-01..10, O-01..07, toàn bộ GR/QA.
- **Blocking phase:** Design Freeze.
- **Status:** OPEN — BLOCKER.

## DQ-003 — Baseline kỹ thuật M0 là gì?

- **DQ-ID:** DQ-003
- **Question:** Godot minor, renderer, thiết bị/OS Android-iOS thấp mục tiêu và môi trường macOS/Xcode nào dùng để nghiệm thu?
- **Category:** Technical validation
- **Why it matters:** Không thể đánh giá FPS, stutter, RAM/VRAM hay input nếu không có baseline.
- **Current hypothesis:** Cần ít nhất một Android thấp và một iPhone mục tiêu cụ thể.
- **Options:** Chưa được liệt kê trong GDD; chọn theo thị trường/khả năng thiết bị.
- **Known evidence:** Godot 4.x được chọn; iOS cần macOS/Xcode.
- **Missing evidence:** Device matrix, OS, renderer và toolchain đã chạy.
- **Related GDD IDs:** O-02, TECH-13/19/21, QA-30/50.
- **Blocking phase:** M0.
- **Status:** OPEN.

## DQ-004 — Tham số cử chỉ nào đạt?

- **DQ-ID:** DQ-004
- **Question:** 280 ms và 12 điểm logic có cho tỷ lệ nhận đúng đủ cao trên thiết bị mục tiêu không?
- **Category:** UX / input
- **Why it matters:** Đây là thao tác cốt lõi và lỗi nhận dạng có thể trực tiếp làm mất tim.
- **Current hypothesis:** 280/12 là giá trị khởi đầu, không phải kết quả đã chứng minh.
- **Options:** Giữ; điều chỉnh theo thiết bị; điều chỉnh theo accessibility nếu có bằng chứng.
- **Known evidence:** Vector biên 279/281 ms và 11/13 điểm chạy trong Python.
- **Missing evidence:** Raw touch traces, error rate và quan sát người dùng.
- **Related GDD IDs:** GR-09..14/29/30, UX-09..11/22/23, QA-08/09/12/43..45.
- **Blocking phase:** M0.
- **Status:** OPEN.

## DQ-005 — Ngân sách sprite/atlas là bao nhiêu?

- **DQ-ID:** DQ-005
- **Question:** Kích thước atlas, frame rate, nén, RAM/VRAM, thời gian tải và cache budget nào đạt M0?
- **Category:** Art / technical performance
- **Why it matters:** Chưa có giới hạn RAM/VRAM nên QA-30/50 chưa có pass/fail đầy đủ.
- **Current hypothesis:** Một bộ clip mèo mặc định dùng chung là hướng ít rủi ro nhất.
- **Options:** Các tier atlas/frame/nén chỉ được chọn sau đo.
- **Known evidence:** Mục tiêu ≥55 FPS, không stutter >100 ms; phép tính RGBA8 lý thuyết.
- **Missing evidence:** Atlas thật và profiler trên thiết bị mục tiêu.
- **Related GDD IDs:** D-06, TECH-19/21, ART-06..13, QA-30/50.
- **Blocking phase:** M0.
- **Status:** OPEN.

## DQ-006 — Công thức điểm có nên giữ? — CLOSED VỀ VAI TRÒ

- **DQ-ID:** DQ-006
- **Question:** Hệ số 100/25 và việc hiển thị điểm có dễ hiểu, hữu ích và không làm tăng ức chế không?
- **Category:** Game design / balance
- **Why it matters:** MVP không có replay, xếp hạng hoặc economy nên điểm có thể là chỉ số chết.
- **Resolution:** DEC-016 giữ công thức làm scorecard chỉ ở Result, không quy đổi và không hiện trong puzzle. Hệ số 100/25 vẫn tuneable M1 qua decision change.
- **Options:** Giữ; tune hệ số; giảm vai trò hiển thị; thay đổi chỉ qua decision change.
- **Known evidence:** Công thức xác định rõ và không có hai nguồn điểm.
- **Missing evidence:** Người chơi có chú ý/hiểu/quan tâm hay không.
- **Related GDD IDs:** DEC-005/016, GR-18, UX-05/06, O-03, QA-16.
- **Blocking phase:** Không chặn Design Freeze; tuning M1.
- **Status:** CLOSED — vai trò/hiển thị đã chốt; tuning là research M1.

## DQ-007 — Mô hình thất bại có công bằng không? — BASELINE CLOSED

- **DQ-ID:** DQ-007
- **Question:** 3 tim, Undo chỉ cho X, X đỏ khóa và Retry toàn bàn có phù hợp với tông game không?
- **Category:** Game feel
- **Why it matters:** Review đã nhận diện nguy cơ rage quit, nhất là cuối level 6×6.
- **Resolution:** DEC-014/016 chốt baseline luật cho MVP; cảm giác công bằng vẫn phải được kiểm chứng và có thể mở change request sau M1.
- **Options:** Giữ; thay đổi chỉ sau playtest và decision/GDD update chính thức.
- **Known evidence:** Interaction contract v2 kiểm Undo/Restart; luật 3 tim/X đỏ đã chốt độc lập meta.
- **Missing evidence:** Tỷ lệ bỏ cuộc, cảm nhận công bằng và lỗi fat-finger.
- **Related GDD IDs:** DEC-014/016, D-08, GR-13/16/17/19/31..33, QA-11/14/54/55.
- **Blocking phase:** Không chặn Design Freeze; validation M1.
- **Status:** CLOSED — baseline; VALIDATION-PENDING M1.

## DQ-008 — Band S1/S2 + S3 có đủ chất lượng cho 24 level không?

- **DQ-ID:** DQ-008
- **Question:** Có thể tạo 18 level S1/S2 và 6 level cuối thực sự cần S3, đều hấp dẫn, dễ đọc và không lạm dụng givens không?
- **Category:** Puzzle/content design
- **Why it matters:** Đây là rủi ro chất lượng nội dung chính sau khi scope S3 đã chốt.
- **Current hypothesis:** Logic band tạo đủ không gian thiết kế; vẫn cần corpus và blind solve để chứng minh.
- **Options:** Biên tập lại bố cục/givens trong band; thay level không đạt; không hạ cổng S3 hoặc thêm S4/S5.
- **Known evidence:** T01/E01/E02 có trace S2; S301 có trace S3→S2 hợp lệ.
- **Missing evidence:** Candidate pool 24 level, chỉ số solver và playtest.
- **Related GDD IDs:** DEC-013, D-02, LV-02/03/05/08, QA-01..07/37/40/41/57.
- **Blocking phase:** M1.
- **Status:** OPEN.

## DQ-009 — Tiêu chí đạt của từng level là gì? — CLOSED

- **DQ-ID:** DQ-009
- **Question:** Ngưỡng completion, hint, lỗi, đoán, thời gian và perceived fairness nào làm một level đạt?
- **Category:** Acceptance / content
- **Why it matters:** “Có một lượt blind solve” chưa đủ phân biệt level hợp lệ với level tốt.
- **Resolution:** Level đạt khi tìm đủ mèo và còn ≥1 tim; content gate yêu cầu vùng liên thông, nghiệm duy nhất, trace đúng logic band, không đoán và một blind solve ≥1 tim có biên bản thời gian/lỗi/Hint/điểm kẹt. Campaign qua thêm playtest 10 người, device và accessibility gate.
- **Options:** Chốt một bộ ngưỡng chung; hoặc ngưỡng theo band/level role.
- **Known evidence:** Có mục tiêu thời gian và yêu cầu 10 người ở release gate.
- **Missing evidence:** Biên bản của 24 level thật và báo cáo playtest; đây là M2 evidence, không còn thiếu định nghĩa.
- **Related GDD IDs:** DEC-016, GR-25, LV-05/08, QA-33/49/57, GDD/07 §5.
- **Blocking phase:** M2 content complete.
- **Status:** CLOSED — DEC-016/GDD 07.

## DQ-010 — Nhận diện phát hành là gì?

- **DQ-ID:** DQ-010
- **Question:** Tên phát hành, logo và art identity gốc nào được chọn?
- **Category:** Product/art
- **Why it matters:** Chặn asset cuối và kiểm tra bản quyền thương hiệu.
- **Current hypothesis:** “Vườn Mèo” chỉ là tên tạm.
- **Options:** Chưa được đề xuất trong canonical GDD.
- **Known evidence:** Art direction “khu vườn tươi sáng, vui”.
- **Missing evidence:** Naming/brand review.
- **Related GDD IDs:** O-01, ART-01..05.
- **Blocking phase:** Trước art cuối/M1.
- **Status:** OPEN.

## DQ-011 — Level 10/20 phải tạo trải nghiệm gì?

- **DQ-ID:** DQ-011
- **Question:** Motif, nhịp suy luận và sticker cụ thể nào khiến level 10/20 đặc biệt mà không đổi luật?
- **Category:** Content milestone
- **Why it matters:** Yêu cầu hiện tại nêu vị trí nhưng chưa có acceptance riêng ngoài review người.
- **Current hypothesis:** Làm thủ công trong tập quy tắc đã học.
- **Options:** Motif hình, nhịp trace hoặc khoảnh khắc suy luận; chưa chốt.
- **Known evidence:** LV-07 và QA-49 khóa vị trí/mục đích.
- **Missing evidence:** Level thật và playtest.
- **Related GDD IDs:** LV-07, O-06, QA-36/49.
- **Blocking phase:** M1/M2.
- **Status:** OPEN.

## DQ-012 — Accessibility được nghiệm thu thế nào?

- **DQ-ID:** DQ-012
- **Question:** Quy trình nào chứng minh grayscale, chữ lớn, reduced motion và screen reader đạt?
- **Category:** UX/accessibility
- **Why it matters:** Yêu cầu đã có nhưng chưa có protocol và ngưỡng người dùng.
- **Current hypothesis:** QA chức năng cần bổ sung bằng thử nghiệm với assistive technology.
- **Options:** Test chuyên gia; user test; kết hợp hai nguồn.
- **Known evidence:** Contrast/touch targets và action ngữ nghĩa đã đặc tả.
- **Missing evidence:** Prototype và báo cáo accessibility.
- **Related GDD IDs:** UX-16..21, ART-03/11, QA-27..29/36.
- **Blocking phase:** M1.
- **Status:** OPEN.

## DQ-013 — Có phát hành N=7–12 không?

- **DQ-ID:** DQ-013
- **Question:** N=7–12 có phù hợp điện thoại dọc không zoom/pan hay chỉ giữ làm schema/tooling?
- **Category:** Future scope
- **Why it matters:** Có ảnh hưởng palette, solver, accessibility và nội dung tương lai.
- **Current hypothesis:** Không thuộc MVP; N12 hiện chỉ là fixture biên.
- **Options:** Không phát hành; phát hành theo thiết bị/bố cục; giới hạn N thấp hơn sau nghiên cứu.
- **Known evidence:** Schema/validator nhận N12; fixture N12 được giải sẵn.
- **Missing evidence:** Puzzle thật, UI, touch, solver và thiết bị.
- **Related GDD IDs:** O-04, LV-01, UX-18, QA-35/42.
- **Blocking phase:** Sau MVP.
- **Status:** DEFERRED.

## DQ-014 — Economy/meta sau MVP có hình dạng nào?

- **DQ-ID:** DQ-014
- **Question:** Công thức vàng, giá cứu lượt/mèo và khả năng quảng cáo thưởng nào bền vững?
- **Category:** Future economy/meta
- **Why it matters:** Không thể chốt trước dữ liệu hoàn thành/điểm của MVP.
- **Current hypothesis:** Hint vẫn miễn phí; Retry luôn miễn phí; các giá trị khác chưa chốt.
- **Options:** Được mô tả ở GDD/11 nhưng chưa có lựa chọn được phê duyệt.
- **Known evidence:** Rủi ro poverty trap và yêu cầu idempotency đã biết.
- **Missing evidence:** Dữ liệu 24 level, cohort người chơi và khả năng SDK/quyền riêng tư.
- **Related GDD IDs:** D-09/10, O-05/07, QA-46/47/52/53.
- **Blocking phase:** Sau MVP.
- **Status:** DEFERRED.
