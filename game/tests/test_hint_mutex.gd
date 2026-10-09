extends SceneTree

const HintMutex = preload("res://scripts/screens/hint_mutex.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_acquire_release_cycle()
	_test_double_acquire_blocked()
	_test_force_release_clears_all()
	_test_is_locked_during_acquire()
	_test_is_locked_during_cooldown()
	if _fails.is_empty():
		print("HINT_MUTEX_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_acquire_release_cycle() -> void:
	var m := HintMutex.new()
	_assert(m.try_acquire("hint"), "first acquire succeeds")
	m.release("hint")
	# Cooldown blocks immediately after release
	_assert(m.is_locked(), "locked during cooldown after release")

func _test_double_acquire_blocked() -> void:
	var m := HintMutex.new()
	_assert(m.try_acquire("a"), "acquire a")
	_assert(not m.try_acquire("b"), "acquire b blocked while a held")
	m.release("a")

func _test_force_release_clears_all() -> void:
	var m := HintMutex.new()
	m.try_acquire("hint")
	m.force_release()
	_assert(not m.is_locked(), "not locked after force_release")
	_assert(m.try_acquire("hint"), "acquire after force_release")

func _test_is_locked_during_acquire() -> void:
	var m := HintMutex.new()
	_assert(not m.is_locked(), "not locked initially")
	m.try_acquire("x")
	_assert(m.is_locked(), "locked after acquire")
	m.release("x")

func _test_is_locked_during_cooldown() -> void:
	var m := HintMutex.new()
	m.try_acquire("x")
	m.release("x")
	_assert(m.is_locked(), "locked during cooldown")
	_assert(not m.try_acquire("y"), "acquire blocked during cooldown")

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		_fails.append("FAIL: " + msg)
