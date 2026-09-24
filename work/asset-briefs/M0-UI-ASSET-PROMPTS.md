# M0 — UI và Asset Prompt Brief

Tài liệu này chuyển brief `M0-UI-ASSET-BRIEFS` thành danh sách thực thi dành cho việc tạo asset bằng công cụ AI hoặc công cụ đồ họa 2D/3D. Sau khi asset được gom đủ, agent tích hợp có thể dùng tài liệu này để dựng UI trong Godot.

## 1. Nguyên tắc chung

### 1.1 Phạm vi

MVP gồm các màn hình:

- Home `UX-01`
- Puzzle `UX-03`
- Tutorial Level 1 `UX-04`
- Result thắng `UX-05`
- Result thua `UX-06`
- Help/Luật `UX-07`
- Settings `UX-08`

Các asset hình ảnh và âm thanh cần tạo:

| ID | Đối tượng | Loại | Ưu tiên |
| --- | --- | --- | --- |
| `CAT-01` | Mèo mặc định | 3D model, rig, animation, sprite 2D | A |
| `RULE-01` | Bốn icon luật | Vector, PNG | A |
| `STATE-01` | Tim và cảnh báo | Vector, PNG | A |
| `NAV-01` | Icon điều hướng/hành động | Vector, PNG | B |
| `TUT-01` | Minh họa cử chỉ | Vector, PNG layer | B |
| `FX-01` | Sparkle và hiệu ứng thắng | PNG layer, animation tùy chọn | B |
| `BG-01` | Nền Home và Result | Layered background | C |
| `RESULT-01` | Khung Result thắng | Vector/layer, PNG | C |
| `SFX-01` | Âm thanh phản hồi | WAV và project nguồn | D |

### 1.2 Định hướng mỹ thuật chung

- Game puzzle vườn cây sáng sủa, thân thiện, dành cho màn hình điện thoại dọc.
- Hình khối mềm, nét sạch, tương phản rõ, dễ đọc khi thu nhỏ.
- Mèo có màu lông trung tính, không bị nhuộm theo màu vùng puzzle.
- Icon đơn sắc, để Godot tự áp màu và trạng thái.
- Asset không chứa chữ, số, logo, tên thương hiệu hoặc giao diện hoàn chỉnh.
- Không sao chép nhân vật, icon, âm thanh, bố cục hoặc level của game thương mại.
- Ưu tiên hình dạng và độ tương phản thay vì chỉ dùng màu để truyền đạt thông tin.
- Luôn chừa safe area cho chữ và nút trên màn hình dọc.

### 1.3 Mẫu cấu trúc prompt

Có thể dùng cấu trúc sau cho từng công cụ AI:

```text
Create an original [asset type] for a bright portrait-mobile garden logic puzzle.
Subject: [đối tượng chính].
Purpose: [nơi sử dụng và thông tin cần truyền đạt].
Visual language: [hình khối, nét, màu, độ tương phản, mức chi tiết].
Composition: [bố cục, khoảng trống, hướng nhìn, vùng an toàn].
Variants: [các trạng thái hoặc phiên bản cần tạo].
Technical output: [nền trong suốt, vector, kích thước, layer, frame, file nguồn].
Keep the design original, reusable, readable at small size, and free of baked text.
```

Negative prompt dùng chung:

```text
No words, letters, numbers, logo, watermark, brand identity, UI screenshot,
button background, baked text, commercial game imitation, copied character,
copied iconography, noisy detail, unreadable tiny marks, fake checkerboard,
opaque background when transparency is requested, flashing effect, gore,
photorealistic style, or elements outside the requested canvas.
```

## 2. Ranh giới UI và asset

### 2.1 Thành phần AI cần tạo

- Nhân vật mèo và các animation của mèo.
- Icon luật, icon trạng thái, icon điều hướng.
- Minh họa cử chỉ tutorial.
- Sparkle, progress highlight và sticker thắng không chữ.
- Nền vườn cho Home và Result.
- Khung trang trí Result thắng.
- Âm thanh phản hồi.

### 2.2 Thành phần Godot sẽ dựng

- Text, số level, điểm số, nhãn vùng A–F và nội dung tutorial.
- Board, lưới ô, màu vùng và họa tiết vùng A–F.
- Nền nút, vùng chạm, layout, safe area và responsive layout.
- Trạng thái pressed, selected, disabled của nút.
- Switch trong Settings.
- Dấu X đỏ của ô sai; asset `warning` và `lock` chỉ cung cấp hình hỗ trợ.
- Thanh tiến độ, bộ đếm tim và toàn bộ dữ liệu động.
- Tint/ánh sáng khác nhau cho Result thắng và Result thua.

