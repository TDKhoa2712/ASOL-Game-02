# SPEC: Restyle màn hình Cài Đặt (`settings.tscn`)

> Dành cho AI agent chỉnh sửa Godot 4 scene. Đọc hết file này trước khi sửa.
> **Không cần giống reference 100%.** Mục tiêu là *cùng bố cục, cùng cảm giác*: popup gọn, toggle dạng ô icon + pill ON/OFF, nút cam bo tròn. Assets (icon, font) sẽ được chủ dự án thay sau, nên mọi thứ phải dễ thay.

---

## 0. Tài liệu tham chiếu

| Tên | Vai trò |
|---|---|
| Image 1 (reference) | Popup "Cài Đặt": tiêu đề + nút X, hàng 4 ô toggle vuông (icon + pill ON/OFF), 1 hàng toggle rộng, nút outline, nút cam |
| Image 2 (hiện tại) | Màn hình đang lỗi bố cục (xem mục 1) |
| `settings.tscn` | Scene hiện tại cần sửa |

---

## 1. Chẩn đoán scene hiện tại (đây là lý do nhìn "xấu")

Những lỗi này nằm trong `settings.tscn`, sửa chúng là bước đầu tiên:

1. **Nội dung bị dồn sang phải**: mỗi hàng toggle là `HBoxContainer` có `alignment = 2` (END) và Label có `custom_minimum_size = (300, 48)` nhưng `size_flags_horizontal = 1` (chỉ FILL, không EXPAND). Kết quả: label + switch dính nhau và bị đẩy về bên phải.
   → Label phải dùng `size_flags_horizontal = 3` (FILL + EXPAND), bỏ `alignment = 2`, bỏ min width 300.
2. **Khoảng trống lớn giữa card**: node `Spacer` có `size_flags_vertical = 2` (EXPAND) và card cao cố định 60% màn hình (`anchor_top 0.2` → `anchor_bottom 0.8`).
   → Card phải **co theo nội dung**, bỏ `Spacer`.
3. **Trùng node**: `SafeArea/ModalCard` và `SafeArea/Content` đều là `PanelContainer` cùng anchor, cùng `StylePanel` → viền/bóng bị vẽ 2 lần. `ModalCard` không chứa gì.
   → **Xoá `ModalCard`**, giữ `Content`.
4. **Switch quá nhỏ, không rõ ON/OFF**: `CheckButton` chỉ đổi màu nền, icon check mặc định của theme rất nhỏ.
   → Thay bằng **PillSwitch** (mục 5).
5. **Màu chữ label và đường kẻ bị lạc tông**: label `#344054` và separator `#D0D5DF` là xám xanh lạnh, trong khi cả game là tông kem/nâu/cam ấm.
   → Đổi sang bảng màu ở mục 3.
6. Nút X đóng popup không tồn tại.

---

## 2. RÀNG BUỘC BẮT BUỘC (không được phá)

Chưa có file script của màn hình này trong tài liệu, nên agent phải **tự tìm** (`grep -r "settings" res://scripts` hoặc script gắn trên node root `Settings`) trước khi sửa.

- Giữ nguyên **tên và đường dẫn** các node sau vì script có thể tham chiếu chúng:
  - `SafeArea/Content/Stack/AudioToggle/AudioSwitch`
  - `SafeArea/Content/Stack/HapticsToggle/HapticsSwitch`
  - `SafeArea/Content/Stack/ReducedMotionToggle/ReducedMotionSwitch`
  - `SafeArea/Content/Stack/HighContrastToggle/HighContrastSwitch`
  - `SafeArea/Content/Stack/LargeTextToggle/LargeTextSwitch`
  - `SafeArea/Content/Stack/BackButton`
- Nếu cần đổi cấu trúc (ví dụ chuyển switch vào trong tile), **hãy cập nhật mọi đường dẫn** `$...`, `get_node(...)`, `%UniqueName` trong script và không để lỗi "Node not found".
  - Cách an toàn nhất: đặt các switch làm **Unique Name** (`%AudioSwitch`, ...) rồi sửa script dùng `%`, sau đó mới di chuyển node.
