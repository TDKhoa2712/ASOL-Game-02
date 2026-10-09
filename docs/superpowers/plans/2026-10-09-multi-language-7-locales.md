# Multi-Language (7 Locales) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust, lightweight multi-language localization system supporting 7 target locales (`en`, `ja`, `vi`, `id`, `pt_BR`, `es`, `ko`) with 3-tier priority resolution (Player Saved → System/Device with Aliases → Fallback `en`), compact CJK font fallback integration, metrics-safe UI dialog, and grammatically accurate 1-parameter format strings.

**Architecture:** 
1. Pure static logic `LocaleResolver` resolves active locale using strict 3-tier priority, normalizes platform aliases (`in` → `id`, `tl` → `fil`, `pt` region matching), and provides native language names.
2. `FontTokens` wires a compact CJK subset font (~2.7MB) into `FontFile.fallbacks` of primary fonts (`BeVietnamPro` and `Nunito`) to prevent "tofu" glyph missing errors without bloating package size.
3. Expanded `strings.csv` with 8 columns (`key,en,ja,vi,id,pt_BR,es,ko`) covering all 76 UI and hint keys, with grammar-accurate placeholder positions for `%s` / `%d`.
4. `LanguageSelectDialog` modal in `OptionsScreen` allows players to choose from 7 native language names with safe vertical margins (≥52px row height) preventing CJK/diacritic clipping.
5. Injected into `AppShell` composition root on boot and setting change — no autoloads, fully testable with Godot headless.

**Tech Stack:** Godot 4.7 / GDScript, TranslationServer, SIL OFL CJK Subset Font, CSV Localization

**Spec:** Current codebase (`game/scripts/screens/app_shell.gd`, `game/scripts/state/config_store.gd`, `game/locale/strings.csv`, `game/scripts/theme/font_tokens.gd`, `game/scripts/screens/options_screen.gd`)

---

## Global Constraints

- Modules ≤ 300 lines per file. Single responsibility per module.
- Composition root pattern — dependencies injected from `AppShell`, no autoloads.
- Clean-room compliance: zero matches for reference names (`EventBus`, `EventName`, `GameState`, `SaveStore`, `SoundManager`, `LanguageManager`, etc.).
- Never import directly from `extracted_reusable/`. Assets must reside cleanly in `game/assets/`.
- Strict 3-tier priority: 1) Saved user preference → 2) Supported device/OS locale → 3) Fallback `en`.
- Font assets must be compact: CJK font must use subset (~2.7MB), not full 20MB–40MB packages.
- All tests must extend `SceneTree` and run headlessly via `Godot_v4.7.2-stable_win64_console.exe --headless`.
- Conventional Commits: `<type>(<scope>): <description>`.

---

## Review Focus

1. **3-Tier Priority Invariants**:
   - When player has saved `"ja"`, it MUST use `"ja"` regardless of device OS locale.
   - When player has no saved preference (`""`), device locale `pt_BR` MUST resolve to `"pt_BR"`, `ja_JP` to `"ja"`, `id_ID` (or Android legacy `in_ID`) to `"id"`.
   - When device locale is unsupported (e.g., `de_DE`, `ru_RU`, `ar_SA`), it MUST resolve to `"en"`.
2. **Font Fallback & Glyph Rendering**:
   - Latin and Vietnamese text must continue using `BeVietnamPro` and `Nunito`.
   - Japanese (`あ`, `ゲーム`, `設定`) and Korean (`게임`, `설정`, `레벨`) must render without square tofu glyphs.
3. **Font Metrics & UI Alignment**:
   - `LanguageSelectDialog` items and OptionsScreen tiles must not clip top/bottom accents or CJK characters.
   - Vertical padding must be symmetrical (`content_margin` top/bottom 10px, min button height 52px).
