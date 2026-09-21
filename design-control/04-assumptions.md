# Assumption Register

Các mục dưới đây **không phải quyết định dự án**. Một giả định chỉ được chuyển
thành quyết định khi có bằng chứng và được ghi vào `02-decision-log.md`.

| ASM-ID | Assumption | Basis | Why it is not a decision | Evidence available | Validation | Status |
| --- | --- | --- | --- | --- | --- | --- |
| ASM-001 | Optimistic X preview sẽ tạo cảm giác tức thì mà không gây nháy khó chịu khi rollback | REV-UX-01 | Chưa có hình ảnh/runtime | Vector logic | Quan sát frame-by-frame trên thiết bị | OPEN-M0 |
| ASM-002 | 280 ms và 12 điểm logic phù hợp đa số người chơi/thiết bị | Giá trị khởi đầu trong GDD | O-02 nói phải playtest | Boundary vectors | Touch traces và error rate | OPEN-M0 |
| ASM-003 | `event.index == 0` đại diện ổn định cho ngón chính | Thiết kế gesture hiện hành | Phụ thuộc platform/event stream | Mô hình Python | Device event logging | OPEN-M0 |
| ASM-004 | Một atlas mèo mặc định đạt FPS/RAM/VRAM mục tiêu | Pipeline sprite đã chọn | Chưa có atlas thật | Ước lượng texture | Profiler Android/iPhone | OPEN-M0 |
| ASM-005 | Vùng vẫn dễ đọc khi mọi cat dùng cùng ngoại hình | REV-TECH-05 | Chưa có board visual | Nhãn/họa tiết được đặc tả | Recognition test | OPEN-M0 |
| ASM-006 | Board 6×6 vẫn đạt vùng chạm 44×44 với toàn bộ UI | UX-18 | Chưa có layout thiết bị thật | Yêu cầu kích thước | Device layout test | OPEN-M0 |
| ASM-007 | 3 tim/Undo X một bước/X đỏ khóa được cảm nhận là công bằng | DEC-014/016 | Đây là quyết định luật, không phải bằng chứng cảm giác | Review + contract v2 | Playtest level dài | OPEN-M1 |
| ASM-008 | Scorecard 100/25 ở Result có ý nghĩa dù không replay/economy | GR-18/O-03 | Hệ số được để mở cân bằng | Công thức và vai trò rõ | Comprehension/motivation test | OPEN-M1 |
| ASM-009 | 24 level tuyến tính đủ giá trị cho release đầu | D-01 | Chưa có campaign hoặc tổng thời gian thật | Mục tiêu thời lượng | Completion/satisfaction data | OPEN-M1 |
| ASM-010 | Band 18 level S1/S2 + 6 level cần S3 đủ tạo campaign thú vị, dễ đọc | DEC-013/LV-08 | Fixture kỹ thuật không đại diện campaign | T01/E01/E02/S301 | Corpus, solver metrics, blind solve ≥1 tim | OPEN-M1/M2 |
| ASM-011 | Tutorial T1–T6 trong Level 1 giúp ít nhất 8/10 người mới hiểu luật/cử chỉ | DEC-015, 01 §4, 03 §4 | Chưa có script level thật | Tutorial spec | Novice playtest | OPEN-M1 |
| ASM-012 | Progress/session/hash/atomic-write design phù hợp platform | TECH-06/08..15 | Chưa có save runtime | Failure scenarios rõ | Fault-injection tests | OPEN-M1 |
| ASM-013 | Duplicate geometry window 8 level đủ bảo đảm đa dạng | LV-04 | Đây là heuristic biên tập | Canonicalization test | Campaign diversity review | OPEN-M1 |
| ASM-014 | N=7–12 có thể dùng không zoom/pan trên một số thiết bị | O-04 | Chỉ có schema fixture | N12 validator pass | Future usability study | DEFERRED |
