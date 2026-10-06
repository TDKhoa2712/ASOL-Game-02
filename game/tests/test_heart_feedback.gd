extends SceneTree

const PuzzleScreen = preload("res://scripts/screens/puzzle_screen.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

class ResumeRuntime extends RefCounted:
	var current_session: Variant
	var sessions: Variant = null
	func current_level_label() -> String: return "heart-test"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	LayoutTokens.set_motion(true)
	await _test_loss_and_refresh()
	await _test_last_heart()
	await _test_restart_and_leave()
	await _test_failed_resume()
	_test_reduced_motion_and_resume()
	LayoutTokens.set_motion(true)
	if failures.is_empty():
		print("HEART_FEEDBACK_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _puzzle(hearts: int = 3) -> Control:
	var puzzle := PuzzleScreen.new()
	puzzle.session = PlaySession.new({
		"size": 4, "id": "heart-test", "hash": "heart-test",
		"regions": ["AABB", "ABBB", "CCBB", "CCDB"],
		"solution": [1, 3, 0, 2], "givens": [{"r": 0, "c": 1}],
	}, hearts)
	puzzle._is_custom = true
	root.add_child(puzzle)
	puzzle.board.configure(puzzle.session)
	puzzle._connect_session()
	puzzle._update_hearts()
	return puzzle

func _animating(puzzle: Control) -> bool:
	return puzzle.hearts_display.has_method("is_animating") and puzzle.hearts_display.is_animating()

func _test_loss_and_refresh() -> void:
	var puzzle := _puzzle()
	await process_frame
	var icons: Array = puzzle.hearts_display.get_children()
	puzzle.session.try_candy(0, 0)
	_check(puzzle.session.hearts == 2, "wrong candy immediately costs one heart")
	_check(puzzle.hearts_display.get_children() == icons, "loss preserves all three HUD slots")
	_check(_animating(puzzle), "wrong candy starts heart break and fall")
	if icons[2].has_method("is_breaking"):
		_check(icons[2].is_breaking() and not icons[0].is_breaking(), "only the lost heart breaks")
	puzzle.session.try_candy(1, 3)
	_check(_animating(puzzle), "correct candy refresh keeps loss animation alive")
	await create_timer(1.0).timeout
	_check(not _animating(puzzle), "fall finishes and cleans up")
	_check(puzzle.hearts_display.get_child_count() == 3, "empty heart keeps HUD width stable")
	puzzle.free()

func _test_last_heart() -> void:
	var puzzle := _puzzle(1)
	await process_frame
	var results: Array = []
	puzzle.level_done.connect(func(won: bool): results.append(won))
	puzzle.session.try_candy(0, 0)
	_check(puzzle.session.phase == PlaySession.Phase.FAILED, "last mistake immediately fails gameplay")
	_check(results.is_empty(), "result waits for last heart to fall")
	_check(_animating(puzzle), "last heart plays the same animation")
	await create_timer(1.0).timeout
	_check(results == [false], "failure result emitted once after animation")
	puzzle.free()

func _test_restart_and_leave() -> void:
	var puzzle := _puzzle(1)
	var results: Array = []
	puzzle.level_done.connect(func(won: bool): results.append(won))
	puzzle.session.try_candy(0, 0)
	puzzle._confirm_restart()
	_check(puzzle.session.hearts == 3 and not _animating(puzzle), "restart restores hearts and cancels fall")
	await create_timer(1.0).timeout
	_check(results.is_empty(), "old animation cannot fail restarted session")
	puzzle.session.hearts = 1
	puzzle._update_hearts()
	puzzle.session.try_candy(0, 0)
	puzzle.free()
	await create_timer(1.0).timeout
	_check(results.is_empty(), "leaving during final fall cannot emit stale failure")

func _test_reduced_motion_and_resume() -> void:
	LayoutTokens.set_motion(false)
	var puzzle := _puzzle(2)
	_check(not _animating(puzzle), "restored missing heart does not replay loss")
	var results: Array = []
	puzzle.level_done.connect(func(won: bool): results.append(won))
	puzzle.session.try_candy(0, 0)
	_check(not _animating(puzzle), "reduced motion uses static empty heart")
	puzzle.session.try_candy(0, 2)
	_check(results == [false], "reduced motion shows failure without waiting for animation")
	puzzle.free()

func _test_failed_resume() -> void:
	var original := _puzzle(1)
	original.session.try_candy(0, 0)
	var saved: Dictionary = original.session.to_save_data()
	var level: Dictionary = original.session.level
	original.free()
	var runtime := ResumeRuntime.new()
	runtime.current_session = PlaySession.from_save_data(saved, level)
	var restored := PuzzleScreen.new()
	var results: Array = []
	restored.level_done.connect(func(won: bool): results.append(won))
	root.add_child(restored)
	restored.setup(runtime, null)
	_check(not _animating(restored), "failed resume does not replay falling hearts")
	await process_frame
	_check(results == [false], "reopening after final fall restores failure result")
	restored.free()

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)
