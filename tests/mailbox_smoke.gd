extends SceneTree

const STORE := preload("res://src/systems/mailbox_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const VIEW := preload("res://src/ui/lobby_mailbox_view.gd")

var ack_succeeds := false

func fake_ack(ids: Array) -> Dictionary:
	return {"ids":ids} if ack_succeeds else {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://mailbox_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var mails := STORE.local_mail()
	assert(mails.size() == 3 and STORE.unread_count(mails) == 2)
	assert(STORE.apply(mails[0].id, mails[0].attachments))
	assert(PROGRESS.get_demon_token() == 10 and STORE.applied(mails[0].id))
	assert(STORE.apply(mails[0].id, mails[0].attachments))
	assert(PROGRESS.get_demon_token() == 10)
	var valid_dir := SCOPE.guest_directory
	SCOPE.guest_directory = "user://missing/mailbox"
	assert(not STORE.apply(mails[1].id, mails[1].attachments))
	SCOPE.guest_directory = valid_dir
	assert(PROGRESS.get_hero_token() == 0 and not STORE.applied(mails[1].id))
	mails[1]["claim_state"] = "granted"
	assert(STORE.recover(mails))
	assert(PROGRESS.get_hero_token() == 10 and STORE.unread_count(STORE.local_mail()) == 0)
	assert(STORE.forget_acknowledged([mails[0].id]))
	assert(not STORE.applied(mails[0].id) and PROGRESS.get_demon_token() == 10)
	assert(not PROGRESS.add_hero_token(-11) and PROGRESS.get_hero_token() == 10)
	SCOPE.guest_directory = "user://mailbox_ui_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	root.get_node("LocalTestMode").active = true
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	var view = lobby.mailbox_view
	view.refresh()
	assert(view.mail.size() == 3 and STORE.unread_count(view.mail) == 2)
	view.show()
	assert(view.root.visible)
	assert(view.list.get_child_count() >= 3)
	var row = view.list.get_child(view.list.get_child_count() - 1)
	assert("운영팀" in row.get_node("SenderTitle").text)
	assert(not row.get_node("Body").text.is_empty())
	assert(row.find_child("AttachmentIcon", true, false).texture != null)
	assert(view._deletable_ids().size() == 1)
	view._confirm_delete_all()
	assert(view.delete_ids.size() == 1)
	view.confirmation.hide()
	await view._delete_selected()
	assert(view.mail.size() == 2)
	view.hide()
	assert(not view.root.visible)
	root.get_node("LocalTestMode").active = false
	await view.refresh()
	assert(view.status.text == preload("res://src/data/mailbox_catalog.gd").UNAVAILABLE)
	assert(view.all_button.disabled and view.delete_button.disabled)
	root.get_node("LocalTestMode").active = true
	await view.refresh()
	await view.claim_all()
	assert(PROGRESS.get_demon_token() == 10 and PROGRESS.get_hero_token() == 10)
	assert(STORE.unread_count(view.mail) == 0)
	var old_mail := {"id":"old-granted", "claim_state":"granted", "attachments":{"hero_token":7}}
	var server_mail: Array = [old_mail]
	for i in 200: server_mail.append({"id":str(i), "claim_state":"granted", "applied_at":"done"})
	assert(STORE.recover(server_mail) and PROGRESS.get_hero_token() == 17)
	view.mail = server_mail
	view.rpc_override = fake_ack
	assert(not await view._ack_pending(SCOPE.user_id))
	assert(STORE.recover(server_mail) and PROGRESS.get_hero_token() == 17 and STORE.applied("old-granted"))
	ack_succeeds = true
	assert(await view._ack_pending(SCOPE.user_id))
	assert(not STORE.applied("old-granted") and old_mail.applied_at == "acknowledged")
	lobby.queue_free()
	print("PASS mailbox_smoke")
	quit()