4. **Grammatical Placeholder Placement (`%s` / `%d`)**:
   - `title.play`: EN `Level %s`, JA `レベル %s`, VI `Màn %s`, KO `레벨 %s`, ES `Nivel %s`, PT_BR `Nível %s`, ID `Level %s`.
   - No string formatting exceptions or crashes when calling `tr(key) % arg`.

---

## File Structure & Responsibilities

| File | Responsibility |
|---|---|
| `game/scripts/core/locale_resolver.gd` | Pure logic for 3-tier priority, alias normalization, native names, and display lists. |
| `game/tests/test_locale_resolver.gd` | Unit tests for all priority tiers, aliases, and edge cases. |
| `game/assets/fonts/NotoSansCJK-subset.ttf` | Compact CJK subset font asset for Japanese & Korean glyph fallback. |
| `game/scripts/theme/font_tokens.gd` | Provides heading/body fonts with configured CJK fallbacks. |
| `game/tests/test_font_cjk_fallback.gd` | Test verifying CJK glyph availability on fallback chain. |
| `game/locale/strings.csv` | Master translations for 7 target languages across 76 keys. |
| `game/project.godot` | Configures `locale/fallback="en"` and registers 7 translation resources. |
| `game/scripts/state/config_store.gd` | Stores player language preference (`VALID_LANGUAGES` includes 7 locales + `""`). |
| `game/tests/test_config_language.gd` | Tests for language saving, persistence, validation, and signal emission. |
| `game/scripts/screens/language_select_dialog.gd` | Modal dialog displaying 7 native language options with safe margins and checkmark. |
| `game/scripts/screens/options_screen.gd` | Triggers language dialog, updates display button label. |
| `game/scripts/screens/app_shell.gd` | Boots with `LocaleResolver`, applies changes, rebuilds active screen. |
| `game/tests/test_localization.gd` | Integration tests verifying key coverage and runtime translation across all 7 locales. |

---

### Task 1: Pure Logic LocaleResolver (TDD)

**Files:**
- Create: `game/scripts/core/locale_resolver.gd`
- Test: `game/tests/test_locale_resolver.gd`

**Interfaces:**
- Consumes: `OS.get_locale()`, `OS.get_locale_language()`
- Produces:
  - `const SUPPORTED_LOCALES: Array[String] = ["en", "ja", "vi", "id", "pt_BR", "es", "ko"]`
  - `const DEFAULT_FALLBACK: String = "en"`
  - `static func resolve_locale(saved_locale: String, device_locale: String) -> String`
  - `static func normalize_device_locale(raw_locale: String) -> String`
  - `static func get_native_name(locale: String) -> String`
  - `static func get_options_list() -> Array[Dictionary]`

- [ ] **Step 1: Write failing unit tests for LocaleResolver**

Create `game/tests/test_locale_resolver.gd` with test cases:
1. Saved preference takes precedence over any device locale (e.g. saved `"ja"` with device `"vi_VN"` returns `"ja"`).
2. Blank or invalid saved preference falls through to device locale.
3. Device `pt_BR` matches `"pt_BR"`.
4. Device `ja_JP` matches `"ja"`.
5. Device `ko_KR` matches `"ko"`.
6. Legacy Android `in_ID` aliases to `"id"`.
7. Device `es_ES` matches `"es"`.
8. Unsupported device locale (e.g. `de_DE`, `fr_FR`, `ru_RU`) returns `"en"`.
9. `get_native_name` returns correct native titles.
10. `get_options_list` returns exactly 7 items with keys `locale` and `native`.

- [ ] **Step 2: Run test to confirm failure**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_locale_resolver.gd
```
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement `LocaleResolver`**

Create `game/scripts/core/locale_resolver.gd`:
```gdscript
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
		lang = SYS_LANG_ALIASES[lang]
	if parts.size() > 1:
		var region := parts[1].to_upper()
		var candidate := "%s_%s" % [lang, region]
		if is_supported(candidate):
			return candidate
	return lang

static func is_supported(locale: String) -> bool:
	return SUPPORTED_LOCALES.has(locale)

