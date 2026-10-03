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
