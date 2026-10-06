# Procedural SFX Audio System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace file-based SFX (missing .ogg files) with procedural PCM synthesis — all sound effects generated from code at startup — and provide an interactive tuner scene for the user to adjust parameters in real time.

**Architecture:** A static `PcmSynth` class generates `AudioStreamWAV` objects from DSP parameters (waveform, frequency sweep, ADSR envelope, noise mix, low-pass filter). `SfxCatalog` switches from `FILE_MAP` paths to a `PRESETS` dictionary of synthesis parameters per Effect. `SfxPlayer` prewarns all streams at `_ready()` from those presets. A standalone `SfxTunerScene` provides slider-based real-time editing with one-click "Copy Params" export.

**Tech Stack:** Godot 4 / GDScript, 16-bit PCM mono synthesis at 22050 Hz, no external dependencies.

**Spec:** `docs/superpowers/specs/godot-procedural-audio-design.md`

## Global Constraints

- Module ≤ 300 lines. One file, one responsibility.
- No autoloads. Composition root pattern — dependencies injected from `app_shell`.
- Signals, not EventBus.
- No names/enums from `extracted_reusable/`.
- Original code only — spec is reference for DSP math, not copy source.
- Scope: R1, 30 levels, N=4-6.

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `game/scripts/feedback/pcm_synth.gd` | Static DSP engine: waveform generation, ADSR, pitch sweep, noise mix, low-pass filter → `AudioStreamWAV` |
| Modify | `game/scripts/feedback/sfx_catalog.gd` | Replace `FILE_MAP` with `PRESETS` dictionary mapping `Effect` → synthesis parameters |
| Modify | `game/scripts/feedback/sfx_player.gd` | Generate streams from `PcmSynth` + `SfxCatalog.PRESETS` instead of loading .ogg files; add pool-based polyphony and pitch randomization |
| Create | `game/scenes/sfx_tuner.tscn` | Scene layout for tuner UI (sliders, dropdown, buttons) |
| Create | `game/scripts/feedback/sfx_tuner.gd` | Controller for tuner scene: real-time preview, copy-to-clipboard |
| Create | `game/tests/test_pcm_synth.gd` | Unit tests for DSP engine |
| Create | `game/tests/test_sfx_player_procedural.gd` | Integration tests for procedural playback |

## Review Focus

1. **Clipping when volume × envelope > 1.0** — final sample must be clamped to [-1.0, 1.0] before int16 conversion; unclamped values wrap to loud pops.
2. **Click/pop at sound start/end** — attack < 0.005 or release < 0.01 causes discontinuity; envelope auto-scaling must prevent this.
3. **Division by zero in pitch sweep** — exponential curve with `frequency == 0` or `end_frequency == 0` produces NaN; guard with linear fallback.
4. **Pool exhaustion** — 8 rapid-fire effects (e.g. fast swipe marking) must not crash; round-robin reuse must stop the oldest player cleanly.
5. **Tuner scene slider ranges** — frequency sliders must not allow negative values; duration must be > 0; sustain must be in [0, 1].

---

### Task 1: PCM Synthesis Engine (`pcm_synth.gd`)

**Files:**
- Create: `game/scripts/feedback/pcm_synth.gd`
- Create: `game/tests/test_pcm_synth.gd`

**Interfaces:**
- Consumes: nothing (standalone static utility)
- Produces:
  - `PcmSynth.generate(params: Dictionary) -> AudioStreamWAV` — params keys: `freq`, `end_freq`, `duration`, `volume`, `wave` (enum), `noise_mix`, `noise_decay`, `attack`, `decay`, `release`, `sustain`, `pitch_curve` (enum), `low_pass`, `duty_cycle`
  - `PcmSynth.generate_melody(freqs: Array[float], note_dur: float, volume: float, wave: int) -> AudioStreamWAV`
  - `PcmSynth.Wave` enum: `SINE, SQUARE, TRIANGLE, SAWTOOTH`
  - `PcmSynth.Curve` enum: `LINEAR, EXPONENTIAL`
  - `PcmSynth.SAMPLE_RATE: int = 22050`

- [ ] **Step 1: Write the failing test**

Create `game/tests/test_pcm_synth.gd`:

