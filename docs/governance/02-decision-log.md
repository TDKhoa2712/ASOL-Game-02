# Nhật ký quyết định thiết kế

Chỉ ghi các quyết định đã có trong GDD hiện hành/GDD 09. Các DEC ngày
2026-09-18 là baseline v0.4.2; DEC-013..016 ngày 2026-09-21 tạo baseline v0.5.0. DEC-017 ngày 2026-09-22 bổ sung governance cho Design Freeze mà không đổi luật GDD.

## DEC-001 — Campaign tuyến tính 24 level

- **DEC-ID:** DEC-001
- **Date:** 2026-09-18
- **Decision:** MVP có 24 level gốc, `order=1..24`, N=4–6; không chương, chọn level, chơi lại hay bỏ qua.
- **Alternatives considered:** Bản đồ/chương, replay, mở khóa sao và meta được review đề xuất nhưng không chọn cho MVP.
- **Rationale:** Giảm scope và giữ tiến trình/save đơn giản trước khi core puzzle được chứng minh.
- **Evidence:** Đặc tả nhất quán; validator có release gate order/N. Chưa có campaign/playtest.
- **Affected GDD IDs:** D-01, GR-26..28, UX-01, LV-01, QA-01.
- **Status:** ACTIVE — MVP.

## DEC-002 — Baseline lịch sử trước v0.5 chỉ dùng S1/S2

- **DEC-ID:** DEC-002
- **Date:** 2026-09-18
- **Decision:** Baseline hiện hành chỉ chấp nhận trace S2; S1 là chứng cứ loại trừ dựng từ trạng thái.
- **Alternatives considered:** Đưa S3 sớm vào MVP; S4/S5.
- **Rationale:** Chỉ phát hành quy tắc có proof trace, hint và QA giải thích được.
- **Evidence:** Fixture/validator/test S2 đang qua. S3+ chỉ có đặc tả nghiên cứu.
- **Affected GDD IDs:** D-02, GR-07/21..24, LV-03, TECH-04, QA-05/18..20.
- **Status:** SUPERSEDED ngày 2026-09-21 bởi DEC-013; chỉ giữ làm lịch sử.

## DEC-003 — Optimistic X preview và double-tap cùng ô

- **DEC-ID:** DEC-003
- **Date:** 2026-09-18
- **Decision:** Tap đầu hiện X/clear ngay; double-tap cùng ô hoàn tác preview và gọi một `TryCat`; drag lấy mode từ ô đầu.
- **Alternatives considered:** Chờ 280 ms mới hiện X, tool toggle, long press đặt mèo.
- **Rationale:** Giữ phản hồi tức thì mà không đổi mô hình X/mèo.
- **Evidence:** 16 interaction vectors tham chiếu; chưa có runtime/device test.
- **Affected GDD IDs:** D-04, GR-09..14/29/30, UX-09..11/22/23, QA-08/09/12/43..45.
- **Status:** ACTIVE — tham số 280 ms/12 điểm là PROVISIONAL.

## DEC-004 — Baseline lịch sử: ba tim, không Undo, X đỏ khóa

- **DEC-ID:** DEC-004
- **Date:** 2026-09-18
- **Decision:** MVP giữ 3 tim, không Undo; thử sai tạo `x_error` cố định đến Retry; Retry cùng level miễn phí.
- **Alternatives considered:** Undo 1–3 bước, casual/challenge mode, cho xóa X đỏ, cứu lượt trong MVP.
- **Rationale:** Giữ luật/state MVP nhỏ; cứu lượt được tách sang post-MVP.
- **Evidence:** Quyết định REV-GD-01 và contract tham chiếu. Chưa có playtest công bằng/cảm xúc.
- **Affected GDD IDs:** D-08, GR-13/16/17/19, QA-11/14.
- **Status:** PARTIALLY SUPERSEDED ngày 2026-09-21: ba tim/X đỏ vẫn giữ qua DEC-016; “không Undo” bị thay bởi DEC-014.

## DEC-005 — Công thức điểm lượt hiện tại

- **DEC-ID:** DEC-005
- **Date:** 2026-09-18
- **Decision:** `score=max(0,100×correctPlacedCount−25×mistakeCount)`; given/X/hint/thời gian không cho điểm.
- **Alternatives considered:** Hệ ba sao và dùng điểm/sao để mở khóa được review đề xuất nhưng không chọn.
- **Rationale:** Một công thức thuần, có thể tính lại, không tạo hai nguồn dữ liệu.
- **Evidence:** Luật và QA-16 rõ; chưa có player evidence.
- **Affected GDD IDs:** GR-18, UX-03/05/06, QA-16, O-03.
- **Status:** ACTIVE-MVP — công thức giữ; hệ số 100/25 vẫn tuneable ở M1 qua decision change.

