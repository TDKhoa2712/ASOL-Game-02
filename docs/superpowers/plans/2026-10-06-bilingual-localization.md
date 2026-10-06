# Bilingual Localization + Official Fonts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all hardcoded Vietnamese UI strings with Godot's built-in TranslationServer, add English translations, and bundle two OFL-licensed fonts (Baloo 2 + Nunito) with full Vietnamese diacritics support.

**Architecture:** CSV-based localization using Godot's `TranslationServer`. A `strings.csv` file with columns `key,vi,en` is the source of truth. Each screen replaces hardcoded strings with `tr("key")`. A new `font_tokens.gd` provides lazy-loaded font accessors. Language toggle added to Settings via `config_store.gd`.

**Tech Stack:** Godot 4.7 GDScript, Godot TranslationServer, CSV import, Baloo 2 + Nunito fonts (OFL)

**Spec:** `docs/superpowers/specs/2026-10-06-bilingual-localization-design.md`

## Global Constraints

- Gate: existing 76 Python tests + 32 Godot suites must pass after every task
- Clean-room: no names from `extracted_reusable/`; verify with `rg -n "(EventBus|EventName|GameState|SaveStore|...)" game/scripts/`
- Module ≤ 300 lines
- No changes to gameplay logic, layout dimensions, or `textKey` trace system
- Font total ≤ 2 MB
- Vietnamese diacritics: all 134 Latin Extended characters must render correctly

## Review Focus

1. **Format-string mismatch:** `tr("title.play") % label` will crash if the translation is missing the `%s` placeholder. Every `tr()` call using `%` must have matching placeholders in both VI and EN columns. — Test added to Task 2.
2. **Locale persistence across restart:** if `config_store` doesn't save the `"language"` key (it currently only saves `bool` values from `EDITABLE_KEYS`), the language resets on restart. — Test added to Task 3.
3. **UI rebuild after locale change:** `TranslationServer.set_locale()` doesn't auto-update programmatically-created Labels. Every screen that builds text in `_ensure_nodes()` or `_update_ui()` must be refreshed. — Test added to Task 5.
4. **CSV encoding:** Godot's CSV importer requires UTF-8 with BOM for proper Vietnamese character parsing. — Verified in Task 1.
5. **Font fallback:** if a `.ttf` file fails to load, labels revert to Godot default (which lacks Vietnamese glyphs). `font_tokens.gd` should log a warning but not crash. — Test added to Task 2.

---

### Task 1: Font files + CSV + project.godot configuration

**Files:**
- Create: `game/assets/fonts/Baloo2-Regular.ttf` (download from Google Fonts)
- Create: `game/assets/fonts/Baloo2-Bold.ttf`
- Create: `game/assets/fonts/Nunito-Regular.ttf`
- Create: `game/assets/fonts/Nunito-SemiBold.ttf`
- Create: `game/assets/fonts/Nunito-Bold.ttf`
- Create: `game/assets/fonts/LICENSE-OFL.txt`
- Create: `game/locale/strings.csv`
- Modify: `game/project.godot`

**Interfaces:**
- Consumes: nothing
- Produces: font files at `res://assets/fonts/`, translation CSV at `res://locale/strings.csv`, project.godot internationalization section

- [x] **Step 1: Download fonts**

Download from Google Fonts (TTF format, not variable):
- Baloo 2: Regular (400), Bold (700) — 2 files
- Nunito: Regular (400), SemiBold (600), Bold (700) — 3 files

Place into `game/assets/fonts/`. Create `LICENSE-OFL.txt` containing the OFL 1.1 license text with both font attributions (Ek Type for Baloo 2, Vernon Adams/Cyreal for Nunito).

- [x] **Step 2: Verify font file sizes**

```bash
rtk proxy ls -la game/assets/fonts/*.ttf
```

Expected: each file 100–400 KB, total under 2 MB.

- [x] **Step 3: Create strings.csv**

Create `game/locale/strings.csv` with UTF-8 BOM encoding. The file must start with the bytes `EF BB BF` (UTF-8 BOM) for Godot's CSV importer to correctly handle Vietnamese characters.