Không tạo một ảnh screenshot chứa toàn bộ UI. Các lớp cần được tách để Godot có thể thay chữ, dữ liệu, màu và trạng thái.

## 3. Danh sách màn hình UI

## 3.1 Home — `UX-01`

### Mục đích

Màn hình vào game, cho người chơi biết level hiện tại và bắt đầu hoặc tiếp tục chơi.

### Thành phần cần bố trí

- Nền vườn dọc `BG-01`.
- Tên/số level hiện tại do Godot render.
- Nút Chơi hoặc Tiếp tục.
- Nút Trợ giúp dùng `NAV-01/help`.
- Nút Settings dùng `NAV-01/settings`.
- Mèo `CAT-01` nếu layout chọn hiển thị nhân vật.

### Yêu cầu layout

- Khu vực trung tâm yên, ít chi tiết để đặt tiêu đề và nút.
- Không đặt chi tiết nền dưới safe area của chữ/nút.
- Nút chính phải nổi bật hơn nút phụ.
- Không bake tên game hoặc logo cuối vào background.

### Prompt bối cảnh tham khảo

```text
Create an original bright portrait mobile game home-screen background for a garden logic puzzle. Use soft foliage and simple garden shapes framing the left and right edges, with a quiet low-detail center for a live level title, a primary play button, and secondary help and settings controls. Keep the upper and lower safe areas calm and readable. Cheerful, warm, clean, and compact rather than busy. Deliver separate far-background and foreground decoration layers, with no cat, no board, no text, no logo, and no UI controls.
```

## 3.2 Puzzle — `UX-03`

### Mục đích

Màn chơi chính, nơi người chơi giải board và luôn nhìn thấy bốn luật.

### Thành phần cần bố trí

- Header và dữ liệu level do Godot.
- Ba tim `STATE-01`.
- Dải bốn luật `RULE-01` gồm row, column, region, diagonal.
- Board do Godot dựng.
- Màu, nhãn và họa tiết vùng A–F do Godot dựng.
- Tiến độ N vị trí.
- Undo, Restart, Hint, Help và Settings dùng `NAV-01`.
- Mèo `CAT-01` trong các ô given/cat.
- Phản hồi đúng từ `FX-01`.

### Yêu cầu layout

- Không hiển thị điểm trong lúc đang chơi.
- Board là vùng thao tác ưu tiên; không để decoration che ô.
- Bốn luật phải đọc được cùng label chữ, không phụ thuộc riêng vào icon.
- Icon và chữ phải còn rõ ở kích thước điện thoại nhỏ.
- Phản hồi đúng chỉ ngắn và không khóa input.
- Cảnh báo ô sai phải có hình dạng ngoài màu đỏ.

### Prompt icon luật

```text
Create four original cohesive monochrome pictogram icons for a mobile garden logic puzzle. Show one cat per row, one cat per column, one cat per outlined patterned region, and cats forbidden from touching diagonally. Use tiny square-grid diagrams and a simple abstract cat marker with bold clean contours, generous negative space, and consistent line weight. Create each icon separately on a transparent background, readable at approximately 44 logical points, suitable for code-applied color. No letters, words, numbers, solution layout, button background, or decorative detail that hides the rule.
```

## 3.3 Tutorial Level 1 — `UX-04`

### Mục đích

Giải thích thao tác thông qua sáu mốc T1–T6 và hành động thật của người chơi.

### Thành phần cần bố trí

- Board ví dụ do Godot dựng.
- Ô focus và trạng thái board do Godot.
- Nội dung chữ và hành động T1–T6 do Godot.
- Tiến độ theo hành động.
- Overlay cử chỉ từ `TUT-01`.
- Điều hướng bằng `NAV-01/back` và `NAV-01/help` nếu cần.

### Yêu cầu layout

- Overlay phải nằm trên khu vực minh họa nhưng không chiếm vùng input.
- Ô đang được tập phải vẫn nhìn thấy.
- Chữ hướng dẫn nằm ngoài asset hình, có thể thay đổi hoặc dịch.
- Có phiên bản tĩnh khi bật reduced motion.

## 3.4 Result thắng — `UX-05`

### Mục đích

Xác nhận người chơi hoàn thành level và cho phép đi tiếp hoặc về Home.

### Thành phần cần bố trí

