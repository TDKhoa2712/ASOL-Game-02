# Module 6: Feedback — Audio & Haptic

> **Phụ thuộc:** Module 2 (State) cho ConfigStore
> **Tham khảo:** `extracted_reusable/scripts/sound/` (2 files), `common/vibrate_manager.gd`

## Tổng quan

Module Feedback xử lý phản hồi cảm giác: SFX, BGM, vibration. Reference có SoundManager (520 dòng, 66 sound kinds, polyphony, BGM pause reasons, AB test, ad integration) + VibrateManager (443 dòng, 8 levels, 35 trigger positions, iOS CoreHaptics, RAM detection). Rebuild đơn giản hóa mạnh.

**Cải tiến từ reference:**
- SFX rate limiting (`min_interval`) — ngăn spam sound khi auto-mark nhiều cells
- Auto-mark SFX mới (LOCK_CELL) cho auto-mark feedback

---

## File 1: `game/scripts/feedback/sfx_catalog.gd`

**Trách nhiệm:** Registry of sound effect types and file paths.

**Tham khảo hành vi từ:** `sound_manager.gd` -> `Kind` enum + `_SOUND_PATHS`

```gdscript
# sfx_catalog.gd
extends RefCounted

enum Effect {
    MARK,           # đánh X
    UNDO,           # bỏ X / undo action
    CANDY_YES,      # tìm đúng kẹo
    CANDY_NO,       # đặt sai
    LOCK_CELL,      # auto-mark LOCKED cell (subtle tick)
    HINT_SHOW,      # hiện gợi ý
    STAGE_CLEAR,    # thắng level
    STAGE_FAIL,     # thua level
    BTN_PRESS,      # nhấn nút UI
    BOARD_OPEN,     # mở board
    RESTART,        # restart level
}

const FILE_MAP := {
    Effect.MARK: "res://audio/sfx/mark.ogg",
    Effect.UNDO: "res://audio/sfx/undo.ogg",
    Effect.CANDY_YES: "res://audio/sfx/candy_found.ogg",
    Effect.CANDY_NO: "res://audio/sfx/candy_wrong.ogg",
    Effect.LOCK_CELL: "res://audio/sfx/lock_tick.ogg",
    Effect.HINT_SHOW: "res://audio/sfx/hint.ogg",
    Effect.STAGE_CLEAR: "res://audio/sfx/win.ogg",
    Effect.STAGE_FAIL: "res://audio/sfx/fail.ogg",
    Effect.BTN_PRESS: "res://audio/sfx/tap.ogg",
    Effect.BOARD_OPEN: "res://audio/sfx/enter.ogg",
    Effect.RESTART: "res://audio/sfx/restart.ogg",
}

# Rate limiting: minimum ms between plays of same effect
# Prevents spam when auto-marking many cells in sequence
const MIN_INTERVAL_MS := {
    Effect.LOCK_CELL: 60,    # rapid but not overwhelming during auto-mark
    Effect.MARK: 100,        # prevent double-fire on fast swipe
}
```

**Khác biệt với reference:**
- 11 effects thay 66 `Kind` entries
- Tên: `Effect` thay `Kind`, `CANDY_YES` thay `MARK_CAT`, `STAGE_CLEAR` thay `LEVEL_WIN`
- **Thêm:** `LOCK_CELL` effect cho auto-mark feedback
- **Thêm:** `MIN_INTERVAL_MS` — rate limiting config per effect (từ reference `_min_interval_sec`)
- Không voice/meow/combo/rank/pass_anim sounds
- Không polyphony config per-kind

---

## File 2: `game/scripts/feedback/sfx_player.gd`

**Trách nhiệm:** SFX playback engine with rate limiting.

**Tham khảo hành vi từ:** `sound_manager.gd` -> SFX system + `_last_play_usec` rate limiting

```gdscript
# sfx_player.gd
extends Node

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

var _streams: Dictionary = {}       # Effect -> AudioStream
var _players: Dictionary = {}       # Effect -> AudioStreamPlayer
var _last_play_ms: Dictionary = {}  # Effect -> int (last play timestamp)
var _muted: bool = false

func _ready() -> void:
    # Preload available streams, create AudioStreamPlayer per effect

func play(effect: int) -> void:
    # If muted or no player: return
    # Rate limiting: check MIN_INTERVAL_MS for this effect
    var now := Time.get_ticks_msec()
    if SfxCatalog.MIN_INTERVAL_MS.has(effect):
        var last: int = _last_play_ms.get(effect, 0)
        if now - last < SfxCatalog.MIN_INTERVAL_MS[effect]:
            return  # throttled
    _last_play_ms[effect] = now
    # player.play()

func set_muted(on: bool) -> void:
    # Stop all playing sounds when muting
    _muted = on
    if on:
        for p in _players.values():
            if p.playing:
                p.stop()

func is_muted() -> bool:
    return _muted
```

**Cải tiến từ reference:**
- **Rate limiting** — `_last_play_ms` tracks last play time per effect. Effects with `MIN_INTERVAL_MS` entry are throttled. Prevents sound spam during auto-mark cascade (e.g., placing candy auto-marks 8 cells → 8 LOCK_CELL in <100ms).
- Reference: `_last_play_usec` dict + `_min_interval_sec` per Kind