```csv
key,vi,en
title.name,CanDoKu,CanDoKu
title.play,Level %s,Level %s
title.replay,Chơi lại chiến dịch,Replay Campaign
title.help_tooltip,Xem cách chơi,How to Play
title.debug,🛠 Debug,🛠 Debug
help.title,Cách chơi,How to Play
help.body,"Mỗi hàng, cột và vùng có đúng một viên kẹo. Kẹo không chạm chéo nhau. Chạm một lần để đánh dấu X, chạm hai lần để thử đặt kẹo, kéo để đánh dấu nhiều ô.","Each row, column, and region contains exactly one candy. Candies cannot touch diagonally. Tap once to mark X, double-tap to place a candy, swipe to mark multiple cells."
settings.title,CÀI ĐẶT,SETTINGS
settings.audio,Âm thanh,Sound
settings.haptic,Rung phản hồi,Haptic Feedback
settings.reduced_motion,Giảm chuyển động,Reduce Motion
settings.large_text,Cỡ chữ lớn,Large Text
settings.high_contrast,Độ tương phản cao,High Contrast
settings.colorblind,Hỗ trợ phân biệt màu,Colorblind Mode
settings.undo_x,Hoàn tác X,Undo X
settings.language,Ngôn ngữ,Language
settings.language.vi,Tiếng Việt,Tiếng Việt
settings.language.en,English,English
settings.back,Quay lại,Back
settings.restart,Bắt đầu lại,Restart
puzzle.level_caption,Màn,Level
puzzle.hint_unit,Xem kỹ khu vực này,Look at this area
puzzle.hint_cell,Đặt kẹo ở đây,Place candy here
puzzle.restart_title,Chơi lại màn này?,Restart this level?
puzzle.restart_body,Các ô đã đánh dấu và số lỗi của lượt chơi sẽ được đặt lại.,Your marks and mistakes will be reset.
puzzle.restart_ok,Chơi lại,Restart
puzzle.restart_cancel,Tiếp tục,Continue
puzzle.rule_row,1 kẹo mỗi hàng và cột,1 candy per row and column
puzzle.rule_region,1 kẹo mỗi vùng,1 candy per region
puzzle.rule_diagonal,Kẹo không chạm góc,Candies don't touch diagonally
result.win.title,Hoan hô!,Hooray!
result.win.title_campaign,Hoàn thành chiến dịch!,Campaign Complete!
result.win.subtitle,Bạn đã tìm đủ kẹo!,You found all the candies!
result.win.next,Tiếp tục,Continue
result.win.replay,Chơi lại,Play Again
result.win.home,Trang chủ,Home
result.lose.title,Hết tim,Out of Hearts
result.lose.subtitle,Bạn có thể thử lại màn này.,You can try this level again.
result.lose.retry,Thử lại,Retry
result.lose.home,Trang chủ,Home
boot.error,Lỗi khởi động: %s,Boot error: %s
boot.save_failed,Lưu dữ liệu thất bại: %s,Save failed: %s
common.ok,OK,OK
```

- [x] **Step 4: Add internationalization to project.godot**

Append to `game/project.godot`:

```ini
[internationalization]

locale/translations=PackedStringArray("res://locale/strings.vi.translation", "res://locale/strings.en.translation")
locale/fallback="vi"
```

- [x] **Step 5: Verify CSV can be parsed**

```bash
rtk proxy python3 -c "
import csv, codecs
with open('game/locale/strings.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    rows = list(reader)
    assert 'key' in reader.fieldnames
    assert 'vi' in reader.fieldnames
    assert 'en' in reader.fieldnames
    for row in rows:
        if '%s' in row['vi'] or '%d' in row['vi']:
            assert '%s' in row['en'] or '%d' in row['en'], f'Format mismatch: {row[\"key\"]}'
    print(f'OK: {len(rows)} keys, all format strings match')
"
```

- [x] **Step 6: Commit**

