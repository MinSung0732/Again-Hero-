extends RefCounted

const DATA := preload("res://src/data/mailbox_catalog.gd")
const STORE := preload("res://src/systems/mailbox_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const POLICY := preload("res://src/data/lobby_ui_policy_catalog.gd")
var settings_ref: WeakRef
var lobby: Control
var root: VBoxContainer
var title_plate: PanelContainer
var list: VBoxContainer
var status: Label
var all_button: Button
var rows: Array = []
var mail: Array = []
var busy := false
var rpc_override: Callable

func install(owner: RefCounted, parent: Control) -> void:
	settings_ref = weakref(owner)
	lobby = owner.lobby
	root = VBoxContainer.new()
	root.name = "MailboxContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(root)
	var title := Label.new()
	title.text = DATA.TITLE
	title_plate = owner._title_plate(lobby.other_tab, title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 28)
	root.add_child(status)
	all_button = Button.new()
	all_button.text = DATA.CLAIM_ALL
	all_button.custom_minimum_size.y = 88
	SKIN.apply(all_button)
	root.add_child(all_button)
	all_button.pressed.connect(claim_all)
	hide()
	refresh.call_deferred()

func show() -> void:
	root.show()
	title_plate.show()
	refresh()

func hide() -> void:
	root.hide()
	title_plate.hide()

func refresh() -> void:
	if busy or not is_instance_valid(lobby) or not lobby.is_inside_tree(): return
	busy = true
	status.text = DATA.LOADING
	var local: bool = lobby.get_node("/root/LocalTestMode").active
	var account := SCOPE.user_id
	var result: Dictionary = {}
	if local:
		result = {"mail": STORE.local_mail()}
	elif not account.is_empty() and lobby.get_node("/root/CloudStore").can_write():
		result = await lobby.get_node("/root/CloudStore").request_optional_rpc("list_my_mail", {"p_recent_limit":DATA.LIST_LIMIT})
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	if result.get("mail") is Array:
		mail = result.mail
		var ok := STORE.recover(mail)
		if not local and ok: ok = await _ack_pending(account)
		if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
		status.text = DATA.EMPTY if mail.is_empty() else ("" if ok else DATA.ERROR)
	else:
		status.text = DATA.ERROR
	busy = false
	_render()

func _render() -> void:
	var owner: Variant = settings_ref.get_ref()
	if owner == null: return
	var button: Button = owner.other_menu_buttons.get("mailbox")
	var count := STORE.unread_count(mail)
	if button != null: button.text = DATA.TITLE + (" (%d)" % count if count > 0 else "") + POLICY.MENU_ARROW
	all_button.disabled = busy or count == 0
	var definitions := DATA.currencies()
	for i in mail.size():
		if i >= rows.size():
			var row := VBoxContainer.new()
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 28)
			row.add_child(label)
			var attachments := HBoxContainer.new()
			row.add_child(attachments)
			var claim := Button.new()
			claim.custom_minimum_size.y = 72
			SKIN.apply(claim)
			row.add_child(claim)
			list.add_child(row)
			rows.append(row)
		var row: VBoxContainer = rows[i]
		var item: Dictionary = mail[i]
		row.show()
		(row.get_child(0) as Label).text = "%s\n%s" % [item.get("title", ""), item.get("body", "")]
		var attachment_row := row.get_child(1)
		for child in attachment_row.get_children(): child.queue_free()
		for currency in item.get("attachments", {}):
			if not definitions.has(currency): continue
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(48, 48)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = DATA.texture(String(definitions[currency].icon_path))
			attachment_row.add_child(icon)
			var amount := Label.new()
			amount.text = str(item.attachments[currency])
			amount.add_theme_font_size_override("font_size", 28)
			attachment_row.add_child(amount)
		var claim: Button = row.get_child(2)
		for connection in claim.pressed.get_connections(): claim.pressed.disconnect(connection.callable)
		var pending: bool = STORE.pending(item)
		claim.text = DATA.CLAIM if pending else DATA.CLAIMED
		claim.disabled = busy or not pending
		claim.pressed.connect(claim_one.bind(String(item.id)))
	for i in range(mail.size(), rows.size()): rows[i].hide()

func claim_one(id: String) -> void:
	if busy: return
	busy = true
	_render()
	var local: bool = lobby.get_node("/root/LocalTestMode").active
	var account := SCOPE.user_id
	var result: Dictionary = {}
	if local:
		for item in mail:
			if item.id == id: result = {"id":id, "attachments":item.attachments}; break
	elif not account.is_empty() and lobby.get_node("/root/CloudStore").can_write():
		result = await lobby.get_node("/root/CloudStore").request_optional_rpc("grant_mail", {"p_id":id})
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	var ok: bool = result.get("id") == id and result.get("attachments") is Dictionary and STORE.apply(id, result.attachments)
	if ok:
		for item in mail:
			if item.id == id: item.claim_state = "granted"
	if ok and not local: ok = await _ack_pending(account)
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	status.text = "" if ok else DATA.ERROR
	busy = false
	_render()

func claim_all() -> void:
	for item in mail:
		if STORE.pending(item):
			await claim_one(String(item.id))
			if STORE.pending(item): return

func _ack_pending(account: String) -> bool:
	var ids: Array = STORE.pending_ids()
	if ids.is_empty(): return true
	var result: Dictionary = await _request_ack(ids)
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: return false
	if not result.get("ids") is Array: return false
	var confirmed: Array = result.ids.filter(func(id): return id in ids)
	if not STORE.forget_acknowledged(confirmed): return false
	for item in mail:
		if item.get("id") in confirmed: item["applied_at"] = "acknowledged"
	return confirmed.size() == ids.size()

func _request_ack(ids: Array) -> Dictionary:
	if rpc_override.is_valid(): return await rpc_override.call(ids)
	return await lobby.get_node("/root/CloudStore").request_optional_rpc("ack_mail", {"p_ids":ids})
