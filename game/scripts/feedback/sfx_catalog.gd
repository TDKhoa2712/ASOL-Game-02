# sfx_catalog.gd
extends RefCounted

const PcmSynth = preload("res://scripts/feedback/pcm_synth.gd")

enum Effect {
	MARK,           # đánh X
	UNMARK,         # bỏ X (bubble pop)
	CANDY_YES,      # tìm đúng kẹo
	CANDY_NO,       # đặt sai
	HINT_SHOW,      # hiện gợi ý
	STAGE_CLEAR,    # thắng level
	STAGE_FAIL,     # thua level
	BTN_PRESS,      # nhấn nút UI
	BOARD_OPEN,     # mở board
	RESTART,        # restart level
	TAP_BACK,       # back/home navigation
	TOGGLE_ON,      # settings switch on
	TOGGLE_OFF,     # settings switch off
	DIALOG_OPEN,    # confirmation/help opens
	DIALOG_CLOSE,   # confirmation/help closes
	UNDO_X,         # successful undo
	PROGRESS_COMPLETE, # halfway progress milestone
	LOCK_TICK,     # reserved for system auto-mark
	SETTINGS_OPEN, # source whoosh when settings opens
}

const UI_TICK := {
	"freq": 410.0, "end_freq": 275.0, "duration": 0.074, "volume": 0.23,
	"wave": PcmSynth.Wave.TRIANGLE, "noise_mix": 0.2, "noise_decay": 0.01,
	"attack": 0.005, "decay": 0.02, "release": 0.02, "sustain": 0.14,
	"pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL, "low_pass": 1350.0,
}

const SHARED_UI_EFFECTS := [Effect.HINT_SHOW, Effect.BTN_PRESS, Effect.RESTART,
	Effect.TAP_BACK, Effect.TOGGLE_ON, Effect.TOGGLE_OFF, Effect.DIALOG_OPEN,
	Effect.DIALOG_CLOSE, Effect.UNDO_X]

const PRESETS := {
	Effect.MARK: {
		"freq": 600.0, "end_freq": 900.0, "duration": 0.06, "volume": 0.25,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.005, "decay": 0.01,
		"release": 0.02, "sustain": 0.4, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.UNMARK: {
		"freq": 654.0,
		"end_freq": 1376.0,
		"duration": 0.05500000000000001,
		"volume": 0.28,
		"speed": 1.0,
		"noise_mix": 0.0,
		"noise_decay": 0.049999999999999996,
		"attack": 0.005,
		"decay": 0.025,
		"release": 0.02,
		"sustain": 0.1,
		"duty_cycle": 0.5,
		"wave": PcmSynth.Wave.SINE,
		"pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
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
	Effect.HINT_SHOW: UI_TICK,
	Effect.BTN_PRESS: UI_TICK,
	Effect.BOARD_OPEN: {
		"freq": 350.0, "end_freq": 700.0, "duration": 0.25, "volume": 0.20,
		"wave": PcmSynth.Wave.TRIANGLE, "attack": 0.02, "decay": 0.05,
		"release": 0.08, "sustain": 0.4, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.RESTART: UI_TICK,
	Effect.TAP_BACK: UI_TICK,
	Effect.TOGGLE_ON: UI_TICK,
	Effect.TOGGLE_OFF: UI_TICK,
	Effect.DIALOG_OPEN: UI_TICK,
	Effect.DIALOG_CLOSE: UI_TICK,
	Effect.UNDO_X: UI_TICK,
	Effect.SETTINGS_OPEN: {
		"type": "file", "path": "res://assets/audio/sfx/settings-whoosh.ogg",
		"speed": 1.0,
	},
	Effect.PROGRESS_COMPLETE: {
		"freq": 660.0, "end_freq": 990.0, "duration": 0.26, "volume": 0.16,
		"wave": PcmSynth.Wave.SINE, "attack": 0.018, "decay": 0.04,
		"release": 0.085, "sustain": 0.45, "pitch_curve": PcmSynth.PitchCurve.EXPONENTIAL,
	},
	Effect.LOCK_TICK: {
		"freq": 670.0, "end_freq": 550.0, "duration": 0.055, "volume": 0.11,
		"wave": PcmSynth.Wave.TRIANGLE, "noise_mix": 0.06, "noise_decay": 0.015,
		"attack": 0.005, "decay": 0.012, "release": 0.02, "sustain": 0.22,
		"pitch_curve": PcmSynth.PitchCurve.LINEAR, "low_pass": 2600.0,
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
		"speed": 0.9,
	},
}

const PENCIL_PRESETS := {
	Effect.MARK: {
		"duration": 0.176,
		"volume": 0.22,
		"speed": 0.88,
		"low_pass": 1480.0,
		"high_pass": 1070.0,
		"type": "pencil",
	},
}

const PITCH_RANDOMIZE := {
	Effect.MARK: true,
	Effect.UNMARK: true,
	Effect.CANDY_YES: true,
	Effect.CANDY_NO: true,
}

# Rate limiting: minimum ms between plays of same effect
# Prevents repeated effects during a swipe.
const MIN_INTERVAL_MS := {
	Effect.MARK: 100,        # prevent double-fire on fast swipe
	Effect.LOCK_TICK: 90,
}
