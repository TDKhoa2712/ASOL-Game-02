@tool
class_name CandyCharacter
extends Node2D

## Candy mascot character composed of multiple 2.5D SVG layers.
## Expressions: normal, happy, wink, surprised, sad, sleepy, heart
## Actions: celebrate(), drop_in(), idle styles: hop, breathe, shiver, none

signal celebrated

const ART := "res://assets/candy/"
const BLINKABLE := ["normal", "surprised", "heart"]
const AUTO_ARMS := {
	"normal": "down",
	"happy": "up",
	"wink": "wave",
	"surprised": "up",
	"sad": "down",
	"sleepy": "down",
	"heart": "heart"
}
const ARM_POSES := {
	"down": [Vector2(97, 164), 20.0, Vector2(223, 164), -20.0],
	"up": [Vector2(94, 98), -25.0, Vector2(226, 98), 25.0],
	"wave": [Vector2(97, 164), 20.0, Vector2(228, 100), 25.0],
	"heart": [Vector2(132, 170), 30.0, Vector2(188, 170), -30.0],
}
const SHOULDER_R := Vector2(214, 118)

@export_enum("normal", "happy", "wink", "surprised", "sad", "sleepy", "heart") var expression: String = "normal":
	set(v):
		expression = v
		if is_node_ready():
			_apply_expression()

@export_enum("auto", "down", "up", "wave", "heart") var arms_pose: String = "auto":
	set(v):
		arms_pose = v
		if is_node_ready():
			_apply_expression()

@export_enum("normal", "sad") var palette: String = "normal":
	set(v):
		palette = v
		if is_node_ready():
			_apply_palette()

@export_enum("hop", "breathe", "shiver", "none") var idle_style: String = "hop":
	set(v):
		idle_style = v
		if is_node_ready() and not Engine.is_editor_hint():
			_start_idle()

@export var wing_droop := 0.0:
	set(v):
		wing_droop = v
		if is_node_ready():
			_apply_palette()

@export var cracked := false:
	set(v):
		cracked = v
		if is_node_ready() and has_node("Rig/Squash/Art/Crack"):
			$Rig/Squash/Art/Crack.visible = v

@export var auto_blink := true

var _idle: Tween
var _flap: Tween
var _wave: Tween
var _fx_tw: Tween
var _tears: Tween
var _celebrating := false
var _blink_left := 3.0

static func cpos(x: float, y: float) -> Vector2:
	return (Vector2(x, y) - Vector2(160, 128)) * 2.0

@onready var _rig: Node2D = $Rig
@onready var _squash: Node2D = $Rig/Squash
@onready var _art: Node2D = $Rig/Squash/Art
@onready var _shadow: Sprite2D = $Shadow
@onready var _wing_l: Sprite2D = $Rig/Squash/Art/WingL
@onready var _wing_r: Sprite2D = $Rig/Squash/Art/WingR
@onready var _leg_l: Sprite2D = $Rig/Squash/Art/LegL
@onready var _leg_r: Sprite2D = $Rig/Squash/Art/LegR
@onready var _body: Sprite2D = $Rig/Squash/Art/Body
@onready var _face: Sprite2D = $Rig/Squash/Art/Face
@onready var _heart: Sprite2D = $Rig/Squash/Art/HeartProp
@onready var _arm_l: Sprite2D = $Rig/Squash/Art/ArmL
@onready var _arm_pivot: Node2D = $Rig/Squash/Art/ArmRPivot
@onready var _arm_r: Sprite2D = $Rig/Squash/Art/ArmRPivot/ArmR
@onready var _tear_l: Sprite2D = $Rig/Squash/Art/TearL
@onready var _tear_r: Sprite2D = $Rig/Squash/Art/TearR
@onready var _fx: Sprite2D = $Rig/Squash/Art/FX
@onready var _burst: CPUParticles2D = $Burst

