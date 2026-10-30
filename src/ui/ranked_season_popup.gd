extends RefCounted

const ROW_SKIN := preload("res://src/ui/mission_row_skin.gd")
const DATA := preload("res://src/data/mailbox_catalog.gd")
const HEROES := preload("res://src/data/hero_character_catalog.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const RULES := preload("res://src/data/ranked_rules.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const MODAL_LAYER := 130 # Same tier as DungeonEntryNotice.
var lobby: Control
var panel: PanelContainer
var result: Dictionary = {}
var loading := false
var shown := false
var local := false
var rpc_override: Callable

func install(owner: Control) -> void:
	lobby = owner
	lobby.get_node("/root/CloudStore").status_changed.connect(_on_status)
	lobby.tree_exiting.connect(_disconnect)
	refresh.call_deferred()

func _disconnect() -> void:
	var cloud := lobby.get_node("/root/CloudStore")
	if cloud.status_changed.is_connected(_on_status): cloud.status_changed.disconnect(_on_status)

func _on_status(_message: String) -> void:
	refresh.call_deferred()

func refresh() -> void:
	if loading or shown or not is_instance_valid(lobby) or not lobby.is_inside_tree(): return
	local = lobby.get_node("/root/LocalTestMode").active
	var account := SCOPE.user_id
	if not local and (account.is_empty() or not lobby.get_node("/root/CloudStore").can_write()): return
	loading = true
	var response: Dictionary = {}
	if local:
		var config := ConfigFile.new()
		SCOPE.load_config(config, PROGRESS.SAVE_PATH)
		if not config.get_value("ranked_season", "preview_seen", false): response = {"result":DATA.SEASON_PREVIEW.duplicate(true)}
	else:
		response = await _request("latest_unseen_ranked_season", {})
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: loading = false; return
	if not response.get("result") is Dictionary: loading = false; return
	result = response.result
	while lobby.get_node("/root/TutorialFlow").locks_lobby() or lobby.get_node("/root/TutorialFlow").modal_visible:
		await lobby.get_tree().create_timer(0.5).timeout
		if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: loading = false; return
	shown = true
	loading = false
	_build()

func _build() -> void:
	var layer := ColorRect.new()
	layer.name = "RankedSeasonOverlay"
	layer.color = Color(0, 0, 0, 0.75)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	# Own canvas layer: lobby art raised with z_index must not draw over the modal.
	var canvas := CanvasLayer.new()
	canvas.name = "RankedSeasonLayer"
	canvas.layer = MODAL_LAYER
	lobby.add_child(canvas)
	layer.theme = lobby.theme
	canvas.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.name = "Frame"
	panel.custom_minimum_size = Vector2(DATA.FRAME_SIZE.x, 0)
	var frame := lobby.panel_style.duplicate() as StyleBox
	frame.set_content_margin_all(DATA.FRAME_MARGIN)
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	SKIN.apply(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", DATA.GAP)
	panel.add_child(box)
	_label(box, "주간 랭킹 정산", 40)
	for role in ["hero", "demon"]:
		var state: Variant = result.get(role)
		if not state is Dictionary: continue
		var tier := String(state.get("final_tier", ""))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", ROW_SKIN.style(DATA.SEASON_ROW_FILL, DATA.SEASON_ROW_EDGE, DATA.ROW_PADDING))
		box.add_child(card)
		var line := HBoxContainer.new()
		line.name = role.capitalize() + "Row"
		line.add_theme_constant_override("separation", DATA.ROW_GAP)
		card.add_child(line)
		var played := int(state.get("wins", 0)) + int(state.get("losses", 0)) > 0
		var usage_id := String(result.get("hero_top_hero_id" if role == "hero" else "demon_top_transcendence_id", ""))
		var path := ""
		if played and not usage_id.is_empty():
			if role == "hero": path = String(STAGES.get_stage(HEROES.stage_for_hero(usage_id)).get("portrait_path", ""))
			else: path = MONSTERS.get_ui_icon_path(usage_id)
		if not path.is_empty() and DATA.texture(path) != null: _icon(line, path, DATA.SEASON_PORTRAIT_SIZE, "Portrait", role == "demon")
		else: _icon(line, RULES.icon_path(tier), DATA.SEASON_PORTRAIT_SIZE, "TierFallback")
		if not played: continue
		var detail := VBoxContainer.new()
		line.add_child(detail)
		var tier_line := HBoxContainer.new()
		detail.add_child(tier_line)
		_icon(tier_line, RULES.icon_path(tier), DATA.SEASON_TIER_SIZE, "TierIcon")
		var text := DATA.SEASON_ROLE_FORMAT % ("마왕" if role == "demon" else "용사")
		if tier != "hero": text += " · " + RULES.display_name(tier)
		if tier == "hero" and int(state.get("server_rank", 0)) > 0: text += " · %d위" % int(state.server_rank)
		text += " · MMR %d" % int(state.get("final_mmr", 0))
		_label(tier_line, text, 28)
		var top_role := String(result.get("demon_top_role", ""))
		if role == "demon" and not top_role.is_empty(): _label(detail, "주력 역할: " + MONSTERS.get_role_label(top_role), 26)
	var reward_tier := String(result.get("reward_tier", ""))
	var hero: Dictionary = result.get("hero", {})
	var demon: Dictionary = result.get("demon", {})
	var reward_role := "용사" if int(hero.get("final_mmr", -1)) > int(demon.get("final_mmr", -1)) else "마왕"
	_label(box, DATA.SEASON_REWARD_FORMAT % [reward_role, RULES.display_name(reward_tier)], 28)
	var currencies := DATA.currencies()
	for key in ["demon_token", "hero_token"]:
		var line := HBoxContainer.new()
		box.add_child(line)
		_icon(line, String(currencies.get(key, {}).get("icon_path", "")))
		_label(line, "%s %d" % [currencies.get(key, {}).get("name", key), int(result.get(key, 0))], 28)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for spec in [["우편함으로", true], ["확인", false]]:
		var button := Button.new()
		button.text = spec[0]
		ROW_SKIN.apply_button(button)
		button.custom_minimum_size = DATA.SEASON_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(button)
		button.pressed.connect(_close.bind(spec[1], layer))

func _label(parent: Node, text: String, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)

func _icon(parent: Node, path: String, size: int = 96, node_name: String = "", crop: bool = false) -> void:
	var icon := TextureRect.new()
	icon.name = node_name if not node_name.is_empty() else "Icon"
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not path.is_empty():
		icon.texture = DATA.texture(path)
		if crop and icon.texture != null:
			var image := icon.texture.get_image()
			if image != null and image.get_used_rect().has_area():
				var atlas := AtlasTexture.new()
				atlas.atlas = icon.texture
				atlas.region = image.get_used_rect()
				icon.texture = atlas
	parent.add_child(icon)

func _close(open_mail: bool, layer: Control) -> void:
	layer.queue_free()
	if open_mail:
		lobby.mailbox_view.show()
	if local:
		var config := ConfigFile.new()
		SCOPE.load_config(config, PROGRESS.SAVE_PATH)
		config.set_value("ranked_season", "preview_seen", true)
		SCOPE.save_configs({PROGRESS.SAVE_PATH.get_file():config})
	else:
		await _request("mark_ranked_season_seen", {"p_week_start":result.get("week_start", "")})

func _request(method: String, args: Dictionary) -> Dictionary:
	if rpc_override.is_valid(): return await rpc_override.call(method, args)
	return await lobby.get_node("/root/CloudStore").request_optional_rpc(method, args)
