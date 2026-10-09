# build_mascot_atlas.gd — Offline tool: composes the mascot SVG parts into a frame atlas.
# Run: <godot> --headless --path game --script res://tools/build_mascot_atlas.gd [-- --check]
extends SceneTree

const SRC := "res://assets/candy/"
const OUT_PNG := "res://assets/candy/anim/mascot_atlas.png"
const OUT_JSON := "res://assets/candy/anim/mascot_atlas.json"
const FRAME := 128
const PAD := 2
const COLS := 10
const SVG_SCALE := 0.175 # 640px-wide parts -> 112px
const BASE := Vector2i(112, 91)
const GROUND := 110 # bottom of the mascot canvas: mascot centred in the frame (feet at y=94, see candy_cell_drawer FOOT_Y)
const FEET := 16 # empty canvas rows below the feet
const WING_PIVOT_L := 0.29 # wing joint as fraction of BASE.x
const WING_PIVOT_R := 0.71
const ANIMS := [["appear", 12, 30, false], ["idle", 18, 12, false], ["error", 16, 30, false], ["sad", 16, 12, true], ["win", 20, 30, false]]

var _parts := {}

func _init() -> void:
	var check := OS.get_cmdline_user_args().has("--check")
	quit(_check() if check else _build())

func _build() -> int:
	for name in ["body", "body_sad", "wing_l", "wing_r", "wing_l_sad", "wing_r_sad", "leg_l", "leg_r", "tear",
			"face_normal", "face_blink", "face_happy", "face_heart", "face_sad", "face_surprised"]:
		var img := Image.new()
		var scale := SVG_SCALE * (2.0 if name == "tear" else 1.0)
		if img.load_svg_from_string(FileAccess.get_file_as_string(SRC + name + ".svg"), scale) != OK:
			printerr("cannot load ", name); return 1
		img.convert(Image.FORMAT_RGBA8)
		_parts[name] = img
	var total := 0
	for a in ANIMS: total += a[1]
	var rows := int(ceil(float(total) / COLS))
	var atlas := Image.create(COLS * (FRAME + PAD), rows * (FRAME + PAD), false, Image.FORMAT_RGBA8)
	var meta := {"version": 1, "frame_size": [FRAME, FRAME], "anims": {}}
	var idx := 0
	for a in ANIMS:
		var frames := []
		for i in range(a[1]):
			var t := float(i) / float(max(1, a[1] - 1))
			var at := Vector2i((idx % COLS) * (FRAME + PAD), (idx / COLS) * (FRAME + PAD))
			atlas.blend_rect(_compose(_pose(a[0], t, i)), Rect2i(0, 0, FRAME, FRAME), at)
			frames.append([at.x, at.y]); idx += 1
		meta.anims[a[0]] = {"fps": a[2], "loop": a[3], "frames": frames}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_PNG.get_base_dir()))
	if atlas.save_png(OUT_PNG) != OK: printerr("save png failed"); return 1
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t")); f.close()
	print("MASCOT_ATLAS_BUILT ", atlas.get_size(), " frames=", total)
	return 0

# Shape-only poses: expression, wing flap, sad parts, tear. Body motion (squash, hop,
# shake, tint) is applied at runtime by scripts/screens/mascot_motion.gd for smoothness.
func _pose(anim: String, t: float, i: int) -> Dictionary:
	var p := {"body": "body", "wing": "", "face": "face_normal", "wing_s": 1.0, "tear": -1.0}
	match anim:
		"appear":
			p.face = "face_surprised" if t < 0.6 else "face_happy"
		"idle":
			p.wing_s = 1.0 - 0.4 * absf(sin(TAU * 2.0 * t))
			p.face = "face_blink" if i >= 8 and i <= 10 else "face_normal"
		"error":
			p.face = "face_surprised"
		"sad":
			p.body = "body_sad"; p.wing = "_sad"; p.face = "face_sad"
			p.wing_s = 1.0 - 0.2 * absf(sin(TAU * t))
			p.tear = t
		"win":
			p.wing_s = 1.0 - 0.55 * absf(sin(TAU * 3.0 * t))
			p.face = "face_happy" if t < 0.5 else "face_heart"
	return p

func _compose(p: Dictionary) -> Image:
	var m := Image.create(BASE.x, BASE.y, false, Image.FORMAT_RGBA8)
	_blend_wing(m, _parts["wing_l" + p.wing], WING_PIVOT_L, p.wing_s)
	_blend_wing(m, _parts["wing_r" + p.wing], WING_PIVOT_R, p.wing_s)
	for name in ["leg_l", "leg_r", p.body, p.face]:
		var src: Image = _parts[name]
		m.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)
	var out := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	var at := Vector2i((FRAME - BASE.x) / 2, GROUND - BASE.y)
	out.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), at)
	if p.tear >= 0.0:
		var tear: Image = _parts["tear"]
		out.blend_rect(tear, Rect2i(Vector2i.ZERO, tear.get_size()), at + Vector2i(int(BASE.x * 0.40), int(BASE.y * 0.62 + 18.0 * p.tear)))
	return out

func _blend_wing(dst: Image, wing: Image, pivot: float, ws: float) -> void:
	var img := wing.duplicate()
	var w := maxi(1, int(img.get_width() * ws))
	img.resize(w, img.get_height(), Image.INTERPOLATE_BILINEAR)
	var px := BASE.x * pivot
	dst.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(px - px * ws), 0))

func _check() -> int:
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT_JSON))
	var img := Image.load_from_file(ProjectSettings.globalize_path(OUT_PNG))
	if meta == null or img == null: printerr("atlas missing"); return 1
	for a in ANIMS:
		var info: Dictionary = meta.anims.get(a[0], {})
		if info.get("frames", []).size() != a[1]: printerr("bad count ", a[0]); return 1
		for fr in info.frames:
			if fr[0] + FRAME > img.get_width() or fr[1] + FRAME > img.get_height(): printerr("out of bounds ", a[0]); return 1
	print("MASCOT_ATLAS_CHECK_PASS")
	return 0
