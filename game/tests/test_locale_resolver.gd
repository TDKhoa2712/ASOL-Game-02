extends SceneTree

const LocaleResolver = preload("res://scripts/core/locale_resolver.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_saved_priority()
	_test_empty_or_invalid_saved_falls_through()
	_test_device_exact_matching()
	_test_device_base_language_matching()
	_test_device_alias_handling()
	_test_fallback_unsupported()
	_test_native_names()
	_test_options_list()

	if _fails.is_empty():
		print("LOCALE_RESOLVER_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _test_saved_priority() -> void:
	_assert(LocaleResolver.resolve_locale("ja", "vi_VN") == "ja", "Saved 'ja' should take priority over device 'vi_VN'")
	_assert(LocaleResolver.resolve_locale("es", "en_US") == "es", "Saved 'es' should take priority over device 'en_US'")
	_assert(LocaleResolver.resolve_locale("pt_BR", "ja") == "pt_BR", "Saved 'pt_BR' should take priority over device 'ja'")
	_assert(LocaleResolver.resolve_locale("vi", "en_US") == "vi", "Saved 'vi' should take priority over device 'en_US'")

func _test_empty_or_invalid_saved_falls_through() -> void:
	_assert(LocaleResolver.resolve_locale("", "ja_JP") == "ja", "Empty saved should fall through to device 'ja_JP'")
	_assert(LocaleResolver.resolve_locale("invalid_lang", "ko_KR") == "ko", "Invalid saved should fall through to device 'ko_KR'")

func _test_device_exact_matching() -> void:
	_assert(LocaleResolver.resolve_locale("", "pt_BR") == "pt_BR", "Device 'pt_BR' should resolve to 'pt_BR'")
	_assert(LocaleResolver.resolve_locale("", "pt-BR") == "pt_BR", "Device 'pt-BR' hyphenated should resolve to 'pt_BR'")

func _test_device_base_language_matching() -> void:
	_assert(LocaleResolver.resolve_locale("", "ja_JP") == "ja", "Device 'ja_JP' should resolve to base 'ja'")
	_assert(LocaleResolver.resolve_locale("", "ko_KR") == "ko", "Device 'ko_KR' should resolve to base 'ko'")
	_assert(LocaleResolver.resolve_locale("", "es_ES") == "es", "Device 'es_ES' should resolve to base 'es'")
	_assert(LocaleResolver.resolve_locale("", "es_MX") == "es", "Device 'es_MX' should resolve to base 'es'")
	_assert(LocaleResolver.resolve_locale("", "vi_VN") == "vi", "Device 'vi_VN' should resolve to base 'vi'")
	_assert(LocaleResolver.resolve_locale("", "en_US") == "en", "Device 'en_US' should resolve to base 'en'")
	_assert(LocaleResolver.resolve_locale("", "en_GB") == "en", "Device 'en_GB' should resolve to base 'en'")

func _test_device_alias_handling() -> void:
	_assert(LocaleResolver.resolve_locale("", "in_ID") == "id", "Device legacy 'in_ID' should alias to 'id'")
	_assert(LocaleResolver.resolve_locale("", "in") == "id", "Device legacy 'in' should alias to 'id'")
	# Note: tl (Tagalog) is deferred to future version, so it falls back to 'en'
	_assert(LocaleResolver.resolve_locale("", "tl_PH") == "en", "Device 'tl_PH' should fallback to 'en'")

func _test_fallback_unsupported() -> void:
	_assert(LocaleResolver.resolve_locale("", "de_DE") == "en", "Unsupported 'de_DE' should fallback to 'en'")
	_assert(LocaleResolver.resolve_locale("", "fr_FR") == "en", "Unsupported 'fr_FR' should fallback to 'en'")
	_assert(LocaleResolver.resolve_locale("", "ru_RU") == "en", "Unsupported 'ru_RU' should fallback to 'en'")
	_assert(LocaleResolver.resolve_locale("", "ar_SA") == "en", "Unsupported 'ar_SA' should fallback to 'en'")
	_assert(LocaleResolver.resolve_locale("", "") == "en", "Empty device locale should fallback to 'en'")

func _test_native_names() -> void:
	_assert(LocaleResolver.get_native_name("en") == "English", "Native name for 'en' should be 'English'")
	_assert(LocaleResolver.get_native_name("ja") == "日本語", "Native name for 'ja' should be '日本語'")
	_assert(LocaleResolver.get_native_name("vi") == "Tiếng Việt", "Native name for 'vi' should be 'Tiếng Việt'")
	_assert(LocaleResolver.get_native_name("id") == "Bahasa Indonesia", "Native name for 'id' should be 'Bahasa Indonesia'")
	_assert(LocaleResolver.get_native_name("pt_BR") == "Português (Brasil)", "Native name for 'pt_BR' should be 'Português (Brasil)'")
	_assert(LocaleResolver.get_native_name("es") == "Español", "Native name for 'es' should be 'Español'")
	_assert(LocaleResolver.get_native_name("ko") == "한국어", "Native name for 'ko' should be '한국어'")

func _test_options_list() -> void:
	var list: Array[Dictionary] = LocaleResolver.get_options_list()
	_assert(list.size() == 7, "Options list should have 7 entries, got %d" % list.size())
	for item in list:
		_assert(item.has("locale") and item.has("native"), "Option item must contain 'locale' and 'native'")
		_assert(LocaleResolver.is_supported(item.locale), "Item locale must be supported")