static func get_native_name(locale: String) -> String:
	return NATIVE_NAMES.get(locale, locale)

static func get_options_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for loc in SUPPORTED_LOCALES:
		list.append({
			"locale": loc,
			"native": get_native_name(loc),
		})
	return list
```

- [ ] **Step 4: Run test to confirm pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_locale_resolver.gd
```
Expected: `LOCALE_RESOLVER_PASS` (exit code 0).

- [ ] **Step 5: Commit Task 1**

```bash
git add game/scripts/core/locale_resolver.gd game/tests/test_locale_resolver.gd
git commit -m "feat(i18n): implement pure logic LocaleResolver with 3-tier priority"
```

---

### Task 2: ConfigStore 7-Locale Support (TDD)

**Files:**
- Modify: `game/scripts/state/config_store.gd:6-8,27-31`
- Modify: `game/tests/test_config_language.gd`

**Interfaces:**
- Consumes: `VALID_LANGUAGES: Array[String]`
- Produces: Persistent support for `["", "en", "ja", "vi", "id", "pt_BR", "es", "ko"]` in `config.json`.

- [ ] **Step 1: Update `test_config_language.gd` with 7 languages and empty string fallback**

Update `game/tests/test_config_language.gd` to test:
- Setting each of `"en"`, `"ja"`, `"vi"`, `"id"`, `"pt_BR"`, `"es"`, `"ko"`, and `""` succeeds and emits `option_changed`.
- Setting invalid language (e.g. `"fr"`, `"xx"`, `123`) is rejected.
- Persistence across store reloads for all 7 locales.

- [ ] **Step 2: Run test to confirm failure**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_config_language.gd
```
Expected: FAIL on unsupported languages.

- [ ] **Step 3: Update `config_store.gd`**

In `game/scripts/state/config_store.gd`:
```gdscript
const VALID_LANGUAGES: Array[String] = ["", "en", "ja", "vi", "id", "pt_BR", "es", "ko"]
```
Allow empty string `""` to represent "follow system/auto" when not explicitly overridden by user.

- [ ] **Step 4: Run test to confirm pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_config_language.gd
```
Expected: `CONFIG_LANGUAGE_PASS` (exit code 0).

- [ ] **Step 5: Commit Task 2**

```bash
git add game/scripts/state/config_store.gd game/tests/test_config_language.gd
git commit -m "feat(state): expand ConfigStore to validate 7 target locales"
```

---

### Task 3: CJK Subset Font Fallback & Metrics Protection

**Files:**
- Add: `game/assets/fonts/NotoSansCJK-subset.ttf` (copied cleanly from project font pool, ~2.7MB)
- Modify: `game/scripts/theme/font_tokens.gd`
- Create: `game/tests/test_font_cjk_fallback.gd`

**Interfaces:**
- Consumes: `FontTokens.heading()`, `FontTokens.body()`, `FontTokens.heading_regular()`
- Produces: Each primary font file has `NotoSansCJK-subset.ttf` in its `fallbacks` array.

- [ ] **Step 1: Write test verifying CJK glyph support**

Create `game/tests/test_font_cjk_fallback.gd` testing that:
1. `FontTokens.heading()` and `FontTokens.body()` can render Japanese sample characters (`あ`, `日`, `本`, `語`) without error.
2. `FontTokens.heading()` and `FontTokens.body()` can render Korean sample characters (`한`, `글`, `게`, `임`) without error.
3. Fallback list contains the CJK font.

- [ ] **Step 2: Copy CJK subset font to `game/assets/fonts/NotoSansCJK-subset.ttf`**

Copy `extracted_reusable/assets/fonts/NotoSourceHan-subset.ttf` to `game/assets/fonts/NotoSansCJK-subset.ttf`.
(Verify clean-room: no script references `extracted_reusable/`, asset is native to `game/assets/fonts/`).

- [ ] **Step 3: Update `font_tokens.gd` with fallback wiring**

