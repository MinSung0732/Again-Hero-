extends RefCounted

const DATA := preload("res://src/data/mailbox_catalog.gd")
const RULES := preload("res://src/data/ranked_rules.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
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
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	lobby.add_child(layer)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -420; panel.offset_right = 420
	panel.offset_top = -500; panel.offset_bottom = 500
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	_label(box, "주간 랭킹 정산", 40)
	for role in ["demon", "hero"]:
		var state: Variant = result.get(role)
		if not state is Dictionary: continue
		var tier := String(state.get("final_tier", ""))
		var line := HBoxContainer.new()
		box.add_child(line)
		_icon(line, RULES.icon_path(tier))
		var text := ("마왕" if role == "demon" else "용사") + " · " + RULES.display_name(tier)
		if tier == "hero" and int(state.get("server_rank", 0)) > 0: text += " %d위" % int(state.server_rank)
		text += " · MMR %d" % int(state.get("final_mmr", 0))
		_label(line, text, 28)
	_label(box, "보상 기준 · " + RULES.display_name(String(result.get("reward_tier", ""))), 28)
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
		button.custom_minimum_size = Vector2(220, 80)
		SKIN.apply(button)
		buttons.add_child(button)
		button.pressed.connect(_close.bind(spec[1], layer))

func _label(parent: Node, text: String, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)

func _icon(parent: Node, path: String) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not path.is_empty(): icon.texture = DATA.texture(path)
	parent.add_child(icon)

func _close(open_mail: bool, layer: Control) -> void:
	layer.queue_free()
	if open_mail:
		lobby._switch_tab("other")
		lobby.settings_view.show_mailbox()
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
