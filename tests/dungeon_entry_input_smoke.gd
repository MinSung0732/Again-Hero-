extends SceneTree
class Tutorial extends Node:
	func locks_lobby(): return false
class Transition extends Node:
	func is_transitioning(): return false
class Host extends Control:
	func _format_shop_number(n): return str(n)
var checks:=0
var failures:=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok: failures+=1;push_error(msg)
func _initialize():call_deferred("run")
func click(point: Vector2):
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=true;root.push_input(event)
	event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=false;root.push_input(event)
func run():
	root.size=Vector2i(1080,1920)
	for pair in [["TutorialFlow",Tutorial.new()],["SceneTransition",Transition.new()]]:
		pair[1].name=pair[0];root.add_child(pair[1])
	for variant in ["before","after"]:
		var script=load("res://tests/stamina_view_before.gd" if variant=="before" else "res://src/ui/lobby_stamina_view.gd")
		if script==null or not script.can_instantiate():quit(1);return
		var host=Host.new();host.size=Vector2(1080,1920);host.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(host)
		var view=script.new();view.lobby=host
		var info=Button.new();info.position=Vector2(480,80);info.size=Vector2(120,80);host.add_child(info);view._info_button=info;info.pressed.connect(view._toggle_info)
		var value=Label.new();host.add_child(value);view.value=value
		view._build_overlay()
		var button=Button.new();button.position=Vector2(350,700);button.size=Vector2(380,80);button.text="던전 입장";host.add_child(button)
		var presses=[0];button.pressed.connect(func():presses[0]+=1)
		view.show_info()
		await process_frame
		await process_frame
		await process_frame
		# Reproduce a visible info card over the entry button, regardless of resize.
		view.overlay.position=Vector2(250,400);view.overlay.size=Vector2(650,600)
		click(button.get_global_rect().get_center())
		await process_frame
		check(presses[0]==(0 if variant=="before" else 1),"tooltip click interception "+variant)
		if variant=="after":
			check(view.overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE,"information card never blocks underlying GUI")
			var event=InputEventScreenTouch.new();event.position=Vector2(950,1500);event.pressed=true
			check(not view.handle_info_input(event) and not view.overlay.visible,"outside touch closes without consuming entry input")
			view.show_info()
			view.show_entry_notice("팀 편성에서 마왕 스킬 3개를 편성해 주세요.")
			check(not view.overlay.visible and view._entry_notice.visible,"entry failure uses dedicated dialog")
			check(view._entry_notice.title=="던전 입장 안내" and view._entry_notice.dialog_text.contains("마왕 스킬"),"clear failure title and reason")
			var notice=view._entry_notice;view._entry_notice.hide()
			view.show_entry_notice("스테미너가 부족합니다.")
			check(view._entry_notice==notice and notice.dialog_text=="스테미너가 부족합니다.","dialog reused, message updated")
			view._entry_notice.hide()
			view.show_info()
			view.close_info()
			click(info.get_global_rect().get_center())
			check(view.overlay.visible and view._info_pinned,"explicit stamina click still opens details")
			click(info.get_global_rect().get_center())
			check(not view.overlay.visible,"second explicit stamina click still closes details")
			view.show_info()
			var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true
			check(view.handle_info_input(cancel) and not view.overlay.visible,"escape still closes info")
		host.queue_free()
		await process_frame
	var actor_script=load("res://tests/entry_actor.gd")
	if actor_script==null or not actor_script.can_instantiate():quit(1);return
	for scenario in ["valid","monsters","skills","both","insufficient","save_failed","test_exempt"]:
		var actor=actor_script.new();root.add_child(actor)
		if scenario in ["monsters","both"]:actor.team_selected_ids.clear()
		if scenario in ["skills","both"]:actor.demon_skill_selected_ids.clear()
		if scenario=="insufficient":actor.STAMINA.result={"success":false,"reason":"insufficient"}
		if scenario=="save_failed":actor.STAMINA.result={"success":false,"reason":"save_failed"}
		if scenario=="test_exempt":actor.LocalTestMode.active=true;actor.team_selected_ids.clear();actor.demon_skill_selected_ids.clear()
		actor._enter_selected_stage(true)
		var valid=scenario in ["valid","test_exempt"]
		check(actor.entered==(1 if valid else 0),"entry gate "+scenario)
		check(actor.stamina_view.info_calls==0 and actor.stamina_view.notice_calls==(0 if valid else 1),"failure route "+scenario)
		check(actor.stamina_view.closes==1,"old tooltip closed on entry "+scenario)
		if scenario in ["monsters","skills","both"]:check(actor.STAMINA.calls==0,"formation failure never charges stamina")
		if scenario=="insufficient":check(actor.stamina_view.message=="스테미너가 부족합니다.","insufficient reason preserved")
		if scenario=="save_failed":check(actor.stamina_view.message.contains("저장"),"save reason preserved")
		if valid:
			actor._enter_selected_stage(true)
			check(actor.entered==1 and actor.STAMINA.calls==1,"duplicate entry remains blocked")
		actor.queue_free();await process_frame
	print("dungeon_entry_input_smoke: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
