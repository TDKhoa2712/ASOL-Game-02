extends SceneTree

const SpecialProvider = preload("res://scripts/endless/provider/special_provider.gd")
const SuperHardProvider = preload("res://scripts/endless/provider/super_hard_provider.gd")
const SingleRegionProvider = preload("res://scripts/endless/provider/single_region_provider.gd")
const SpTtProvider = preload("res://scripts/endless/provider/sp_tt_provider.gd")
const OneFishProvider = preload("res://scripts/endless/provider/onefish_provider.gd")
const EndlessConfig = preload("res://scripts/endless/endless_config.gd")
const EndlessProgress = preload("res://scripts/endless/endless_progress.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_special_provider()
	_test_super_hard_provider()
	_test_single_region_provider()
	_test_sp_tt_provider()
	_test_onefish_provider()
	if _fails.is_empty():
		print("PROVIDERS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_special_provider() -> void:
	var cfg = EndlessConfig.default_config()
	var bank = BankReader.new()
	var sp = SpecialProvider.new(cfg)

	_assert(sp.is_available(10, false), "level 10 is milestone")
	_assert(not sp.is_available(11, false), "level 11 is not milestone")
	_assert(not sp.is_available(35, true), "super hard overrides milestone")

	var e10: Dictionary = sp.get_entry(10, bank)
	_assert(not e10.is_empty(), "level 10 returns entry")
	_assert(e10.get("_source") == &"sp", "source is sp")

	var e200: Dictionary = sp.get_entry(200, bank)
	_assert(not e200.is_empty(), "level 200 returns entry")
	_assert(e200.get("_source") == &"lk", "source is lk")

func _test_super_hard_provider() -> void:
	var cfg = EndlessConfig.default_config()
	var bank = BankReader.new()
	var sh = SuperHardProvider.new(cfg)

	_assert(not sh.is_super_hard(25), "level 25 is not super hard (< 35)")
	_assert(sh.is_super_hard(35), "level 35 is super hard")
	_assert(not sh.is_super_hard(36), "level 36 is not super hard")
	_assert(sh.is_super_hard(45), "level 45 is super hard")

	var entry35: Dictionary = sh.get_entry(35, bank)
	_assert(not entry35.is_empty(), "level 35 returns entry")
	_assert(entry35.get("_source") == &"super_hard", "source is super_hard")
	_assert(int(entry35.get("size", 0)) == 11, "super hard size is 11")

func _test_single_region_provider() -> void:
	var cfg = EndlessConfig.default_config()
	var bank = BankReader.new()
	var prog = EndlessProgress.new()
	var srp = SingleRegionProvider.new(cfg)

	_assert(srp.is_available(), "single_region enabled by default")
	var entry: Dictionary = srp.get_entry(8, 3, bank, prog)
	_assert(not entry.is_empty(), "returns single region entry")
	_assert(entry.get("_source") == &"single_region", "source is single_region")

func _test_sp_tt_provider() -> void:
	var cfg = EndlessConfig.default_config()
	var bank = BankReader.new()
	var prog = EndlessProgress.new()
	var stp = SpTtProvider.new(cfg)

	_assert(not stp.is_available(), "sp_tt disabled by default")
	cfg.sp_tt_enabled = true
	_assert(stp.is_available(), "sp_tt enabled when toggle on")

	var entry: Dictionary = stp.get_entry(8, 2, bank, prog)
	# might return entry or empty depending on category availability
	_assert(entry is Dictionary, "sp_tt get_entry returns dict")

func _test_onefish_provider() -> void:
	var cfg = EndlessConfig.default_config()
	var bank = BankReader.new()
	var prog = EndlessProgress.new()
	var ofp = OneFishProvider.new(cfg)

	_assert(not ofp.is_available(), "onefish disabled by default")
	cfg.onefish_enabled = true
	_assert(ofp.is_available(), "onefish enabled when toggle on")

	var entry: Dictionary = ofp.get_entry(8, 3, bank, prog)
	_assert(not entry.is_empty(), "returns onefish entry")
	_assert(entry.get("_source") == &"onefish", "source is onefish")

func _assert(cond: bool, label: String) -> void:
	if not cond:
		_fails.append("FAIL: " + label)
