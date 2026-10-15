# Day-7 step: the gift box opens and shows the hints/candy drops added to the stock.
# Renders only what setup() receives; never reads or writes save (debug previews reuse it).
extends Control

signal continued()

var reward: Dictionary = {}
var title_label: Label
var gift: GiftBoxView
var hint_label: Label
var place_label: Label
var continue_btn: Button

func setup(r: Dictionary) -> void:
	reward = r.duplicate(true)
	_ensure_nodes()
	hint_label.text = tr("streak.gift_hint") % maxi(0, int(reward.get("hint", 0)))
	place_label.text = tr("streak.gift_place") % maxi(0, int(reward.get("place", 0)))
	gift.play_idle()
	gift.call_deferred("play_open")

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if continue_btn != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#FFF6E8"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	title_label = _label(box, tr("streak.gift_title"), 40)
	gift = GiftBoxView.create()
	gift.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(gift)
	hint_label = _label(box, "", 32)
	place_label = _label(box, "", 32)
	continue_btn = Button.new(); continue_btn.text = tr("common.continue")
	continue_btn.custom_minimum_size = Vector2(280, 72)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.pressed.connect(func(): continued.emit())
	box.add_child(continue_btn)

func _label(parent: Control, text: String, font_size: int) -> Label:
	var l := Label.new(); l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l
