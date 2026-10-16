extends SceneTree

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const Strip = preload("res://scripts/screens/streak_cycle_strip.gd")
const Gift = preload("res://scripts/screens/gift_box_view.gd")
var failures: Array[String] = []

func _init() -> void:
	LayoutTokens.motion_enabled = false
	var strip: StreakCycleStrip = Strip.new()
	root.add_child(strip)
	check(strip.cells.size() == 7, "seven cells")
	check(strip.gift_box is GiftBoxView, "gift box lives in the strip")
	check(strip.gift_box.get_parent() != null and strip.cells[6].is_ancestor_of(strip.gift_box), "gift in last cell")

	strip.show_view({"count": 0, "cycle_done": 0, "kept_today": false})
	check(_states(strip) == ["today", "todo", "todo", "todo", "todo", "todo", "todo"], "fresh profile")
	strip.show_view({"count": 3, "cycle_done": 2, "kept_today": false})
	check(_states(strip) == ["done", "done", "today", "todo", "todo", "todo", "todo"], "at risk: next cell is today")
	check(strip.today_index() == 2, "today index")
	strip.fill_today_animated()
	check(strip.cell_state(2) == "done" and strip.today_index() == -1, "fill today marks it done")
	strip.fill_today_animated()
	check(strip.cell_state(3) == "todo", "second fill is a no-op")
	strip.show_view({"count": 3, "cycle_done": 3, "kept_today": true})
	check(_states(strip) == ["done", "done", "done", "todo", "todo", "todo", "todo"], "kept today")
	strip.show_view({"count": 7, "cycle_done": 7, "kept_today": true})
	check(_states(strip).count("done") == 7 and strip.today_index() == -1, "gift day fills all")
	strip.show_view({"count": 6, "cycle_done": 6, "kept_today": false})
	check(strip.cell_state(6) == "today", "day 7 pending is today")
	strip.show_view({})
	check(_states(strip)[0] == "today", "empty view is safe")

	var box: GiftBoxView = Gift.create()
	root.add_child(box)
	var got := [false]
	box.opened.connect(func(): got[0] = true)
	box.play_idle()
	check(not box.is_open, "idle is closed")
	box.play_open()
	check(got[0] and box.is_open, "open emits opened (no motion)")

	strip.queue_free(); box.queue_free()
	if failures.is_empty():
		print("STREAK_STRIP_PASS"); quit(0)
	else:
		for f in failures: printerr(f)
		quit(1)

func _states(strip: StreakCycleStrip) -> Array:
	var out := []
	for i in 7: out.append(strip.cell_state(i))
	return out

func check(cond: bool, label: String) -> void:
	if not cond: failures.append(label)