Modify `game/scripts/theme/font_tokens.gd`:
```gdscript
static var _cjk_fallback: FontFile = null

static func _get_cjk_fallback() -> FontFile:
	if _cjk_fallback == null:
		_cjk_fallback = _load_font("res://assets/fonts/NotoSansCJK-subset.ttf")
	return _cjk_fallback

static func _apply_fallbacks(font: FontFile) -> void:
	if font == null:
		return
	var cjk := _get_cjk_fallback()
	if cjk != null and not font.fallbacks.has(cjk):
		font.fallbacks.append(cjk)
```
Call `_apply_fallbacks()` inside `heading()`, `heading_regular()`, `body()`, `body_semibold()`, and `body_bold()`.

- [ ] **Step 4: Run test to confirm pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_font_cjk_fallback.gd
```
Expected: `FONT_CJK_FALLBACK_PASS` (exit code 0).

- [ ] **Step 5: Verify existing font tests still pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_font_tokens.gd
```
Expected: `FONT_TOKENS_PASS`.

- [ ] **Step 6: Commit Task 3**

```bash
git add game/assets/fonts/NotoSansCJK-subset.ttf game/scripts/theme/font_tokens.gd game/tests/test_font_cjk_fallback.gd
git commit -m "feat(theme): configure compact CJK subset font fallbacks for headings and body"
```

---

### Task 4: Translations Expansion (`strings.csv`) & Engine Config

**Files:**
- Modify: `game/locale/strings.csv`
- Modify: `game/project.godot`
- Modify: `game/tests/test_localization.gd`

**Interfaces:**
- Produces: 8-column CSV with columns `key,en,ja,vi,id,pt_BR,es,ko`.
- Format accuracy: `%s` / `%d` positional placement adapted to each language's grammar.

- [ ] **Step 1: Update `test_localization.gd` with 7-language verification**

Modify `game/tests/test_localization.gd` to iterate over all 7 locales (`en`, `ja`, `vi`, `id`, `pt_BR`, `es`, `ko`) for all 76 translation keys and assert that `tr(key) != key`. Also test parameter substitution (`tr("title.play") % "5"` and `tr("title.endless") % 10`).

- [ ] **Step 2: Run test to confirm failure before CSV expansion**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_localization.gd
```
Expected: FAIL (missing translations for `ja`, `id`, `pt_BR`, `es`, `ko`).

- [ ] **Step 3: Expand `game/locale/strings.csv`**

Expand all 76 keys across all 7 languages. Ensure proper formatting:
- `title.play`: `Level %s` (EN, ID), `レベル %s` (JA), `Màn %s` (VI), `Nível %s` (PT_BR), `Nivel %s` (ES), `레벨 %s` (KO)
- `title.endless`: `Endless: Level %d` (EN, ID), `エンドレス: レベル %d` (JA), `Vô tận: Màn %d` (VI), `Infinito: Nível %d` (PT_BR), `Infinito: Nivel %d` (ES), `무한: 레벨 %d` (KO)
- `puzzle.restart_title`, `hint.*`, `help.*`, `settings.*`, `result.*` all professionally localized.

- [ ] **Step 4: Update `project.godot`**

Set:
```ini
[internationalization]

locale/translations=PackedStringArray("res://locale/strings.en.translation", "res://locale/strings.ja.translation", "res://locale/strings.vi.translation", "res://locale/strings.id.translation", "res://locale/strings.pt_BR.translation", "res://locale/strings.es.translation", "res://locale/strings.ko.translation")
locale/fallback="en"
```

- [ ] **Step 5: Run tests to confirm pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_localization.gd
```
Expected: `LOCALIZATION_PASS` (exit code 0).

- [ ] **Step 6: Commit Task 4**

```bash
git add game/locale/strings.csv game/project.godot game/tests/test_localization.gd
git commit -m "feat(i18n): expand strings.csv to 7 languages with grammar-aware formatting"
```

---

