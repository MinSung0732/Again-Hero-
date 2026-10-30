extends RefCounted

const ROW_SKIN := preload("res://src/ui/mission_row_skin.gd")
const DATA := preload("res://src/data/ranked_leaderboard_catalog.gd")
const RULES := preload("res://src/data/ranked_rules.gd")
var lobby: Control
var root: VBoxContainer
var title_plate: Control
var scroll: ScrollContainer
var canvas: Control
var status: Label
var my_line: HBoxContainer
var pool: Array = []
var tabs := {}
var caches := {}
var role := "hero"
var generation := 0
var owner_id := ""
var touch_start := -1.0
var textures := {}
var cloud_override: Node

func install(settings: RefCounted, parent: Control) -> void:
	lobby = settings.lobby
	root = VBoxContainer.new()
	root.name = "RankHistoryContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(root)
	var title := Label.new()
	title.text = DATA.TITLE
	title_plate = settings._title_plate(lobby.other_tab, title)
	var tab_row := HBoxContainer.new()
	root.add_child(tab_row)
	for entry in DATA.ROLES:
		var button := Button.new()
		button.text = entry[1]
		ROW_SKIN.apply_button(button)
		button.custom_minimum_size.y = DATA.TAB_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_row.add_child(button)
		button.pressed.connect(select_role.bind(String(entry[0])))
		tabs[entry[0]] = button
		caches[entry[0]] = _new_cache()
	scroll = ScrollContainer.new()
	scroll.name = "LeaderboardScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(canvas)
	for i in DATA.POOL_SIZE:
		var line := _make_line(canvas)
		pool.append(line)
	status = Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 26)
	canvas.add_child(status)
	my_line = _make_line(root)
	my_line.name = "MyRankFixed"
	my_line.custom_minimum_size.y = DATA.ROW_HEIGHT
	scroll.get_v_scroll_bar().value_changed.connect(_on_scroll)
	scroll.resized.connect(_render)
	scroll.gui_input.connect(_on_input)
	hide()

func _new_cache() -> Dictionary:
	return {"rows": [], "busy": false, "end": false, "error": "", "loaded": false, "generation": 0, "scroll": 0}

func _make_line(parent: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", DATA.ROW_GAP)
	line.set_meta("row_color", DATA.ROW_COLORS[0])
	line.draw.connect(func(): line.draw_rect(Rect2(Vector2.ZERO, line.size), line.get_meta("row_color")))
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line)
	var rank := Label.new()
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank.name = "Rank"
	var rank_padding := StyleBoxEmpty.new()
	rank_padding.content_margin_left = DATA.ROW_GAP
	rank.add_theme_stylebox_override("normal", rank_padding)
	rank.custom_minimum_size.x = DATA.RANK_WIDTH
	rank.add_theme_font_size_override("font_size", 27)
	line.add_child(rank)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.name = "Tier"
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line.add_child(icon)
	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.name = "Nickname"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 27)
	line.add_child(name_label)
	var score := Label.new()
	score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score.name = "MMR"
	var score_padding := StyleBoxEmpty.new()
	score_padding.content_margin_right = DATA.ROW_GAP
	score.add_theme_stylebox_override("normal", score_padding)
	score.add_theme_font_size_override("font_size", 25)
	line.add_child(score)
	return line

func show() -> void:
	var gateway := lobby.get_node("/root/LoginGateway")
	var current := String(gateway.user_id)
	if current != owner_id:
		owner_id = current
		generation += 1
		for key in caches: caches[key] = _new_cache()
	root.show()
	title_plate.show()
	select_role(role)
	if lobby.main_modes_view != null:
		var modes = lobby.main_modes_view
		if not modes.ranked_profile_changed.is_connected(_render_my): modes.ranked_profile_changed.connect(_render_my)
		modes._request_ranked_profile()
	_render_my()

func hide() -> void:
	root.hide()
	title_plate.hide()

func select_role(next: String) -> void:
	if not caches.has(next): return
	if caches.has(role): caches[role].scroll = scroll.scroll_vertical
	role = next
	for key in tabs:
		var button: Button = tabs[key]
		button.disabled = key == role
		button.add_theme_stylebox_override("disabled", button.get_theme_stylebox("pressed"))
		button.add_theme_color_override("font_disabled_color", Color.WHITE)
	scroll.scroll_vertical = int(caches[role].scroll)
	_render()
	_render_my()
	if not caches[role].loaded and not caches[role].busy: _load_next()

func refresh() -> void:
	var old: Dictionary = caches[role]
	var next_generation := int(old.generation) + 1
	caches[role] = _new_cache()
	caches[role].generation = next_generation
	scroll.scroll_vertical = 0
	_render()
	_load_next()

