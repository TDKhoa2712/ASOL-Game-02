extends SceneTree

const TutorialTips = preload("res://scripts/campaign/tutorial_tips.gd")
const TutorialGuide = preload("res://scripts/campaign/tutorial_guide.gd")

var _fails: Array[String] = []

func _init() -> void:
	var guide := TutorialGuide.new(null)
	var tip := TutorialTips.tip_for("mistake", {"hearts": 2}, guide)
	_assert(tip.id == "C-err" and tip.args == {"n": 2}, "first mistake explains the red X")
	guide.mark_seen("C-err")
	_assert(TutorialTips.tip_for("mistake", {"hearts": 2}, guide).is_empty(), "each tip shows once")
	_assert(TutorialTips.tip_for("mistake", {"hearts": 1}, guide).id == "C-heart1", "last heart warning")
	_assert(TutorialTips.tip_for("undo_blocked", {}, guide).id == "C-undo", "undo barrier tip")
	_assert(TutorialTips.tip_for("level_start", {"label": "L04", "size": 5}, guide).id == "C-size5", "first 5x5 board")
	_assert(TutorialTips.tip_for("level_start", {"label": "L03", "size": 4}, guide).is_empty(), "4x4 needs no tip")
	_assert(TutorialTips.tip_for("level_start", {"label": "L19", "size": 6}, TutorialGuide.new(null)).id == "C-s3", "first S3 level")
	var idle := TutorialTips.tip_for("idle", {"hints_used": 0}, guide)
	_assert(idle.id == "C-idle" and idle.bounce_hint and idle.text.is_empty(), "idle only bounces the hint button")
	_assert(TutorialTips.tip_for("idle", {"hints_used": 1}, TutorialGuide.new(null)).is_empty(), "no idle nudge after a hint")
	if _fails.is_empty():
		print("TUTORIAL_TIPS_PASS")
		quit(0)
	else:
		for f in _fails: printerr(f)
		quit(1)

func _assert(condition: bool, label: String) -> void:
	if not condition: _fails.append("FAIL: " + label)
