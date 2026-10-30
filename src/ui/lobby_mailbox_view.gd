extends RefCounted

const DATA := preload("res://src/data/mailbox_catalog.gd")
const STORE := preload("res://src/systems/mailbox_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const MODAL_LAYER := 130 # Same tier as DungeonEntryNotice.
var lobby: Control
var root: ColorRect
var list: VBoxContainer
var title: Label
var status: Label
var all_button: Button
var delete_button: Button
var confirmation: ConfirmationDialog
var delete_ids: Array = []
var mail: Array = []
var busy := false
var available := false
var rpc_override: Callable

func install(owner: Control) -> void:
	lobby = owner
	root = ColorRect.new()
	root.name = "MailboxOverlay"
	root.color = Color(0, 0, 0, 0.75)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	# Own canvas layer: lobby art raised with z_index must not draw over the modal.
	var canvas := CanvasLayer.new()
	canvas.name = "MailboxLayer"
	canvas.layer = MODAL_LAYER
	lobby.add_child(canvas)
	root.theme = lobby.theme
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.gui_input.connect(_outside_input)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.name = "Frame"
	panel.custom_minimum_size = Vector2(840, 1100)
	var frame := lobby.panel_style.duplicate() as StyleBox
	frame.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	SKIN.apply(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	title = Label.new()
	title.text = DATA.TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	heading.add_child(title)
	var close := Button.new()
	close.text = DATA.CLOSE_SYMBOL
	close.tooltip_text = DATA.CLOSE
	close.custom_minimum_size = DATA.BUTTON_SIZE
	SKIN.apply(close)
	heading.add_child(close)
	close.pressed.connect(hide)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 28)
	box.add_child(status)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	all_button = Button.new()
	all_button.text = DATA.CLAIM_ALL
	all_button.custom_minimum_size = DATA.BUTTON_SIZE
	all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SKIN.apply(all_button)
	buttons.add_child(all_button)
	all_button.pressed.connect(claim_all)
	delete_button = Button.new()
	delete_button.text = DATA.DELETE_ALL
	delete_button.custom_minimum_size = DATA.BUTTON_SIZE
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SKIN.apply(delete_button)
	buttons.add_child(delete_button)
	delete_button.pressed.connect(_confirm_delete_all)
	confirmation = ConfirmationDialog.new()
	root.add_child(confirmation)
	confirmation.confirmed.connect(_delete_selected)
	root.hide()
	refresh.call_deferred()

func show() -> void:
	root.show()
	root.move_to_front()
	refresh()

func hide() -> void:
	root.hide()

func blocks_input(event: InputEvent) -> bool:
	if not root.visible: return false
	if event.is_action_pressed("ui_cancel"):
		if confirmation.visible: confirmation.hide()
		else: hide()
		lobby.get_viewport().set_input_as_handled()
	return true

func _outside_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: hide()
	elif event is InputEventScreenTouch and event.pressed: hide()

func refresh() -> void:
	if busy or not is_instance_valid(lobby) or not lobby.is_inside_tree(): return
	busy = true
	status.text = DATA.LOADING
	var local: bool = lobby.get_node("/root/LocalTestMode").active
	var account := SCOPE.user_id
	var result: Dictionary = {"unavailable": true}
	if local: result = {"mail": STORE.local_mail()}
	elif not account.is_empty() and lobby.get_node("/root/CloudStore").can_write():
		result = await lobby.get_node("/root/CloudStore").request_optional_rpc("list_my_mail", {"p_recent_limit": DATA.LIST_LIMIT})
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	available = result.get("mail") is Array
	if available:
		mail = result.mail
		var ok := STORE.recover(mail)
		if not local and ok: ok = await _ack_pending(account)
		if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
		status.text = DATA.EMPTY if mail.is_empty() else ("" if ok else DATA.ERROR)
	else:
		mail = []
		status.text = DATA.UNAVAILABLE if result.get("unavailable", false) else DATA.ERROR
	busy = false
	_render()

func _render() -> void:
	for child in list.get_children(): child.queue_free()
	var count := STORE.unread_count(mail)
	title.text = DATA.TITLE_FORMAT % [DATA.TITLE, count]
	if is_instance_valid(lobby.main_tools_view): lobby.main_tools_view.set_notification_count(&"mailbox", count)
	all_button.disabled = busy or not available or count == 0
	delete_button.disabled = busy or not available or _deletable_ids().is_empty()
	var definitions := DATA.currencies()
	for item in mail:
		var card := PanelContainer.new()
		card.name = "MailRow"
		card.custom_minimum_size.y = DATA.ROW_HEIGHT
		var style := StyleBoxFlat.new()
		style.bg_color = DATA.ROW_COLOR
		style.border_color = DATA.ROW_BORDER
		style.set_border_width_all(2)
		style.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", style)
		list.add_child(card)
		var row := VBoxContainer.new()
		card.add_child(row)
		var sender := String(item.sender) if item.get("sender") is String else ""
		if sender.is_empty(): sender = DATA.SENDERS.get(item.get("kind", ""), DATA.DEFAULT_SENDER)
		var heading := Label.new()
		heading.name = "SenderTitle"
		heading.text = DATA.HEADER_FORMAT % [sender, item.get("title", "")]
		heading.add_theme_font_size_override("font_size", 28)
		row.add_child(heading)
		var body := Label.new()
		body.name = "Body"
		body.text = String(item.get("body", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.max_lines_visible = 2
		body.mouse_filter = Control.MOUSE_FILTER_STOP
		body.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed): body.max_lines_visible = -1 if body.max_lines_visible == 2 else 2
		)
		body.add_theme_font_size_override("font_size", 26)
		row.add_child(body)
		var date := Label.new()
		date.name = "Date"
		date.text = String(item.get("created_at", "")).left(10)
		row.add_child(date)
		var line := HBoxContainer.new()
		row.add_child(line)
		var attachments: Dictionary = item.get("attachments", {})
		if attachments.is_empty(): _icon(line, DATA.MESSAGE_ICON)
		for currency in attachments:
			if not definitions.has(currency): continue
			_icon(line, String(definitions[currency].icon_path))
			var amount := Label.new()
			amount.text = str(attachments[currency])
			amount.add_theme_font_size_override("font_size", 28)
			line.add_child(amount)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(spacer)
		if not attachments.is_empty():
			var claim := Button.new()
			claim.text = DATA.CLAIM if STORE.pending(item) else DATA.CLAIMED
			claim.custom_minimum_size = DATA.BUTTON_SIZE
			claim.disabled = busy or not available or not STORE.pending(item)
			SKIN.apply(claim)
			line.add_child(claim)
			claim.pressed.connect(claim_one.bind(String(item.id)))
		var remove := Button.new()
		remove.text = DATA.DELETE
		remove.custom_minimum_size = DATA.BUTTON_SIZE
		remove.tooltip_text = DATA.DELETE
		remove.disabled = busy or not available or not STORE.deletable(item)
		SKIN.apply(remove)
		line.add_child(remove)
		remove.pressed.connect(_confirm_delete.bind([item.id]))

func _icon(parent: Control, path: String) -> void:
	var icon := TextureRect.new()
	icon.name = "AttachmentIcon"
	icon.custom_minimum_size = DATA.ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = DATA.texture(path)
	parent.add_child(icon)

func _deletable_ids() -> Array:
	var ids: Array = []
	for item in mail:
		if STORE.deletable(item): ids.append(item.id)
	return ids

func _confirm_delete_all() -> void:
	_confirm_delete(_deletable_ids())

func _confirm_delete(ids: Array) -> void:
	if busy or not available or ids.is_empty(): return
	delete_ids = ids
	confirmation.dialog_text = DATA.DELETE_CONFIRM % ids.size()
	confirmation.popup_centered()

func _delete_selected() -> void:
	if busy: return
	var ids := delete_ids.filter(func(id): return id in _deletable_ids())
	if ids.is_empty(): return
	busy = true
	_render()
	var account := SCOPE.user_id
	var result: Dictionary = {}
	if lobby.get_node("/root/LocalTestMode").active:
		if STORE.delete_local(ids): result = {"ids": ids}
	elif not account.is_empty() and lobby.get_node("/root/CloudStore").can_write():
		result = await lobby.get_node("/root/CloudStore").request_optional_rpc("delete_mail", {"p_ids": ids})
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	if result.get("ids") is Array:
		var removed: Array = result.ids.filter(func(id): return id in ids)
		mail = mail.filter(func(item): return item.id not in removed)
		status.text = DATA.EMPTY if mail.is_empty() else ""
	else:
		status.text = DATA.UNAVAILABLE if result.get("unavailable", false) else DATA.ERROR
		if result.get("unavailable", false): available = false
	busy = false
	_render()

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
			if item.id == id: item.claim_state = "granted"; if local: item["applied_at"] = "local"
	if ok and not local: ok = await _ack_pending(account)
	if not is_instance_valid(lobby) or not lobby.is_inside_tree() or account != SCOPE.user_id: busy = false; return
	status.text = "" if ok else (DATA.UNAVAILABLE if result.get("unavailable", false) else DATA.ERROR)
	if result.get("unavailable", false): available = false
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
