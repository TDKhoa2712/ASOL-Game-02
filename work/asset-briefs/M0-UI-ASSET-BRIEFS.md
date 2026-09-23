# MVP UI và asset briefs — M0-UI-ASSET-BRIEFS

## 1. Mục đích và giới hạn

Tài liệu này là danh sách sản xuất để chủ dự án tạo asset gốc bằng công cụ mình chọn. Agent bàn giao cấu tạo, prompt và hợp đồng file; asset nào được gửi trước có thể được tích hợp trong một package UI sau này. `M0-A02` và `M0-A03` tiếp tục dùng hình tạm và chạy độc lập với danh sách này. Brief không chứng nhận asset, UI hoặc hiệu năng đã hoàn thành.

Nguồn chuẩn là [GDD/01](../../GDD/01-tam-nhin-va-pham-vi.md), [GDD/03](../../GDD/03-luong-man-hinh-va-ux.md), [GDD/06](../../GDD/06-my-thuat-va-am-thanh.md) và [GDD/08](../../GDD/08-ke-hoach-trien-khai-cho-agent.md). Bản đầu có 24 level tuyến tính, bàn phát hành N=4–6, một mèo mặc định và sáu vùng A–F. Tên “Vườn Mèo” là tên tạm; logo và chữ trang trí mang tên phát hành chờ quyết định O-01. Danh mục dưới đây không gồm bản đồ/chương/chọn level, tiền vàng, quảng cáo, bộ sưu tập mèo hoặc generator hậu MVP.

### Phân vai và hợp đồng chung

| Bên | Việc làm |
| --- | --- |
| Agent ở package brief này | Xác định đối tượng, lớp cấu tạo, prompt, tên file, tiêu chí tiếp nhận. |
| Chủ dự án | Tạo tác phẩm gốc, giữ file nguồn có thể sửa, xuất file đúng ID, cung cấp thông tin nguồn gốc/quyền. |
| Agent ở package tích hợp sau | Kiểm file nhận, nối asset vào Godot, dựng layout/tương tác, thử trên màn hình thật theo package được giao. |

Mọi chữ giao diện, số level, tim, điểm, nhãn vùng A–F và trạng thái nút do Godot hiển thị bằng khóa localization. Không đưa chữ vào PNG/sprite. Board, viền ô, X thường, màu nền vùng, họa tiết lặp và focus Hint nên được vẽ từ code/vector để giữ độ nét khi N và tỉ lệ màn hình đổi. Các hình trang trí không được chứa thông tin luật duy nhất.

Các kích thước xuất bên dưới là **nguồn dự kiến** để sản xuất và kiểm thử; kích thước frame, atlas, nén và ngân sách runtime cuối do `M0-A03` đo trên Android/iPhone mục tiêu. Thiết kế trên canvas tham chiếu dọc 1080×1920; bố cục phải tự thích nghi với safe area và chữ dài hơn 30%. N≤6 cần vùng chạm thực tế tối thiểu 44×44 điểm logic. Không phóng/trượt bàn để bù cho art quá dày.

## 2. Danh mục màn hình và ranh giới hình ảnh

| Màn/luồng | UI và dữ liệu do Godot dựng | Asset có thể nhập |
| --- | --- | --- |
| Home `UX-01` | Tên/số level hiện tại, Chơi/Tiếp tục, Trợ giúp, Settings, hết nội dung | `BG-01`, `NAV-01`, mèo `CAT-01` nếu hiển thị |
| Puzzle `UX-03` | Header, 3 tim, bốn luật luôn nhìn thấy, board, nhãn/họa tiết A–F, tiến độ N vị trí, Undo, Restart, Hint, Help, Settings | `CAT-01`, `RULE-01`, `NAV-01`, `STATE-01`, `FX-01` |
| Tutorial Level 1 `UX-04` | T1–T6, ô focus, nội dung chữ/hành động, tiến độ theo hành động | `TUT-01` dùng khi minh họa cử chỉ; không phủ vùng chạm đang tập |
| Kết quả thắng `UX-05` | Điểm lượt, câu khích lệ, Level tiếp theo, Home | `CAT-01` clip celebrate, `RESULT-01`, `BG-01` |
| Kết quả thua `UX-06` | 3 tim hết, điểm lượt, Retry, Home; scene riêng | `CAT-01` clip sad, `STATE-01`, `BG-01` |
| Trợ giúp/Luật `UX-07` | Ví dụ hàng/cột/vùng/chạm chéo và thao tác được dựng từ board mẫu, chữ và nút trở lại | `RULE-01`, `TUT-01`, `NAV-01` |
| Settings `UX-08` | Điều khiển âm, rung, giảm chuyển động, hỗ trợ phân biệt vùng; trở lại đúng nơi gọi | `NAV-01`; trạng thái switch do Godot vẽ |

