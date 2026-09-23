extends Control


const BoardScript = preload("res://scripts/spike_board_6x6.gd")
const CAT_ATLAS := preload("res://assets/spike/cat-probe-atlas.png")
const BACKGROUND := Color("#F6F2EA")
const INK := Color("#344054")
const SAFE_SIDE := 54.0


var board: Control
var cats: Node2D
var labels: HBoxContainer
var sticker: PanelContainer
var error_badge: Label
var _jump_elapsed := 0.0
var _jumping := false


func _ready() -> void:
	_build()
	resized.connect(_layout_probe)
	_layout_probe()


func _process(delta: float) -> void:
	if not _jumping:
		return
	_jump_elapsed += delta
	var frame := mini(int(_jump_elapsed / 0.12), 3)
	for cat in cats.get_children():
		(cat as Sprite2D).texture.region = Rect2(frame * 128, 0, 128, 128)
	if _jump_elapsed >= 0.7:
		_jumping = false
		sticker.hide()
		for cat in cats.get_children():
			(cat as Sprite2D).texture.region = Rect2(0, 0, 128, 128)


func trigger_success() -> void:
	error_badge.hide()
	sticker.show()
	_jump_elapsed = 0.0
	_jumping = true


func trigger_error() -> void:
	_jumping = false
	sticker.hide()
	error_badge.show()


func _build() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := _label("Rendering probe · 6×6", 42)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var caption := _label("Một atlas mèo dùng trên sáu vùng", 27)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(caption)

	board = BoardScript.new()
	board.name = "Board6x6"
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)

	cats = Node2D.new()
	cats.name = "CatSprites"
	add_child(cats)
	for index in range(6):
		var frame := AtlasTexture.new()
		frame.atlas = CAT_ATLAS
		frame.region = Rect2(0, 0, 128, 128)
		var cat := Sprite2D.new()
		cat.name = "Cat%d" % index
		cat.texture = frame
		cats.add_child(cat)

	labels = HBoxContainer.new()
	labels.name = "RegionLabels"
	labels.add_theme_constant_override("separation", 4)
	add_child(labels)
	for index in range(6):
		var region_label := _label(char(65 + index), 30)
		region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.add_child(region_label)

	sticker = PanelContainer.new()
	sticker.name = "Sticker"
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sticker_text := _label("Hay lắm! ✦", 34)
	sticker.add_child(sticker_text)
	add_child(sticker)
	sticker.hide()

	error_badge = _label("!  Ô này chưa đúng", 30)
	error_badge.name = "ErrorBadge"
	error_badge.add_theme_color_override("font_color", Color("#9D2424"))
	add_child(error_badge)
	error_badge.hide()

	var success_button := Button.new()
	success_button.name = "SuccessButton"
	success_button.text = "Thử mèo nhảy"
	success_button.pressed.connect(trigger_success)
	add_child(success_button)

	var error_button := Button.new()
	error_button.name = "ErrorButton"
	error_button.text = "Thử X sai"
	error_button.pressed.connect(trigger_error)
	add_child(error_button)

	var note := _label("Atlas mẫu kỹ thuật · cần đo trên Android và iPhone mục tiêu", 23)
	note.name = "Note"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)


func _layout_probe() -> void:
	if board == null:
		return
	var side := minf(size.x - SAFE_SIDE * 2.0, 840.0)
	board.size = Vector2.ONE * side
	board.position = Vector2((size.x - side) * 0.5, maxf(300.0, (size.y - side) * 0.42))
	board.queue_redraw()
	var cell := side / 6.0
	for index in range(6):
		var cat: Sprite2D = cats.get_child(index)
		cat.position = board.position + Vector2(index + 0.5, index + 0.5) * cell
		cat.scale = Vector2.ONE * minf(1.0, cell / 140.0)
	labels.position = Vector2(board.position.x, board.position.y + side + 18.0)
	labels.size = Vector2(side, 52.0)
	$Title.position = Vector2(SAFE_SIDE, 95.0)
	$Title.size = Vector2(size.x - SAFE_SIDE * 2.0, 65.0)
	$Caption.position = Vector2(SAFE_SIDE, 172.0)
	$Caption.size = Vector2(size.x - SAFE_SIDE * 2.0, 46.0)
	sticker.position = Vector2((size.x - 245.0) * 0.5, board.position.y - 74.0)
	sticker.size = Vector2(245.0, 56.0)
	error_badge.position = Vector2(SAFE_SIDE, board.position.y - 74.0)
	error_badge.size = Vector2(size.x - SAFE_SIDE * 2.0, 56.0)
	$SuccessButton.position = Vector2(SAFE_SIDE, board.position.y + side + 102.0)
	$SuccessButton.size = Vector2((size.x - SAFE_SIDE * 2.0 - 20.0) * 0.5, 82.0)
	$ErrorButton.position = Vector2($SuccessButton.position.x + $SuccessButton.size.x + 20.0, $SuccessButton.position.y)
	$ErrorButton.size = $SuccessButton.size
	$Note.position = Vector2(SAFE_SIDE, $SuccessButton.position.y + 102.0)
	$Note.size = Vector2(size.x - SAFE_SIDE * 2.0, 70.0)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label
