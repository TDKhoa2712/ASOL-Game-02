# HOME SCREEN UI REDESIGN SPEC (Godot 4)

> **Mục tiêu:** Chỉnh `home.tscn` của game (hiện tên **MÈO LOGIC**) để có bố cục & phong cách tương tự màn hình chính của tham chiếu **Meow Doku**.
> **Không cần giống 100%.** Assets (logo, avatar, icon…) sẽ được chủ dự án thay sau → mọi asset phải là **placeholder dễ thay** (chỉ đổi thuộc tính `texture`, không sửa code/layout).
> **Phạm vi:** CHỈ màn Home. Không đụng gameplay, không đụng các màn khác.

---

## 0. Đọc trước khi làm (BẮT BUỘC)

1. Mở `home.tscn` hiện tại + `scripts/pastel_backdrop.gd`.
2. **Tìm script điều khiển màn Home.** `home.tscn` KHÔNG gắn script lên node `Home`, nghĩa là logic (đổi text nút, bắt signal `pressed`, đổi màn) nằm ở nơi khác (screen manager / main / autoload). Chạy grep:
   - `grep -rn "SafeArea" --include=*.gd .`
   - `grep -rn "PlayButton\|HelpButton\|SettingsButton\|CurrentLevelLabel\|ProgressHint\|ProfileLabel\|SavedLabel\|HeroText" --include=*.gd .`
   - `grep -rn "screen_id" --include=*.gd .`
3. Ghi lại **mọi node path** mà script đang dùng. Nếu đổi cây node → **phải cập nhật script tương ứng** (hoặc giữ tên + dùng Unique Name `%`). Không được để lỗi `Node not found`.
4. Kiểm tra `project.godot`: kích thước viewport gốc (ước tính 540×960), `stretch/mode`, `stretch/aspect`, orientation portrait.
5. Kiểm tra font đang dùng. **Font mới phải hỗ trợ tiếng Việt đầy đủ dấu** (xem §6).

---

## 1. Phân tích tham chiếu (Meow Doku, ảnh 1159×2576 ≈ 9:20)

Toàn bộ số đo bên dưới là **ước lượng từ ảnh**, quy đổi về nền **540 px rộng** (hệ số ≈ 0.466) và **tỉ lệ theo chiều cao màn hình** để chạy được nhiều tỉ lệ (9:16 → 9:20).

### 1.1 Bố cục tổng thể (từ trên xuống)

| # | Khối | Vị trí (tỉ lệ màn hình) | Kích thước @540w | Ghi chú |
|---|------|-------------------------|------------------|---------|
| A | **Avatar** (góc trái trên) | x 3.3% → 18.8%, y 4.2% → 11.2% | ~84×84 px | Khung vuông bo góc ~10px, viền xanh lá dày ~4px, ảnh mèo nền tím nhạt |
| B | **Currency pill** (giữa trên) | tâm x 50%, y 4.7% → 8.9% | ~150×50 px | Pill trắng, icon cuộn len bên trái + số bên phải (đậm, nâu cam) |
| C | **Nút Settings** (góc phải trên) | tâm x ≈ 92%, tâm y ≈ 6.8% | Ø ~49 px | Hình tròn trắng, icon bánh răng màu nâu tím |
| D | **Logo** | x 26% → 74%, y 20.5% → 34.2% | rộng ~260 px, tỉ lệ ~1.57:1 | 2 dòng chữ nâu, chữ "O" là biểu tượng mèo (tai xanh / đuôi cam) |
| E | **Side rail trái** (Leaderboard) | x 3.4% → 24.5%, y 45.7% → 54.8% | icon ~114 px + timer pill | Bục podium 1-2-3 trong vòng cam; dưới là pill tối chứa đếm ngược `HH:MM:SS` |
| F | **Nút chính "Tiếp Tục"** | x 15.4% → 84.6%, y 70.8% → 77.4% | ~374×79 px | Pill cam, chữ lớn + dòng phụ "Màn N", có glow cam |
| G | **Nút phụ "Thử Thách Hằng Ngày"** | x 15.4% → 84.6%, y 80.0% → 86.6% | ~374×77 px | Pill xanh tím (periwinkle) |
| H | **Timer tab dưới nút G** | tâm x 50%, ngay dưới nút G | ~130×33 px | Tab dính vào đáy nút G, chỉ bo góc dưới, icon đồng hồ + `HH:MM:SS` |
| I | Vùng trống đáy | y 89% → 100% | — | Chừa safe-area, không có bottom nav |

