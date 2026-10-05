# sfx_catalog.gd
extends RefCounted

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")

enum Effect {
	MARK,           # đánh X
	CANDY_YES,      # tìm đúng kẹo
	CANDY_NO,       # đặt sai
	HINT_SHOW,      # hiện gợi ý
	STAGE_CLEAR,    # thắng level
	STAGE_FAIL,     # thua level
	BTN_PRESS,      # nhấn nút UI
	BOARD_OPEN,     # mở board
	RESTART,        # restart level
}

const PRESETS := {
	Effect.MARK: {
		"freq": 600.0, "end_freq": 900.0, "duration": 0.06, "volume": 0.25,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.005, "decay": 0.01,
		"release": 0.02, "sustain": 0.4, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.CANDY_YES: {
		"freq": 520.0, "end_freq": 1040.0, "duration": 0.14, "volume": 0.30,
		"wave": PcmSynth.Wave.SINE, "noise_mix": 0.05, "noise_decay": 0.02,
		"attack": 0.005, "decay": 0.03, "release": 0.04, "sustain": 0.7,
		"pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.CANDY_NO: {
		"freq": 300.0, "end_freq": 150.0, "duration": 0.18, "volume": 0.30,
		"wave": PcmSynth.Wave.SQUARE, "noise_mix": 0.2, "noise_decay": 0.04,
		"attack": 0.005, "decay": 0.04, "release": 0.06, "sustain": 0.2,
		"pitch_curve": PcmSynth.PitchCurve.LINEAR, "low_pass": 1800.0, "duty_cycle": 0.5,
	},
	Effect.HINT_SHOW: {
		"freq": 800.0, "end_freq": 1200.0, "duration": 0.20, "volume": 0.25,
		"wave": PcmSynth.Wave.SINE, "attack": 0.02, "decay": 0.04,
		"release": 0.06, "sustain": 0.5, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.BTN_PRESS: {
		"freq": 1000.0, "end_freq": 700.0, "duration": 0.04, "volume": 0.20,
		"wave": PcmSynth.Wave.TRIANGLE, "noise_mix": 0.15, "noise_decay": 0.01,
		"attack": 0.005, "decay": 0.01, "release": 0.015, "sustain": 0.4,
		"pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.BOARD_OPEN: {
		"freq": 350.0, "end_freq": 700.0, "duration": 0.25, "volume": 0.20,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.02, "decay": 0.05,
		"release": 0.08, "sustain": 0.4, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.RESTART: {
		"freq": 500.0, "end_freq": 250.0, "duration": 0.15, "volume": 0.22,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.01, "decay": 0.03,
		"release": 0.04, "sustain": 0.3, "pitch_curve": PcmSynth.PitchCurve.LINEAR,
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

const PITCH_RANDOMIZE := {
	Effect.MARK: true,
	Effect.CANDY_YES: true,
	Effect.CANDY_NO: true,
	Effect.BTN_PRESS: true,
}

# Rate limiting: minimum ms between plays of same effect
# Prevents repeated effects during a swipe.
const MIN_INTERVAL_MS := {
	Effect.MARK: 100,        # prevent double-fire on fast swipe
}
