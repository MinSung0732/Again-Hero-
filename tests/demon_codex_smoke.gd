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
			check(page.stat_values.map(func(label): return label.text) == DATA.stat_values(id),"real structured stats " + id)
			if category == "transcendent":
				check(page.trans_view.unlock.text.contains(DATA.RULES.describe(id).split(" 및 ")[0].split(" 또는 ")[0]),"real unlock " + id)
				for kind in ["illustration","banner"]:
					check(not page.art_buttons[kind].disabled,"available artwork " + id + kind)
					view.preview(category,kind)
					check(view.preview_root.visible and view.preview_image.texture != null,"artwork preview " + id + kind)
					view.close_preview()
				check(page.art_buttons.plus_banner.disabled == (id not in ["zeus","manticore"]),"no invented five-upgrade banners " + id)
		# Cards preserve either state. A content switch must never toggle the disclosure.
		if page.body.visible: page.toggle.confirmed.emit()
		page.cards[page.ids[0]].confirmed.emit()
		check(not page.body.visible,"card cannot auto-open " + category)
		page.toggle.confirmed.emit()
		page.cards[page.ids[-1]].confirmed.emit()
		check(page.body.visible,"card preserves expanded state " + category)
		page.toggle.confirmed.emit()
		if category == "monsters":
			for id in page.ids:
				var groups := DATA.related_augment_groups(id)
				var detail: Control = page.detail_cache[id]
				check(detail.get_node("NormalAugments").get_meta("augment_ids") == groups.normal.map(func(entry): return String(entry.id)),"normal augment group " + id)
				check(detail.get_node("SpecialAugments").get_meta("augment_ids") == groups.special.map(func(entry): return String(entry.id)),"special augment group " + id)
				check(groups.normal.all(func(entry): return entry.augment_type == "normal"),"normal type " + id)
				check(groups.special.all(func(entry): return entry.augment_type == "special"),"special type " + id)
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
			check(page.grid.columns == 1,"compact single-column list")
			check(view.tabs.columns == (4 if width >= 460 else 2),"compact category navigation")
			for card in page.cards.values(): check(card.size.x <= width and is_equal_approx(card.size.y,VIEW.CARD_HEIGHT),"complete cards fit width")
	# Regression: all text lengths produce exactly the same collapsed list position.
	for category in ["monsters","transcendent"]:
		view.select_category(category)
		var page: Dictionary = view.monster_pages[category]
		for width in [360,540,740,1000]:
			parent.size.x = width
			if page.body.visible: page.toggle.confirmed.emit()
			await process_frame
			await process_frame
			var list_top: float = page.grid.position.y
			var summary_height: float = page.header.get_parent().size.y
			for id in page.ids:
				view.select_monster(category,id)
				await process_frame
				await process_frame
				check(is_equal_approx(page.grid.position.y,list_top),"text cannot shift collapsed grid %s %d" % [id,width])
				check(is_equal_approx(page.header.get_parent().size.y,summary_height),"fixed summary height " + id)
				check(page.header.size.y == VIEW.SUMMARY_HEIGHT,"fixed header height " + id)
				page.toggle.confirmed.emit()
				await process_frame
				await process_frame
				check(page.body.visible and page.toggle.text.contains("접기"),"explicitly expands " + id)
				check(view.root.get_combined_minimum_size().x <= width,"expanded detail fits %s %d" % [id,width])
				page.toggle.confirmed.emit()
				await process_frame
				await process_frame
				check(not page.body.visible and is_equal_approx(page.grid.position.y,list_top),"collapse restores list " + id)
	view.select_category("transcendent")
	view.select_monster("transcendent","manticore")
	check(view.monster_pages.transcendent.identity.text.contains("폭발"),"localized role")
	view.preview("transcendent","plus_banner")
	check(view.preview_title.text.contains("5초월"),"five-upgrade preview")
	for viewport_size in [Vector2i(360,800),Vector2i(540,960),Vector2i(1280,720)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		check(view.preview_root.size.is_equal_approx(root.get_visible_rect().size),"artwork covers entire viewport")
		check(Rect2(Vector2.ZERO,view.preview_root.size).encloses(view.preview_exit.get_rect()),"exit always inside screen")
		check(view.preview_root.mouse_filter == Control.MOUSE_FILTER_STOP,"blocks underlying navigation")
	view.preview_exit.confirmed.emit()
	check(not view.preview_root.visible and view.preview_image.texture == null,"exit closes and releases display")
	view.preview("transcendent","illustration")
	check(view.preview_image.texture is AtlasTexture,"display trims transparent margins only")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	view.preview_root.gui_input.emit(escape)
	check(not view.preview_root.visible,"Escape returns to codex")
	view.preview("transcendent","plus_banner")
	parent.hide()
	check(not view.preview_root.visible,"parent tab hidden closes preview")
	parent.show()
	view.scroll.scroll_vertical = 400
	view.monster_pages.transcendent.cards.zeus.confirmed.emit()
	check(view.monster_pages.transcendent.selected == "zeus" and view.scroll.scroll_vertical == 0 and not view.monster_pages.transcendent.body.visible,"card selects while preserving collapsed detail")
	view.select_category("skills")
	check(not view.preview_root.visible,"category change closes preview")
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
	check(not view.root.visible and not view.title_plate.visible and not view.preview_root.visible,"navigation cleanup")
	host.free()
	check(not root.size_changed.is_connected(view._resize_preview),"viewport signal disconnected when lobby is destroyed")
	print("DEMON_CODEX: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