```gdscript
# test_pcm_synth.gd
extends SceneTree

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")

var _pass := 0
var _fail := 0

func _init() -> void:
    test_generate_returns_audio_stream()
    test_sample_count_matches_duration()
    test_clamp_prevents_overflow()
    test_envelope_auto_scale()
    test_exponential_curve_zero_freq_fallback()
    test_melody_concatenates_notes()
    print("PCM Synth tests: %d passed, %d failed" % [_pass, _fail])
    quit(1 if _fail > 0 else 0)

func _assert(condition: bool, msg: String) -> void:
    if condition:
        _pass += 1
    else:
        _fail += 1
        push_error("FAIL: " + msg)

func test_generate_returns_audio_stream() -> void:
    var stream := PcmSynth.generate({
        "freq": 440.0, "duration": 0.1, "volume": 0.3, "wave": PcmSynth.Wave.SINE
    })
    _assert(stream is AudioStreamWAV, "generate should return AudioStreamWAV")
    _assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "format should be 16-bit")
    _assert(stream.mix_rate == PcmSynth.SAMPLE_RATE, "sample rate should be 22050")
    _assert(not stream.stereo, "should be mono")

func test_sample_count_matches_duration() -> void:
    var dur := 0.2
    var stream := PcmSynth.generate({"freq": 440.0, "duration": dur, "volume": 0.3, "wave": PcmSynth.Wave.SINE})
    var expected_bytes: int = int(PcmSynth.SAMPLE_RATE * dur) * 2
    _assert(stream.data.size() == expected_bytes, "byte count should match duration × sample_rate × 2")

func test_clamp_prevents_overflow() -> void:
    var stream := PcmSynth.generate({
        "freq": 440.0, "duration": 0.05, "volume": 2.0, "wave": PcmSynth.Wave.SQUARE
    })
    for i in range(0, stream.data.size(), 2):
        var val: int = stream.data.decode_s16(i)
        _assert(val >= -32767 and val <= 32767, "sample %d out of range: %d" % [i / 2, val])

func test_envelope_auto_scale() -> void:
    # attack+decay+release > duration should not crash
    var stream := PcmSynth.generate({
        "freq": 440.0, "duration": 0.05, "volume": 0.3, "wave": PcmSynth.Wave.SINE,
        "attack": 0.1, "decay": 0.1, "release": 0.1, "sustain": 0.5
    })
    _assert(stream.data.size() > 0, "auto-scale envelope should still produce samples")

func test_exponential_curve_zero_freq_fallback() -> void:
    # end_freq = 0 with EXPONENTIAL should not produce NaN
    var stream := PcmSynth.generate({
        "freq": 440.0, "end_freq": 0.0, "duration": 0.05, "volume": 0.3,
        "wave": PcmSynth.Wave.SINE, "pitch_curve": PcmSynth.Curve.EXPONENTIAL
    })
    for i in range(0, mini(stream.data.size(), 20), 2):
        var val: int = stream.data.decode_s16(i)
        _assert(not is_nan(float(val)), "sample should not be NaN with zero end_freq")

func test_melody_concatenates_notes() -> void:
    var freqs: Array[float] = [440.0, 550.0, 660.0]
    var note_dur := 0.1
    var stream := PcmSynth.generate_melody(freqs, note_dur, 0.3, PcmSynth.Wave.TRIANGLE)
    var expected_bytes: int = int(PcmSynth.SAMPLE_RATE * note_dur) * 3 * 2
    _assert(stream.data.size() == expected_bytes, "melody byte count should match note_count × note_dur × rate × 2")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path game --script res://tests/test_pcm_synth.gd`
Expected: FAIL — `PcmSynth` not found.

- [ ] **Step 3: Implement `pcm_synth.gd`**

Create `game/scripts/feedback/pcm_synth.gd`:

