class_name SettingsUIConfig
extends RefCounted

## =============================================================================
## BẢNG CẤU HÌNH THÔNG SỐ GIAO DIỆN CÀI ĐẶT (SETTINGS UI CONFIG)
## =============================================================================
## Tập trung toàn bộ thông số thiết kế cho màn hình Cài Đặt (Settings Screen)
## và các công tắc dạng viên thuốc (PillSwitch).
## Bạn có thể tùy biến màu sắc, kích thước, bo góc, khoảng cách đệm và cỡ chữ
## ngay tại file này mà không cần chỉnh sửa sâu trong code xử lý logic.
## =============================================================================


# ==============================================================================
# 1. BẢNG MÀU (COLOR PALETTE)
# ==============================================================================

## Màu nền của chiếc thẻ (card/modal) cài đặt chính.
## Giá trị: #FFFDFB (trắng kem ấm, độ trong suốt 0.98 để hơi lộ nền game mờ ảo).
const PANEL_BG := Color(1.0, 0.992, 0.984, 0.98)

## Màu đường viền bao quanh card chính và viền của các ô tính năng.
## Giá trị: #EADACE (màu be pastel thanh lịch, giúp tách bạch thẻ với nền mờ).
const PANEL_BORDER := Color(0.918, 0.855, 0.808, 1.0)

## Màu nền bên trong 4 ô vuông toggle (Âm thanh, Nhạc, Rung, Gợi ý) và hàng độ tương phản.
## Giá trị: #FFF6EE (cam sữa rất nhạt, tạo chiều sâu cho từng ô chức năng).
const TILE_BG := Color(1.0, 0.965, 0.933, 1.0)

## Màu chữ tiêu đề lớn "CÀI ĐẶT" ở trên cùng của modal.
## Giá trị: #6D4A45 (nâu sô-cô-la đậm, độ tương phản cao, dễ đọc).
const TEXT_TITLE := Color(0.427, 0.290, 0.271, 1.0)

## Màu chữ phụ và màu của icon nút đóng [X] ở góc phải trên.
## Giá trị: #8E706B (nâu hạt dẻ trung tính, nhẹ nhàng hơn tiêu đề chính).
const TEXT_SUB := Color(0.557, 0.439, 0.420, 1.0)

## Màu nhãn văn bản tên chức năng ("Âm thanh", "Nhạc nền", "Độ tương phản cao", v.v.).
## Giá trị: #6D4A45 (nâu đậm rõ nét).
const TEXT_BODY := Color(0.427, 0.290, 0.271, 1.0)

## Màu nền của công tắc dạng viên thuốc (PillSwitch) ở trạng thái BẬT (ON).
## Giá trị: #5DBB74 (xanh lá cây tươi sáng, biểu thị tính năng đang kích hoạt).
const SWITCH_ON := Color(0.365, 0.733, 0.455, 1.0)

## Màu nền của công tắc dạng viên thuốc (PillSwitch) ở trạng thái TẮT (OFF).
## Giá trị: #C9B8AD (xám be trung tính, biểu thị tính năng đã bị vô hiệu hóa).
const SWITCH_OFF := Color(0.788, 0.722, 0.678, 1.0)

## Màu sắc của núm tròn gạt công tắc (Knob).
## Giá trị: Trắng tinh khiết (Color.WHITE), tạo độ nổi bật trên nền xanh hoặc xám.
const SWITCH_KNOB := Color.WHITE

## Màu icon biểu tượng khi tính năng đang BẬT.
## Giá trị: #6D4A45 (nâu đậm rõ nét, đồng màu với nhãn).
const ICON_ON := Color(0.427, 0.290, 0.271, 1.0)

## Màu icon biểu tượng khi tính năng đang TẮT.
## Giá trị: #B9A79C (nâu xám mờ nhạt, tạo cảm giác biểu tượng chìm xuống).
const ICON_OFF := Color(0.725, 0.655, 0.612, 1.0)

## Màu nền nút chính dạng khối màu đặc (Nút cam "Quay lại" hoặc "Chơi Lại").
## Giá trị: #F29564 (cam san hô rực rỡ, là nút Call-To-Action chính).
const BTN_PRIMARY_BG := Color(0.949, 0.584, 0.392, 1.0)

