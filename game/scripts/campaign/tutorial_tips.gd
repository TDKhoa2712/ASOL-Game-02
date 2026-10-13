# One-time contextual tips from L03 on (GDD 03 §4). Pure: picks the tip for an
# event; the caller shows it and records the id through the guide.
extends RefCounted

const IDLE_SECONDS := 30.0
const S3_INTRO_LABEL := "L19"

static func tip_for(event: String, ctx: Dictionary, guide: Variant) -> Dictionary:
	var id := ""
	match event:
		"mistake":
			if int(ctx.get("hearts", 0)) == 1 and not guide.has_seen("C-heart1"):
				id = "C-heart1"
			elif not guide.has_seen("C-err"):
				return _tip("C-err", "tutorial.tip_error", {"n": int(ctx.get("hearts", 0))})
		"undo_blocked":
			id = "C-undo"
		"level_start":
			if str(ctx.get("label", "")) == S3_INTRO_LABEL and not guide.has_seen("C-s3"):
				id = "C-s3"
			elif int(ctx.get("givens", 0)) > 0 and not guide.has_seen("C-given"):
				id = "C-given"
			elif int(ctx.get("size", 0)) >= 5:
				id = "C-size5"
		"idle":
			if int(ctx.get("hints_used", 0)) == 0 and not guide.has_seen("C-idle"):
				return {"id": "C-idle", "text": "", "args": {}, "bounce_hint": true}
	if id.is_empty() or guide.has_seen(id):
		return {}
	return _tip(id, "tutorial.tip_" + id.substr(2).replace("-", "_"), {})

static func _tip(id: String, text: String, args: Dictionary) -> Dictionary:
	return {"id": id, "text": text, "args": args, "bounce_hint": false}