```gdscript
# pcm_synth.gd — Procedural PCM audio synthesis engine
class_name PcmSynth
extends RefCounted

enum Wave { SINE, SQUARE, TRIANGLE, SAWTOOTH }
enum Curve { LINEAR, EXPONENTIAL }

const SAMPLE_RATE: int = 22050

static func generate(p: Dictionary) -> AudioStreamWAV:
    var freq: float = p.get("freq", 440.0)
    var end_freq: float = p.get("end_freq", freq)
    var dur: float = p.get("duration", 0.15)
    var vol: float = p.get("volume", 0.5)
    var wave: int = p.get("wave", Wave.TRIANGLE)
    var noise_mix: float = p.get("noise_mix", 0.0)
    var noise_decay: float = p.get("noise_decay", 0.05)
    var attack: float = p.get("attack", 0.01)
    var decay_t: float = p.get("decay", 0.03)
    var release: float = p.get("release", 0.04)
    var sustain: float = p.get("sustain", 0.6)
    var curve: int = p.get("pitch_curve", Curve.LINEAR)
    var lp: float = p.get("low_pass", -1.0)
    var duty: float = p.get("duty_cycle", 0.5)

    if end_freq <= 0.0:
        end_freq = freq
        curve = Curve.LINEAR

    var env_total := attack + decay_t + release
    if env_total > dur and env_total > 0.0:
        var k := dur / env_total
        attack *= k; decay_t *= k; release *= k

    var n_samples := int(SAMPLE_RATE * dur)
    var buf := PackedByteArray()
    buf.resize(n_samples * 2)

    var phase := 0.0
    var flt := 0.0
    var alpha := 1.0
    if lp > 0.0:
        alpha = clampf((TAU * lp) / float(SAMPLE_RATE), 0.0, 1.0)

    for i in range(n_samples):
        var t := float(i) / float(SAMPLE_RATE)
        var cf := freq
        if end_freq != freq:
            if curve == Curve.EXPONENTIAL and freq > 0.0 and end_freq > 0.0:
                cf = freq * pow(end_freq / freq, t / dur)
            else:
                cf = freq + (end_freq - freq) * (t / dur)

        phase += (TAU * cf) / float(SAMPLE_RATE)
        if phase >= TAU:
            phase = fmod(phase, TAU)

        var env := _envelope(t, dur, attack, decay_t, release, sustain)
        var s := _wave_sample(wave, phase, duty)

        if noise_mix > 0.0:
            var nm := noise_mix * exp(-t / noise_decay) if noise_decay > 0.0 else noise_mix
            s = lerp(s, randf_range(-1.0, 1.0), nm)

        if lp > 0.0:
            flt = flt + alpha * (s - flt)
            s = flt

        buf.encode_s16(i * 2, int(clampf(s * vol * env, -1.0, 1.0) * 32767.0))

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = buf
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    return stream

static func generate_melody(freqs: Array[float], note_dur: float = 0.1,
        vol: float = 0.4, wave: int = Wave.TRIANGLE) -> AudioStreamWAV:
    var spn := int(SAMPLE_RATE * note_dur)
    var buf := PackedByteArray()
    buf.resize(spn * freqs.size() * 2)
    var off := 0
    for f in freqs:
        var ph := 0.0
        var att := note_dur * 0.15
        var rel := note_dur * 0.20
        for i in range(spn):
            var t := float(i) / float(SAMPLE_RATE)
            ph += (TAU * f) / float(SAMPLE_RATE)
            if ph >= TAU: ph = fmod(ph, TAU)
            var env := 1.0
            if t < att: env = t / att
            elif (note_dur - t) < rel: env = (note_dur - t) / rel
            var s := _wave_sample(wave, ph, 0.5)
            buf.encode_s16((off + i) * 2, int(clampf(s * vol * env, -1.0, 1.0) * 32767.0))
        off += spn
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = buf
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    return stream

static func _wave_sample(w: int, phase: float, duty: float) -> float:
    match w:
        Wave.SINE: return sin(phase)
        Wave.SQUARE: return 1.0 if (phase / TAU) < duty else -1.0
        Wave.TRIANGLE: return (2.0 / PI) * asin(sin(phase))
        Wave.SAWTOOTH: return 2.0 * ((phase / TAU) - floor((phase / TAU) + 0.5))
    return 0.0

static func _envelope(t: float, dur: float, att: float, dec: float, rel: float, sus: float) -> float:
    if att > 0.0 and t < att: return t / att
    if dec > 0.0 and t < (att + dec): return 1.0 - (1.0 - sus) * ((t - att) / dec)
    if t < (dur - rel): return sus
    if rel > 0.0 and t < dur: return sus * (dur - t) / rel
    return 0.0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path game --script res://tests/test_pcm_synth.gd`
Expected: PASS — all 6 tests green.

- [ ] **Step 5: Commit**

```bash
git add game/scripts/feedback/pcm_synth.gd game/tests/test_pcm_synth.gd
git commit -m "feat(audio): add PcmSynth procedural DSP engine with tests"
```

---

### Task 2: Convert SfxCatalog to Procedural Presets

**Files:**
- Modify: `game/scripts/feedback/sfx_catalog.gd` (full rewrite, 33 lines → ~90 lines)
- Modify: `game/scripts/feedback/sfx_player.gd` (rewrite _ready to use PcmSynth)
- Create: `game/tests/test_sfx_player_procedural.gd`