## Màu nền nút chính khi người chơi nhấn giữ ngón tay vào (Pressed state).
## Giá trị: #E0834F (cam sẫm hơn, tạo phản hồi xúc giác thị giác bấm xuống).
const BTN_PRIMARY_PRESSED := Color(0.878, 0.514, 0.310, 1.0)

## Màu đường viền của nút phụ dạng rỗng (Nút "Phản Hồi" - Outline Button).
## Giá trị: #B97A56 (nâu đất ấm áp, đồng điệu với bảng màu chung).
const BTN_OUTLINE_BORDER := Color(0.725, 0.478, 0.337, 1.0)

## Màu lớp phủ che phủ toàn màn hình phía sau thẻ Cài Đặt (Modal Dimmer / Backdrop).
## Giá trị: Nâu tối mờ (độ mờ alpha 0.35), giúp làm tối màn hình game để nổi bật modal.
const DIMMER_COLOR := Color(0.357, 0.286, 0.267, 0.35)

## Màu chấm đỏ thông báo (Badge) trên các nút hoặc icon khi có thông báo mới.
## Giá trị: #E5484D (đỏ thông báo nổi bật).
const BADGE_RED := Color(0.898, 0.282, 0.302, 1.0)


# ==============================================================================
# 2. KÍCH THƯỚC, BO GÓC & KHOẢNG CÁCH (DIMENSIONS, RADIUS & PADDING)
# ==============================================================================

# --- Thẻ Card Cài Đặt Chính ---
## Độ cong bo tròn 4 góc của khung card chính (đơn vị: pixel). Số càng lớn góc càng tròn mịn.
const CARD_CORNER_RADIUS := 40

## Độ dày viền ngoài bao quanh card chính (đơn vị: pixel).
const CARD_BORDER_WIDTH := 2

## Khoảng đệm lề trái/phải bên trong card chính (padding ngang, pixel).
const CARD_PADDING_X := 24.0

## Khoảng đệm lề trên/dưới bên trong card chính (padding dọc, pixel).
const CARD_PADDING_Y := 24.0

## Tỷ lệ neo lề trái của card so với màn hình (0.06 = cách mép trái màn hình 6%).
const CARD_ANCHOR_LEFT := 0.06

## Tỷ lệ neo lề phải của card so với màn hình (0.94 = cách mép phải màn hình 6%).
const CARD_ANCHOR_RIGHT := 0.94

# --- 4 Ô Vuông Tính Năng (Sound, Music, Haptic, Hint Tiles) ---
## Độ bo tròn 4 góc của các ô vuông toggle (pixel).
const TILE_CORNER_RADIUS := 20

## Độ dày đường viền của các ô vuông toggle (pixel).
const TILE_BORDER_WIDTH := 2

## Đệm trong lề ngang của mỗi ô vuông toggle (pixel).
const TILE_PADDING_X := 8.0

## Đệm trong lề dọc của mỗi ô vuông toggle (pixel).
const TILE_PADDING_Y := 12.0

## Khoảng cách (separation) giữa các ô trong lưới/hàng (pixel).
const TILE_ROW_SEPARATION := 10

# --- Hàng Rộng (Ô "Độ Tương Phản Cao" - High Contrast Row) ---
## Độ bo góc của hàng dài nằm ngang (pixel).
const ROW_WIDE_CORNER_RADIUS := 20

## Độ dày đường viền của hàng dài (pixel).
const ROW_WIDE_BORDER_WIDTH := 2

## Đệm lề ngang bên trong hàng dài (pixel).
const ROW_WIDE_PADDING_X := 16.0

## Đệm lề dọc bên trong hàng dài (pixel).
const ROW_WIDE_PADDING_Y := 10.0

## Chiều cao tối thiểu của hàng dài (pixel), đảm bảo đủ không gian cho văn bản và công tắc.
const ROW_WIDE_MIN_HEIGHT := 64.0

# --- Các Nút Bấm Hành Động (Action Buttons) ---
## Độ bo cong góc của các nút bấm lớn ("Quay lại", "Chơi lại", "Phản Hồi").
## 38px tạo thành dạng viên thuốc tròn 2 đầu (Pill/Stadium button) với chiều cao ~72px.
const BTN_CORNER_RADIUS := 38

## Chiều cao của nút chính màu cam đặc (Primary Button, pixel).
const BTN_PRIMARY_HEIGHT := 72.0

## Chiều cao của nút viền rỗng (Outline Button, pixel).
const BTN_OUTLINE_HEIGHT := 68.0