- Nền `BG-01`, có thể dùng tint ấm.
- Mèo `CAT-01/celebrate`.
- Khung trang trí `RESULT-01`.
- Điểm lượt và câu khích lệ do Godot.
- Nút Level tiếp theo và Home.
- Sticker hoặc sparkle `FX-01`.

### Yêu cầu layout

- Mèo và điểm số nằm trong vùng trung tâm thoáng.
- Khung không che mèo, điểm hoặc nút.
- Nút phải dùng được ngay cả khi hiệu ứng đang chạy.
- Không dùng chữ hoặc số bake vào sticker.

## 3.5 Result thua — `UX-06`

### Mục đích

Thông báo người chơi đã dùng hết ba tim và cho phép chơi lại hoặc về Home.

### Thành phần cần bố trí

- Nền `BG-01`, có thể dùng tint dịu hơn.
- Mèo `CAT-01/sad`.
- Ba tim rỗng hoặc mất từ `STATE-01`.
- Điểm lượt do Godot.
- Nút Retry và Home.

### Yêu cầu layout

- Cảm xúc nhẹ nhàng, không tạo cảm giác phạt nặng.
- Không tái sử dụng khung sticker thắng làm bố cục chính.
- Thông tin và nút phải đọc được khi không có âm thanh.

## 3.6 Help/Luật — `UX-07`

### Mục đích

Giải thích bốn luật và thao tác thông qua board minh họa.

### Thành phần cần bố trí

- Ví dụ hàng, cột, vùng và chạm chéo do Godot dựng từ board mẫu.
- Icon `RULE-01`.
- Overlay `TUT-01` khi minh họa thao tác.
- Chữ giải thích và nút Back do Godot.

### Yêu cầu layout

- Mỗi luật có icon, label và ví dụ trực quan.
- Ví dụ không được là lời giải của một level thật.
- Không dùng ảnh screenshot hoàn chỉnh làm asset cố định.

## 3.7 Settings — `UX-08`

### Mục đích

Cho phép người chơi điều chỉnh âm thanh, rung, reduced motion và hỗ trợ phân biệt vùng.

### Thành phần cần bố trí

- Icon `sound`.
- Icon `vibration`.
- Icon `reduced_motion`.
- Icon `region_assist`.
- Switch, label và trạng thái bật/tắt do Godot.
- Nút Back dùng `NAV-01/back`.

### Yêu cầu layout

- Mỗi setting phải có label hoặc accessibility text.
- Trạng thái bật/tắt không chỉ dựa vào màu.
- Reduced motion phải thay animation bằng frame tĩnh khi có thể.

## 4. Phiếu tạo asset chi tiết

## 4.1 `CAT-01` — Mèo mặc định

### Sử dụng

Puzzle, Home tùy chọn, Result thắng, Result thua và phản hồi đặt mèo đúng.

### Nội dung cần tạo

1. Character turnaround: front, side, three-quarter.
2. Model 3D gốc chỉnh sửa được.
3. Rig ổn định, có pivot chân rõ.
4. Animation `idle`, `jump`, `celebrate`, `sad`.
5. Icon và silhouette tĩnh.
6. Sprite sequence PNG RGBA từ cùng camera.
7. Frame tĩnh cho reduced motion.

### Định hướng hình ảnh

- Silhouette nhỏ gọn, nhận ra được tai, mặt, chân và đuôi.
- Mắt và biểu cảm rõ khi thu nhỏ vào ô N=6.
- Lông màu trung tính, tách khỏi palette vùng A–F.
- Hình khối mềm, sạch, thân thiện; không phụ kiện giống nhân vật có sẵn.
- Camera orthographic cố định, ánh sáng nhất quán.

### Prompt concept

```text
Design an original friendly cat character for a bright garden logic puzzle on a portrait phone screen. Show a consistent front, side, and three-quarter turnaround with a compact silhouette, readable ears, face, legs, and tail at small size. Include neutral, joyful, and gently disappointed expressions. Use soft shapes, clean edges, warm playful personality, and neutral fur independent of puzzle-region colors. Plain background, no words, no logo, no accessories resembling an existing game character. Keep proportions identical across every view.
```

### Prompt model và animation

```text
Create an original editable 3D cat model from the approved character turnaround. Separate the head, ears, tail, and limbs as needed for animation. Build a clean rig with consistent scale and a stable ground pivot. Produce four readable clips: calm idle, short upward jump, joyful celebrate, and gentle sad reaction. Render orthographic transparent 2D frames from one fixed camera with consistent lighting, scale, canvas, and alpha. Also provide a calm static frame for reduced motion. Do not recolor the cat by puzzle region and do not bake UI text, board, or background into the frames.
```