```bash
git add game/assets/fonts/ game/locale/strings.csv game/project.godot
git commit -m "$(cat <<'EOF'
feat(i18n): add Baloo 2 + Nunito fonts and bilingual strings CSV

Bundle 5 OFL-licensed font files (Baloo 2 heading, Nunito body) with
full Vietnamese diacritics support. Create strings.csv with 40+ keys
in Vietnamese and English. Configure TranslationServer in project.godot.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Font tokens helper + unit tests

**Files:**
- Create: `game/scripts/theme/font_tokens.gd`
- Create: `game/tests/test_font_tokens.gd`

**Interfaces:**
- Consumes: font files at `res://assets/fonts/*.ttf`
- Produces: `FontTokens.heading()`, `FontTokens.heading_regular()`, `FontTokens.body()`, `FontTokens.body_semibold()`, `FontTokens.body_bold()` — all return `FontFile`

- [x] **Step 1: Write test**

Create `game/tests/test_font_tokens.gd`:

```gdscript
extends SceneTree

const FontTokens = preload("res://scripts/theme/font_tokens.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_heading_loads()
	_test_heading_regular_loads()
	_test_body_loads()
	_test_body_semibold_loads()
	_test_body_bold_loads()
	_test_caching()
	_test_all_support_vietnamese()

	if _fails.is_empty():
		print("FONT_TOKENS_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_heading_loads() -> void:
	var font := FontTokens.heading()
	if font == null:
		_fails.append("heading() returned null")
	elif not font is FontFile:
		_fails.append("heading() did not return FontFile")

func _test_heading_regular_loads() -> void:
	var font := FontTokens.heading_regular()
	if font == null:
		_fails.append("heading_regular() returned null")

func _test_body_loads() -> void:
	var font := FontTokens.body()
	if font == null:
		_fails.append("body() returned null")

func _test_body_semibold_loads() -> void:
	var font := FontTokens.body_semibold()
	if font == null:
		_fails.append("body_semibold() returned null")

func _test_body_bold_loads() -> void:
	var font := FontTokens.body_bold()
	if font == null:
		_fails.append("body_bold() returned null")

func _test_caching() -> void:
	var a := FontTokens.heading()
	var b := FontTokens.heading()
	if a != b:
		_fails.append("heading() not cached — returned different instances")

func _test_all_support_vietnamese() -> void:
	var test_chars := "ĂẮẦẪƠỜƯỪỮỰàáảãạ"
	for getter in ["heading", "body", "body_semibold", "body_bold"]:
		var font: FontFile = FontTokens.call(getter)
		if font == null:
			continue
		for ch in test_chars:
			if not font.has_char(ch.unicode_at(0)):
				_fails.append("%s() missing Vietnamese char U+%04X (%s)" % [getter, ch.unicode_at(0), ch])
				break
```

- [x] **Step 2: Run test — verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_font_tokens.gd
```

Expected: FAIL — `font_tokens.gd` does not exist yet.

- [x] **Step 3: Implement font_tokens.gd**

Create `game/scripts/theme/font_tokens.gd`:

```gdscript
extends RefCounted

static var _heading: FontFile = null
static var _heading_regular: FontFile = null
static var _body: FontFile = null
static var _body_semibold: FontFile = null
static var _body_bold: FontFile = null

static func heading() -> FontFile:
	if _heading == null:
		_heading = _load_font("res://assets/fonts/Baloo2-Bold.ttf")
	return _heading

static func heading_regular() -> FontFile:
	if _heading_regular == null:
		_heading_regular = _load_font("res://assets/fonts/Baloo2-Regular.ttf")
	return _heading_regular

static func body() -> FontFile:
	if _body == null:
		_body = _load_font("res://assets/fonts/Nunito-Regular.ttf")
	return _body

static func body_semibold() -> FontFile:
	if _body_semibold == null:
		_body_semibold = _load_font("res://assets/fonts/Nunito-SemiBold.ttf")
	return _body_semibold

static func body_bold() -> FontFile:
	if _body_bold == null:
		_body_bold = _load_font("res://assets/fonts/Nunito-Bold.ttf")
	return _body_bold

static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path):
		push_warning("FontTokens: missing font file %s" % path)
		return null
	return load(path) as FontFile
```

- [x] **Step 4: Run test — verify it passes**

```bash
rtk godot --headless --path game --script res://tests/test_font_tokens.gd
```

Expected: `FONT_TOKENS_PASS`

- [x] **Step 5: Run full gate**

```bash
rtk python -B tools/verify.py --godot <executable>
```

Expected: all existing tests still pass.

- [x] **Step 6: Commit**

```bash
git add game/scripts/theme/font_tokens.gd game/tests/test_font_tokens.gd
git commit -m "$(cat <<'EOF'
feat(i18n): add FontTokens helper with lazy-loaded Baloo 2 + Nunito

