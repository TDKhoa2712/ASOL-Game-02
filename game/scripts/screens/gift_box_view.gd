# Gift box slot. Placeholder art now; the final animation replaces this scene's content only.
class_name GiftBoxView
extends Control

signal opened

const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")
const SCENE := "res://scenes/components/gift_box_view.tscn"
const ART := "res://assets/ui/streak/gift_box.svg"

var is_open := false
var art: TextureRect
var _tween: Tween = null

static func create() -> GiftBoxView:
	return (load(SCENE) as PackedScene).instantiate() as GiftBoxView

func _init() -> void:
	name = "GiftBoxView"
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	art = TextureRect.new()
	if ResourceLoader.exists(ART): art.texture = load(ART) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

func play_idle() -> void:
	_stop()
	is_open = false
	art.modulate = Color.WHITE
	art.scale = Vector2.ONE
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		return
	art.pivot_offset = custom_minimum_size * 0.5
	_tween = create_tween().set_loops()
	_tween.tween_property(art, "rotation", 0.08, 0.6).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(art, "rotation", -0.08, 0.6).set_trans(Tween.TRANS_SINE)

func play_open() -> void:
	_stop()
	if not LayoutTokens.motion_enabled or not is_inside_tree():
		_finish_open()
		return
	art.pivot_offset = custom_minimum_size * 0.5
	_tween = create_tween()
	_tween.tween_property(art, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(art, "modulate:a", 0.0, 0.2)
	_tween.finished.connect(_finish_open)

func _finish_open() -> void:
	is_open = true
	opened.emit()

func _stop() -> void:
	if _tween != null:
		_tween.kill(); _tween = null
	art.rotation = 0.0