### Bàn giao

- File model/rig/animation nguồn, ưu tiên `.blend` hoặc tương đương.
- Bản trao đổi `.glb` nếu phù hợp.
- PNG sequence RGBA cho từng clip.
- Icon và silhouette nền trong suốt.
- Mỗi frame cùng canvas, pivot, camera và khoảng trống.

### Kiểm tra

- Nhận ra mèo khi đặt vào ô N=6.
- Không nhầm icon mèo với X hoặc warning.
- Bốn clip giữ nguyên ngoại hình.
- Animation không che board hoặc vùng touch.

## 4.2 `RULE-01` — Bốn icon luật

### Nội dung cần tạo

- `rule_row`
- `rule_column`
- `rule_region`
- `rule_diagonal`

### Định hướng hình ảnh

- Sơ đồ ô vuông tối giản.
- Dấu mèo trừu tượng, không cần vẽ mèo chi tiết.
- Icon region phải có viền hoặc họa tiết vùng.
- Icon diagonal phải thể hiện hai ô kề góc.
- Cùng lưới căn chỉnh, cùng trọng lượng nét, cùng lề.
- Đơn sắc, dễ đổi màu bằng code.

### Prompt

```text
Create four original cohesive monochrome pictograms for a portrait mobile garden logic puzzle. The four separate symbols must communicate: one cat per row, one cat per column, one cat per outlined patterned region, and cats cannot touch diagonally. Use miniature square-cell diagrams, simple abstract cat markers, bold clean contours, generous negative space, and a consistent rounded line weight. Make every icon readable at approximately 44 logical points and suitable for code-applied tinting. Deliver four separate transparent assets. No letters, words, numbers, solution level, UI screenshot, button background, or copied commercial iconography.
```

### Bàn giao

- 4 file vector chỉnh sửa được.
- 4 PNG RGBA 256×256.
- Tên file thống nhất và mỗi icon là một file riêng.

## 4.3 `STATE-01` — Tim, warning và lock

### Nội dung cần tạo

- `heart_full`
- `heart_empty`
- `warning`
- `lock`

### Định hướng hình ảnh

- Tim đầy và tim rỗng có cùng silhouette.
- Warning phải hiểu được khi chuyển sang grayscale.
- Lock nhỏ nhưng còn nhận ra ở kích thước thấp.
- Không dùng chớp sáng hoặc hiệu ứng nhấp nháy.
- Cảnh báo không được phụ thuộc hoàn toàn vào màu đỏ.

### Prompt

```text
Create an original cohesive set of four clean mobile puzzle status icons: a full heart, an empty heart, a caution mark, and a small lock. Use strong silhouettes, consistent line weight, friendly garden-game tone, and clear visual centers. The caution mark and lock must remain understandable in grayscale through shape and contour, not hue alone. Deliver four separate transparent images, suitable for code-applied colors. No text, no glow, no flashing effect, no warning based only on red color, and no copied game iconography.
```

### Bàn giao

- Nguồn vector riêng cho từng icon.
- PNG RGBA 256×256.
- Phiên bản tĩnh, không animation.

## 4.4 `NAV-01` — Icon điều hướng và hành động

### Nội dung cần tạo

```text
home, back, help, settings, undo, restart, hint,
sound, vibration, reduced_motion, region_assist
```

### Định hướng hình ảnh

- Hình học bo tròn, nét tự tin, nhiều khoảng âm.
- Cùng viewBox, cùng lề, cùng trọng lượng nét.
- Icon monochrome, không gắn nền nút.
- Disabled/pressed/selected sẽ do Godot xử lý.
- Region assist nên gợi ý họa tiết hoặc pattern hỗ trợ phân biệt vùng, không chỉ là một giọt màu.

### Prompt

```text
Create an original cohesive set of eleven monochrome action icons for a bright garden mobile logic puzzle: home, back, help, settings, undo, restart, hint, sound, vibration, reduced motion, and region-assist pattern. Use simple rounded geometry, confident contours, ample negative space, and a shared alignment grid. Make every symbol readable at approximately 44 logical points and suitable for UI tinting. Deliver each symbol separately on a transparent background as editable vector and PNG. No text, button background, cat character, brand mark, copied commercial icon, or decorative detail that changes the meaning.
```

### Bàn giao

- 11 file vector.
- 11 PNG RGBA 256×256.
- Cùng viewBox, lề và trọng lượng nét.