### Task 5: UI Language Selection Dialog & Options Screen

**Files:**
- Create: `game/scripts/screens/language_select_dialog.gd`
- Modify: `game/scripts/screens/options_screen.gd:248-288`
- Modify: `game/tests/test_screens.gd`

**Interfaces:**
- Consumes: `LocaleResolver.get_options_list()`, `ConfigStore.set_option("language", loc)`
- Produces: Modal overlay displaying 7 native language buttons with checkmark, min height 52px, symmetrical padding.

- [ ] **Step 1: Write test for LanguageSelectDialog in `test_screens.gd`**

Verify that:
1. Dialog instantiates with 7 language buttons.
2. Active language shows checkmark indicator.
3. Selecting a language emits `language_selected(locale)` and updates config.

- [ ] **Step 2: Implement `LanguageSelectDialog`**

Create `game/scripts/screens/language_select_dialog.gd` (≤ 150 lines):
- Dimmer scrim background.
- Card panel with title `tr("settings.language")`.
- VBoxContainer inside ScrollContainer with 7 items.
- Each button has `custom_minimum_size = Vector2(0, 52)` with `content_margin_top = 10`, `content_margin_bottom = 10` for font metric safety.
- Shows native name (`日本語`, `Tiếng Việt`, `English`, etc.) and a checkmark if selected.
- Back/Close button.

- [ ] **Step 3: Update `OptionsScreen` language tile**

In `game/scripts/screens/options_screen.gd`:
- Change `_make_language_tile()`: instead of 2-way toggle, clicking `LangBtn` opens `LanguageSelectDialog`.
- `LangBtn.text` displays current active language's native name (e.g. `LocaleResolver.get_native_name(current)`).
- When a new language is selected from the dialog, update config and refresh UI.

- [ ] **Step 4: Run test to confirm pass**

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_screens.gd
```
Expected: PASS.

- [ ] **Step 5: Commit Task 5**

```bash
git add game/scripts/screens/language_select_dialog.gd game/scripts/screens/options_screen.gd game/tests/test_screens.gd
git commit -m "feat(ui): add 7-locale LanguageSelectDialog modal with metric-safe padding"
```

---

### Task 6: AppShell Boot Integration & Full Verification

**Files:**
- Modify: `game/scripts/screens/app_shell.gd:52-57,252-255`
- Test: `tools/verify.py`

**Interfaces:**
- Consumes: `LocaleResolver.resolve_locale()`, `TranslationServer.set_locale()`, `FontTokens`
- Produces: Automated language boot resolution on startup and real-time screen re-rendering on language switch.

- [ ] **Step 1: Wire `LocaleResolver` into `AppShell`**

In `game/scripts/screens/app_shell.gd`:
- At `_ready()`:
  ```gdscript
  var saved_lang: String = str(config.get_option("language"))
  var initial_locale := LocaleResolver.resolve_locale(saved_lang, OS.get_locale())
  TranslationServer.set_locale(initial_locale)
  ```
- In `_apply_setting("language", value)`:
  ```gdscript
  "language":
      var resolved := LocaleResolver.resolve_locale(str(value), OS.get_locale())
      TranslationServer.set_locale(resolved)
      _rebuild_current_screen()
  ```

- [ ] **Step 2: Run clean-room check**

```bash
powershell -Command "Select-String -Path 'game/scripts/**/*.gd' -Pattern 'EventBus|EventName|GameState|SaveStore|SoundManager|LanguageManager|queendoku|meowdoku' -CaseSensitive:$false"
```
Expected: 0 matches.

- [ ] **Step 3: Run full verification suite**

```bash
python -B tools/verify.py --godot Godot_v4.7.2-stable_win64_console.exe
```
Expected: All tests PASS.

- [ ] **Step 4: Commit Task 6**

```bash
git add game/scripts/screens/app_shell.gd
git commit -m "feat(core): wire 3-tier locale resolution into AppShell composition root"
```