func _load_next() -> void:
	var key := role
	var cache: Dictionary = caches[key]
	if cache.busy or cache.end: return
	var local: bool = lobby.get_node("/root/LocalTestMode").active
	if not local and String(lobby.get_node("/root/LoginGateway").user_id).is_empty():
		cache.error = DATA.GUEST
		_render()
		return
	cache.busy = true
	cache.error = ""
	var offset: int = cache.rows.size()
	var token: int = cache.generation
	var session := generation
	_render()
	var result := {}
	if local:
		var rows := []
		for i in range(offset, mini(offset + DATA.PAGE_SIZE, DATA.LOCAL_COUNT)):
			var mmr := 4000 - i * 40
			rows.append({"rank": i + 1, "nickname": DATA.LOCAL_NAME % (i + 1), "mmr": mmr, "tier": RULES.tier(mmr, i + 1)})
		result = {"rows": rows}
	else:
		var cloud: Node = cloud_override if cloud_override != null else lobby.get_node("/root/CloudStore")
		result = await cloud.request_optional_rpc("get_ranked_leaderboard", {"role": key, "page_offset": offset, "page_size": DATA.PAGE_SIZE})
	if not is_instance_valid(lobby) or session != generation or int(caches[key].generation) != token: return
	if not local and String(lobby.get_node("/root/LoginGateway").user_id) != owner_id: return
	cache.busy = false
	if result.get("rows") is Array:
		cache.rows.append_array(result.rows)
		cache.loaded = true
		cache.end = result.rows.size() < DATA.PAGE_SIZE
	else:
		cache.error = DATA.UNAVAILABLE if result.get("unavailable", false) else DATA.ERROR
	if role == key: _render()

func _on_scroll(_value: float) -> void:
	_render()
	var bar := scroll.get_v_scroll_bar()
	if root.visible and bar.max_value > bar.page and bar.value >= bar.max_value - bar.page - 1.0:
		_load_next()

func _on_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and scroll.scroll_vertical == 0: touch_start = event.position.y
		elif not event.pressed:
			if touch_start >= 0 and event.position.y - touch_start >= DATA.PULL_DISTANCE: refresh()
			touch_start = -1.0
	elif event is InputEventScreenDrag and touch_start >= 0 and event.position.y - touch_start >= DATA.PULL_DISTANCE:
		touch_start = -1.0
		refresh()

func _render() -> void:
	if scroll == null or canvas == null: return
	var cache: Dictionary = caches[role]
	var rows: Array = cache.rows
	canvas.custom_minimum_size = Vector2(0, rows.size() * DATA.ROW_HEIGHT + DATA.ROW_HEIGHT)
	var start := maxi(0, int(scroll.scroll_vertical / DATA.ROW_HEIGHT) - 1)
	for i in pool.size():
		var index := start + i
		var line: HBoxContainer = pool[i]
		line.visible = index < rows.size()
		if line.visible:
			line.position = Vector2(0, index * DATA.ROW_HEIGHT)
			line.size = Vector2(maxf(canvas.size.x, scroll.size.x), DATA.ROW_HEIGHT)
			_set_line(line, rows[index])
			line.set_meta("row_color", DATA.ROW_COLORS[index % DATA.ROW_COLORS.size()])
			line.queue_redraw()
	status.position = Vector2(0, rows.size() * DATA.ROW_HEIGHT)
	status.size = Vector2(maxf(canvas.size.x, scroll.size.x), DATA.ROW_HEIGHT)
	status.text = DATA.LOADING if cache.busy else (cache.error if not cache.error.is_empty() else (DATA.END if cache.end else ""))

func _render_my() -> void:
	if my_line == null: return
	var local: bool = lobby.get_node("/root/LocalTestMode").active
	var guest := String(lobby.get_node("/root/LoginGateway").user_id).is_empty() and not local
	var state := {}
	if lobby.main_modes_view != null: state = lobby.main_modes_view.ranked_profile_data.get(role, {})
	if state.is_empty() or guest:
		_set_line(my_line, {"rank": 0, "nickname": DATA.GUEST if guest else DATA.NO_RECORD})
	else:
		_set_line(my_line, {"rank": state.get("server_rank", 0), "nickname": DATA.MY_RANK, "tier": state.get("tier", ""), "mmr": state.get("mmr", 0)})

func _set_line(line: HBoxContainer, data: Dictionary) -> void:
	var rank: int = int(data.get("rank", 0))
	var tier := String(data.get("tier", ""))
	var label: Label = line.get_node("Rank")
	label.text = ("%d위" % rank) if rank > 0 else (DATA.OUTSIDE_RANK if line == my_line else "")
	label.add_theme_color_override("font_color", DATA.PODIUM_COLORS[rank - 1] if rank > 0 and rank <= DATA.PODIUM_COLORS.size() else Color.WHITE)
	var path := RULES.icon_path(tier)
	if not path.is_empty() and not textures.has(path): textures[path] = load(path)
	(line.get_node("Tier") as TextureRect).texture = textures.get(path)
	(line.get_node("Nickname") as Label).text = String(data.get("nickname", ""))
	(line.get_node("MMR") as Label).text = "MMR %d" % int(data.mmr) if data.has("mmr") else ""
