extends RefCounted

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
const OVERLAY_CHARS = ["", "★", "◆", "♥", "▲", "✕", "●"]

static var _cell_bg_tex: Texture2D = null
static var _border_tex: Texture2D = null
static var _card_sb: StyleBoxFlat = null
static var _card_cr: int = -1

static func get_cell_bg_tex() -> Texture2D:
	if _cell_bg_tex != null:
		return _cell_bg_tex
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect x="0" y="0" width="128" height="128" rx="26" ry="26" fill="#FFFFFF"/></svg>'
	var img := Image.new()
	var err := img.load_svg_from_string(svg, 2.0)
	if err == OK:
		_cell_bg_tex = ImageTexture.create_from_image(img)
	return _cell_bg_tex

static func get_border_tex() -> Texture2D:
	if _border_tex != null:
		return _border_tex
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect x="3" y="3" width="122" height="122" rx="20" ry="20" fill="none" stroke="#FFFFFF" stroke-width="6"/></svg>'
	var img := Image.new()
	var err := img.load_svg_from_string(svg, 2.0)
	if err == OK:
		_border_tex = ImageTexture.create_from_image(img)
	return _border_tex

static var _border_sb: StyleBoxFlat = null
static var _border_cr: int = -1

static func _get_card_sb(cr: int) -> StyleBoxFlat:
	if _card_sb != null and _card_cr == cr:
		return _card_sb
	_card_sb = StyleBoxFlat.new()
	_card_sb.bg_color = Palette.PILL_BG
	_card_sb.set_corner_radius_all(cr)
	_card_sb.shadow_color = Palette.BOARD_SHADOW
	_card_sb.shadow_size = 18
	_card_sb.shadow_offset = Vector2(0, 8)
	_card_cr = cr
	_border_sb = null
	return _card_sb

static func _get_border_sb(cr: int) -> StyleBoxFlat:
	if _border_sb != null and _border_cr == cr:
		return _border_sb
	_border_sb = StyleBoxFlat.new()
	_border_sb.bg_color = Color.TRANSPARENT
	_border_sb.draw_center = false
	_border_sb.border_color = Palette.BOARD_BORDER
	var bw := int(LayoutTokens.BOARD_BORDER_WIDTH)
	_border_sb.set_border_width_all(bw)
	_border_sb.set_corner_radius_all(cr)
	_border_cr = cr
	return _border_sb

