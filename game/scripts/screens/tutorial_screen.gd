# Mandatory onboarding overlay (RST-028). Shown over Home until the player
# finishes it once; Help can replay it as practice without touching progress.
extends Control

const TutorialFlow = preload("res://scripts/campaign/tutorial_flow.gd")
const PuzzleBoard = preload("res://scripts/screens/puzzle_board.gd")
const TutorialOverlay = preload("res://scripts/screens/tutorial_overlay.gd")
const ConfettiLayer = preload("res://scripts/ui/confetti_layer.gd")
const ActionButton = preload("res://scripts/ui/action_button.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const FontTokens = preload("res://scripts/theme/font_tokens.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const SfxCatalog = preload("res://scripts/feedback/sfx_catalog.gd")

signal completed()

const DONE_ID := "ONBOARD"
const DIM_BG := Color("#3E3936")
const LIT_BG := Color("#FFF6E2")
const EMPHASIS := "#3D8BEB"
const HAND_SVG := '<svg width="56" height="64" viewBox="0 0 56 64" xmlns="http://www.w3.org/2000/svg"><path d="M20 4 c3 0 5 2 5 5 v19 l3 -1 c2.5 -0.6 5 1 5.5 3.5 l0.3 1 l2.4 -0.6 c2.6 -0.6 5 1 5.6 3.6 l0.2 0.8 l1.6 -0.4 c2.8 -0.6 5.4 1.4 5.8 4.2 l1.6 11.4 C55.6 60 50 64 43 64 H29 c-4.6 0 -8.8 -2.4 -11.1 -6.3 L6.6 39 c-1.5 -2.5 -0.8 -5.8 1.6 -7.4 c2.2 -1.4 5.1 -1 6.8 1 L15 34 V9 c0 -3 2 -5 5 -5 z" fill="#FFFFFF" stroke="#7A4A2A" stroke-width="3" stroke-linejoin="round"/></svg>'

var flow: TutorialFlow = TutorialFlow.new()
var practice: bool = false
var guide: Variant = null
var sfx: Variant = null
var bg: ColorRect
var bubble_text: RichTextLabel
var board: PuzzleBoard
var overlay: TutorialOverlay
var hand: TextureRect
var action_button: Button
var hint_button: Button
var _hand_tween: Tween = null
var _hint_shown: bool = false
var _shown_id: String = ""
var _busy: bool = false
# Seconds the finished step stays on screen before the next one fades in.
static var step_pause := 1.1
const FADE_SEC := 0.25
const MISS_SEC := 2.0

# Adds the overlay to host unless the player already finished it.
static func attach(host: Control, runtime: Variant, practice_run: bool = false, sfx_player: Variant = null) -> Control:
	var g: Variant = runtime.tutorial if runtime != null and "tutorial" in runtime else null
	if not practice_run and (g == null or g.has_seen(DONE_ID)):
		return null
	var s: Control = (load("res://scripts/screens/tutorial_screen.gd") as GDScript).new()
	s.practice = practice_run; s.guide = g; s.sfx = sfx_player
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(s)
	return s

func _ready() -> void:
	name = "TutorialScreen"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	flow.changed.connect(_on_flow_changed)
	flow.missed.connect(_on_missed)
	flow.finished.connect(_finish)
	board.configure(flow.session)
	board.cell_double_tapped.connect(func(r: int, c: int) -> void: if not _busy: _input_result(flow.double_tap(r, c), r, c, true))
	board.cell_tapped.connect(func(r: int, c: int) -> void: if not _busy: _input_result(flow.tap(r, c), r, c, false))
	board.cell_swiped.connect(func(cells: Array) -> void: if not _busy: _input_result(flow.stroke(cells), -1, -1, false))
	_refresh.call_deferred()

func _build() -> void:
	bg = ColorRect.new(); bg.color = DIM_BG; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var col := VBoxContainer.new(); col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 56; col.offset_right = -56; col.offset_top = 200; col.offset_bottom = -120
	col.add_theme_constant_override("separation", 72); add_child(col)
	var panel := PanelContainer.new(); panel.name = "Bubble"
	var sb := StyleBoxFlat.new(); sb.bg_color = Color.WHITE; sb.border_color = Color("#FFC56A"); sb.set_border_width_all(10)
	sb.set_corner_radius_all(56); sb.content_margin_left = 48; sb.content_margin_right = 48; sb.content_margin_top = 36; sb.content_margin_bottom = 36
	sb.shadow_color = Color(0, 0, 0, 0.18); sb.shadow_size = 12; sb.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", sb); col.add_child(panel)
	bubble_text = RichTextLabel.new(); bubble_text.name = "BubbleText"; bubble_text.bbcode_enabled = true; bubble_text.fit_content = true
	bubble_text.scroll_active = false; bubble_text.mouse_filter = Control.MOUSE_FILTER_IGNORE; bubble_text.custom_minimum_size = Vector2(0, 120)
	bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bubble_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bf := FontTokens.body_bold()
	if bf != null: bubble_text.add_theme_font_override("normal_font", bf); bubble_text.add_theme_font_override("bold_font", bf)
	bubble_text.add_theme_font_size_override("normal_font_size", 50); bubble_text.add_theme_color_override("default_color", Color("#8A4F4A"))
	panel.add_child(bubble_text)
	var holder := Control.new(); holder.custom_minimum_size = Vector2(960, 960); holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(holder)
	board = PuzzleBoard.new(); board.name = "Board"; board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); holder.add_child(board)
	overlay = TutorialOverlay.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); holder.add_child(overlay)
	overlay.bind(board.get_cell_rect)
	var actions := CenterContainer.new(); actions.custom_minimum_size = Vector2(0, 160); col.add_child(actions)
	var row := HBoxContainer.new(); actions.add_child(row)
	action_button = ActionButton.create("", Color("#41C34B"), Color("#239A35"), Color(0, 0, 0, 0), 56, 150, 12)
	action_button.name = "ActionButton"; action_button.custom_minimum_size = Vector2(640, 150); action_button.pressed.connect(_on_action)
	row.add_child(action_button)
	hint_button = ActionButton.create("", Color.WHITE, Color("#E7D3CC"), Color(0, 0, 0, 0), 46, 130, 8)
	hint_button.name = "HintButton"; hint_button.custom_minimum_size = Vector2(640, 130)
	hint_button.add_theme_color_override("font_color", Color("#8A4F4A")); hint_button.pressed.connect(_on_hint)
	row.add_child(hint_button)
	hand = TextureRect.new(); hand.name = "Hand"; hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := Image.new(); img.load_svg_from_string(HAND_SVG, 3.2); hand.texture = ImageTexture.create_from_image(img)
	hand.size = hand.texture.get_size(); hand.z_index = 5; add_child(hand)

