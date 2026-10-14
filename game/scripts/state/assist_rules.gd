# Pure rules for the assist stock (hint, place-candy) and the 7-day play streak.
extends RefCounted

const CAP := 10
const CYCLE_DAYS := 7
const KINDS := ["hint", "place"]
const USED_KEY := {"hint": "usedHint", "place": "usedPlace"}
const START := {"hint": 3, "place": 1}
const INVALID_GAP := -999999

static func new_data() -> Dictionary:
	return {"version": 1, "hint": START.hint, "place": START.place,
		"streakDays": 0, "lastStreakDate": "", "usedHint": 0, "usedPlace": 0, "totalStreak": 0, "bestStreak": 0}

static func sanitize(raw: Variant) -> Dictionary:
	var out := new_data()
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		return out
	for kind in KINDS:
		out[kind] = _int_in(raw.get(kind), 0, CAP, START[kind])
		out[USED_KEY[kind]] = _int_in(raw.get(USED_KEY[kind]), 0, 9999, 0)
	out.streakDays = _int_in(raw.get("streakDays"), 0, CYCLE_DAYS - 1, 0)
	var date := str(raw.get("lastStreakDate", ""))
	out.lastStreakDate = date if _unix(date) != INVALID_GAP else ""
	# Saves from before totalStreak existed: the running cycle is a lower bound.
	out.totalStreak = maxi(_int_in(raw.get("totalStreak"), 0, 100000, 0), out.streakDays)
	out.bestStreak = maxi(_int_in(raw.get("bestStreak"), 0, 100000, 0), out.totalStreak)
	return out

static func consume(data: Dictionary, kind: String) -> Dictionary:
	if not KINDS.has(kind) or int(data.get(kind, 0)) <= 0:
		return {"ok": false, "data": data}
	var next := data.duplicate(true)
	next[kind] = int(next[kind]) - 1
	next[USED_KEY[kind]] = int(next[USED_KEY[kind]]) + 1
	return {"ok": true, "data": next}

static func add(data: Dictionary, kind: String, amount: int) -> Dictionary:
	var next := data.duplicate(true)
	if KINDS.has(kind):
		next[kind] = clampi(int(next.get(kind, 0)) + amount, 0, CAP)
	return next

static func reward_for(used: int) -> int:
	if used >= 5: return 4
	if used >= 2: return 3
	return 2

static func record_win(data: Dictionary, today_date: String) -> Dictionary:
	var last: String = data.get("lastStreakDate", "")
	var gap := day_gap(last, today_date) if last != "" else 2
	if gap == 0 or gap < 0:
		return {"data": data, "reward": {}}
	var next := data.duplicate(true)
	next.lastStreakDate = today_date
	if gap == 1:
		next.streakDays = int(next.streakDays) + 1
		next.totalStreak = int(next.get("totalStreak", 0)) + 1
	else:
		next.streakDays = 1
		next.totalStreak = 1
		next.usedHint = 0
		next.usedPlace = 0
	next.bestStreak = maxi(int(next.get("bestStreak", 0)), int(next.totalStreak))
	if int(next.streakDays) < CYCLE_DAYS:
		return {"data": next, "reward": {}}
	var reward := {}
	for kind in KINDS:
		var before := int(next[kind])
		next = add(next, kind, reward_for(int(next[USED_KEY[kind]])))
		reward[kind] = int(next[kind]) - before
	next.streakDays = 0
	next.usedHint = 0
	next.usedPlace = 0
	return {"data": next, "reward": reward}

static func streak_view(data: Dictionary, today_date: String) -> Dictionary:
	var last: String = data.get("lastStreakDate", "")
	var gap := day_gap(last, today_date) if last != "" else INVALID_GAP
	var alive := gap == 0 or gap == 1
	var count := int(data.get("totalStreak", 0)) if alive else 0
	var cycle := int(data.get("streakDays", 0)) if alive else 0
	if gap == 0 and cycle == 0 and count > 0:
		cycle = CYCLE_DAYS  # today's win completed the pack
	return {"count": count, "best": int(data.get("bestStreak", 0)), "kept_today": gap == 0,
		"at_risk": count > 0 and gap != 0, "cycle_done": cycle}

static func day_gap(from_date: String, to_date: String) -> int:
	var a := _unix(from_date)
	var b := _unix(to_date)
	if a == INVALID_GAP or b == INVALID_GAP:
		return INVALID_GAP
	return int(round(float(b - a) / 86400.0))

static func today() -> String:
	return Time.get_date_string_from_system()

static func _unix(date: String) -> int:
	if date.length() != 10 or date[4] != "-" or date[7] != "-":
		return INVALID_GAP
	var parts := date.split("-")
	for p in parts:
		if not p.is_valid_int(): return INVALID_GAP
	var m := int(parts[1]); var d := int(parts[2])
	if m < 1 or m > 12 or d < 1 or d > 31:
		return INVALID_GAP
	return Time.get_unix_time_from_datetime_string(date + "T00:00:00")

static func _int_in(value: Variant, lo: int, hi: int, fallback: int) -> int:
	if not (value is int or value is float):
		return fallback
	var v := int(value)
	if lo == 0 and hi == CYCLE_DAYS - 1 and (v < lo or v > hi):
		return fallback
	return clampi(v, lo, hi)