**Khoảng trống lớn giữa Logo (D) và Nút chính (F) là chủ ý** (vùng thở + chỗ cho side rail E). Không lấp đầy.

### 1.2 Nền (Background)

- Màu nền kem: ≈ `#F7F1EC`.
- Lưới **ô vuông bo góc** (~6 cột, mỗi ô ≈ 16% chiều rộng, khe ≈ 1%), màu chênh rất nhẹ so với nền (`#FAF5F0` hoặc trắng α≈0.35).
- Lưới **đậm ở đỉnh & đáy, mờ dần về giữa** (vùng logo/nút gần như phẳng) → dùng gradient alpha theo trục Y.
- Vài ô có **họa tiết mờ**: dấu `X`, hình đầu mèo (nét đào nhạt `#F5E3D0`, α 0.3–0.5), đặt rải rác, KHÔNG đè lên logo/nút.

### 1.3 Bảng màu (ước lượng)

| Token | Hex | Dùng cho |
|-------|-----|----------|
| `bg_cream` | `#F7F1EC` | Nền |
| `bg_tile` | `#FAF5F0` | Ô lưới nền |
| `deco_peach` | `#F5E3D0` | Họa tiết X / mèo mờ |
| `brown_logo` | `#8B5A3C` | Chữ logo |
| `blue_accent` | `#8FA5F1` | Nút phụ, tai mèo logo |
| `orange_primary` | `#F0932A` | Nút chính, vòng cam |
| `text_white` | `#FFFFFF` | Chữ trên nút |
| `text_white_soft` | `#FFFFFF` α 0.85 | Dòng phụ trên nút |
| `currency_text` | `#A85A0A` | Số trên currency pill |
| `gear_mauve` | `#86546A` | Icon bánh răng |
| `avatar_border` | `#7DB843` | Viền avatar |
| `timer_dark` | `#645858` | Pill timer leaderboard |

> Bảng màu hiện tại của MÈO LOGIC (`#F2956B` cam, `#899EF0` xanh, `#6D4A45` nâu) đã rất gần → **giữ hệ màu hiện có làm chuẩn**, chỉ điều chỉnh về các token trên nếu thấy hợp. Gom mọi màu vào **một chỗ** (Theme hoặc file `ui_tokens.gd`) để chủ dự án đổi dễ.

### 1.4 Typography

- Font tham chiếu: sans **bo tròn, đậm, hình học** (kiểu Baloo / Nunito Black / Fredoka).
- Tiêu đề nút chính: ~38 px bold trắng, có bóng chữ rất nhẹ.
- Dòng phụ nút chính: ~20 px, trắng α 0.85.
- Tiêu đề nút phụ: ~26–28 px bold trắng.
- Timer: ~18–20 px bold, số dùng **tabular figures** nếu font hỗ trợ (tránh nhảy chữ khi đếm).
- Số currency: ~28 px bold.

### 1.4 Hình dạng & hiệu ứng

- **Mọi nút chính/phụ là pill hoàn toàn** (`corner_radius = chiều cao / 2`, dùng 999 cũng được).
- Nút có **glow/bóng màu cùng tông nút** (không phải bóng đen): alpha ~0.35, size ~20, offset `(0, 6)`.
- Không có card lớn bao quanh nội dung (khác với bản hiện tại).

---

## 2. So sánh hiện tại → mục tiêu

