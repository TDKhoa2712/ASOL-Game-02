> HISTORICAL — Nội dung có thể đã bị GDD v0.5.0 supersede; không dùng làm requirement triển khai.

# 01 — Rà soát & Đánh giá Toàn diện Thiết kế và Kiến trúc Game "Vườn Mèo"

**Ngày lập:** 2026-09-18  
**Tác giả đánh giá:** Senior Game Programmer & Lead Game Designer  
**Đối tượng sử dụng:** Các Coding Agent, Game Designer, Developer tiếp nhận dự án  
**Tài liệu đối chiếu:** Toàn bộ đặc tả GDD v0.3 (`GDD/01` đến `GDD/09`)

---

## 1. Mục đích tài liệu
Tài liệu này ghi nhận các **thiếu sót, điểm nghẽn trải nghiệm người dùng (UX bottleneck), mâu thuẫn cơ chế gameplay và rủi ro kỹ thuật tiềm ẩn** trong bản đặc tả GDD v0.3. 

Mục tiêu nhằm giúp các Agent/Developer tham gia phát triển:
1. Nhìn thấy các rủi ro trước khi bắt tay vào hiện thực hóa code (tránh đập đi xây lại).
2. Có căn cứ đề xuất chỉnh sửa luật hoặc cấu trúc kỹ thuật theo đúng quy trình (sửa GDD, schema, validator và test đồng bộ theo quy định tại `AGENTS.md`).
3. Theo dõi tiến độ giải quyết từng vấn đề thông qua bảng mã định danh.

---

## 2. Bảng tổng hợp vấn đề (Issue Matrix)

| Mã ID | Phân loại | Mức độ | Điều khoản GDD liên quan | Vấn đề cốt lõi | Trạng thái đề xuất |
| :--- | :--- | :---: | :--- | :--- | :---: |
| **REV-UX-01** | Input / UX | **Nghiêm trọng** | `GR-09..14`, `UX-09..11`, `TECH-14` | Độ trễ 280ms chặn X tức thì gây cảm giác game bị đơ/lag cảm ứng. | Chờ duyệt giải pháp |
| **REV-GD-01** | Game Feel / Rules | **Cao** | `GR-13`, `GR-16`, `GR-17`, `D-04` | 3 tim + phạt điểm + không Undo gây ức chế khi bấm nhầm; ma sát thao tác thừa với `x_error`. | Đề xuất sửa luật |
| **REV-GD-02** | Motivation / Loop | **Trung bình** | `GR-18`, `UX-03`, `GDD 01 §2` | Điểm số là chỉ số chết (Dead Metric), không kích thích cạnh tranh hay mở khóa. | Đề xuất bổ sung |
| **REV-GD-03** | Retention / Meta | **Cao** | `D-01`, `GR-26..28`, `UX-01` | Tuyến tính 24 level không có lý do quay lại (D1/D7 Retention = 0); thiếu yếu tố "Vườn Mèo". | Đề xuất bổ sung |
| **REV-TECH-01**| Performance / Engine | **Nghiêm trọng** | `D-06`, `TECH-18..19`, `ART-09` | Godot 4 `SubViewport` 3D lồng trong 2D UI gây tụt FPS, shader compilation stutter trên mobile yếu. | Chốt quyết định M0 |
| **REV-TECH-02**| Input Physics | **Trung bình** | `UX-11`, `TECH-03` | Chưa xử lý Touch Slop (độ trượt ngón tay) và Multi-touch / Palm Rejection. | Đề xuất bổ sung spec |
| **REV-TECH-03**| Scalability / UI | **Cao** | `LV-01`, `UX-18`, `QA-35` | N=12 khiến ô chạm chỉ còn ~26pt (vi phạm chuẩn HIG 44pt); Zoom & Pan xung đột cử chỉ Double-tap. | Đề xuất hạ trần |
| **REV-TECH-04**| Logic Depth / Pacing | **Trung bình** | `LV-02..03`, `TECH-04`, `GDD 04 §2`| Giới hạn S1/S2 khiến puzzle ở N=5, 6 dễ rơi vào tầm thường hoặc phải dùng quá nhiều given. | Đề xuất mở sớm S3 |

---

## 3. Chi tiết phân tích và phương án cải tiến