## DEC-006 — Godot 4.x và sprite 2D từ nguồn 3D

- **DEC-ID:** DEC-006
- **Date:** 2026-09-18
- **Decision:** Hướng production là Godot 4.x/GDScript; model/animation 3D gốc được render offline thành sprite sheet 2D.
- **Alternatives considered:** Phaser production; runtime 3D qua `SubViewport`; scene thắng 3D riêng.
- **Rationale:** Giảm rủi ro renderer/runtime 3D trên mobile và giữ pipeline nhân vật gốc.
- **Evidence:** Architecture review; chưa có atlas/build/device measurement.
- **Affected GDD IDs:** D-06, REV-TECH-01, TECH-18/19, ART-06..11, QA-30/34.
- **Status:** ACTIVE — minor/renderer/budget chốt ở M0.

## DEC-007 — Mèo không mã hóa vùng

- **DEC-ID:** DEC-007
- **Date:** 2026-09-18
- **Decision:** Mọi ô `cat` dùng mèo đang chọn; MVP dùng mèo mặc định. Vùng dùng nền/viền/nhãn/họa tiết, không tô lông mèo theo vùng.
- **Alternatives considered:** Một atlas theo từng màu vùng; grayscale base + shader tint vùng.
- **Rationale:** Tránh nhân atlas/VRAM và tách presentation khỏi luật vùng.
- **Evidence:** Quyết định REV-TECH-05; chưa có visual prototype.
- **Affected GDD IDs:** D-06/10, TECH-18/20/21, ART-01/02/12/13, QA-09/50/52.
- **Status:** ACTIVE.

## DEC-008 — Offline-first, không dịch vụ mạng trong MVP

- **DEC-ID:** DEC-008
- **Date:** 2026-09-18
- **Decision:** MVP Android/iOS chơi offline, không account, network analytics, ad SDK hoặc IAP.
- **Alternatives considered:** Quảng cáo thưởng chỉ được xem xét trong gói post-MVP.
- **Rationale:** Giảm scope, dependency mạng và rủi ro riêng tư trước khi core được chứng minh.
- **Evidence:** GDD nhất quán; chưa có build để kiểm tra dependency.
- **Affected GDD IDs:** D-07, TECH-11, QA-26/34.
- **Status:** ACTIVE — MVP.

## DEC-009 — Schema tới N=12, release đầu chỉ N≤6 và không zoom/pan

- **DEC-ID:** DEC-009
- **Date:** 2026-09-18
- **Decision:** Schema/validator nhận N=4–12; release đầu chỉ N=4–6; board không dùng zoom/pan.
- **Alternatives considered:** Hạ trần schema; N=10–12 chỉ tablet/landscape; thêm zoom/pan.
- **Rationale:** Giữ khả năng tooling tương lai mà không nhận rủi ro usability vào MVP.
- **Evidence:** N12 fixture qua validator; chưa chứng minh gameplay/UI N12.
- **Affected GDD IDs:** D-01, REV-TECH-03, LV-01, UX-18, QA-27/35/42.
- **Status:** ACTIVE — N>6 DEFERRED.

## DEC-010 — Meta/economy không thuộc MVP

- **DEC-ID:** DEC-010
- **Date:** 2026-09-18
- **Decision:** Wallet, vàng, cứu lượt, điểm danh và quảng cáo thưởng là post-MVP; không tạo interface/placeholder trong MVP. Mỗi lượt MVP có một Hint miễn phí và Retry/Restart miễn phí.
- **Alternatives considered:** Dùng vàng mua hint/trợ giúp; cứu lượt trong MVP.
- **Rationale:** Tránh poverty trap và không để economy chặn tiến trình puzzle.
- **Evidence:** REV-GD-02/REV-ECO-01/REV-GD-04 đã được GDD/09 giải quyết.
- **Affected GDD IDs:** D-09, QA-46/47/53, GDD/11.
- **Status:** DEFERRED — POST-MVP.

## DEC-011 — “Vườn mèo” tương lai là danh sách mèo đã mua

