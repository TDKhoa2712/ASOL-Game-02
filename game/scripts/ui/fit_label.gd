# fit_label.gd — wrapped label that shrinks its font until the text fits max_lines.
# Keeps short captions (rule cards) tidy in every language at any width.
extends Label

const MAX_LINES := 2
const META_FIT := "_fit_text"  # text_scaler leaves fitted labels alone

@export var max_font_size: int = 28
@export var max_lines: int = MAX_LINES
@export var min_font_size: int = 14

func _init() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_meta(META_FIT, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSLATION_CHANGED:
		refit()

func refit() -> void:
	var font := get_theme_font("font")
	var width := size.x
	if font == null or width <= 0.0:
		return
	var fitted := min_font_size
	for font_size in range(max_font_size, min_font_size - 1, -1):
		var block := font.get_multiline_string_size(text, horizontal_alignment, width, font_size)
		if block.y <= font.get_height(font_size) * max_lines + 1.0:
			fitted = font_size
			break
	if get_theme_font_size("font_size") != fitted:
		add_theme_font_size_override("font_size", fitted)
