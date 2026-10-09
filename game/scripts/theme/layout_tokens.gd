extends RefCounted

# Board.
const BOARD_PADDING := 16
const CELL_GAP_RATIO := 0.024
const CELL_CORNER_RATIO := 0.20
const CARD_CORNER_RATIO := 0.07
const CARD_GROW := 14.0
const BOARD_BORDER_WIDTH := 4.0
const BOARD_INNER_PAD_RATIO := 0.022
const CELL_DEPTH_RATIO := 0.065

# Typography.
const TITLE_SIZE := 32
const HEADING_SIZE := 24
const BODY_SIZE := 16
const CAPTION_SIZE := 12

# Spacing.
const GUTTER := 16
const STACK_GAP := 12
const SECTION_GAP := 24

# Animation.
const TRANSITION_MS := 200
const FADE_MS := 150
const AUTO_MARK_STAGGER_MS := 40
const LOCK_FADE_MS := 120

# Screen transition animations.
const RIBBON_DROP_MS := 800
const HEART_POP_MS := 600
const HEART_POP_STAGGER_MS := 250
const MASCOT_RISE_MS := 700
const CARD_RISE_MS := 700
const CARD_RISE_STAGGER_MS := 200
const CONFETTI_FALL_MIN_MS := 3200
const CONFETTI_FALL_MAX_MS := 6200
const RAYS_SPIN_MS := 22000
const BUTTON_PULSE_MS := 1400
const PROGRESS_FILL_MS := 1200
const LOGO_IN_MS := 900

# Gameplay.
const INITIAL_HEARTS := 3
const DOUBLE_TAP_MS := 350
const MAX_UNDO_DEPTH := 100

# Cell-internal sizing ratios (fraction of cell width).
const X_PADDING_RATIO := 0.28
const X_STROKE_RATIO := 0.09
const X_STROKE_RATIO_HC := 0.12
const X_MIN_STROKE := 4.0
const X_BOW_RATIO := 0.022
const CANDY_TEX_RATIO := 0.74
const MASCOT_TEX_RATIO := 1.15 # atlas frames carry transparent margins, so they may overhang the cell
const GIVEN_HALO_RATIO := 0.38
const OVERLAY_ICON_RATIO := 0.35
const SOLUTION_HINT_RATIO := 0.32
const ERROR_BADGE_OUTER_RATIO := 0.09
const ERROR_BADGE_INNER_RATIO := 0.07

# Heart icon size (px).
const HEART_SIZE := 48

# Adaptive scale for large boards: boost cell-internal elements so they stay
# readable on small physical cells.  Returns a multiplier >= 1.0.
static func cell_content_scale(board_size: int) -> float:
	if board_size <= 6:
		return 1.0
	return 1.0 + float(board_size - 6) * 0.06

# Accessibility state (set by app_shell from config at startup and on change).
static var motion_enabled: bool = true
static var large_text_enabled: bool = false

static func set_motion(on: bool) -> void:
	motion_enabled = on

static func set_large_text(on: bool) -> void:
	large_text_enabled = on

static func tile_font_size() -> int:
	return 26 if large_text_enabled else 22
