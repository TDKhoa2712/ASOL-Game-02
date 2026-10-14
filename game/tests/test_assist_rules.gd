extends SceneTree

const Rules = preload("res://scripts/state/assist_rules.gd")
var failures: Array[String] = []

func _init() -> void:
	_test_defaults_and_sanitize()
	_test_consume_and_add()
	_test_reward_thresholds()
	_test_streak()
	if failures.is_empty():
		print("ASSIST_RULES_PASS")
		quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)

func _test_defaults_and_sanitize() -> void:
	var d := Rules.new_data()
	check(d.hint == 3 and d.place == 1, "start 3 hint 1 place")
	check(d.streakDays == 0 and d.lastStreakDate == "", "start streak empty")
	var s := Rules.sanitize({"hint": -4, "place": 99, "streakDays": 12, "lastStreakDate": "bad", "usedHint": "x"})
	check(s.hint == 0 and s.place == 10, "clamp counts to 0..10")
	check(s.streakDays == 0, "streak outside 0..6 resets")
	check(s.lastStreakDate == "", "invalid date dropped")
	check(s.usedHint == 0, "non-number used dropped")
	check(Rules.sanitize(null) == Rules.new_data(), "null -> defaults")
	check(Rules.sanitize({}) == Rules.new_data(), "empty -> defaults")

func _test_consume_and_add() -> void:
	var d := Rules.new_data()
	var r := Rules.consume(d, "place")
	check(r.ok and r.data.place == 0 and r.data.usedPlace == 1, "consume place")
	check(d.place == 1, "consume does not mutate input")
	check(not Rules.consume(r.data, "place").ok, "consume at 0 fails")
	check(Rules.add(d, "hint", 20).hint == 10, "add clamps at 10")
	check(not Rules.consume(d, "coins").ok, "unknown kind fails")

func _test_reward_thresholds() -> void:
	check(Rules.reward_for(0) == 2 and Rules.reward_for(1) == 2, "0-1 -> 2")
	check(Rules.reward_for(2) == 3 and Rules.reward_for(4) == 3, "2-4 -> 3")
	check(Rules.reward_for(5) == 4 and Rules.reward_for(40) == 4, ">=5 -> 4")

func _test_streak() -> void:
	check(Rules.day_gap("2026-12-31", "2027-01-01") == 1, "gap across year")
	check(Rules.day_gap("2026-02-28", "2026-03-01") == 1, "gap across month")
	var d := Rules.new_data()
	var r := Rules.record_win(d, "2026-10-01")
	check(r.data.streakDays == 1 and r.reward.is_empty(), "first win day 1")
	var same := Rules.record_win(r.data, "2026-10-01")
	check(same.data == r.data and same.reward.is_empty(), "same day twice no change")
	var back := Rules.record_win(r.data, "2026-09-20")
	check(back.data == r.data, "clock rollback ignored")
	var used: Dictionary = Rules.consume(r.data, "hint").data
	var missed := Rules.record_win(used, "2026-10-03")
	check(missed.data.streakDays == 1 and missed.data.usedHint == 0, "missed day resets streak and counters")
	# 7 consecutive days: hint used 5 times, place 0 times
	var cur := Rules.add(Rules.new_data(), "hint", 7)  # hint = 10
	cur = Rules.record_win(cur, "2026-10-01").data  # day 1 (a fresh start clears counters)
	for i in 5: cur = Rules.consume(cur, "hint").data  # hint = 5, usedHint = 5
	var reward := {}
	for day in range(2, 8):
		var res := Rules.record_win(cur, "2026-10-%02d" % day)
		cur = res.data
		if day < 7: check(res.reward.is_empty(), "no reward before day 7 (%d)" % day)
		else: reward = res.reward
	check(reward == {"hint": 4, "place": 2}, "day 7 reward by usage")
	check(cur.hint == 9 and cur.place == 3, "reward added")
	check(cur.streakDays == 0 and cur.usedHint == 0 and cur.usedPlace == 0, "cycle restarts")
	check(Rules.record_win(cur, "2026-10-08").data.streakDays == 1, "next day is day 1")
	# cap: place already 10 -> reward reports only what was added
	var full := Rules.add(Rules.new_data(), "place", 10)
	for day in range(1, 8): 
		var res2 := Rules.record_win(full, "2026-11-%02d" % day)
		full = res2.data
		if day == 7: check(res2.reward.place == 0 and full.place == 10, "reward clipped at cap")