func _ready() -> void:
	_apply_palette()
	_apply_expression()
	if has_node("Rig/Squash/Art/Crack"):
		$Rig/Squash/Art/Crack.visible = cracked
	if Engine.is_editor_hint():
		return
	_start_idle()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not auto_blink:
		return
	_blink_left -= delta
	if _blink_left <= 0.0:
		_blink_left = randf_range(2.4, 4.6)
		if BLINKABLE.has(_shown_expression()):
			_face.texture = load(ART + "face_blink.svg")
			get_tree().create_timer(0.12).timeout.connect(_restore_face)

func _restore_face() -> void:
	if is_instance_valid(_face):
		_face.texture = load(ART + "face_%s.svg" % _shown_expression())

func _shown_expression() -> String:
	return "happy" if _celebrating else expression

func _apply_palette() -> void:
	if _body == null: return
	var sfx := "" if palette == "normal" else "_sad"
	_body.texture = load(ART + "body%s.svg" % sfx)
	_wing_l.texture = load(ART + "wing_l%s.svg" % sfx)
	_wing_r.texture = load(ART + "wing_r%s.svg" % sfx)
	_wing_l.rotation_degrees = -wing_droop
	_wing_r.rotation_degrees = wing_droop
	if not Engine.is_editor_hint():
		_start_flap()