static func draw(board: Variant) -> void:
	if board._session == null:
		return
	var br: Rect2 = board._board_rect()
	var card_rect: Rect2 = board._card_rect()
	var card_cr := int(card_rect.size.x * LayoutTokens.CARD_CORNER_RATIO)
	board.draw_style_box(_get_card_sb(card_cr), card_rect)
	board.draw_style_box(_get_border_sb(card_cr), card_rect)

	var count := int(board._session.level.get("size", 0))
	if count <= 0:
		return
	var gap: float = board._cell_gap(br.size.x)
	var cell_w := (br.size.x - gap * float(count - 1)) / float(count)
	var cr := int(cell_w * LayoutTokens.CELL_CORNER_RATIO)
	var bg_tex := get_cell_bg_tex()
	if bg_tex == null:
		return

	# Pre-resolve cell kinds taking previews into account
	var kinds: Array = []
	kinds.resize(count)
	for r in range(count):
		var row_kinds: Array = []
		row_kinds.resize(count)
		for c in range(count):
			var kind: int = board._session.board[r][c]
			var cell_coord := Vector2i(r, c)
			if board._preview_set.has(cell_coord):
				if board._preview_mark and kind == CellModel.CellKind.BLANK:
					kind = CellModel.CellKind.MARK
				elif not board._preview_mark and kind == CellModel.CellKind.MARK:
					kind = CellModel.CellKind.BLANK
			row_kinds[c] = kind
		kinds[r] = row_kinds

	var depth := cell_w * LayoutTokens.CELL_DEPTH_RATIO

	# Pass 1a: Cell bottom edge (3D depth)
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var cell_rect: Rect2 = board._cell_rect(r, c)
			if cell_scale != 1.0:
				board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
			var zone := str(board._zone_grid[r][c]) if board._zone_grid.size() > r and board._zone_grid[r].size() > c else ""
			var base_col: Color = board._zone_colors.get(zone, Palette.BG_CREAM)
			var edge_col := base_col.darkened(0.22)
			var edge_rect := Rect2(cell_rect.position + Vector2(0, depth), cell_rect.size)
			board.draw_texture_rect(bg_tex, edge_rect, false, edge_col)
			if cell_scale != 1.0:
				board.draw_set_transform(Vector2.ZERO)

	# Pass 1b: Cell backgrounds
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var cell_rect: Rect2 = board._cell_rect(r, c)
			if cell_scale != 1.0:
				board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
			var zone := str(board._zone_grid[r][c]) if board._zone_grid.size() > r and board._zone_grid[r].size() > c else ""
			var base_col: Color = board._zone_colors.get(zone, Palette.BG_CREAM)
			board.draw_texture_rect(bg_tex, cell_rect, false, base_col)
			if cell_scale != 1.0:
				board.draw_set_transform(Vector2.ZERO)

	# Pass 2: State overlays
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var ov: Color = Palette.cell_state_overlay(int(kinds[r][c]))
			if ov.a > 0.0:
				var cell_rect: Rect2 = board._cell_rect(r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
				board.draw_texture_rect(bg_tex, cell_rect, false, ov)
				if cell_scale != 1.0:
					board.draw_set_transform(Vector2.ZERO)

	# Pass 3: Zone accessibility icons (a11y)
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var zone := str(board._zone_grid[r][c]) if board._zone_grid.size() > r and board._zone_grid[r].size() > c else ""
			var icon_val: int = board._zone_overlays.get(zone, 0)
			if icon_val > 0 and icon_val < OVERLAY_CHARS.size():
				var cell_rect: Rect2 = board._cell_rect(r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
				var base_col: Color = board._zone_colors.get(zone, Palette.BG_CREAM)
				var is_dark := base_col.get_luminance() < 0.5
				var tint := RegionPainter.overlay_tint(base_col, is_dark)
				var icon_size := int(cell_w * LayoutTokens.OVERLAY_ICON_RATIO)
				board.draw_string(ThemeDB.fallback_font, cell_rect.position + Vector2(0.0, cell_rect.size.y * 0.65), OVERLAY_CHARS[icon_val], HORIZONTAL_ALIGNMENT_CENTER, cell_rect.size.x, icon_size, tint)
				if cell_scale != 1.0:
					board.draw_set_transform(Vector2.ZERO)

	# Pass 4a: Static candy (placed and givens)
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var k: int = int(kinds[r][c])
			if k == CellModel.CellKind.CANDY or k == CellModel.CellKind.GIVEN:
				var cell_rect: Rect2 = board._cell_rect(r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
				board._draw_cell_candy(cell_rect, k == CellModel.CellKind.GIVEN, r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(Vector2.ZERO)

	# Pass 4b: Static marks (MARK and ERROR not currently animating)
	for r in range(count):
		for c in range(count):
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			if board.has_mark_anim(r, c): continue
			var k: int = int(kinds[r][c])
			if k == CellModel.CellKind.MARK or k == CellModel.CellKind.ERROR:
				var cell_rect: Rect2 = board._cell_rect(r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
				board._draw_cell_x(cell_rect, k == CellModel.CellKind.ERROR, r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(Vector2.ZERO)

	# Pass 5: Animating marks
	for r in range(count):
		for c in range(count):
			if not board.has_mark_anim(r, c): continue
			var cell_scale: float = board.cell_entry_scale(r, c)
			if cell_scale <= 0.0: continue
			var k: int = int(kinds[r][c])
			if k == CellModel.CellKind.MARK or k == CellModel.CellKind.ERROR:
				var cell_rect: Rect2 = board._cell_rect(r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(cell_rect.get_center() * (1.0 - cell_scale), 0.0, Vector2.ONE * cell_scale)
				board._draw_cell_x(cell_rect, k == CellModel.CellKind.ERROR, r, c)
				if cell_scale != 1.0:
					board.draw_set_transform(Vector2.ZERO)

	# Pass 6: Borders (High contrast, solution hint, active highlights)
	if board._high_contrast:
		for r in range(count):
			for c in range(count):
				var cell_rect: Rect2 = board._cell_rect(r, c)
				board._draw_border(cell_rect, Palette.MARK_STROKE, 2, cr)

	if board._show_solution and board._session != null:
		var sol: Array = board._session.level.get("solution", [])
		for r in range(count):
			if r < sol.size():
				var sol_c: int = int(sol[r])
				var k: int = int(kinds[r][sol_c])
				if k != CellModel.CellKind.CANDY and k != CellModel.CellKind.GIVEN:
					board._draw_solution_hint(board._cell_rect(r, sol_c))

	if not board._highlight_set.is_empty():
		var pulse_alpha: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(board._highlight_pulse_phase))
		var highlight_col := Color(Palette.ACCENT_ORANGE, pulse_alpha)
		for cell_coord in board._highlight_set.keys():
			var r: int = cell_coord.x
			var c: int = cell_coord.y
			if r >= 0 and r < count and c >= 0 and c < count:
				board._draw_border(board._cell_rect(r, c), highlight_col, 3, cr)