| Hiện tại (`home.tscn`) | Mục tiêu |
|------------------------|----------|
| Card lớn `Content` (PanelContainer, bo 44) bao mọi thứ | **Bỏ card**, nội dung thả trực tiếp lên nền |
| `TopBar`: 2 Label chữ "✦ VƯỜN NHỎ" và "● ĐÃ LƯU" | Avatar + Currency pill + nút Settings tròn |
| `HeroCard` chứa tagline "BỐN MÙA · BỐN VÙNG · MỘT LỜI GIẢI" (cao 118) | Bỏ khối card; tagline (nếu giữ) thành **1 dòng nhỏ dưới logo** |
| `Title` Label "MÈO LOGIC" cỡ 64 | **Logo** (`TextureRect`), Label làm fallback tới khi có asset |
| `CurrentLevelLabel` riêng | Gộp vào **dòng phụ của nút chính** |
| `PlayButton` 240×92 radius 36 | Pill lớn ~374×79, glow, 2 dòng chữ |
| `HelpButton` xanh 240×76 | Chuyển thành **nút icon tròn** ở side rail trái (vị trí của leaderboard) |
| `SettingsButton` viền trắng 240×76 | Thành **icon bánh răng tròn** góc phải trên |
| `ProgressHint` "Tiến trình được lưu tự động" | Giữ, chữ nhỏ ở đáy màn (hoặc gộp vào chỉ báo "Đã lưu" nhỏ) |
| `Backdrop` (pastel_backdrop.gd) tile hai bên mép | Điều chỉnh: lưới 6 cột, mờ dần giữa, thêm họa tiết X/mèo |

---

## 3. Cây node đề xuất

Giữ `Home` (Control, `metadata/screen_id = "home"`) và `Backdrop` như cũ. Dùng **anchor theo tỉ lệ** (không hard-code pixel toàn màn).

```
Home (Control, full rect)                      metadata/screen_id = "home"
├── Backdrop (Control, full rect, script pastel_backdrop.gd)   [giữ, chỉnh theo §4.1]
└── SafeArea (MarginContainer/Control, full rect, tôn trọng notch)
    ├── TopBar (Control, anchor top, cao ~60)
    │   ├── AvatarButton (Button/TextureButton)   -> khung viền xanh + TextureRect "AvatarImage"
    │   ├── CurrencyPill (PanelContainer, giữa)
    │   │   └── HBox: TextureRect "CurrencyIcon" + Label "CurrencyValue"
    │   └── SettingsButton (Button, tròn Ø49, icon gear)      <- GIỮ TÊN
    ├── LogoBlock (VBox, anchor tâm-trên, y 20%–34%)
    │   ├── LogoImage (TextureRect, keep_aspect_centered)     -> placeholder logo
    │   ├── Title (Label "MÈO LOGIC")                         <- fallback, ẩn khi LogoImage có texture; GIỮ TÊN
    │   └── Tagline (Label, nhỏ, tuỳ chọn)                    <- thay cho HeroText
    ├── SideRailLeft (VBox, anchor trái, tâm y ≈ 50%)
    │   ├── HelpButton (Button/TextureButton tròn ~ Ø 64–114)  <- GIỮ TÊN
    │   └── LeaderboardEntry (VBox)  [FEATURE FLAG, mặc định ẨN]
    │       ├── LeaderboardIcon (TextureButton)
    │       └── LeaderboardTimer (PanelContainer + Label "HH:MM:SS")
    ├── BottomStack (VBoxContainer, anchor đáy, y 70%–89%, gap ~14)
    │   ├── PlayButton (Button, pill cam)                      <- GIỮ TÊN
    │   │   └── VBox: Label "PlayTitle" + Label "PlaySubtitle"
    │   ├── DailyButton (Button, pill xanh)  [FEATURE FLAG, mặc định ẨN nếu game chưa có chế độ này]
    │   │   └── (tab dính đáy) DailyTimerTab: HBox icon đồng hồ + Label "DailyTimer"
    │   └── ProgressHint (Label, nhỏ)                          <- GIỮ TÊN
    ├── CurrentLevelLabel (Label)                              <- nếu script còn ghi vào node này, GIỮ và ẩn (visible=false) hoặc trỏ script sang PlaySubtitle
    ├── ProfileLabel / SavedLabel                              <- cũ; nếu script còn dùng thì giữ ẩn, không thì xóa cùng script
```