## 4.5 `TUT-01` — Overlay cử chỉ

### Nội dung cần tạo

- `gesture_tap`: một ngón tay và vòng chạm.
- `gesture_drag`: ngón tay, đường kéo ngắn qua các ô liền kề.
- `gesture_double_tap`: hai nhịp chạm trên chính xác cùng một ô.

### Định hướng hình ảnh

- Ngón tay stylized, không photorealistic.
- Vòng chạm và đường kéo tách layer.
- Giữ ô đích nhìn thấy được.
- Overlay không che chữ hướng dẫn hoặc vùng input.
- Mỗi cử chỉ có bản tĩnh rõ nghĩa.

### Prompt

```text
Create three original instructional gesture overlays for a portrait mobile garden puzzle: a fingertip tap, a short drag path through adjacent square cells, and two sequential taps on exactly the same cell. Draw the finger, contact ring, and drag path as separate transparent layers with a consistent rounded visual style. Keep the target cell visible and leave open space for live Vietnamese instruction text outside the artwork. No board screenshot, words, numbers, UI panel, or imitation of a commercial tutorial.
```

### Bàn giao

- Nguồn vector hoặc layer chỉnh sửa được.
- PNG RGBA riêng cho từng lớp.
- Ghi rõ pivot và điểm chạm trong `source.md`.

## 4.6 `FX-01` — Phản hồi đúng và sticker thắng

### Nội dung cần tạo

- Sparkle nhỏ.
- Progress highlight tĩnh.
- Khung/sticker thắng không chữ.
- Phiên bản tĩnh cho reduced motion.
- Sequence animation nếu cần.

### Định hướng hình ảnh

- Garden-themed, vui nhưng tiết chế.
- Không che board, tim, luật hoặc navigation.
- Không vẽ mèo, điểm số, chữ hoặc confetti wall.
- Hiệu ứng Puzzle ngắn, khoảng tối đa 0,7 giây.
- Result có thể loop nhẹ nhưng nút luôn dùng được.

### Prompt

```text
Create original restrained garden-themed celebration accents for a mobile logic puzzle: a few soft sparkles, one small progress highlight, and a wordless win sticker frame. Use bright cheerful accents without covering the board, hearts, rule icons, or navigation. Export every element as a separate transparent layer and provide a calm static variant for reduced motion. No cat, score number, text, logo, confetti wall, intense flash, glow overload, or effect that blocks input.
```

### Bàn giao

- PNG RGBA từng element.
- Nguồn layer chỉnh sửa được.
- Nếu có sequence: mọi frame cùng canvas và pivot.

## 4.7 `BG-01` — Nền Home và Result

### Nội dung cần tạo

- Layer nền xa.
- Layer foliage/trang trí tiền cảnh.
- Bản gốc đủ lớn cho màn hình dọc tối thiểu 1080×1920.
- Có thể tạo thêm bản tham khảo warm-win và calm-loss, nhưng ưu tiên Godot tint từ nền gốc.

### Định hướng hình ảnh

- Vườn sáng, thân thiện, không quá chi tiết.
- Hai bên có foliage để tạo khung.
- Trung tâm và vùng đặt text/nút phải yên.
- Crop được ở nhiều tỉ lệ điện thoại.
- Không đưa mèo, board, chữ, logo hoặc UI vào nền.

### Prompt

```text
Paint an original bright welcoming garden background for a portrait mobile logic game. Use gentle foliage and simple organic shapes to frame the left and right edges, while keeping a quiet low-detail center for live Vietnamese UI text, score, and buttons. Separate far background and foreground decoration as editable layers so the art can crop across different phone aspect ratios. Keep the design cheerful, subtle, readable, and safe-area friendly. No cat character, puzzle grid, words, logo, UI controls, sticker, or resemblance to an existing game.
```

### Bàn giao

- File nguồn layer chỉnh sửa được.
- Xuất preview tối thiểu 1080×1920.
- Ghi rõ safe area và vùng có thể crop.

## 4.8 `RESULT-01` — Khung Result thắng

### Nội dung cần tạo

- Khung trang trí hoa/lá.
- Petal và accent shape.
- Huy hiệu trống không chữ.
- Foreground pieces tách riêng.
- Vùng trung tâm trống cho mèo và score.

### Định hướng hình ảnh

- Chỉ dùng cho màn thắng.
- Không che mèo, điểm, lời khích lệ hoặc nút.
- Có thể thay đổi vị trí khi màn hình khác tỉ lệ.
- Khung tham chiếu khoảng 720×720 trên canvas 1080×1920.