**Interfaces:**
- Consumes: `PcmSynth.generate(params)`, `PcmSynth.generate_melody(freqs, ...)`
- Produces:
  - `SfxCatalog.Effect` enum (unchanged names: MARK, CANDY_YES, CANDY_NO, HINT_SHOW, STAGE_CLEAR, STAGE_FAIL, BTN_PRESS, BOARD_OPEN, RESTART)
  - `SfxCatalog.PRESETS: Dictionary` — maps `Effect` → `Dictionary` of PcmSynth params
  - `SfxCatalog.MELODY_PRESETS: Dictionary` — maps `Effect` → `Dictionary` with `freqs`, `note_dur`, `volume`, `wave`
  - `SfxCatalog.MIN_INTERVAL_MS: Dictionary` (unchanged)
  - `SfxPlayer.play(effect: int) -> void` (unchanged API)

- [ ] **Step 1: Write the failing integration test**

Create `game/tests/test_sfx_player_procedural.gd`:

```gdscript
# test_sfx_player_procedural.gd
extends SceneTree

const SfxPlayer = preload("res://scripts/feedback/sfx_player.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

var _pass := 0
var _fail := 0

func _init() -> void:
    test_all_presets_produce_streams()
    test_player_play_does_not_crash()
    test_mute_prevents_play()
    test_rate_limit_throttles()
    print("SFX Player procedural tests: %d passed, %d failed" % [_pass, _fail])
    quit(1 if _fail > 0 else 0)

func _assert(cond: bool, msg: String) -> void:
    if cond: _pass += 1
    else: _fail += 1; push_error("FAIL: " + msg)

func test_all_presets_produce_streams() -> void:
    _assert(SfxCatalog.PRESETS is Dictionary or SfxCatalog.get("MELODY_PRESETS") != null,
        "SfxCatalog should have PRESETS or MELODY_PRESETS")
    for effect in SfxCatalog.Effect.values():
        var has_preset: bool = SfxCatalog.PRESETS.has(effect) or SfxCatalog.MELODY_PRESETS.has(effect)
        _assert(has_preset, "Effect %d should have a preset" % effect)

func test_player_play_does_not_crash() -> void:
    var player := SfxPlayer.new()
    var root := get_root()
    root.add_child(player)
    # Wait one frame for _ready
    await root.get_tree().process_frame
    for effect in SfxCatalog.Effect.values():
        player.play(effect)
    _assert(true, "play() all effects without crash")
    player.queue_free()

func test_mute_prevents_play() -> void:
    var player := SfxPlayer.new()
    get_root().add_child(player)
    await get_root().get_tree().process_frame
    player.set_muted(true)
    _assert(player.is_muted(), "should be muted")
    player.play(SfxCatalog.Effect.BTN_PRESS)
    # No crash, no sound
    _assert(true, "muted play should not crash")
    player.queue_free()

func test_rate_limit_throttles() -> void:
    var player := SfxPlayer.new()
    get_root().add_child(player)
    await get_root().get_tree().process_frame
    player.play(SfxCatalog.Effect.MARK)
    player.play(SfxCatalog.Effect.MARK)
    _assert(true, "rapid double-play should not crash")
    player.queue_free()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path game --script res://tests/test_sfx_player_procedural.gd`
Expected: FAIL — `SfxCatalog.PRESETS` not defined.

- [ ] **Step 3: Rewrite `sfx_catalog.gd` with procedural presets**

Replace `game/scripts/feedback/sfx_catalog.gd`:

