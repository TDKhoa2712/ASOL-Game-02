extends RefCounted

const ShapeFingerprint = preload("res://scripts/content/shape_fingerprint.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")

static func build(label: String, level: Dictionary, entry: Dictionary, palette: Array[Color]) -> Dictionary:
	var n: int = int(level.get("size", 4))
	var regions: Array = level.get("regions", [])
	var colors := RegionPainter.assign_colors(n, regions, palette)
	var color_hex: Dictionary = {}
	for zone_key in colors:
		color_hex[zone_key] = (colors[zone_key] as Color).to_html()
	return {
		"level_id": label,
		"size": n,
		"rank": int(entry.get("rank", 1)),
		"bank_index": int(entry.get("index", 0)),
		"transform_id": int(entry.get("transform", 0)),
		"regions": regions.duplicate(true),
		"solution": level.get("solution", []).duplicate(true),
		"givens": level.get("givens", []).duplicate(true),
		"zone_colors": color_hex,
		"zone_overlays": {},
		"hearts_start": 3,
		"seed": int(level.get("seed", 0)),
		"shape_hash": ShapeFingerprint.compute(n, regions),
	}

static func restore_level(snap: Dictionary) -> Dictionary:
	return {
		"size": snap.get("size", 4),
		"regions": snap.get("regions", []).duplicate(true),
		"solution": snap.get("solution", []).duplicate(true),
		"givens": snap.get("givens", []).duplicate(true),
		"seed": snap.get("seed", 0),
		"id": snap.get("level_id", ""),
	}
