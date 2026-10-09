# gradient_bg.gd — Radial gradient background using a shader.
extends ColorRect

const SHADER_CODE := "
shader_type canvas_item;
uniform vec4 color_center : source_color = vec4(1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform vec4 color_edge : source_color = vec4(1.0, 0.88, 0.54, 1.0);
uniform vec2 center_uv = vec2(0.5, 0.28);
uniform float mid_stop = 0.36;
void fragment() {
	float d = distance(UV, center_uv);
	vec4 c;
	if (d < mid_stop) {
		c = mix(color_center, color_mid, d / mid_stop);
	} else {
		c = mix(color_mid, color_edge, clamp((d - mid_stop) / (1.0 - mid_stop), 0.0, 1.0));
	}
	COLOR = c;
}
"

static var _shader: Shader = null

func _init(center: Color = Color.WHITE, mid: Color = Color.YELLOW, edge: Color = Color.ORANGE, center_uv: Vector2 = Vector2(0.5, 0.28)) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("color_center", center)
	mat.set_shader_parameter("color_mid", mid)
	mat.set_shader_parameter("color_edge", edge)
	mat.set_shader_parameter("center_uv", center_uv)
	material = mat
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