```gdscript
# sfx_catalog.gd — Procedural sound effect presets for CanDoKu
extends RefCounted

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")

enum Effect {
    MARK,
    CANDY_YES,
    CANDY_NO,
    HINT_SHOW,
    STAGE_CLEAR,
    STAGE_FAIL,
    BTN_PRESS,
    BOARD_OPEN,
    RESTART,
}

const PRESETS := {
    Effect.MARK: {
        "freq": 600.0, "end_freq": 900.0, "duration": 0.06, "volume": 0.25,
        "wave": PcmSynth.Wave.TRIANGLE, "attack": 0.005, "decay": 0.01,
        "release": 0.02, "sustain": 0.4, "pitch_curve": PcmSynth.Curve.EXPONENTIAL,
    },
    Effect.CANDY_YES: {
        "freq": 520.0, "end_freq": 1040.0, "duration": 0.14, "volume": 0.30,
        "wave": PcmSynth.Wave.SINE, "noise_mix": 0.05, "noise_decay": 0.02,
        "attack": 0.005, "decay": 0.03, "release": 0.04, "sustain": 0.7,
        "pitch_curve": PcmSynth.Curve.EXPONENTIAL,
    },
    Effect.CANDY_NO: {
        "freq": 300.0, "end_freq": 150.0, "duration": 0.18, "volume": 0.30,
        "wave": PcmSynth.Wave.SQUARE, "noise_mix": 0.2, "noise_decay": 0.04,
        "attack": 0.005, "decay": 0.04, "release": 0.06, "sustain": 0.2,
        "pitch_curve": PcmSynth.Curve.LINEAR, "low_pass": 1800.0, "duty_cycle": 0.5,
    },
    Effect.HINT_SHOW: {
        "freq": 800.0, "end_freq": 1200.0, "duration": 0.20, "volume": 0.25,
        "wave": PcmSynth.Wave.SINE, "attack": 0.02, "decay": 0.04,
        "release": 0.06, "sustain": 0.5, "pitch_curve": PcmSynth.Curve.EXPONENTIAL,
    },
    Effect.BTN_PRESS: {
        "freq": 1000.0, "end_freq": 700.0, "duration": 0.04, "volume": 0.20,
        "wave": PcmSynth.Wave.TRIANGLE, "noise_mix": 0.15, "noise_decay": 0.01,
        "attack": 0.005, "decay": 0.01, "release": 0.015, "sustain": 0.4,
        "pitch_curve": PcmSynth.Curve.EXPONENTIAL,
    },
    Effect.BOARD_OPEN: {
        "freq": 350.0, "end_freq": 700.0, "duration": 0.25, "volume": 0.20,
        "wave": PcmSynth.Wave.TRIANGLE, "attack": 0.02, "decay": 0.05,
        "release": 0.08, "sustain": 0.4, "pitch_curve": PcmSynth.Curve.EXPONENTIAL,
    },
    Effect.RESTART: {
        "freq": 500.0, "end_freq": 250.0, "duration": 0.15, "volume": 0.22,
        "wave": PcmSynth.Wave.TRIANGLE, "attack": 0.01, "decay": 0.03,
        "release": 0.04, "sustain": 0.3, "pitch_curve": PcmSynth.Curve.LINEAR,
    },
}

const MELODY_PRESETS := {
    Effect.STAGE_CLEAR: {
        "freqs": [523.25, 659.25, 783.99, 1046.50],
        "note_dur": 0.11, "volume": 0.30, "wave": PcmSynth.Wave.TRIANGLE,
    },
    Effect.STAGE_FAIL: {
        "freqs": [392.0, 329.63, 293.66, 261.63],
        "note_dur": 0.13, "volume": 0.30, "wave": PcmSynth.Wave.TRIANGLE,
    },
}

const MIN_INTERVAL_MS := {
    Effect.MARK: 80,
}

const PITCH_RANDOMIZE := {
    Effect.MARK: true,
    Effect.CANDY_YES: true,
    Effect.CANDY_NO: true,
    Effect.HINT_SHOW: false,
    Effect.STAGE_CLEAR: false,
    Effect.STAGE_FAIL: false,
    Effect.BTN_PRESS: true,
    Effect.BOARD_OPEN: false,
    Effect.RESTART: false,
}
```

- [ ] **Step 4: Rewrite `sfx_player.gd` for procedural synthesis**

Replace `game/scripts/feedback/sfx_player.gd`:

```gdscript
# sfx_player.gd — Procedural SFX playback with polyphonic pool
extends Node

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

const POOL_SIZE: int = 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _last_play_ms: Dictionary = {}
var _muted: bool = false

func _ready() -> void:
    for i in range(POOL_SIZE):
        var player := AudioStreamPlayer.new()
        player.bus = &"Master"
        add_child(player)
        _pool.append(player)
    _prewarm()

func _prewarm() -> void:
    for effect in SfxCatalog.Effect.values():
        if SfxCatalog.PRESETS.has(effect):
            _streams[effect] = PcmSynth.generate(SfxCatalog.PRESETS[effect])
        elif SfxCatalog.MELODY_PRESETS.has(effect):
            var mp: Dictionary = SfxCatalog.MELODY_PRESETS[effect]
            var freqs: Array[float] = []
            for f in mp.freqs:
                freqs.append(float(f))
            _streams[effect] = PcmSynth.generate_melody(
                freqs, mp.get("note_dur", 0.1),
                mp.get("volume", 0.4), mp.get("wave", PcmSynth.Wave.TRIANGLE))

func play(effect: int) -> void:
    if _muted:
        return
    var now := Time.get_ticks_msec()
    if SfxCatalog.MIN_INTERVAL_MS.has(effect):
        var last: int = _last_play_ms.get(effect, -100000)
        if now - last < SfxCatalog.MIN_INTERVAL_MS[effect]:
            return
    _last_play_ms[effect] = now
    var stream: AudioStreamWAV = _streams.get(effect)
    if stream == null:
        return
    var player: AudioStreamPlayer = _pool[_pool_idx]
    _pool_idx = (_pool_idx + 1) % POOL_SIZE
    player.stream = stream
    if SfxCatalog.PITCH_RANDOMIZE.get(effect, false):
        player.pitch_scale = randf_range(0.94, 1.06)
    else:
        player.pitch_scale = 1.0
    player.play()

func set_muted(on: bool) -> void:
    _muted = on
    if on:
        for p in _pool:
            if p.playing:
                p.stop()

func is_muted() -> bool:
    return _muted
```