### Prompt

```text
Create an original wordless celebratory garden sticker frame for a mobile puzzle win screen. Use a few soft leaves, petals, and warm accent shapes around an open central space reserved for a separately animated cat and live score text. Export the frame and foreground pieces as separate transparent layers so the composition can adapt to different screens. Keep result buttons unobstructed. No numbers, letters, cat illustration, logo, copied reward badge, dense border, or baked UI.
```

### Bàn giao

- File vector/layer chỉnh sửa được.
- PNG RGBA từng phần.
- Preview trên canvas 1080×1920.

## 4.9 `SFX-01` — Âm thanh phản hồi

### Nội dung cần tạo

- `mark_clear`: tick nhẹ khi đánh dấu/xóa.
- `cat_correct`: âm ấm, vui khi đặt mèo đúng.
- `cat_wrong`: âm sai nhẹ, không gây căng thẳng.
- `win`: motif thắng ngắn dưới 2 giây.
- `lose`: âm thua dịu, không mang tính trừng phạt.

### Định hướng âm thanh

- Âm thanh không được là nguồn thông tin duy nhất.
- Tắt âm vẫn phải chơi được và hiểu được trạng thái.
- Tránh giọng nói, còi báo động, âm chói và melody dễ nhận diện.
- Âm lượng giữa các file nhất quán.

### Prompt âm thanh

```text
Compose five original short, soft UI sound effects for a cheerful offline garden puzzle: a subtle mark-clear tick, a warm correct-cat accent, a gentle wrong-attempt cue, a brief win motif under two seconds, and a calm loss cue. Keep the sounds nonverbal, low-fatigue, distinct on phone speakers, and free from recognizable melodies. Avoid harsh alarms, clipping, long silence, sampled commercial game audio, and dramatic cinematic effects. Deliver separate clean files and an editable source project.
```

### Bàn giao

- WAV mono hoặc stereo, 48 kHz.
- Project âm thanh chỉnh sửa được.
- Không clipping, không đuôi im lặng dài.
- Tên file đúng manifest.

## 5. Checklist trước khi gửi asset

### Nội dung

- [ ] Đúng ID asset.
- [ ] Đúng số lượng file và variant.
- [ ] Không có chữ, số, logo hoặc watermark bị bake.
- [ ] Không dùng reference từ game thương mại.
- [ ] Asset tách lớp, không gộp nhân vật với nền hoặc UI.

### Kỹ thuật

- [ ] Nền trong suốt là alpha thật, không phải nền caro vẽ sẵn.
- [ ] Icon có nguồn vector và PNG RGBA 256×256.
- [ ] Sprite animation có cùng canvas, camera, pivot và scale.
- [ ] Background có nguồn layer và preview tối thiểu 1080×1920.
- [ ] Âm thanh 48 kHz, không clipping.
- [ ] Tên file dùng chữ thường, số và dấu gạch dưới.

### Accessibility và gameplay

- [ ] Có thể hiểu icon ở grayscale.
- [ ] Trạng thái không chỉ khác nhau bằng màu.
- [ ] Asset không che board hoặc vùng touch.
- [ ] Có frame tĩnh cho reduced motion khi phù hợp.
- [ ] Nút và text vẫn do Godot điều khiển được.

## 6. Cấu trúc thư mục bàn giao

Mỗi ID nên được gom theo cấu trúc:

```text
assets/<ID>/
├── source/
├── export/
└── source.md
```

Trong `source.md`, ghi:

- Người hoặc công cụ tạo.
- Ngày tạo và phiên bản công cụ.
- Prompt đầy đủ.
- Reference tự tạo nếu có.
- Quyền sử dụng.
- Mô tả chỉnh sửa hậu kỳ.
- Danh sách file nguồn và file xuất.
- Ghi chú alpha, canvas, pivot, safe area và variant.

## 7. Thứ tự tạo đề xuất

1. `CAT-01`, `RULE-01`, `STATE-01` — giúp thay hình tạm trên Puzzle.
2. `NAV-01`, `TUT-01`, `FX-01` — giúp dựng Tutorial, Help và thao tác.
3. `BG-01`, `RESULT-01` — hoàn thiện Home và Result.
4. `SFX-01` — gắn vào các event sau khi UI đã có.

Các thông số atlas, nén và kích thước runtime cuối cùng sẽ được chốt sau khi có kết quả đo thiết bị của `M0-A03`.