# --- Icon & Công Tắc Viên Thuốc (Icons & Pill Switches) ---
## Kích thước khung icon bên trong các ô vuông tính năng (độ rộng x độ cao, pixel).
const ICON_SIZE := Vector2(40, 40)

## Kích thước hiển thị thị giác của công tắc viên thuốc (Rộng: 64px, Cao: 30px).
const PILL_SIZE := Vector2(64, 30)

## Kích thước vùng cảm ứng chạm ngón tay (Touch Target) của công tắc (Rộng: 72px, Cao: 44px).
## Theo chuẩn UI di động, vùng chạm tối thiểu ~44px giúp người chơi bấm cực nhạy và không bị trượt.
const PILL_TOUCH_SIZE := Vector2(72, 44)


# ==============================================================================
# 3. CỠ CHỮ VĂN BẢN (FONT SIZES)
# ==============================================================================

## Cỡ chữ tiêu đề "CÀI ĐẶT" (pixel).
const FONT_SIZE_TITLE := 44

## Cỡ chữ phụ đề phiên bản hoặc văn bản ghi chú nhỏ (pixel).
const FONT_SIZE_SUBTITLE := 20

## Cỡ chữ nhãn bên dưới icon trong các ô vuông ("Âm thanh", "Nhạc", "Rung", "Gợi ý").
const FONT_SIZE_TILE_LABEL := 15

## Cỡ chữ tên chức năng trong hàng dài ("Độ tương phản cao").
const FONT_SIZE_ROW_LABEL := 20

## Cỡ chữ in hoa trên các nút hành động lớn ("QUAY LẠI", "CHƠI LẠI", "PHẢN HỒI").
const FONT_SIZE_BUTTON := 26

## Cỡ chữ nhãn "BẬT" / "TẮT" (hoặc "ON" / "OFF") hiển thị trong lòng viên thuốc công tắc.
const FONT_SIZE_PILL := 12


# ==============================================================================
# 4. HÀM KHỞI TẠO STYLEBOX (STYLEBOX FACTORY METHODS)
# ==============================================================================

## Tạo StyleBoxFlat hoàn chỉnh cho khung Card Modal chính (kèm đổ bóng mềm).
static func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(CARD_BORDER_WIDTH)
	style.set_corner_radius_all(CARD_CORNER_RADIUS)
	style.shadow_color = Color(0.35, 0.22, 0.18, 0.18)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 12)
	style.content_margin_left = CARD_PADDING_X
	style.content_margin_right = CARD_PADDING_X
	style.content_margin_top = CARD_PADDING_Y
	style.content_margin_bottom = CARD_PADDING_Y
	return style


## Tạo StyleBoxFlat cho 4 ô vuông tính năng (Âm thanh, Nhạc, Rung, Gợi ý).
static func make_tile_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.set_corner_radius_all(TILE_CORNER_RADIUS)
	style.content_margin_left = TILE_PADDING_X
	style.content_margin_right = TILE_PADDING_X
	style.content_margin_top = TILE_PADDING_Y
	style.content_margin_bottom = TILE_PADDING_Y
	return style


## Tạo StyleBoxFlat cho hàng ngang rộng (Tùy chọn Độ tương phản cao).
static func make_row_wide_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(ROW_WIDE_BORDER_WIDTH)
	style.set_corner_radius_all(ROW_WIDE_CORNER_RADIUS)
	style.content_margin_left = ROW_WIDE_PADDING_X
	style.content_margin_right = ROW_WIDE_PADDING_X
	style.content_margin_top = ROW_WIDE_PADDING_Y
	style.content_margin_bottom = ROW_WIDE_PADDING_Y
	return style


## Tạo StyleBoxFlat cho nút bấm chính (khối cam đặc, có đổ bóng nổi bật).
## Tham số [param pressed]: true nếu đang ở trạng thái người chơi bấm giữ.
static func make_button_primary_style(pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BTN_PRIMARY_PRESSED if pressed else BTN_PRIMARY_BG
	style.set_corner_radius_all(BTN_CORNER_RADIUS)
	if not pressed:
		style.shadow_color = Color(0.55, 0.31, 0.2, 0.18)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 6)
	return style


## Tạo StyleBoxFlat cho nút bấm viền rỗng (Outline button).
static func make_button_outline_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = BTN_OUTLINE_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(BTN_CORNER_RADIUS)
	return style
