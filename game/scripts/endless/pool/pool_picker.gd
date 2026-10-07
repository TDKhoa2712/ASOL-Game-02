# pool_picker.gd
class_name PoolPicker
extends RefCounted


static func pick_at(sources: Array, pos: Dictionary) -> Dictionary:
	var inject_counters: Dictionary = pos.get("inject_counters", {})
	var main_idx: int = int(pos.get("main_idx", 0))

	# 1. Check injection sources (inject_every > 0)
	for src in sources:
		var every: int = int(src.inject_every)
		if every > 0 and not src.levels.is_empty():
			var s_id: String = str(src.source_id)
			var counter: Dictionary = inject_counters.get(s_id, {})
			var since: int = int(counter.get("since", 0))
			var idx: int = int(counter.get("idx", 0))
			if since >= every:
				var chosen_idx: int = idx % src.levels.size()
				var level_raw: Dictionary = src.levels[chosen_idx]
				var level_dict: Dictionary = level_raw.duplicate(true)
				level_dict["_source"] = src.source_id
				level_dict["_apply_transform"] = src.apply_transform
				level_dict["_is_injection"] = true
				return level_dict

	# 2. Sequential sources (inject_every == 0) in priority order
	var seq_sources: Array = []
	var total_seq: int = 0
	for src in sources:
		if int(src.inject_every) == 0 and not src.levels.is_empty():
			seq_sources.append(src)
			total_seq += src.levels.size()

	if total_seq == 0:
		return {}

	var effective_idx: int = main_idx % total_seq
	var accumulated: int = 0
	for src in seq_sources:
		var count: int = src.levels.size()
		if effective_idx < accumulated + count:
			var local_idx: int = effective_idx - accumulated
			var level_raw: Dictionary = src.levels[local_idx]
			var level_dict: Dictionary = level_raw.duplicate(true)

			level_dict["_source"] = src.source_id
			level_dict["_apply_transform"] = src.apply_transform
			level_dict["_is_injection"] = false
			return level_dict
		accumulated += count

	return {}
