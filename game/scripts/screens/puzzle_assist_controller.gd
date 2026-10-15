# Binds the assist stock to the puzzle dock: badges, place-candy, empty popup; records finished rounds.
extends RefCounted

const AssistDock = preload("res://scripts/screens/assist_dock.gd")
const AssistEmptyPopup = preload("res://scripts/screens/assist_empty_popup.gd")
const PlaceCandyAssist = preload("res://scripts/core/place_candy_assist.gd")
const PlaySession = preload("res://scripts/input/play_session.gd")

var inventory: Variant = null
var round_result: Dictionary = {}  # last recorded round on this screen; read by app_shell's StreakFlow
var streak_source: Variant = null  # inventory that records the streak; set even for custom levels
var popup: AssistEmptyPopup = null
var _screen: Control = null
var _hint_btn: Button = null
var _place_btn: Button = null

func setup(screen: Control, hint_btn: Button, place_btn: Button) -> void:
	_screen = screen; _hint_btn = hint_btn; _place_btn = place_btn
	if popup == null:
		popup = AssistEmptyPopup.new()
		screen.add_child(popup)
		popup.ad_pressed.connect(func(): AssistDock.show_toast(_screen, _screen.tr("assist.coming_soon")))

func bind(inv: Variant, coordinator: Variant, streak_inv: Variant = null) -> void:
	inventory = inv
	streak_source = streak_inv if streak_inv != null else inv
	if _place_btn != null: _place_btn.visible = inventory != null
	if coordinator != null: coordinator.inventory = inventory
	if inventory == null:
		return
	if coordinator != null and not coordinator.stock_empty.is_connected(popup.open):
		coordinator.stock_empty.connect(popup.open)
	if not inventory.changed.is_connected(_on_changed):
		inventory.changed.connect(_on_changed)
	_on_changed("hint", inventory.count("hint"))
	_on_changed("place", inventory.count("place"))

func on_place(session: Variant, coordinator: Variant) -> void:
	if inventory == null or session == null or session.phase != PlaySession.Phase.ACTIVE:
		return
	if inventory.count("place") <= 0:
		popup.open("place")
		return
	var lvl: Dictionary = session.level
	var cell := PlaceCandyAssist.pick_cell(session.board, int(lvl["size"]), lvl["regions"], lvl["solution"])
	if cell.is_empty() or not inventory.try_consume("place"):
		return
	coordinator.place_candy(session, cell)

# Records the finished round; returns {extended, view, reward} for the streak screens, {} when skipped.
# Custom/debug levels are skipped unless the session-only debug switch is on.
func on_round_finished(session: Variant, is_custom: bool) -> Dictionary:
	round_result = {}
	var inv: Variant = streak_source if streak_source != null else inventory
	if inv == null or session == null or (is_custom and not inv.debug_counts_custom):
		return round_result
	round_result = inv.on_round_finished()
	return round_result

func _on_changed(kind: String, count: int) -> void:
	var btn := _hint_btn if kind == "hint" else _place_btn
	if btn != null: AssistDock.set_badge(btn, count)