func _apply_expression() -> void:
	if _face == null: return
	var e := _shown_expression()
	_face.texture = load(ART + "face_%s.svg" % e)
	var fx_path := ART + "fx_%s.svg" % e
	_fx.visible = ResourceLoader.exists(fx_path)
	if _fx.visible:
		_fx.texture = load(fx_path)
	_heart.visible = e == "heart"
	_tear_l.visible = e == "sad"
	_tear_r.visible = e == "sad"
	var pose: String = "up" if _celebrating else (AUTO_ARMS[e] if arms_pose == "auto" else arms_pose)
	var p: Array = ARM_POSES[pose]
	_arm_l.position = cpos(p[0].x, p[0].y)
	_arm_l.rotation_degrees = p[1]
	_arm_pivot.rotation = 0.0
	_arm_r.position = cpos(p[2].x, p[2].y) - cpos(SHOULDER_R.x, SHOULDER_R.y)
	_arm_r.rotation_degrees = p[3]
	if Engine.is_editor_hint():
		return
	_kill(_wave)
	if pose == "wave":
		_wave = create_tween().set_loops()
		_wave.tween_property(_arm_pivot, "rotation_degrees", 22.0, 0.4).set_trans(Tween.TRANS_SINE)
		_wave.tween_property(_arm_pivot, "rotation_degrees", -18.0, 0.4).set_trans(Tween.TRANS_SINE)
	_kill(_fx_tw)
	if _fx.visible:
		_fx.scale = Vector2.ONE
		_fx_tw = create_tween().set_loops()
		_fx_tw.tween_property(_fx, "scale", Vector2(1.1, 1.1), 0.7).set_trans(Tween.TRANS_SINE)
		_fx_tw.tween_property(_fx, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	_kill(_tears)
	if e == "sad":
		_tears = create_tween().set_loops()
		for tear in [_tear_l, _tear_r]:
			_tears.parallel().tween_method(_tear_step.bind(tear), 0.0, 1.0, 1.6)
		_tears.tween_interval(0.3)

func _tear_step(p: float, tear: Sprite2D) -> void:
	if not is_instance_valid(tear): return
	var base := cpos(136, 136) if tear == _tear_l else cpos(186, 136)
	tear.position = base + Vector2(0, p * 80.0)
	tear.modulate.a = clampf(1.0 - p, 0.0, 1.0) if p > 0.15 else p / 0.15
	tear.scale = Vector2.ONE * lerpf(0.5, 1.0, minf(p * 4.0, 1.0))

func _kill(t: Tween) -> void:
	if t and t.is_valid():
		t.kill()

func _set_height(h: float) -> void:
	_rig.position.y = -h
	var k := clampf(h / 260.0, 0.0, 1.0)
	_shadow.scale = Vector2.ONE * lerpf(1.0, 0.7, k)
	_shadow.modulate.a = lerpf(1.0, 0.5, k)

func _start_flap() -> void:
	_kill(_flap)
	var amp := 3.0 if wing_droop != 0.0 else 10.5
	var base_l := -wing_droop
	_flap = create_tween().set_loops()
	_flap.tween_property(_wing_l, "rotation_degrees", base_l - amp, 0.45).set_trans(Tween.TRANS_SINE)
	_flap.parallel().tween_property(_wing_r, "rotation_degrees", -base_l + amp, 0.45).set_trans(Tween.TRANS_SINE)
	_flap.tween_property(_wing_l, "rotation_degrees", base_l + amp * 0.8, 0.45).set_trans(Tween.TRANS_SINE)
	_flap.parallel().tween_property(_wing_r, "rotation_degrees", -base_l - amp * 0.8, 0.45).set_trans(Tween.TRANS_SINE)

func _start_idle() -> void:
	_kill(_idle)
	_squash.scale = Vector2.ONE
	_squash.rotation = 0.0
	_set_height(0.0)
	match idle_style:
		"hop":
			_idle = create_tween().set_loops()
			_idle.tween_property(_squash, "scale", Vector2(1.07, 0.93), 0.2).set_trans(Tween.TRANS_SINE)
			_idle.tween_method(_set_height, 0.0, 48.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_idle.parallel().tween_property(_squash, "scale", Vector2(0.96, 1.05), 0.25)
			_idle.parallel().tween_property(_leg_l, "position:y", cpos(142, 184).y - 10, 0.25)
			_idle.tween_method(_set_height, 48.0, 0.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_idle.parallel().tween_property(_leg_l, "position:y", cpos(142, 184).y, 0.3)
			_idle.tween_property(_squash, "scale", Vector2(1.09, 0.91), 0.1)
			_idle.tween_property(_squash, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_idle.parallel().tween_property(_leg_r, "position:y", cpos(178, 184).y - 10, 0.15)
			_idle.tween_property(_leg_r, "position:y", cpos(178, 184).y, 0.15)
		"breathe":
			_idle = create_tween().set_loops()
			_idle.tween_property(_squash, "scale", Vector2(1.05, 0.95), 1.5).set_trans(Tween.TRANS_SINE)
			_idle.tween_property(_squash, "scale", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE)
		"shiver":
			_idle = create_tween().set_loops()
			_idle.tween_interval(1.6)
			for a in [-2.0, 2.0, -1.5, 1.5, 0.0]:
				_idle.tween_property(_squash, "rotation_degrees", a, 0.07)

func drop_in(delay: float = 0.0) -> void:
	var target := position
	position.y -= 500.0 * scale.y
	modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(self, "position:y", target.y, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_squash, "scale", Vector2(1.15, 0.85), 0.1)
	t.tween_property(_squash, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func celebrate() -> void:
	if _celebrating:
		return
	_celebrating = true
	_kill(_idle)
	_apply_expression()
	_set_height(0.0)
	var t := create_tween()
	t.tween_property(_squash, "scale", Vector2(1.14, 0.86), 0.15)
	t.tween_callback(_burst.restart)
	t.tween_method(_set_height, 0.0, 260.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_squash, "scale", Vector2(0.95, 1.06), 0.2)
	t.parallel().tween_method(_flip, 0.0, 1.0, 0.55)
	t.tween_method(_set_height, 260.0, 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_squash, "scale", Vector2(1.16, 0.84), 0.08)
	t.tween_property(_squash, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(_end_celebrate)

func _flip(p: float) -> void:
	_art.scale.x = cos(p * TAU)
	var shade := lerpf(0.8, 1.0, absf(cos(p * TAU)))
	_art.modulate = Color(shade, shade, shade)

func _end_celebrate() -> void:
	_art.scale = Vector2.ONE
	_art.modulate = Color.WHITE
	_celebrating = false
	_apply_expression()
	_start_idle()
	celebrated.emit()
