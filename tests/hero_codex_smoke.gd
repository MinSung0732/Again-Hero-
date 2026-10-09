extends SceneTree
const DATA := preload("res://src/data/hero_codex_catalog.gd")
const VIEW := preload("res://src/ui/lobby_hero_codex_view.gd")
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
		check(view.hero_name.text.contains(entry.name),"identity updates")
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
	view.hide()
	check(not view.root.visible and not view.title_plate.visible,"subpage cleanup")
	host.free()
	print("HERO_CODEX: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
class CodexHost extends Control:
	var other_tab: Control = self
