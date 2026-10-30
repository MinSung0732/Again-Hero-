extends RefCounted

const DATA := preload("res://src/data/mailbox_catalog.gd")
const ROW_SKIN := preload("res://src/ui/mission_row_skin.gd")
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
	panel.custom_minimum_size = DATA.FRAME_SIZE
	var frame := lobby.panel_style.duplicate() as StyleBox
	frame.set_content_margin_all(DATA.FRAME_MARGIN)
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	SKIN.apply(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", DATA.GAP)
	panel.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	title = Label.new()
	title.text = DATA.TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	heading.add_child(title)
	var close := Button.new()
	close.text = DATA.CLOSE
	close.tooltip_text = DATA.CLOSE
	ROW_SKIN.apply_button(close)
	close.custom_minimum_size = DATA.CLOSE_SIZE
	heading.add_child(close)
	close.pressed.connect(hide)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", DATA.GAP)
	scroll.add_child(list)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 28)
	box.add_child(status)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	all_button = Button.new()
	all_button.text = DATA.CLAIM_ALL
	ROW_SKIN.apply_button(all_button)
	all_button.custom_minimum_size = DATA.BUTTON_SIZE
	all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(all_button)
	all_button.pressed.connect(claim_all)
	delete_button = Button.new()
	delete_button.text = DATA.DELETE_ALL
	ROW_SKIN.apply_button(delete_button)
	delete_button.custom_minimum_size = DATA.BUTTON_SIZE
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	if available and mail.is_empty():
		var empty := TextureRect.new()
		empty.name = "EmptyIllustration"
		empty.custom_minimum_size = DATA.EMPTY_SIZE
		empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		empty.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		empty.texture = DATA.texture(DATA.EMPTY_ICON)
		list.add_child(empty)
	var definitions := DATA.currencies()
	for item in mail:
		var card := PanelContainer.new()
		card.name = "MailRow"
		card.custom_minimum_size.y = DATA.ROW_HEIGHT
		card.add_theme_stylebox_override("panel", ROW_SKIN.style("32233e", "776184", DATA.ROW_PADDING))
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", DATA.ROW_GAP)
		card.add_child(row)
		var attachments: Dictionary = item.get("attachments", {})
		var reward := VBoxContainer.new()
		reward.custom_minimum_size.x = DATA.ATTACHMENT_WIDTH
		row.add_child(reward)
		if attachments.is_empty(): _icon(reward, DATA.MESSAGE_ICON)
		for currency in attachments:
			if not definitions.has(currency): continue
			_icon(reward, String(definitions[currency].icon_path))
			var amount := Label.new()
			amount.text = str(attachments[currency])
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			amount.add_theme_font_size_override("font_size", 28)
			reward.add_child(amount)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(content)
		var sender := String(item.sender) if item.get("sender") is String else ""
		if sender.is_empty(): sender = DATA.SENDERS.get(item.get("kind", ""), DATA.DEFAULT_SENDER)
		var heading := Label.new()
		heading.name = "SenderTitle"
		heading.text = DATA.HEADER_FORMAT % [sender, item.get("title", "")]
		heading.add_theme_color_override("font_color", DATA.SENDER_COLOR)
		heading.add_theme_font_size_override("font_size", 28)
		heading.clip_text = true
		content.add_child(heading)
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
		content.add_child(body)
		var date := Label.new()
		date.name = "Date"
		date.add_theme_font_size_override("font_size", DATA.DATE_FONT_SIZE)
		date.text = String(item.get("created_at", "")).left(10)
		content.add_child(date)
		var actions := VBoxContainer.new()
		row.add_child(actions)
		if not attachments.is_empty():
			if STORE.pending(item):
				var claim := Button.new()
				claim.name = "Claim"
				claim.text = DATA.CLAIM
				ROW_SKIN.apply_button(claim)
				claim.custom_minimum_size = DATA.ACTION_SIZE
				claim.disabled = busy or not available
				actions.add_child(claim)
				claim.pressed.connect(claim_one.bind(String(item.id)))
			else:
				var stamp := TextureRect.new()
				stamp.name = "ClaimedStamp"
				stamp.custom_minimum_size = DATA.ACTION_SIZE
				stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				stamp.texture = DATA.texture(DATA.CLAIMED_ICON)
				stamp.tooltip_text = DATA.CLAIMED
				actions.add_child(stamp)
				var claimed_label := Label.new()
				claimed_label.text = DATA.CLAIMED
				claimed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				claimed_label.add_theme_font_size_override("font_size", 20)
				actions.add_child(claimed_label)
		var remove := Button.new()
		remove.name = "Delete"
		remove.icon = DATA.texture(DATA.TRASH_ICON)
		remove.expand_icon = true
		remove.custom_minimum_size = DATA.ACTION_SIZE
		remove.tooltip_text = DATA.DELETE
		remove.disabled = busy or not available or not STORE.deletable(item)
		SKIN.apply(remove)
		actions.add_child(remove)
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