- **DEC-ID:** DEC-011
- **Date:** 2026-09-18
- **Decision:** Nếu bật meta, Vườn mèo là danh sách mèo mua bằng vàng để chọn; không Garden Lobby, petting hoặc tự cấp mèo khi thắng.
- **Alternatives considered:** Garden Lobby tương tác, mèo tự mở theo level, petting, mèo riêng theo ô/vùng.
- **Rationale:** Giữ meta nhỏ và presentation độc lập với puzzle data.
- **Evidence:** REV-META-01 được giải quyết trong GDD/09; chưa có economy/asset evidence.
- **Affected GDD IDs:** D-10, REV-META-01, TECH-20/21, QA-52.
- **Status:** DEFERRED — POST-MVP.

## DEC-012 — Generator sau MVP; mốc 10/20 làm thủ công

- **DEC-ID:** DEC-012
- **Date:** 2026-09-18
- **Decision:** Level 10/20 được biên tập thủ công trước release; generator offline chỉ đề xuất level mới/mốc 30/40 về sau và vẫn cần review người.
- **Alternatives considered:** Runtime random level; dùng generator sửa lại 10/20 sau phát hành; “luật ẩn”.
- **Rationale:** Giữ ID/puzzle phát hành bất biến và không thay validation bằng ngẫu nhiên.
- **Evidence:** Pipeline/QA tương lai đã đặc tả; chưa có generator hoặc campaign.
- **Affected GDD IDs:** D-09, REV-GD-03, LV-07, QA-48/49.
- **Status:** Mốc 10/20 ACTIVE-MVP; generator DEFERRED.

## DEC-013 — S3 bắt buộc cho chặng cuối MVP

- **DEC-ID:** DEC-013
- **Date:** 2026-09-21
- **Decision:** Schema level là v4. Order 1–18 chỉ dùng S1/S2; mỗi order 19–24 phải có ít nhất một S3 khóa giao thoa hợp lệ và không thể hoàn tất chỉ bằng closure S2. S4/S5 không thuộc MVP.
- **Alternatives considered:** (A) S1/S2 cho cả 24 level; (B) S3 change-gated; (C) S3 bắt buộc có kiểm soát cho 19–24. Chọn C.
- **Rationale:** Mở đủ chiều sâu thiết kế cho sáu level khó nhất nhưng giới hạn rõ schema, content band và cổng QA; loại bỏ trạng thái scope lấp lửng.
- **Evidence:** Fixture S301, validator/test S3 v4 và release-band test đang qua; runtime Hint và sáu level release thật vẫn cần bằng chứng M2.
- **Affected GDD IDs:** D-02, GR-07/21..24, LV-03/08, TECH-01/04, QA-05/07/37/40/41/57.
- **Status:** ACTIVE-MVP.

## DEC-014 — Restart và Undo X một bước

- **DEC-ID:** DEC-014
- **Date:** 2026-09-21
- **Decision:** Cho Restart có xác nhận, reset toàn bộ lượt trên cùng level. Cho Undo đúng action X vừa commit: một MarkX/ClearX hoặc toàn bộ stroke; không Undo cat/`x_error`/tim/scorecard/Hint, không Redo, không vượt qua `TryCat`. Khe Undo chỉ ở runtime và bị xóa bởi lifecycle theo GR-33.
- **Alternatives considered:** Không Undo/Restart; chỉ Restart; lịch sử Undo nhiều bước; Undo `TryCat` trong cửa sổ thời gian. Chọn Restart + Undo X một bước.
- **Rationale:** Xử lý thao tác nháp và nhu cầu làm lại với state nhỏ, không mở đường hoàn tác kết quả thử mèo hoặc thay đổi hình phạt.
- **Evidence:** Interaction contract v2 có vector MarkX/ClearX/stroke, ranh giới `TryCat`, Back To Home và Restart; runtime Godot còn cần replay M0.
- **Affected GDD IDs:** D-04, GR-31..33, UX-03/24/25, TECH-03/08, QA-54/55.
- **Status:** ACTIVE-MVP.

## DEC-015 — Một Hint mỗi lượt và tutorial duy nhất ở Level 1

