extends SceneTree

const ShapeFingerprint = preload("res://scripts/content/shape_fingerprint.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_identity_fingerprint()
	_test_d4_variants_same_fingerprint()
	_test_different_topology_different_fingerprint()
	_test_label_swap_same_fingerprint()
	_test_format()
	_test_5x5()
	if _fails.is_empty():
		print("SHAPE_FINGERPRINT_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_identity_fingerprint() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var fp := ShapeFingerprint.compute(4, regions)
	_assert(fp.length() > 0, "fingerprint not empty")
	var fp2 := ShapeFingerprint.compute(4, regions)
	_assert(fp == fp2, "same input same fingerprint")

func _test_d4_variants_same_fingerprint() -> void:
	var regions := ["AABB", "ABBB", "CCBB", "CCDB"]
	var base_fp := ShapeFingerprint.compute(4, regions)
	for t in range(1, 8):
		var transformed := BoardTransform.transform_regions(regions, 4, t)
		var fp := ShapeFingerprint.compute(4, transformed)
		_assert(fp == base_fp, "D4 variant t=%d must match base fingerprint" % t)

func _test_different_topology_different_fingerprint() -> void:
	var r1 := ["AABB", "ABBB", "CCBB", "CCDB"]
	var r2 := ["ABBC", "ABBC", "ADDC", "ADDC"]
	_assert(ShapeFingerprint.compute(4, r1) != ShapeFingerprint.compute(4, r2), "different topology must differ")

func _test_label_swap_same_fingerprint() -> void:
	# Relabel A<->C in r1: same topology, different labels
	var r1 := ["AABB", "ABBB", "CCBB", "CCDB"]
	var r_swap: Array = []
	for row_str in r1:
		var new_row := ""
		for i in range(row_str.length()):
			var ch: String = row_str[i]
			if ch == "A":
				new_row += "C"
			elif ch == "C":
				new_row += "A"
			else:
				new_row += ch
		r_swap.append(new_row)
	_assert(ShapeFingerprint.compute(4, r1) == ShapeFingerprint.compute(4, r_swap), "label swap same fingerprint")

func _test_format() -> void:
	var fp := ShapeFingerprint.compute(4, ["AABB", "ABBB", "CCBB", "CCDB"])
	_assert(fp.begins_with("4x4_"), "format starts with size prefix")
	_assert(fp.length() == 4 + 16, "format: NxN_ (4 chars) + 16 hex chars = 20 total")

func _test_5x5() -> void:
	var r5 := ["AABBC", "ADBBC", "DDDEC", "DFEEC", "FFEEE"]
	var fp := ShapeFingerprint.compute(5, r5)
	_assert(fp.begins_with("5x5_"), "5x5 format")
	_assert(fp.length() == 4 + 16, "5x5 length correct")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
