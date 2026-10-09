# sunburst_rays.gd — Rotating sunburst background rays for win screen.
extends Control

const Palette = preload("res://scripts/theme/palette.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

var _center_uv: Vector2 = Vector2(0.5, 0.28)
var _ray_color: Color = Palette.WIN_RAYS
var _ray_count: int = 18
var _spin_node: Control

func _init(center_uv: Vector2 = Vector2(0.5, 0.28)) -> void:
	_center_uv = center_uv
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_spin_node = _RaysDraw.new(_ray_color, _ray_count)
	_spin_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spin_node)

func _ready() -> void:
	_update_layout()
	resized.connect(_update_layout)
	if LayoutTokens.motion_enabled:
		var tw := _spin_node.create_tween().set_loops()
		tw.tween_property(_spin_node, "rotation", TAU, LayoutTokens.RAYS_SPIN_MS / 1000.0).from(0.0)

func _update_layout() -> void:
	if _spin_node == null: return
	var center_pos := Vector2(size.x * _center_uv.x, size.y * _center_uv.y)
	var radius := maxf(size.x, size.y) * 1.5
	_spin_node.position = center_pos
	_spin_node.size = Vector2(radius * 2, radius * 2)
	_spin_node.pivot_offset = Vector2.ZERO

class _RaysDraw extends Control:
	var _col: Color
	var _num: int

	func _init(color: Color, num_rays: int) -> void:
		_col = color
		_num = num_rays

	func _draw() -> void:
		var radius := 1600.0
		var angle_step := TAU / float(_num * 2)
		for i in range(_num):
			var a1 := float(i * 2) * angle_step
			var a2 := a1 + angle_step
			var pts: PackedVector2Array = [
				Vector2.ZERO,
				Vector2(cos(a1) * radius, sin(a1) * radius),
				Vector2(cos(a2) * radius, sin(a2) * radius),
			]
			draw_colored_polygon(pts, _col)
