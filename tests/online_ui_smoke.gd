extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const RULES := preload("res://src/online/match_rules.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const CAMERA_VIEW := preload("res://src/ui/battle_camera_view.gd")
class CommandSpy:
	extends RefCounted
	var reconnecting := false
	var kind := ""
	var argument := {}
	func command(value: String,data: Dictionary) -> bool:
		kind = value; argument = data; return true
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for path in ["res://src/main/main.gd","res://src/hero_mode/hero_mode.gd","res://src/online/match_scene.gd","res://src/online/battle_view.gd","res://src/ui/battle_camera_view.gd","res://src/online/primitive_mirror.gd","res://src/online/combat_feedback.gd","res://src/ui/hero_pause_view.gd","res://src/ui/hero_survival_hud.gd","res://src/ui/hero_battle_frame.gd","res://src/ui/hero_pad_settings.gd","res://src/ui/demon_action_choices.gd","res://src/online/battle_room.gd","res://src/online/match_server.gd","res://src/online/match_rules.gd","res://src/ui/augment_hold_popup.gd","res://src/ui/demon_augment_panel_view.gd","res://src/ui/hero_augment_cards_view.gd","res://src/ui/castle_battle_chrome.gd"]:
		var script: Script = load(path)
		check(script != null and script.can_instantiate(),"modified script loads: "+path)
	var solo_packed: PackedScene = load("res://src/main/Main.tscn")
	check(solo_packed != null and solo_packed.can_instantiate(),"solo scene loads")
	var pause_packed: PackedScene = load("res://src/ui/BattlePauseMenu.tscn")
	check(pause_packed != null and pause_packed.can_instantiate(),"shared solo pause scene loads")
	var solo := solo_packed.instantiate()
	check(solo.get_node_or_null("HUD/BottomBar/CommandBar") != null and solo.get_node_or_null("HUD/DemonUltimatePanel/UltimateButtons") != null,"solo paths survive shared scene extraction")
	check(solo.get_node_or_null("HUD/MutationPanel/Margin/VBox/Choices/Choice2") != null,"solo mutation path survives extraction")
	check(solo.get_node_or_null("HUD/DemonAugmentPanel/Margin/VBox/Title") != null,"solo demon augment path survives extraction")
	check(Vector2(solo.get_node("BattleViewportContainer/BattleViewport").size) == CAMERA_VIEW.DEMON_SIZE,"demon camera size follows solo viewport")
	solo.free()
	var hero_packed: PackedScene = load("res://src/hero_mode/HeroMode.tscn")
	check(hero_packed != null and hero_packed.can_instantiate(),"hero mode scene loads")
	var hero_scene := hero_packed.instantiate(); hero_scene.free()
	var online_packed: PackedScene = load("res://src/online/OnlineMatch.tscn")
	check(online_packed != null and online_packed.can_instantiate(),"online scene loads")
	var online := online_packed.instantiate()
	check(online.get_node_or_null("BottomBar/CommandBar") != null and online.get_node_or_null("DemonUltimatePanel/UltimateButtons") != null,"online shared lower scenes instantiate")
	online.free()
	var local = root.get_node("LocalTestMode")
	var old_active: bool = local.active
	var old_preview: bool = local.tutorial_preview
	var old_owner: String = SCOPE.user_id
	var old_directory: String = SCOPE.guest_directory
	local.active = false; local.tutorial_preview = false; SCOPE.user_id = ""; SCOPE.guest_directory = "user://"
	root.size = Vector2i(1080,1920)
	for role in ["hero","demon"]:
		root.size = Vector2i(1080,1920)
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var packed: PackedScene = load("res://src/online/OnlineMatch.tscn")
		check(packed != null,"scene compiles with autoloads")
		var scene = packed.instantiate(); root.add_child(scene)
		await process_frame; await process_frame
		check(scene.role == role,"requested role")
		scene.match_menu.show()
		await process_frame; await process_frame
		var resume: Button = scene.match_menu.find_child("ResumeButton" if role == "demon" else "Pause_resume",true,false)
		var rules_button: Button = scene.match_menu.find_child("RulesButton" if role == "demon" else "Pause_rules",true,false)
		var surrender: Button = scene.match_menu.find_child("SurrenderButton" if role == "demon" else "Pause_surrender",true,false)
		check(resume != null and rules_button != null and surrender != null,"menu buttons exist")
		for button in [rules_button,surrender]:
			check(button.get_theme_stylebox("normal") == resume.get_theme_stylebox("normal"),"menu button skin matches")
			check(button.get_theme_font_size("font_size") == resume.get_theme_font_size("font_size"),"menu font matches")
		check(surrender.get_global_rect().end.y <= root.size.y,"surrender fits viewport")
		if role == "hero":
			var scroll: ScrollContainer = scene.match_menu.find_child("PauseScroll",true,false)
			check(not scroll.get_v_scroll_bar().visible,"hero menu does not scroll")
		surrender.pressed.emit(); check(scene.surrender_dialog.visible,"surrender opens confirmation"); scene.surrender_dialog.hide()
		scene.match_menu.hide()

		check(scene.queue_button.custom_minimum_size.y >= 72,"mobile button size")
		check(not scene.cancel_button.visible and not scene.action_notice.visible,"setup does not show battle instructions or matching cancel")
		check(scene.view.size.x > 500 and scene.view.size.y > 300,"battle panel expands")
		check(scene.hold_popup.dots.size() == RULES.AUGMENT_HOLD_LIMIT and not scene.hold_popup.popup.visible,"pooled hold dots start closed")
		check(scene.hold_popup.lower_button.text == "내리기" and scene.hold_popup.reroll_button != null,"online hold controls present")
		if role == "demon":
			check(scene.hold_popup.popup.scene_file_path == "res://src/ui/demon_augment_panel.tscn" and scene.hold_popup.confirm_button != null,"demon uses shared augment scene")
			check(scene.hold_popup.lower_button.get_parent() == scene.hold_popup.popup_rows.get_node("Actions"),"lower button stays inside shared panel actions")
		else:
			check(scene.hold_popup.popup_rows.get_node_or_null("HorizontalAugmentCards") != null,"hero uses shared horizontal card builder")
		var holds: Array = []
		for number in 3:
			holds.append({"number":number+1,"candidates":[{"id":"survival_power","name":"생존력","description":"체력 증가"}]})
		scene._update_holds(holds); await process_frame
		check(scene.hold_popup.dots.filter(func(dot): return dot.visible).size() == 3 and not scene.hold_popup.popup.visible,"three holds add three dots without opening")
		check(scene.hold_popup.dot_glows.size() == RULES.AUGMENT_HOLD_LIMIT and scene.hold_popup.dot_glow_tweens[2] != null and scene.hold_popup.dot_glow_tweens[2].is_valid(),"newest held slot glows once")
		await create_timer(scene.hold_popup.NEW_HOLD_GLOW_IN+scene.hold_popup.NEW_HOLD_GLOW_OUT+0.1).timeout
		check(scene.hold_popup.dot_glows[2].modulate.a <= 0.01 and scene.hold_popup.dot_glows[2].mouse_filter == Control.MOUSE_FILTER_IGNORE,"glow fades out and never blocks taps")
		scene.hold_popup.dots[1].pressed.emit(); await process_frame
		check(scene.hold_popup.popup.visible and scene.hold_popup.opened_number == 2 and scene.hold_popup.card_names[0].text == "생존력","dot opens its own candidate popup")
		check(scene.hold_popup.title_label.text.contains("보관 2번"),"opened offer displays its held number")
		if role == "hero":
			check(scene.hold_popup.cards[0].get_node_or_null("MarginContainer/VBoxContainer/AugmentIcon") != null and scene.hold_popup.cards[0].get_node_or_null("MarginContainer/VBoxContainer/Name") != null,"hero offer uses shared card structure")
		else:
			check(scene.hold_popup.cards[0].get_node_or_null("Level") != null and scene.hold_popup.popup_rows.get_node("Title").text == "마왕의 개입","demon offer uses solo card and title")
			for viewport_size in [Vector2i(1080,1920),Vector2i(1536,1920)]:
				root.size = viewport_size
				preload("res://src/ui/demon_augment_panel_view.gd").populate(scene.hold_popup.popup,[{"augment_type":"special","monster_id":"slime","name":"special","description":"effect"}],1,0,0)
				await process_frame; await process_frame
				var card: Button = scene.hold_popup.cards[0]
				check(not card.get_node("Level").get_global_rect().intersects(card.get_node("AugmentDetails").get_global_rect()),"special tag avoids details at " + str(viewport_size))
			root.size = Vector2i(1080,1920)
			var long_candidate := {"id":"survival_power","name":"룬방패수호병 최대 체력 증가","description":"최대 체력이 증가합니다"}
			preload("res://src/ui/demon_augment_panel_view.gd").populate(scene.hold_popup.popup,[long_candidate],1,0,0)
			var name_label: Label = scene.hold_popup.cards[0].get_node("Name")
			var description: Label = scene.hold_popup.cards[0].get_node("Description")
			check(name_label.text.contains("\n") and name_label.get_theme_font("font").get_height(name_label.get_theme_font_size("font_size")) * 2 <= name_label.size.y and name_label.get_global_rect().end.y <= description.get_global_rect().position.y,"two-line demon name fits before description")
		scene.hold_popup.lower_button.pressed.emit()
		check(not scene.hold_popup.popup.visible and scene.hold_popup.dots[1].visible,"lower closes popup and keeps dot")
		if role == "hero": check(scene.elite_panel == null and scene.elite_buttons.is_empty(),"hero has no elite UI")
		else:
			var saved_client = scene.client
			var elite_spy := CommandSpy.new(); scene.client = elite_spy
			var saved_wait: bool = scene.waiting_for_start; scene.waiting_for_start = false
			scene._update_elite_ui(["slime","spider","orc"],[[1,"slime"],[2,"spider"]])
			check(scene.elite_panel.visible and scene.elite_panel.get_node("Margin/VBox/Choices").get_child_count() == 3,"elite choices shown")
			scene.elite_panel.get_node("Margin/VBox/Choices/Choice0").pressed.emit()
			check(elite_spy.kind == "elite_choose" and elite_spy.argument == {"id":"slime"},"elite choice command")
			scene._update_elite_ui([],[[1,"slime"],[2,"spider"]])
			check(not scene.elite_panel.visible and scene.elite_buttons[0].visible and scene.elite_buttons[1].visible and not scene.elite_buttons[2].visible,"elite cards reflect snapshot")
			scene.elite_buttons[1].pressed.emit()
			scene.view._layout_map()
			var tap := InputEventMouseButton.new(); tap.button_index = MOUSE_BUTTON_LEFT; tap.pressed = true; tap.position = scene.view.size * 0.5
			var world: Vector2 = (tap.position - scene.view.map_offset) / scene.view.map_scale
			scene.view._gui_input(tap)
			check(elite_spy.kind == "elite_summon" and elite_spy.argument == {"serial":2,"x":world.x,"y":world.y},"elite placement sends camera transformed world coordinates")
			scene._update_elite_ui([],[]); scene.client = saved_client; scene.waiting_for_start = saved_wait
		var real_client = scene.client
		var command_spy := CommandSpy.new(); scene.client = command_spy
		scene.hold_popup.open_index(1); scene.hold_popup.cards[0].pressed.emit()
		if role == "demon":
			check(command_spy.kind.is_empty() and not scene.hold_popup.confirm_button.disabled,"demon card selection awaits apply")
			scene.hold_popup.confirm_button.pressed.emit()
		check(command_spy.kind == ("choose" if role == "hero" else "demon_choose") and command_spy.argument == {"id":"survival_power","number":2},"candidate sends role command with held number")
		if role == "hero":
			scene.rerolls_left = 1; scene.reroll_limit = 2; scene._update_holds(holds)
			scene.hold_popup.open_index(0); scene.hold_popup.reroll_button.pressed.emit()
			check(command_spy.kind == "reroll" and command_spy.argument == {"number":1},"hero refresh sends existing reroll command")
			scene.hold_popup.close_popup()
		scene.client = real_client
		var dot_count: int = scene.hold_popup.dot_row.get_child_count()
		scene._update_holds(holds.duplicate(true))
		check(scene.hold_popup.dot_row.get_child_count() == dot_count,"same holds keep pooled node count")
		scene._update_holds(holds + [{"number":4,"candidates":holds[0].candidates}])
		scene._update_holds([holds[1],holds[2],{"number":4,"candidates":holds[0].candidates},{"number":5,"candidates":holds[0].candidates}])
		check(scene.hold_popup.dots.filter(func(dot): return dot.visible).size() <= RULES.AUGMENT_HOLD_LIMIT and scene.status.text.contains("자동 선택됨"),"server overflow removes oldest dot and shows toast")
		if role == "hero":
			check(scene.pad.mode == "free" and scene.pad.input_surface == scene.view,"touch binds battle only")
			check(scene.pad_mode_selector != null and scene.pad_mode_selector.get_parent().name == "PadModeRow","hero settings reuse solo pad-mode row")
			check(scene.hold_popup.popup in scene.pad.input_exclusions and scene.hold_popup.dot_row in scene.pad.input_exclusions,"augment popup and dots are excluded from the move pad")
			scene.view.set_match_roster([],"")
			check(scene.view.reveal_on_sight and scene.view._admit_sighted_actor("slime") and not scene.view._admit_sighted_actor("not_a_monster"),"hero without demon roster admits only real monsters on sight")
		else:
			# Since protocol 9 the demon's summon buttons come from the server's
			# validated loadout on "matched", not a fixed roster.
			check(scene.summon_buttons.is_empty(),"no roster before matching")
			scene._event({"op":"matched","map":"plaza","duration":600,"battlefield":{"stage":"stage_1","bounds":[3200,3200],"map":"plaza"},"roster":["slime","orc","spider","bomb_rat","skeleton_archer"],"skill_ids":["line_assault"]})
			await process_frame
			check(scene.summon_buttons.size() == 5 and scene.selected_monster == "slime","matched loadout builds solo summon cards")
			check(scene.summon_buttons[0].get_node("Icon").texture != null and scene.summon_buttons[0].get_node("Cost").text != "","catalog icon and cost on summon cards")
			scene.local_preparing = false; scene.waiting_for_start = false
			scene._update_demon_controls({"mana":0.0,"summon_costs":{"slime":9.0,"orc":12.0,"spider":8.0,"bomb_rat":9.0,"skeleton_archer":12.0},"demon_charge":0.0,"demon_charge_max":100.0,"demon_cooldowns":{"line_assault":5.0},"demon_ready":{"line_assault":false},"transcend_ready":false,"transcend_used":false})
			check(scene.summon_buttons.all(func(button): return button.disabled) and scene.skill_buttons.line_assault.disabled,"cost and cooldown disable buttons")
			scene._update_demon_controls({"mana":100.0,"summon_costs":{"slime":9.0,"orc":12.0,"spider":8.0,"bomb_rat":9.0,"skeleton_archer":12.0},"demon_charge":100.0,"demon_charge_max":100.0,"demon_cooldowns":{"line_assault":0.0},"demon_ready":{"line_assault":true},"transcend_ready":true,"transcend_used":false})
			check(not scene.summon_buttons[0].disabled and not scene.skill_buttons.line_assault.disabled,"ready cards and skill enable")
			scene._update_demon_controls({"mana":100.0,"summon_costs":{"slime":200.0,"orc":12.0,"spider":8.0,"bomb_rat":9.0,"skeleton_archer":12.0},"demon_charge":100.0,"demon_charge_max":100.0,"demon_cooldowns":{"line_assault":0.0},"demon_ready":{"line_assault":true},"transcend_ready":true,"transcend_used":false})
			check(scene.summon_buttons[0].disabled and scene.summon_buttons[0].get_node("Cost").text == "200.0","server adjusted cost overrides catalog base")
		scene._join()
		check(scene.client.socket == null,"guest without token never queues")
		check(scene.test_code == null,"ordinary account screen has no test invitation field")
		check(scene.disconnect_button == null and scene.reconnect_button == null,"ordinary screen has no connection test buttons")
		check(scene.metrics_panel == null and scene.match_menu.find_child("ConnectionMetricsButton",true,false) == null,"ordinary accounts have no metrics overlay or menu action")
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		check(scene.view.size.x > 1200,"tablet width expands")
		if role == "hero":
			scene._receive_chests([{"serial":1,"name":"시험 보상","description":"복귀 보존"}])
			scene._advance_chest_notice(0.01)
			check(scene.chest_notice.visible and scene.chest_notice.text.contains("시험 보상"),"received chest is shown during battle")
			scene.connection_waiting = true
			var chest_remaining: float = scene.chest_seconds
			scene._advance_chest_notice(10.0)
			check(scene.chest_notice.visible and scene.chest_seconds == chest_remaining,"reconnect grace preserves unread chest notice time")
			scene.connection_waiting = false
			scene._receive_chests([{"serial":1,"name":"시험 보상"}])
			check(scene.chest_queue.is_empty(),"replayed receipt after recovery never duplicates chest")
		scene.client.match_id = "ui-recovery"
		scene._event({"op":"connection","match":"ui-recovery","paused":true,"remaining":15.0})
		scene._process(0.01)
		check(scene.connection_waiting and scene.status.text.contains("일시정지"),"server grace countdown displayed")
		scene.hold_popup.open_index(0)
		check(scene.hold_popup.cards[0].disabled and scene.hold_popup.reroll_button.disabled,"grace disables augment actions")
		scene.hold_popup.close_popup()
		if role == "hero": check(not scene.pad.enabled,"grace disables touch movement")
		else:
			for button in scene.summon_buttons: check(button.disabled,"grace disables summon buttons")
		scene._event({"op":"connection","match":"ui-recovery","paused":false,"remaining":0.0})
		check(not scene.connection_waiting,"server resume clears pause")
		scene.client.reconnecting = true; scene.client.connection_recovering.emit(true,20.0)
		check(not scene.ended and scene.status.text.contains("연결 복구"),"local transport loss keeps scene alive")
		scene.client.reconnecting = false; scene.client.connection_recovering.emit(false,0.0)
		scene.last_tick = 99
		scene._event({"op":"matched","match":"ui-recovery","resumed":true,"map":"plaza","duration":600,"battlefield":{"stage":"stage_1","bounds":[3200,3200],"map":"plaza"}})
		check(scene.last_tick == -1,"resume forces snapshot refresh even at same tick")
		scene._event({"op":"result","match":"ui-recovery","winner":role})
		var result_text: String = scene.status.text
		scene._event({"op":"result","match":"ui-recovery","winner":""})
		check(scene.ended and scene.status.text == result_text,"terminal UI is idempotent")
		if role == "hero": check(not scene.chest_notice.visible and scene.chest_queue.is_empty(),"result clears chest notice before end presentation")
		scene._event({"op":"matched","hero":"ranged_rookie","map":"plaza","duration":600,"battlefield":{"stage":"stage_1","bounds":[3200,3200],"map":"plaza"}})
		await process_frame
		scene.battle_frame_enabled = true; scene._apply_match_frame(); await process_frame
		check(scene.top_bar.visible and scene.top_bar.get_node_or_null("RunTimer") != null and scene.top_bar.get_node_or_null("HeroHPBar") != null and scene.top_bar.get_node_or_null("Monsters") != null,"both roles share battle top bar")
		var frame: Control = scene.get_node("HeroBattleFrame" if role == "hero" else "CastleBattleChrome")
		check(frame.visible and frame.z_index == -10 and frame.anchor_right == 1.0 and frame.anchor_bottom == 1.0 and frame.size == scene.size and scene.view.z_index > frame.z_index,"role frame stays behind battlefield")
		check(scene.get_node_or_null("CastleBattleChrome") == null if role == "hero" else scene.get_node_or_null("HeroBattleFrame") == null,"only the role's frame exists")
		check(scene.view.clip_contents,"battle clips sprites, effects and feedback")
		check(is_equal_approx(scene.view.get_global_rect().position.y,470.0 if role == "hero" else 420.0),"battle starts at solo role frame top")
		check(is_equal_approx(scene.view.get_global_rect().position.x,90.0 if role == "hero" else 120.0),"battle uses solo role side inset")
		if role == "hero":
			check(is_equal_approx(scene.view.get_global_rect().position.y,scene.demon_info_panel.get_global_rect().end.y) and scene.get_node_or_null("CastleBattleChrome") == null,"no castle gray layer or gap below demon info")
		else:
			var dot_style := scene.hold_popup.dots[0].get_theme_stylebox("normal") as StyleBoxTexture
			check(dot_style != null and dot_style.texture != null,"held slots use authored gold badge texture")
		scene.battle_frame_enabled = false; scene._apply_match_frame(); await process_frame
		check(not frame.visible and is_equal_approx(scene.view.get_global_rect().position.x,0.0) and is_equal_approx(scene.view.get_global_rect().position.y,470.0 if role == "hero" else 350.0),"frame off expands to solo role area")
		var top_backing: Control = scene.get_node("BattleTopBacking")
		var lower_backing: Control = scene.get_node("BattleLowerBacking")
		check(top_backing.visible and top_backing.z_index < frame.z_index and top_backing.get_global_rect().position == Vector2.ZERO and top_backing.get_global_rect().end.x >= root.size.x and top_backing.get_global_rect().end.y >= scene.top_bar.get_global_rect().end.y,"frame off keeps top HUD background across header")
		check(lower_backing.visible and lower_backing.get_global_rect().end.x >= root.size.x and lower_backing.get_global_rect().end.y >= root.size.y,"frame off keeps lower HUD background")
		scene.battle_frame_enabled = true; scene._apply_match_frame(); await process_frame
		check(frame.visible and top_backing.visible and lower_backing.visible and is_equal_approx(scene.view.get_global_rect().position.x,90.0 if role == "hero" else 120.0),"frame on restores original inset with both backdrops")
		check(not scene.status.visible and not scene.action_notice.visible and not scene.cancel_button.visible,"battle hides debug rows and matching cancel")
		check(lower_backing != null and lower_backing.visible and ((frame.floor_backing != null and (lower_backing as TextureRect).texture != null) if role == "demon" else (lower_backing as ColorRect).color == preload("res://src/ui/hero_survival_hud.gd").BACKGROUND_COLOR),"solo role lower HUD backing covers both roles")
		scene.top_bar.get_node("StageMenuButton").pressed.emit(); await process_frame
		check(scene.match_menu.visible and not paused and scene.settings_panel.scene_file_path == "res://src/ui/BattleSettings.tscn","menu opens shared solo settings without pausing battle")
		if role == "demon":
			check(scene.match_menu.get_node_or_null("MenuPanel/Margin/VBox/RulesButton") != null and scene.match_menu.get_node_or_null("MenuPanel/Margin/VBox/SurrenderButton") != null and not scene.match_menu.get_node("MenuPanel/Margin/VBox/RestartButton").visible and not scene.match_menu.get_node("MenuPanel/Margin/VBox/LobbyButton").visible,"demon menu shares solo pause panel with online actions")
		else:
			check(scene.match_menu.find_child("Pause_rules",true,false) != null and scene.match_menu.find_child("Pause_surrender",true,false) != null and scene.match_menu.find_child("Pause_restart",true,false) == null,"hero menu shares solo pause builder with online actions")
		scene._open_match_settings(); await process_frame
		check(scene.settings_panel.visible and not paused,"settings keeps combat running")
		scene._close_match_settings(); scene._confirm_surrender(); await process_frame
		check(scene.surrender_dialog.visible,"surrender menu opens confirmation")
		scene.surrender_dialog.hide()
		scene._close_match_menu()
		scene.status.text = "짧은 알림"
		scene._process(0.1)
		check(scene.battle_toast.visible and scene.battle_toast.text == "짧은 알림","battle status uses toast")
		scene._process(3.1)
		check(not scene.battle_toast.visible,"battle toast expires")
		if role == "hero":
			check(scene.demon_info_panel.visible and scene.demon_info_panel.size.x > 0 and scene.demon_info_panel.size.y > 0 and scene.demon_info_panel.get_node_or_null("IllustratedBattlePanel") != null and scene.demon_info_panel.get_node("IllustratedBattlePanel").size == scene.demon_info_panel.size and scene.demon_info_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE,"hero demon information draws a sized gold frame without input: panel="+str(scene.demon_info_panel.size)+" frame="+str(scene.demon_info_panel.get_node("IllustratedBattlePanel").size))
			check(scene.demon_info_panel.get_node("Content").get_child(0).get_theme_font_size("font_size") == 24 and scene.demon_info_hints.get_theme_font_size("font_size") == 22,"hero demon information text is readable")
			check(scene.demon_info_panel.get_global_rect().end.y <= scene.view.get_global_rect().position.y,"demon information clears battlefield")
			scene._update_demon_info({"augment_hints":["공격 강화","방어 강화"]})
			check(scene.demon_info_hints.text.contains("공격 강화") and scene.demon_info_hints.text.contains("방어 강화"),"demon augment hints update")
			scene._update_demon_info({"augment_hints":[]})
			check(scene.demon_info_hints.text.contains("아직 없음"),"empty demon augment hints are explicit")
		else:
			check(scene.hero_build_toggle.visible and not scene.hero_build_overlay.visible,"hero build button starts closed")
			check(scene.direction_buttons.size() == 5 and scene.get_node_or_null("DirectionRow") == null,"demon uses shared choice buttons without battlefield direction row")
			scene._open_direction_select()
			var choice_grid: GridContainer = scene.demon_panel.get_node("ActionChoiceGrid")
			check(choice_grid.visible and choice_grid.get_child_count() == 5 and not scene.skill_row.visible and not scene.demon_panel.get_node("UltimateBar").visible,"line direction shows five choices and hides skills and ultimate bar")
			check(choice_grid.get_child(0).text.contains("동쪽") and choice_grid.get_child(1).text.contains("서쪽") and choice_grid.get_child(2).text.contains("북쪽") and choice_grid.get_child(3).text.contains("남쪽") and choice_grid.get_child(4).text == "취소","line direction uses solo button labels")
			choice_grid.get_child(4).pressed.emit()
			check(not choice_grid.visible and scene.skill_row.visible and scene.demon_panel.get_node("UltimateBar").visible and scene.demon_panel.get_node("UltimateLabel").text == scene.ultimate_status_text,"cancel restores demon skill controls")
			var skill_client = scene.client; var was_ended: bool = scene.ended
			scene.client = command_spy; scene.ended = false
			scene._open_direction_select(); choice_grid.get_child(0).pressed.emit()
			check(command_spy.kind == "skill" and command_spy.argument == {"id":"line_assault","direction":"east"} and not choice_grid.visible,"direction choice sends existing skill command: "+command_spy.kind+" "+str(command_spy.argument)+" grid="+str(choice_grid.visible))
			scene.client = skill_client; scene.ended = was_ended
			scene.hero_build_toggle.pressed.emit(); await process_frame
			check(scene.hero_build_overlay.visible and scene.hero_build_frame.get_node_or_null("IllustratedBattlePanel") != null and scene.hero_build_frame.size.x >= scene.size.x * 0.8,"hero build opens wide gold popup")
			check(absf(scene.hero_build_frame.get_global_rect().get_center().x-scene.size.x*0.5) <= 2.0 and not paused,"popup is centered and combat stays active")
			scene._update_match_hud({"seconds":41.0,"hero":[100.0,100.0,720,1200,3],"actors":[]})
			scene._update_hero_build({"level":3,"weapons":[["ranged_rookie_arcane_bolt",2,false]],"passives":[["survival_power",1]],"augments":["공격력 증가"],"rerolls_left":99,"held_offers":["비공개"]})
			await process_frame
			var build_text: String = ""
			for label in scene.hero_build_panel.find_children("*","Label",true,false):
				build_text += label.text
				check(label.size.x >= 200.0,"public build label keeps readable width: "+label.text+" width="+str(label.size.x))
			check(scene.hero_build_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and scene.hero_build_panel.size.x >= scene.hero_build_scroll.size.x - 24.0,"public build fills scroll width")
			check(scene.hero_build_weapon_cards.size() == WEAPONS.WEAPON_SLOTS and scene.hero_build_passive_cards.size() == WEAPONS.PASSIVE_SLOTS,"public build has every equipment slot")
			var weapon_name: Label = scene.hero_build_weapon_cards[0].get_node("Row/Text/Name")
			var weapon_details: Label = scene.hero_build_weapon_cards[0].get_node("Row/Text/Details")
			check(weapon_name.text.contains(String(WEAPONS.WEAPONS["ranged_rookie_arcane_bolt"].name)) and weapon_name.text.contains("Lv.2") and weapon_details.text.contains("피해") and weapon_details.text.contains("간격") and weapon_details.text.contains("사거리") and weapon_details.get_line_count() == 1,"equipped weapon shows name, level, and one-line stats")
			check(build_text.contains("공격력 증가"),"public build shows chosen augments")
			check(scene.hero_build_hp_text.text.contains("720 / 1200") and scene.hero_build_level.text.contains("Lv.3") and scene.hero_build_hp_bar.value == 720,"public build shows current hero HP and level")
			check(not build_text.contains("비공개") and not build_text.contains("99") and not build_text.contains("새로고침"),"held choices and reroll state remain private")
			var previous_signature: String = scene.hero_build_signature
			var previous_nodes: int = scene.hero_build_panel.find_children("*","Control",true,false).size()
			scene._update_hero_build(scene.hero_build_data)
			check(scene.hero_build_signature == previous_signature and scene.hero_build_panel.find_children("*","Control",true,false).size() == previous_nodes,"unchanged public build keeps nodes")
			var outside := InputEventMouseButton.new(); outside.pressed = true; outside.position = Vector2(10,10)
			scene._hero_build_outside_input(outside)
			check(not scene.hero_build_overlay.visible,"outside tap closes build popup")
			scene.hero_build_toggle.pressed.emit(); scene._close_hero_build()
			check(not scene.hero_build_overlay.visible and not scene.hero_build_toggle.button_pressed,"close hides build popup")
		var snapshot := {"seconds":41.0,"hero":[100.0,100.0,720,1200,3],"actors":[[1,"slime",200.0,200.0,50,50],[2,"orc",300.0,300.0,80,80]]}
		scene._update_match_hud(snapshot)
		check(scene.top_bar.get_node("RunTimer").text.contains("09:19") and scene.top_bar.get_node("HeroHP").text.contains("720 / 1200") and scene.top_bar.get_node("Monsters").text.contains("2"),"snapshot updates timer HP and monster count")
		check(scene.top_bar.get_node("HeroHPBar").value == 720 and scene.top_bar.get_node("HeroHPBar").max_value == 1200,"snapshot updates HP bar")
		if role == "hero":
			scene._update_hud_progress(3,24,50)
			check(scene.hero_slots.get_node("IllustratedBattlePanel").size == scene.hero_slots.size and scene.hero_slots.size.y > 0,"hero lower inventory draws gold frame")
			check(scene.top_bar.get_node("ExpBar").value == 24 and scene.top_bar.get_node("ExpBar").visible,"hero EXP shown")
			scene._update_hero_inventory({"level":3,"exp":24,"exp_next":50,"rerolls_left":1,"reroll_limit":2,"weapons":[["ranged_rookie_arcane_bolt",2,false]],"passives":[["survival_power",1]]})
			check(scene.weapon_buttons[0].get_node("Icon").texture != null and scene.weapon_buttons[0].get_node("Rank").text == "Lv.2" and scene.passive_buttons[0].get_node("Icon").texture != null,"snapshot fills shared hero slots")
			check(scene.weapon_buttons[0].get_parent().name == "무기Inventory" and scene.passive_buttons[0].get_parent().name == "보조Inventory" and (scene.weapon_buttons[0].get_theme_stylebox("normal") as StyleBoxFlat).border_width_left == 4,"hero slots use shared inventory rows and pixel skin")
		else: check(not scene.top_bar.get_node("ExpBar").visible and scene.top_bar.get_node("HeroLevel").text.contains("3"),"demon sees level without EXP")
		root.size = Vector2i(1080,1920); await process_frame; await process_frame
		scene.view._layout_map()
		check((scene.view.size/scene.view.map_scale).distance_to(CAMERA_VIEW.viewport_size(role == "hero")) < 0.1,"phone visible world matches solo camera")
		check(scene.view.map_offset.x <= 0 and scene.view.map_offset.y <= 0 and scene.view.map_offset.x + scene.view.bounds.x * scene.view.map_scale.x >= scene.view.size.x and scene.view.map_offset.y + scene.view.bounds.y * scene.view.map_scale.y >= scene.view.size.y,"phone camera clamps map over viewport")
		if role == "hero": check(is_equal_approx(scene.demon_info_panel.size.x,scene.top_bar.get_node("HeroStatusFrame").size.x),"phone demon information matches hero status width")
		check(scene.top_bar.get_global_rect().end.x <= root.size.x and absf(scene.view.get_global_rect().position.y-(470.0 if role == "hero" else 420.0)) <= 1.0 and absf(scene.view.get_global_rect().end.x-(root.size.x-(90.0 if role == "hero" else 120.0))) <= 1.0,"phone battlefield matches solo frame rect")
		var lower: Control = scene.demon_panel if role == "demon" else scene.hero_slots
		check(lower.get_global_rect().end.y <= root.size.y and scene.view.get_global_rect().end.y <= lower.get_global_rect().position.y,"phone lower HUD fits below battlefield")
		if role == "demon":
			check(scene.bottom_bar.get_global_rect().end.y <= root.size.y and scene.summon_buttons[-1].get_global_rect().end.x <= root.size.x,"phone cards fit")
			scene.hero_build_toggle.pressed.emit(); await process_frame
			check(scene.hero_build_frame.size.x >= root.size.x * 0.8 and scene.hero_build_frame.get_global_rect().position.x >= 0 and scene.hero_build_frame.get_global_rect().end.x <= root.size.x and scene.hero_build_frame.get_global_rect().end.y <= root.size.y,"phone build popup fits screen")
			scene._close_hero_build()
		check(scene.hold_popup.dot_row.get_global_rect().end.y <= lower.get_global_rect().position.y and absf(scene.view.get_global_rect().end.y-lower.get_global_rect().position.y) <= 2.0,"phone battlefield fills to lower HUD and dots stay above it")
		scene.hold_popup.open_index(0); await process_frame
		check(scene.hold_popup.popup.get_global_rect().position.y >= 0 and scene.hold_popup.popup.get_global_rect().end.y <= root.size.y,"phone popup fits")
		if role == "demon": check(scene.hold_popup.popup.get_global_rect().end.y < scene.bottom_bar.get_global_rect().position.y and scene.hold_popup.lower_button.get_global_rect().end.y <= scene.hold_popup.popup.get_global_rect().end.y,"phone augment popup clears bottom bar")
		scene.hold_popup.close_popup()
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		scene.battle_frame_enabled = false; scene._apply_match_frame(); await process_frame
		check(top_backing.visible and top_backing.get_global_rect().position == Vector2.ZERO and top_backing.get_global_rect().end.x >= root.size.x and top_backing.get_global_rect().end.y >= scene.top_bar.get_global_rect().end.y and lower_backing.visible and lower_backing.get_global_rect().end.x >= root.size.x and lower_backing.get_global_rect().end.y >= root.size.y,"tablet frame off retains top and lower HUD backgrounds")
		scene.battle_frame_enabled = true; scene._apply_match_frame(); await process_frame
		check(frame.visible and top_backing.visible and lower_backing.visible and is_equal_approx(scene.view.get_global_rect().position.x,90.0 if role == "hero" else 120.0),"tablet frame on restores original inset")
		scene.view._layout_map()
		check((scene.view.size/scene.view.map_scale).distance_to(CAMERA_VIEW.viewport_size(role == "hero")) < 0.1,"tablet visible world matches solo camera")
		check(scene.view.map_offset.x <= 0 and scene.view.map_offset.y <= 0 and scene.view.map_offset.x + scene.view.bounds.x * scene.view.map_scale.x >= scene.view.size.x and scene.view.map_offset.y + scene.view.bounds.y * scene.view.map_scale.y >= scene.view.size.y,"tablet camera clamps map over viewport")
		if role == "hero": check(is_equal_approx(scene.demon_info_panel.size.x,scene.top_bar.get_node("HeroStatusFrame").size.x),"tablet demon information matches hero status width")
		check(scene.top_bar.get_global_rect().end.x <= root.size.x and scene.top_bar.get_node("Monsters").get_global_rect().end.x <= root.size.x and absf(scene.view.get_global_rect().position.y-(470.0 if role == "hero" else 420.0)) <= 1.0 and absf(scene.view.get_global_rect().end.x-(root.size.x-(90.0 if role == "hero" else 120.0))) <= 1.0,"tablet battlefield matches solo frame rect")
		check(lower.get_global_rect().end.y <= root.size.y and lower.get_global_rect().end.x <= root.size.x and scene.view.get_global_rect().end.y <= lower.get_global_rect().position.y,"tablet lower HUD fits below battlefield")
		if role == "demon":
			check(scene.bottom_bar.get_global_rect().end.y <= root.size.y and scene.summon_buttons[-1].get_global_rect().end.x <= root.size.x,"tablet cards fit")
			scene.hero_build_toggle.pressed.emit(); await process_frame
			check(scene.hero_build_frame.size.x >= root.size.x * 0.8 and scene.hero_build_frame.get_global_rect().position.x >= 0 and scene.hero_build_frame.get_global_rect().end.x <= root.size.x and scene.hero_build_frame.get_global_rect().end.y <= root.size.y,"tablet build popup fits screen")
			scene._close_hero_build()
		check(scene.hold_popup.dot_row.get_global_rect().end.y <= lower.get_global_rect().position.y and absf(scene.view.get_global_rect().end.y-lower.get_global_rect().position.y) <= 2.0,"tablet battlefield fills to lower HUD and dots stay above it")
		scene.hold_popup.open_index(0); await process_frame
		check(scene.hold_popup.popup.get_global_rect().position.x >= 0 and scene.hold_popup.popup.get_global_rect().end.x <= root.size.x and scene.hold_popup.popup.get_global_rect().end.y <= root.size.y,"tablet popup fits")
		if role == "demon": check(scene.hold_popup.popup.get_global_rect().end.y < scene.bottom_bar.get_global_rect().position.y and scene.hold_popup.lower_button.get_global_rect().end.y <= scene.hold_popup.popup.get_global_rect().end.y,"tablet augment popup clears bottom bar")
		scene.hold_popup.close_popup()
		var camera_view = scene.view
		camera_view.bounds = Vector2(3200,3200)
		camera_view.motion.clear()
		camera_view.state = {"hero":[1600.0,1600.0,100.0,100.0,1,[0,0,0,0,0,-79,-64,-49]],"hero_archetype":"ranged_kiter","actors":[]}
		camera_view._layout_map()
		var center_before: Vector2 = (camera_view.size*0.5-camera_view.map_offset)/camera_view.map_scale
		check(center_before.distance_to(Vector2(1600,1600)) < 0.1,"camera follows hero at center")
		camera_view.state.hero[0] = 10.0; camera_view.state.hero[1] = 10.0
		camera_view._layout_map()
		var edge_center: Vector2 = (camera_view.size*0.5-camera_view.map_offset)/camera_view.map_scale
		check(edge_center.distance_to(CAMERA_VIEW.viewport_size(role == "hero")*0.5) < 0.1,"camera clamps hero at top-left world edge")
		camera_view.state.hero[0] = 3190.0; camera_view.state.hero[1] = 3190.0
		camera_view._layout_map()
		var far_center: Vector2 = (camera_view.size*0.5-camera_view.map_offset)/camera_view.map_scale
		check(far_center.distance_to(camera_view.bounds-CAMERA_VIEW.viewport_size(role == "hero")*0.5) < 0.1,"camera clamps hero at bottom-right world edge")
		if role == "demon":
			camera_view.state.hero[0] = 1600.0; camera_view.state.hero[1] = 1600.0
			camera_view.set_camera_view_locked(true)
			var lock_box := scene.settings_panel.get_node("Panel/Margin/VBox/SettingsTabs/Gameplay/CameraLock") as CheckBox
			lock_box.toggled.emit(false)
			check(not camera_view.camera_view_locked,"solo camera setting unlocks online demon view")
			var unlocked_center: Vector2 = camera_view.manual_center
			camera_view.pan_camera_by_screen_delta(Vector2(100,60))
			check(camera_view.manual_center.distance_to(unlocked_center-Vector2(100,60)/camera_view.map_scale) < 0.1,"demon drag pans by solo screen-to-world rule")
			camera_view.state.hero[0] = 2400.0; camera_view._layout_map()
			check(camera_view.manual_center.distance_to(unlocked_center-Vector2(100,60)/camera_view.map_scale) < 0.1,"unlocked camera does not follow hero")
			var placed: Array[Vector2] = []
			camera_view.placement.connect(func(point: Vector2): placed.append(point))
			var tap := InputEventMouseButton.new(); tap.button_index = MOUSE_BUTTON_LEFT; tap.position = camera_view.size*0.5; tap.pressed = true
			camera_view._gui_input(tap); tap.pressed = false; camera_view._gui_input(tap)
			check(placed.size() == 1 and placed[0].distance_to(camera_view.manual_center) < 0.1,"tap after camera pan sends visible world point for summon")
			tap.pressed = true; camera_view._gui_input(tap)
			var swipe := InputEventMouseMotion.new(); swipe.button_mask = MOUSE_BUTTON_MASK_LEFT; swipe.relative = Vector2(30,0)
			camera_view._gui_input(swipe); tap.pressed = false; camera_view._gui_input(tap)
			check(placed.size() == 1 and camera_view.manual_center.x < unlocked_center.x,"drag moves view without sending summon")
			lock_box.toggled.emit(true)
			check(camera_view.camera_view_locked,"camera lock resumes hero tracking")
			camera_view._layout_map()
			check(camera_view.manual_center.distance_to(Vector2(2400,1600)) < 0.1,"relocked demon view follows current hero")
		else:
			camera_view.set_camera_view_locked(false)
			check(camera_view.camera_view_locked,"hero camera cannot be unlocked")
		scene.queue_free(); await process_frame
	local.active = true; local.tutorial_preview = false; SCOPE.user_id = ""; SCOPE.guest_directory = local.test_directory
	check(local.is_online_match_allowed(),"isolated localtest has online permission")
	check(preload("res://src/systems/mode_unlock_store.gd").unlocked("rank","stage_1"),"localtest existing rank unlock reaches entry")
	local.tutorial_preview = true
	check(not local.is_online_match_allowed(),"tutorial preview has no online permission")
	local.tutorial_preview = false; SCOPE.user_id = "ordinary-account"
	check(not local.is_online_match_allowed(),"real account cannot borrow stale test flag")
	SCOPE.user_id = ""; SCOPE.guest_directory = "user://"
	check(not local.is_online_match_allowed(),"normal guest directory has no test permission")
	SCOPE.guest_directory = local.test_directory
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
		await process_frame
		check(scene.initial_local_test and scene.test_code != null and scene.test_code.secret,"localtest invitation UI for both roles")
		check(scene.disconnect_button.disabled and scene.reconnect_button.disabled,"test buttons disabled before match")
		check(scene.metrics_panel.get_parent() == scene and scene.metrics_panel not in scene.setup_controls,"metrics overlay survives setup controls hiding")
		scene._show_match_layout()
		if role == "demon":
			scene._update_elite_ui([],[[1,"slime"],[2,"spider"],[3,"orc"]])
			for dimensions in [Vector2i(1080,1920),Vector2i(1536,1920)]:
				root.size = dimensions; await process_frame; await process_frame
				for card in scene.elite_buttons:
					var rect: Rect2 = card.get_global_rect()
					check(not rect.intersects(scene.bottom_bar.get_global_rect()) and not rect.intersects(scene.hold_popup.dot_row.get_global_rect()) and not rect.intersects(scene.hero_build_toggle.get_global_rect()),"elite cards clear battle controls")
			scene._update_elite_ui([],[])
		scene._open_match_menu()
		var metrics_button: Button = scene.match_menu.find_child("ConnectionMetricsButton",true,false)
		check(metrics_button != null,"both roles expose test metrics from battle menu")
		metrics_button.pressed.emit(); await process_frame
		check(scene.metrics_panel.visible and not scene.match_menu.visible and scene.metrics_label.text.contains("RTT"),"battle menu opens populated metrics above battlefield")
		if role == "hero": check(scene.metrics_panel in scene.pad.input_exclusions,"metrics overlay cannot steer touch pad")
		scene._reset_metrics()
		check(scene.metrics_label.text.contains("미측정"),"reset immediately refreshes visible metrics")
		var close_metrics: Button = scene.metrics_panel.find_children("*","Button",true,false).back()
		close_metrics.pressed.emit()
		check(not scene.metrics_panel.visible,"metrics close restores unobstructed battle")
		scene.endpoint.text = "ws://127.0.0.1:24844"
		scene._join()
		check(scene.client.socket == null and scene.status.text.contains("입장코드"),"missing code stays disconnected")
		scene.test_code.text = preload("res://src/online/local_test_access.gd").new_ticket()
		scene._join()
		check(scene.client.socket != null and scene.client.token.is_empty() and scene.test_code.text.is_empty(),"localtest queues without social token; field cleared")
		check(scene.cancel_button.visible and scene.action_notice.visible,"matching wait shows cancel and instructions")
		local.active = false; scene._process(0.01)
		check(scene.ended and scene.client.socket == null and scene.status.text.contains("테스트 모드"),"leaving test scope closes connection")
		scene._join()
		check(scene.client.socket == null,"stale test scene cannot rejoin after scope change")
		local.active = true
		scene.queue_free(); await process_frame
	local.active = old_active; local.tutorial_preview = old_preview; SCOPE.user_id = old_owner; SCOPE.guest_directory = old_directory
	print("ONLINE_UI_PASS checks=",checks); quit()