Provides static accessors for heading (Baloo 2 Bold/Regular) and body
(Nunito Regular/SemiBold/Bold) fonts with caching and missing-file
warnings. Tests verify loading, caching, and Vietnamese char coverage.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Language setting in config_store + test

**Files:**
- Modify: `game/scripts/state/config_store.gd`
- Modify: `game/tests/test_screens.gd` (or create `game/tests/test_config_language.gd`)

**Interfaces:**
- Consumes: `ConfigStore` existing API
- Produces: `config_store.get_option("language")` returns `"vi"` or `"en"`, `set_option("language", "en")` persists and emits signal

The current `config_store.gd` only handles `bool` values via `EDITABLE_KEYS`. The `"language"` key stores a `String`, so `set_option` needs adjustment.

- [x] **Step 1: Write test**

Create `game/tests/test_config_language.gd`:

```gdscript
extends SceneTree

const ConfigStore = preload("res://scripts/state/config_store.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_config_lang_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_default_language()
	_test_set_language_en()
	_test_persist_language()
	_test_signal_emitted()
	_test_invalid_language_rejected()

	DirAccess.remove_absolute(_tmp_dir.path_join("config.json"))
	DirAccess.remove_absolute(_tmp_dir)

	if _fails.is_empty():
		print("CONFIG_LANGUAGE_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_default_language() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	if cfg.get_option("language") != "vi":
		_fails.append("default language should be 'vi', got '%s'" % str(cfg.get_option("language")))

func _test_set_language_en() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	cfg.set_option("language", "en")
	if cfg.get_option("language") != "en":
		_fails.append("language should be 'en' after set, got '%s'" % str(cfg.get_option("language")))

func _test_persist_language() -> void:
	var cfg1 := ConfigStore.new(_tmp_dir)
	cfg1.set_option("language", "en")
	var cfg2 := ConfigStore.new(_tmp_dir)
	if cfg2.get_option("language") != "en":
		_fails.append("language not persisted, got '%s'" % str(cfg2.get_option("language")))

func _test_signal_emitted() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	var received := []
	cfg.option_changed.connect(func(k: String, v: Variant): received.append([k, v]))
	cfg.set_option("language", "en")
	if received.size() != 1 or received[0][0] != "language":
		_fails.append("signal not emitted for language change, received=%s" % str(received))

func _test_invalid_language_rejected() -> void:
	var cfg := ConfigStore.new(_tmp_dir)
	cfg.set_option("language", "fr")
	if cfg.get_option("language") != "vi":
		_fails.append("invalid language 'fr' should be rejected, got '%s'" % str(cfg.get_option("language")))
```

- [x] **Step 2: Run test — verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_config_language.gd
```

Expected: FAIL — `"language"` not in `EDITABLE_KEYS`, default not `"vi"`.

- [x] **Step 3: Modify config_store.gd**

In `game/scripts/state/config_store.gd`, make these changes:

1. Add `"language"` to `DEFAULTS` with value `"vi"`:

```gdscript
const DEFAULTS := {"audio": true, "haptic": true, "reduced_motion": false, "high_contrast": false, "large_text": false, "colorblind": false, "undo_x": true, "language": "vi"}
```

2. Add `"language"` to `EDITABLE_KEYS`:

```gdscript
const EDITABLE_KEYS: Array[String] = ["audio", "haptic", "reduced_motion", "high_contrast", "large_text", "colorblind", "undo_x", "language"]
```

3. Add a constant for valid languages:

```gdscript
const VALID_LANGUAGES: Array[String] = ["vi", "en"]
```

4. Modify `set_option` to handle both `bool` and `String` types:

Replace the current `set_option`:

```gdscript
func set_option(key: String, value: Variant) -> void:
	if not EDITABLE_KEYS.has(key):
		return
	if key == "language":
		if not value is String or not VALID_LANGUAGES.has(value):
			return
	else:
		if not value is bool:
			return
	if _data[key] == value:
		return
	_data[key] = value
	save_config()
	option_changed.emit(key, value)