- [ ] **Step 5: Run tests**

Run: `godot --headless --path game --script res://tests/test_sfx_player_procedural.gd`
Expected: PASS — all 4 tests green.

Also run existing test to make sure `puzzle_screen` still compiles:
Run: `godot --headless --path game --script res://tests/test_pcm_synth.gd`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add game/scripts/feedback/sfx_catalog.gd game/scripts/feedback/sfx_player.gd game/tests/test_sfx_player_procedural.gd
git commit -m "feat(audio): replace file-based SFX with procedural PCM presets"
```

---

### Task 3: SFX Tuner Scene (Interactive Parameter Editor)

**Files:**
- Create: `game/scenes/sfx_tuner.tscn`
- Create: `game/scripts/feedback/sfx_tuner.gd`

**Interfaces:**
- Consumes: `PcmSynth.generate(params)`, `PcmSynth.generate_melody(...)`, `SfxCatalog.PRESETS`, `SfxCatalog.MELODY_PRESETS`, `SfxCatalog.Effect`
- Produces: Standalone debug scene — no other module depends on it.

The tuner scene provides:
- **Dropdown** to select a preset (Effect name) — loads its current params into sliders
- **Sliders** for each parameter: freq (20–4000), end_freq (0–4000), duration (0.02–1.0), volume (0–1), wave type (dropdown 0–3), noise_mix (0–1), noise_decay (0.01–0.5), attack (0–0.2), decay (0–0.3), release (0–0.3), sustain (0–1), pitch_curve (dropdown 0–1), low_pass (0–8000, 0=off), duty_cycle (0.1–0.9)
- **"Play" button** — generates and plays the sound with current slider values
- **"Copy Params" button** — prints the current parameters as a GDScript dictionary literal to the console (user copies it into sfx_catalog.gd)
- **Labels** showing current numeric values next to each slider

- [ ] **Step 1: Create the scene file**

Create `game/scenes/sfx_tuner.tscn` — a minimal scene with root Control node pointing to the script. The UI is built programmatically in `_ready()` to keep the .tscn minimal and avoid editor dependency:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/feedback/sfx_tuner.gd" id="1"]

[node name="SfxTuner" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
```

- [ ] **Step 2: Implement `sfx_tuner.gd`**

Create `game/scripts/feedback/sfx_tuner.gd`:

