shader_type canvas_item;

// A diagonal white band that sweeps across every logo facet that shares this material.
// shine_pos is in screen (canvas) pixels along the axis  x + y * skew.
uniform float shine_pos = -100000.0;
uniform float band = 40.0;        // half-width of the band in px
uniform float skew = 0.32;        // ~ CSS skewX(-18deg)
uniform float strength = 0.75;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float d = world_pos.x + world_pos.y * skew - shine_pos;
	float s = 1.0 - smoothstep(0.0, band, abs(d));
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), s * strength);
}
