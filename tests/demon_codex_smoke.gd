extends SceneTree
const VIEW := preload("res://src/ui/lobby_demon_codex_view.gd")
const DATA := preload("res://src/data/demon_codex_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SKILL_ART := preload("res://src/data/skill_icon_catalog.gd")
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
func frames() -> void:
	await process_frame
	await process_frame
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
	parent.size = Vector2(740,700)
	host.add_child(parent)
	var view := VIEW.new()
	view.install(owner,parent)
	var before := COLLECTION.load_state().duplicate(true)
	view.show()
	check(view.pages.size() == 1,"lazy initial page")
	for category in DATA.CATEGORIES: view.select_category(category[0])
	check(view.pages.size() == 4,"four categories")
	check(DATA.monster_ids(false).size() == 21 and DATA.monster_ids(true).size() == 4,"actual catalog counts")
	for total in [0,1,16,17,200,300]:
		var ids: Array = []
		for i in range(total): ids.append("fixture_%d" % i)
		var gathered: Array = []
		for index in range(DATA.page_count(total)):
			var chunk := DATA.page_ids(ids,index)
			check(chunk.size() <= 16,"bounded page size")
			gathered.append_array(chunk)
		check(gathered == ids,"all entries exactly once %d" % total)
		if total > 0: check(DATA.page_ids(ids,999) == DATA.page_ids(ids,DATA.page_count(total)-1),"clamps last page")
	for category in ["monsters","transcendent"]:
		view.select_category(category)
		var page: Dictionary = view.monster_pages[category]
		check(page.slots.size() == 16 and page.grid.get_child_count() == 16,"sixteen reusable card controls")
		check(page.cards.size() == mini(16,page.ids.size()),"first page populated")
		check(not view.detail_root.visible,"no eager details")
		for id in page.ids:
			view._select_card(category,id)
			check(view.detail_root.visible,"opens modal " + id)
			check(page.name.text == DATA.MONSTERS.get_monster_name(id),"real name " + id)
			for panel in page.body.find_children("*","PanelContainer",true,false):
				if panel.has_meta("icon_key") and SKILL_ART.PATHS.has(String(panel.get_meta("icon_key"))):
					check(panel.find_children("*","TextureRect",true,false).any(func(icon): return icon.texture != null),"actual codex skill art " + id)
			check(page.portrait.texture != null,"dot loaded " + id)
			check(page.stat_values.map(func(label): return label.text) == DATA.stat_values(id),"structured stats " + id)
			if category == "monsters":
				var groups := DATA.related_augment_groups(id)
				var detail: Control = page.detail_cache[id]
				check(detail.get_node("NormalAugments").get_meta("augment_ids") == groups.normal.map(func(entry): return String(entry.id)),"normal augment IDs " + id)
				check(detail.get_node("SpecialAugments").get_meta("augment_ids") == groups.special.map(func(entry): return String(entry.id)),"special augment IDs " + id)
				for label in detail.find_children("*","Label",true,false):
					if label.text.begins_with("최대 ") and label.text.ends_with("레벨"): check(label.autowrap_mode == TextServer.AUTOWRAP_OFF,"max level cannot wrap vertically")
				check(page.detail_cache.size() <= VIEW.DETAIL_CACHE_LIMIT and page.extra.get_child_count() <= VIEW.DETAIL_CACHE_LIMIT,"bounded attached detail cache")
			else:
				for kind in ["illustration","banner"]:
					view.preview(category,kind)
					check(view.preview_root.visible and view.preview_image.texture != null,"art preview " + id + kind)
					view.close_preview()
					check(view.detail_root.visible,"art returns to details")
				check(page.art_buttons.plus_banner.disabled == (id not in ["zeus","manticore"]),"only registered five-upgrade banners")
			view.close_detail()
		page.search.text = "does-not-exist"
		page.search.text_changed.emit(page.search.text)
		check(page.cards.is_empty() and page.slots.all(func(slot): return not slot.button.visible),"empty search")
		page.search.text = ""
		page.search.text_changed.emit(page.search.text)
		for width in [360,540,740,1000]:
			parent.size.x = width
			view._select_card(category,page.ids[0])
			await frames()
			view.close_detail()
			check(view.root.get_combined_minimum_size().x <= width,"no overflow %s %d" % [category,width])
			check(page.grid.columns == (4 if width >= 640 else (3 if width >= 460 else 2)),"responsive grid")
			for slot in page.slots:
				if slot.button.visible: check(is_equal_approx(slot.button.size.y,VIEW.CARD_HEIGHT),"fixed card height")
	view.select_category("monsters")
	var ordinary: Dictionary = view.monster_pages.monsters
	parent.size = Vector2(740,700)
	view.set_page("monsters",1)
	await frames()
	check(ordinary.cards.size() == 5 and ordinary.previous.disabled == false and ordinary.next.disabled,"last page has five real entries")
	view.set_page("monsters",0)
	await frames()
	view.scroll.scroll_vertical = 70
	await frames()
	var offset: int = view.scroll.scroll_vertical
	check(offset > 0,"fixture has scrollable list")
	var grid_top: float = ordinary.grid.global_position.y
	view._select_slot("monsters",0)
	view.detail_scroll.scroll_vertical = 90
	view.close_detail()
	check(ordinary.page_index == 0 and ordinary.search.text.is_empty() and view.scroll.scroll_vertical == offset,"modal preserves list state")
	check(is_equal_approx(ordinary.grid.global_position.y,grid_top),"modal cannot shift list")
	view.select_category("skills")
	view.select_category("monsters")
	await frames()
	check(view.scroll.scroll_vertical == offset,"category return restores list position")
	view.set_page("monsters",1)
	view._select_slot("monsters",0)
	view.detail_close.confirmed.emit()
	check(ordinary.page_index == 1 and ordinary.cards.size() == 5 and not view.detail_root.visible,"close retains second page")
	ordinary.search.text = DATA.MONSTERS.get_monster_name("slime")
	ordinary.search.text_changed.emit(ordinary.search.text)
	check(ordinary.page_index == 0 and ordinary.cards.has("slime"),"search resets page and shows matching entry")
	ordinary.search.text = ""
	ordinary.search.text_changed.emit(ordinary.search.text)
	view._select_card("monsters","slime")
	var cached: Control = ordinary.detail_cache.slime
	view.close_detail()
	view._select_card("monsters","slime")
	check(ordinary.detail_cache.slime == cached,"cached detail reused")
	view.select_category("transcendent")
	view._select_card("transcendent","manticore")
	check(view.monster_pages.transcendent.identity.text.contains("폭발"),"localized role")
	view.preview("transcendent","plus_banner")
	for viewport_size in [Vector2i(360,800),Vector2i(540,960),Vector2i(1280,720)]:
		root.size = viewport_size
		await frames()
		check(view.preview_root.size.is_equal_approx(root.get_visible_rect().size),"full screen artwork")
		check(view.detail_root.size.is_equal_approx(root.get_visible_rect().size),"modal overlay fills viewport")
		check(view.detail_root.get_global_rect().encloses(view.detail_close.get_global_rect()),"modal close inside screen")
		check(view.detail_root.get_global_rect().encloses(view.detail_panel.get_global_rect()),"detail panel fits screen")
		var frame: PanelContainer = view.monster_pages.transcendent.detail_frame
		var column: Control = frame.get_child(0)
		check(column.global_position.x-frame.global_position.x >= 40 and frame.get_global_rect().end.x-column.get_global_rect().end.x >= 40,"detail text inset from both borders")
		check(view.preview_root.get_global_rect().encloses(view.preview_exit.get_global_rect()),"art exit inside screen")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	view.preview_root.gui_input.emit(escape)
	check(not view.preview_root.visible and view.detail_root.visible,"Escape returns to modal")
	view.detail_root.gui_input.emit(escape)
	check(not view.detail_root.visible,"Escape closes modal")
	view._select_card("transcendent","manticore")
	view.preview("transcendent","illustration")
	check(view.preview_image.texture is AtlasTexture,"trimmed display only")
	parent.hide()
	check(not view.preview_root.visible and not view.detail_root.visible,"ancestor hide clears both overlays")
	parent.show()
	check(COLLECTION.load_state() == before,"collection remains read-only")
	view.hide()
	host.free()
	check(not root.size_changed.is_connected(view._resize_preview),"viewport signal cleanup")
	print("DEMON_CODEX: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
