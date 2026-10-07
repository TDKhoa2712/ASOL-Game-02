extends SceneTree

const PoolSource = preload("res://scripts/endless/pool/pool_source.gd")
const PoolBuilder = preload("res://scripts/endless/pool/pool_builder.gd")
const PoolPicker = preload("res://scripts/endless/pool/pool_picker.gd")
const EndlessConfig = preload("res://scripts/endless/endless_config.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_pool_source_data()
	_test_pool_builder_sorts_by_priority()
	_test_pool_builder_with_real_bank()
	_test_pool_picker_sequential()
	_test_pool_picker_injection()
	if _fails.is_empty():
		print("POOL_REGISTRY_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_pool_source_data() -> void:
	var src = PoolSource.new()
	src.source_id = &"test"
	src.priority = 5
	src.inject_every = 4
	src.apply_transform = true
	src.levels = [{"id": 1}]
	_assert(src.source_id == &"test", "source_id")
	_assert(src.priority == 5, "priority")
	_assert(src.inject_every == 4, "inject_every")
	_assert(src.levels.size() == 1, "levels")

func _test_pool_builder_sorts_by_priority() -> void:
	var builder = PoolBuilder.new()
	var s1 = PoolSource.new()
	s1.source_id = &"p10"
	s1.priority = 10
	var s2 = PoolSource.new()
	s2.source_id = &"p0"
	s2.priority = 0

	builder.register(s1)
	builder.register(s2)
	var sources: Array = builder.get_sources()
	_assert(sources.size() == 2, "2 sources registered")
	_assert(sources[0].source_id == &"p0", "p0 sorted first")
	_assert(sources[1].source_id == &"p10", "p10 sorted second")

func _test_pool_builder_with_real_bank() -> void:
	var bank = BankReader.new()
	var cfg = EndlessConfig.default_config()
	var builder = PoolBuilder.new()

	var sources: Array = builder.build(bank, cfg, 8, 2, "N")
	_assert(sources.size() >= 2, "at least regular and lkstyle built for 8x8")
	_assert(sources[0].source_id == &"regular", "regular is first")

func _test_pool_picker_sequential() -> void:
	var s1 = PoolSource.new()
	s1.source_id = &"regular"
	s1.priority = 0
	s1.levels = [{"id": "r0"}, {"id": "r1"}]

	var s2 = PoolSource.new()
	s2.source_id = &"lkstyle"
	s2.priority = 1
	s2.levels = [{"id": "lk0"}]

	var sources: Array = [s1, s2]
	var entry0: Dictionary = PoolPicker.pick_at(sources, {"main_idx": 0, "inject_counters": {}})
	_assert(entry0.get("id") == "r0", "pick index 0 is r0")
	_assert(entry0.get("_source") == &"regular", "source is regular")

	var entry2: Dictionary = PoolPicker.pick_at(sources, {"main_idx": 2, "inject_counters": {}})
	_assert(entry2.get("id") == "lk0", "pick index 2 is lk0")
	_assert(entry2.get("_source") == &"lkstyle", "source is lkstyle")

func _test_pool_picker_injection() -> void:
	var s1 = PoolSource.new()
	s1.source_id = &"regular"
	s1.priority = 0
	s1.levels = [{"id": "r0"}, {"id": "r1"}]

	var s_inj = PoolSource.new()
	s_inj.source_id = &"lk_mod"
	s_inj.priority = 10
	s_inj.inject_every = 4
	s_inj.levels = [{"id": "inj0"}]

	var sources: Array = [s1, s_inj]
	# since < 4 -> sequential
	var e_seq: Dictionary = PoolPicker.pick_at(sources, {"main_idx": 0, "inject_counters": {"lk_mod": {"idx": 0, "since": 2}}})
	_assert(e_seq.get("id") == "r0", "not yet injected")

	# since >= 4 -> injection triggers
	var e_inj: Dictionary = PoolPicker.pick_at(sources, {"main_idx": 0, "inject_counters": {"lk_mod": {"idx": 0, "since": 4}}})
	_assert(e_inj.get("id") == "inj0", "injection triggers at since=4")
	_assert(e_inj.get("_source") == &"lk_mod", "source is lk_mod")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)
