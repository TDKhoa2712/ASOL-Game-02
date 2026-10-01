# Module 5: Theme — Visual Tokens & Palette

> **Phụ thuộc:** Module 1 (Core) cho CellKind states
> **Tham khảo:** `gameplay/view/board_view.gd` (WARM_POOL, COOL_POOL, PALETTE_V13, V14), `gameplay/core/level_generator.gd` (12-color palette)

## Tổng quan

Module Theme định nghĩa design tokens: color palette, spacing, sizing. Reference có 4+ palette variants cho AB testing. Rebuild cần 1 palette duy nhất cho playtest.

**Cải tiến từ reference:**
- GIVEN cell state colors (halo + distinct candy tint)
- LOCKED cell state colors (dimmed overlay)
- Cell state color mapping cho tất cả 6 CellKind states

---

## File 1: `game/scripts/theme/palette.gd`

**Trách nhiệm:** Color constants — region colors, UI colors, state colors for all 6 CellKind.

```gdscript
# palette.gd
extends RefCounted

# --- Region colors (12 colors, pastel, cho board N=4-6) ---
const ZONE_COLORS: Array[Color] = [
    Color("#E8A8C1"),  # hồng nhạt
    Color("#A5C8E8"),  # xanh dương nhạt
    Color("#B5D99C"),  # xanh lá nhạt
    Color("#F5D680"),  # vàng nhạt
    Color("#D4A5E8"),  # tím nhạt
    Color("#F5B89C"),  # cam nhạt
    Color("#8CC8C8"),  # ngọc nhạt
    Color("#E8C8A5"),  # nâu nhạt
    Color("#C8E8A5"),  # xanh lime nhạt
    Color("#E8A5A5"),  # đỏ nhạt
    Color("#A5E8D4"),  # mint nhạt
    Color("#C8A5E8"),  # lavender nhạt
]

# --- UI colors ---
const BG_CREAM := Color("#FFFDF5")
const BG_PAPER := Color("#F5F0E8")
const INK := Color("#344054")
const INK_LIGHT := Color("#667085")
const ACCENT_ORANGE := Color("#E8723C")
const ACCENT_BLUE := Color("#4A90D9")
const CORAL := Color("#F28B82")
const MINT := Color("#81C995")
const LILAC := Color("#B39DDB")
const DIVIDER := Color("#E0DDD4")

# --- Cell state colors (mapped to CellKind enum) ---
# BLANK (0): no overlay, region color shows through
# MARK (1): white X mark
const MARK_WHITE := Color(1.0, 1.0, 1.0, 0.88)
const MARK_STROKE := Color("#344054")

# CANDY (2): player-placed candy
const CANDY_BROWN := Color("#A56643")
const CANDY_LIGHT := Color("#F7CFA8")

# WRONG (3): incorrect candy attempt
const ERROR_RED := Color("#E53935")
const ERROR_BG := Color("#FFEBEE")

# GIVEN (4): pre-placed candy from level data — distinct from player candy
const GIVEN_CANDY := Color("#7D4E2A")       # darker brown than player candy
const GIVEN_HALO := Color("#FFF7D6")        # soft gold halo around given cells
const GIVEN_BG_TINT := Color(1, 0.97, 0.88, 0.3)  # warm tint on region color

# LOCKED (5): auto-marked cells — visually subdued, non-interactive
const LOCKED_OVERLAY := Color(0.0, 0.0, 0.0, 0.08)  # subtle dim
const LOCKED_X_COLOR := Color("#B0B0B0")              # grey X mark
const LOCKED_X_ALPHA := 0.45                          # faded

# --- Button colors ---
const BTN_PRIMARY := Color("#E8723C")
const BTN_PRIMARY_HOVER := Color("#D4652F")
const BTN_DISABLED := Color("#D0D5DD")

# --- Utility ---

static func cell_state_overlay(kind: int) -> Color:
    match kind:
        3:  # WRONG
            return ERROR_BG
        4:  # GIVEN
            return GIVEN_BG_TINT
        5:  # LOCKED
            return LOCKED_OVERLAY
        _:
            return Color.TRANSPARENT
```

**Khác biệt với reference:**
- 1 palette thay 4+ AB variants (WARM_POOL, COOL_POOL, V13, V14)
- Tên: `ZONE_COLORS` thay `REGION_PALETTE` / `WARM_POOL_RGB`
- Color objects thay RGB int arrays
- Không split warm/cool — single pastel palette
- **Thêm:** GIVEN_CANDY, GIVEN_HALO, GIVEN_BG_TINT cho GIVEN state
- **Thêm:** LOCKED_OVERLAY, LOCKED_X_COLOR cho LOCKED state
- **Thêm:** `cell_state_overlay()` helper cho rendering

---

## File 2: `game/scripts/theme/layout_tokens.gd`

**Trách nhiệm:** Spacing, sizing, animation constants.

```gdscript
# layout_tokens.gd
extends RefCounted

# --- Board ---
const BOARD_PADDING := 16
const CELL_GAP_RATIO := 0.008  # gap = board_width * ratio
const CELL_CORNER_RATIO := 0.14
const CARD_CORNER_RATIO := 0.04
const CARD_GROW := 8.0

# --- Typography ---
const TITLE_SIZE := 32
const HEADING_SIZE := 24
const BODY_SIZE := 16
const CAPTION_SIZE := 12

# --- Spacing ---
const GUTTER := 16
const STACK_GAP := 12
const SECTION_GAP := 24

# --- Animation ---
const TRANSITION_MS := 200
const FADE_MS := 150
const AUTO_MARK_STAGGER_MS := 40   # stagger between auto-mark cell animations
const LOCK_FADE_MS := 120          # fade duration for LOCKED cells appearing

# --- Gameplay ---
const INITIAL_HEARTS := 3
const DOUBLE_TAP_MS := 350
const MAX_UNDO_DEPTH := 100
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/theme/`
- [ ] Viết `palette.gd` — including GIVEN/LOCKED state colors
- [ ] Viết `layout_tokens.gd` — including auto-mark animation timing
- [ ] Commit: `feat(theme): add visual design tokens and palette with GIVEN/LOCKED states`
