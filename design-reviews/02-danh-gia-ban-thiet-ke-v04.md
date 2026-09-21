# 02 — Rà soát & Đánh giá Chuyên sâu Bản thiết kế GDD v0.4

**Ngày lập:** 2026-09-18  
**Tác giả đánh giá:** Senior Game Programmer & Lead Game Designer  
**Đối tượng sử dụng:** Các Coding Agent, Game Designer, Developer tiếp nhận dự án  
**Tài liệu đối chiếu:** GDD v0.4 (đặc biệt là `GDD/10`, `GDD/11`, `interactions.sample.json`, `test_interaction_contract.py`)

**Quyết định sau góp ý 2026-09-18:** [GDD v0.4.2](../GDD/README.md) và [bảng quyết định](../GDD/09-ra-soat-thiet-ke.md) là nguồn triển khai. Phân tích và phương án trong bản review dưới đây được giữ để lưu lịch sử; các điểm mua hint, Garden Lobby, mèo tự về vườn và tô mèo theo màu vùng đã được thay bằng quyết định mới.

---

## 1. Mục đích và bối cảnh

Bản cập nhật GDD v0.4 đã có những bước tiến rất lớn so với v0.3, trực tiếp phản hồi các góp ý tại [01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md](01-danh-gia-va-kien-nghi-thiet-ke-kien-truc.md). 

Tài liệu này đóng vai trò là **Bản đánh giá lần 2 (Second-Pass Review)** nhằm:
1. Ghi nhận các giải pháp xuất sắc đã được đưa vào v0.4.
2. Cảnh báo **4 vấn đề tiềm ẩn mới phát sinh** về mặt kinh tế game (Game Economy), hiệu năng bộ nhớ texture (VRAM), tâm lý người chơi khi thua cuộc và bản sắc meta-game của trò chơi.
3. Cung cấp giải pháp kỹ thuật cụ thể để các Agent triển khai Gói A, B, G, H áp dụng ngay mà không làm xáo trộn kiến trúc cốt lõi.

---

## 2. Bảng tổng hợp vấn đề mới (New Issue Matrix)

| Mã ID | Phân loại | Mức độ | Tài liệu liên quan | Vấn đề cốt lõi | Trạng thái đề xuất |
| :--- | :--- | :---: | :--- | :--- | :---: |
| **REV-ECO-01** | Game Economy | **Nghiêm trọng** | `GDD 11 §2`, `QA-46/47` | Nghịch lý kinh tế "Bẫy nghèo đói": Người chơi yếu cần hint lại kiếm được ít vàng nhất, dẫn đến kẹt màn và gỡ game. | Đã điều chỉnh trong GDD v0.4.2: hint miễn phí, vàng cứu lượt/mua mèo |
| **REV-TECH-05**| GPU Memory / VRAM | **Cao** | `D-06`, `TECH-18/19`, `ART-02` | Xuất riêng Sprite Sheet cho từng màu mèo gây phình to VRAM (hàng trăm MB), dẫn đến Out-Of-Memory trên mobile yếu. | Đã điều chỉnh: mèo không tô theo vùng; mỗi mèo một bộ clip, kiểm cache/VRAM |
| **REV-GD-04**  | Player Frustration | **Cao** | `D-08`, `GR-16/17/19`, `QA-14` | Hết 3 tim phạt thua và reset trắng bàn cờ gây ức chế tột độ ở các bàn 6×6 khi chỉ vì một cú chạm nhầm vô ý. | Đặc tả mở rộng sau MVP: vàng hoặc quảng cáo thưởng khi thiếu vàng; Retry miễn phí |
| **REV-META-01**| Retention / Theme | **Trung bình** | `GDD 01 §1`, `UX-01`, `GDD 11` | Game thiếu hoàn toàn yếu tố "Vườn Mèo" thực sự; màn Home đơn điệu, thiếu tương tác cảm xúc để giữ chân người chơi. | Đã chốt: Vườn mèo là danh sách mèo mua bằng vàng để chọn |