- **DEC-ID:** DEC-015
- **Date:** 2026-09-21
- **Decision:** Mỗi lượt có một Hint miễn phí; evidence hợp lệ tiêu thụ, `NoHint` không tiêu thụ, reload giữ hạn mức, Retry/Restart cấp lượt mới. Tutorial T1–T6 chỉ ở Level 1; từ Level 2 áp dụng phạt bình thường. Mỗi level luôn hiện vùng luật bốn icon + chữ.
- **Alternatives considered:** Hint vô hạn; cooldown; Hint hai nấc; tutorial trải Level 1–4 hoặc bất tử Level 1–2. Chọn hạn mức một/lượt và tutorial Level 1.
- **Rationale:** Ngăn spam Hint mà không thêm economy/cooldown; tập trung onboarding và trả gameplay chuẩn ngay từ Level 2.
- **Evidence:** Interaction contract v2 kiểm evidence/NoHint/Restart; usability/tutorial và Hint S3 cần M1/M2.
- **Affected GDD IDs:** GR-21..24, UX-03/04/14, TECH-04, QA-18..22/33/56.
- **Status:** ACTIVE-MVP.

## DEC-016 — Scorecard Result-only và acceptance độc lập meta

- **DEC-ID:** DEC-016
- **Date:** 2026-09-21
- **Decision:** Giữ 3 tim, `x_error` khóa và công thức scorecard, nhưng chỉ hiện điểm ở Result và không hứa quy đổi. Thắng khi đủ N mèo và còn ít nhất 1 tim. Content acceptance yêu cầu uniqueness/trace cùng một lượt giải mù ≥1 tim; runtime/campaign còn qua cổng 10 người, thiết bị và accessibility riêng.
- **Alternatives considered:** Điểm ở header; hệ sao; bỏ tim; tim theo cỡ bàn; dựa vào cứu lượt/economy tương lai. Chọn Pure MVP Isolation.
- **Rationale:** Luật MVP phải tự chứng minh giá trị, không dựa vào interface hoặc lời hứa meta chưa tồn tại; tách hợp lệ logic của level khỏi chất lượng runtime.
- **Evidence:** GDD/QA đã có tiêu chí máy kiểm và playtest; fairness của 3 tim vẫn là giả thuyết M1 chứ không phải blocker quyết định scope.
- **Affected GDD IDs:** D-05/08/09, GR-17..19/25, LV-05/08, UX-05/06, QA-14..16/27..29/57.
- **Status:** ACTIVE-MVP.

## DEC-017 — Design Freeze khóa core và quản lý danh sách tuneable

- **DEC-ID:** DEC-017
- **Date:** 2026-09-22
- **Decision:** GDD v1.0 Design Freeze khóa phạm vi MVP và các loại trừ, GR/state transition, điều kiện thắng/thua, schema level/save/session, tiến trình campaign, ranh giới module và QA gate. Các tham số tuneable được giới hạn ở: cửa sổ double-tap 280 ms và ngưỡng kéo 12 điểm logic (M0, UX Lead + Technical Lead); feedback khoảng 0,7 giây (M1, UX Lead); hệ số scorecard 100/25 nhưng không đổi vai trò Result-only (M1, Game Design Lead); atlas/frame/nén và ngân sách tải/RAM/VRAM trong ngưỡng TECH-19 (M0, Technical Lead + Art Lead); nhịp khó, thời gian mục tiêu và presentation không đổi luật (M1/M2, Game Design/Puzzle/UX Lead).
- **Alternatives considered:** Freeze mọi giá trị; hoặc hoãn toàn bộ freeze tới sau M1. Chọn freeze core và tune có kiểm soát để M0/M1 còn hiệu chỉnh cảm giác mà không làm trôi luật.
- **Rationale:** Tách invariant triển khai khỏi tham số cần đo trên thiết bị/người chơi, đồng thời ngăn tuning bị dùng để lách thay đổi scope hoặc schema.
- **Change control:** Mọi tuning phải có evidence, owner, phase và DEC cập nhật giá trị trước khi merge. Thay đổi ngoài danh sách tuneable, hoặc đổi ý nghĩa luật/schema/tiến trình/phạm vi/scorecard, bắt buộc mở lại Design Freeze bằng package `design-change` hoặc `governance`, cập nhật đồng bộ GDD, fixture, validator/test và QA.
- **Evidence:** GDD 00–09, checklist Design Freeze 06, risk/research register và phê duyệt package M0-PREFLIGHT.
- **Affected GDD IDs:** D-01..10, GR-01..33, LV-01..08, TECH-01..21, ART-01..13, toàn bộ QA MVP.
- **Status:** ACTIVE-GOVERNANCE — đóng DQ-002; không tự tuyên bố Design Freeze đã đạt.
