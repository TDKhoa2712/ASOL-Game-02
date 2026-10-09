# candy_atlas.gd — Loads and caches the mascot sprite atlas and its frame metadata.
extends RefCounted

const PNG_PATH := "res://assets/candy/anim/mascot_atlas.png"
const JSON_PATH := "res://assets/candy/anim/mascot_atlas.json"

static var _tex: Texture2D = null
static var _meta: Dictionary = {}
static var _frames: Dictionary = {}
static var _size := Vector2(128, 128)
static var _tried := false

static func reset() -> void:
	_tex = null; _meta = {}; _frames = {}; _tried = false

static func ensure_loaded(png_path := PNG_PATH, json_path := JSON_PATH) -> bool:
	if _tried: return _tex != null
	_tried = true
	if not ResourceLoader.exists(png_path) or not FileAccess.file_exists(json_path): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not data is Dictionary or not data.get("anims") is Dictionary: return false
	var fs: Array = data.get("frame_size", [128, 128])
	_size = Vector2(fs[0], fs[1])
	for anim in data.anims:
		var info: Dictionary = data.anims[anim]
		_frames[anim] = info.get("frames", [])
		_meta[anim] = {"fps": int(info.get("fps", 12)), "loop": bool(info.get("loop", false)), "count": _frames[anim].size()}
	_tex = load(png_path) as Texture2D
	if _tex == null: _meta = {}; _frames = {}
	return _tex != null

static func texture() -> Texture2D: return _tex
static func meta() -> Dictionary: return _meta

static func frame_rect(anim: String, frame: int) -> Rect2:
	var list: Array = _frames.get(anim, [])
	if frame < 0 or frame >= list.size(): return Rect2()
	return Rect2(Vector2(list[frame][0], list[frame][1]), _size)
