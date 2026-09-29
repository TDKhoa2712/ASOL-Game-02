class_name SettingsUIConfig
extends RefCounted

## =============================================================================
## CẤU HÌNH THÔNG SỐ GIAO DIỆN CÀI ĐẶT (SETTINGS UI CONFIG)
## Bạn có thể chỉnh sửa mọi màu sắc, kích thước, font chữ, độ bo góc tại file này.
## =============================================================================

# --- 1. BẢNG MÀU (COLOR PALETTE) ---
const PANEL_BG := Color(1.0, 0.992, 0.984, 0.98)        # #FFFDFB (nền card chính)
const PANEL_BORDER := Color(0.918, 0.855, 0.808, 1.0)     # #EADACE (viền card và viền tile)
const TILE_BG := Color(1.0, 0.965, 0.933, 1.0)           # #FFF6EE (nền các ô toggle)

const TEXT_TITLE := Color(0.427, 0.290, 0.271, 1.0)       # #6D4A45 (tiêu đề "CÀI ĐẶT")
const TEXT_SUB := Color(0.557, 0.439, 0.420, 1.0)         # #8E706B (phụ đề & nút X)
const TEXT_BODY := Color(0.427, 0.290, 0.271, 1.0)        # #6D4A45 (nhãn các cài đặt)

const SWITCH_ON := Color(0.365, 0.733, 0.455, 1.0)       # #5DBB74 (viên thuốc khi BẬT)
const SWITCH_OFF := Color(0.788, 0.722, 0.678, 1.0)      # #C9B8AD (viên thuốc khi TẮT)
const SWITCH_KNOB := Color.WHITE                          # Núm tròn công tắc

const ICON_ON := Color(0.427, 0.290, 0.271, 1.0)         # #6D4A45 (icon đậm khi BẬT)
const ICON_OFF := Color(0.725, 0.655, 0.612, 1.0)        # #B9A79C (icon mờ khi TẮT)

const BTN_PRIMARY_BG := Color(0.949, 0.584, 0.392, 1.0)  # #F29564 (nút cam "Quay lại" / "Chơi Lại")
const BTN_PRIMARY_PRESSED := Color(0.878, 0.514, 0.310, 1.0) # #E0834F (khi nhấn nút cam)
const BTN_OUTLINE_BORDER := Color(0.725, 0.478, 0.337, 1.0)  # #B97A56 (viền nút outline "Phản Hồi")

const DIMMER_COLOR := Color(0.357, 0.286, 0.267, 0.35)   # Lớp làm tối nền phía sau modal
const BADGE_RED := Color(0.898, 0.282, 0.302, 1.0)       # #E5484D (chấm đỏ thông báo)

# --- 2. KÍCH THƯỚC & BO GÓC (GEOMETRY & DIMENSIONS) ---
const CARD_CORNER_RADIUS := 40
const CARD_BORDER_WIDTH := 2
const CARD_PADDING_X := 24.0
const CARD_PADDING_Y := 24.0
const CARD_ANCHOR_LEFT := 0.06
const CARD_ANCHOR_RIGHT := 0.94

const TILE_CORNER_RADIUS := 20
const TILE_BORDER_WIDTH := 2
const TILE_PADDING_X := 8.0
const TILE_PADDING_Y := 12.0
const TILE_ROW_SEPARATION := 10

const ROW_WIDE_CORNER_RADIUS := 20
const ROW_WIDE_BORDER_WIDTH := 2
const ROW_WIDE_PADDING_X := 16.0
const ROW_WIDE_PADDING_Y := 10.0
const ROW_WIDE_MIN_HEIGHT := 64.0

const BTN_CORNER_RADIUS := 38
const BTN_PRIMARY_HEIGHT := 72.0
const BTN_OUTLINE_HEIGHT := 68.0

const ICON_SIZE := Vector2(40, 40)
const PILL_SIZE := Vector2(64, 30)
const PILL_TOUCH_SIZE := Vector2(72, 44)

# --- 3. CỠ CHỮ (FONT SIZES) ---
const FONT_SIZE_TITLE := 44
const FONT_SIZE_SUBTITLE := 20
const FONT_SIZE_TILE_LABEL := 15
const FONT_SIZE_ROW_LABEL := 20
const FONT_SIZE_BUTTON := 26
const FONT_SIZE_PILL := 12


## Tạo StyleBox cho card modal chính
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


## Tạo StyleBox cho 4 ô toggle vuông
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


## Tạo StyleBox cho hàng rộng (Độ tương phản cao)
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


## Tạo StyleBox cho nút chính (cam đặc)
static func make_button_primary_style(pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BTN_PRIMARY_PRESSED if pressed else BTN_PRIMARY_BG
	style.set_corner_radius_all(BTN_CORNER_RADIUS)
	if not pressed:
		style.shadow_color = Color(0.55, 0.31, 0.2, 0.18)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 6)
	return style


## Tạo StyleBox cho nút phụ (outline)
static func make_button_outline_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = BTN_OUTLINE_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(BTN_CORNER_RADIUS)
	return style
