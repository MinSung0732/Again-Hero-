extends SceneTree
const MOTION := preload("res://src/online/actor_motion.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func sample(y: float) -> Dictionary:
	return {"bounds":[3600,3600],"hero":[100,y,80,100,1,[204,0,0,0,0,-79,-64,-49]],"hero_archetype":RULES.HERO,"actors":[[1,RULES.ROSTER[0],200,y,10,20,[128,-1,-44,100,100]]],"visuals":[command(0,y),command(1,y),command(-2,150),command(-1,175)]}
func command(owner: int,y: float) -> Array:
	return [owner,"res://assets/art/fixture.png",0,0,16,16,1,0,0,1,100,y,-8,-8,16,16,1,1,1,1,0,y]
func run() -> void:
	var motion = MOTION.new()
	motion.replace([0,0,1,1,1],[[1,RULES.ROSTER[0],10,10,1,1]])
	check(motion.position(0,Vector2.INF)==Vector2.ZERO and not motion.active,"first state snaps")
	motion.replace([100,100,1,1,1],[[1,RULES.ROSTER[0],110,110,1,1]])
	check(motion.position(0,Vector2.INF)==Vector2.ZERO,"new target does not jump")
	motion.advance(DATA.MOTION_SECONDS*0.5)
	check(motion.position(0,Vector2.INF).is_equal_approx(Vector2(50,50)),"half-time linear position")
	check(motion.position(1,Vector2.INF).is_equal_approx(Vector2(60,60)),"monster uses same clock")
	motion.replace([150,150,1,1,1],[[1,RULES.ROSTER[0],160,160,1,1]])
	check(motion.position(0,Vector2.INF).is_equal_approx(Vector2(50,50)),"jitter retarget starts from displayed point")
	motion.advance(DATA.MOTION_SECONDS)
	check(motion.position(0,Vector2.INF)==Vector2(150,150) and not motion.active,"converges within one interval")
	motion.advance(DATA.MOTION_SECONDS*10)
	check(motion.position(0,Vector2.INF)==Vector2(150,150),"no extrapolation when packets stop")
	motion.replace([160,160,1,1,1],[])
	check(motion.position(0,Vector2.INF)==Vector2(160,160),"long gap resets baseline")
	check(not motion.slots.has(1),"death releases wire slot immediately")
	motion.replace([160+DATA.MOTION_SNAP_DISTANCE*2,160,1,1,1],[[2,RULES.ROSTER[0],90,90,1,1]])
	check(not motion.active and motion.position(2,Vector2.INF)==Vector2(90,90),"teleport and new spawn snap")
	motion.clear()
	check(motion.slots.is_empty() and motion.free_count==MOTION.CAPACITY,"reset releases all tracks")
	var actors: Array = []
	for id in DATA.MAX_ACTORS: actors.append([id+1,RULES.ROSTER[0],id,10,1,1])
	motion.replace([0,0,1,1,1],actors)
	check(motion.slots.size()==MOTION.CAPACITY and motion.free_count==0,"maximum accepted roster fits pool")
	for actor in actors: actor[0] += DATA.MAX_ACTORS
	motion.replace([0,0,1,1,1],actors)
	check(motion.slots.size()==MOTION.CAPACITY and not motion.slots.has(1),"full roster replacement recycles before acquisition")
	var complete := true
	for id in DATA.MAX_ACTORS: complete = complete and motion.slots.has(id+1+DATA.MAX_ACTORS)
	check(complete,"all replacement wire IDs retained")
	var view = VIEW.new(); root.add_child(view); view.set_process(false)
	check(view.update_state(sample(100)),"baseline view accepts state")
	var next := sample(200); var untouched := JSON.stringify(next)
	check(view.update_state(next),"moving state accepted")
	check(view.visual_slots[view.visual_order[0]]>=0,"display ground remains behind pillar at start")
	view.advance_motion(DATA.MOTION_SECONDS*0.25)
	check(view.motion.position(0,Vector2.INF)==Vector2(100,125),"PNG and fallback/HP share displayed actor position")
	check(view.render_visuals[view.visual_order[0]][0]==0,"early display ground behind static prop")
	view.advance_motion(DATA.MOTION_SECONDS*0.5)
	check(view.render_visuals[view.visual_order[0]][0]==-2,"pillar ordering changes at displayed ground crossing")
	for index in view.render_visuals.size():
		if int(view.render_visuals[index][0])<0: check(view.visual_slots[index]==-1,"props and anonymous projectiles never inherit actor movement")
	check(JSON.stringify(next)==untouched,"wire transforms/positions/HP remain immutable")
	view.pause_motion(); var frozen: Vector2 = view.motion.position(0,Vector2.INF)
	view.advance_motion(1.0)
	check(view.motion.position(0,Vector2.INF)==frozen,"disconnect/result freezes display")
	view.resume_motion(); check(view.update_state(sample(210)),"resume accepts fresh baseline")
	check(view.motion.position(0,Vector2.INF)==Vector2(100,210) and not view.motion.active,"resume never glides from old match")
	var bad := sample(220); bad.actors.append(bad.actors[0].duplicate())
	check(not view.update_state(bad) and view.state.hero[1]==210,"duplicate wire IDs rejected before motion/state mutation")
	bad = sample(220); bad.actors[0][0]=1.5
	check(not view.update_state(bad),"fractional actor identity rejected")
	check(view.update_state(sample(220)) and view.is_processing(),"movement schedules render processing without pending textures")
	view._process(DATA.MOTION_SECONDS)
	check(not view.motion.active,"motion settles independently of pending cold textures")
	var texture_deadline := Time.get_ticks_msec()+6000
	while not view.pending_textures.is_empty() and Time.get_ticks_msec()<texture_deadline: await process_frame
	check(not view.is_processing() and view.pending_textures.is_empty(),"settled motion and completed textures stop idle polling")
	var stale_at := Time.get_ticks_usec()+int(DATA.MOTION_RESET_SECONDS*1000000.0)+2000
	while Time.get_ticks_usec()<stale_at: await process_frame
	check(view.update_state(sample(230)) and view.motion.position(0,Vector2.INF)==Vector2(100,230),"stale idle gap snaps using monotonic receipt clock")
	view.clear_state()
	check(view.motion.slots.is_empty() and view.visual_order.is_empty(),"leave/rematch clears motion and depth cache")
	view.queue_free(); await process_frame
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	await process_frame
	scene.client.match_id="motion-fixture"
	scene._event({"op":"connection","match":"motion-fixture","paused":true,"remaining":15.0})
	check(scene.view.motion_paused,"peer disconnect reaches motion pause")
	scene._event({"op":"connection","match":"motion-fixture","paused":false,"remaining":0.0})
	check(not scene.view.motion_paused and scene.view.motion.slots.is_empty(),"peer resume resets motion baseline")
	scene.client.connection_recovering.emit(true,15.0)
	check(scene.view.motion_paused,"local socket loss reaches motion pause")
	scene._event({"op":"matched","match":"motion-fixture","resumed":true,"map":"plaza","duration":600,"battlefield":{"stage":"stage_1","bounds":[3200,3200],"map":"plaza"}})
	check(not scene.view.motion_paused,"local resume resets baseline before ready")
	scene._event({"op":"result","match":"motion-fixture","winner":"hero"})
	check(scene.result_pending and scene.view.presentation_speed < 1.0 and scene.ended,"terminal result slows only presentation and blocks input")
	scene.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("ONLINE_MOTION_PASS checks=",checks); quit()
