extends RefCounted

const BoardTransform = preload("res://scripts/content/board_transform.gd")

static func compute(size: int, regions: Array) -> String:
	var smallest := ""
	for t in range(BoardTransform.TRANSFORM_COUNT):
		var transformed: Array = BoardTransform.transform_regions(regions, size, t)
		var normalized := _remap_labels(transformed, size)
		var serialized := "|".join(normalized)
		if smallest.is_empty() or serialized < smallest:
			smallest = serialized
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(smallest.to_utf8_buffer())
	var hex := ctx.finish().hex_encode()
	return "%dx%d_%s" % [size, size, hex.substr(0, 16)]

static func _remap_labels(regions: Array, size: int) -> Array[String]:
	var mapping: Dictionary = {}
	var next_id: int = 0
	var result: Array[String] = []
	for r in range(size):
		var row_str := str(regions[r])
		var new_row := ""
		for c in range(size):
			var ch: String = row_str[c] if c < row_str.length() else ""
			if not mapping.has(ch):
				mapping[ch] = String.chr(65 + next_id)
				next_id += 1
			new_row += mapping[ch]
		result.append(new_row)
	return result
