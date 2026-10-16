extends SceneTree

const PuzzleLayout = preload("res://scripts/screens/puzzle_layout.gd")
const FitLabel = preload("res://scripts/ui/fit_label.gd")
const CoachBubble = preload("res://scripts/screens/coach_bubble.gd")
const TextScaler = preload("res://scripts/theme/text_scaler.gd")

var _fails: Array[String] = []

func _initialize() -> void:
	_run()

func _run() -> void:
	await _test_long_caption_fits_two_lines()
	await _test_hidden_rules_keep_board_in_place()
	await _test_hint_card_never_moves_board()
	await _test_coach_bubble_spans_rule_slot_and_never_squishes()
	if _fails.is_empty():
		print("RULE_CARDS_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _test_long_caption_fits_two_lines() -> void:
	var label := FitLabel.new()
	label.max_font_size = 40
	label.size = Vector2(300, 0)
	label.text = "Candies cannot touch each other, not even diagonally at all"
	root.add_child(label)
	await process_frame
	label.size.x = 300
	label.refit()
	_assert(label.get_line_count() <= FitLabel.MAX_LINES, "caption wraps to <= 2 lines (got %d)" % label.get_line_count())
	_assert(label.get_theme_font_size("font_size") < 40, "long caption shrinks its font")
	TextScaler.apply(label, true)
	_assert(label.get_line_count() <= FitLabel.MAX_LINES, "large-text scaling does not re-break the fit")
	label.queue_free()

func _test_hidden_rules_keep_board_in_place() -> void:
	var host := Control.new()
	host.size = Vector2(1080, 1920)
	root.add_child(host)
	var n: Dictionary = PuzzleLayout.build(host)
	for i in 3: await process_frame
	var board_card: Control = n["board"].get_parent()
	var before := board_card.global_position.y
	n["rules"].visible = false
	for i in 3: await process_frame
	_assert(is_equal_approx(board_card.global_position.y, before), "board stays put when rules hide (%s -> %s)" % [before, board_card.global_position.y])
	host.queue_free()

func _test_hint_card_never_moves_board() -> void:
	var host := Control.new()
	host.size = Vector2(1080, 1920)
	root.add_child(host)
	var n: Dictionary = PuzzleLayout.build(host)
	for i in 3: await process_frame
	var board_card: Control = n["board"].get_parent()
	var before := board_card.global_position.y
	var long_text := "This hint text is deliberately long so it would wrap to many lines and push the board down if the slot could grow with it. ".repeat(3)
	n["hint_overlay"].show_hint({"strategy": "CONTRA_CHAIN", "explanation_key": long_text, "chain_detail": {}})
	for i in 4: await process_frame
	_assert(is_equal_approx(board_card.global_position.y, before), "board stays put when a long hint shows (%s -> %s)" % [before, board_card.global_position.y])
	var card: Control = n["hint_overlay"]
	_assert(card.get_global_rect().end.y <= board_card.global_position.y + 0.5, "hint card ends above the board")
	host.queue_free()

func _test_coach_bubble_spans_rule_slot_and_never_squishes() -> void:
	var host := Control.new()
	host.size = Vector2(1080, 1920)
	root.add_child(host)
	var n: Dictionary = PuzzleLayout.build(host)
	var rule_slot: Control = n["rules"].get_parent()
	var bubble := CoachBubble.new()
	bubble.visible = false
	rule_slot.add_child(bubble)
	rule_slot.move_child(bubble, n["rules"].get_index() + 1)
	for i in 3: await process_frame
	n["rules"].visible = false
	bubble.visible = true
	bubble.show_message("Find the candies hidden behind the colored cells! Each row, column and zone has exactly one, and candies never touch.", "", false)
	for i in 3: await process_frame
	_assert(bubble.size.x >= 500.0, "coach bubble fills horizontal slot instead of squishing (got %s)" % bubble.size.x)
	_assert(bubble.size.y <= PuzzleLayout.RULE_SLOT_HEIGHT + 1.0, "coach bubble fits inside rule slot height (got %s)" % bubble.size.y)
	host.queue_free()

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append(msg)
