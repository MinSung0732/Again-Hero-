extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const MAIL := preload("res://src/systems/mailbox_store.gd")
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SHOP_TOKEN: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = true
	var folder := "user://shop_token_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	var demon: Control = lobby.get_node("SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopTokenChip")
	check(not demon.is_visible_in_tree(), "hidden on main")
	check(PROGRESS.add_demon_token(37), "save demon token")
	lobby._switch_tab("shop")
	await process_frame
	check(demon.is_visible_in_tree(), "demon visible")
	check(demon.get_node("TokenRow/Icon").texture != null, "demon icon")
	check(demon.get_node("TokenRow/Value").text.ends_with("37"), "demon balance")
	check(PROGRESS.add_demon_token(5), "change demon balance")
	root.get_node("CloudStore").canonical_reloaded.emit()
	check(demon.get_node("TokenRow/Value").text.ends_with("42"), "refresh balance")
	check(MAIL.apply("shop-token-test", {"hero_token": 19}), "mail token reward")
	lobby.hero_lobby_view.set_active(true)
	lobby._switch_tab("shop")
	await process_frame
	var hero: Control = lobby.hero_lobby_view.bodies.shop.get_node("ShopTokenChip")
	check(hero.is_visible_in_tree() and not demon.is_visible_in_tree(), "hero only")
	check(hero.get_node("TokenRow/Icon").texture != null, "hero icon")
	check(hero.get_node("TokenRow/Value").text.ends_with("19"), "hero balance")
	for height in [1920, 2400]:
		hero = lobby.hero_lobby_view.bodies.shop.get_node("ShopTokenChip")
		root.size = Vector2i(1080, height)
		await process_frame
		check(hero.get_global_rect().position.x >= 0 and hero.get_global_rect().end.x <= root.get_visible_rect().size.x, "hero within width")
		lobby.hero_lobby_view.set_active(false)
		await process_frame
		check(demon.get_global_rect().position.x >= 0 and demon.get_global_rect().end.x <= root.get_visible_rect().size.x, "demon within width")
		lobby.hero_lobby_view.set_active(true)
	hero = lobby.hero_lobby_view.bodies.shop.get_node("ShopTokenChip")
	lobby._switch_tab("other")
	await process_frame
	check(not hero.is_visible_in_tree() and not demon.is_visible_in_tree(), "hidden on other")
	print("SHOP_TOKEN ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
