# Rà soát Thiết kế Trò chơi Toàn diện (Senior Game Design Review) — MVP

**Dự án:** Vườn Mèo (ASOL-Game-02)  
**Vai trò:** Senior Game Designer  
**Thời điểm lập:** 2026-09-21  
**Phạm vi rà soát ban đầu:** MVP theo baseline GDD v0.4.2  
**Resolution snapshot:** 2026-09-21, áp dụng GDD v0.5.0 và DEC-013..016  
**Tài liệu đối chiếu trọng tâm:** `GDD/01-tam-nhin-va-pham-vi.md`, `GDD/02-luat-choi-va-trang-thai.md`, `GDD/04-thiet-ke-level.md`, `GDD/09-ra-soat-thiet-ke.md`, `GDD/11-ke-hoach-meta-va-sinh-level.md`, `design-reviews/*`, `design-control/*`

---

## I. Giới thiệu và Nguyên tắc Rà soát

Bản đánh giá này đóng vai trò là tài liệu thẩm định chuyên môn độc lập của Senior Game Designer trước thềm GDD v1.0 Design Freeze. Báo cáo tập trung phân tích 15 khía cạnh cốt lõi của trải nghiệm người chơi (Player Experience - PX), cơ chế gameplay vi mô/vĩ mô, công thái học thao tác và các rủi ro vận hành trong phiên bản phát hành đầu tiên (MVP).

Các mục “Current rule”, alternative và synthesis bên dưới ghi lại **snapshot trước quyết định**. Nếu khác bảng Resolution sau đây, chúng là lịch sử đã bị supersede; luật chạy nằm ở GDD v0.5.0.

### Resolution — 2026-09-21

| GD-ID | Trạng thái | Quyết định áp dụng | Truy vết |
| --- | --- | --- | --- |
| GD-01 | VALIDATION-PENDING M0 | Giữ optimistic preview 280 ms/12 pt; chỉ giữ nếu accidental `TryCat` <3%. | DEC-003, QA-08/09/12/43..45 |
| GD-02 | RESOLVED-DESIGN / VALIDATION-PENDING | Mỗi level có vùng luật bốn icon + chữ luôn nhìn thấy; giữ hàng tiến độ vùng, kiểm độ đọc ở M0/M1. | DEC-015, UX-03, QA-27..29 |
| GD-03 | RESOLVED | Thua bắt đầu lại toàn bộ cùng level; Retry miễn phí, không cứu lượt MVP. | DEC-016, GR-19, QA-14 |
| GD-04 | RESOLVED-BASELINE / VALIDATION-PENDING | Giữ 3 tim kết hợp `x_error`; luật phải tự chứng minh công bằng, không dựa meta tương lai. | DEC-016, GR-16/17, RISK-002 |
| GD-05 | RESOLVED-BASELINE / VALIDATION-PENDING | Giữ `x_error` khóa đến Retry/Restart; Undo không tác động X đỏ. | DEC-014/016, GR-13/16/32 |
| GD-06 | RESOLVED | Thêm Restart có xác nhận và Undo đúng một action X; không Undo `TryCat`, không Redo, khe runtime-only. | DEC-014, GR-31..33, QA-54/55 |
| GD-07 | RESOLVED-ROLE / TUNEABLE | Score chỉ là scorecard ở Result, không quy đổi; giữ công thức 100/25, hệ số còn tuneable M1. | DEC-005/016, GR-18, QA-16 |
| GD-08 | RESOLVED | Một Hint miễn phí mỗi lượt; evidence tiêu thụ, `NoHint` không tiêu thụ; điểm danh/quảng cáo cấp thêm Hint là post-MVP. | DEC-015, GR-21..24, QA-56 |
| GD-09 | RESOLVED-MVP | Giữ 24 level tuyến tính, không replay/skip/level select; generator sau MVP. | DEC-001/012 |
| GD-10 | RESOLVED | Chọn Alternative B nhưng nâng thành yêu cầu: từng level 19–24 bắt buộc cần S3; 1–18 chỉ S1/S2. | DEC-013, LV-08, QA-57 |
| GD-11 | RESOLVED | Level 1 là tutorial duy nhất; từ Level 2 áp dụng luật/phạt bình thường. | DEC-015, UX-04, QA-22/33 |
| GD-12 | PARTIALLY-RESOLVED / VALIDATION-PENDING | Restart + Undo X phá hai mắt xích ức chế; 3 tim/X đỏ/tiến trình tuyến tính vẫn cần playtest M1. | DEC-014/016, RISK-001/002 |
| GD-13 | RESOLVED-MVP / NAMING-OPEN | Không thêm meta động lực vào MVP; “Vườn Mèo” chỉ là tên tạm và được đổi sau naming review. | D-09/10, DQ-010 |
| GD-14 | RESOLVED | Giữ schema/tool N≤12, release N≤6; không zoom/pan, N>6 post-MVP. | DEC-009, QA-35/42 |
| GD-15 | RESOLVED | Chọn Alternative B Pure MVP Isolation: không wallet/gold/rescue/ads/check-in/interface meta; score/tim độc lập meta. | DEC-010/016, GDD/11 |

Mọi đánh giá đều tuân thủ các nguyên tắc:
1. **Không coi sở thích chủ quan là chân lý:** Mọi nhận định đều phải dựa trên bằng chứng đã có hoặc được gắn nhãn giả thuyết cần kiểm chứng.
2. **Không thiết kế lại toàn bộ game:** Tôn trọng tối đa các trụ cột đã được thống nhất tại GDD v0.4.2.
3. **Không thêm tính năng bừa bãi:** Chỉ đề xuất giải pháp khi có vấn đề nghiêm trọng đã được chứng minh.
4. **Cô lập triệt để MVP:** Ngăn chặn các hệ thống meta/kinh tế tương lai (Post-MVP) làm biến dạng hoặc gây ức chế cho trải nghiệm cốt lõi của bản đầu.

---

## II. Đánh giá Chi tiết 15 Phương diện Thiết kế

---

