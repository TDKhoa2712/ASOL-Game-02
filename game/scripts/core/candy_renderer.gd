extends RefCounted

const CandyPalette = preload("res://scripts/theme/candy_palette.gd")
const ASSET_DIR := "res://assets/candy/"

static var _cache: Dictionary = {}

static func texture_for_type(candy_type: String) -> Texture2D:
	var resolved := candy_type if CandyPalette.CANDY_TYPES.has(candy_type) else "bonbon"
	var path := ASSET_DIR + resolved + ".png"
	if not ResourceLoader.exists(path):
		path = ASSET_DIR + resolved + ".svg"
	if not ResourceLoader.exists(path):
		path = ASSET_DIR + "candy_icon.png"
	if not ResourceLoader.exists(path):
		path = "res://assets/ui/board/candy.svg"
	var texture := load(path) as Texture2D
	_cache[resolved] = texture
	return texture

static func type_for_level(level_index: int) -> String:
	if level_index < 0 or level_index >= 30:
		return "bonbon"
	return CandyPalette.CANDY_TYPES[int(level_index / 5.0)]

static func type_for_label(label: String) -> String:
	if not label.begins_with("L") or not label.substr(1).is_valid_int():
		return "bonbon"
	var number := int(label.substr(1))
	return type_for_level(number - 1) if number >= 1 and number <= 30 else "bonbon"
