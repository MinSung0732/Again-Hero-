extends SceneTree
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	root.get_node("SceneTransition")._entry_options = {"role":"hero"}
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.local_preparing = false; scene.waiting_for_start = false
	check(not scene.chest_panel.visible,"chest panel starts hidden")
	check(scene.inventory_detail != null and scene.inventory_detail.is_inside_tree(),"inventory detail dialog survives chest panel setup")
	scene._update_hero_inventory({"level":1,"exp":0,"exp_next":10,"rerolls_left":0,"reroll_limit":0,"weapons":[["ranged_rookie_arcane_bolt",2,false]],"passives":[]})
	scene._show_slot_info(true,0)
	check(scene.inventory_detail.visible and scene.inventory_detail.dialog_text.contains("Lv.2"),"equipped slot still opens full details")
	scene.inventory_detail.hide()
	check(not preload("res://src/ui/hero_augment_icons.gd").cache.is_empty(),"shared icon atlas cache warms before chest receipt")
	var receipt := {"serial":1,"id":"survival_power","name":"생존력","description":"체력 증가","evolution":false}
	scene._receive_chests([receipt]); scene._advance_chest_notice(0.01)
	await process_frame
	check(scene.chest_panel.visible and scene.chest_notice.text.contains("상자 ·"),"receipt opens a nonmodal reward panel")
	check(scene.chest_icon.texture == preload("res://src/ui/hero_augment_icons.gd").texture("survival_power"),"reward icon reuses solo icon catalog")
	check(scene.chest_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.chest_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.chest_notice.mouse_filter == Control.MOUSE_FILTER_IGNORE,"reward notice never captures battle touches")
	check(scene.chest_panel.size.x <= root.size.x * 0.6, "reward width at most 60 percent")
	check(not scene.chest_panel.get_global_rect().intersects(scene.hold_popup.dot_row.get_global_rect()), "reward avoids hold dots")
	check(scene.chest_panel.get_global_rect().position.y >= 0 and scene.chest_panel.get_global_rect().end.y <= root.size.y,"phone reward panel fits screen")
	root.size = Vector2i(1536,1920); await process_frame
	check(scene.chest_panel.size.x <= root.size.x * 0.6,"wide reward width at most 60 percent")
	check(not scene.chest_panel.get_global_rect().intersects(scene.hold_popup.dot_row.get_global_rect()),"wide reward avoids hold dots")
	root.size = Vector2i(1080,1920); await process_frame
	var panel = scene.chest_panel; var icon = scene.chest_icon
	var remaining: float = scene.chest_seconds
	scene.connection_waiting = true; scene._advance_chest_notice(10.0)
	check(scene.chest_seconds == remaining and scene.chest_panel.visible,"recovery preserves unread reward duration")
	scene.connection_waiting = false; scene._receive_chests([receipt])
	check(scene.chest_queue.is_empty(),"snapshot replay does not duplicate reward")
	scene._receive_chests([{"serial":2,"id":"survival_power","name":"진화 무기","description":"진화 효과","evolution":true}])
	scene._advance_chest_notice(3.0)
	check(scene.chest_notice.text.contains("진화 무기"),"evolution receipt clearly marks final evolution")
	check(scene.chest_panel == panel and scene.chest_icon == icon,"consecutive rewards reuse panel and icon nodes")
	scene._advance_chest_notice(3.0)
	check(not scene.chest_panel.visible,"reward panel closes after queue drains")
	scene._receive_chests([{"serial":3,"name":"종료 전 보상"}]); scene._advance_chest_notice(0.01)
	scene.ended = true; scene._set_controls(false)
	check(not scene.chest_panel.visible and scene.chest_queue.is_empty(),"terminal state clears reward presentation")
	scene._clear_chest_notice(true)
	check(scene.chest_last_serial == 0 and scene.chest_icon.texture == null,"new match resets serial and reward icon")
	scene.queue_free(); await process_frame
	print("ONLINE_CHEST_NOTICE_PASS checks=",checks); quit()
