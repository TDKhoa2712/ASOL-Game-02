extends RefCounted

const CANDY_TYPES: Array[String] = [
	"bonbon", "lollipop", "gummy_drop", "hard_candy", "toffee", "cotton_puff"
]

const CANDY_COLORS := {
	"bonbon": {
		"body": Color("#E8847A"),
		"body_light": Color("#F0A098"),
		"body_dark": Color("#D8706A"),
		"wrapper": Color("#FFD18A"),
		"wrapper_dark": Color("#E8BC70"),
		"outline": Color("#8C433B"),
		"highlight": Color("#FFF1D4"),
	},
	"lollipop": {
		"spiral_1": Color("#D94F4F"),
		"spiral_2": Color("#FFF5F0"),
		"rim": Color("#B33A3A"),
		"stick": Color("#C4A882"),
		"stick_outline": Color("#8B7355"),
	},
	"gummy_drop": {
		"body": Color("#5DC9A8"),
		"body_light": Color("#7DDCBE"),
		"body_dark": Color("#3DAF8A"),
		"edge": Color("#2D7F6A"),
	},
	"hard_candy": {
		"body_light": Color("#B8A0E8"),
		"body": Color("#9B7ED8"),
		"body_dark": Color("#7B5DC0"),
		"outline": Color("#5A3D9E"),
	},
	"toffee": {
		"body": Color("#A06E2E"),
		"foil": Color("#E8C34A"),
		"foil_light": Color("#F0D86A"),
		"foil_dark": Color("#C4A030"),
		"outline": Color("#7A5420"),
	},
	"cotton_puff": {
		"body": Color("#F4B8C1"),
		"body_light": Color("#F8D0D6"),
		"body_dark": Color("#E8A0AC"),
		"shadow": Color("#D08090"),
	},
}

const GIVEN_HALO := Color("#FFF7E8")
const GIVEN_HALO_OPACITY := 0.4
const ERROR_TINT := Color("#D94040")
const ERROR_X := Color("#D94040")
const ERROR_OPACITY := 0.4
