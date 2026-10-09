# game/tests/test_candy_anim_state.gd
extends SceneTree

const CandyAnimState = preload("res://scripts/screens/candy_anim_state.gd")

var _fails: Array[String] = []
const META := {
	"appear": {"fps": 10, "loop": false, "count": 4},
	"idle": {"fps": 10, "loop": false, "count": 4},
	"error": {"fps": 10, "loop": false, "count": 4},
	"sad": {"fps": 10, "loop": true, "count": 4},
	"win": {"fps": 10, "loop": false, "count": 4},
}

func _init() -> void:
	_test_appear_then_rest()
	_test_no_change_returns_false()
	_test_idle_triggers_within_window()
	_test_idle_cap()
	_test_error_all_once()
	_test_sad_loops_and_overrides_error()
	_test_win_holds_last_and_staggers()
	_test_motion_off()
	_test_sync_rests_placed_cells()
	_test_motion_toggled_live()
	_test_progress_is_continuous()
	if _fails.is_empty():
		print("CANDY_ANIM_STATE_PASS"); quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond: _fails.append("FAIL: " + msg)

func _test_appear_then_rest() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.frame_of(c) == ["appear", 0], "appear starts at frame 0")
	_assert(s.advance(0.15, true), "advance reports frame change")
	_assert(s.frame_of(c) == ["appear", 1], "appear frame 1 after 0.15s")
	s.advance(0.5, true)
	_assert(s.frame_of(c) == ["idle", 0], "appear finishes into idle rest")

func _test_no_change_returns_false() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(1, 1))
	_assert(not s.advance(0.01, true), "resting cell does not request redraw")

func _test_idle_triggers_within_window() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(2, 3)
	s.rest(c)
	var elapsed := 0.0
	while elapsed < 2.4:
		s.advance(0.1, true); elapsed += 0.1
	_assert(s.idle_playing_count() == 0, "idle not before 2.5s")
	var played := false
	while elapsed < 5.5:
		s.advance(0.05, true); elapsed += 0.05
		if s.frame_of(c)[1] > 0: played = true
	_assert(played, "idle plays within 2.5-5s window")

func _test_idle_cap() -> void:
	var s := CandyAnimState.new(META)
	s.idle_min = 0.1; s.idle_max = 0.1
	for r in 12:
		for c in 12: s.rest(Vector2i(r, c))
	var peak := 0
	for i in 40:
		s.advance(0.05, true); peak = maxi(peak, s.idle_playing_count())
	_assert(peak == CandyAnimState.MAX_CONCURRENT_IDLE, "idle capped at MAX_CONCURRENT_IDLE (peak=%d)" % peak)

func _test_error_all_once() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(0, 0)); s.rest(Vector2i(1, 2))
	s.play_all("error")
	_assert(s.frame_of(Vector2i(1, 2))[0] == "error", "play_all applies to every cell")
	s.advance(0.5, true)
	_assert(s.frame_of(Vector2i(1, 2)) == ["idle", 0], "error plays once then rests")

func _test_sad_loops_and_overrides_error() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.rest(c)
	s.play_all("error")
	s.play_all("sad")
	s.advance(2.05, true)
	_assert(s.frame_of(c)[0] == "sad", "sad keeps looping and overrides error")
	_assert(s.idle_playing_count() == 0, "sad cells never start idle")

func _test_win_holds_last_and_staggers() -> void:
	var s := CandyAnimState.new(META)
	s.rest(Vector2i(0, 0)); s.rest(Vector2i(3, 0))
	s.play_all("win", 0.1)
	s.advance(0.15, true)
	_assert(s.frame_of(Vector2i(0, 0))[1] > 0, "row 0 starts immediately")
	_assert(s.frame_of(Vector2i(3, 0)) == ["win", 0], "row 3 waits for stagger")
	for i in 40: s.advance(0.05, true)
	_assert(s.frame_of(Vector2i(3, 0)) == ["win", 3], "win holds last frame")
	_assert(not s.advance(1.0, true), "finished win does not redraw")

func _test_motion_off() -> void:
	var s := CandyAnimState.new(META)
	s.motion = false
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.frame_of(c) == ["idle", 0], "no motion: appear goes straight to rest")
	s.play_all("win")
	_assert(s.frame_of(c) == ["win", 3], "no motion: win shows final pose")
	_assert(not s.advance(1.0, false), "inactive advance never redraws")

func _test_sync_rests_placed_cells() -> void:
	var s := CandyAnimState.new(META)
	s.sync([[0, 2], [4, 3]])
	_assert(s.frame_of(Vector2i(0, 1)) == ["idle", 0] and s.frame_of(Vector2i(1, 0)) == ["idle", 0], "sync rests candy+given")
	_assert(not s._cells.has(Vector2i(1, 1)), "sync skips ERROR cells")

func _test_motion_toggled_live() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.tick(0.0, false, true), "turning motion off requests a redraw")
	_assert(s.frame_of(c) == ["idle", 0], "motion off mid-appear settles to rest, not a tiny frame")
	s.play_all("sad")
	_assert(not s.tick(0.5, false, true), "motion off: sad stays still")
	s.tick(0.0, true, true)
	_assert(s.tick(0.15, true, true) and s.frame_of(c)[1] > 0, "motion back on: sad resumes looping")

func _test_progress_is_continuous() -> void:
	var s := CandyAnimState.new(META)
	var c := Vector2i(0, 0)
	s.play(c, "appear")
	_assert(s.progress_of(c) == 0.0, "progress starts at 0")
	_assert(s.advance(0.01, true), "playing cell redraws every tick even without a frame change")
	_assert(absf(s.progress_of(c) - 0.025) < 0.001, "progress is continuous (0.01s of 0.4s)")
	s.play_all("sad")
	s.advance(0.5, true)
	_assert(absf(s.progress_of(c) - 0.25) < 0.001, "looping progress wraps (0.5s of 0.4s)")
	s.play_all("win")
	for i in 20: s.advance(0.05, true)
	_assert(s.progress_of(c) == 1.0, "finished win holds progress 1")
	_assert(s.progress_of(Vector2i(9, 9)) == 0.0, "unknown cell progress 0")