```

5. Modify `load_config` to handle the string key:

In the loop `for key in EDITABLE_KEYS:`, replace the body:

```gdscript
	for key in EDITABLE_KEYS:
		if key == "language":
			if saved.options.get(key) is String and VALID_LANGUAGES.has(saved.options[key]):
				_data[key] = saved.options[key]
		else:
			if saved.options.get(key) is bool:
				_data[key] = saved.options[key]
```

- [x] **Step 4: Run test — verify it passes**

```bash
rtk godot --headless --path game --script res://tests/test_config_language.gd
```

Expected: `CONFIG_LANGUAGE_PASS`

- [x] **Step 5: Run full gate**

```bash
rtk python -B tools/verify.py --godot <executable>
```

Expected: all existing tests still pass (especially `test_screens.gd` which tests options).

- [x] **Step 6: Commit**

```bash
git add game/scripts/state/config_store.gd game/tests/test_config_language.gd
git commit -m "$(cat <<'EOF'
feat(i18n): add language setting to config_store

Support "language" key ("vi"/"en") in config with string-type handling,
persistence, and validation. Invalid locales are rejected. Existing
bool-only keys unchanged.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire language into app_shell + TranslationServer

**Files:**
- Modify: `game/scripts/screens/app_shell.gd`

**Interfaces:**
- Consumes: `config.get_option("language")`, `TranslationServer.set_locale()`
- Produces: locale applied at boot, re-applied on setting change, screen refreshed

- [x] **Step 1: Add language handling to _apply_setting**

In `game/scripts/screens/app_shell.gd`, add a case in `_apply_setting`:

```gdscript
		"language":
			if value is String:
				TranslationServer.set_locale(str(value))
				_rebuild_current_screen()
```

Add this helper method to `app_shell.gd`:

```gdscript
func _rebuild_current_screen() -> void:
	if nav == null:
		return
	var current := nav.current_name()
	_swap_screen("", current)
```

- [x] **Step 2: Add language to _apply_all_settings**

Add to the end of `_apply_all_settings()`:

```gdscript
	_apply_setting("language", config.get_option("language"))
```

- [x] **Step 3: Localize boot error strings**

Replace the two hardcoded error strings in `_on_boot_error` and `_on_save_failed`:

```gdscript
func _on_boot_error(err: String) -> void:
	push_error("Boot error: " + err)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = tr("boot.error") % err
		save_error_dialog.popup_centered()

func _on_save_failed(reason: String) -> void:
	push_warning("Save failed: " + reason)
	if save_error_dialog != null:
		save_error_dialog.dialog_text = tr("boot.save_failed") % reason
		save_error_dialog.popup_centered()
```

- [x] **Step 4: Run full gate**

```bash
rtk python -B tools/verify.py --godot <executable>
```

Expected: all tests pass.

- [x] **Step 5: Commit**

```bash
git add game/scripts/screens/app_shell.gd
git commit -m "$(cat <<'EOF'
feat(i18n): wire language setting into app_shell

Apply TranslationServer locale at boot and on language change.
Rebuild current screen after locale switch. Localize boot/save
error dialog strings.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Localize all screens + apply fonts + language toggle

This is the largest task — it touches every screen file to replace hardcoded strings with `tr()` and apply font overrides. Grouped as one task because the screens share a common pattern and the deliverable is "all UI text goes through i18n".

**Files:**
- Modify: `game/scripts/screens/title_screen.gd`
- Modify: `game/scripts/screens/options_screen.gd`
- Modify: `game/scripts/screens/puzzle_layout.gd`
- Modify: `game/scripts/screens/puzzle_screen.gd`
- Modify: `game/scripts/screens/result_screen.gd`
- Modify: `game/scripts/screens/hint_overlay.gd`
- Create: `game/tests/test_localization.gd`

**Interfaces:**
- Consumes: `FontTokens.*()`, `tr()`, `config_store.get_option("language")`
- Produces: all UI text localized, fonts applied, language toggle in settings

- [x] **Step 1: Write integration test**

Create `game/tests/test_localization.gd`:

```gdscript
extends SceneTree

