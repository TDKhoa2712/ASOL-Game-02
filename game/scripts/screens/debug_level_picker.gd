# debug_level_picker.gd
extends PanelContainer

signal level_selected(level_data: Dictionary, label: String)
signal progress_reset(mode: String)
signal close_requested()

const Palette = preload("res://scripts/theme/palette.gd")
const BankReader = preload("res://scripts/content/bank_reader.gd")
const BoardTransform = preload("res://scripts/content/board_transform.gd")
const DebugEndlessPanel = preload("res://scripts/screens/debug_endless_panel.gd")
const DebugResetBar = preload("res://scripts/screens/debug_reset_bar.gd")

var _bank: BankReader
var _playlist: Array = []
var _discovered_sizes: Array[int] = []
var _mode: int = 0
var _selected_level: Dictionary = {}
var _selected_label: String = ""
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

var _tab_playlist_btn: Button; var _tab_bank_btn: Button; var _tab_endless_btn: Button
var _playlist_container: VBoxContainer; var _bank_container: VBoxContainer
var _endless_panel: DebugEndlessPanel; var _reset_bar: DebugResetBar
var _size_filter_btn: OptionButton; var _diff_filter_btn: OptionButton
var _playlist_list: ItemList; var _bank_size_btn: OptionButton
var _bank_rank_btn: OptionButton; var _bank_index_spin: SpinBox
var _bank_transform_btn: OptionButton; var _info_label: Label
var _play_btn: Button; var _close_btn: Button

static func discover_banks(bank_dir: String = "res://data/banks/") -> Array[int]:
	var sizes: Array[int] = []
	var dir := DirAccess.open(bank_dir)
	if dir != null:
		dir.list_dir_begin(); var fn := dir.get_next()
		while fn != "":
			if not dir.current_is_dir() and fn.begins_with("bank_") and fn.ends_with(".json") and not fn.ends_with(".pace.json"):
				var core := fn.trim_prefix("bank_").trim_suffix(".json")
				if "x" in core:
					var parts := core.split("x")
					if parts.size() == 2 and parts[0].is_valid_int() and parts[0] == parts[1]:
						var n := parts[0].to_int()
						if not sizes.has(n): sizes.append(n)
			fn = dir.get_next()
	sizes.sort(); return sizes

static func discover_campaigns(campaign_dir: String = "res://data/campaigns/") -> Dictionary:
	var campaigns: Dictionary = {}
	var dir := DirAccess.open(campaign_dir)
	if dir != null:
		dir.list_dir_begin(); var fn := dir.get_next()
		while fn != "":
			if not dir.current_is_dir() and fn.ends_with(".json") and fn != "active_campaign.json":
				var full_path := campaign_dir.path_join(fn); var id := fn.trim_suffix(".json")
				var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(full_path))
				if parsed is Dictionary and parsed.has("id"): id = str(parsed.id)
				campaigns[id] = full_path
			fn = dir.get_next()
	return campaigns

func _init() -> void:
	_discovered_sizes = discover_banks()
	custom_minimum_size = Vector2(960, 1380)
	_build_ui()

func setup(bank: BankReader, playlist: Array = [], endless_rt: Variant = null, campaign_rt: Variant = null) -> void:
	_bank = bank; _playlist = playlist.duplicate(true)
	_populate_filters(); _populate_bank_sizes()
	if _endless_panel != null: _endless_panel.setup(_bank, endless_rt)
	if _reset_bar != null: _reset_bar.setup(campaign_rt, endless_rt)
	if not _playlist.is_empty(): select_playlist_entry(str(_playlist[0].get("label", "")))
	elif not _discovered_sizes.is_empty(): select_custom_bank_level(_discovered_sizes[0], 1, 0, 0)

func get_playlist_sizes() -> Array[int]:
	var sizes: Array[int] = []
	for e in _playlist:
		var s: int = int(e.get("size", 0))
		if s > 0 and not sizes.has(s): sizes.append(s)
	sizes.sort(); return sizes

func get_playlist_difficulties() -> Array[String]:
	var diffs: Array[String] = []
	for e in _playlist:
		var d: String = str(e.get("difficulty", ""))
		if d != "" and not diffs.has(d): diffs.append(d)
	return diffs

