extends SceneTree

const STORE := preload("res://src/systems/mailbox_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const VIEW := preload("res://src/ui/lobby_mailbox_view.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://mailbox_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var mails := STORE.local_mail()
	assert(mails.size() == 2 and STORE.unread_count(mails) == 2)
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
	assert(not PROGRESS.add_hero_token(-11) and PROGRESS.get_hero_token() == 10)
	SCOPE.guest_directory = "user://mailbox_ui_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	root.get_node("LocalTestMode").active = true
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	var view = lobby.settings_view.mailbox_view
	view.refresh()
	assert(view.mail.size() == 2 and STORE.unread_count(view.mail) == 2)
	assert("2" in lobby.settings_view.other_menu_buttons.mailbox.text)
	await view.claim_all()
	assert(PROGRESS.get_demon_token() == 10 and PROGRESS.get_hero_token() == 10)
	assert(STORE.unread_count(view.mail) == 0)
	lobby.queue_free()
	print("PASS mailbox_smoke")
	quit()