- Giữ `metadata/screen_id = "settings"`, node `Backdrop` (script `pastel_backdrop.gd`, `variant = "settings"`) và `Dimmer`.
- Giữ tooltip hiện có (ví dụ "kết nối tại R3" là ghi chú cho giai đoạn nối logic sau, đừng xoá).
- Giữ nguyên logic bật/tắt hiện tại: tín hiệu `toggled` và thuộc tính `button_pressed` phải hoạt động như cũ.
- Nếu đổi kiểu node `CheckButton` → `Button` (toggle) thì kiểm tra script có khai báo kiểu tĩnh `CheckButton` hay không (`@onready var x: CheckButton`) và đổi thành `Button`.
- Viewport là màn hình dọc (mobile). Mọi thứ phải dùng anchor/container, **không** hard-code vị trí pixel tuyệt đối.
- Không hard-code chuỗi màu rải rác; gom vào StyleBox/Theme hoặc một file `ui_theme_settings.gd`/`.tres` để chủ dự án dễ chỉnh.

---

## 3. Bảng màu và thông số (lấy từ scene hiện tại, đổi sang hex cho dễ đọc)

| Token | Hex | Dùng cho | Ghi chú |
|---|---|---|---|
| `panel_bg` | `#FFFDFB` (alpha 0.98) | Nền card | giữ nguyên |
| `panel_border` | `#EADACE` | Viền card, viền tile, đường kẻ | giữ nguyên |
| `tile_bg` | `#FFF6EE` | Nền ô toggle | mới, ấm hơn panel một chút |
| `text_title` | `#6D4A45` | Tiêu đề | giữ nguyên |
| `text_body` | `#6D4A45` | Label toggle | **đổi** từ `#344054` |
| `text_sub` | `#8E706B` | Subtitle, caption phụ | giữ nguyên |
| `switch_on` | `#5DBB74` | Pill ON | đậm hơn `#8FD49A` cũ để chữ trắng đọc được |
| `switch_off` | `#C9B8AD` | Pill OFF | be-nâu ấm |
| `icon_on` | `#6D4A45` | Icon khi ON | |
| `icon_off` | `#B9A79C` | Icon khi OFF | mờ hơn |
| `accent` | `#F29564` | Nút chính "Quay lại" | giữ nguyên |
| `accent_outline` | `#B97A56` | Viền + chữ nút phụ | mới |
| `dimmer` | `#5B4944` alpha `0.35` | Nền mờ phía sau | tăng từ 0.22 để giống modal |
| `badge_red` | `#E5484D` | Chấm đỏ thông báo (tuỳ chọn) | |

Bo góc: card `40`, tile `20`, hàng rộng `20`, nút `999` (pill hoàn toàn) hoặc `38` nếu nút cao 76.

---

## 4. Bố cục mục tiêu

```
┌──────────────────────────────────┐
│           CÀI ĐẶT             ✕  │   ← TitleBar (X góc phải)
│      Tùy chỉnh trải nghiệm chơi  │   ← Subtitle (giữ, nhỏ)
│                                  │
│ ┌──────┐┌──────┐┌──────┐┌──────┐ │
│ │ 🔊   ││ 📳   ││ 🌀   ││ Aa   │ │   ← 4 TILE bằng nhau
│ │Âm    ││Rung  ││Giảm  ││Chữ to│ │     icon + caption
│ │thanh ││      ││chuyển││(+30%)│ │
│ │[ON ●]││[● OFF││động  ││[● OFF│ │     pill ON/OFF
│ └──────┘└──────┘└──────┘└──────┘ │
│ ┌──────────────────────────────┐ │
│ │ Độ tương phản cao / Grayscale│ │   ← Hàng rộng (giống "Chế độ họa tiết")
│ │                     [● OFF ] │ │
│ └──────────────────────────────┘ │
│                                  │
│   (Phản Hồi)  ← tuỳ chọn, ẩn     │
│   (Chơi Lại)  ← tuỳ chọn, ẩn     │
│  ╭────────────────────────────╮  │
│  │         Quay lại           │  │   ← Nút cam chính
│  ╰────────────────────────────╯  │
└──────────────────────────────────┘
```

### 4.1 Ánh xạ reference → game của chúng ta

Reference có 4 ô icon (nhạc, âm thanh, giọng nói, rung) và 1 hàng "Chế độ họa tiết". Game của mình chỉ có **5 cài đặt sẵn có**, không thêm cài đặt mới chưa có logic:

| Vị trí reference | Cài đặt của mình | Node giữ tên |
|---|---|---|
| Ô 1 (nhạc/loa) | Âm thanh | `AudioSwitch` |
| Ô 2 | Rung (haptic) | `HapticsSwitch` |
| Ô 3 | Giảm chuyển động | `ReducedMotionSwitch` |
| Ô 4 | Chữ to (+30%) | `LargeTextSwitch` |
| Hàng rộng "Chế độ họa tiết" | Độ tương phản cao / Grayscale | `HighContrastSwitch` |

