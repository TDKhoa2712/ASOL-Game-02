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
var _measure_status := "idle"
var _measure_duration := 20.0
var _measure_warmup := 2.0
var _measure_elapsed := 0.0
var _sample_elapsed := 0.0
var _sample_frames := 0
var _worst_frame_ms := 0.0
var _slow_frames := 0
var _peak_static_mb := 0.0
var _peak_video_mb := 0.0
var _result: Dictionary = {}


func _ready() -> void:
	_build()
	resized.connect(_layout_probe)
	_layout_probe()


func _process(delta: float) -> void:
	_record_measurement(delta)
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


func start_measurement(duration_sec: float = 20.0, warmup_sec: float = 2.0) -> void:
	_measure_duration = maxf(duration_sec, 0.01)
	_measure_warmup = maxf(warmup_sec, 0.0)
	_measure_elapsed = 0.0
	_sample_elapsed = 0.0
	_sample_frames = 0
	_worst_frame_ms = 0.0
	_slow_frames = 0
	_peak_static_mb = 0.0
	_peak_video_mb = 0.0
	_measure_status = "running"
	_result = {"status": "running"}
	$MeasureButton.disabled = true
	$ProbeResults.text = "Đang đo: khởi động..."


func measurement_result() -> Dictionary:
	return _result.duplicate()


func _record_measurement(delta: float) -> void:
	if _measure_status != "running":
		return
	_measure_elapsed += delta
	if _measure_elapsed <= _measure_warmup:
		$ProbeResults.text = "Đang làm nóng: %.1f / %.1f giây" % [_measure_elapsed, _measure_warmup]
		return
	_sample_elapsed += delta
	_sample_frames += 1
	_worst_frame_ms = maxf(_worst_frame_ms, delta * 1000.0)
	if delta > 0.1:
		_slow_frames += 1
	_peak_static_mb = maxf(_peak_static_mb, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	_peak_video_mb = maxf(_peak_video_mb, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	if _sample_frames % 120 == 0:
		trigger_success()
	$ProbeResults.text = "Đang đo: %.1f / %.1f giây" % [_sample_elapsed, _measure_duration]
	if _sample_elapsed >= _measure_duration:
		_measure_status = "complete"
		_result = {
			"status": "complete",
			"frames": _sample_frames,
			"seconds": _sample_elapsed,
			"fps": _sample_frames / _sample_elapsed,
			"worst_frame_ms": _worst_frame_ms,
			"slow_frames": _slow_frames,
			"static_mb": _peak_static_mb,
			"video_mb": _peak_video_mb,
		}
		$ProbeResults.text = "Hoàn tất · %.1f FPS TB · khung tệ nhất %.1f ms\n>100 ms: %d · RAM Godot: %s · video: %s" % [
			_result.fps, _worst_frame_ms, _slow_frames,
			_memory_text(_peak_static_mb), _memory_text(_peak_video_mb),
		]
		$MeasureButton.disabled = false


func _memory_text(megabytes: float) -> String:
	return "%.1f MB" % megabytes if megabytes > 0.0 else "không có dữ liệu"


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

	var measure_button := Button.new()
	measure_button.name = "MeasureButton"
	measure_button.text = "Đo 20 giây"
	measure_button.pressed.connect(start_measurement)
	add_child(measure_button)

	var probe_results := _label("Chạm Đo 20 giây, rồi chụp ảnh kết quả", 25)
	probe_results.name = "ProbeResults"
	probe_results.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(probe_results)


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
	$MeasureButton.position = Vector2((size.x - 360.0) * 0.5, $Note.position.y + 75.0)
	$MeasureButton.size = Vector2(360.0, 75.0)
	$ProbeResults.position = Vector2(SAFE_SIDE, $MeasureButton.position.y + 85.0)
	$ProbeResults.size = Vector2(size.x - SAFE_SIDE * 2.0, 95.0)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label
