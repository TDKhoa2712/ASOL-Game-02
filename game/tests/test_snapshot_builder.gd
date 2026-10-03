extends SceneTree

const SnapshotBuilder = preload("res://scripts/campaign/snapshot_builder.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_build_keys()
	_test_restore_round_trip()
	_test_restore_partial_snap()
	if _fails.is_empty():
		print("SNAPSHOT_BUILDER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_build_keys() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "AABB", "CCDD", "CCDD"],
		"solution": [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
		"givens": [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"seed": 42,
	}
	var entry := {"rank": 2, "index": 5, "transform": 0}
	var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]
	var snap := SnapshotBuilder.build("L05", level, entry, palette)
	for key in ["level_id", "size", "rank", "bank_index", "transform_id", "regions", "solution", "givens", "zone_colors", "zone_overlays", "hearts_start", "seed", "shape_hash"]:
		_assert(snap.has(key), "build has key: " + key)
	_assert(snap.level_id == "L05", "level_id correct")
	_assert(snap.size == 4, "size correct")
	_assert(snap.rank == 2, "rank correct")
	_assert(snap.hearts_start == 3, "hearts_start is 3")
	_assert(snap.shape_hash != "", "shape_hash not empty")

func _test_restore_round_trip() -> void:
	var level := {
		"size": 4,
		"regions": ["AABB", "AABB", "CCDD", "CCDD"],
		"solution": [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
		"givens": [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"seed": 7,
	}
	var entry := {"rank": 1, "index": 0, "transform": 0}
	var palette: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]
	var snap := SnapshotBuilder.build("L01", level, entry, palette)
	var restored := SnapshotBuilder.restore_level(snap)
	_assert(restored.size == 4, "restored size")
	_assert(restored.regions == level.regions, "restored regions")
	_assert(restored.solution == level.solution, "restored solution")
	_assert(restored.seed == 7, "restored seed")
	_assert(restored.id == "L01", "restored id")

func _test_restore_partial_snap() -> void:
	var snap := {"level_id": "L99", "size": 5}
	var restored := SnapshotBuilder.restore_level(snap)
	_assert(restored.size == 5, "partial snap size")
	_assert(restored.regions == [], "partial snap regions empty")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