**Quy tắc đổi tên/di chuyển node:** mỗi node bị đổi path phải có dòng cập nhật tương ứng trong script điều khiển. Ưu tiên bật **Access as Unique Name (`%`)** cho các node script cần (`%PlayButton`, `%HelpButton`, `%SettingsButton`, `%PlaySubtitle`, `%ProgressHint`, …) để tránh vỡ path sau này.

---

## 4. Đặc tả từng thành phần

### 4.1 Backdrop
- Giữ `pastel_backdrop.gd`, **đọc trước khi sửa**. Thêm/sửa để có:
  - Lưới ô bo góc **6 cột**, số hàng theo chiều cao màn hình.
  - Alpha ô theo Y: `~1.0` ở 0–15% và 85–100% chiều cao, giảm về `~0.15` quanh 30–70%.
  - 4–8 họa tiết `X` / đầu mèo, α 0.3–0.5, vị trí **cố định theo seed** (không nhấp nháy mỗi lần vào màn).
  - `mouse_filter = IGNORE` (đã có).
- Có thể export biến: `tile_color`, `deco_color`, `columns`, `fade_center_alpha`.

### 4.2 Avatar (A)
- Khung ~84×84, viền 4px `avatar_border`, bo ~10. Ảnh bên trong `TextureRect` (`expand_mode = ignore size`, `stretch_mode = keep_aspect_covered`), clip bo góc (dùng `clip_children` hoặc `PanelContainer` + `clip_contents`).
- Placeholder: ô màu tím nhạt `#B9B3E6` + emoji/hình mèo đơn giản.
- Bấm → signal `avatar_pressed` (hiện có thể chưa làm gì; không được crash).

### 4.3 Currency pill (B)  — *tuỳ chọn*
- `PanelContainer`, nền trắng, bo hoàn toàn, bóng mềm (`shadow_color` nâu α 0.10, size 10, offset (0,4)). Padding ngang ~14.
- Icon 28 px trái, số phải, số cỡ ~28 bold `currency_text`.
- Nếu game **chưa có đồng tiền**: đặt `visible = false` qua biến `show_currency` (mặc định `false`). Bố cục vẫn phải đẹp khi ẩn.

### 4.4 Settings (C)
- Nút tròn Ø ~49 (min size 44×44 cho touch), nền trắng, icon gear `gear_mauve`, bóng nhẹ. Đặt cách mép phải ~18 px.
- **Giữ tên `SettingsButton` và signal `pressed`.**

### 4.5 Logo (D)
- `LogoImage`: `TextureRect`, `expand_mode = ignore size`, `stretch_mode = keep_aspect_centered`, `custom_minimum_size` ≈ (260, 165), căn giữa ngang.
- Khi `texture == null` → hiển thị `Title` (Label) làm fallback, cỡ ~54, màu `brown_logo`, font đậm.
- (Tuỳ chọn) animation nhẹ: logo "thở" scale 1.0↔1.02, 3s, loop; **tắt khi bật "giảm chuyển động"** trong Cài đặt (game đã có tuỳ chọn này – kiểm tra script settings).

### 4.6 Side rail trái (E)
- **HelpButton** (luật chơi): nút tròn nền trắng/kem, viền nhẹ, icon `?` hoặc quyển sách, vị trí tương ứng icon leaderboard của tham chiếu (x ≈ 3.4%, tâm y ≈ 50%). Giữ tên + signal.
- **Leaderboard + timer**: dựng sẵn nhưng **ẩn mặc định** (`show_leaderboard = false`). Timer là pill `timer_dark`, chữ trắng bold, định dạng `HH:MM:SS`. Không tự chế logic backend.

