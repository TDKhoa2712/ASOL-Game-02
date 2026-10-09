# combo_feedback.gd — joins the combo streak to its voice cue and word-art popup.
extends RefCounted

const ComboTracker = preload("res://scripts/feedback/combo_tracker.gd")
const ComboPopup = preload("res://scripts/screens/combo_popup.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const WIDTH_SHARE := 0.8 # word art spans at most this share of the board width
const RISE := 0.4 # popup centre sits this many cell heights above the cell top

var tracker := ComboTracker.new()
var popup: ComboPopup
var _board: Control
var _sfx: Variant

func bind(board: Control, sfx: Variant) -> void:
	_sfx = sfx
	if board == _board: return
	_board = board
	popup = ComboPopup.new()
	board.add_child(popup)

func reset() -> void:
	tracker.reset()
	if popup != null: popup.hide_combo()

# Returns the combo level shown, or 0 when the candy came from a hint.
func on_candy(row: int, col: int, from_hint: bool) -> int:
	if from_hint:
		reset()
		if _sfx != null: _sfx.play(SfxCatalog.Effect.CANDY_YES)
		return 0
	var level := tracker.on_correct()
	if _sfx != null: _sfx.play(SfxCatalog.combo_effect(level))
	if popup != null and _board != null:
		var width := _board.size.x
		var base_scale := minf(1.0, width * WIDTH_SHARE / ComboPopup.FRAME.x)
		var half := ComboPopup.FRAME * base_scale * 0.5
		var cell: Rect2 = _board.get_cell_rect(row, col)
		var at := Vector2(clampf(cell.get_center().x, half.x, maxf(half.x, width - half.x)),
			maxf(cell.position.y - cell.size.y * RISE, half.y))
		popup.show_combo(level, at, base_scale)
	return level