Lý do: "Chế độ họa tiết" của reference cũng là tuỳ chọn trợ năng thị giác, nên "Độ tương phản cao" là tương đương gần nhất.

Vì "Giảm chuyển động" và "Chữ to" khó diễn đạt chỉ bằng icon, **mỗi ô có thêm caption chữ nhỏ** bên dưới icon (reference không có, đây là điều chỉnh có chủ đích).

### 4.2 Cấu trúc node đề xuất

```
Settings (Control)                       ← giữ
├─ Backdrop (pastel_backdrop.gd)         ← giữ
├─ Dimmer (ColorRect)                    ← đổi alpha 0.35
└─ SafeArea (Control)
   └─ Content (PanelContainer)           ← card; xoá ModalCard trùng
      └─ Stack (VBoxContainer, sep 16)
         ├─ TitleBar (Control, min height 64)          ← MỚI
         │  ├─ Title (Label, căn giữa, full rect)      ← chuyển vào đây
         │  └─ CloseButton (Button, góc trên phải)     ← MỚI
         ├─ Subtitle (Label)
         ├─ TileRow (HBoxContainer, sep 10)            ← MỚI
         │  ├─ AudioToggle (PanelContainer, size_flags_h = 3)
         │  │  └─ VBox (icon, caption, AudioSwitch)
         │  ├─ HapticsToggle        (tương tự)
         │  ├─ ReducedMotionToggle  (tương tự)
         │  └─ LargeTextToggle      (tương tự)
         ├─ HighContrastToggle (PanelContainer)        ← hàng rộng
         │  └─ HBox
         │     ├─ HighContrastLabel  (size_flags_h = 3)
         │     └─ HighContrastSwitch
         ├─ ButtonStack (VBoxContainer, sep 12)        ← MỚI
         │  ├─ FeedbackButton  (visible = false)       ← tuỳ chọn, mục 6
         │  ├─ RestartButton   (visible = false)       ← tuỳ chọn, mục 6
         │  └─ BackButton                              ← chuyển vào đây
```

Ghi chú:
- Xoá `Separator1`, `Separator2`, `Spacer` (không còn dùng trong bố cục ô).
- Node `*Toggle` đổi từ `HBoxContainer` sang `PanelContainer`; **tên giữ nguyên**, còn `*Label` cũ của 4 ô đổi vai trò thành caption.
- Khi di chuyển node, làm theo mục 2 để không vỡ đường dẫn trong script.

### 4.3 Card (`Content`)

- Anchor ngang: `anchor_left = 0.06`, `anchor_right = 0.94`.
- Anchor dọc: `anchor_top = 0.5`, `anchor_bottom = 0.5`, `grow_vertical = 2` (BOTH) → card **tự co theo nội dung và nằm giữa màn hình**. Không đặt chiều cao cố định.
- `StylePanel`: giữ nền/viền/bóng hiện tại; `corner_radius = 40`; `content_margin = 24`.
- Đảm bảo `SafeArea` tôn trọng vùng an toàn của thiết bị (notch). Nếu chưa có script, chấp nhận như hiện tại.

### 4.4 Ô toggle (`AudioToggle`, ...)

- `PanelContainer` với StyleBoxFlat: `bg = tile_bg`, viền 2px `panel_border`, `corner_radius = 20`, `content_margin = 10`.
- `size_flags_horizontal = 3` để 4 ô chia đều chiều ngang.
- Bên trong `VBoxContainer` (`separation = 6`, căn giữa):
  1. **Icon** `TextureRect` (`custom_minimum_size = 40x40`, `expand_mode = fit`, `stretch_mode = keep_aspect_centered`); tint bằng `modulate` = `icon_on` khi ON, `icon_off` khi OFF.
  2. **Caption** `Label` (font size 15, màu `text_body`, `horizontal_alignment = center`, `autowrap_mode = word smart`, `custom_minimum_size.y` đủ 2 dòng, khoảng 40) để chữ dài như "Giảm chuyển động" xuống dòng mà không làm lệch chiều cao 4 ô.
  3. **Switch** (PillSwitch) căn giữa.
- Trạng thái OFF: icon mờ (`icon_off`). Có thể vẽ thêm gạch chéo lên icon (giống icon rung bị gạch trong reference) nhưng **không bắt buộc**.

### 4.5 Hàng rộng (`HighContrastToggle`)

