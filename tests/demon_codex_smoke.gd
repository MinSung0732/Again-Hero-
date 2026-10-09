extends SceneTree
const VIEW := preload("res://src/ui/lobby_demon_codex_view.gd")
const DATA := preload("res://src/data/demon_codex_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
class CodexOwner extends RefCounted:
	var lobby: Control
	func _title_plate(parent: Control, title: Label) -> PanelContainer:
		var panel := PanelContainer.new()
		parent.add_child(panel)
		panel.add_child(title)
		return panel
class CodexHost extends Control:
	var other_tab: Control = self
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("DEMON_CODEX: " + message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://demon-codex-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var font := FontFile.new()
	if font.load_dynamic_font("res://assets/fonts/Galmuri11.ttf") == OK: ThemeDB.fallback_font = font
	var host := CodexHost.new()
	root.add_child(host)
	var owner := CodexOwner.new()
	owner.lobby = host
	var parent := VBoxContainer.new()
	parent.size = Vector2(740,1400)
	host.add_child(parent)
	var view := VIEW.new()
	view.install(owner,parent)
	var before := COLLECTION.load_state().duplicate(true)
	view.show()
	check(view.pages.size() == 1,"lazy initial page")
	for category in DATA.CATEGORIES: view.select_category(category[0])
	check(view.pages.size() == 4,"four real categories")
	check(DATA.monster_ids(false).size() == 21 and DATA.monster_ids(true).size() == 4,"all registered monsters")
	for category in ["monsters","transcendent"]:
		view.select_category(category)
		var page: Dictionary = view.monster_pages[category]
		for id in page.ids:
			view.select_monster(category,id)
			check(page.name.text == DATA.MONSTERS.get_monster_name(id),"real name " + id)
			check(page.portrait.texture != null,"dot loaded " + id)
			check(page.stats.text.contains(DATA.stats(id)),"real stats " + id)
			if category == "transcendent":
				check(page.trans_view.unlock.text.contains(DATA.RULES.describe(id).split(" 및 ")[0].split(" 또는 ")[0]),"real unlock " + id)
				for kind in ["illustration","banner"]:
					check(not page.art_buttons[kind].disabled,"available artwork " + id + kind)
					view.preview(category,kind)
					check(view.popup.visible and view.preview_image.texture != null,"artwork preview " + id + kind)
					view.popup.hide()
				check(page.art_buttons.plus_banner.disabled == (id not in ["zeus","manticore"]),"no invented five-upgrade banners " + id)
		page.search.text = "does-not-exist"
		page.search.text_changed.emit(page.search.text)
		check(page.cards.values().all(func(card): return not card.visible),"empty search")
		page.search.text = ""
		page.search.text_changed.emit(page.search.text)
		check(page.cards.values().all(func(card): return card.visible),"clear restores cards")
		for width in [360,540,740,1000]:
			parent.size.x = width
			await process_frame
			await process_frame
			check(view.root.get_combined_minimum_size().x <= width,"no horizontal overflow %s %d" % [category,width])
			for card in page.cards.values(): check(card.size.x <= width and card.size.y >= 206,"complete cards fit width")
	view.select_category("transcendent")
	view.select_monster("transcendent","manticore")
	check(view.monster_pages.transcendent.identity.text.contains("폭발"),"localized role")
	view.preview("transcendent","plus_banner")
	check(view.preview_title.text.contains("5초월"),"five-upgrade preview")
	parent.hide()
	check(not view.popup.visible,"parent tab hidden closes preview")
	parent.show()
	view.scroll.scroll_vertical = 400
	view.monster_pages.transcendent.cards.zeus.confirmed.emit()
	check(view.monster_pages.transcendent.selected == "zeus" and view.scroll.scroll_vertical == 0,"card selects and returns to detail")
	view.select_category("skills")
	check(not view.popup.visible,"category change closes preview")
	for width in [360,540,740,1000]:
		parent.size.x = width
		for category in DATA.CATEGORIES:
			view.select_category(category[0])
			await process_frame
			await process_frame
			check(view.root.get_combined_minimum_size().x <= width,"all categories fit %s %d" % [category[0],width])
	var ordinary: Dictionary = view.monster_pages.monsters
	var cached: int = ordinary.extra.get_child_count()
	for i in range(10):
		view.select_category("monsters")
		for id in ordinary.ids: view.select_monster("monsters",id)
		view.hide()
		view.show()
	check(ordinary.extra.get_child_count() == cached,"details reused without reconstruction")
	check(COLLECTION.load_state() == before,"read-only collection and upgrade progress")
	view.hide()
	check(not view.root.visible and not view.title_plate.visible and not view.popup.visible,"navigation cleanup")
	host.free()
	print("DEMON_CODEX: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
