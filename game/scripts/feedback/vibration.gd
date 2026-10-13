# vibration.gd
extends RefCounted

enum Strength { SOFT, NORMAL, FIRM }

const _DURATION_MS := {
	Strength.SOFT: 15,
	Strength.NORMAL: 30,
	Strength.FIRM: 60,
}

static var _on: bool = true

static func pulse(strength: int) -> void:
	if not _on or not has_hardware():
		return
	var duration: int = _DURATION_MS.get(strength, 30)
	Input.vibrate_handheld(duration)

static func set_on(enabled: bool) -> void:
	_on = enabled

static func is_on() -> bool:
	return _on

static func has_hardware() -> bool:
	# Mobile browsers expose vibration through the Web export too.
	for feature in ["mobile", "android", "ios", "web_android", "web_ios"]:
		if OS.has_feature(feature): return true
	return false
