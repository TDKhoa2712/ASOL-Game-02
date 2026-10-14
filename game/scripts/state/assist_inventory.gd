# Persistent assist stock (hint, place-candy) plus the play streak that refills it.
extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")
const AssistRules = preload("res://scripts/state/assist_rules.gd")

signal changed(kind: String, count: int)
signal save_failed(reason: String)
signal streak_extended(total: int)

var data: Dictionary = AssistRules.new_data()
var _store: DualSlotStore

func _init(profile_dir: String) -> void:
	_store = DualSlotStore.new(profile_dir, "assists")
	var read := _store.read_json()
	data = AssistRules.sanitize(read.data if read.ok else {})

func count(kind: String) -> int:
	return int(data.get(kind, 0))

func try_consume(kind: String) -> bool:
	var res := AssistRules.consume(data, kind)
	if not res.ok:
		return false
	_commit(res.data, [kind])
	return true

func grant(kind: String, amount: int) -> int:
	var before := count(kind)
	_commit(AssistRules.add(data, kind, amount), [kind])
	return count(kind) - before

func on_level_won(today: String = "") -> Dictionary:
	var res := AssistRules.record_win(data, today if today != "" else AssistRules.today())
	if res.data == data:
		return {}
	_commit(res.data, res.reward.keys())
	streak_extended.emit(int(data.get("totalStreak", 0)))
	return res.reward

func streak_view(today: String = "") -> Dictionary:
	return AssistRules.streak_view(data, today if today != "" else AssistRules.today())

func _commit(next: Dictionary, kinds: Array) -> void:
	data = next
	if not _store.write_json(data):
		save_failed.emit("write_failed")
	for kind in kinds:
		changed.emit(kind, count(kind))