const TitleScreen = preload("res://scripts/screens/title_screen.gd")
const ResultScreen = preload("res://scripts/screens/result_screen.gd")
const OptionsScreen = preload("res://scripts/screens/options_screen.gd")
const ConfigStore = preload("res://scripts/state/config_store.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")

var _fails: Array[String] = []
var _tmp_dir: String = ""

func _init() -> void:
	_tmp_dir = "user://test_i18n_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

	_test_title_uses_tr()
	_test_result_uses_tr()
	_test_locale_switch()
	_test_csv_key_coverage()

	DirAccess.remove_absolute(_tmp_dir.path_join("config.json"))
	DirAccess.remove_absolute(_tmp_dir)

	if _fails.is_empty():
		print("LOCALIZATION_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_title_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := TitleScreen.new()
	var mock := _MockRuntime.new()
	screen._ensure_nodes()
	screen.setup(mock)
	if screen.play_btn == null:
		_fails.append("title play_btn is null")
		return
	if "Level" not in screen.play_btn.text:
		_fails.append("title play_btn should contain 'Level' in EN, got '%s'" % screen.play_btn.text)
	TranslationServer.set_locale("vi")

func _test_result_uses_tr() -> void:
	TranslationServer.set_locale("en")
	var screen := ResultScreen.new()
	screen.setup(true, 5000, "L01", false)
	if screen.message_label == null:
		_fails.append("result message_label is null")
		return
	if screen.message_label.text != "Hooray!":
		_fails.append("result win title in EN should be 'Hooray!', got '%s'" % screen.message_label.text)
	TranslationServer.set_locale("vi")

func _test_locale_switch() -> void:
	TranslationServer.set_locale("vi")
	var result := tr("result.win.title")
	if result != "Hoan hô!":
		_fails.append("VI result.win.title should be 'Hoan hô!', got '%s'" % result)
	TranslationServer.set_locale("en")
	result = tr("result.win.title")
	if result != "Hooray!":
		_fails.append("EN result.win.title should be 'Hooray!', got '%s'" % result)
	TranslationServer.set_locale("vi")

func _test_csv_key_coverage() -> void:
	var expected_keys := [
		"title.name", "title.play", "title.replay",
		"settings.audio", "settings.haptic",
		"result.win.title", "result.lose.title",
		"puzzle.rule_row", "puzzle.rule_region", "puzzle.rule_diagonal",
	]
	TranslationServer.set_locale("vi")
	for key in expected_keys:
		var translated := tr(key)
		if translated == key:
			_fails.append("key '%s' has no VI translation (tr returned key)" % key)
	TranslationServer.set_locale("en")
	for key in expected_keys:
		var translated := tr(key)
		if translated == key:
			_fails.append("key '%s' has no EN translation (tr returned key)" % key)
	TranslationServer.set_locale("vi")

class _MockRuntime extends RefCounted:
	func current_level_label() -> String: return "L01"
	func is_campaign_done() -> bool: return false
```

- [x] **Step 2: Run test — verify it fails**

```bash
rtk godot --headless --path game --script res://tests/test_localization.gd
```

Expected: FAIL — screens still use hardcoded strings.

- [x] **Step 3: Localize title_screen.gd**

In `game/scripts/screens/title_screen.gd`:

Add preload at top:

```gdscript
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
```

In `_ensure_nodes()`, replace hardcoded strings:

```gdscript
	# Line 47: debug_btn.text
	debug_btn.text = tr("title.debug")

	# Line 57: help_btn.tooltip_text
	help_btn.tooltip_text = tr("title.help_tooltip")

	# Line 94: title_label.text
	title_label.text = tr("title.name")

	# Line 125: help_dialog.title
	help_dialog.title = tr("help.title")

	# Line 126: help_dialog.dialog_text
	help_dialog.dialog_text = tr("help.body")
```

Add font overrides after creating labels:

```gdscript
	# After title_label creation (line ~97):
	var heading_font := FontTokens.heading()
	if heading_font != null:
		title_label.add_theme_font_override("font", heading_font)

	# After play_btn creation (line ~120):
	var btn_font := FontTokens.body_semibold()
	if btn_font != null:
		play_btn.add_theme_font_override("font", btn_font)
```

In `_update_ui()`, replace hardcoded strings:

```gdscript
func _update_ui() -> void:
	if runtime == null:
		return
	var label: String = runtime.current_level_label()
	if play_btn != null:
		if runtime.is_campaign_done():
			play_btn.text = tr("title.replay")
		else:
			play_btn.text = tr("title.play") % label.trim_prefix("L")
```

- [x] **Step 4: Localize options_screen.gd + add language toggle**

In `game/scripts/screens/options_screen.gd`:

Add preload:

```gdscript
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
```

Replace the hardcoded `LABELS` dict with tr() lookups. Change `_make_tile` to use `tr()`:

```gdscript
const LABEL_KEYS := {
	"audio": "settings.audio",
	"haptic": "settings.haptic",
	"reduced_motion": "settings.reduced_motion",
	"large_text": "settings.large_text",
	"high_contrast": "settings.high_contrast",
	"colorblind": "settings.colorblind",
	"undo_x": "settings.undo_x",
}
```

In `_make_tile`, change:

```gdscript
	lbl.text = tr(LABEL_KEYS.get(key, key))
```

Replace hardcoded strings in `_ensure_nodes()`:

```gdscript
	# Line 78: title.text
	title.text = tr("settings.title")

	# Line 98: back_btn.text
	back_btn.text = tr("settings.back")

	# Line 112: restart_btn.text
	restart_btn.text = tr("settings.restart")
```

Add font overrides:

```gdscript
	var body_font := FontTokens.body()
	if body_font != null:
		title.add_theme_font_override("font", FontTokens.body_semibold())
		back_btn.add_theme_font_override("font", body_font)
		restart_btn.add_theme_font_override("font", body_font)
```

Add language tile after the WIDE_KEYS loop in `_build_rows()`:

```gdscript
	# After the WIDE_KEYS loop:
	vbox.add_child(_make_language_tile())
```

Add the language tile builder:

```gdscript
func _make_language_tile() -> PanelContainer:
	var tile := PanelContainer.new()
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Palette.SURFACE_TILE
	tile_style.set_corner_radius_all(20)
	tile_style.set_content_margin_all(14)
	tile.add_theme_stylebox_override("panel", tile_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = tr("settings.language")
	lbl.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	lbl.add_theme_color_override("font_color", Palette.INK)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var lang_btn := Button.new()
	lang_btn.name = "LangBtn"
	var current: String = str(_config.get_option("language")) if _config != null else "vi"
	lang_btn.text = tr("settings.language.vi") if current == "vi" else tr("settings.language.en")
	lang_btn.custom_minimum_size = Vector2(160, 44)
	lang_btn.add_theme_font_size_override("font_size", LayoutTokens.tile_font_size())
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Palette.SURFACE_HOVER
	btn_style.set_corner_radius_all(12)
	btn_style.set_content_margin_all(8)
	for state in ["normal", "hover", "pressed", "focus"]:
		lang_btn.add_theme_stylebox_override(state, btn_style)
	lang_btn.pressed.connect(func():
		var cur: String = str(_config.get_option("language")) if _config != null else "vi"
		var next: String = "en" if cur == "vi" else "vi"
		if _config != null:
			_config.set_option("language", next)
	)
	row.add_child(lang_btn)

	tile.add_child(row)
	return tile
```

- [x] **Step 5: Localize puzzle_layout.gd**

In `game/scripts/screens/puzzle_layout.gd`:

Add preload:

```gdscript
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
```

Replace hardcoded strings:

```gdscript
	# Line 44: level caption "Màn"
	var level_caption := _label(tr("puzzle.level_caption"), 24, Palette.TEXT_STAT)

	# Lines 86-89: rule_data
	var rule_data := [
		[".X./XCX/.X.", tr("puzzle.rule_row")],
		["XXX/XC./X..", tr("puzzle.rule_region")],
		["XXX/XCX/XXX", tr("puzzle.rule_diagonal")],
	]

	# Lines 127-130: restart confirm dialog
	confirm.title = tr("puzzle.restart_title")
	confirm.dialog_text = tr("puzzle.restart_body")
	confirm.get_ok_button().text = tr("puzzle.restart_ok")
	confirm.get_cancel_button().text = tr("puzzle.restart_cancel")
```

Add font to level value label:

```gdscript
	var heading_font := FontTokens.heading_regular()
	if heading_font != null:
		level_value.add_theme_font_override("font", heading_font)
```

- [x] **Step 6: Localize puzzle_screen.gd**

In `game/scripts/screens/puzzle_screen.gd`:

Replace the hardcoded hint strings in `_on_hint()`:

```gdscript
	# Lines 185-188:
	var unit_label: String = ""
	if stage == "unit":
		unit_label = tr("puzzle.hint_unit")
	elif stage == "cell":
		unit_label = tr("puzzle.hint_cell")
```

- [x] **Step 7: Localize result_screen.gd**

In `game/scripts/screens/result_screen.gd`:

Add preload:

```gdscript
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
```

Replace strings in `_ensure_nodes()`:

```gdscript
	# Line 77-83: button captions
	next_btn = _make_button("NextBtn", tr("result.win.next"))
	retry_btn = _make_button("RetryBtn", tr("result.lose.retry"))
	replay_btn = _make_button("ReplayBtn", tr("result.win.replay"))
	home_btn = _make_button("HomeBtn", tr("result.win.home"), true)
```

Replace strings in `_update_ui()`:

```gdscript
	if message_label != null:
		if _is_win:
			message_label.text = tr("result.win.title_campaign") if _is_last_level else tr("result.win.title")
		else:
			message_label.text = tr("result.lose.title")
	if result_message != null:
		result_message.text = tr("result.win.subtitle") if _is_win else tr("result.lose.subtitle")
```

Add font overrides in `_ensure_nodes()`:

```gdscript
	var heading_font := FontTokens.heading()
	if heading_font != null:
		message_label.add_theme_font_override("font", heading_font)
	var body_font := FontTokens.body()
	if body_font != null:
		result_message.add_theme_font_override("font", body_font)
		score_label.add_theme_font_override("font", body_font)
```

- [x] **Step 8: Localize hint_overlay.gd**

In `game/scripts/screens/hint_overlay.gd`:

Replace the OK button text:

```gdscript
	# Line 53: _close_btn.text
	_close_btn.text = tr("common.ok")
```

- [x] **Step 9: Run localization test**

```bash
rtk godot --headless --path game --script res://tests/test_localization.gd
```

Expected: `LOCALIZATION_PASS`

- [x] **Step 10: Run full gate**

```bash
rtk python -B tools/verify.py --godot <executable>
```

Expected: all 76 Python tests + 32+ Godot suites pass.

- [x] **Step 11: Run clean-room check**

```bash
rtk proxy rg -n "(EventBus|EventName|GameState|SaveStore|SoundManager|BgmPauseReason|VibrateManager|BoardGestureRecognizer|CellAction|CellState|BoardInputScheme|BankData|BankSorter|LevelBankIO|BankPage|QueenDoku|queendoku|meowdoku)" game/scripts/
```

Expected: no matches.

- [x] **Step 12: Verify tr() key coverage**

```bash
rtk proxy rg -o 'tr\("([^"]+)"\)' game/scripts/ --replace '$1' | sort -u > /tmp/tr_keys.txt
rtk proxy python3 -c "
import csv
with open('game/locale/strings.csv', 'r', encoding='utf-8-sig') as f:
    csv_keys = {row['key'] for row in csv.DictReader(f)}
with open('/tmp/tr_keys.txt') as f:
    code_keys = {line.strip() for line in f if line.strip()}
missing = code_keys - csv_keys
if missing:
    print(f'FAIL: keys in code but not CSV: {missing}')
else:
    print(f'OK: all {len(code_keys)} tr() keys found in CSV')
"
```

Expected: all keys found.

- [x] **Step 13: Commit**

```bash
git add game/scripts/screens/ game/scripts/screens/hint_overlay.gd game/tests/test_localization.gd
git commit -m "$(cat <<'EOF'
feat(i18n): localize all screens with tr() + apply Baloo 2/Nunito fonts

Replace hardcoded Vietnamese strings in title, options, puzzle layout,
puzzle screen, result screen, and hint overlay with tr() keys. Apply
Baloo 2 for headings and Nunito for body text. Add language toggle
(VI/EN) to options screen.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```