### REV-UX-01: Độ trễ cảm giác (Input Lag) do cửa sổ 280ms nhận diện chạm đôi
* **Hiện trạng GDD:** [GR-09..14](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L28-L34) và [UX-10](file:///D:/Work/Alpaca_Solution/Game-test/GDD/03-luong-man-hinh-va-ux.md#L51) quy định 1 chạm chỉ được xác nhận sau khi hết cửa sổ 280ms (để tránh ghi X trung gian nếu người dùng chạm lần hai).
* **Phân tích rủi ro:**
  * 70–80% thao tác trong game puzzle dạng lưới là **đánh dấu loại trừ (X)**. Người chơi thường lướt gõ liên tục vào 3–5 ô trống.
  * Việc mỗi dấu X bị "ém" lại 280ms mới xuất hiện tạo cảm giác phản hồi cực kỳ chậm chạp, như thể máy bị treo hoặc màn hình cảm ứng bị liệt.
* **Phương án đề xuất:**
  * **Phương án 1 (Khuyến nghị cao nhất): Phản hồi lạc quan (Optimistic Feedback).** Chạm lần 1 hiện X ngay lập tức (<50ms). Nếu chạm lần 2 trong vòng 280ms tại cùng ô, chuyển đổi ngay từ X sang Mèo (`TryCat`). Về mặt thị giác người chơi thấy X nháy nhẹ rồi hóa Mèo, cảm giác tương tác cực kỳ nhạy và tự nhiên.
  * **Phương án 2: Chuyển đổi chế độ bút (Tool Toggle).** Đặt 2 nút chế độ dưới bàn: `[Chế độ X]` và `[Chế độ Mèo]`. Ở chế độ nào thì 1 chạm là thực thi ngay trạng thái đó, triệt tiêu hoàn toàn sự phụ thuộc vào thời gian 280ms.
  * **Phương án 3: Long Press cho Mèo.** 1 chạm = Đánh/Xóa X ngay; Nhấn giữ (Long press ~250ms) = Thử đặt Mèo.

---

### REV-GD-01: Cơ chế phạt tim khắc nghiệt & ma sát thừa từ `x_error`
* **Hiện trạng GDD:** [GR-16](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L42) phạt mất 1/3 tim và trừ 25 điểm khi thử mèo sai; [GR-13](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L32) bắt buộc phải bấm xóa X đỏ rồi mới được thao tác tiếp; [D-04](file:///D:/Work/Alpaca_Solution/Game-test/GDD/README.md#L28) cấm hoàn toàn Undo.
* **Phân tích rủi ro:**
  * Mobile có hiện tượng bấm nhầm tự nhiên do ngón tay che khuất hoặc chạm lệch (fat-finger). Bị phạt mất tim và trừ điểm vì một cú bấm nhầm gây ức chế tâm lý nặng nề, làm mất đi tính "thư giãn, ấm áp" của chủ đề Vườn Mèo.
  * Về mặt tư duy logic: Khi một ô thành X đỏ (đã thử và sai), bản thân X đỏ đã là một ghi chú loại trừ. Bắt người chơi phải tốn thêm một thao tác chạm vào ô đó để "xóa X đỏ về empty" rồi mới làm việc khác là một nấc cản trở (friction) vô lý.
* **Phương án đề xuất:**
  * Bổ sung tính năng **Undo tối thiểu 1–3 bước gần nhất**.
  * Cho phép người chơi giữ nguyên X đỏ trên bàn như một dấu X đặc biệt (hoặc coi X đỏ như X thường), không cấm thao tác ở các ô khác.
  * Tách biệt chế độ: **Thư giãn (Casual - Không giới hạn tim, tự do suy luận)** và **Thử thách (Challenge / Timed - Giữ 3 tim cho đối tượng thích hardcore)**.

---

### REV-GD-02: Điểm số hiện tại là chỉ số chết (Dead Metric)
* **Hiện trạng GDD:** [GR-18](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L44) tính điểm theo công thức `max(0, 100 × correctPlaced − 25 × mistakeCount)`. Điểm chỉ hiển thị khi kết thúc màn, không cộng dồn, không xếp hạng, không dùng để mua sắm.
* **Phân tích rủi ro:**
  * Người chơi sẽ nhanh chóng bỏ qua điểm số vì nó không mang lại giá trị nào trong game. Mất đi một công cụ quan trọng để kích thích người chơi hoàn thiện (perfectionist drive).
* **Phương án đề xuất:**
  * Chuyển đổi hoặc bổ sung hệ thống **Đánh giá 3 Sao**:
    * ⭐⭐⭐: Giải đúng 100% không mắc lỗi, không dùng gợi ý.
    * ⭐⭐: Mắc 1–2 lỗi hoặc có dùng 1 gợi ý.
    * ⭐: Hoàn thành màn chơi.
  * Sao tích lũy được dùng làm đơn vị mở khóa nội dung mới trong Vườn Mèo (mở thêm loài mèo, phụ kiện vườn).

---

### REV-GD-03: Thiếu Meta-Game và Động lực giữ chân (Day 1 / Day 7 Retention)
* **Hiện trạng GDD:** [D-01](file:///D:/Work/Alpaca_Solution/Game-test/GDD/README.md#L25) chỉ có đúng 24 level tuyến tính, không có màn chọn lại level cũ, hoàn thành xong là hết game.
* **Phân tích rủi ro:**
  * Thời gian hoàn thành 24 level chỉ mất khoảng 30–60 phút. Sau đó tỷ lệ gỡ cài đặt (churn rate) là 100%.
  * Tên game là "Vườn Mèo" nhưng người chơi chỉ thấy bàn cờ lưới hình học, không có yếu tố "Vườn" để chăm sóc hay ngắm nhìn.
* **Phương án đề xuất:**
  * **Sổ tay giống mèo / Album sưu tập (Cat Compendium):** Mỗi level vượt qua sẽ giải cứu/thu hút một chú mèo về vườn. Màn hình Home là một khu vườn nhỏ ấm cúng với các chú mèo đã sưu tập được đang nằm ngủ/chơi đùa.
  * **Câu đố hàng ngày (Daily Puzzle):** Mỗi ngày một bài toán mới với lịch điểm danh (Calendar streak) để kéo người chơi mở game đều đặn mỗi ngày.
  * **Cho phép chơi lại các level đã hoàn thành** để săn đủ 3 sao.

---

### REV-TECH-01: Rủi ro hiệu năng của Godot 4 `SubViewport` 3D trên Mobile
* **Hiện trạng GDD:** [D-06](file:///D:/Work/Alpaca_Solution/Game-test/GDD/README.md#L30) và [GDD 05 §1](file:///D:/Work/Alpaca_Solution/Game-test/GDD/05-kien-truc-va-du-lieu.md#L10) định hướng dùng Godot 4, dựng UI 2D và lồng một cảnh 3D bằng `SubViewport` / `ViewportTexture`.
* **Phân tích rủi ro:**
  * **Băng thông bộ nhớ (Memory Bandwidth):** Render target kép (FBO pass sang CanvasTexture pass) khiến GPU mobile đời thấp (Mali G52/G57, Adreno cũ) bị tụt xung, tụt FPS và gây nóng máy, hao pin.
  * **Khựng hình (Shader Stuttering):** Lúc màn Thắng bật SubViewport lên, việc biên dịch shader 3D lần đầu gây giật khung hình (>100ms), vi phạm [TECH-19](file:///D:/Work/Alpaca_Solution/Game-test/GDD/05-kien-truc-va-du-lieu.md#L114).
  * **Lỗi hiển thị Alpha:** ViewportTexture trong suốt trong Godot thường bị viền đen (dark fringing) do vấn đề premultiplied alpha khi vẽ đè lên 2D Control Node.
* **Phương án đề xuất:**
  * **Chiến lược ưu tiên số 1:** Thiết kế 3D trong Blender nhưng **xuất ra Sprite-Sheet 2D chất lượng cao** (Render 60fps frame sequence kèm shadow). Vừa giữ được độ đáng yêu 3D, vừa siêu nhẹ (~30MB), đảm bảo 60 FPS mượt mà trên 100% điện thoại giá rẻ.
  * **Chiến lược nếu giữ 3D:** Biến màn Thắng/Vườn thành một **Scene 3D độc lập**, chuyển cảnh hoàn toàn từ Scene Puzzle 2D sang Scene Win 3D thay vì lồng SubViewport vào giữa cây giao diện 2D.

---

### REV-TECH-02: Bổ sung xử lý vật lý cảm ứng (Touch Slop & Multi-touch)
* **Hiện trạng GDD:** [UX-11](file:///D:/Work/Alpaca_Solution/Game-test/GDD/03-luong-man-hinh-va-ux.md#L52) và [TECH-03](file:///D:/Work/Alpaca_Solution/Game-test/GDD/05-kien-truc-va-du-lieu.md#L20) chỉ mô tả logic trừu tượng, chưa có thông số vật lý cảm ứng.
* **Phân tích rủi ro:**
  * Khi chạm ngón tay, luôn có độ xê dịch vi mô (micro-movement). Không có ngưỡng dung sai (`touch_slop`) sẽ khiến engine nhận diện nhầm Tap thành Drag.
  * Người dùng tì lòng bàn tay vào mép màn hình (Palm contact) dễ gây kích hoạt nhầm tọa độ chạm.
* **Phương án đề xuất:**
  * Bổ sung quy chuẩn kỹ thuật cho Gesture Layer:
    * `TOUCH_SLOP_RADIUS = 12.0` (pixels logic). Mọi di chuyển trong bán kính này vẫn tính là đứng yên tại ô.
    * Khóa đa điểm trên bàn cờ: Chỉ tiếp nhận sự kiện từ `event.index == 0` (ngón tay chạm đầu tiên). Bỏ qua các ngón tay phụ.

---

### REV-TECH-03: Kích thước vùng chạm khi mở rộng N=12 trên Mobile Dọc
* **Hiện trạng GDD:** [LV-01](file:///D:/Work/Alpaca_Solution/Game-test/GDD/04-thiet-ke-level.md#L7) hỗ trợ schema N=4..12; [UX-18](file:///D:/Work/Alpaca_Solution/Game-test/GDD/03-luong-man-hinh-va-ux.md#L80) đặt điều kiện chạm 44×44pt cho N≤6.
* **Phân tích rủi ro:**
  * Màn hình điện thoại có bề ngang hữu dụng ~360pt. Với bàn cờ 12×12, mỗi ô chỉ rộng khoảng **~26pt**, thấp hơn nhiều so với tiêu chuẩn công thái học tối thiểu 44pt (Apple HIG) và 48dp (Google Material Design).
  * Nếu dùng cơ chế Thu phóng & Trượt (Zoom & Pan): Cử chỉ **Double-Tap (Đang dùng để đặt mèo)** sẽ xung đột trực tiếp với cử chỉ Double-Tap-to-Zoom kinh điển trên mobile.
* **Phương án đề xuất:**
  * Khống chế kích thước tối đa trên Mobile Portrait là **N=8 hoặc N=9**.
  * Quy định rõ: N=10..12 chỉ dành cho phiên bản Tablet / iPad hoặc chế độ màn hình ngang (Landscape).

---

### REV-TECH-04: Chiều sâu câu đố và sự phụ thuộc vào S1/S2
* **Hiện trạng GDD:** [GDD 04 §2](file:///D:/Work/Alpaca_Solution/Game-test/GDD/04-thiet-ke-level.md#L16-L25) chỉ công nhận S1 (loại trừ) và S2 (ứng viên duy nhất). Các kỹ thuật nâng cao S3–S5 bị hoãn lại sau bản đầu.
* **Phân tích rủi ro:**
  * Ở bàn 5×5 và 6×6, các bài toán chỉ giải được bằng S1/S2 thường quá đơn giản (luôn có vùng 1 ô hoặc hàng trống lộ liễu), thiếu đi cảm giác thử thách trí tuệ. Để giữ nghiệm duy nhất bằng S1/S2, người tạo màn buộc phải cấp nhiều mèo cho sẵn (`givens`), làm giảm tính hấp dẫn.
  * Kỹ thuật giao thoa (Intersection / Subsets - S3) là "linh hồn" của dòng game Queens/Star Battle.
* **Phương án đề xuất:**
  * Đưa **S3 (Nhóm khóa giao thoa / Intersection Elimination)** vào phạm vi nghiên cứu sớm hơn (ngay trong giai đoạn M1/M2) để nâng cao chất lượng biên tập 24 level phát hành.

---

## 4. Hướng dẫn hành động cho các Agent tiếp theo

1. **Khi thực hiện Gói A (Spike M0):**
   * Đọc kỹ mục `REV-TECH-01` để đo lường hiệu năng 3D SubViewport so với phương án Sprite-Sheet 2D trước khi quyết định kiến trúc đồ họa cố định.
   * Tham chiếu `REV-UX-01` và `REV-TECH-02` khi xây dựng Gesture Layer nguyên mẫu.
2. **Khi thực hiện Gói B (Core & Rules):**
   * Kiểm tra tính khả thi của việc cho phép Undo và giảm hình phạt với `x_error` theo `REV-GD-01`.
3. **Khi thực hiện Gói C & H (Validator & Level Design):**
   * Tham chiếu `REV-TECH-04` để cân nhắc độ sâu suy luận cho các level từ 13 đến 24.
4. **Khi cập nhật quy chuẩn GDD:**
   * Mọi thay đổi về luật và dữ liệu bắt buộc phải tuân thủ quy trình tại [AGENTS.md](file:///D:/Work/Alpaca_Solution/Game-test/AGENTS.md) (sửa đồng bộ GDD, sample data, validator và unit test).
