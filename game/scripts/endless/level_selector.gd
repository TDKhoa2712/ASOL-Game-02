# level_selector.gd
class_name LevelSelector
extends RefCounted

const ControlStrategyClass = preload("res://scripts/endless/strategy/control_strategy.gd")
const SettlementHandlerClass = preload("res://scripts/endless/settlement/settlement_handler.gd")

var _bank: RefCounted
var _config: RefCounted
var _progress: RefCounted

var _strategy: RefCounted
var _settlement: RefCounted


func _init(bank: RefCounted, config: RefCounted, progress: RefCounted) -> void:
	_bank = bank
	_config = config
	_progress = progress

	_strategy = ControlStrategyClass.new(_config)
	_settlement = SettlementHandlerClass.new()


func select_next_level() -> Dictionary:
	var request := {
		"bank": _bank,
		"config": _config,
		"progress": _progress,
		"level_num": _progress.get_level_num() if _progress != null else 1,
	}
	return _strategy.select(request)


func on_level_complete(result: Dictionary) -> void:
	if _settlement != null and _progress != null and _config != null:
		_settlement.on_level_complete(result, _progress, _config)


func get_bank() -> RefCounted:
	return _bank


func get_config() -> RefCounted:
	return _config


func get_progress() -> RefCounted:
	return _progress