Không hiển thị điểm khi đang chơi. Result thắng và thua dùng nội dung, bố cục và biểu cảm riêng; không thay mỗi dòng chữ trên cùng một ảnh thắng. Sticker/particle ở ngoài vùng chạm board hoặc chỉ xuất hiện ngắn; nút Result dùng được ngay.

## 3. Thứ tự giao asset theo lô

| Lô | Gửi trước | Vì sao dùng được ngay |
| --- | --- | --- |
| A — bàn M0 | `CAT-01` concept/model/clip mẫu, `RULE-01`, `STATE-01` | Thay hình tạm trên puzzle, thử mèo cùng ngoại hình ở nhiều vùng, đo sprite với `M0-A03`. |
| B — thao tác | `NAV-01`, `TUT-01`, `FX-01` | Dựng Tutorial, Help và các nút của puzzle mà không đợi Home/Result. |
| C — khung MVP | `BG-01`, `RESULT-01` | Dựng Home và hai Result sau khi luồng điều hướng/save sẵn sàng. |
| D — âm | `SFX-01` | Gắn vào event đã có; âm và rung vẫn tắt độc lập. |

Lô là thứ tự đề xuất, không phải dependency bắt buộc. Mỗi ID có thể được gửi riêng. Một package tích hợp sau này chỉ nhận các ID đã có file và được kiểm tra; phần còn lại tiếp tục dùng hình tạm. Khi package M0 khác đã bàn giao, việc thay hình và điều chỉnh UI nằm ở package tích hợp mới với `allowed_paths` riêng.

## 4. Quy cách bàn giao chung

Mỗi ID bàn giao một thư mục `assets/<ID>/` trong đợt tích hợp tương lai, gồm file nguồn sửa được, bản xuất và `source.md` ghi: người/công cụ tạo, ngày, phiên bản, quyền sử dụng, mô tả chỉnh sửa và danh sách file. Tên file dùng chữ thường, số và dấu gạch dưới; ví dụ `cat_default_jump_0001.png`. Nếu dùng công cụ tạo sinh, lưu prompt và nguồn tham chiếu do chính mình tạo trong `source.md`. Không dùng hình, âm thanh, model, nhân vật, level hoặc UI của game thương mại làm input hay output.

Ảnh cần alpha thật khi yêu cầu nền trong suốt, không dùng nền caro vẽ vào ảnh. Các lớp tái sử dụng xuất riêng, không gộp mèo với màu vùng, chữ, nút hoặc nền. Bản nguồn giữ độ phân giải cao hơn bản game; kích thước runtime sẽ chốt sau `M0-A03`. Mỗi sprite frame phải cùng canvas, hướng camera, chân đế/pivot và khoảng trống để animation không giật. Với icon, cung cấp bản nguồn vector sửa được nếu công cụ hỗ trợ, cùng PNG trong suốt 256×256 để kiểm thử; hình phải đọc được khi thu về khoảng 44 điểm logic. Với nền dọc, cung cấp nguồn ít nhất 1080×1920 và vùng trung tâm ít chi tiết để chữ/nút nổi rõ; art phải mở rộng/crop được ở màn hình khác tỉ lệ.

Tiêu chí tiếp nhận chung: ID/tên file khớp manifest; file mở được; alpha/canvas/pivot đúng; không có chữ bị bake; nét rõ ở kích thước sử dụng; không che board/hướng dẫn; bản quyền/nguồn gốc có thể truy vết. Agent tích hợp sẽ ghi nhận `planned → received → accepted → integrated` cho từng ID trong evidence của package tích hợp, không sửa lại brief đã bàn giao.

## 5. Phiếu tạo theo đối tượng

### CAT-01 — Mèo mặc định gốc và sprite runtime