func select_playlist_entry(label: String) -> void:
	var entry: Dictionary = {}
	for item in _playlist:
		if str(item.get("label", "")) == label: entry = item; break
	if entry.is_empty(): return
	var s: int = int(entry.get("size", 4)); var r: int = int(entry.get("rank", 1))
	var idx: int = int(entry.get("index", 0)); var tf_id: int = int(entry.get("transform", 0))
	if _bank != null:
		_bank.load_bank(s); var raw := _bank.get_level(s, r, idx)
		_selected_level = BoardTransform.apply(raw, tf_id) if tf_id > 0 else raw.duplicate(true)
	_selected_level["id"] = label; _selected_level["_playlist_label"] = label; _selected_label = label
	_update_info_display(label, s, str(entry.get("difficulty", "normal")), r, _selected_level)

func select_custom_bank_level(board_size: int, rank: int, index: int, transform: int = 0) -> void:
	if _bank != null:
		_bank.load_bank(board_size); var raw := _bank.get_level(board_size, rank, index)
		_selected_level = BoardTransform.apply(raw, transform) if transform > 0 else raw.duplicate(true)
	var label := "Bank %dx%d R%d #%d" % [board_size, board_size, rank, index]
	_selected_level["id"] = label; _selected_level["_bank_meta"] = {"size": board_size, "rank": rank, "index": index, "transform": transform}
	_selected_label = label
	_update_info_display(label, board_size, "custom", rank, _selected_level)

func confirm_selection() -> void:
	if not _selected_level.is_empty(): level_selected.emit(_selected_level, _selected_label)

