extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const RULES := preload("res://src/online/match_rules.gd")
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
	for path in ["res://src/main/main.gd","res://src/online/match_scene.gd","res://src/online/battle_room.gd","res://src/ui/augment_hold_popup.gd"]:
		var script: Script = load(path)
		check(script != null and script.can_instantiate(),"modified script loads: "+path)
	var solo_packed: PackedScene = load("res://src/main/Main.tscn")
	check(solo_packed != null and solo_packed.can_instantiate(),"solo scene loads")
	var solo := solo_packed.instantiate()
	check(solo.get_node_or_null("HUD/BottomBar/CommandBar") != null and solo.get_node_or_null("HUD/DemonUltimatePanel/UltimateButtons") != null,"solo paths survive shared scene extraction")
	solo.free()
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
		check(scene.queue_button.custom_minimum_size.y >= 72,"mobile button size")
		check(scene.view.size.x > 500 and scene.view.size.y > 300,"battle panel expands")
		check(scene.hold_popup.dots.size() == RULES.AUGMENT_HOLD_LIMIT and not scene.hold_popup.popup.visible,"pooled hold dots start closed")
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
		scene.hold_popup.lower_button.pressed.emit()
		check(not scene.hold_popup.popup.visible and scene.hold_popup.dots[1].visible,"lower closes popup and keeps dot")
		var real_client = scene.client
		var command_spy := CommandSpy.new(); scene.client = command_spy
		scene.hold_popup.open_index(1); scene.hold_popup.cards[0].pressed.emit()
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
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		check(scene.view.size.x > 1200,"tablet width expands")
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
		scene._event({"op":"matched","hero":"ranged_rookie","map":"plaza","duration":600,"battlefield":{"stage":"stage_1","bounds":[3200,3200],"map":"plaza"}})
		await process_frame
		check(scene.top_bar.visible and scene.top_bar.get_node_or_null("RunTimer") != null and scene.top_bar.get_node_or_null("HeroHPBar") != null and scene.top_bar.get_node_or_null("Monsters") != null,"both roles share battle top bar")
		var snapshot := {"seconds":41.0,"hero":[100.0,100.0,720,1200,3],"actors":[[1,"slime",200.0,200.0,50,50],[2,"orc",300.0,300.0,80,80]]}
		scene._update_match_hud(snapshot)
		check(scene.top_bar.get_node("RunTimer").text.contains("09:19") and scene.top_bar.get_node("HeroHP").text.contains("720 / 1200") and scene.top_bar.get_node("Monsters").text.contains("2"),"snapshot updates timer HP and monster count")
		check(scene.top_bar.get_node("HeroHPBar").value == 720 and scene.top_bar.get_node("HeroHPBar").max_value == 1200,"snapshot updates HP bar")
		if role == "hero":
			scene._update_hud_progress(3,24,50)
			check(scene.top_bar.get_node("ExpBar").value == 24 and scene.top_bar.get_node("ExpBar").visible,"hero EXP shown")
			scene._update_hero_inventory({"level":3,"exp":24,"exp_next":50,"rerolls_left":1,"reroll_limit":2,"weapons":[["ranged_rookie_arcane_bolt",2,false]],"passives":[["survival_power",1]]})
			check(scene.weapon_buttons[0].get_node("Icon").texture != null and scene.weapon_buttons[0].get_node("Rank").text == "Lv.2" and scene.passive_buttons[0].get_node("Icon").texture != null,"snapshot fills shared hero slots")
		else: check(not scene.top_bar.get_node("ExpBar").visible and scene.top_bar.get_node("HeroLevel").text.contains("3"),"demon sees level without EXP")
		root.size = Vector2i(1080,1920); await process_frame; await process_frame
		check(scene.top_bar.get_global_rect().end.x <= root.size.x and scene.view.get_global_rect().position.y >= scene.top_bar.get_global_rect().end.y,"phone top bar fits above battlefield")
		var lower: Control = scene.demon_panel if role == "demon" else scene.hero_slots
		check(lower.get_global_rect().end.y <= root.size.y and scene.view.get_global_rect().end.y <= lower.get_global_rect().position.y,"phone lower HUD fits below battlefield")
		if role == "demon":
			check(scene.bottom_bar.get_global_rect().end.y <= root.size.y and scene.summon_buttons[-1].get_global_rect().end.x <= root.size.x,"phone cards fit")
		check(scene.hold_popup.dot_row.get_global_rect().end.y <= lower.get_global_rect().position.y and scene.view.get_global_rect().end.y <= scene.hold_popup.dot_row.get_global_rect().position.y,"phone dots fit between battlefield and lower HUD")
		scene.hold_popup.open_index(0); await process_frame
		check(scene.hold_popup.popup.get_global_rect().position.y >= 0 and scene.hold_popup.popup.get_global_rect().end.y <= root.size.y,"phone popup fits")
		scene.hold_popup.close_popup()
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		check(scene.top_bar.get_global_rect().end.x <= root.size.x and scene.top_bar.get_node("Monsters").get_global_rect().end.x <= root.size.x and scene.view.get_global_rect().position.y >= scene.top_bar.get_global_rect().end.y,"tablet top bar fits above battlefield")
		check(lower.get_global_rect().end.y <= root.size.y and lower.get_global_rect().end.x <= root.size.x and scene.view.get_global_rect().end.y <= lower.get_global_rect().position.y,"tablet lower HUD fits below battlefield")
		if role == "demon": check(scene.bottom_bar.get_global_rect().end.y <= root.size.y and scene.summon_buttons[-1].get_global_rect().end.x <= root.size.x,"tablet cards fit")
		check(scene.hold_popup.dot_row.get_global_rect().end.y <= lower.get_global_rect().position.y and scene.view.get_global_rect().end.y <= scene.hold_popup.dot_row.get_global_rect().position.y,"tablet dots fit between battlefield and lower HUD")
		scene.hold_popup.open_index(0); await process_frame
		check(scene.hold_popup.popup.get_global_rect().position.x >= 0 and scene.hold_popup.popup.get_global_rect().end.x <= root.size.x and scene.hold_popup.popup.get_global_rect().end.y <= root.size.y,"tablet popup fits")
		scene.hold_popup.close_popup()
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
		scene.endpoint.text = "ws://127.0.0.1:24844"
		scene._join()
		check(scene.client.socket == null and scene.status.text.contains("입장코드"),"missing code stays disconnected")
		scene.test_code.text = preload("res://src/online/local_test_access.gd").new_ticket()
		scene._join()
		check(scene.client.socket != null and scene.client.token.is_empty() and scene.test_code.text.is_empty(),"localtest queues without social token; field cleared")
		local.active = false; scene._process(0.01)
		check(scene.ended and scene.client.socket == null and scene.status.text.contains("테스트 모드"),"leaving test scope closes connection")
		scene._join()
		check(scene.client.socket == null,"stale test scene cannot rejoin after scope change")
		local.active = true
		scene.queue_free(); await process_frame
	local.active = old_active; local.tutorial_preview = old_preview; SCOPE.user_id = old_owner; SCOPE.guest_directory = old_directory
	print("ONLINE_UI_PASS checks=",checks); quit()