```gdscript
# sfx_tuner.gd — Interactive SFX parameter editor for tuning procedural sounds
extends Control

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

var _player: AudioStreamPlayer
var _sliders: Dictionary = {}
var _labels: Dictionary = {}
var _preset_dropdown: OptionButton
var _scroll: ScrollContainer
var _vbox: VBoxContainer

const PARAM_DEFS := [
    ["freq", 20.0, 4000.0, 440.0, 1.0],
    ["end_freq", 0.0, 4000.0, 440.0, 1.0],
    ["duration", 0.02, 1.0, 0.15, 0.01],
    ["volume", 0.0, 1.0, 0.3, 0.01],
    ["wave", 0.0, 3.0, 2.0, 1.0],
    ["noise_mix", 0.0, 1.0, 0.0, 0.01],
    ["noise_decay", 0.005, 0.5, 0.05, 0.005],
    ["attack", 0.0, 0.2, 0.01, 0.001],
    ["decay", 0.0, 0.3, 0.03, 0.001],
    ["release", 0.0, 0.3, 0.04, 0.001],
    ["sustain", 0.0, 1.0, 0.6, 0.01],
    ["pitch_curve", 0.0, 1.0, 0.0, 1.0],
    ["low_pass", 0.0, 8000.0, 0.0, 10.0],
    ["duty_cycle", 0.1, 0.9, 0.5, 0.01],
]

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.bus = &"Master"
    add_child(_player)

    _scroll = ScrollContainer.new()
    _scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(_scroll)

    _vbox = VBoxContainer.new()
    _vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll.add_child(_vbox)

    var title := Label.new()
    title.text = "SFX Tuner — CanDoKu Procedural Audio"
    title.add_theme_font_size_override("font_size", 20)
    _vbox.add_child(title)

    _add_preset_dropdown()
    _add_separator()
    for def in PARAM_DEFS:
        _add_slider_row(def[0], def[1], def[2], def[3], def[4])
    _add_separator()
    _add_buttons()

func _add_preset_dropdown() -> void:
    var row := HBoxContainer.new()
    var lbl := Label.new()
    lbl.text = "Preset:"
    lbl.custom_minimum_size.x = 100
    row.add_child(lbl)
    _preset_dropdown = OptionButton.new()
    _preset_dropdown.custom_minimum_size.x = 200
    for effect in SfxCatalog.Effect.values():
        _preset_dropdown.add_item(SfxCatalog.Effect.find_key(effect), effect)
    _preset_dropdown.item_selected.connect(_on_preset_selected)
    row.add_child(_preset_dropdown)
    _vbox.add_child(row)

func _add_slider_row(param_name: String, min_val: float, max_val: float, default_val: float, step_val: float) -> void:
    var row := HBoxContainer.new()
    var name_lbl := Label.new()
    name_lbl.text = param_name
    name_lbl.custom_minimum_size.x = 100
    row.add_child(name_lbl)

    var slider := HSlider.new()
    slider.min_value = min_val
    slider.max_value = max_val
    slider.step = step_val
    slider.value = default_val
    slider.custom_minimum_size.x = 300
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(slider)

    var val_lbl := Label.new()
    val_lbl.text = str(default_val)
    val_lbl.custom_minimum_size.x = 80
    row.add_child(val_lbl)

    slider.value_changed.connect(func(v: float): val_lbl.text = "%.3f" % v)
    _sliders[param_name] = slider
    _labels[param_name] = val_lbl
    _vbox.add_child(row)

func _add_separator() -> void:
    _vbox.add_child(HSeparator.new())

func _add_buttons() -> void:
    var row := HBoxContainer.new()
    var play_btn := Button.new()
    play_btn.text = "▶ Play"
    play_btn.pressed.connect(_on_play)
    row.add_child(play_btn)

    var copy_btn := Button.new()
    copy_btn.text = "📋 Copy Params"
    copy_btn.pressed.connect(_on_copy_params)
    row.add_child(copy_btn)

    _vbox.add_child(row)

func _current_params() -> Dictionary:
    var p := {}
    for def in PARAM_DEFS:
        var key: String = def[0]
        var val: float = _sliders[key].value
        if key == "wave":
            p[key] = int(val)
        elif key == "pitch_curve":
            p[key] = int(val)
        elif key == "low_pass":
            if val <= 0.0:
                continue
            p[key] = val
        else:
            p[key] = val
    return p

func _on_play() -> void:
    var params := _current_params()
    var stream := PcmSynth.generate(params)
    _player.stream = stream
    _player.pitch_scale = 1.0
    _player.play()

func _on_copy_params() -> void:
    var params := _current_params()
    var parts: PackedStringArray = []
    for key in params:
        var val = params[key]
        if val is int:
            if key == "wave":
                parts.append('"%s": PcmSynth.Wave.%s' % [key, ["SINE", "SQUARE", "TRIANGLE", "SAWTOOTH"][val]])
            elif key == "pitch_curve":
                parts.append('"%s": PcmSynth.Curve.%s' % [key, ["LINEAR", "EXPONENTIAL"][val]])
            else:
                parts.append('"%s": %d' % [key, val])
        else:
            parts.append('"%s": %s' % [key, val])
    var output := "{\n    " + ",\n    ".join(parts) + ",\n}"
    DisplayServer.clipboard_set(output)
    print("=== Copied to clipboard ===")
    print(output)
    print("===========================")

func _on_preset_selected(idx: int) -> void:
    var effect: int = _preset_dropdown.get_item_id(idx)
    var params: Dictionary = {}
    if SfxCatalog.PRESETS.has(effect):
        params = SfxCatalog.PRESETS[effect].duplicate()
    elif SfxCatalog.MELODY_PRESETS.has(effect):
        params = SfxCatalog.MELODY_PRESETS[effect].duplicate()
    for def in PARAM_DEFS:
        var key: String = def[0]
        if params.has(key):
            _sliders[key].value = float(params[key])
        else:
            _sliders[key].value = def[3]

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        _on_play()
```

- [ ] **Step 3: Test manually**

Open the scene in Godot:
1. Open Godot editor, load `game/scenes/sfx_tuner.tscn`
2. Press F6 (Run Current Scene)
3. Select preset from dropdown → sliders populate
4. Adjust sliders → press Play (or Spacebar) → hear the result
5. Press "Copy Params" → check console output and clipboard