---

## 3. Ghi nhận các điểm tiến bộ vượt bậc ở bản v0.4

Trước khi phân tích các điểm cần hoàn thiện, đội ngũ kỹ thuật và thiết kế đánh giá rất cao 4 thay đổi lớn trong v0.4:
1. **Cử chỉ Optimistic Preview & Drag Stroke ([GR-29/30](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L34-L35)):** Cho phép 1 chạm hiện X ngay trên hình và kéo để đánh/xóa X hàng loạt là giải pháp chuẩn mực, giải quyết triệt để cảm giác trễ 280ms mà vẫn giữ được logic chạm đôi an toàn.
2. **Quyết định Engine 2D Sprite Sheet từ Model 3D ([D-06](file:///D:/Work/Alpaca_Solution/Game-test/GDD/README.md#L33)):** Tránh được cạm bẫy hiệu năng của `SubViewport` 3D runtime trong Godot 4, đảm bảo độ mượt 60 FPS trên 100% thiết bị Android/iOS mục tiêu.
3. **Cơ sở toán học bài bản cho S3–S5 ([GDD 10](file:///D:/Work/Alpaca_Solution/Game-test/GDD/10-nghien-cuu-quy-tac-suy-luan.md)):** Thiết lập hệ thống tiên đề và điều kiện tập hợp chuẩn xác cho quy tắc Khóa giao thoa (S3), đồng thời hoãn S5 (phản chứng) để tránh hint bị biến thành bài giảng toán dài dòng.
4. **Bộ test vector cử chỉ có thể thực thi ([interactions.sample.json](file:///D:/Work/Alpaca_Solution/Game-test/GDD/data/interactions.sample.json)):** Chuẩn hóa 16 ca kiểm thử cảm ứng (touch slop, jitter, multi-touch rejection) ngay từ đầu giúp việc lập trình Gesture Controller sau này có hợp đồng kỹ thuật rõ ràng.

---

## 4. Chi tiết 4 vấn đề tiềm ẩn mới & Giải pháp đề xuất

### REV-ECO-01: Nghịch lý kinh tế "Bẫy nghèo đói" (The Poverty Trap) trong GDD 11
* **Hiện trạng GDD 11:** 
  * Điểm cuối lượt đổi thành vàng theo công thức `gold = floor(score / 50)` chỉ cấp 1 lần khi thắng.
  * Dùng vàng để mua lượt Hint nâng cao (8 vàng) hoặc Trợ giúp nâng cao (12 vàng).
* **Phân tích rủi ro thiết kế:**
  * **Nghịch lý phân phối:**
    * *Người chơi giỏi:* Giải nhanh, 0 lỗi, đạt điểm tối đa -> tích lũy lượng vàng khổng lồ nhưng **không bao giờ cần mua Hint**.
    * *Người chơi mới / kỹ năng thấp (nhóm đối tượng casual chính):* Thử sai nhiều, bị trừ điểm, kiếm được rất ít vàng hoặc 0 vàng -> Khi đến các level khó (15–20), họ kẹt và **không đủ tiền mua Hint**.
  * **Hậu quả:** Người cần sự trợ giúp nhất lại là người nghèo nhất. Họ không thể tự giải, không có vàng mua hint, không thể vượt qua level -> **Gỡ cài đặt (Churn rate 100%)**.
* **Giải pháp đề xuất:**
  1. **Tách biệt Trợ giúp khỏi Vàng:** Không bán Hint bằng vàng kiếm từ điểm số. Hint nên là **tài nguyên tự hồi phục theo thời gian** (ví dụ: mỗi 5–10 phút hồi 1 lượt, tích lũy tối đa 2–3 lượt) hoặc tặng miễn phí khi người chơi gặp chuỗi thất bại liên tiếp (Pity System).
  2. **Tái định vị Vàng cho Metagame:** Vàng chỉ nên dùng cho các giá trị mong muốn (Aspirational Value) như: Mở khóa các giống mèo mới, trang trí sân vườn, mua phụ kiện vòng cổ cho mèo, hoặc dùng cho cơ chế Cứu nguy (`REV-GD-04`).

---

### REV-TECH-05: Nguy cơ tràn VRAM do bùng nổ Sprite Sheet đa màu
* **Hiện trạng GDD 06 & D-06:** Hoạt ảnh mèo (idle, jump, celebrate, sad) được render từ model 3D thành Sprite Sheet 2D cho 6 màu vùng (A–F) và mở rộng 12 màu (A–L).
* **Phân tích rủi ro kỹ thuật:**
  * Một chuỗi animation mèo sắc nét (kích thước frame 256×256 px, 30–60 FPS, dài 2–3 giây) có thể cần atlas sprite sheet kích thước 2048×2048 px hoặc 4096×4096 px (~16MB đến 64MB uncompressed VRAM).
  * Nếu xuất riêng sprite sheet cho 6 màu -> ngốn **~100MB – 200MB VRAM**. Nếu mở rộng 12 màu -> ngốn **~250MB – 400MB VRAM** chỉ riêng cho texture của mèo.
  * Trên các thiết bị Android tầm thấp (RAM 2GB–3GB), bộ nhớ GPU dùng chung với RAM hệ thống, dung lượng VRAM lớn này sẽ kích hoạt cơ chế Low-Memory Killer làm sập ứng dụng (Crash OOM).
* **Giải pháp đề xuất (Kỹ thuật Palette Swapping / Shader Tinting):**
  1. Đội ngũ Art chỉ xuất **DUY NHẤT 1 BỘ SPRITE SHEET MÀU TRẮNG/XÁM (Grayscale Base Texture)** kèm texture mặt nạ (Mask Map nếu cần bảo vệ mắt mèo hoặc phụ kiện không bị đổi màu).
  2. Trong Godot 4, viết một **CanvasItem Shader cực nhẹ**:
     ```gdshader
     shader_type canvas_item;
     uniform vec4 region_color : source_color;
     void fragment() {
         vec4 tex = texture(TEXTURE, UV);
         // Tô màu lông mèo theo mã màu vùng nhưng vẫn giữ nguyên độ sáng tối (shading)
         COLOR = vec4(tex.rgb * region_color.rgb, tex.a);
     }
     ```
  3. **Lợi ích:** Tiết kiệm **85% dung lượng file và bộ nhớ VRAM** (chỉ tốn ~15MB cho tất cả các màu mèo), giảm 90% công sức cho họa sĩ 3D.

---

### REV-GD-04: Sự tàn nhẫn của "3 Tim + Khóa X Đỏ + Không Undo"
* **Hiện trạng GDD 02:** Thử sai mất 1 tim, ô biến thành `x_error` bị khóa vĩnh viễn, hết 3 tim là thua cuộc và bắt buộc phải Retry lại toàn bộ màn chơi từ đầu ([GR-16/17/19](file:///D:/Work/Alpaca_Solution/Game-test/GDD/02-luat-choi-va-trang-thai.md#L42-L49)).
* **Phân tích rủi ro trải nghiệm:**
  * Ở các level 5×5 hoặc 6×6, người chơi đã đầu tư 4–5 phút suy luận căng thẳng và tìm được 5/6 chú mèo. Chỉ vì ngón tay run hoặc vô ý chạm đúp nhầm vào 1 ô trống -> mất tim thứ 3 -> **toàn bộ 5 phút công sức bị xóa sạch, bàn cờ reset về đầu**.
  * Cảm giác mất mát đột ngột này biến một tựa game "Thư giãn, chữa lành" thành trải nghiệm gây ức chế cực độ (Rage Quit).
* **Giải pháp đề xuất (Cơ chế Cứu nguy - Second Chance / Revive):**
  1. Khi tim về 0, hiển thị màn hình cảnh báo với lựa chọn:
     * **Thử lại từ đầu (Miễn phí).**
     * **Cứu lượt chơi (Dùng 5–10 Vàng):** Hồi phục lại 1 tim, mở khóa ô `x_error` vừa bấm nhầm thành ô `empty` và cho phép người chơi tiếp tục giải bàn cờ hiện tại.
  2. Cơ chế này bảo vệ tâm lý người chơi, đồng thời giải quyết bài toán tiêu thụ vàng (Sink) rất hiệu quả cho nền kinh tế game.

---

### REV-META-01: Thiếu vắng bản sắc "Vườn Mèo" (The Missing Garden Lobby)
* **Hiện trạng GDD 01 & 03:** Giao diện Home chỉ gồm các nút: `Chơi/Tiếp tục`, `Trợ giúp`, `Settings` ([UX-01](file:///D:/Work/Alpaca_Solution/Game-test/GDD/03-luong-man-hinh-va-ux.md#L30)). Bàn chơi là ma trận lưới hình học.
* **Phân tích rủi ro sản phẩm:**
  * Tên trò chơi là **Vườn Mèo**, nhưng người chơi không thấy "Vườn" ở đâu. Toàn bộ trải nghiệm bị bó hẹp trong một bàn cờ Sudoku khô khan.
  * Thiếu sợi dây liên kết cảm xúc giữa người chơi và các nhân vật mèo – yếu tố cốt lõi tạo nên sự lan tỏa (viral) của dòng game cozy trên TikTok/Shorts.
* **Giải pháp đề xuất (The Garden Lobby):**
  1. **Biến màn Home thành một Khu Vườn Nhỏ:** 
     * Thay vì nền menu tĩnh, Home là một bãi cỏ xanh ấm áp.
     * Mỗi khi vượt qua một level, chú mèo tương ứng với level đó sẽ chạy ra khu vườn ở màn hình Home, nằm sưởi nắng, ngủ hoặc đi dạo.
  2. **Tương tác đơn giản (Petting):** 
     * Người chơi có thể chạm vào chú mèo trong vườn để nghe tiếng kêu "Meow", mèo nhảy lên hoặc cuộn tròn hạnh phúc.
  3. Chi phí triển khai phần này rất thấp (tái sử dụng sprite sheet mèo đã có) nhưng giá trị gia tăng về mặt cảm xúc và tỷ lệ giữ chân (Retention) là khổng lồ.

---

## 5. Quyết định triển khai sau góp ý

1. **Gói A/G — Art & Audio:** Bản đầu dùng một bộ clip mèo mặc định cho mọi ô `cat` và mọi vùng. Vùng nhận diện bằng nền/viền/nhãn/họa tiết; không cần shader tô mèo theo vùng. Mèo mua về sau có gói clip riêng, tải theo lựa chọn của người chơi (TECH-18/20/21, ART-12/13, QA-50/52).
2. **Gói B/D — Core & Save:** Bản đầu giữ GR-17/19. Gói meta sau MVP thêm trạng thái chờ cứu lượt khi tim về 0, giao dịch vàng hoặc xác nhận quảng cáo thưởng, hồi 1 tim và xóa riêng X đỏ cuối; Retry miễn phí luôn dùng được (GDD 11, QA-47/53).
3. **Gói F/K — UI & Meta:** Vườn mèo chỉ liệt kê `purchasedAppearanceIds` mua bằng vàng; mèo mặc định có nút chọn riêng. `selectedAppearanceId` là mèo mặc định hoặc một ID đã mua. Không lấy `completedLevelIds` để cấp mèo, không dựng Garden Lobby hoặc petting. Hình trên mọi ô `cat`/given và hoạt ảnh theo mèo đang chọn; hint cơ bản miễn phí (GDD 11, QA-52).
