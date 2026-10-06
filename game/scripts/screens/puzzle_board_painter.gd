extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const OVERLAY_CHARS = ["", "★", "◆", "♥", "▲", "✕", "●"]

static func draw(board: Variant) -> void:
	if board._session == null:
		return
	var br: Rect2 = board._board_rect()
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Palette.PILL_BG; card_sb.set_corner_radius_all(int(br.size.x * LayoutTokens.CARD_CORNER_RATIO))
	board.draw_style_box(card_sb, br.grow(LayoutTokens.CARD_GROW))

	var count := int(board._session.level.get("size", 0))
	if count <= 0:
		return
	var gap: float = board._cell_gap(br.size.x)
	var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	var cr := int(cell_w * LayoutTokens.CELL_CORNER_RATIO)

	for r in range(count):
		for c in range(count):
			var cell_rect: Rect2 = board._cell_rect(r, c)
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
			var zone := str(board._zone_grid[r][c]) if board._zone_grid.size() > r and board._zone_grid[r].size() > c else ""
			var base_col: Color = board._zone_colors.get(zone, Palette.BG_CREAM)
			var sb := StyleBoxFlat.new()
			sb.bg_color = base_col; sb.set_corner_radius_all(cr)
			board.draw_style_box(sb, cell_rect)

			if board._high_contrast:
				board._draw_border(cell_rect, Palette.MARK_STROKE, 2, cr)
			var icon_val: int = board._zone_overlays.get(zone, 0)
			if icon_val > 0 and icon_val < OVERLAY_CHARS.size():
				var is_dark := base_col.get_luminance() < 0.5
				var tint := RegionPainter.overlay_tint(base_col, is_dark)
				var icon_size := int(cell_w * 0.35)
				board.draw_string(ThemeDB.fallback_font, cell_rect.position + Vector2(0.0, cell_rect.size.y * 0.65), OVERLAY_CHARS[icon_val], HORIZONTAL_ALIGNMENT_CENTER, cell_rect.size.x, icon_size, tint)

			var kind: int = board._session.board[r][c]
			if board._preview_cells.has([r, c]):
				if board._preview_mark and kind == CellModel.CellKind.BLANK:
					kind = CellModel.CellKind.MARK
				elif not board._preview_mark and kind == CellModel.CellKind.MARK:
					kind = CellModel.CellKind.BLANK
			var ov: Color = Palette.cell_state_overlay(kind)
			if ov.a > 0.0:
				var ov_sb := StyleBoxFlat.new()
				ov_sb.bg_color = ov; ov_sb.set_corner_radius_all(cr)
				board.draw_style_box(ov_sb, cell_rect)

			if kind != CellModel.CellKind.MARK and kind != CellModel.CellKind.ERROR and board._mark_anims.has(Vector2i(r, c)):
				var ck := Vector2i(r, c)
				board._mark_anims.erase(ck)
				if board._mark_tweens.has(ck) and is_instance_valid(board._mark_tweens[ck]): board._mark_tweens[ck].kill()
				board._mark_tweens.erase(ck)

			match kind:
				CellModel.CellKind.MARK: board._draw_cell_x(cell_rect, false, r, c)
				CellModel.CellKind.CANDY: board._draw_cell_candy(cell_rect, false)
				CellModel.CellKind.ERROR: board._draw_cell_x(cell_rect, true, r, c)
				CellModel.CellKind.GIVEN: board._draw_cell_candy(cell_rect, true)

			if board._highlight_cells.has([r, c]):
				var pulse_alpha: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(board._highlight_pulse_phase))
				board._draw_border(cell_rect, Color(Palette.ACCENT_ORANGE, pulse_alpha), 3, cr)

	board.draw_set_transform(Vector2.ZERO)