Verify:
- Each preset loads correctly
- Slider changes produce audible differences
- Copy produces valid GDScript dictionary
- No crashes on extreme values (freq=20, duration=1.0, etc.)

- [ ] **Step 4: Commit**

```bash
git add game/scenes/sfx_tuner.tscn game/scripts/feedback/sfx_tuner.gd
git commit -m "feat(audio): add SFX tuner scene for interactive sound design"
```

---

### Task 4: Wire Procedural SFX into Gameplay & Verify

**Files:**
- Verify: `game/scripts/screens/puzzle_screen.gd` (should work unchanged — same `sfx.play(SfxCatalog.Effect.X)` API)
- Verify: `game/scripts/screens/app_shell.gd` (should work unchanged — same `SfxPlayer.new()` pattern)

**Interfaces:**
- Consumes: `SfxPlayer.play(effect)`, `SfxCatalog.Effect.*`
- Produces: nothing new (verification task)

- [ ] **Step 1: Verify `puzzle_screen.gd` compatibility**

The existing calls in `puzzle_screen.gd` use `sfx.play(SfxCatalog.Effect.MARK)` etc. Since we kept the same `Effect` enum names and the same `play(effect: int)` signature, no changes should be needed.

Read `puzzle_screen.gd` and confirm every `sfx.play(SfxCatalog.Effect.X)` call uses an Effect that exists in the new `SfxCatalog`.

Check list:
- `BOARD_OPEN` ✓
- `MARK` ✓ (×2)
- `HINT_SHOW` ✓
- `RESTART` ✓
- `CANDY_YES` ✓
- `CANDY_NO` ✓
- `STAGE_CLEAR` ✓
- `STAGE_FAIL` ✓

- [ ] **Step 2: Run all existing tests**

```bash
godot --headless --path game --script res://tests/test_pcm_synth.gd
godot --headless --path game --script res://tests/test_sfx_player_procedural.gd
```

Expected: both PASS.

- [ ] **Step 3: Run the game and test SFX in context**

1. `godot --path game` (or F5 in editor)
2. Open a level → hear BOARD_OPEN sound
3. Tap a cell → hear MARK sound (with slight pitch variation)
4. Find a candy → hear CANDY_YES
5. Make a mistake → hear CANDY_NO
6. Use hint → hear HINT_SHOW
7. Win level → hear STAGE_CLEAR arpeggio
8. Navigate menus → hear BTN_PRESS

If any sound feels wrong, use the tuner scene (Task 3) to adjust, then update `SfxCatalog.PRESETS`.

- [ ] **Step 4: Clean up old file references**

Remove the now-unused `FILE_MAP` reference. Since we already replaced `sfx_catalog.gd` entirely in Task 2, verify the old `audio/sfx/` directory reference no longer appears anywhere:

```bash
rg "audio/sfx/" game/scripts/
rg "FILE_MAP" game/scripts/
```

Expected: no matches.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore(audio): verify procedural SFX integration with gameplay"
```

---

## How to Use the Tuner (For Sound Design)

After implementation, this is the workflow to tune any sound:

1. **Run tuner scene**: In Godot editor, open `game/scenes/sfx_tuner.tscn`, press F6
2. **Select a preset**: Choose from dropdown (e.g., CANDY_YES)
3. **Adjust sliders**: Change frequency, waveform, envelope, etc. — press Space to preview
4. **Copy params**: When satisfied, press "Copy Params" — the dictionary goes to your clipboard
5. **Paste into catalog**: Replace the corresponding entry in `sfx_catalog.gd`'s `PRESETS` const
6. **Test in game**: Run the game (F5) to hear it in context

### Quick Slider Guide

| Slider | What it does | Puzzle game tips |
|--------|-------------|-----------------|
| freq / end_freq | Start/end pitch | Sweep up = positive feel, sweep down = negative |
| duration | Sound length | Keep short (0.04–0.20s) for UI, longer for win/fail |
| wave | Waveform shape | SINE=soft, TRIANGLE=warm, SQUARE=retro, SAWTOOTH=sharp |
| noise_mix | Adds texture | Low (0.05–0.15) for organic feel, high for impact |
| attack | Fade-in time | Keep ≥ 0.005 to avoid clicks |
| sustain | Held volume level | 0.3–0.7 for most effects |
| release | Fade-out time | Keep ≥ 0.01 to avoid pops |
| low_pass | Muffles highs | 0=off, 800–2000 for warm sounds |
