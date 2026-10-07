# pool_builder.gd
class_name PoolBuilder
extends RefCounted

const PoolSourceClass = preload("res://scripts/endless/pool/pool_source.gd")

var _sources: Array = []


func register(source: RefCounted) -> void:
	_sources.append(source)
	_sources.sort_custom(func(a, b): return a.priority < b.priority)


func get_sources() -> Array:
	return _sources


func build(bank: RefCounted, config: RefCounted, size: int, rank: int, tier: String) -> Array:
	_sources.clear()

	# 1. Regular: priority 0, sequential
	if config.is_pool_enabled(&"regular"):
		var reg := PoolSourceClass.new()
		reg.source_id = &"regular"
		reg.priority = 0
		reg.inject_every = 0
		reg.apply_transform = true
		bank.load_bank(size)
		reg.levels = bank.get_levels(size, rank)
		if not reg.levels.is_empty():
			register(reg)

	# 2. LKStyle: priority 1, sequential, size >= 7
	if config.is_pool_enabled(&"lkstyle") and size >= 7:
		var lks := PoolSourceClass.new()
		lks.source_id = &"lkstyle"
		lks.priority = 1
		lks.inject_every = 0
		lks.apply_transform = true
		lks.levels = bank.get_lkstyle_levels(size, rank, tier)
		if not lks.levels.is_empty():
			register(lks)

	# 3. GC: priority 2, sequential, conditional
	if config.is_pool_enabled(&"gc"):
		var gc_levels: Array = bank.get_gc_levels(size, rank)
		if not gc_levels.is_empty():
			var gc_src := PoolSourceClass.new()
			gc_src.source_id = &"gc"
			gc_src.priority = 2
			gc_src.inject_every = 0
			gc_src.apply_transform = true
			gc_src.levels = gc_levels
			register(gc_src)

	# 4. LKModified: priority 10, inject every N
	var lk_mod_inject: int = config.get_inject_every(&"lk_modified")
	if config.is_pool_enabled(&"lk_modified") and lk_mod_inject > 0:
		var lk_mod_levels: Array = bank.get_lk_mod_levels(size, rank, false)
		if not lk_mod_levels.is_empty():
			var lkm := PoolSourceClass.new()
			lkm.source_id = &"lk_modified"
			lkm.priority = 10
			lkm.inject_every = lk_mod_inject
			lkm.apply_transform = true
			lkm.levels = lk_mod_levels
			register(lkm)

	return _sources