func _update_info_display(lbl: String, s: int, diff: String, rank: int, lvl: Dictionary) -> void:
	var reg_cnt: int = lvl.get("regions", []).size(); var giv_cnt: int = lvl.get("givens", []).size()
	_info_label.text = "Màn: %s | Size: %dx%d | %s (Rank %d)\nSố vùng: %d | Ô kẹo cho sẵn: %d" % [
		lbl, s, s, diff, rank, reg_cnt, giv_cnt
	]
	_play_btn.disabled = lvl.is_empty()

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.96, 0.93, 0.98); style.set_corner_radius_all(24); style.set_content_margin_all(28)
	style.shadow_color = Color(0, 0, 0, 0.35); style.shadow_size = 24; style.set_border_width_all(3)
	style.border_color = Color(0.3, 0.25, 0.2, 0.8)
	add_theme_stylebox_override("panel", style)

	var root_vbox := VBoxContainer.new(); root_vbox.add_theme_constant_override("separation", 14); add_child(root_vbox)

	var header := PanelContainer.new(); var h_style := StyleBoxFlat.new()
	h_style.bg_color = Color(0.88, 0.85, 0.8, 0.6); h_style.set_corner_radius_all(14); h_style.set_content_margin_all(10)
	header.add_theme_stylebox_override("panel", h_style); header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_header_input)

	var h_row := HBoxContainer.new(); h_row.add_theme_constant_override("separation", 12); header.add_child(h_row)
	var title := Label.new(); title.text = "🛠 DEBUG: Chọn màn (Kéo để di chuyển)"
	title.add_theme_font_size_override("font_size", 32); title.add_theme_color_override("font_color", Palette.INK); h_row.add_child(title)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; spacer.mouse_filter = Control.MOUSE_FILTER_PASS; h_row.add_child(spacer)
	_close_btn = Button.new(); _close_btn.text = "✕ Đóng"; _close_btn.custom_minimum_size = Vector2(140, 60); _close_btn.add_theme_font_size_override("font_size", 28)
	_close_btn.pressed.connect(func(): close_requested.emit()); h_row.add_child(_close_btn); root_vbox.add_child(header)

	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 10)
	_tab_playlist_btn = _tab_btn("Chiến dịch", 0, tabs); _tab_bank_btn = _tab_btn("Ngân hàng (Bank)", 1, tabs); _tab_endless_btn = _tab_btn("Vô tận (Endless)", 2, tabs)
	root_vbox.add_child(tabs)

	_playlist_container = VBoxContainer.new(); _playlist_container.size_flags_vertical = Control.SIZE_EXPAND_FILL; _playlist_container.add_theme_constant_override("separation", 10); root_vbox.add_child(_playlist_container)
	var filter_row := HBoxContainer.new(); filter_row.add_theme_constant_override("separation", 12)
	var flbl := Label.new(); flbl.text = "Lọc Size:"; flbl.add_theme_font_size_override("font_size", 26); filter_row.add_child(flbl)
	_size_filter_btn = OptionButton.new(); _size_filter_btn.custom_minimum_size.y = 56; _size_filter_btn.add_theme_font_size_override("font_size", 26)
	_size_filter_btn.item_selected.connect(func(_i): _apply_playlist_filters()); filter_row.add_child(_size_filter_btn)
	var dlbl := Label.new(); dlbl.text = "Độ khó:"; dlbl.add_theme_font_size_override("font_size", 26); filter_row.add_child(dlbl)
	_diff_filter_btn = OptionButton.new(); _diff_filter_btn.custom_minimum_size.y = 56; _diff_filter_btn.add_theme_font_size_override("font_size", 26)
	_diff_filter_btn.item_selected.connect(func(_i): _apply_playlist_filters()); filter_row.add_child(_diff_filter_btn); _playlist_container.add_child(filter_row)

	_playlist_list = ItemList.new(); _playlist_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; _playlist_list.custom_minimum_size.y = 380; _playlist_list.add_theme_font_size_override("font_size", 26)
	_playlist_list.item_selected.connect(func(i): select_playlist_entry(str(_playlist_list.get_item_metadata(i)))); _playlist_container.add_child(_playlist_list)

	_bank_container = VBoxContainer.new(); _bank_container.size_flags_vertical = Control.SIZE_EXPAND_FILL; _bank_container.add_theme_constant_override("separation", 12); _bank_container.visible = false; root_vbox.add_child(_bank_container)
	_bank_size_btn = OptionButton.new(); _bank_size_btn.custom_minimum_size.y = 56; _bank_size_btn.add_theme_font_size_override("font_size", 26)
	_bank_size_btn.item_selected.connect(_on_bank_size_selected); _add_row(_bank_container, "Kích thước bàn cờ (Size N):", _bank_size_btn)
	_bank_rank_btn = OptionButton.new(); _bank_rank_btn.custom_minimum_size.y = 56; _bank_rank_btn.add_theme_font_size_override("font_size", 26)
	_bank_rank_btn.item_selected.connect(func(_i): _update_custom_selection()); _add_row(_bank_container, "Rank (Độ khó):", _bank_rank_btn)
	_bank_index_spin = SpinBox.new(); _bank_index_spin.min_value = 0; _bank_index_spin.max_value = 999; _bank_index_spin.custom_minimum_size.y = 56
	_bank_index_spin.value_changed.connect(func(_v): _update_custom_selection()); _add_row(_bank_container, "Chỉ số màn (Index):", _bank_index_spin)
	_bank_transform_btn = OptionButton.new(); _bank_transform_btn.custom_minimum_size.y = 56; _bank_transform_btn.add_theme_font_size_override("font_size", 26)
	for t in ["Gốc (0°)", "Xoay 90°", "Xoay 180°", "Xoay 270°", "Lật ngang", "Lật dọc", "Chéo 1", "Chéo 2"]: _bank_transform_btn.add_item(t)
	_bank_transform_btn.item_selected.connect(func(_i): _update_custom_selection()); _add_row(_bank_container, "Biến đổi (Transform):", _bank_transform_btn)

	_endless_panel = DebugEndlessPanel.new(); _endless_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; _endless_panel.visible = false
	_endless_panel.level_changed.connect(func(lvl: Dictionary, lbl: String):
		_selected_level = lvl; _selected_label = lbl; var s: int = int(lvl.get("size", 4)); var r: int = int(lvl.get("rank", 1))
		_update_info_display(lbl, s, str(lvl.get("difficulty", "normal")), r, lvl)
	); root_vbox.add_child(_endless_panel)

	var info_panel := PanelContainer.new(); var ip_style := StyleBoxFlat.new()
	ip_style.bg_color = Color(0.9, 0.88, 0.84, 0.8); ip_style.set_corner_radius_all(14); ip_style.set_content_margin_all(14)
	info_panel.add_theme_stylebox_override("panel", ip_style)
	_info_label = Label.new(); _info_label.text = "Chưa chọn màn nào"; _info_label.add_theme_font_size_override("font_size", 26)
	_info_label.add_theme_color_override("font_color", Palette.INK); info_panel.add_child(_info_label); root_vbox.add_child(info_panel)

	_reset_bar = DebugResetBar.new(); _reset_bar.progress_reset.connect(func(m: String): progress_reset.emit(m)); root_vbox.add_child(_reset_bar)
	_play_btn = Button.new(); _play_btn.text = "▶ Vào chơi màn này ngay"; _play_btn.custom_minimum_size.y = 72; _play_btn.add_theme_font_size_override("font_size", 30)
	_play_btn.pressed.connect(confirm_selection); root_vbox.add_child(_play_btn)

