extends RefCounted

const BoardTransform = preload("res://scripts/content/board_transform.gd")

var _size: int
var _rank: int
var _bank_count: int
var _index: int = 0
var _transform: int = 0

func _init(size: int, rank: int, bank_count: int) -> void:
	_size = size
	_rank = rank
	_bank_count = maxi(0, bank_count)

func current() -> Dictionary:
	return {"size": _size, "rank": _rank, "index": _index, "transform": _transform}

func advance() -> Dictionary:
	if _bank_count == 0:
		return current()
	_index += 1
	if _index >= _bank_count:
		_index = 0
		_transform = (_transform + 1) % BoardTransform.TRANSFORM_COUNT
	return current()

func set_position(index: int, transform: int = 0) -> void:
	_index = clampi(index, 0, maxi(0, _bank_count - 1))
	_transform = clampi(transform, 0, BoardTransform.TRANSFORM_COUNT - 1)

func effective_plays() -> int:
	return _bank_count * BoardTransform.TRANSFORM_COUNT

func to_dict() -> Dictionary:
	return current()

static func from_dict(data: Dictionary, bank_count: int) -> RefCounted:
	var script = load("res://scripts/campaign/bank_cursor.gd") as GDScript
	var cursor = script.new(int(data.get("size", 0)), int(data.get("rank", 0)), bank_count)
	cursor.set_position(int(data.get("index", 0)), int(data.get("transform", 0)))
	return cursor
