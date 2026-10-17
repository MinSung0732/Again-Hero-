extends SceneTree
const DATA := preload("res://src/data/lobby_ui_policy_catalog.gd")
const CLOUD := preload("res://src/network/cloud_store.gd")
var checks := 0
var failed := false

class Lobby extends Control:
	var other_tab: Control
	var other_settings_tab_button: Button
	var other_account_tab_button: Button
	var other_settings_panel: VBoxContainer
	var other_account_panel: VBoxContainer
	var bgm_slider := HSlider.new()
	var sfx_slider := HSlider.new()
	var bgm_mute_check := CheckBox.new()
	var sfx_mute_check := CheckBox.new()
	var gameplay_settings_path := ""
	var hero_mode := false
	var practice_calls := 0
	func _is_hero_lobby_mode() -> bool: return hero_mode
	func _enter_practice_battle() -> void: practice_calls += 1
	func _sync_audio_settings_ui() -> void: pass
class Content extends RefCounted:
	var root := Control.new()
	func show() -> void: root.show()
	func hide() -> void: root.hide()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed=true; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1080,1920)
	var host := Lobby.new(); root.add_child(host)
	host.other_tab=Control.new(); host.add_child(host.other_tab)
	for node in [host.bgm_slider,host.sfx_slider,host.bgm_mute_check,host.sfx_mute_check]: host.add_child(node)
	host.gameplay_settings_path="user://lobby_policy_"+CLOUD.new_operation_id()+".cfg"
	var box := VBoxContainer.new(); host.other_tab.add_child(box)
	var title := Label.new(); title.name="Title"; box.add_child(title)
	var tabs := HBoxContainer.new(); tabs.name="Tabs"; box.add_child(tabs)
	host.other_settings_tab_button=Button.new(); host.other_settings_tab_button.text="설정"; tabs.add_child(host.other_settings_tab_button)
	host.other_account_tab_button=Button.new(); host.other_account_tab_button.text="계정"; tabs.add_child(host.other_account_tab_button)
	host.other_settings_panel=VBoxContainer.new(); box.add_child(host.other_settings_panel)
	host.other_account_panel=VBoxContainer.new(); box.add_child(host.other_account_panel)
	var view: RefCounted = load("res://tests/lobby_policy_settings_fixture.gd").new(); view.lobby=host
	host.other_settings_tab_button.pressed.connect(view.show_page.bind("sound"))
	host.other_account_tab_button.pressed.connect(view.show_page.bind("account"))
	view._bind_settings_tabs(tabs)
	var expected_tabs := ["game","sound","notice","account","misc"]
	check(tabs.get_child_count()==5,"five tabs retained")
	for index in expected_tabs.size():
		var id: String=expected_tabs[index]
		check(tabs.get_child(index)==view.buttons[id] and view.buttons[id].text==DATA.TABS[index][1],"tab order/label preserved: "+id)
	check(view.buttons.sound==host.other_settings_tab_button and view.buttons.account==host.other_account_tab_button,"original bound sound/account buttons reused")
	check(host.other_settings_tab_button.pressed.get_connections().size()==1 and host.other_account_tab_button.pressed.get_connections().size()==1,"original signal ownership preserved")
	var stack := VBoxContainer.new(); box.add_child(stack)
	for id in expected_tabs:
		var page: VBoxContainer = view._settings_page(id)
		if page.get_parent()!=null: page.reparent(stack)
		else: stack.add_child(page)
		view.pages[id]=page
	check(view.pages.sound==host.other_settings_panel and view.pages.account==host.other_account_panel,"original sound/account pages reused")
	view._build_game()
	view.scroll=ScrollContainer.new(); box.add_child(view.scroll)
	view.account_heading=MarginContainer.new(); view.pages.account.add_child(view.account_heading)
	view.account_inset=MarginContainer.new(); view.pages.account.add_child(view.account_inset)
	view._build_other_menu(box)
	view.profile_view=Content.new(); view.hero_codex_view=Content.new(); view.demon_codex_view=Content.new()
	for content in [view.profile_view,view.hero_codex_view,view.demon_codex_view]: host.other_tab.add_child(content.root)
	view.show_menu()
	var expected_menu := ["profile","demon_book","hero_book","rank_history","practice","settings"]
	check(view.other_menu_buttons.size()==6,"six current categories retained")
	var rows: Node = view.other_menu.get_node("OtherMenuScroll/Categories")
	for index in expected_menu.size():
		var id: String=expected_menu[index]; var button: Button=view.other_menu_buttons[id]
		check(rows.get_child(index)==button and button.custom_minimum_size.y==132,"menu order/touch size: "+id)
		check(button.disabled==(id=="rank_history"),"menu availability: "+id)
	check(view.other_menu_buttons.rank_history.text=="랭킹기록\n준비 중","pending ranking category remains disabled")
	check(not view.other_menu_buttons.practice.visible,"practice hidden outside allowed mode")
	var mode:=root.get_node("LocalTestMode"); mode.practice_allowed=true
	view.show_menu()
	check(view.other_menu_buttons.practice.visible and view.other_menu_buttons.practice.text=="연습전투  ›\n무한 체력 도망 더미 · 등록한 초월 기술 확인","practice gate re-evaluates on menu return")
	view.other_menu_buttons.practice.pressed.emit()
	check(host.practice_calls==1,"practice action reaches lobby exactly once")
	mode.practice_allowed=false
	for id in ["profile","hero_book","demon_book"]:
		view.other_menu_buttons[id].pressed.emit()
		var target: RefCounted=view.get(DATA.OTHER_VIEWS[id].property)
		check(target.root.visible and not view.other_menu.visible and not view.settings_root.visible and view.other_navigation.visible,"menu action shows correct content: "+id)
		for other in ["profile","hero_book","demon_book"]:
			if id!=other: check(not view.get(DATA.OTHER_VIEWS[other].property).root.visible,"other content hidden")
		check(view.other_back_button.custom_minimum_size.y==(56 if id=="demon_book" else 88),"back-button height preserved")
		view.other_back_button.pressed.emit()
		check(view.other_menu.visible and not view.other_navigation.visible and not target.root.visible,"back returns to menu")
	view.other_menu_buttons.settings.pressed.emit()
	check(view.settings_root.visible and view.selected=="game" and view.pages.game.visible,"settings action resumes current tab")
	for id in expected_tabs:
		view.buttons[id].pressed.emit()
		check(view.selected==id and view.pages[id].visible,"tab signal selects page: "+id)
		check(view.account_heading.visible==(id=="account") and view.account_inset.visible==(id=="account"),"account header policy")
		for other in expected_tabs:
			if other!=id: check(not view.pages[other].visible,"inactive tab hidden")
	view._save_game(false,"camera_view_locked"); view._sync_game()
	check(not view.game_checks.camera_view_locked.button_pressed,"demon camera preference saved")
	host.hero_mode=true; view._sync_game()
	check(view.game_checks.camera_view_locked.disabled and view.game_checks.camera_view_locked.button_pressed,"hero camera remains forced on")
	view._save_game(false,"camera_view_locked")
	var config:=ConfigFile.new(); config.load(host.gameplay_settings_path)
	check(config.get_value("gameplay","camera_view_locked",true)==false,"forced hero UI does not overwrite demon preference")
	view._save_game(false,"battle_frame_enabled"); view._sync_game()
	check(not view.game_checks.battle_frame_enabled.disabled and not view.game_checks.battle_frame_enabled.button_pressed,"independent frame option remains editable in hero mode")
	host.hero_mode=false; view._sync_game()
	check(not view.game_checks.camera_view_locked.disabled and not view.game_checks.camera_view_locked.button_pressed,"demon camera preference restored")
	check(not view._menu_action({"method":"missing_action"}).is_valid() and not view._menu_visible({"visible_if":"missing_gate"}),"missing handler/gate fails closed")
	var tray: Control=load("res://src/ui/lobby_tool_trays.gd").new(); tray.install(host,func():return true)
	check(tray._rails[&"left"].get_child_count()==3 and tray._rails[&"right"].get_child_count()==1,"tool tray counts retained")
	tray._show_more(&"left"); check(tray._overflow.title=="미션 · 이벤트","left overflow title retained")
	tray._show_more(&"right"); check(tray._overflow.title=="친구 · 커뮤니티","right overflow title retained")
	tray._activate(&"friends"); check(tray._notice.dialog_text==tray.CATALOG.EMPTY_MESSAGE,"tool fallback notice preserved")
	tray._notice.hide()
	var entries: Array=[]
	for i in 100: entries.append({"id":StringName("tool_"+str(i)),"title":"도구"+str(i),"side":&"left"})
	var allowed := [true]; var fired := [0]
	var large: Control=load("res://src/ui/lobby_tool_trays.gd").new()
	large.install(host,func():return allowed[0],entries)
	check(large._rails[&"left"].get_child_count()==3,"100 tools keep the existing direct button cap")
	large.register_action(&"tool_99",func():fired[0]+=1)
	large._activate(&"tool_99"); allowed[0]=false; large._activate(&"tool_99")
	check(fired[0]==1,"registered action and permission gate preserved")
	allowed[0]=true; large._show_more(&"left")
	check(large._overflow_grid.get_child_count()==100,"all tools available in overflow")
	var first_id: int=large._overflow_grid.get_child(0).get_instance_id()
	large._show_more(&"left")
	check(large._overflow_grid.get_child(0).get_instance_id()==first_id,"reopening same overflow reuses its controls")
	large.set_notification(&"tool_99",true)
	check(large._rails[&"left"].get_node("MoreTools/NotificationDot").visible,"overflow badge aggregation unchanged")
	host.hide()
	check(not large._overflow.visible,"hiding lobby closes overflow")
	var settings_path := host.gameplay_settings_path
	host.queue_free(); await process_frame
	DirAccess.remove_absolute(settings_path)
	print("LOBBY_UI_POLICY checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