### 4.7 Nút chính `PlayButton` (F)
- Kích thước tối thiểu `Vector2(374, 79)` → nên dùng `size_flags_horizontal = FILL` với margin 15.4% hai bên để co giãn theo màn.
- StyleBoxFlat:
  ```
  bg_color = orange_primary (#F0932A hoặc giữ #F2956B)
  corner_radius_* = 999
  shadow_color = Color(orange, 0.35); shadow_size = 20; shadow_offset = Vector2(0, 6)
  content_margin_left/right = 24, top/bottom = 10
  ```
- Hai dòng: `PlayTitle` (~38 bold trắng) và `PlaySubtitle` (~20, trắng α 0.85).
- Trạng thái theo dữ liệu (kế thừa logic text hiện có trong script điều khiển — **không được làm mất**):
  - Chưa chơi: `Chơi` / `Level 1`
  - Đang dở: `Tiếp Tục` / `Level N`
  - Hoàn thành hết level hiện có: `Chơi lại từ L01` / (dòng phụ dùng câu mô tả hiện tại "Đã hoàn thành các level hiện có · MVP cho phép kiểm tra lại từ L01" — rút gọn cho vừa 1–2 dòng nhỏ, hoặc chuyển xuống `ProgressHint`).
- Thuật ngữ: dùng **"Level"** như game hiện tại (tham chiếu dùng "Màn"). Đổi sang "Màn" chỉ khi chủ dự án yêu cầu.
- Hiệu ứng nhấn: `pressed` → scale 0.96 (tween 80 ms), thả → về 1.0 (overshoot nhẹ). Có style `hover`, `pressed` (tối hơn 8%), `disabled` (xám nhạt).

### 4.8 Nút phụ `DailyButton` (G) + timer tab (H) — *tuỳ chọn*
- Cùng kích thước/bo/glow với PlayButton, màu `blue_accent`, chữ `Thử Thách Hằng Ngày` ~26–28 bold trắng.
- **Timer tab**: `PanelContainer` rộng ~130, cao ~33, chỉ bo **hai góc dưới** (~16), màu xanh tím hơi xám hơn nút (`#8E9FE8`), dính sát đáy nút, icon đồng hồ 18 px + `HH:MM:SS` ~20 bold.
- Nếu game **chưa có chế độ thử thách hằng ngày**: `visible = false` (biến `show_daily = false`). **Cần chủ dự án xác nhận** (xem §8).
- **Nút "Trợ giúp / Luật" cũ dạng pill xanh không còn ở đây** (đã chuyển sang side rail).

### 4.9 Chỉ báo lưu / hint
- `ProgressHint`: 11–12 px, màu `#8E706B` α 0.8, căn giữa, đặt dưới cùng `BottomStack` hoặc ~93% chiều cao. Nếu script còn cập nhật `SavedLabel` ("● ĐÃ LƯU") thì đưa nó thành chấm nhỏ cạnh `ProgressHint`, đừng để lạc chỗ.

---

## 5. Style tokens (đề xuất copy vào Theme/`ui_tokens.gd`)

```gdscript
# ui_tokens.gd  (autoload hoặc class_name UITokens)
const BG_CREAM        := Color("F7F1EC")
const BG_TILE         := Color("FAF5F0")
const DECO_PEACH      := Color("F5E3D0")
const BROWN_LOGO      := Color("8B5A3C")
const ORANGE_PRIMARY  := Color("F0932A")
const BLUE_ACCENT     := Color("8FA5F1")
const GEAR_MAUVE      := Color("86546A")
const AVATAR_BORDER   := Color("7DB843")
const TIMER_DARK      := Color("645858")
const CURRENCY_TEXT   := Color("A85A0A")
const PILL_RADIUS     := 999
const BTN_GLOW_ALPHA  := 0.35
```

Sub-resource mẫu cho `home.tscn` (nút chính):

