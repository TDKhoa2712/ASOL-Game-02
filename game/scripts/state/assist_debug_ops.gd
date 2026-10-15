# game/scripts/state/assist_debug_ops.gd
# Pure debug edits of assist/streak data; callers commit via AssistInventory.replace_data.
extends RefCounted

const AssistRules = preload("res://scripts/state/assist_rules.gd")
const DayClock = preload("res://scripts/state/day_clock.gd")

static func set_cycle(data: Dictionary, pos: int, today: String) -> Dictionary:
	var next := data.duplicate(true)
	var p := clampi(pos, 0, AssistRules.CYCLE_DAYS - 1)
	next.streakDays = p
	next.totalStreak = maxi(int(next.get("totalStreak", 0)), p)
	next.bestStreak = maxi(int(next.get("bestStreak", 0)), int(next.totalStreak))
	next.lastStreakDate = DayClock.shift_date(today, -1) if p > 0 else ""
	return next

static func reset_streak(data: Dictionary) -> Dictionary:
	var next := data.duplicate(true)
	next.streakDays = 0
	next.totalStreak = 0
	next.lastStreakDate = ""
	next.usedHint = 0
	next.usedPlace = 0
	return next

static func reset_stock(data: Dictionary) -> Dictionary:
	var next := data.duplicate(true)
	for kind in AssistRules.KINDS:
		next[kind] = int(AssistRules.START[kind])
	return next

static func nudge(data: Dictionary, kind: String, delta: int) -> Dictionary:
	var next := data.duplicate(true)
	next[kind] = clampi(int(next.get(kind, 0)) + delta, 0, AssistRules.CAP)
	return next