- **Dùng ở:** ô `cat`/given trên mọi vùng, phản hồi mèo đúng, Home nếu phù hợp, Result thắng/thua.
- **Cấu tạo:** concept chính diện và góc 3/4; model 3D gốc có đầu, tai, thân, chân, đuôi, mắt và biểu cảm; rig; bốn clip `idle`, `jump`, `celebrate`, `sad`; icon/silhouette tĩnh; sprite frame PNG nền trong suốt render từ cùng model. Không tạo phiên bản theo A–F.
- **Trạng thái:** `idle` đọc rõ trong ô N=6; `jump` ngắn cho đặt mèo đúng; `celebrate` vui cho Result thắng; `sad` nhẹ cho Result thua. Có frame tĩnh đại diện cho chế độ giảm chuyển động.
- **Nguồn/xuất:** file model/rig/animation có thể sửa (ưu tiên `.blend` hoặc tương đương), bản trao đổi `.glb` nếu dùng được, PNG sequence RGBA từng clip và icon trong suốt. Frame đầu/cùng clip cùng canvas/pivot; số frame và atlas cuối chờ đo `M0-A03`.
- **Prompt concept:** “Design an original friendly cat character for a bright garden logic puzzle on a portrait phone screen. Make a compact, unmistakable silhouette with readable ears, face and tail at small size. Show front, side and three-quarter turnaround plus neutral, joyful and gently disappointed expressions. Soft shapes, clean edges, warm playful personality. Neutral fur independent of puzzle region colors. Plain background, no words, no logo, no accessories that resemble an existing game character. Keep proportions consistent across views.”
- **Prompt model/rig:** “Create an original editable 3D model from the supplied approved character turnaround. Separate animatable head, ears, tail and limbs as needed; build a clean rig with consistent scale and a stable ground pivot. Produce idle, short jump, celebrate and gentle sad clips. Render orthographic transparent 2D frames from one fixed camera with consistent lighting and alpha. Do not recolor the cat for puzzle regions or bake UI text/background into frames.”
- **Duyệt:** icon không lẫn với X và dấu cảnh báo; silhouette còn nhận được trên ô nhỏ N=6; các clip không đổi ngoại hình; sticker và chuyển động không che thao tác. Một ảnh tham khảo do công cụ ảnh tạo ra chưa thay thế model/rig/clip và file nguồn theo GDD/06.

### RULE-01 — Bốn biểu tượng luật

- **Dùng ở:** dải bốn luật luôn thấy trong Puzzle, Help, Tutorial. Chữ nhãn do Godot render cạnh icon.
- **Cấu tạo:** bốn icon riêng `row`, `column`, `region`, `diagonal`. Dùng sơ đồ ô và dấu mèo trừu tượng cùng một nét; icon vùng phải có ranh giới/họa tiết; icon chạm chéo thể hiện hai ô kề góc. Không biến icon thành lời giải level.
- **Trạng thái:** chuẩn và nhấn/focus do Godot tô viền; icon nguồn một màu đủ tương phản.
- **Nguồn/xuất:** bốn SVG hoặc nguồn vector sửa được, bốn PNG RGBA 256×256; thống nhất lề và trọng lượng nét.
- **Prompt:** “Create four original, cohesive pictogram icons for a mobile garden logic puzzle: one cat per row, one per column, one per outlined patterned region, and cats cannot touch diagonally. Use tiny square-grid diagrams with a simple abstract cat marker; bold clean contours, generous negative space, legible at 44 logical points. Deliver each icon separately on transparent background, monochrome shapes suitable for code-applied color. No letters, words, numbers, existing game iconography or decorative detail that hides the rule.”
- **Duyệt:** bốn luật phân biệt ở thang xám; chữ nhãn luôn đi kèm trên puzzle, không dựa vào icon đơn lẻ.

### STATE-01 — Tim và cảnh báo ô sai

- **Dùng ở:** ba tim trên Puzzle, màn thua, `x_error`; X thường do Godot vẽ để preview tức thì.
- **Cấu tạo:** tim đầy/rụng hoặc rỗng cùng silhouette; dấu cảnh báo có hình rõ ngoài màu đỏ; dấu khóa nhỏ cho `x_error`. Cảnh báo và khóa xuất riêng để Godot ghép với X đỏ/viền vùng.
- **Trạng thái:** tim còn/mất; cảnh báo bình thường và phiên bản không chuyển động. Không làm hiệu ứng chớp.
- **Nguồn/xuất:** nguồn vector riêng cho `heart_full`, `heart_empty`, `warning`, `lock`; PNG RGBA 256×256.
- **Prompt:** “Create a cohesive original set of four clean mobile game status icons: full heart, empty heart, caution mark and small lock. The caution mark and lock must remain understandable without red color; use shape and contour, not hue alone. Friendly garden game tone, strong small-size silhouette, consistent line weight and visual center. Four separate transparent images, no text, no glow or flashing effects.”
- **Duyệt:** thử thang xám vẫn phân biệt tim và lỗi; X đỏ có thêm dấu cảnh báo/viền, không được xem như màu vùng.

