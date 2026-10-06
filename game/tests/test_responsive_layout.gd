extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")

var _fails: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append("FAIL: " + msg)

func _create_level(n: int) -> Dictionary:
	var regions: Array = []
	for r in range(n):
		var s: String = ""
		for c in range(n):
			s += char(65 + r)
		regions.append(s)
	return {
		"size": n,
		"regions": regions,
		"solution": range(n),
		"givens": [],
		"id": "T%02d" % n
	}

func _run_tests() -> void:
	var screen := PuzzleScreen.new()
	screen.size = Vector2(1080, 1920)
	root.add_child(screen)
	await process_frame
	await process_frame

	var safe_area: MarginContainer = screen.get_node_or_null("SafeArea") as MarginContainer
	_assert(safe_area != null, "SafeArea exists")
	var root_vbox: VBoxContainer = screen.get_node_or_null("SafeArea/Root") as VBoxContainer
	_assert(root_vbox != null, "Root VBox exists")
	var status_row: HBoxContainer = screen.get_node_or_null("SafeArea/Root/StatusRow") as HBoxContainer
	_assert(status_row != null, "StatusRow exists")
	var board_card: PanelContainer = screen.get_node_or_null("SafeArea/Root/BoardCard") as PanelContainer
	_assert(board_card != null, "BoardCard exists")
	var board: PuzzleBoard = screen.board
	_assert(board != null, "Board exists")

	# Test 1: For all N from 4 to 12, StatusRow and Root VBox must not overflow 1004 width
	const MAX_CONTENT_WIDTH := 1004.0
	for n in [4, 5, 6, 7, 8, 9, 10, 11, 12]:
		var session := PlaySession.new(_create_level(n))
		screen.session = session
		board.configure(session)
		screen._update_hearts()
		await process_frame

		var status_min_w: float = status_row.get_combined_minimum_size().x
		_assert(status_min_w < 700.0, "StatusRow min width %f < 700 at N=%d" % [status_min_w, n])

		var vbox_min_w: float = root_vbox.get_combined_minimum_size().x
		_assert(vbox_min_w <= MAX_CONTENT_WIDTH, "Root VBox width %f <= %f at N=%d" % [vbox_min_w, MAX_CONTENT_WIDTH, n])

		var region_row: HBoxContainer = status_row.get_node_or_null("RegionProgressPill/RegionIcons") as HBoxContainer
		_assert(region_row != null and region_row.get_child_count() == n, "RegionIcons has %d children at N=%d" % [n, n])

		for icon in region_row.get_children():
			if icon is TextureRect:
				_assert(icon.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Icon uses EXPAND_IGNORE_SIZE at N=%d" % n)
				_assert(icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Icon uses STRETCH_KEEP_ASPECT_CENTERED at N=%d" % n)
				if n <= 6:
					_assert(icon.custom_minimum_size.x >= 46.0, "Icon width %f >= 46.0 at N=%d" % [icon.custom_minimum_size.x, n])
					_assert(icon.custom_minimum_size.y >= 46.0, "Icon height %f >= 46.0 at N=%d" % [icon.custom_minimum_size.y, n])

	# Test 1b: Verify candy texture dynamically adapts to level candy_type or level id
	var custom_level := _create_level(5)
	custom_level["candy_type"] = "lollipop"
	var custom_session := PlaySession.new(custom_level)
	screen.session = custom_session
	board.configure(custom_session)
	screen._update_hearts()
	await process_frame
	var custom_region_row: HBoxContainer = status_row.get_node_or_null("RegionProgressPill/RegionIcons") as HBoxContainer
	if custom_region_row != null and custom_region_row.get_child_count() > 0:
		var sample_icon: TextureRect = custom_region_row.get_child(0) as TextureRect
		var want_tex: Texture2D = CandyRenderer.texture_for_type("lollipop")
		_assert(sample_icon.texture == want_tex, "Candy icon dynamically adapts to level candy_type")

	# Test 2: PuzzleBoard expands responsively inside BoardCard
	_assert(board.size_flags_horizontal & Control.SIZE_EXPAND_FILL != 0, "Board has horizontal expand flag")
	_assert(board.size_flags_vertical & Control.SIZE_EXPAND_FILL != 0, "Board has vertical expand flag")
	var br: Rect2 = board._board_rect()
	_assert(br.size.x >= 700.0, "Board rect side %f >= 700.0 in 1080x1920 layout" % br.size.x)

	screen.queue_free()
	await process_frame

	if _fails.is_empty():
		print("RESPONSIVE_LAYOUT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)
