extends SceneTree

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const CellModel = preload("res://scripts/core/cell_model.gd")
var failures: Array[String] = []
var _observed_voice_index := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell = load("res://scenes/main.tscn").instantiate()
	shell.profile_dir = OS.get_user_data_dir().path_join("sfx_context_%d" % Time.get_ticks_usec())
	root.add_child(shell)
	await process_frame
	var title = shell.screen_host.get_child(0)
	title.options_btn.pressed.emit()
	_expect_effect(shell.sfx, SfxCatalog.Effect.SETTINGS_OPEN, "title settings opens")
	var options = shell.screen_host.get_child(0)
	options.back_btn.pressed.emit()
	_expect_effect(shell.sfx, SfxCatalog.Effect.TAP_BACK, "settings closes with shared click")
	shell._on_title_play()
	var puzzle = shell.screen_host.get_child(0)
	_expect_effect(shell.sfx, SfxCatalog.Effect.BOARD_OPEN, "board open")
	puzzle.settings_btn.pressed.emit()
	_expect_effect(shell.sfx, SfxCatalog.Effect.SETTINGS_OPEN, "puzzle settings opens")
	options = shell.screen_host.get_child(0)
	options.back_btn.pressed.emit()
	_check(shell.sfx._last_play_ms.has(SfxCatalog.Effect.TAP_BACK),
		"puzzle settings closes with shared click")
	puzzle = shell.screen_host.get_child(0)
	var blank := _wrong_cell(puzzle.session)
	puzzle._on_board_tap(blank.x, blank.y)
	_expect_effect(shell.sfx, SfxCatalog.Effect.MARK, "tap mark")
	puzzle._on_undo()
	_expect_effect(shell.sfx, SfxCatalog.Effect.UNDO_X, "successful undo")
	puzzle._on_undo()
	_check(shell.sfx._pool_idx == _observed_voice_index, "empty undo is silent")
	var last_ms: int = shell.sfx._last_play_ms[SfxCatalog.Effect.MARK]
	while Time.get_ticks_msec() - last_ms < 110: await process_frame
	puzzle._on_board_tap(blank.x, blank.y)
	_expect_effect(shell.sfx, SfxCatalog.Effect.MARK, "mark after undo")
	last_ms = shell.sfx._last_play_ms[SfxCatalog.Effect.MARK]
	while Time.get_ticks_msec() - last_ms < 110: await process_frame
	puzzle._on_board_swipe([[blank.x, blank.y]])
	_expect_effect(shell.sfx, SfxCatalog.Effect.UNMARK, "swipe removes mark")
	puzzle._on_hint()
	_expect_effect(shell.sfx, SfxCatalog.Effect.HINT_SHOW, "hint")
	puzzle._on_restart()
	_expect_effect(shell.sfx, SfxCatalog.Effect.DIALOG_OPEN, "restart confirmation opens")
	puzzle.restart_confirm.hide()
	_expect_effect(shell.sfx, SfxCatalog.Effect.DIALOG_CLOSE, "restart confirmation closes")
	puzzle._confirm_restart()
	_expect_effect(shell.sfx, SfxCatalog.Effect.RESTART, "restart")
	var session = puzzle.session
	for row in range(session.level.solution.size()):
		var col := int(session.level.solution[row])
		if session.cell_at(row, col) == CellModel.CellKind.GIVEN: continue
		puzzle._on_board_double_tap(row, col)
		var total: int = int(session.level.size) - session.level.get("givens", []).size()
		var found: int = total - session.remaining_candies()
		if found == int((total + 1) / 2) and found < total:
			_expect_effect(shell.sfx, SfxCatalog.Effect.PROGRESS_COMPLETE, "halfway progress")
		elif session.phase == 0:
			_expect_effect(shell.sfx, SfxCatalog.Effect.CANDY_YES, "correct candy")
	_expect_effect(shell.sfx, SfxCatalog.Effect.STAGE_CLEAR, "win melody")
	shell._on_next_level()
	puzzle = shell.screen_host.get_child(0)
	for mistake in range(3):
		blank = _wrong_cell(puzzle.session)
		puzzle._on_board_double_tap(blank.x, blank.y)
		if puzzle.session.phase == 0:
			_expect_effect(shell.sfx, SfxCatalog.Effect.CANDY_NO, "wrong candy")
	_expect_effect(shell.sfx, SfxCatalog.Effect.STAGE_FAIL, "failure melody")
	if puzzle.hearts_display.is_animating(): await puzzle.hearts_display.loss_animation_finished
	shell.config.set_option("audio", false)
	var fail_screen = shell.screen_host.get_child(0)
	fail_screen.home_btn.pressed.emit()
	for voice in shell.sfx.get_children():
		if voice is AudioStreamPlayer:
			_check(not voice.playing, "audio option mutes menu and gameplay")
	# The binding belongs to this composition root, not unrelated controls.
	shell.config.set_option("audio", true)
	var outside := Button.new()
	root.add_child(outside)
	var before: int = shell.sfx._pool_idx
	outside.pressed.emit()
	_check(shell.sfx._pool_idx == before, "unrelated UI is outside binding scope")
	outside.free()
	shell.sfx.set_muted(true)
	shell.free()
	var cleanup_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - cleanup_ms < 100: await process_frame
	if failures.is_empty():
		print("SFX_GAMEPLAY_PASS")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _wrong_cell(session) -> Vector2i:
	for row in range(session.level.size):
		for col in range(session.level.size):
			if col != int(session.level.solution[row]) and session.cell_at(row, col) == CellModel.CellKind.BLANK:
				return Vector2i(row, col)
	return Vector2i(-1, -1)

func _expect_effect(player, effect: int, label: String) -> void:
	var voice: AudioStreamPlayer = player._pool[(player._pool_idx + 7) % 8]
	# A short UI cue can finish while the destination screen is being built.
	_check(player._pool_idx != _observed_voice_index and voice.stream == player._streams[effect],
		"%s dispatches correct sound (actual=%s, muted=%s)" % [label, player._streams.find_key(voice.stream), player.is_muted()])
	_observed_voice_index = player._pool_idx

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append("FAIL: " + label)
