extends RefCounted

const CellModel = preload("res://scripts/core/cell_model.gd")
const CandyRules = preload("res://scripts/core/candy_rules.gd")
const RegionPainter = preload("res://scripts/content/region_painter.gd")
const Palette = preload("res://scripts/theme/palette.gd")
const CandyRenderer = preload("res://scripts/core/candy_renderer.gd")
const LayoutTokens = preload("res://scripts/theme/layout_tokens.gd")

static func resolve_candy_texture(session: Variant) -> Texture2D:
	if session == null or session.level == null:
		return CandyRenderer.texture_for_type("bonbon")
	var custom_tex = session.level.get("candy_texture", null)
	if custom_tex is Texture2D:
		return custom_tex
	var candy_type := str(session.level.get("candy_type", ""))
	if candy_type.is_empty():
		candy_type = CandyRenderer.type_for_label(str(session.level.get("id", "")))
	return CandyRenderer.texture_for_type(candy_type)

static func calculate_sizing(size: int) -> Dictionary:
	var icon_size: float = clampf(288.0 / float(maxi(size, 6)), 24.0, 48.0)
	var gap: int = int(clampf(72.0 / float(maxi(size, 6)), 4.0, 12.0))
	return {"icon_size": icon_size, "gap": gap}

static func sync_status(session: Variant, regions_row: HBoxContainer) -> void:
	if session == null or session.level == null:
		return
	var size: int = int(session.level.get("size", 0))
	var regions: Array = session.level.get("regions", [])
	var found: Dictionary = {}
	for row in range(size):
		for col in range(size):
			if CellModel.is_placed(session.board[row][col]):
				found[CandyRules.zone_of(regions, row, col)] = true

	var zone_colors: Dictionary = RegionPainter.assign_colors(size, regions, Palette.ZONE_COLORS)
	var candy_texture: Texture2D = resolve_candy_texture(session)
	var sizing: Dictionary = calculate_sizing(size)
	var icon_size: float = float(sizing.icon_size)
	var gap: int = int(sizing.gap)
	regions_row.add_theme_constant_override("separation", gap)

	if regions_row.get_child_count() != size:
		for child in regions_row.get_children():
			regions_row.remove_child(child)
			child.free()
		var found_list: Array[String] = []
		var unfound_list: Array[String] = []
		for index in range(size):
			var zid: String = char(65 + index)
			if found.has(zid):
				found_list.append(zid)
			else:
				unfound_list.append(zid)
		var order: Array[String] = found_list + unfound_list
		for zid in order:
			var icon := TextureRect.new()
			icon.name = "Candy_%s" % zid
			icon.set_meta("zone_id", zid)
			icon.texture = candy_texture
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(icon_size, icon_size)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.modulate = zone_colors.get(zid, Palette.ZONE_COLORS[0]) if found.has(zid) else Palette.ICON_MUTED
			regions_row.add_child(icon)
	else:
		# Update properties on existing instances
		for child in regions_row.get_children():
			if child is TextureRect:
				var zid: String = child.get_meta("zone_id", "")
				child.texture = candy_texture
				child.custom_minimum_size = Vector2(icon_size, icon_size)
				child.modulate = zone_colors.get(zid, Palette.ZONE_COLORS[0]) if found.has(zid) else Palette.ICON_MUTED

		# Reorder: found first (maintaining order), then unfound
		var target_idx: int = 0
		for child in regions_row.get_children():
			var zid: String = child.get_meta("zone_id", "")
			if found.has(zid):
				regions_row.move_child(child, target_idx)
				target_idx += 1

static func play_candy_found(session: Variant, regions_row: HBoxContainer, region_id: String) -> Tween:
	if session == null or region_id.is_empty():
		return null
	if not LayoutTokens.motion_enabled:
		sync_status(session, regions_row)
		return null

	var children := regions_row.get_children()
	var icon: TextureRect = null
	var old_idx: int = -1
	for i in range(children.size()):
		if children[i].get_meta("zone_id", "") == region_id:
			icon = children[i] as TextureRect
			old_idx = i
			break

	if icon == null:
		sync_status(session, regions_row)
		return null

	var size: int = int(session.level.get("size", 0))
	var regions: Array = session.level.get("regions", [])
	var found_count: int = 0
	for row in range(size):
		for col in range(size):
			if CellModel.is_placed(session.board[row][col]):
				found_count += 1

	var target_idx: int = mini(found_count - 1, children.size() - 1)
	var zone_colors: Dictionary = RegionPainter.assign_colors(size, regions, Palette.ZONE_COLORS)
	var target_color: Color = zone_colors.get(region_id, Color.WHITE)
	var sizing: Dictionary = calculate_sizing(size)
	var icon_size: float = float(sizing.icon_size)
	var step: float = icon_size + float(sizing.gap)

	icon.z_index = 10
	icon.pivot_offset = Vector2(icon_size, icon_size) * 0.5
	var tw := icon.create_tween()

	# Phase 1: Pop & Wobble
	tw.tween_property(icon, "scale", Vector2(1.35, 1.35), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(icon, "rotation_degrees", -8.0, 0.05)
	tw.tween_property(icon, "rotation_degrees", 8.0, 0.07)
	tw.tween_property(icon, "rotation_degrees", -4.0, 0.06)
	tw.tween_property(icon, "rotation_degrees", 0.0, 0.04)

	# Phase 2: Reveal candy color
	tw.parallel().tween_property(icon, "modulate", target_color, 0.18)

	# Phase 3: Slide to front & push others back
	if old_idx > target_idx:
		var start_x: float = icon.position.x if icon.position.x > 0.0 else float(old_idx) * step
		var target_x: float = start_x - float(old_idx - target_idx) * step
		for j in range(target_idx, old_idx):
			var shifted: Control = children[j] as Control
			var shifted_start_x: float = shifted.position.x if shifted.position.x > 0.0 else float(j) * step
			var shifted_target_x: float = shifted_start_x + step
			tw.parallel().tween_property(shifted, "position:x", shifted_target_x, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(icon, "position:x", target_x, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tw.parallel().tween_property(icon, "scale", Vector2.ONE, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	tw.tween_callback(func():
		icon.z_index = 0
		if old_idx > target_idx:
			regions_row.move_child(icon, target_idx)
		regions_row.queue_sort()
	)

	return tw