### NAV-01 — Bộ icon điều hướng và hành động

- **Dùng ở:** Home, Puzzle, Help, Settings và Result.
- **Cấu tạo:** `home`, `back`, `help`, `settings`, `undo`, `restart`, `hint`, `sound`, `vibration`, `reduced_motion`, `region_assist`. Nền nút, trạng thái disabled/pressed/selected và vùng chạm do Godot dựng; ảnh chỉ chứa ký hiệu.
- **Nguồn/xuất:** nguồn vector từng icon và PNG RGBA 256×256 cùng viewbox/lề. Dùng một trọng lượng nét và lưới căn chỉnh.
- **Prompt:** “Create an original cohesive 11-icon set for a bright garden mobile puzzle: home, back, help, settings, undo, restart, hint, sound, vibration, reduced motion and region-assist pattern. Simple rounded geometry with confident contours and ample negative space, readable at 44 logical points. Export each symbol separately centered on transparent background as editable vector and PNG. Monochrome forms for UI tinting; no text, button background, cat character, commercial icon copies or branded shapes.”
- **Duyệt:** các icon mang nghĩa rõ khi đi cùng nhãn/trình đọc màn hình; disabled không chỉ thể hiện bằng nhạt màu.

### TUT-01 — Minh họa cử chỉ

- **Dùng ở:** Tutorial Level 1 và Help; board ví dụ, focus ô và hướng dẫn chữ vẫn do Godot dựng.
- **Cấu tạo:** bàn tay/ngón chạm tĩnh, đường kéo ngắn, hai nhịp chạm cùng ô; mỗi phần tách lớp để Godot đặt lên vị trí thật. Không vẽ cả một screenshot bàn chơi trong asset.
- **Trạng thái:** single tap, drag, double tap; bản tĩnh đủ truyền ý khi giảm chuyển động.
- **Nguồn/xuất:** nguồn vector từng lớp và PNG RGBA 256×256; điểm chạm/pivot rõ trong `source.md`.
- **Prompt:** “Create three original instructional gesture overlays for a portrait mobile puzzle: one fingertip tap, a short drag path through adjacent square cells, and two sequential taps on exactly the same cell. Draw finger, contact ring and path as separate transparent layers with a consistent rounded visual style. Keep the target cell visible and leave room for live Vietnamese instruction text outside the image. No board screenshot, words, numbers or imitation of a commercial tutorial.”
- **Duyệt:** mốc T1–T6 vẫn theo hành động người chơi; overlay không chiếm input hoặc che ô cần chạm.

### FX-01 — Phản hồi mèo đúng và sticker thắng

- **Dùng ở:** đúng mèo ngắn trên Puzzle; Result thắng. Chữ “Hay lắm!”/“Tuyệt!” do Godot hiển thị.
- **Cấu tạo:** sparkle nhỏ, điểm sáng tĩnh cho vùng tiến độ, sticker chúc mừng không chữ; xuất riêng từng phần. Hoạt ảnh mèo lấy từ `CAT-01`, không vẽ mèo mới trong sticker.
- **Trạng thái:** động ngắn tối đa khoảng 0,7 giây trên Puzzle và bản tĩnh cho giảm chuyển động; Result có thể loop nhẹ nhưng nút luôn dùng ngay.
- **Nguồn/xuất:** lớp PNG RGBA riêng; nguồn sửa được; nếu có sequence, mỗi frame cùng canvas/pivot.
- **Prompt:** “Create original restrained garden-themed celebration accents for a mobile logic puzzle: a few soft sparkles, one progress highlight and a small wordless win sticker frame. Bright and cheerful without covering the game board or navigation. Export each element as a separate transparent layer; provide a calm static variant. No cat, score number, text, logo, confetti wall or intense flash.”
- **Duyệt:** vẫn đọc được board, tim và vùng luật; không khóa thao tác, không gây chói.

### BG-01 — Nền Home và Result