**Khác biệt với reference:**
- Không polyphony (1 player per effect)
- Không EventBus emission
- Không GameState dependency
- Không `play_people_voice()` variant

---

## File 3: `game/scripts/feedback/bgm_player.gd`

**Trách nhiệm:** Background music playback.

**Tham khảo hành vi từ:** `sound_manager.gd` -> BGM system

```gdscript
# bgm_player.gd
extends Node

var _player: AudioStreamPlayer
var _muted: bool = false

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.bus = &"Master"
    add_child(_player)

func play_track(path: String) -> void:
    # Load stream, set loop, play. Graceful if file missing.

func stop() -> void

func set_muted(on: bool) -> void:
    # Stop playback when muting

func is_playing() -> bool
```

**Khác biệt với reference:**
- Không multi-reason pause system (BgmPauseReason)
- Không ABTestManager music switching
- Không ad integration auto-pause
- Không SFX-triggered BGM pause
- Không debug timer logging
- Single track, simple play/stop

---

## File 4: `game/scripts/feedback/vibration.gd`

**Trách nhiệm:** Haptic feedback wrapper.

**Tham khảo hành vi từ:** `common/vibrate_manager.gd` (443 dòng, 8 levels, 35 positions)

```gdscript
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
    # If disabled or no hardware: return
    # Input.vibrate_handheld(duration)

static func set_on(enabled: bool) -> void:
    _on = enabled

static func is_on() -> bool:
    return _on

static func has_hardware() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
```

**Khác biệt với reference:**
- 3 strengths thay 8 levels
- Tên: `Vibration` thay `VibrateManager`, `Strength` thay `Level`, `SOFT/NORMAL/FIRM` thay `LEVEL1..LEVEL10`
- Không `Pos` enum (35 trigger positions) — caller chọn strength trực tiếp
- Không `_pos_table` lookup
- Không iOS CoreHaptics native plugin
- Không RAM detection (`_RAM_4G_MB`)
- Không ABTest gating (`_Cond.VIBRATE_ADD`)
- Không EventBus emission
- Dùng Godot built-in `Input.vibrate_handheld()`

---

## Tests

### `game/tests/test_feedback.gd`

```gdscript
extends SceneTree

const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")
const Vibration = preload("res://scripts/feedback/vibration.gd")

var _fails: Array[String] = []

func _init() -> void:
    _test_catalog_complete()
    _test_catalog_rate_limits()
    _test_vibration_toggle()
    _test_vibration_pulse_disabled()
    _test_vibration_hardware()
    if _fails.is_empty():
        print("FEEDBACK_PASS")
        quit(0)
    else:
        for f in _fails: printerr(f)
        quit(1)

func _test_catalog_complete() -> void:
    for val in SfxCatalog.Effect.values():
        _assert(SfxCatalog.FILE_MAP.has(val), "path for effect %d" % val)
    _assert(SfxCatalog.FILE_MAP.size() == 11, "11 effects mapped")

func _test_catalog_rate_limits() -> void:
    # LOCK_CELL must have rate limit (prevent auto-mark spam)
    _assert(SfxCatalog.MIN_INTERVAL_MS.has(SfxCatalog.Effect.LOCK_CELL), "LOCK_CELL has rate limit")
    _assert(SfxCatalog.MIN_INTERVAL_MS[SfxCatalog.Effect.LOCK_CELL] > 0, "LOCK_CELL interval > 0")
    # Effects without rate limit should play immediately
    _assert(not SfxCatalog.MIN_INTERVAL_MS.has(SfxCatalog.Effect.CANDY_YES), "CANDY_YES has no rate limit")

func _test_vibration_toggle() -> void:
    Vibration.set_on(true)
    _assert(Vibration.is_on(), "vibration on")
    Vibration.set_on(false)
    _assert(not Vibration.is_on(), "vibration off")
    Vibration.set_on(true)

func _test_vibration_pulse_disabled() -> void:
    Vibration.set_on(false)
    Vibration.pulse(Vibration.Strength.SOFT)  # should not crash
    Vibration.set_on(true)

func _test_vibration_hardware() -> void:
    var hw := Vibration.has_hardware()
    _assert(typeof(hw) == TYPE_BOOL, "returns bool")

func _assert(cond: bool, label: String) -> void:
    if not cond:
        _fails.append("FAIL: " + label)
```

---

## Checklist thực hiện

- [ ] Tạo thư mục `game/scripts/feedback/`
- [ ] Viết `sfx_catalog.gd` — including LOCK_CELL + MIN_INTERVAL_MS
- [ ] Viết test `test_feedback.gd` (fail)
- [ ] Viết `sfx_player.gd` — with rate limiting
- [ ] Viết `bgm_player.gd`
- [ ] Viết `vibration.gd`
- [ ] Chạy test -> pass
- [ ] Commit: `feat(feedback): add SFX with rate limiting, BGM and haptic feedback`
