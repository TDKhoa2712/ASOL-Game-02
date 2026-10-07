# game_features.gd
# Module quan ly co tinh nang (Feature Flags) cho cac che do choi cua CanDoKu.
class_name GameFeatures
extends RefCounted

# ==============================================================================
# CAU HINH PHAT HANH (RELEASE CONFIGURATION)
# Thay doi cac hang so duoi day de bat/tat che do choi khi xuat ban release:
# - ENABLE_CAMPAIGN: Bat che do Chien dich (100 man choi / demo)
# - ENABLE_ENDLESS:  Bat che do Vo tan (36.000+ man choi vo han)
# ==============================================================================
const ENABLE_CAMPAIGN: bool = true
const ENABLE_ENDLESS: bool = false

static var _override_campaign: Variant = null
static var _override_endless: Variant = null


static func is_campaign_enabled() -> bool:
	var c: bool = ENABLE_CAMPAIGN if _override_campaign == null else bool(_override_campaign)
	var e: bool = ENABLE_ENDLESS if _override_endless == null else bool(_override_endless)
	# Safety fallback: Luon giu it nhat 1 che do hoat dong neu ca 2 deu bi tat
	if not c and not e:
		return true
	return c


static func is_endless_enabled() -> bool:
	var c: bool = ENABLE_CAMPAIGN if _override_campaign == null else bool(_override_campaign)
	var e: bool = ENABLE_ENDLESS if _override_endless == null else bool(_override_endless)
	if not c and not e:
		return false
	return e


static func set_campaign_enabled(enabled: bool) -> void:
	_override_campaign = enabled


static func set_endless_enabled(enabled: bool) -> void:
	_override_endless = enabled


static func reset_overrides() -> void:
	_override_campaign = null
	_override_endless = null