# Turns **word** markers in the translated text into colored emphasis.
static func emphasize(text: String) -> String:
	var parts := text.split("**")
	var out := ""
	for i in parts.size():
		out += ("[color=%s]%s[/color]" % [EMPHASIS, parts[i]]) if i % 2 == 1 else parts[i]
	return "[center]" + out + "[/center]"

# Same step: update targets at once. New step: hold the result, then fade over.
func _on_flow_changed() -> void:
	var s := flow.step()
	if s.is_empty() or s.id == _shown_id or _shown_id.is_empty() or step_pause <= 0.0 or not is_inside_tree():
		_refresh()
		return
	_busy = true
	hand.visible = false
	if _hand_tween != null: _hand_tween.kill()
	overlay.show_spotlight(overlay._lit, [])
	await get_tree().create_timer(step_pause).timeout
	if not is_inside_tree(): return
	var fade := create_tween()
	fade.tween_property(bubble_text, "modulate:a", 0.0, FADE_SEC)
	await fade.finished
	if not is_inside_tree(): return
	_refresh()
	create_tween().tween_property(bubble_text, "modulate:a", 1.0, FADE_SEC)
	_busy = false

func _refresh() -> void:
	var s := flow.step()
	if s.is_empty():
		return
	_shown_id = s.id
	bubble_text.text = emphasize(tr(s.text))
	var partial: bool = s.lit.size() < 16
	_tween_bg(DIM_BG if partial else LIT_BG)
	overlay.show_spotlight(s.lit, s.targets if s.gesture == "double" or (s.hint and _hint_shown) else [])
	action_button.visible = not s.button.is_empty()
	action_button.text = tr(s.button) if not s.button.is_empty() else ""
	hint_button.visible = s.hint and not _hint_shown
	hint_button.text = tr("tutorial.hint")
	board.redraw()
	if s.confetti:
		var c := ConfettiLayer.new(); add_child(c); c.start()
		if sfx != null: sfx.play(SfxCatalog.Effect.STAGE_CLEAR)
	_point_hand(s)

func _point_hand(s: Dictionary) -> void:
	if _hand_tween != null: _hand_tween.kill()
	var cells: Array = s.targets
	if cells.is_empty() or (s.hint and not _hint_shown):
		hand.visible = false
		return
	_start_hand.call_deferred(s) # board rects settle after layout

func _start_hand(s: Dictionary) -> void:
	var cells: Array = s.targets
	hand.visible = true
	var start := _cell_center(cells[0])
	hand.position = start
	if not LayoutTokens.motion_enabled:
		return
	_hand_tween = create_tween().set_loops()
	if s.gesture == "swipe" and cells.size() > 1:
		for cell in cells: _hand_tween.tween_property(hand, "position", _cell_center(cell), 0.45)
		_hand_tween.tween_interval(0.4)
		_hand_tween.tween_property(hand, "position", start, 0.0)
	else:
		var presses := 2 if s.gesture == "double" or s.hint else 1
		for i in presses:
			_hand_tween.tween_property(hand, "position", start + Vector2(0, 18), 0.12)
			_hand_tween.tween_property(hand, "position", start, 0.12)
		_hand_tween.tween_interval(0.8)

# Fingertip of the hand sits at the cell center.
func _cell_center(cell: Array) -> Vector2:
	var rect: Rect2 = board.get_cell_rect(int(cell[0]), int(cell[1]))
	return board.global_position - global_position + rect.get_center() - Vector2(hand.size.x * 0.34, hand.size.y * 0.08)

func _input_result(ok: bool, r: int, c: int, placed: bool) -> void:
	if ok:
		if placed: board.play_candy_pop(r, c)
		if sfx != null: sfx.play(SfxCatalog.Effect.CANDY_YES if placed else SfxCatalog.Effect.MARK)
	elif not flow.step().get("free", false):
		board.play_error_shake() # guided steps: only the lit cells take input
	board.redraw()

# Free play: a wrong candy is just refused with a gentle note, then the step text returns.
func _on_missed(_r: int, _c: int) -> void:
	bubble_text.text = emphasize(tr("tutorial.s_miss"))
	var id := _shown_id
	await get_tree().create_timer(MISS_SEC).timeout
	if is_inside_tree() and id == _shown_id and not _busy:
		bubble_text.text = emphasize(tr(flow.step().get("text", "")))

func _on_action() -> void:
	flow.press_button()

func _on_hint() -> void:
	_hint_shown = true
	_refresh()

func _finish() -> void:
	if not practice and guide != null: guide.mark_seen(DONE_ID)
	completed.emit()
	queue_free()

func _tween_bg(target: Color) -> void:
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		bg.color = target
		return
	create_tween().tween_property(bg, "color", target, 0.3)
