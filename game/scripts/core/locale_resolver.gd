# locale_resolver.gd
class_name LocaleResolver
extends RefCounted

const SUPPORTED_LOCALES: Array[String] = [
	"en", "ja", "vi", "id", "pt_BR", "es", "ko",
]

const SYS_LANG_ALIASES: Dictionary = {
	"in": "id",
	"tl": "fil",
	"iw": "he",
}

const DEFAULT_FALLBACK: String = "en"

const NATIVE_NAMES: Dictionary = {
	"en": "English",
	"ja": "日本語",
	"vi": "Tiếng Việt",
	"id": "Bahasa Indonesia",
	"pt_BR": "Português (Brasil)",
	"es": "Español",
	"ko": "한국어",
}

static func resolve_locale(saved_locale: String, device_locale: String) -> String:
	if is_supported(saved_locale):
		return saved_locale
	var normalized := normalize_device_locale(device_locale)
	if is_supported(normalized):
		return normalized
	var base_lang := normalized.split("_")[0]
	if is_supported(base_lang):
		return base_lang
	return DEFAULT_FALLBACK

static func normalize_device_locale(raw: String) -> String:
	if raw.is_empty():
		return DEFAULT_FALLBACK
	var clean := raw.replace("-", "_")
	var parts := clean.split("_")
	var lang := parts[0].to_lower()
	if SYS_LANG_ALIASES.has(lang):
		lang = str(SYS_LANG_ALIASES[lang])
	if parts.size() > 1:
		var region := parts[1].to_upper()
		var candidate := "%s_%s" % [lang, region]
		if is_supported(candidate):
			return candidate
	return lang

static func is_supported(locale: String) -> bool:
	return SUPPORTED_LOCALES.has(locale)

static func get_native_name(locale: String) -> String:
	return str(NATIVE_NAMES.get(locale, locale))

static func get_options_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for loc in SUPPORTED_LOCALES:
		list.append({
			"locale": loc,
			"native": get_native_name(loc),
		})
	return list
