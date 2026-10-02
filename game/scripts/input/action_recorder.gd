extends RefCounted

const MAX_DEPTH := 100

enum Source {
	USER = 0,
	SYSTEM = 1,
}

var _stack: Array = []

func push_group(actions: Array) -> void:
	if actions.is_empty():
		return
	_stack.append(actions)
	if _stack.size() > MAX_DEPTH:
		_stack.pop_front()

func pop_group() -> Array:
	if _stack.is_empty():
		return []
	return _stack.pop_back()

func can_undo() -> bool:
	return not _stack.is_empty()

func clear() -> void:
	_stack.clear()

func depth() -> int:
	return _stack.size()