- Cùng StyleBox với ô toggle, chiều cao tối thiểu khoảng 64.
- `HBoxContainer`: label bên trái (`size_flags_horizontal = 3`, font 22, màu `text_body`, `autowrap word smart`), PillSwitch bên phải, căn giữa dọc.
- Text giữ nguyên: "Độ tương phản cao / Grayscale".

### 4.6 Tiêu đề và nút X

- `Title`: giữ text "CÀI ĐẶT", font 44 đến 48, màu `text_title`, căn giữa ngang và dọc trong `TitleBar`.
- `CloseButton`: `Button` phẳng (`flat = true`), min size `56x56` (vùng chạm tối thiểu 44), neo góc trên phải của `TitleBar`. Icon `res://assets/ui/icons/icon_close.svg` tint `text_sub`; nếu chưa có icon thì tạm dùng text `"X"`.
- **Hành vi**: kết nối `CloseButton.pressed` tới **đúng handler mà `BackButton.pressed` đang dùng** (tìm trong script). Không viết logic đóng màn hình mới.

### 4.7 Nút chính `BackButton`

- Giữ text "Quay lại". Giữ `custom_minimum_size` cao 76, **rộng full** (`size_flags_horizontal = 3`, bỏ min width 240 nếu nó làm nút không full).
- `StyleBack`: `bg = accent`, `corner_radius = 38`, bóng như hiện tại. Font 25 đến 28, màu chữ trắng.
- Thêm style `pressed` hơi tối hơn (`#E0834F`) và `hover` giữ như normal.

---

## 5. PillSwitch (thay `CheckButton`)

Mục tiêu: công tắc dạng viên thuốc có chữ **ON/OFF** và núm tròn trượt, giống reference, **không phụ thuộc asset** (vẽ bằng code nên không vỡ khi thay art).

- Tạo `res://scripts/ui/pill_switch.gd` và gắn vào 5 node `*Switch`, đổi kiểu node thành `Button` (toggle) như mô tả ở mục 2.
- Kích thước vẽ 64x30; vùng chạm 72x44 (đủ ngón tay).
- Khi ON: nền `switch_on`, núm bên phải, chữ "ON" bên trái. Khi OFF: nền `switch_off`, núm bên trái, chữ "OFF" bên phải. Núm trượt bằng tween 0.15s.

Gợi ý triển khai (agent được phép chỉnh, miễn giữ hành vi):

```gdscript
class_name PillSwitch
extends Button

@export var on_color := Color("5DBB74")
@export var off_color := Color("C9B8AD")
@export var knob_color := Color.WHITE
@export var pill_size := Vector2(64, 30)
@export var on_text := "ON"
@export var off_text := "OFF"
@export var font_size_px := 12

var _t := 0.0 # 0 = OFF, 1 = ON

func _init() -> void:
	toggle_mode = true
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE

func _ready() -> void:
	custom_minimum_size = pill_size + Vector2(8, 14)
	_t = 1.0 if button_pressed else 0.0
	toggled.connect(_on_toggled)
	queue_redraw()

func _on_toggled(on: bool) -> void:
	var tw := create_tween()
	tw.tween_method(_set_t, _t, 1.0 if on else 0.0, 0.15)

func _set_t(v: float) -> void:
	_t = v
	queue_redraw()

func _draw() -> void:
	var r := Rect2((size - pill_size) * 0.5, pill_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = off_color.lerp(on_color, _t)
	sb.set_corner_radius_all(int(pill_size.y * 0.5))
	draw_style_box(sb, r)

	var pad := 3.0
	var d := pill_size.y - pad * 2.0
	var kx := lerpf(r.position.x + pad, r.end.x - pad - d, _t)
	draw_circle(Vector2(kx + d * 0.5, r.position.y + pill_size.y * 0.5), d * 0.5, knob_color)

	var font := get_theme_default_font()
	var txt := on_text if button_pressed else off_text
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_px)
	var tx := (r.position.x + 9.0) if button_pressed else (r.end.x - 9.0 - ts.x)
	var baseline := r.position.y + pill_size.y * 0.5 \
		+ (font.get_ascent(font_size_px) - font.get_descent(font_size_px)) * 0.5
	draw_string(font, Vector2(tx, baseline), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_px, Color.WHITE)
```

Nếu `ReducedMotionSwitch` đang ON, tween nên bị bỏ qua (gán `_t` thẳng); chỉ làm nếu script có sẵn cách đọc cài đặt này, không thêm state mới.

