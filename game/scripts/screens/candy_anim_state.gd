# candy_anim_state.gd — Pure per-cell animation state for board candies (no nodes).
extends RefCounted

const MAX_CONCURRENT_IDLE := 6

var motion: bool = true
var idle_min := 2.5
var idle_max := 5.0
var _meta: Dictionary
var _cells: Dictionary = {} # Vector2i -> {anim, t, playing, wait, done, cycle}

func _init(meta: Dictionary) -> void:
	_meta = meta

func clear() -> void:
	_cells.clear()

func sync(board: Array) -> void:
	_cells.clear()
	for r in board.size():
		for c in board[r].size():
			var k: int = int(board[r][c])
			if k == 2 or k == 4: rest(Vector2i(r, c)) # CellKind.CANDY / GIVEN

func rest(cell: Vector2i) -> void:
	var cycle: int = _cells[cell].cycle + 1 if _cells.has(cell) else 0
	_cells[cell] = {"anim": "idle", "t": 0.0, "playing": false, "wait": _idle_wait(cell, cycle), "done": false, "cycle": cycle}

func play(cell: Vector2i, anim: String, delay: float = 0.0) -> void:
	if not _meta.has(anim): return
	if not motion:
		if anim == "appear" or anim == "error": rest(cell)
		else: _cells[cell] = {"anim": anim, "t": 0.0, "playing": false, "wait": 0.0, "done": anim == "win", "cycle": 0}
		return
	_cells[cell] = {"anim": anim, "t": 0.0, "playing": delay <= 0.0, "wait": delay, "done": false, "cycle": 0}

func play_all(anim: String, row_delay: float = 0.0) -> void:
	for cell in _cells.keys():
		play(cell, anim, cell.x * row_delay)

func frame_of(cell: Vector2i) -> Array:
	if not _cells.has(cell): return ["idle", 0]
	var e: Dictionary = _cells[cell]
	return [e.anim, _frame(e)]

func idle_playing_count() -> int:
	var n := 0
	for e in _cells.values():
		if e.anim == "idle" and e.playing: n += 1
	return n

func tick(delta: float, motion_now: bool, visible: bool) -> bool:
	var changed := false
	if motion_now != motion: set_motion(motion_now); changed = true
	return advance(delta, visible) or changed

func set_motion(enabled: bool) -> void:
	motion = enabled
	for cell in _cells.keys():
		var e: Dictionary = _cells[cell]
		if enabled:
			if e.anim == "sad": e.playing = true; e.t = 0.0
		elif e.anim == "win": e.playing = false; e.done = true
		elif e.anim == "sad": e.playing = false
		elif e.playing or e.anim != "idle": rest(cell)

func advance(delta: float, active: bool) -> bool:
	if not active or not motion or _cells.is_empty(): return false
	var changed := false
	var idle_slots := MAX_CONCURRENT_IDLE - idle_playing_count()
	for cell in _cells.keys():
		var e: Dictionary = _cells[cell]
		var before := _frame(e)
		if not e.playing:
			if e.done or e.anim == "sad": continue
			e.wait -= delta
			if e.wait > 0.0: continue
			if e.anim == "idle":
				if idle_slots <= 0: continue
				idle_slots -= 1
			e.playing = true; e.t = 0.0
			changed = changed or _frame(e) != before
			continue
		e.t += delta
		var info: Dictionary = _meta[e.anim]
		if not info.loop and e.t * info.fps >= info.count:
			if e.anim == "win":
				e.playing = false; e.done = true
			else:
				rest(cell); changed = true; continue
		if _frame(e) != before: changed = true
	return changed

func _frame(e: Dictionary) -> int:
	var info: Dictionary = _meta[e.anim]
	if not e.playing: return info.count - 1 if e.done else 0
	var f := int(e.t * info.fps)
	return f % info.count if info.loop else mini(f, info.count - 1)

func _idle_wait(cell: Vector2i, cycle: int) -> float:
	var h := posmod(cell.x * 7919 + cell.y * 104729 + cycle * 1299709, 1000)
	return idle_min + (idle_max - idle_min) * float(h) / 1000.0
