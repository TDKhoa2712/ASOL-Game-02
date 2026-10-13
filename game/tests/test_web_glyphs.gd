extends SceneTree

# Web builds have no system font fallback: every player-facing character must
# come from the bundled fonts, or it renders as an empty box.

const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const HintOverlay = preload("res://scripts/screens/hint_overlay.gd")
const HelpScreen = preload("res://scripts/screens/help_screen.gd")
const LOCALES := ["en", "ja", "vi", "id", "pt_BR", "es", "ko"]
const DEBUG_KEYS := ["title.debug"]

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_translations()
	_test_hint_icons()
	await _test_help_screen()
	if _failures.is_empty():
		print("WEB_GLYPHS_PASS"); quit(0)
	else:
		for f in _failures: printerr(f)
		quit(1)

func _covered(ch: String) -> bool:
	var font: Font = FontTokens.body()
	if font.has_char(ch.unicode_at(0)): return true
	for fb in font.fallbacks:
		if fb.has_char(ch.unicode_at(0)): return true
	return false

func _check(text: String, where: String) -> void:
	var missing := ""
	for ch in text:
		if ch.strip_edges() == "" or missing.contains(ch): continue
		if not _covered(ch): missing += ch
	if missing != "":
		_failures.append("FAIL: %s has glyphs missing from bundled fonts: %s" % [where, missing])

func _test_translations() -> void:
	for loc in LOCALES:
		var tr_res := load("res://locale/strings.%s.translation" % loc) as Translation
		for key in tr_res.get_message_list():
			if DEBUG_KEYS.has(str(key)): continue
			_check(str(tr_res.get_message(key)), "%s:%s" % [loc, key])

func _test_hint_icons() -> void:
	for s in ["WRONG_MARK", "MARK_NEIGHBORS", "LOCK_INTERSECTION", "LOCKED_SUBSET", "SINGLE_CANDIDATE", "FALLBACK", "CONTRA_CHAIN"]:
		_check(HintOverlay._icon_for(s), "hint icon " + s)

func _test_help_screen() -> void:
	var help = HelpScreen.new()
	root.add_child(help)
	await process_frame
	for lbl in help.find_children("*", "Label", true, false):
		_check(lbl.text, "help label '%s'" % lbl.text.left(20))
	help.queue_free()
	await process_frame