- **Dùng ở:** Home, Result thắng, Result thua. Puzzle ưu tiên nền đơn giản để bàn nổi bật.
- **Cấu tạo:** nền vườn tươi sáng có các lớp xa/gần tách được; vùng giữa ít chi tiết; biến thể thắng ấm hơn và thua dịu hơn có thể tạo bằng ánh sáng/tint trong Godot từ cùng nền gốc.
- **Nguồn/xuất:** nguồn layer sửa được; bản kiểm thử dọc tối thiểu 1080×1920; chừa vùng crop an toàn bốn phía, không bake chữ, nút, mèo hay sticker.
- **Prompt:** “Paint an original bright, welcoming garden background for a portrait mobile logic game. Gentle foliage and simple shapes frame the left and right edges, with a quiet low-detail center for live UI text and buttons. Separate far background and foreground decoration as editable layers so the layout can crop for different phone aspect ratios. Cheerful but subtle, no cat character, puzzle grid, words, logo, UI controls or resemblance to an existing game.”
- **Duyệt:** chữ và nút có đủ tương phản sau khi đặt overlay; không làm giảm độ đọc màn thua hay Home ở safe area.

### RESULT-01 — Khung sticker kết quả thắng

- **Dùng ở:** Result thắng quanh `CAT-01` celebrate; màn thua dùng bố cục và biểu cảm riêng, không tái dùng sticker thắng.
- **Cấu tạo:** khung hoa/lá nhỏ và huy hiệu trống không chữ; các mảnh tách lớp để bố cục thích nghi. Điểm và câu khích lệ do Godot render.
- **Nguồn/xuất:** nguồn vector/layer sửa được; PNG RGBA từng phần, kích thước khung tham chiếu 720×720 trên canvas 1080×1920.
- **Prompt:** “Create an original wordless celebratory garden sticker frame for a mobile puzzle win screen. Use a few soft leaves, petals and warm accent shapes around an open central space reserved for a separately animated cat and live score text. Export foreground pieces and frame as separate transparent layers. Keep the result buttons unobstructed. No numbers, letters, cat illustration, logo or copied game reward badge.”
- **Duyệt:** `CAT-01` không bị che, điểm đọc được, nút Level tiếp theo/Home luôn chạm được.

### SFX-01 — Bộ âm thanh phản hồi gốc

- **Dùng ở:** X/clear, đúng, sai, thắng, thua. Âm không là nguồn thông tin duy nhất.
- **Cấu tạo:** năm file `mark_clear`, `cat_correct`, `cat_wrong`, `win`, `lose`; âm ngắn, sắc thái vui/nhẹ. `win` dưới 2 giây. Tránh giọng nói và melody nhận diện từ tác phẩm khác.
- **Nguồn/xuất:** session/project âm thanh sửa được và WAV mono hoặc stereo 48 kHz; mức âm nhất quán, không clipping, không đuôi im lặng dài. Bản nén runtime chọn sau đo.
- **Prompt:** “Compose five original short, soft UI sound effects for a cheerful offline garden puzzle: a subtle mark/clear tick, a warm correct-cat accent, a gentle wrong-attempt cue, a brief win motif under two seconds, and a calm loss cue. Keep them nonverbal, low-fatigue and distinct at phone speakers. No recognizable melody, sampled commercial game audio or harsh alarm. Deliver separate clean files with editable source project.”
- **Duyệt:** tắt âm không mất thông tin; âm/rung có setting độc lập, không thêm độ trễ cho preview X hoặc điều hướng.

## 6. Cách nhận từng phần và chuyển sang tích hợp

Khi chủ dự án gửi một asset, agent tích hợp ghi ID, phiên bản, đường dẫn nguồn/xuất, kết quả kiểm alpha/kích thước/pivot, ảnh xem ở tỉ lệ sử dụng và quyết định `accepted` hoặc lý do cần sửa. Một file đến sớm không làm package M0 chức năng phải chờ. Nếu asset được sửa sau khi đã tích hợp, tăng phiên bản và thay trong package tích hợp có phạm vi `allowed_paths` phù hợp.

Package tích hợp sau cần đối chiếu các mã `UX-01/03..25`, `ART-01..11` và QA tương ứng trong GDD, nhưng chỉ nhận những mã có thể chứng minh bằng scene, thiết bị và người chơi ở giai đoạn đó. Đặc biệt `M0-A03` chốt ngân sách atlas/thiết bị; package brief này không gán pass cho `TECH-13/19/21` hoặc QA mobile. Các asset cuối cần chờ quyết định tên/logo O-01; mọi câu chữ trong prompt hiện không phụ thuộc tên tạm.