```
[sub_resource type="StyleBoxFlat" id="StylePlay"]
bg_color = Color(0.941, 0.576, 0.165, 1)
corner_radius_top_left = 999
corner_radius_top_right = 999
corner_radius_bottom_right = 999
corner_radius_bottom_left = 999
shadow_color = Color(0.941, 0.576, 0.165, 0.35)
shadow_size = 20
shadow_offset = Vector2(0, 6)
content_margin_left = 24.0
content_margin_top = 10.0
content_margin_right = 24.0
content_margin_bottom = 10.0
```

---

## 6. Font

- Cần font **bo tròn, đậm, hỗ trợ đủ dấu tiếng Việt**. Gợi ý (license miễn phí, đều có Vietnamese subset): **Baloo 2**, **Nunito**, **Be Vietnam Pro**. Kiểm tra bằng chuỗi: `Thử Thách Hằng Ngày – Tiếp Tục – Chơi lại từ L01 – ưỡ ẩ ộ`.
- Tạo `FontVariation`/Theme cho 3 cỡ: `title`, `button`, `caption`. Không hard-code `theme_override_font_sizes` rải rác trong .tscn khi có thể dùng Theme.

---

## 7. Asset placeholder (chủ dự án sẽ thay)

Đặt tại `res://assets/ui/home/`. Nếu chưa có file → agent **tạo placeholder** (PNG đơn giản hoặc `StyleBox`/`ColorRect`), đặt **đúng tên** để chủ dự án ghi đè.

| File | Kích thước gợi ý (3× nền 540) | Ghi chú |
|------|-------------------------------|---------|
| `logo.png` | ~780×496, PNG trong suốt | Logo 2 dòng, thay cho `Title` |
| `avatar_default.png` | 256×256 | Ảnh mèo đại diện |
| `icon_currency.png` | 96×96 | Cuộn len / đồng tiền |
| `icon_settings.png` | 96×96 | Bánh răng (trắng hoặc nâu tím, tô màu bằng `modulate`) |
| `icon_help.png` | 96×96 | Dấu `?` / quyển sách |
| `icon_leaderboard.png` | 256×256 | Podium 1-2-3 |
| `icon_timer.png` | 64×64 | Đồng hồ bấm giờ |
| `bg_deco_x.png`, `bg_deco_cat.png` | 256×256 | Họa tiết mờ cho Backdrop |

Quy ước: icon dạng đơn sắc nên vẽ **trắng** rồi tô bằng `modulate`, để đổi màu không cần sửa file.

---

## 8. Câu hỏi cần chủ dự án xác nhận (agent KHÔNG tự quyết)

1. Game có **chế độ Thử Thách Hằng Ngày** không? (không → ẩn `DailyButton` + timer tab)
2. Game có **đồng tiền / cuộn len** không? (không → ẩn `CurrencyPill`)
3. Có **bảng xếp hạng** không? (không → ẩn `LeaderboardEntry`)
4. Có **avatar/hồ sơ** không? (không → ẩn `AvatarButton`, hoặc giữ chữ "VƯỜN NHỎ")
5. Giữ tagline "BỐN MÙA · BỐN VÙNG · MỘT LỜI GIẢI" hay bỏ?
6. Dùng "Level" hay "Màn"?

Trong lúc chờ: dựng **đầy đủ** các khối, đặt `show_*` = `false` cho phần chưa chắc, và ghi rõ trong báo cáo.

---

## 9. Kế hoạch task (chia cho agent)

