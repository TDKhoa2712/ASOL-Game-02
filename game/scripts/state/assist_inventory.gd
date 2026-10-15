# Persistent assist stock (hint, place-candy) plus the play streak that refills it.
extends RefCounted

const DualSlotStore = preload("res://scripts/state/dual_slot_store.gd")
const AssistRules = preload("res://scripts/state/assist_rules.gd")

signal changed(kind: String, count: int)
signal save_failed(reason: String)

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

# Any finished round (won or lost) keeps the streak; future modes call this too.
# Returns {extended, view, reward}; reward is {hint, place} on day 7, else {}.
func on_round_finished(today: String = "") -> Dictionary:
	var day := today if today != "" else AssistRules.today()
	var res := AssistRules.record_win(data, day)
	var extended: bool = res.data != data
	if extended:
		_commit(res.data, res.reward.keys())
	return {"extended": extended, "view": AssistRules.streak_view(data, day), "reward": res.reward}

func streak_view(today: String = "") -> Dictionary:
	return AssistRules.streak_view(data, today if today != "" else AssistRules.today())

func _commit(next: Dictionary, kinds: Array) -> void:
	data = next
	if not _store.write_json(data):
		save_failed.emit("write_failed")
	for kind in kinds:
		changed.emit(kind, count(kind))
