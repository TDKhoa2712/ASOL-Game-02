extends RefCounted

# Region colors for boards N=4-6.
const ZONE_COLORS: Array[Color] = [
	Color("#91D984"),
	Color("#9586D9"),
	Color("#E0BD43"),
	Color("#F6DA98"),
	Color("#EFACDD"),
	Color("#D884A0"),
	Color("#F4AA71"),
	Color("#BA8665"),
	Color("#469B68"),
	Color("#64B8CB"),
	Color("#A5E8D4"),
	Color("#C8A5E8"),
]

# UI colors.
const BG_CREAM := Color("#FFFDF5")
const BOARD_BG := Color("#F8F1EC")
const BG_PAPER := Color("#F5F0E8")
const SHADOW_SOFT := Color(0.545, 0.353, 0.290, 0.18)
const TEXT_STAT := Color("#9B5A52")
const TEXT_RULE := Color("#A0655C")
const PILL_BG := Color.WHITE
const PILL_RADIUS := 28
const CARD_CORNER := 24
const BOARD_CARD_CORNER := 32
const CARD_SHADOW := Color(0.545, 0.353, 0.290, 0.15)
const INK := Color("#6D4A45")
const INK_LIGHT := Color("#667085")
const ACCENT_ORANGE := Color("#E8723C")
const ACCENT_BLUE := Color("#4A90D9")
const CORAL := Color("#F28B82")
const MINT := Color("#81C995")
const LILAC := Color("#B39DDB")
const DIVIDER := Color("#E0DDD4")
const SURFACE_WARM := Color("#FFFBF7")
const SURFACE_TILE := Color("#FFF6EE")
const SURFACE_HOVER := Color("#FFFDFB")
const SURFACE_PRESSED := Color("#F4EEE9")
const SURFACE_DISABLED := Color("#F0EBE6")
const SCRIM := Color(0, 0, 0, 0.35)
const TEXT_ON_ACCENT := Color.WHITE
const ICON_OFF := Color("#B0A8A0")
const ICON_MUTED := Color(1, 1, 1, 0.25)
const PLAY_BUTTON := Color("#F09329")
const PLAY_GLOW := Color(0.94, 0.58, 0.16, 0.35)
const RESULT_WIN_BG := Color("#E2F1E8")
const RESULT_FAIL_BG := Color("#FCECE2")
const RESULT_WIN_BUTTON := Color("#55A683")
const RESULT_FAIL_BUTTON := Color("#F49359")

# Redesigned screen colors (from mockups).
# Win screen — warm golden.
const WIN_BG_CENTER := Color("#FFFFFF")
const WIN_BG_MID := Color("#FFF8DC")
const WIN_BG_EDGE := Color("#FFE08A")
const WIN_RIBBON_BG := Color("#FF9533")
const WIN_RIBBON_SHADOW := Color("#E0731A")
const WIN_RIBBON_FOLD := Color("#8F3D05")
const WIN_RIBBON_TAIL := Color("#E8731C")
const WIN_RIBBON_TEXT_SHADOW := Color("#A9480A")
const WIN_CARD_SHADOW := Color("#EFD27E")
const WIN_BUTTON_BG := Color("#1F9A4B")
const WIN_BUTTON_SHADOW := Color("#136F35")
const WIN_BUTTON_TEXT_SHADOW := Color("#0F5A2B")
const WIN_RAYS := Color(1.0, 0.745, 0.235, 0.22)
const WIN_STAT_ICON_BG_TIME := Color("#E3F3FF")
const WIN_STAT_ICON_BG_ERR := Color("#FFECE4")
const WIN_STAT_ICON_SHADOW_TIME := Color("#B9DDF7")
const WIN_STAT_ICON_SHADOW_ERR := Color("#F6CDBD")
const WIN_TEXT_SECONDARY := Color("#4F5D86")
const WIN_TEXT_PRIMARY := Color("#23365E")
const WIN_NEXT_BOARD_BG := Color("#FFF1DE")
const WIN_NEXT_BOARD_SHADOW := Color("#EBCFA5")
const WIN_NEXT_CELL := Color("#FBE4C4")
const WIN_DASHED_BORDER := Color("#F3E3B5")
const WIN_DIFFICULTY_EASY := Color("#22894C")
const WIN_DIFFICULTY_MEDIUM := Color("#B05F0A")
const WIN_DIFFICULTY_HARD := Color("#C02C52")
const WIN_DIFFICULTY_EXPERT := Color("#6A2CC0")

