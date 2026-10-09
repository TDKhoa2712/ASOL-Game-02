extends SceneTree

const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

var _fails: Array[String] = []

func _init() -> void:
	var bank := BankReader.new()
	for n in [4, 6, 9, 12]:
		bank.load_bank(n)
		var lvl: Dictionary = {}
		for rank in range(1, 40):
			lvl = bank.get_level(n, rank, 0)
			if not lvl.is_empty():
				break
		lvl = lvl.duplicate(true)
		if lvl.is_empty():
			_fails.append("no level for %dx%d" % [n, n])
			continue
		lvl["id"] = "T"
		for side in [360.0, 680.0]:
			_check(lvl, n, Vector2(side, side + 40.0))
	if _fails.is_empty():
		print("BOARD_FIT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

# Every cell, including its 3D bottom edge, must sit inside the card's border and clear
# the rounded corners.
func _check(lvl: Dictionary, n: int, area: Vector2) -> void:
	var board := PuzzleBoard.new()
	board.size = area
	board.configure(PlaySession.new(lvl), false)
	var card: Rect2 = board._card_rect()
	var inner := card.grow(-LayoutTokens.BOARD_BORDER_WIDTH)
	var cr := card.size.x * LayoutTokens.CARD_CORNER_RATIO
	for r in range(n):
		for c in range(n):
			var cell: Rect2 = board._cell_rect(r, c)
			var depth := cell.size.x * LayoutTokens.CELL_DEPTH_RATIO
			var full := Rect2(cell.position, cell.size + Vector2(0, depth))
			if not inner.encloses(full):
				_fails.append("%dx%d @%s cell %d,%d leaves card %s vs %s" % [n, n, area, r, c, full, inner])
				board.free()
				return
	# Corner cell (bottom-right incl. depth) must not cross the card's rounded corner arc.
	var last: Rect2 = board._cell_rect(n - 1, n - 1)
	var corner := last.end + Vector2(0, last.size.x * LayoutTokens.CELL_DEPTH_RATIO)
	var cell_cr := last.size.x * LayoutTokens.CELL_CORNER_RATIO
	var probe := corner - Vector2.ONE * cell_cr * (1.0 - 1.0 / sqrt(2.0))
	var arc_center := card.end - Vector2.ONE * cr
	var limit := cr - LayoutTokens.BOARD_BORDER_WIDTH
	if probe.x > arc_center.x and probe.y > arc_center.y and probe.distance_to(arc_center) > limit:
		_fails.append("%dx%d @%s corner cell crosses rounded border" % [n, n, area])
	board.free()
