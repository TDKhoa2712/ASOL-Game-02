extends RefCounted

# Region colors for boards N=4-6.
const ZONE_COLORS: Array[Color] = [
	Color("#E8A8C1"),
	Color("#A5C8E8"),
	Color("#B5D99C"),
	Color("#F5D680"),
	Color("#D4A5E8"),
	Color("#F5B89C"),
	Color("#8CC8C8"),
	Color("#E8C8A5"),
	Color("#C8E8A5"),
	Color("#E8A5A5"),
	Color("#A5E8D4"),
	Color("#C8A5E8"),
]

# UI colors.
const BG_CREAM := Color("#FFFDF5")
const BOARD_BG := Color("#F8F1EC")
const BG_PAPER := Color("#F5F0E8")
const SHADOW_SOFT := Color(0.545, 0.353, 0.290, 0.12)
const TEXT_STAT := Color("#9B5A52")
const TEXT_RULE := Color("#A0655C")
const PILL_BG := Color.WHITE
const PILL_RADIUS := 28
const CARD_CORNER := 24
const BOARD_CARD_CORNER := 32
const CARD_SHADOW := Color(0.545, 0.353, 0.290, 0.15)
const INK := Color("#344054")
const INK_LIGHT := Color("#667085")
const ACCENT_ORANGE := Color("#E8723C")
const ACCENT_BLUE := Color("#4A90D9")
const CORAL := Color("#F28B82")
const MINT := Color("#81C995")
const LILAC := Color("#B39DDB")
const DIVIDER := Color("#E0DDD4")

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
