# sfx_catalog.gd
extends RefCounted

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

const FILE_MAP := {
	Effect.MARK: "res://audio/sfx/mark.ogg",
	Effect.CANDY_YES: "res://audio/sfx/candy_found.ogg",
	Effect.CANDY_NO: "res://audio/sfx/candy_wrong.ogg",
	Effect.HINT_SHOW: "res://audio/sfx/hint.ogg",
	Effect.STAGE_CLEAR: "res://audio/sfx/win.ogg",
	Effect.STAGE_FAIL: "res://audio/sfx/fail.ogg",
	Effect.BTN_PRESS: "res://audio/sfx/tap.ogg",
	Effect.BOARD_OPEN: "res://audio/sfx/enter.ogg",
	Effect.RESTART: "res://audio/sfx/restart.ogg",
}

# Rate limiting: minimum ms between plays of same effect
# Prevents repeated effects during a swipe.
const MIN_INTERVAL_MS := {
	Effect.MARK: 100,        # prevent double-fire on fast swipe
}