Thay thế nếu chủ dự án muốn dùng art riêng: hai texture (`switch_on.png`, `switch_off.png`) đặt trong `res://assets/ui/`, `PillSwitch` chỉ đổi texture theo `button_pressed`. Để làm sau.

---

## 6. Thành phần tuỳ chọn (tạo sẵn nhưng ẩn, `visible = false`)

Reference có 2 nút mà màn hình hiện tại chưa có logic. **Chỉ tạo node, không nối logic**, để chủ dự án bật khi cần:

- `FeedbackButton` ("Phản Hồi"): nút **outline**: nền trong suốt, viền 3px `accent_outline`, chữ `accent_outline`, bo pill, cao 68, full width.
- `RestartButton` ("Chơi Lại"): giống style `BackButton` (cam đặc). Chỉ có ý nghĩa nếu màn hình Cài Đặt được mở từ trong ván chơi; khi đó nút này gọi hành vi restart mà game đã có. **Không tự chế logic restart.**
- `NewBadge` (tuỳ chọn): chấm đỏ 12x12 (`badge_red`) ở góc trên phải của `HighContrastToggle`, ẩn mặc định, dùng để báo có tuỳ chọn mới như trong reference.

---

## 7. Asset cần dùng (đặt trong `res://assets/ui/icons/`)

Nếu chưa có, agent tạo icon **SVG đơn giản** làm placeholder (Godot import SVG được). Chủ dự án sẽ thay bằng art riêng, nên **đừng nhúng icon vào script hay dùng emoji** (font mobile thường thiếu glyph):

| File | Dùng cho |
|---|---|
| `icon_sound.svg` | Âm thanh |
| `icon_haptic.svg` | Rung |
| `icon_motion.svg` | Giảm chuyển động |
| `icon_text_size.svg` | Chữ to ("Aa") |
| `icon_close.svg` | Nút X |

Icon nên là hình đơn sắc (trắng hoặc đen) để tint được bằng `modulate`. Mỗi `TextureRect` icon nên gán texture qua thuộc tính, dễ thay trong Inspector.

---

## 8. Việc KHÔNG làm

- Không thêm cài đặt mới (nhạc nền riêng, giọng nói, ...) khi chưa có logic.
- Không đổi tên node hoặc `screen_id`, không đổi tên chuỗi tiếng Việt hiện có (trừ khi spec nêu rõ).
- Không xoá `Backdrop`/`Dimmer`.
- Không hard-code kích thước theo pixel màn hình cụ thể.
- Không tự thêm logic lưu/đọc cài đặt; phần đó là "kết nối tại R3".

---

## 9. Checklist nghiệm thu

- [ ] Card nằm giữa màn hình, **không còn khoảng trống lớn**, cao vừa nội dung.
- [ ] Không còn node `ModalCard`; không còn viền/bóng đôi.
- [ ] 4 ô toggle **bằng nhau, trải đều** chiều ngang; caption "Giảm chuyển động" xuống dòng mà chiều cao 4 ô vẫn bằng nhau.
- [ ] Hàng "Độ tương phản cao / Grayscale" rộng full, label trái, switch phải.
- [ ] Mỗi switch nhìn rõ ON (xanh + chữ ON, núm phải) và OFF (be + chữ OFF, núm trái); bấm được ở mọi trạng thái.
- [ ] Nút X hoạt động giống hệt "Quay lại".
- [ ] Không còn màu xám xanh lạnh (`#344054`, `#D0D5DF`).
- [ ] Chạy scene: không có lỗi "Node not found" / "Invalid access" trong Output.
- [ ] Bật/tắt từng switch phát đúng tín hiệu `toggled` như trước khi sửa.
- [ ] Thử trên viewport dọc nhỏ (khoảng 360x640) và lớn (khoảng 540x960), không bị tràn hay cắt chữ.
- [ ] Icon, font, màu đều thay được từ Inspector/StyleBox mà không sửa code.

---

## 10. Thứ tự làm việc đề xuất

1. Đọc script gắn trên `Settings` và tìm mọi chỗ tham chiếu tới các node ở mục 2.
2. Sửa các lỗi ở mục 1 (bố cục dồn phải, `Spacer`, `ModalCard`, màu lạnh).
3. Tạo `PillSwitch` và thay 5 switch.
4. Dựng `TileRow` và hàng rộng theo mục 4.
5. Thêm `TitleBar` + `CloseButton`.
6. Tạo các node tuỳ chọn ẩn (mục 6) và placeholder icon (mục 7).
7. Chạy và đối chiếu checklist mục 9; báo lại các chỗ đã lệch spec và lý do.