# Lose screen — purple/lavender.
const LOSE_BG_CENTER := Color("#FFFFFF")
const LOSE_BG_MID := Color("#F1ECFA")
const LOSE_BG_EDGE := Color("#D3C6EC")
const LOSE_RIBBON_BG := Color("#7466D1")
const LOSE_RIBBON_SHADOW := Color("#5A4BB5")
const LOSE_RIBBON_FOLD := Color("#2E2470")
const LOSE_RIBBON_TAIL := Color("#5546A8")
const LOSE_RIBBON_TEXT_SHADOW := Color("#3B2E8A")
const LOSE_CARD_SHADOW := Color("#CFC2EA")
const LOSE_BUTTON_BG := Color("#D9620F")
const LOSE_BUTTON_SHADOW := Color("#9A3A08")
const LOSE_BUTTON_TEXT_SHADOW := Color("#8A3306")
const LOSE_TEXT_PRIMARY := Color("#3E2D63")
const LOSE_TEXT_SECONDARY := Color("#5E4C86")
const LOSE_HEART_FILL := Color("#E4DCF0")
const LOSE_HEART_STROKE := Color("#8A7AA8")
const LOSE_HEART_BACK := Color("#BBAED3")
const LOSE_HEART_CRACK := Color("#736292")
const LOSE_CLOUD := Color("#A79BC4")
const LOSE_CLOUD_SHADOW := Color("#8D80AE")
const LOSE_RAIN := Color("#8FB8E0")
const LOSE_TEAR := Color("#6FB8F0")
const LOSE_MASCOT_BODY := Color("#E7B3CA")
const LOSE_MASCOT_BODY_DARK := Color("#B57A98")

# Home screen accent colors.
const HOME_BG_CENTER := Color("#FFFFFF")
const HOME_BG_MID := Color("#FFF8DC")
const HOME_BG_EDGE := Color("#FFE08A")
const HOME_BUTTON_BG := Color("#D9620F")
const HOME_BUTTON_SHADOW := Color("#9A3A08")
const HOME_CARD_SHADOW := Color("#EFD27E")
const HOME_PROGRESS_BG := Color("#FFF1D0")
const HOME_PROGRESS_BG_SHADOW := Color("#F3DFA8")
const HOME_PROGRESS_FILL := Color("#3FB487")
const HOME_PROGRESS_FILL_DARK := Color("#2A8C64")
const HOME_SPEECH_BG := Color.WHITE
const HOME_ICON_BG := Color.WHITE
const HOME_ICON_SHADOW := Color("#E2C46A")
const HOME_TOP_BTN_BG := Color("#3D8BEB")
const HOME_TOP_BTN_SHADOW := Color("#2463B0")

# Shared accent colors for candy decorations.
const CANDY_ORANGE := Color("#FF8A3D")
const CANDY_BLUE := Color("#6FC3FF")
const CANDY_YELLOW := Color("#FFC93C")
const CANDY_GREEN := Color("#7AE0A0")
const CANDY_RED := Color("#FF5A4E")
const CANDY_PURPLE := Color("#B98AF0")
const CONFETTI_COLORS: Array[Color] = [
	Color("#FFC93C"), Color("#FF5A4E"), Color("#4FC3E8"),
	Color("#7AD98A"), Color("#FF9F43"), Color("#B69CFF"),
]

# Heart colors.
const HEART_FILLED := Color("#F5414F")
const HEART_FILLED_DARK := Color("#C9212F")
const HEART_FILLED_STROKE := Color("#7A1018")
const HEART_FILLED_SHINE := Color("#FFD3D6")
const HEART_EMPTY := Color("#F1ECE0")
const HEART_EMPTY_DARK := Color("#D9D2C2")
const HEART_EMPTY_STROKE := Color("#A89E88")

# Twinkle star color.
const TWINKLE_GOLD := Color("#FFC93C")
const TWINKLE_BLUE := Color("#7CC8FF")
const RULE_EMPTY := Color("#E0BFAA")
const CANDY_OUTLINE := Color("#7F4A2F")

# Cell state colors: BLANK (0) shows the region color; MARK (1) uses a white X.
const MARK_WHITE := Color(1.0, 1.0, 1.0, 0.88)
const MARK_STROKE := Color("#344054")

# CANDY (2): player-placed candy.
const CANDY_BROWN := Color("#A56643")
const CANDY_LIGHT := Color("#F7CFA8")

# ERROR (3): incorrect candy attempt.
const ERROR_RED := Color("#E53935")
const ERROR_BG := Color("#FFEBEE")

# GIVEN (4): pre-placed candy from level data.
const GIVEN_CANDY := Color("#7D4E2A")
const GIVEN_HALO := Color("#FFF7D6")
const GIVEN_BG_TINT := Color(1.0, 0.97, 0.88, 0.3)

# Button colors.
const BTN_PRIMARY := Color("#E8723C")
const BTN_PRIMARY_HOVER := Color("#D4652F")
const BTN_DISABLED := Color("#D0D5DD")

static func cell_state_overlay(kind: int) -> Color:
	match kind:
		3: # ERROR
			return ERROR_BG
		4: # GIVEN
			return GIVEN_BG_TINT
		_:
			return Color.TRANSPARENT
