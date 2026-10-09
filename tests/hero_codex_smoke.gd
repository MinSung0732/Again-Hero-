extends SceneTree
const DATA := preload("res://src/data/hero_codex_catalog.gd")
const VIEW := preload("res://src/ui/lobby_hero_codex_view.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
class CodexOwner extends RefCounted:
	var lobby: Control
	func _title_plate(parent: Control, title: Label) -> PanelContainer:
		var plate := PanelContainer.new()
		parent.add_child(plate)
		plate.add_child(title)
		return plate
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HERO_CODEX: "+message)
func run() -> void:
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://codex-fixture-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var font := FontFile.new()
	if FileAccess.file_exists("res://assets/fonts/Galmuri11.ttf") and font.load_dynamic_font("res://assets/fonts/Galmuri11.ttf") == OK: ThemeDB.fallback_font = font
	var owner := CodexOwner.new()
	var host := CodexHost.new()
	root.add_child(host)
	owner.lobby = host
	var parent := VBoxContainer.new()
	parent.size = Vector2(740,1400)
	host.add_child(parent)
	var view := VIEW.new()
	view.install(owner,parent)
	view.show()
	check(view.locked_page.visible and view.hero_name.text == "?","new account has no discovered heroes")
	check(view.list_names.all(func(label): return label.text == "?"),"unknown list names hidden")
	check(view.list_portraits.all(func(image): return image.modulate.r < 0.1),"unknown dots shaded")
	check(view.pages.all(func(page): return not page.visible and page.text.is_empty()),"locked details contain no information")
	check(view.tabs.all(func(tab): return tab.disabled),"locked tabs disabled")
	view.select_tab(4)
	check(not view.resource_page.visible,"locked resource tab cannot reveal portraits")
	check(view.locked_page.get_child(0).texture != null,"closed lock asset loads")
	var config := ConfigFile.new()
	config.set_value("progress","highest_unlocked_stage",10)
	SCOPE.save_config(config,PROGRESS.SAVE_PATH)
	view.show()
	check(view.encountered_stages.is_empty(),"unlocking stages is not encountering heroes")
	PROGRESS.record_hero_encounter("stage_5","returning_magic_hero")
	view.show()
	view.select_stage("stage_5")
	check(view.reveal_active and view.unlock_page.visible,"first encounter starts lock opening")
	check(not view.encountered_stages.has("stage_10"),"shared identity does not reveal unseen later stage")
	view.hide()
	await create_timer(1.1).timeout
	check(not PROGRESS.get_hero_codex_state().revealed.has("stage_5"),"cancelled reveal is not acknowledged")
	view.show()
	view.select_stage("stage_5")
	await create_timer(1.1).timeout
	check(not view.reveal_active and view.pages[0].visible,"unlock animation restores information")
	check(PROGRESS.get_hero_codex_state().revealed.has("stage_5"),"completed animation remembered")
	view.hide()
	view.show()
	check(not view.reveal_active,"completed unlock not replayed")
	SCOPE.load_config(config,PROGRESS.SAVE_PATH)
	config.set_value("cleared","stage_3",true)
	SCOPE.save_config(config,PROGRESS.SAVE_PATH)
	check(PROGRESS.get_hero_codex_state().encountered.has("stage_3"),"legacy clear proves encounter")
	for id in DATA.STAGES.ORDER:
		config.set_value("hero_stage_encounters",id,1)
		config.set_value("hero_codex_revealed",id,true)
	SCOPE.save_config(config,PROGRESS.SAVE_PATH)
	view.show()
	check(view.list_scroll.visible and view.detail_root.visible,"opens to side-by-side hero list and details")
	check(view.selectors.size() == 10 and view.list_portraits.size() == 10,"portrait rows for all heroes")
	check(view.stage_ids.size() == DATA.STAGES.ORDER.size(),"all ordered stages registered")
	check(view.stage_ids.size() == 10,"current ten heroes")
	for id in view.stage_ids:
		var stage := DATA.STAGES.get_stage(id)
		var profile := DATA.HEROES.get_profile(stage.hero_id)
		var original := profile.duplicate(true)
		var entry := DATA.get_entry(id)
		check(not entry.is_empty() and entry.pages.size() == 4,"four readable sections "+id)
		check(profile == original and profile == DATA.HEROES.get_profile(stage.hero_id),"read-only source "+id)
		var skills: Array = []
		DATA.collect_skills(profile,skills)
		for skill in skills:
			check(DATA.SKILLS.describe(skill) != "용사가 전투 상황과 사용 조건에 맞춰 자동으로 사용하는 기술입니다.","concrete skill description "+String(skill.name))
			check(entry.pages[1].contains(skill.name),"named skill included "+String(skill.name))
		for augment_id in profile.augment_pool_ids:
			check(entry.pages[2].contains(DATA.AUGMENTS.get_augment(augment_id).get("name","MISSING")),"actual augment pool "+String(augment_id))
		view.select_stage(id)
		for index in range(4):
			view.select_tab(index)
			check(view.pages[index].visible,"selected page visible")
			check(view.pages.filter(func(page): return page.visible).size() == 1,"one page visible")
		check(view.hero_name.text == entry.name,"identity has no stage label")
		check(view.list_scroll.visible and view.detail_root.visible,"selection preserves left list")
		view.select_tab(4)
		check(view.resource_page.visible and view.pages.all(func(page): return not page.visible),"resource preview replaces text page")
		check(DATA.resource_paths(id).size() == 4,"all resource references")
	check(DATA.get_entry("missing").is_empty(),"unknown stage has no fabricated data")
	check(DATA.get_entry("stage_1").pages[0].contains("체력  375"),"stage-balanced starting HP")
	check(DATA.get_entry("stage_1").pages[0].contains("공격력  37"),"rounded stage-balanced attack")
	check(DATA.parameters({"slow_multiplier":0.8}).contains("×0.8"),"speed multiplier not mistaken for slow percent")
	var node_count := view.root.get_child_count()
	for i in range(15):
		view.hide()
		view.show()
		view.select_stage("stage_1")
	check(view.root.get_child_count() == node_count and view.cached_entries.size() == 10,"reopen reuses controls and cached entries")
	view.select_stage("stage_1")
	for width in [540,740,900]:
		parent.size.x = width
		await process_frame
		check(view.root.get_combined_minimum_size().x <= width,"no horizontal overflow at width %d" % width)
		check(view.portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"portrait contain")
	view.select_tab(0)
	var button = view.tabs[1]
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(10,10)
	button._gui_input(press)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = button.get_global_transform_with_canvas()*press.position
	button._input(release)
	check(view.selected_tab == 1,"mobile completed tap opens section")
	view.select_tab(0)
	button._gui_input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = release.position+Vector2(0,60)
	button._input(drag)
	button._input(release)
	check(view.selected_tab == 0,"drag does not select section")
	SCOPE.guest_directory += "-other-account"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	view.show()
	check(view.locked_page.visible and view.list_names.all(func(label): return label.text == "?"),"account change refreshes cached names and lock")
	check(view.portrait.texture == null and view.resource_images.all(func(image): return image.texture == null),"account change hides old portrait and resources")
	check(view.pages.all(func(page): return page.text.is_empty()),"account change clears previous details")
	SCOPE.user_id = "11111111-1111-4111-8111-111111111111"
	SCOPE.files = {"stage_progress.cfg": {"hero_stage_encounters": {"stage_2": 1}}}
	view.show()
	view.select_stage("stage_2")
	check(view.reveal_active,"signed-in account encounters loaded")
	SCOPE.user_id = "22222222-2222-4222-8222-222222222222"
	SCOPE.files = {}
	await create_timer(1.1).timeout
	check(SCOPE.files.is_empty() and not view.root.visible,"account switch during reveal cannot write another account")
	SCOPE.select_guest()
	view.hide()
	check(not view.root.visible and not view.title_plate.visible,"subpage cleanup")
	host.free()
	print("HERO_CODEX: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
class CodexHost extends Control:
	var other_tab: Control = self