| ID | Task | Phụ thuộc | Đầu ra |
|----|------|-----------|--------|
| T0 | Khảo sát: tìm script điều khiển, liệt kê node path đang dùng, kiểm tra viewport/font | — | Báo cáo ngắn (danh sách path + signal) |
| T1 | Tạo `ui_tokens.gd` + Theme (màu, font size, StyleBox pill) | T0 | File token + Theme |
| T2 | Sửa `pastel_backdrop.gd` theo §4.1 | T0 | Backdrop mới, có export biến |
| T3 | Dựng lại cây node `home.tscn` theo §3 (giữ tên node cốt lõi) | T0, T1 | `home.tscn` mới |
| T4 | Cập nhật script điều khiển cho khớp cây node mới, giữ nguyên logic text nút Play theo trạng thái | T3 | Diff script |
| T5 | Hiệu ứng nhấn nút + (tuỳ chọn) logo idle, tôn trọng "giảm chuyển động" | T3 | Tween |
| T6 | Tạo asset placeholder §7 | T3 | File PNG placeholder |
| T7 | Kiểm thử (§10) + chụp ảnh màn hình | T3–T6 | Báo cáo + ảnh |

Quy tắc: mỗi task nhỏ, commit riêng; không sửa file ngoài phạm vi; nếu vướng phải ghi lại thay vì tự đoán.

---

## 10. Tiêu chí nghiệm thu (Acceptance Checklist)

**Chức năng (không được hỏng)**
- [ ] Bấm Play/Tiếp tục vào đúng level như trước; text nút đúng theo 3 trạng thái (§4.7).
- [ ] Help mở đúng màn luật; Settings mở đúng màn cài đặt.
- [ ] Không có lỗi/warning `Node not found` hay `Invalid access` trong Output khi vào Home.
- [ ] Vào/ra Home nhiều lần không sinh node thừa, tween rò rỉ.
- [ ] Tuỳ chọn "giảm chuyển động" tắt được mọi animation mới.

**Giao diện**
- [ ] Không còn card lớn bao nội dung; nền lưới mờ dần về giữa.
- [ ] Logo (hoặc fallback Title) nằm ~20–34% chiều cao, căn giữa.
- [ ] Nút chính và nút phụ (nếu bật) là pill hoàn toàn, có glow cùng tông, rộng ~69% màn.
- [ ] Nút chính cao ≥ 72 px @540w; mọi vùng bấm ≥ 44×44 px.
- [ ] Đúng chính tả tiếng Việt, không mất dấu, không bị cắt chữ ("Thử Thách Hằng Ngày" nằm trọn 1 dòng ở 540w).
- [ ] Các khối ẩn (`show_*=false`) không để lại khoảng trống xấu.

**Đa kích thước** — kiểm tra ở: 540×960 (9:16), 540×1200 (9:20), 720×1280, 360×640 (nhỏ), và có notch/safe-area:
- [ ] Không chồng lấn, không tràn mép; khoảng thở giữa logo và nút chính co giãn hợp lý.

**Dễ thay asset**
- [ ] Thay `logo.png`, `avatar_default.png`, icon chỉ bằng cách đổi file/`texture`, không phải sửa layout.
- [ ] Mọi màu lấy từ tokens/Theme, không rải hard-code.

---

## 11. Ngoài phạm vi / Cấm

- Không đổi logic gameplay, lưu tiến trình, hay các màn khác.
- Không tự thêm hệ thống mới (currency, leaderboard, daily challenge…) — chỉ dựng UI và ẩn nếu chưa có.
- Không copy asset của Meow Doku (logo, nhân vật, icon). Chỉ tham khảo **bố cục, tỉ lệ, phong cách**; asset phải tự tạo hoặc do chủ dự án cung cấp.
- Không thay đổi tên node cốt lõi (`PlayButton`, `HelpButton`, `SettingsButton`, `ProgressHint`, `Title`, `CurrentLevelLabel`) trừ khi đã cập nhật script và ghi vào báo cáo.

---

## 12. Định dạng báo cáo khi xong

1. Danh sách file đã sửa/tạo.
2. Bảng node path cũ → mới (nếu có đổi) + script đã cập nhật.
3. Ảnh chụp ở 3 kích thước.
4. Mục nào chưa chắc / đang ẩn bằng `show_*`.
5. Việc chủ dự án cần làm (thay asset nào, trả lời câu hỏi §8 nào).