func _on_header_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_is_dragging = ev.pressed; _drag_offset = get_global_mouse_position() - global_position
	elif ev is InputEventScreenTouch:
		_is_dragging = ev.pressed; _drag_offset = get_viewport().get_mouse_position() - global_position
	elif (_is_dragging and ev is InputEventMouseMotion) or (_is_dragging and ev is InputEventScreenDrag):
		var nxt_pos: Vector2 = get_global_mouse_position() - _drag_offset; var vp_size: Vector2 = get_viewport_rect().size
		if vp_size.x > 0 and vp_size.y > 0:
			nxt_pos.x = clampf(nxt_pos.x, 10.0, maxf(10.0, vp_size.x - size.x - 10.0))
			nxt_pos.y = clampf(nxt_pos.y, 10.0, maxf(10.0, vp_size.y - size.y - 10.0))
		global_position = nxt_pos

func _tab_btn(lbl: String, idx: int, p: Container) -> Button:
	var b := Button.new(); b.text = lbl; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 64; b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func(): _switch_mode(idx)); p.add_child(b); return b

func _add_row(parent: Container, lbl_text: String, ctrl: Control) -> void:
	var row := HBoxContainer.new(); var lbl := Label.new(); lbl.text = lbl_text
	lbl.add_theme_font_size_override("font_size", 26); lbl.add_theme_color_override("font_color", Palette.INK)
	row.add_child(lbl); row.add_child(ctrl); parent.add_child(row)

func _switch_mode(m: int) -> void:
	_mode = m; _playlist_container.visible = (_mode == 0); _bank_container.visible = (_mode == 1); _endless_panel.visible = (_mode == 2)
	if _mode == 0: _apply_playlist_filters()
	elif _mode == 1: _update_custom_selection()
	elif _mode == 2:
		_selected_level = _endless_panel.get_selected_level(); _selected_label = _endless_panel.get_selected_label()
		if not _selected_level.is_empty():
			_update_info_display(_selected_label, int(_selected_level.get("size", 4)), str(_selected_level.get("difficulty", "normal")), int(_selected_level.get("rank", 1)), _selected_level)

func _populate_filters() -> void:
	_size_filter_btn.clear(); _size_filter_btn.add_item("Tất cả Size")
	for s in get_playlist_sizes(): _size_filter_btn.add_item("%dx%d" % [s, s], s)
	_diff_filter_btn.clear(); _diff_filter_btn.add_item("Tất cả độ khó")
	for d in get_playlist_difficulties(): _diff_filter_btn.add_item(d)
	_apply_playlist_filters()

func _apply_playlist_filters() -> void:
	_playlist_list.clear()
	var target_size: int = _size_filter_btn.get_selected_id()
	var target_diff: String = _diff_filter_btn.get_item_text(_diff_filter_btn.selected) if _diff_filter_btn.selected > 0 else ""
	for entry in _playlist:
		var s: int = int(entry.get("size", 0)); var d: String = str(entry.get("difficulty", ""))
		if target_size > 0 and s != target_size: continue
		if target_diff != "" and d != target_diff: continue
		var label: String = str(entry.get("label", ""))
		_playlist_list.add_item("[%s] Size %dx%d | %s (Rank %d)" % [label, s, s, d, int(entry.get("rank", 1))])
		_playlist_list.set_item_metadata(_playlist_list.item_count - 1, label)
	if _playlist_list.item_count > 0:
		_playlist_list.select(0); select_playlist_entry(str(_playlist_list.get_item_metadata(0)))

func _populate_bank_sizes() -> void:
	_bank_size_btn.clear()
	for s in _discovered_sizes: _bank_size_btn.add_item("%dx%d" % [s, s], s)
	if not _discovered_sizes.is_empty(): _on_bank_size_selected(0)

func _on_bank_size_selected(_idx: int) -> void:
	var s: int = _bank_size_btn.get_selected_id()
	if _bank != null: _bank.load_bank(s)
	_bank_rank_btn.clear()
	for r in [1, 2, 3]:
		var count: int = _bank.level_count(s, r) if _bank != null else 0
		if count > 0: _bank_rank_btn.add_item("Rank %d (%d màn)" % [r, count], r)
	_update_custom_selection()

func _update_custom_selection() -> void:
	var s: int = _bank_size_btn.get_selected_id(); var r: int = _bank_rank_btn.get_selected_id()
	if r <= 0: r = 1
	var max_idx: int = maxi(0, (_bank.level_count(s, r) - 1) if _bank != null else 0)
	_bank_index_spin.max_value = max_idx
	select_custom_bank_level(s, r, int(_bank_index_spin.value), _bank_transform_btn.selected)
