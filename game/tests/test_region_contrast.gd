extends SceneTree

const RegionPainter = preload("res://scripts/content/region_painter.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")

const SAMPLES_PER_BANK := 40

var _fails: Array[String] = []

func _init() -> void:
	_test_palette_has_no_near_duplicates()
	_test_adjacent_regions_contrast_on_banks()
	if _fails.is_empty():
		print("REGION_CONTRAST_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_palette_has_no_near_duplicates() -> void:
	var p := Palette.ZONE_COLORS
	for i in range(p.size()):
		for j in range(i + 1, p.size()):
			var d := RegionPainter.lab_distance(p[i], p[j])
			_assert(d >= 12.0, "palette %d/%d too similar (dE=%.1f)" % [i, j, d])

func _test_adjacent_regions_contrast_on_banks() -> void:
	var bank := BankReader.new()
	for n in range(4, 13):
		bank.load_bank(n)
		var checked := 0
		for rank in range(1, 30):
			for idx in range(4):
				if checked >= SAMPLES_PER_BANK:
					break
				var lvl: Dictionary = bank.get_level(n, rank, idx)
				if lvl.is_empty():
					continue
				checked += 1
				_check_level(n, lvl["regions"], "%dx%d r%d i%d" % [n, n, rank, idx])
		_assert(checked > 0, "no levels sampled for %dx%d" % [n, n])

func _check_level(n: int, regions: Array, tag: String) -> void:
	var colors := RegionPainter.assign_colors(n, regions, Palette.ZONE_COLORS)
	var grid := RegionPainter.precompute_grid(n, regions)
	for r in range(n):
		for c in range(n):
			for d in [[1, 0], [0, 1]]:
				var nr: int = r + d[0]
				var nc: int = c + d[1]
				if nr >= n or nc >= n or grid[r][c] == grid[nr][nc]:
					continue
				var de := RegionPainter.lab_distance(colors[grid[r][c]], colors[grid[nr][nc]])
				if de < RegionPainter.MIN_ADJACENT_CONTRAST:
					_fails.append("%s: zones %s/%s adjacent dE=%.1f" % [tag, grid[r][c], grid[nr][nc], de])
					return

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)