### GD-01 — Vòng lặp Cốt lõi (Core Loop)
* **GD-ID:** GD-01
* **Observation:** Tỷ lệ phân bổ thao tác trong một ván giải Star Battle / Queens có tính bất đối xứng rất cao: 75–85% hành động của người chơi là đánh dấu hoặc xóa ghi chú loại trừ (X), trong khi hành vi đặt Mèo chỉ diễn ra đúng N lần (4–6 lần/level). Cơ chế 1-chạm X tức thì (optimistic preview) kết hợp 2-chạm đặt Mèo cố gắng giải quyết độ trễ cảm ứng, nhưng đặt hai nhánh hành vi này vào một khoảng cách thời gian rất mong manh (cửa sổ 280 ms).
* **Current rule:** [GDD/01 §1](../../GDD/01-tam-nhin-va-pham-vi.md#L9), [GR-09..14/29/30](../../GDD/02-luat-choi-va-trang-thai.md#L26-L40), [UX-09..11](../../GDD/03-luong-man-hinh-va-ux.md#L48-L53): Chạm/kéo đánh/xóa X tức thì (commit sau 280 ms hoặc khi nhấc ngón); hai chạm nhanh cùng ô trong 280 ms hoàn tác preview và gọi `TryCat`. Ô mèo đúng và given cố định bất biến; ô sai thành `x_error` khóa vĩnh viễn và trừ tim.
* **Why it may be a problem:**
  1. *Nguy cơ nhận diện sai cử chỉ vi mô:* Tốc độ gõ X nhanh của người chơi có thể tạo ra các cú chạm lặp vô ý trên cùng một ô trong khoảng thời gian < 280 ms, vô tình kích hoạt `TryCat` và nhận ngay hình phạt mất tim.
  2. *Bất đối xứng tâm lý:* Người chơi thao tác X với tâm thế "thử nghiệm nháp" tự do, nhưng chỉ cần trượt tay biến thành 2-chạm là lập tức đối mặt với hình phạt chết người không thể hoàn tác.
* **Evidence already available:** 16 interaction vectors trong [`interactions.sample.json`](../../GDD/data/interactions.sample.json) đã kiểm chứng logic trạng thái trên Python reducer; [REV-UX-01](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L37-L46) xác nhận độ trễ 280 ms cũ là không thể chấp nhận và đưa ra giải pháp optimistic preview.
* **What is still unknown:** Tỷ lệ kích hoạt nhầm `TryCat` (accidental double-tap) trên màn hình cảm ứng thật với kích thước ô 44×44 pt; phản ứng giật mình/khó chịu của mắt người chơi khi thấy X xuất hiện rồi biến mất đột ngột để thay bằng Mèo.
* **Alternative A:** Giữ nguyên kiến trúc v0.4.2: Optimistic Preview 280 ms và ngưỡng kéo 12 pt; tinh chỉnh thông số vật lý qua đo đạc thực tế tại M0.
* **Alternative B:** Chuyển đổi chế độ bút (Tool Toggle): Đặt 2 nút chế độ dưới bàn: `[Chế độ X]` và `[Chế độ Mèo]`. 1 chạm thực thi ngay trạng thái của chế độ đó, triệt tiêu hoàn toàn sự phụ thuộc vào thời gian 280 ms.
* **Alternative C:** Long Press đặt Mèo: 1 chạm = Đánh/Xóa X ngay; Nhấn giữ (Long press ~250 ms) = Xác nhận thử đặt Mèo kèm phản hồi rung nhẹ (haptic).
* **Trade-offs:** 
  * *Phương án A:* Giữ giao diện tối giản (không nút bấm thừa), nhưng phụ thuộc nặng vào độ chính xác nhận diện thời gian/cảm ứng.
  * *Phương án B:* An toàn 100% về mặt cử chỉ, nhưng tăng thêm 1 thao tác chuyển đổi mode (mode confusion), làm chậm nhịp chơi.
  * *Phương án C:* Tránh hoàn toàn lỗi nhấp đúp nhầm, nhưng tăng thời gian giữ ngón cho mỗi chú mèo.
* **Recommended validation method:** Chạy bài test đo lường tương tác trên thiết bị thật ở M0 (Replay interaction harness trên Android/iOS), ghi lại tỷ lệ gõ nhầm (fat-finger error rate) của 5 người chơi với tốc độ thao tác nhanh.
* **When to decide:** **M0** (tinh chỉnh thông số) / **M1** (nếu tỷ lệ bấm nhầm vượt quá 3%, cân nhắc chuyển sang Phương án B hoặc C).

---

### GD-02 — Độ rõ ràng của Mục tiêu Người chơi (Player Goal Clarity)
* **GD-ID:** GD-02
* **Observation:** Người chơi phải thỏa mãn đồng thời 4 ràng buộc: Hàng, Cột, Vùng, và Không chạm chéo/kề. Tuy nhiên, phản hồi tiến độ thị giác (Progress Indicator) ở dưới bàn cờ chỉ đại diện cho một chiều duy nhất: **Vùng (Region A..N)**.
* **Current rule:** [GR-01..05](../../GDD/02-luat-choi-va-trang-thai.md#L10-L15), [UX-03](../../GDD/03-luong-man-hinh-va-ux.md#L31), [DEC-007](../governance/02-decision-log.md#L72-L82): Hàng N vị trí dưới bàn hiển thị nhãn/họa tiết vùng A..(N); vị trí chưa tìm có viền nhạt, vị trí đã tìm sáng lên theo màu vùng. Không có chỉ báo trạng thái cho Hàng và Cột.
* **Why it may be a problem:**
  1. *Thiếu cân bằng thông tin:* Người chơi mới có xu hướng nhìn vào hàng tiến độ và lầm tưởng rằng "chỉ cần tìm đủ mỗi vùng một mèo là xong", lơ là việc kiểm tra trùng hàng, trùng cột hoặc chạm góc.
  2. *Khả năng nhận diện vùng hạn chế:* Khi mọi ô Mèo đều dùng chung một ngoại hình mặc định (không tô lông mèo theo vùng theo DEC-007), việc đối chiếu vị trí Mèo trên bàn với nhãn vùng A..N bên dưới phụ thuộc hoàn toàn vào họa tiết nền ô, dễ gây nhầm lẫn trên các màn hình có mật độ điểm ảnh thấp hoặc bị chói sáng ngoài trời.
* **Evidence already available:** [DEC-007](../governance/02-decision-log.md#L72-L82) đã chốt không tô lông mèo theo vùng để bảo vệ VRAM; [ASM-005](../governance/04-assumptions.md#L12) ghi nhận giả định "vùng vẫn đọc được khi mèo dùng chung ngoại hình" là chưa được kiểm chứng trực quan.
* **What is still unknown:** Mức độ người chơi chú ý vào hàng tiến độ vùng so với việc tự quét bàn cờ; tỷ lệ người chơi mắc lỗi trùng cột/hàng do không có chỉ báo trực quan.
* **Alternative A:** Giữ nguyên v0.4.2: Chỉ hiển thị hàng tiến độ Vùng A..N dưới bàn; luật hàng/cột hiển thị ở header thu gọn.
* **Alternative B:** Chỉ báo trực tiếp trên bàn cờ (Board State Dimming): Khi một hàng hoặc một cột đã có đủ 1 Mèo đúng, tự động làm mờ nhẹ (dimming 20%) hoặc đổi màu số thứ tự/viền của hàng/cột đó để người chơi biết trục đó đã hoàn thành.
* **Alternative C:** Bổ sung nhãn kiểm tra 3 trục: Giữ nguyên bàn cờ, nhưng trong phần header hoặc panel luật, hiển thị 3 dấu tích trạng thái: Hàng (x/N), Cột (y/N), Vùng (z/N).
* **Trade-offs:** 
  * *Phương án A:* Giữ giao diện sạch sẽ, thuần khiết puzzle cổ điển, nhưng đòi hỏi người chơi tự rà soát mắt nhiều hơn.
  * *Phương án B:* Giảm tải nhận thức (cognitive load) cực tốt, nhưng có nguy cơ "mớm bài" gián tiếp làm giảm độ khó suy luận nếu không được cân chỉnh tinh tế.
* **Recommended validation method:** Kiểm tra nhận diện thị giác (Visual Recognition Test) ở M0 với mockup bàn cờ đầy đủ chi tiết đồ họa; phỏng vấn người chơi ở M1 xem họ có hiểu vì sao mình chưa thắng dù hàng tiến độ bên dưới đã đầy.
* **When to decide:** **M0** (kiểm tra độ đọc vùng) / **M1** (quyết định có thêm hiệu ứng dimming hàng/cột hay không).

---

### GD-03 — Vòng lặp Thất bại (Failure Loop)
* **GD-ID:** GD-03
* **Observation:** Khi hết 3 tim, trò chơi chuyển sang trạng thái `Failed`, khóa bàn cờ, hiển thị màn hình thua và nút "Thử lại". Thao tác "Thử lại" xóa sạch 100% bàn cờ, bắt đầu lại từ trạng thái ban đầu của màn chơi đó.
* **Current rule:** [GR-19](../../GDD/02-luat-choi-va-trang-thai.md#L49), [UX-06](../../GDD/03-luong-man-hinh-va-ux.md#L34), [DEC-004](../governance/02-decision-log.md#L39-L49): Tim về 0 -> `Failed`. Retry tạo lượt mới trên cùng level, xóa toàn bộ ô, tim hồi 3, điểm về 0, thời gian tính lại. Không có cơ chế cứu lượt trong MVP.
* **Why it may be a problem:**
  1. *Tổn thất công sức (Sunk Cost Fallacy & Frustration):* Ở bàn 6×6 (thời gian giải 4–6 phút), người chơi có thể đã suy luận đúng 5/6 chú mèo và đánh dấu 25 dấu X. Một sai lầm thứ 3 (do suy luận sai bước cuối hoặc trượt tay) xóa sạch toàn bộ 5 phút nỗ lực, buộc họ phải nhập lại từ đầu những gì họ vốn đã biết rõ.
  2. *Cảm xúc tiêu cực (Rage Quit):* Với một tựa game mang vỏ bọc ấm áp, dễ thương ("Vườn Mèo"), hình phạt quét sạch bàn cờ tạo ra sự trừng phạt mang tính trừng phạt nặng nề (punitive), hoàn toàn lệch pha với kỳ vọng thể loại cozy puzzle.
* **Evidence already available:** [REV-GD-01](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L49-L58) và [REV-GD-04](../archive/reviews/02-danh-gia-ban-thiet-ke-v04.md#L83-L93) đều xếp đây là vấn đề nghiêm trọng; [RISK-002](../governance/03-risk-register.md#L9) đánh giá xác suất High, tác động High; [DQ-007](../governance/01-open-questions.md#L91-L103) đang mở.
* **What is still unknown:** Tỷ lệ bỏ game (churn rate) sau lần thất bại đầu tiên ở bàn 5×5 và 6×6; liệu người chơi có kiên nhẫn bấm lại từ đầu hay gỡ cài đặt ngay lập tức.
* **Alternative A:** Giữ nguyên v0.4.2 cho MVP: Thua = Xóa trắng bàn, Retry miễn phí vô hạn lần. Trì hoãn cơ chế cứu lượt sang Post-MVP.
* **Alternative B:** Khôi phục bàn cờ kèm trừng phạt điểm (Soft Reset): Khi Retry, giữ lại các ô Mèo đúng đã đặt trước đó (hoặc giữ lại các dấu X do người chơi tự đặt), chỉ xóa ô `x_error`, đặt lại tim = 3 nhưng khóa điểm màn chơi đó về 0.
* **Alternative C:** Tùy chọn Reset Bàn cờ vs Thử lại giữ nguyên: Trên màn hình Thua, cung cấp 2 lựa chọn: "Xóa làm lại từ đầu" hoặc "Giữ lại bàn cờ & giải tiếp" (không tính điểm kỷ lục).
* **Trade-offs:** 
  * *Phương án A:* Giữ code máy trạng thái và lưu session cực kỳ đơn giản, không phát sinh bug dữ liệu bàn cờ dở dang.
  * *Phương án B/C:* Bảo vệ tối đa tâm lý người chơi, giảm 90% cảm giác ức chế, nhưng đòi hỏi sửa đổi state machine và logic reset của MVP.
* **Recommended validation method:** Tổ chức playtest định tính ở M1 với 10 người chơi mục tiêu (nhóm casual). Ghi nhận chỉ số Dwell Time và tỷ lệ bỏ cuộc giữa chừng sau khi dính màn hình `Failed` ở các level 13–24.
* **When to decide:** **M1** (Sau đợt playtest đầu tiên với người dùng thật).

---

### GD-04 — Hình phạt 3 Tim (3-Heart Punishment)
* **GD-ID:** GD-04
* **Observation:** Hệ thống 3 tim là cơ chế vay mượn từ các game puzzle free-to-play có cơ chế kiếm tiền (monetized puzzle), nơi tim bị trừ để kích thích mua mạng hoặc xem quảng cáo. Trong MVP của Vườn Mèo, game chạy hoàn toàn offline, không IAP, không quảng cáo, và Retry là miễn phí vô hạn.
* **Current rule:** [GR-16](../../GDD/02-luat-choi-va-trang-thai.md#L46), [GR-17](../../GDD/02-luat-choi-va-trang-thai.md#L47), [DEC-004](../governance/02-decision-log.md#L39-L49): Mỗi màn bắt đầu với 3 tim. Thử sai 1 lần mất 1 tim, không hồi tim giữa màn. Hết tim thì thua.
* **Why it may be a problem:**
  1. *Mục đích thiết kế bị mâu thuẫn:* Nếu không bán mạng, mục đích duy nhất của 3 tim là **chống người chơi đoán mò (anti-brute-force)**. Nhưng việc đặt giới hạn cứng 3 lần thử sai trên một bàn cờ 36 ô (6×6) khiến người chơi rơi vào trạng thái tê liệt phân tích (analysis paralysis), không dám suy luận giả định.
  2. *Triệt tiêu tính thư giãn:* Áp lực mất mạng biến một trò chơi thư giãn thành một bài kiểm tra căng thẳng.
* **Evidence already available:** [DEC-004](../governance/02-decision-log.md#L39-L49) ghi nhận đây là quyết định được giữ cho MVP nhưng cần xác thực ở M1; [DQ-007](../governance/01-open-questions.md#L91-L103) xác nhận cảm giác chơi chưa được chứng minh.
* **What is still unknown:** Người chơi có thực sự thử đoán mò nếu không có tim hay không; liệu 3 tim có làm tăng cảm giác hưng phấn khi thắng (high stakes) hay chỉ thuần túy tạo ức chế.
* **Alternative A:** Giữ 3 tim trong MVP: Duy trì cơ chế 3 tim như luật hiện hành để làm baseline đo lường.
* **Alternative B:** Chế độ Tim Thư giãn (Relaxed Hearts): Không giới hạn số tim trong màn chơi thường (hoặc hiển thị bộ đếm số lỗi `Mistakes: x` thay vì trừ tim), tim chỉ tính vào việc trừ điểm cuối màn.
* **Alternative C:** Tăng số tim theo kích thước lưới: Bàn 4×4 = 3 tim; Bàn 5×5 = 4 tim; Bàn 6×6 = 5 tim để tương xứng với số lượng ô và độ phức tạp suy luận.
* **Trade-offs:** 
  * *Phương án A:* Giữ nguyên toàn bộ spec và kiến trúc session v2 hiện tại, không làm xáo trộn kế hoạch dev.
  * *Phương án B:* Biến game thành trải nghiệm cozy đích thực, loại bỏ hoàn toàn rage quit, nhưng làm mất đi cảm giác vượt khó của nhóm người chơi giải đố thuần túy (hardcore puzzle fans).
  * *Phương án C:* Cân bằng tuyệt vời giữa thử thách và độ bao dung cơ học, giữ nguyên logic trừ tim nhưng mở rộng biên độ an toàn.
* **Recommended validation method:** A/B Testing hoặc Blind Playtest ở M1: Nhóm 1 chơi với 3 tim cố định; Nhóm 2 chơi với số tim theo quy mô bàn (Phương án C). So sánh tỷ lệ hoàn thành màn và điểm đánh giá độ hài lòng (CSAT).
* **When to decide:** **M1**.

---

### GD-05 — Hành vi của `x_error` (x_error Behavior)
* **GD-ID:** GD-05
* **Observation:** Khi thử đặt Mèo sai, ô đó chuyển thành trạng thái `x_error` (dấu X màu đỏ kèm biểu tượng cảnh báo). `x_error` bị khóa vĩnh viễn, người chơi không thể xóa, không thể tương tác cho đến khi kết thúc màn chơi hoặc Retry.
* **Current rule:** [GR-08](../../GDD/02-luat-choi-va-trang-thai.md#L18), [GR-13](../../GDD/02-luat-choi-va-trang-thai.md#L32), [GR-16](../../GDD/02-luat-choi-va-trang-thai.md#L46), [REV-GD-01](../../GDD/09-ra-soat-thiet-ke.md#L8): Ô thử sai thành `x_error`, khóa mọi thao tác, chạm hoặc kéo qua bị bỏ qua không mất thêm tim. Hint runtime bỏ qua `x_error` khi tính toán logic.
* **Why it may be a problem:**
  1. *Nghịch lý hỗ trợ suy luận:* Trong logic của Star Battle, biết một ô **không có Mèo** là một thông tin cực kỳ giá trị (loại trừ 1 ứng viên). Bằng cách biến ô sai thành `x_error` vĩnh viễn, trò chơi vô tình tặng không cho người chơi một dấu loại trừ tuyệt đối.
  2. *Ô nhiễm thị giác và cảm xúc tiêu cực:* Màu đỏ chói lọi của `x_error` tồn tại suốt phần còn lại của ván đấu giống như một "vết sẹo" nhắc nhở sai lầm, phá vỡ bảng màu êm dịu của chủ đề khu vườn.
* **Evidence already available:** GDD v0.4.2 đã sửa lỗi của v0.3 (không bắt người chơi phải chạm một lần nữa để xóa X đỏ); [REV-GD-01](../../GDD/09-ra-soat-thiet-ke.md#L8) chốt giữ X đỏ khóa.
* **What is still unknown:** Liệu người chơi có cảm thấy bị "khó chịu thị giác" bởi dấu X đỏ hay họ tận dụng nó như một lợi thế loại trừ miễn phí.
* **Alternative A:** Giữ nguyên v0.4.2: Giữ `x_error` màu đỏ khóa vĩnh viễn trên bàn cho đến khi Retry/Won.
* **Alternative B:** Chuyển hóa mềm (Soft Conversion to X): Ô sai nhấp nháy đỏ và rung nhẹ (haptic) để báo hiệu mất tim, sau đó tự động chuyển thành một dấu X màu xám thông thường.
* **Alternative C:** Cho phép người chơi tự xóa: Giữ màu đỏ ban đầu, nhưng nếu người chơi chạm vào ô `x_error`, nó sẽ chuyển về `x` thường hoặc `empty` nếu họ muốn dọn dẹp bàn cờ cho đẹp mắt.
* **Trade-offs:** 
  * *Phương án A:* Thể hiện rõ ràng lịch sử sai lầm, ngăn chặn người chơi thử lại đúng ô đó lần thứ hai.
  * *Phương án B:* Giữ thẩm mỹ bàn cờ luôn thanh lịch, biến sai lầm thành bài học ghi chú tự nhiên mà không làm biến dạng cấu trúc dữ liệu ô.
* **Recommended validation method:** Thử nghiệm hiển thị giao diện ở M0/M1: Đánh giá khả năng tiếp cận (Accessibility) ở chế độ mù màu/thang xám theo [UX-16](../../GDD/03-luong-man-hinh-va-ux.md#L81) để đảm bảo `x_error` có họa tiết cảnh báo riêng biệt chứ không chỉ dựa vào sắc đỏ.
* **When to decide:** **M0** (chốt hình ảnh cảnh báo tiếp cận) / **M1** (chốt hành vi chuyển đổi sang X thường nếu có phản hồi tiêu cực).

---

### GD-06 — Quyết định Không có Undo và Thiếu Nút Restart giữa chừng (No-Undo Decision & In-game Restart)
* **GD-ID:** GD-06
* **Observation:** MVP cấm hoàn toàn tính năng Hoàn tác (Undo). Đối với dấu X, người chơi có thể tự sửa bằng cách chạm lại; nhưng đối với Mèo đúng đã đặt hoặc Mèo sai (`x_error`), quyết định là tuyệt đối bất biến. Đồng thời, giao diện chơi không có nút "Chơi lại từ đầu" (Restart) giữa chừng.
* **Current rule:** [GDD/02 §2](../../GDD/02-luat-choi-va-trang-thai.md#L24), [D-04](../governance/02-decision-log.md#L32), [DEC-004](../governance/02-decision-log.md#L39-L49): Không có Undo hoặc Restart giữa lượt ở bản đầu. Nút thoát duy nhất trên header là `Back To Home` (tự động lưu ván chơi dở).
* **Why it may be a problem:**
  1. *Bất khả kháng trước lỗi phần cứng/vô ý:* Nếu màn hình bị dính nước, ngón tay run hoặc chạm lệch mép làm kích hoạt một `TryCat` sai, người chơi không có bất kỳ cơ chế cứu vãn nào.
  2. *Bế tắc tâm lý khi muốn chơi lại:* Khi người chơi nhận ra mình đã tư duy sai hướng từ đầu và muốn làm lại một ván sạch sẽ, họ không có nút Restart. Họ buộc phải làm một hành động phi lý: **cố tình chạm đúp bừa bãi 3 lần vào các ô trống để tự sát (hết tim)** nhằm kích hoạt màn hình Failed để được bấm "Thử lại".
* **Evidence already available:** [DEC-004](../governance/02-decision-log.md#L39-L49) loại bỏ Undo để giảm độ phức tạp của Save/State Reducer; [UX-03](../../GDD/03-luong-man-hinh-va-ux.md#L31) xác nhận header chỉ có Back to Home, Settings, Hint, Help.
* **What is still unknown:** Tần suất người chơi thực hiện hành vi "tự sát có chủ đích" để reset bàn cờ trong playtest.
* **Alternative A:** Giữ nguyên v0.4.2: Không Undo, không nút Restart giữa màn.
* **Alternative B:** Bổ sung nút Restart trên Header/Pause Menu: Không thêm Undo từng bước, nhưng bổ sung nút "Làm lại ván này" (Restart Level) trong menu Pause/Settings hoặc cạnh nút Back to Home (có popup xác nhận).
* **Alternative C:** Undo 1 bước gần nhất cho thao tác Mèo: Cho phép hoàn tác duy nhất 1 action gần nhất nếu đó là một cú bấm nhầm trong vòng 3 giây.
* **Trade-offs:** 
  * *Phương án A:* Tiết kiệm chi phí kỹ thuật tối đa cho MVP.
  * *Phương án B:* **Chi phí cực thấp (chỉ gọi lại hàm reset của Retry)**, giải quyết 100% tình huống người chơi bế tắc muốn làm lại mà không làm ảnh hưởng đến độ phức tạp của kiến trúc Undo state history.
  * *Phương án C:* Đòi hỏi quản lý lịch sử nước đi (Move Stack) và tính toán lại tim/điểm phức tạp.
* **Recommended validation method:** Kiểm tra công thái học và kiểm thử luồng người dùng ở M0/M1: Quan sát xem người chơi làm gì khi họ muốn chơi lại một level từ đầu.
* **When to decide:** **Design Freeze / M0** (Khuyến nghị bổ sung ngay Alternative B vào checklist vì chi phí kỹ thuật cực rẻ nhưng giải quyết được nút thắt UX nghiêm trọng).

---

### GD-07 — Ý nghĩa của Điểm số (Score Relevance)
* **GD-ID:** GD-07
* **Observation:** Điểm số được tính theo công thức thuần toán học nhưng hoàn toàn cô lập trong từng ván chơi. Nó không được cộng dồn vào tổng điểm hồ sơ, không có bảng xếp hạng (Leaderboard), không có hệ thống đánh giá sao (1–3 sao), và trong MVP cũng không được dùng để quy đổi ra bất kỳ tài nguyên nào.
* **Current rule:** [GR-18](../../GDD/02-luat-choi-va-trang-thai.md#L48), [DEC-005](../governance/02-decision-log.md#L50-L60): `score = max(0, 100 × correctPlacedCount − 25 × mistakeCount)`. Điểm chỉ hiển thị trên header của lượt hiện tại và màn kết quả. Mèo cho sẵn, X, thời gian, hint không ảnh hưởng điểm.
* **Why it may be a problem:**
  1. *Chỉ số chết (Dead Metric):* Một con số nhảy múa trên màn hình nhưng không có bất kỳ công dụng hay ý nghĩa cạnh tranh nào sẽ nhanh chóng bị người chơi bỏ qua (inattention blindness).
  2. *Thêm dầu vào lửa khi sai sót:* Khi người chơi thử sai, họ vừa bị trừ tim, vừa thấy điểm số bị trừ 25 điểm (`mistakeCount`). Việc trừ điểm một chỉ số vô dụng không tạo thêm động lực mà chỉ tăng thêm sự bực bội vô nghĩa.
* **Evidence already available:** [REV-GD-02](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L61-L72) cảnh báo về Dead Metric; [RISK-014](../governance/03-risk-register.md#L21) xếp mức rủi ro Medium/Medium; [DQ-006](../governance/01-open-questions.md#L77-L89) để ngỏ việc xem xét lại vai trò hiển thị điểm số.
* **What is still unknown:** Người chơi có cảm thấy tự hào khi đạt 600/600 điểm ở level 6×6 hay họ chỉ quan tâm đến việc qua màn để xem hoạt ảnh mèo.
* **Alternative A:** Giữ nguyên công thức và hiển thị điểm ở MVP: Giữ nguyên như DEC-005 làm mốc chuẩn bị cho công thức đổi vàng ở Post-MVP.
* **Alternative B:** Ẩn điểm số khỏi Header trong khi chơi (Result Only): Không hiển thị số điểm trực tiếp trên thanh Header trong ván đấu (để tránh gây phân tâm và giảm áp lực), chỉ hiển thị điểm tổng kết ở màn Thắng (Win Screen).
* **Alternative C:** Thay điểm số bằng Đánh giá Sao trực quan: 
  * 0 lỗi = ⭐⭐⭐ (Hoàn hảo)
  * 1 lỗi = ⭐⭐ (Tốt)
  * 2 lỗi = ⭐ (Đạt)
* **Trade-offs:** 
  * *Phương án A:* Giữ đúng cam kết GDD hiện hành, chuẩn bị sẵn dữ liệu cho GDD 11 sau này.
  * *Phương án B:* Giúp giao diện puzzle cực kỳ thông thoáng, tập trung 100% vào việc suy luận.
  * *Phương án C:* Mang lại ngôn ngữ casual chuẩn mực mà mọi đối tượng người chơi đều hiểu ngay lập tức, nhưng đòi hỏi cập nhật UI màn kết quả.
* **Recommended validation method:** Khảo sát người chơi ở M1: Hỏi người chơi sau khi thắng level "Bạn có nhớ số điểm mình vừa đạt được là bao nhiêu không?" và "Số điểm đó có ý nghĩa gì với bạn không?".
* **When to decide:** **M1** (Tinh chỉnh cân bằng/hiển thị qua decision log).

---

### GD-08 — Hành vi Gợi ý (Hint Behavior)
* **GD-ID:** GD-08
* **Observation:** Hệ thống gợi ý được thiết kế có tính sư phạm rất cao (Pedagogical Design): Gợi ý không tự động điền hộ người chơi, mà phân tích trạng thái bàn cờ hiện tại, tìm một ô mục tiêu S2 (ứng viên duy nhất) còn hiệu lực, tô sáng ô đó cùng vùng tiêu điểm (focus), đồng thời giải thích các ô bị loại trừ S1 bằng các chú mèo nguồn.
* **Current rule:** [GR-21..24](../../GDD/02-luat-choi-va-trang-thai.md#L55-L64), [LV-03](../../GDD/04-thiet-ke-level.md#L9), [UX-14](../../GDD/03-luong-man-hinh-va-ux.md#L55): Hint miễn phí hoàn toàn (không tốn tim, không trừ điểm), có thể dùng vô hạn lần. Hint tính toán động từ trạng thái mèo hiện có, bỏ qua các dấu X tự đặt và `x_error`.
* **Why it may be a problem:**
  1. *Nguy cơ lạm dụng (Hint Spamming):* Vì Hint hoàn toàn miễn phí và không có thời gian hồi chiêu (cooldown), người chơi lười suy nghĩ có thể bấm Hint liên tục từ đầu đến cuối màn để game "dắt tay chỉ việc", triệt tiêu hoàn toàn trải nghiệm giải đố.
  2. *Mâu thuẫn với ghi chú của người chơi:* Nếu người chơi tự đánh dấu X sai vào ô đáp án thật, khi bấm Hint, hệ thống sẽ tô sáng chính ô đó và bảo người chơi "Hãy chạm đúp vào đây để đặt Mèo". Điều này có thể khiến người chơi cảm thấy hệ thống gợi ý đang "phủ nhận" suy nghĩ của mình mà không giải thích vì sao dấu X của họ bị sai.
* **Evidence already available:** Validator S2 và hint logic contract đã được chứng minh qua unit tests ([`test_interaction_contract.py`](../../GDD/tools/test_interaction_contract.py)); GDD v0.4.2 đã loại bỏ ý tưởng bán hint bằng vàng (tránh poverty trap theo [REV-ECO-01](../archive/reviews/02-danh-gia-ban-thiet-ke-v04.md#L46-L59)).
* **What is still unknown:** Tỷ lệ người chơi thực sự đọc dòng giải thích logic so với tỷ lệ chỉ nhìn vào ô tô sáng rồi chạm đúp ngay lập tức.
* **Alternative A:** Giữ nguyên v0.4.2: Hint miễn phí vô hạn, không cooldown, tính toán động dựa trên S2.
* **Alternative B:** Thêm Cooldown mềm (Soft Cooldown): Giữ Hint miễn phí nhưng sau mỗi lần dùng, nút Hint cần thời gian hồi 15–30 giây (hoặc chỉ mở sau khi người chơi thực hiện ít nhất 2 thao tác trên bàn) để khuyến khích tự suy nghĩ.
* **Alternative C:** Gợi ý 2 nấc (Two-tier Hint): Nấc 1 chỉ tô sáng hàng/cột/vùng cần chú ý ("Hãy nhìn vào Vùng B"); chỉ khi bấm lần nữa mới chỉ đích danh ô cần đặt.
* **Trade-offs:** 
  * *Phương án A:* Tránh hoàn toàn bế tắc cho người chơi kém, nhưng có nguy cơ làm hỏng nhịp thử thách.
  * *Phương án B:* Hạn chế tối đa hành vi spam, bảo tồn tính giải đố mà không tốn tài nguyên kinh tế.
  * *Phương án C:* Tính sư phạm hoàn hảo nhất, giúp người chơi tự ngộ ra nghiệm, nhưng tăng độ phức tạp giao diện gợi ý.
* **Recommended validation method:** Ghi nhận telemetry nội bộ tại M1: Đếm số lần yêu cầu Hint trên mỗi level (`hintCount`). Nếu `hintCount >= N` ở đa số người chơi, cần áp dụng Alternative B.
* **When to decide:** **M1**.

---

### GD-09 — Tiến trình Tuyến tính 24 Level (Linear 24-Level Progression)
* **GD-ID:** GD-09
* **Observation:** Cấu trúc tiến trình của MVP cực kỳ tinh gọn: Đúng 24 level xếp theo thứ tự `1..24`. Không có màn hình chọn level (Level Select), không có bản đồ/chương, không cho phép chơi lại level cũ, không cho phép bỏ qua level chưa hoàn thành.
* **Current rule:** [D-01](../../GDD/01-tam-nhin-va-pham-vi.md#L15), [GR-26..28](../../GDD/02-luat-choi-va-trang-thai.md#L70-L73), [DEC-001](../governance/02-decision-log.md#L6-L16): Chỉ lưu trữ tiến trình level hiện tại. Thắng thì tiến lên `order + 1`. Hoàn thành level 24 thì hiển thị thông báo kết thúc nội dung.
* **Why it may be a problem:**
  1. *Bức tường cản (Hard Churn Wall):* Tuyến tính 100% đồng nghĩa với việc nếu người chơi gặp một level không hợp gu hoặc bị kẹt suy luận (ví dụ level 17), họ bị chặn đứng hoàn toàn. Không thể bỏ qua, không thể quay lại chơi các level cũ để giải tỏa tâm lý -> Hành vi duy nhất còn lại là thoát game và gỡ cài đặt.
  2. *Giá trị chơi lại bằng không (Zero Replay Value):* Sau khi giải xong 24 level (ước tính mất 45–75 phút tổng thời gian), người chơi không có bất kỳ lý do hay cơ chế nào để mở lại ứng dụng.
* **Evidence already available:** [DEC-001](../governance/02-decision-log.md#L6-L16) bảo vệ quyết định này để cắt giảm tối đa scope cho MVP; [REV-GD-03](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L74-L84) chỉ ra D1/D7 retention sẽ chạm đáy nếu không có meta.
* **What is still unknown:** Tỷ lệ người chơi hoàn thành trọn vẹn 24 level trong 1 session đầu tiên; điểm kẹt (drop-off cliff) xuất hiện tại level số mấy.
* **Alternative A:** Giữ nguyên 24 level tuyến tính tuyệt đối cho MVP: Không thêm menu chọn màn hay replay để đảm bảo ngày phát hành M0/M1 đúng hạn.
* **Alternative B:** Mở khóa danh sách Level Select tối giản: Màn hình Home có thêm nút "Danh sách màn" hiển thị 24 ô số. Level nào đã qua thì có thể bấm vào chơi lại; level hiện tại đang mở; các level sau bị khóa.
* **Alternative C:** Cơ chế Bỏ qua có điều kiện (Skip Level): Nếu người chơi thất bại 3 lần liên tiếp ở một level, cho phép họ tạm thời bỏ qua màn đó để tiến lên level tiếp theo.
* **Trade-offs:** 
  * *Phương án A:* Giữ save schema ở phiên bản gọn gàng nhất (`currentLevelOrder: int`), không lo quản lý trạng thái sao/kết quả đa màn.
  * *Phương án B:* Tăng giá trị chơi lại lên gấp 3 lần với chi phí phát triển UI rất nhỏ (1 màn hình GridView đơn giản), cho phép người chơi khoe hoặc giải lại các màn mình thích.
* **Recommended validation method:** Đo lường tổng thời lượng trải nghiệm (Total Playtime) trong playtest M1. Nếu người chơi giải hết 24 level dưới 40 phút và muốn chơi tiếp, ưu tiên bổ sung Alternative B ngay trước khi đóng gói phát hành.
* **When to decide:** **M1** (hoặc chuyển sang Post-MVP nếu nguồn lực UI bị hạn chế).

---

### GD-10 — Nhịp độ Độ khó (Difficulty Progression)
* **GD-ID:** GD-10
* **Observation:** Đường cong độ khó dự kiến chia làm 3 chặng: Level 1–4 (4×4, hướng dẫn, 1–3 phút), Level 5–12 (4×4–5×5, dễ, 2–4 phút), Level 13–24 (5×5–6×6, trung bình, 3–6 phút). Quy tắc suy luận bị giới hạn cứng ở S1 (loại trừ) và S2 (ứng viên đơn). Quy tắc S3 (Giao thoa / Intersection) bị hoãn lại sau MVP.
* **Current rule:** [GDD/01 §2](../../GDD/01-tam-nhin-va-pham-vi.md#L28-L33), [GDD/04 §2/§3](../../GDD/04-thiet-ke-level.md#L18-L36), [DEC-002](../governance/02-decision-log.md#L17-L27): Chỉ phát hành các level có nghiệm duy nhất và giải được hoàn toàn bằng trace S2. Cứ sau 3–4 level tăng khó phải có 1 level nghỉ (pacing rest). Level 10 và 20 là mốc đặc biệt.
* **Why it may be a problem:**
  1. *Nghịch lý độ sâu câu đố (The S2 Constraint Ceiling):* Trên bàn 5×5 và 6×6, nếu một bài toán giải được thuần túy bằng S2 mà không cần S3, thì bài toán đó hoặc là:
     * Quá tầm thường (luôn có vùng 1 ô hoặc các hàng trống lộ liễu, không tạo được cảm giác thỏa mãn trí tuệ).
     * Hoặc phải phụ thuộc vào việc cấp sẵn quá nhiều Mèo cho sẵn (`givens`), làm giảm tính chủ động của người chơi.
  2. *Hình dạng vùng quái dị (Contorted Regions):* Để ép bàn cờ 6×6 giải được bằng S2 mà không cho givens, người tạo màn buộc phải uốn éo các vùng màu thành những hình thù ngoằn ngoèo, khiến bàn cờ cực kỳ khó đọc thị giác, vi phạm tiêu chí thẩm mỹ.
* **Evidence already available:** [REV-TECH-04](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L121-L129) đã cảnh báo về giới hạn của S1/S2; [DQ-001](../governance/01-open-questions.md#L7-L20) và [DQ-008](../governance/01-open-questions.md#L105-L118) đang là các blocker mở lớn nhất của dự án.
* **What is still unknown:** Liệu đội ngũ Level Designer có thể tạo ra 12 màn chơi 6×6 (Level 13–24) vừa thanh lịch, vừa thú vị, vừa hoàn toàn giải được bằng S2 mà không cần đoán mò hay không.
* **Alternative A:** Giữ vững giới hạn S1/S2 cho toàn bộ 24 level MVP: Chấp nhận một số màn 6×6 có givens hỗ trợ hoặc cấu trúc vùng dễ để đảm bảo tiến độ dev validator và hint không bị vỡ.
* **Alternative B:** Mở S3 có kiểm soát cho chặng cuối Level 19–24: Nâng cấp validator và hint engine để hỗ trợ quy tắc Khóa giao thoa (S3) chỉ cho 6 level khó nhất, giúp giải phóng tiềm năng thiết kế câu đố.
* **Alternative C:** Điều chỉnh phân bổ kích thước bàn: Giảm bớt số lượng bàn 6×6 trong MVP (chỉ để 4 bàn cuối), tăng tỷ trọng bàn 4×4 và 5×5 chất lượng cao.
* **Trade-offs:** 
  * *Phương án A:* Đảm bảo tuyệt đối an toàn kỹ thuật cho MVP theo schema cũ và validator S2, không cần viết lại.
  * *Phương án B:* Chất lượng giải đố vượt bậc, nhưng rủi ro kéo dài tiến độ phát triển validator và viết lại logic giải thích của Hint.
  * *Phương án C:* Giải pháp dung hòa khôn ngoan nhất: Tận dụng tối đa không gian thiết kế của 4×4 và 5×5 mà không làm căng thẳng hệ thống suy luận S2.
* **Recommended validation method:** Biên tập thủ công 3 ứng viên level 6×6 thuần S2 tại M1, cho người giải mù (blind solve). Đo thời gian giải, số lần kẹt và cảm nhận về "độ thông minh" của câu đố.
* **When to decide:** **Design Freeze** (chốt dứt điểm DQ-001: Không đưa S3 vào MVP, áp dụng Alternative C nếu 6×6 thuần S2 gặp bế tắc).

---

### GD-11 — Tiến trình Hướng dẫn Người chơi (Tutorial Progression)
* **GD-ID:** GD-11
* **Observation:** Hệ thống hướng dẫn được tích hợp trực tiếp vào 4 level đầu tiên (Level 1–4) thông qua 6 mốc T1–T6: T1 (Chạm đặt X), T2 (Chạm xóa X), T3 (Chạm đôi đặt Mèo), T4 (Xem minh họa X đỏ trong Help), T5 (Hint và luật không chạm chéo), T6 (Kéo đánh/xóa X hàng loạt).
* **Current rule:** [GDD/01 §4](../../GDD/01-tam-nhin-va-pham-vi.md#L43), [UX-04](../../GDD/03-luong-man-hinh-va-ux.md#L32), [GDD/03 §4](../../GDD/03-luong-man-hinh-va-ux.md#L62-L76): Riêng ở T1–T3, thao tác sai **trên ô được tô sáng** được nhắc nhở mà không bị phạt tim hay đặt X đỏ. Thao tác trên ô khác ngoài ô tô sáng vẫn bị xử lý theo luật phạt thông thường.
* **Why it may be a problem:**
  1. *Cạm bẫy phạt người mới:* Người mới chơi màn hình cảm ứng thường có thao tác vụng về (ngón tay chạm lệch 5–10 pt sang ô bên cạnh ô tô sáng). Quy định "chỉ miễn phạt trên ô tô sáng, ô khác vẫn phạt bình thường" sẽ khiến một người đang học việc bị mất tim và dính X đỏ ngay ở phút đầu tiên chỉ vì một cú chạm lệch mép.
  2. *Dạy thao tác cơ học thay vì dạy tư duy suy luận:* T1–T3 dạy người chơi *cách bấm nút*, nhưng không dạy họ *vì sao ô đó có Mèo*. Người chơi có thể hoàn thành Level 1 mà hoàn toàn không hiểu quy tắc "vùng 1 ô thì bắt buộc phải có Mèo".
  3. *Ngắt quãng trải nghiệm ở T4:* Bắt người chơi mở màn hình Trợ giúp ở T4 để xem X đỏ làm đứt gãy mạch cảm xúc đang chơi trên bàn.
* **Evidence already available:** [GDD/01 §4](../../GDD/01-tam-nhin-va-pham-vi.md#L43) đặt cổng chất lượng "Ít nhất 8/10 người mới hoàn thành hướng dẫn và hiểu X đỏ"; [ASM-011](../governance/04-assumptions.md#L18) ghi nhận tutorial script chưa được kiểm chứng thực tế.
* **What is still unknown:** Tỷ lệ người chơi mới chạm trượt ra ngoài vùng tô sáng trong Level 1 và 2.
* **Alternative A:** Giữ nguyên quy tắc v0.4.2: Giữ kịch bản T1–T6 và quy tắc miễn trừ có điều kiện như hiện tại.
* **Alternative B:** Chế độ Bất tử tuyệt đối trong Level 1–2 (Invulnerable Onboarding): Trong suốt Level 1 và Level 2 (toàn bộ bàn cờ), mọi thao tác sai đều chỉ hiện nhắc nhở/lắc nhẹ ô, hoàn toàn không trừ tim và không tạo `x_error` để người chơi tự do làm quen.
* **Alternative C:** Tích hợp giải thích logic trực quan: Khi hướng dẫn đặt Mèo ở T3, thêm bong bóng thoại ngắn giải thích logic: "Vùng này chỉ có 1 ô duy nhất, Mèo chắc chắn ở đây!".
* **Trade-offs:** 
  * *Phương án A:* Bảo đảm tính nghiêm minh của code luật từ sớm, nhưng rủi ro rơi rụng người chơi ở phễu đầu vào (Top-of-Funnel Drop-off) rất cao.
  * *Phương án B/C:* Tạo khởi đầu cực kỳ êm ái, thân thiện, truyền đạt đúng tinh thần game ấm áp mà chi phí điều kiện kiểm tra (flag `level.isTutorial`) là vô cùng nhỏ.
* **Recommended validation method:** Usability Testing với 5 người chưa từng chơi game logic dạng lưới ở M1. Quan sát phản ứng và cử chỉ tay của họ trong 3 phút đầu tiên.
* **When to decide:** **M1**.

---

### GD-12 — Rủi ro Ức chế của Người chơi (Player Frustration Risks)
* **GD-ID:** GD-12
* **Observation:** Khi tổng hợp toàn bộ các quyết định thiết kế: (1) Cửa sổ nhận diện 2-chạm 280 ms nhạy cảm, (2) Không có Undo, (3) 3 tim phạt cứng, (4) `x_error` khóa vĩnh viễn, (5) Reset 100% bàn cờ khi thua, (6) Không có nút Restart giữa ván, và (7) Tiến trình tuyến tính không thể bỏ qua màn.
* **Current rule:** Tổ hợp các điều khoản: [GR-13/16/17/19/28](../../GDD/02-luat-choi-va-trang-thai.md), [D-04](../governance/02-decision-log.md#L32), [DEC-004](../governance/02-decision-log.md#L39-L49).
* **Why it may be a problem:**
  * Đây là hiện tượng **"Sự cộng hưởng ức chế" (Compounding Frustration Stack)**.
  * Một lỗi thao tác vật lý nhỏ nhất (Touch Jitter) dẫn thẳng tới mất mạng -> Không thể hoàn tác -> Tích lũy 3 lỗi làm nổ tung toàn bộ thành quả của 5 phút suy luận -> Buộc phải chơi lại từ đầu cùng một màn chơi đó.
  * Chuỗi trừng phạt này phù hợp với thể loại Hardcore Roguelike hoặc Dark Souls, nhưng là một "tai nạn thiết kế" đối với một tựa game mang đề tài "Mèo con dễ thương" hướng tới nhân viên văn phòng giải tỏa căng thẳng giờ nghỉ trưa.
* **Evidence already available:** [01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md) và [02-danh-gia-ban-thiet-ke-v04.md](../archive/reviews/02-danh-gia-ban-thiet-ke-v04.md) đều nhấn mạnh sự tàn nhẫn của chuỗi phạt này; [RISK-001](../governance/03-risk-register.md#L8) và [RISK-002](../governance/03-risk-register.md#L9) đều xếp mức High/High.
* **What is still unknown:** Mức độ chịu đựng (Tolerance Threshold) của tệp người chơi mục tiêu tại thị trường Việt Nam đối với game giải đố dạng này.
* **Alternative A:** Giữ nguyên hiện trạng MVP: Giữ toàn bộ luật cứng để kiểm tra phản ứng cực đoan nhất trong playtest nội bộ.
* **Alternative B:** Phá vỡ mắt xích chết người (Giảm nhẹ ít nhất 2 yếu tố):
  1. Thêm nút **Restart** giữa ván để người chơi chủ động làm lại khi muốn.
  2. Bổ sung cơ chế **Bảo vệ ngón tay (Touch Tolerance)**: Nếu 2-chạm diễn ra trên 2 ô kề sát nhau trong 150 ms, không nhận diện là Mèo sai mà hủy lệnh.
* **Alternative C:** Cơ chế Second Chance miễn phí 1 lần/ván: Khi tim về 0, chú mèo trên màn hình kêu một tiếng "Meow" dễ thương và tặng người chơi thêm 1 tim duy nhất để giải nốt ván chơi (Pity Mechanic).
* **Trade-offs:** 
  * *Phương án A:* Dễ làm cho dev nhất, nhưng rủi ro thất bại về mặt trải nghiệm là gần như chắc chắn.
  * *Phương án B/C:* Giữ nguyên được 90% luật chơi cốt lõi nhưng tháo ngòi được "quả bom ức chế", mang lại cảm giác thân thiện, ấm lòng cho người chơi.
* **Recommended validation method:** Đánh giá chỉ số cảm xúc (Affective State Analysis) trong playtest M1: Đếm số lần người chơi thở dài, cau mày hoặc thốt lên bực bội trong suốt phiên chơi 20 phút.
* **When to decide:** **M1**.

---

### GD-13 — Động lực Người chơi trong một Phiên (Player Motivation During a Session)
* **GD-ID:** GD-13
* **Observation:** Trong phiên chơi MVP, động lực duy nhất của người chơi là động lực nội tại (Intrinsic Motivation): niềm vui khi tự mình giải được câu đố logic. Các yếu tố thúc đẩy ngoại tại (Extrinsic Motivation) chỉ bao gồm: chữ khen ngợi "Nice!" / "Great!", một sticker chúc mừng 2D ở màn thắng, và số thứ tự level tăng lên 1 đơn vị.
* **Current rule:** [GDD/01 §1](../../GDD/01-tam-nhin-va-pham-vi.md#L9), [GDD/02 §7](../../GDD/02-luat-choi-va-trang-thai.md#L91), [DEC-011](../governance/02-decision-log.md#L116-L126): Toàn bộ hệ thống Vườn Mèo, nuôi mèo, bộ sưu tập, mua sắm đều bị loại khỏi MVP. Mọi ô Mèo đều dùng chung sprite mèo mặc định.
* **Why it may be a problem:**
  * Động lực nội tại giải đố là đủ đối với người đam mê Sudoku/Nonogram. Nhưng trò chơi lại đặt tên là **Vườn Mèo** và dùng hình ảnh đại diện là mèo dễ thương để thu hút người dùng.
  * Người chơi tải game vì kỳ vọng được "chăm sóc mèo, xây vườn, ngắm mèo". Khi vào game, họ chỉ thấy một bàn cờ hình học khô khan lặp đi lặp lại 24 lần. Sự lệch pha giữa **Lời hứa thương hiệu (Brand Promise)** và **Thực tế gameplay (Gameplay Reality)** sẽ làm suy giảm động lực duy trì phiên chơi sau 3–4 màn đầu tiên.
* **Evidence already available:** [REV-META-01](../archive/reviews/02-danh-gia-ban-thiet-ke-v04.md#L96-L108) phân tích sâu về sự thiếu vắng bản sắc "Vườn Mèo"; [DEC-011](../governance/02-decision-log.md#L116-L126) đã chốt cắt bỏ Garden Lobby và Petting để giữ scope MVP.
* **What is still unknown:** Mức độ thất vọng của người chơi casual khi nhận ra game hoàn toàn không có tính năng "Vườn" trong bản phát hành đầu.
* **Alternative A:** Giữ nguyên MVP thuần túy Puzzle: Chấp nhận game chỉ là một ứng dụng giải đố thuần khiết, dựa hoàn toàn vào độ cuốn hút của core puzzle.
* **Alternative B:** Phần thưởng Sticker Album siêu nhẹ (Lightweight Sticker Book): Không làm vườn 3D hay petting phức tạp, nhưng mỗi khi vượt qua 1 level, chú mèo tặng cho người chơi một "tem dán" (sticker). Màn hình Home có một nút nhỏ mở cuốn "Sổ sưu tập tem Mèo" để người chơi ngắm lại các thành quả của mình.
* **Alternative C:** Trạng thái Mèo ở màn hình Home biến đổi theo tiến độ: Ở màn hình Home, chú mèo mặc định sẽ có các tư thế khác nhau tùy theo số level đã vượt qua (Level 1: Mèo đang ngủ; Level 10: Mèo ngồi chơi cuộn len; Level 20: Mèo đeo vương miện).
* **Trade-offs:** 
  * *Phương án A:* Scope tối thiểu, rủi ro kỹ thuật bằng 0.
  * *Phương án B:* Tạo động lực sưu tầm cực mạnh với chi phí phát triển 2D tĩnh rất thấp.
  * *Phương án C:* Tận dụng chính các frame animation sẵn có của mèo để làm sống động màn Home mà không cần thêm code hệ thống mới.
* **Recommended validation method:** Phỏng vấn người chơi sau playtest M1: "Điều gì khiến bạn muốn bấm nút chơi màn tiếp theo?".
* **When to decide:** **M1** (Cân nhắc đưa Alternative C vào đánh bóng sản phẩm nếu còn dư thời gian trước release).

---

### GD-14 — Tính Phù hợp của Phạm vi MVP (Scope Appropriateness for MVP)
* **GD-ID:** GD-14
* **Observation:** Phạm vi MVP được định nghĩa rất chặt chẽ và có tính kỷ luật cao: 24 level liên tiếp (N=4–6), logic S1/S2, đồ họa 2D sprite sheet render offline từ model 3D, chơi offline 100%, không tài khoản, không SDK quảng cáo, không IAP, không zoom/pan.
* **Current rule:** [GDD/01 §2](../../GDD/01-tam-nhin-va-pham-vi.md#L13-L23), [00-design-status §3](../governance/00-design-status.md#L33-L44), [DEC-001..012](../governance/02-decision-log.md): Toàn bộ các tính năng meta, kinh tế, sinh màn ngẫu nhiên đều được đánh dấu rõ ràng là DEFERRED / POST-MVP.
* **Why it may be a problem:**
  * Nhìn chung, phạm vi này là **rất xuất sắc và mẫu mực** cho một nhóm phát triển tinh gọn nhằm chứng minh Core Gameplay (Proof of Concept).
  * Tuy nhiên, có một rủi ro tiềm ẩn: **Sự quá tải của trần kỹ thuật tương lai (Future-Proofing Overkill)**. Việc schema và engine cố gắng hỗ trợ N=12 ngay từ đầu ([LV-01](../../GDD/04-thiet-ke-level.md#L7)) trong khi thiết bị mục tiêu là điện thoại dọc không zoom/pan tạo ra một khoản "nợ kiến trúc" (architectural overhead) trong việc kiểm thử và mở rộng dữ liệu mà thực tế bản thân MVP không dùng tới.
* **Evidence already available:** Fixture N12 đã được đưa vào kiểm thử kỹ thuật ([`levels.sample.json`](../../GDD/data/levels.sample.json)); [REV-TECH-03](../archive/reviews/01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md#L110-L119) chỉ ra ô 12×12 trên điện thoại chỉ rộng ~26 pt, vi phạm chuẩn công thái học.
* **What is still unknown:** Liệu việc duy trì hỗ trợ N=12 trong schema có gây cản trở hay làm phức tạp hóa code render bàn cờ ở M0 hay không.
* **Alternative A:** Giữ nguyên kiến trúc hiện tại: Schema nhận N=4–12, phát hành N=4–6.
* **Alternative B:** Khóa trần thực tế ở N=8 hoặc N=9: Điều chỉnh trần dữ liệu tối đa trên mobile portrait xuống N=8 (kích thước tối đa ngón tay người bấm được trên màn hình 360 pt mà không cần zoom). N=10–12 chỉ xét đến khi làm bản tablet.
* **Trade-offs:** Giữ A giúp bảo toàn baseline schema cũ; chuyển sang B giúp thực tế hóa toàn bộ tài liệu và giảm áp lực test biên.
* **Recommended validation method:** Kiểm tra bố cục bàn cờ và vùng chạm trên thiết bị thật ở M0 ([RES-M0-04](../governance/05-research-backlog.md#L21)).
* **When to decide:** **M0** (nếu N=12 gây rắc rối cho UI anchoring trong Godot, hạ trần xuống N=8).

---

### GD-15 — Ảnh hưởng của Hệ thống Meta Tương lai lên MVP (Future Meta Influence on MVP)
* **GD-ID:** GD-15
* **Observation:** Mặc dù GDD v0.4.2 và các tài liệu điều hành đều khẳng định các hệ sinh thái Meta (Ví vàng, cứu lượt, quảng cáo thưởng, mua mèo) đều bị hoãn sang Post-MVP ([GDD/11](../../GDD/11-ke-hoach-meta-va-sinh-level.md), [DEC-010](../governance/02-decision-log.md#L105-L115)), nhưng **"cái bóng" của các hệ thống này vẫn đang chi phối và bóp méo trực tiếp thiết kế của MVP**.
* **Current rule:** 
  * [GR-18](../../GDD/02-luat-choi-va-trang-thai.md#L48): Công thức tính điểm `100 × cat − 25 × mistake` tồn tại trong MVP chỉ vì [GDD 11 §2](../../GDD/11-ke-hoach-meta-va-sinh-level.md#L14) muốn dùng điểm để chia 50 đổi ra vàng!
  * [GR-17/19](../../GDD/02-luat-choi-va-trang-thai.md#L47-L49): Cơ chế phạt thua khi hết 3 tim tồn tại chỉ để làm tiền đề cho tính năng "Cứu lượt bằng vàng hoặc xem quảng cáo thưởng" ở [GDD 11 §2](../../GDD/11-ke-hoach-meta-va-sinh-level.md#L25)!
* **Why it may be a problem:**
  * Đây là một sai lầm phổ biến trong thiết kế game: **Đưa hình phạt của nền kinh tế F2P (Tim, Game Over) vào một phiên bản chưa hề có nền kinh tế F2P!**
  * Hậu quả là người chơi MVP phải gánh chịu toàn bộ sự khắc nghiệt của cơ chế phạt tiền tệ (mất mạng, trừ điểm) nhưng lại không nhận được bất kỳ lợi ích hay phần thưởng nào từ nền kinh tế đó (không có vàng để xài, không có mèo để đổi). MVP bị biến thành một "bản demo bị cắt cụt" thay vì một trò chơi hoàn chỉnh, độc lập và dễ chịu.
* **Evidence already available:** [REV-ECO-01](../archive/reviews/02-danh-gia-ban-thiet-ke-v04.md#L46-L59) vạch trần bẫy nghèo đói; [RISK-015](../governance/03-risk-register.md#L22) cảnh báo về sự rò rỉ đề xuất lịch sử; [06-design-freeze-checklist §3](../governance/06-design-freeze-checklist.md#L23-L30) yêu cầu cô lập hoàn toàn Meta.
* **What is still unknown:** Mức độ gắn kết giữa code Core của MVP và các interface chuẩn bị cho Meta tương lai.
* **Alternative A:** Chấp nhận sự hiện diện của điểm số và 3 tim như những di sản chuẩn bị cho bản cập nhật sau.
* **Alternative B (Thanh lọc hoàn toàn tư duy thiết kế MVP — Pure MVP Isolation):**
  * Tuyên bố rõ ràng trong GDD: Trong phạm vi MVP, điểm số thuần túy là chỉ số thành tích ván đấu (Scorecard), không hứa hẹn bất kỳ sự quy đổi nào.
  * Luật 3 tim phải tự chứng minh được giá trị Game Design của chính nó (tạo cảm giác thử thách trí tuệ) mà không được phép dựa vào lý lẽ "sau này sẽ có nút cứu lượt".
* **Trade-offs:** Phương án B đòi hỏi đội ngũ thiết kế phải dũng cảm nhìn nhận trải nghiệm MVP một cách độc lập, sẵn sàng điều chỉnh luật tim nếu playtest cho thấy nó gây hại, thay vì bảo thủ bám víu vào kế hoạch Post-MVP.
* **Recommended validation method:** Rà soát lại toàn bộ Design Freeze Checklist ([`06-design-freeze-checklist.md`](../governance/06-design-freeze-checklist.md)) trước khi bước vào sản xuất: Cắt đứt mọi sự phụ thuộc về mặt logic giữa MVP và GDD 11.
* **When to decide:** **Design Freeze** (Ngay lập tức).

---

## III. Tổng kết Chiến lược Thiết kế (Design Synthesis)

### 1. Resolution của ba blocker và cổng bằng chứng còn lại

1. **DQ-001 đã đóng bằng DEC-013:** S3 bắt buộc cho từng level 19–24, schema v4; 1–18 chỉ S1/S2. Cổng còn lại là runtime Hint và sáu level thật trước M2.
2. **DQ-009 đã đóng bằng DEC-016/GDD 07:** Level đạt khi đủ mèo với ≥1 tim, qua uniqueness/trace đúng band/không đoán và có blind solve ≥1 tim cùng biên bản. Campaign còn cần playtest 10 người, device và accessibility evidence.
3. **GD-06 đã đóng bằng DEC-014:** MVP có Restart xác nhận và Undo một action X, với contract v2. Runtime Godot còn phải replay QA-54/55 ở M0.

Design Freeze vẫn chưa sẵn sàng vì DQ-002 chưa được owner phê duyệt, chưa có bằng chứng M0 trên thiết bị và chưa có content/runtime Hint S3 M2.

### 2. Hypotheses (Các giả thuyết trải nghiệm cần kiểm chứng bằng dữ liệu tại M0/M1)
1. **Giả thuyết Cảm ứng vi mô (H-Touch):** Cửa sổ 280 ms và ngưỡng kéo 12 pt logic là đủ để người chơi Việt Nam thao tác mượt mà trên các thiết bị Android tầm thấp mà không kích hoạt nhầm `TryCat` quá 3% tổng số thao tác. *(Kiểm chứng tại M0 qua replay vector trên thiết bị thật)*.
2. **Giả thuyết Công bằng của 3 Tim (H-Fairness):** Người chơi chấp nhận hình phạt 3 tim như một thử thách thể hiện sự thông minh chứ không cảm thấy bị trừng phạt bất công khi giải các bàn 5×5 và 6×6. *(Kiểm chứng tại M1 qua playtest người dùng thật)*.
3. **Giả thuyết Chiều sâu theo band (H-Depth):** Đội ngũ thiết kế có thể tạo 18 level S1/S2 và 6 level cuối thực sự cần S3, đều hấp dẫn, dễ đọc và không lạm dụng givens. *(Kiểm chứng M1/M2 qua validator và blind solve ≥1 tim)*.
4. **Giả thuyết Đọc vùng độc lập với ngoại hình Mèo (H-Visual):** Bảng màu 6 vùng kết hợp với họa tiết/nhãn A–F trên bàn cờ là đủ để người chơi phân biệt các miền liên thông trong 0.5 giây mà không cần tô màu lông mèo theo vùng. *(Kiểm chứng tại M0 qua bài test nhận diện thị giác)*.

### 3. Current Decisions to Retain (Giữ làm baseline, vẫn phải đo trên runtime)
1. **Kiến trúc Đồ họa 2D Sprite Sheet kết xuất từ 3D (DEC-006 / REV-TECH-01):** Dùng 2D Sprite Sheet thay `SubViewport` 3D runtime nhằm giảm tải render. Đây là hướng baseline; FPS, nhiệt và bộ nhớ vẫn phải đo trên thiết bị M0 theo TECH-19/21 trước khi xác nhận đạt ngân sách.
2. **Cơ chế Cử chỉ Optimistic Preview & Drag Stroke (DEC-003 / REV-UX-01):** Đánh dấu X preview ngay và hỗ trợ kéo nhiều ô nhằm giảm cảm giác trễ. Cửa sổ 280 ms, ngưỡng 12 pt logic, rollback và tỷ lệ `TryCat` nhầm vẫn là giả thuyết cần kiểm chứng M0.
3. **Mèo mặc định dùng chung, không mã hóa vùng (DEC-007 / REV-TECH-05):** Giảm số biến thể atlas và áp lực bộ nhớ so với mèo riêng từng vùng. Chưa có số đo VRAM/OOM; phải đo trên thiết bị RAM thấp tại M0 thay vì coi ngân sách đã được chứng minh.
4. **Offline-first, không mạng, không quảng cáo trong MVP (DEC-008):** Giữ cho phạm vi phát triển tập trung 100% vào chất lượng game, loại bỏ các rủi ro phức tạp về tuân thủ chính sách quyền riêng tư của Google Play / App Store trong đợt phát hành đầu.
5. **Hint mang tính sư phạm, một lần mỗi lượt (GR-21..24):** Không thương mại hóa Hint trong MVP; dùng S2 hoặc chuỗi S3→S2 để dạy suy luận, evidence hợp lệ mới tiêu thụ hạn mức.

### 4. Features & Research That Should Be Deferred (Các tính năng và nghiên cứu dứt khoát phải hoãn lại sau MVP)
1. **Toàn bộ hệ thống Kinh tế, Ví vàng và Đổi thưởng (GDD 11 §2):** Không viết bất kỳ dòng code nào cho ledger, wallet, hay tỷ lệ đổi điểm ra vàng trong MVP. Toàn bộ tính năng này chỉ được xem xét khi MVP chứng minh được tỷ lệ giữ chân người chơi (Retention).
2. **Cơ chế Cứu lượt bằng Xem Quảng cáo Thưởng (Rewarded Ads Rescue):** Không tích hợp bất kỳ ad mediation hay ad network SDK nào vào build MVP.
3. **Hệ thống Vườn Mèo và Bộ sưu tập ngoại hình (Cat Compendium / Garden Lobby):** Giữ giao diện Home ở mức tối giản theo [UX-01](../../GDD/03-luong-man-hinh-va-ux.md#L30). Không triển khai tính năng chọn mèo hay đổi sprite mèo trong đợt phát hành 24 level đầu.
4. **Nghiên cứu Quy tắc Suy luận Nâng cao S4 (Cặp khóa) và S5 (Phản chứng):** Đưa thẳng vào nhóm **PARKED** ([05-research-backlog.md](../governance/05-research-backlog.md#L47-L48)). Không tiêu tốn bất kỳ giờ làm việc nào của kỹ thuật hay thiết kế vào S4/S5 trước khi game ra mắt thị trường.
5. **Nội dung Level N=7–12 và Zoom/Pan:** Đóng băng hoàn toàn nội dung N > 6. Chỉ giữ schema kỹ thuật, không sản xuất level, không thiết kế UI co giãn cho N=12 trên điện thoại dọc.
6. **Bộ sinh level tự động ngoại tuyến (Offline Generator):** Toàn bộ 24 level phát hành đầu tiên phải được **biên tập thủ công 100% bằng tay (Hand-crafted)** để đảm bảo độ tinh tế, nhịp thở và câu chuyện logic hoàn hảo. Máy sinh level chỉ phục vụ cho việc mở rộng từ level 25 trở đi sau khi MVP đã thành công.
