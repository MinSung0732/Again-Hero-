extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const DATA := preload("res://src/data/online_exp_orb_catalog.gd")
const DISPLAY := preload("res://src/online/exp_orb_view.gd")
const REGISTRY := preload("res://src/online/exp_orb_registry.gd")
const RULES := preload("res://src/online/match_rules.gd")
class TextureSink extends RefCounted:
	var requests:=0
	func _request_texture(_path: String) -> void: requests+=1
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var room:=ROOM.new(); root.add_child(room); room.prepare()
	var battle=room.battle
	battle.process_mode=Node.PROCESS_MODE_DISABLED
	var exp_before:=int(battle.hero.current_exp)
	var point: Vector2=battle.hero.global_position+Vector2(800,0)
	battle._spawn_exp_orb(point,31)
	var rows: Array=room.exp_orb_visuals.snapshot()
	check(rows.size()==1 and DATA.valid(rows),"actual authoritative drop enters bounded visual registry")
	check(int(rows[0][3])==DATA.tier_for(31),"visual tier comes from original EXP thresholds")
	var first_id:=int(rows[0][0])
	var orb: Node2D=room.exp_orb_visuals.active.values()[0].node
	var node_id:=orb.get_instance_id()
	check(not orb.visuals_enabled and not orb.visual.visible,"authority never loads or animates gem artwork on kill")
	orb.magnetized=true
	rows=room.exp_orb_visuals.snapshot()
	check(int(rows[0][4])==DATA.ATTRACTED,"authoritative attraction flag mirrored")
	battle.recycle_exp_orb(orb)
	rows=room.exp_orb_visuals.snapshot()
	check(rows.size()==1 and int(rows[0][4])==DATA.COLLECTED and room.exp_orb_visuals.active.is_empty(),"pool retirement emits retained pickup once")
	battle.recycle_exp_orb(orb)
	check(room.exp_orb_visuals.collected.size()==1,"duplicate retirement does not duplicate pickup")
	# Remove duplicate fixture pool entry: real gameplay retires each activation once.
	battle.exp_orb_pool.erase(orb)
	battle._spawn_exp_orb(point+Vector2(20,0),201)
	rows=room.exp_orb_visuals.snapshot()
	var active_row: Array=rows[-1]
	check(int(active_row[0])!=first_id and room.exp_orb_visuals.active.values()[0].node.get_instance_id()==node_id,"same pooled node receives new visual identity")
	check(int(battle.hero.current_exp)==exp_before,"visual publication/recycle never grants EXP")
	var sink:=TextureSink.new(); var display:=DISPLAY.new()
	display.replace([active_row],sink)
	check(display.slots.size()==1 and sink.requests==DATA.SOURCE.FRAME_COUNT,"tier frame requests are bounded and reused")
	var slot: int=display.slots[int(active_row[0])]
	var moved: Array=active_row.duplicate(); moved[1]+=100
	display.replace([moved],sink); display.advance(RULES.SNAPSHOT_INTERVAL*.5)
	check(is_equal_approx(display.positions[slot].x,float(active_row[1])+50),"drop movement interpolates between server samples")
	var collected: Array=moved.duplicate(); collected[4]=DATA.COLLECTED
	display.replace([collected],sink); display.advance(DATA.ABSORB_SECONDS*.5)
	var elapsed: float=display.elapsed[slot]
	display.replace([collected],sink)
	check(is_equal_approx(display.elapsed[slot],elapsed),"retained collection does not restart absorption")
	check(display.advance(DATA.ABSORB_SECONDS) and not display.needs_process(),"collection finishes with final redraw and stops processing")
	display.replace([],sink)
	check(display.slots.is_empty() and display.free_count==DATA.MAX_ROWS,"absent rows return fixed slots")
	var max_rows: Array=[]
	for index in DATA.MAX_ROWS: max_rows.append([index+1,100,200,0,DATA.IDLE])
	display.replace(max_rows,sink)
	check(display.slots.size()==DATA.MAX_ROWS and display.free_count==0,"fixed capacity handles full visual roster")
	var swapped: Array=[]
	for row in max_rows: swapped.append([int(row[0])+DATA.MAX_ROWS,100,200,0,DATA.IDLE])
	display.replace(swapped,sink)
	check(display.slots.size()==DATA.MAX_ROWS and display.slots.has(DATA.MAX_ROWS*2),"full-capacity replacement releases missing IDs first")
	check(DATA.valid(max_rows) and not DATA.valid(max_rows+[max_rows[0]]),"row count bounded")
	check(not DATA.valid([[1,0,0,0,0],[1,0,0,0,0]]) and not DATA.valid([[1,NAN,0,0,0]]) and not DATA.valid([[1,0,0,99,0]]) and not DATA.valid([[1,0,0,0,3]]),"duplicate IDs and malformed geometry/tier/state rejected")
	var view:=VIEW.new(); root.add_child(view)
	var snapshot: Dictionary=JSON.parse_string(JSON.stringify(room.snapshot()))
	check(DATA.valid(snapshot.exp_orbs),"JSON float-valued gem states survive wire validation")
	check(view.update_state(snapshot) and view.exp_orbs.slots.size()==snapshot.exp_orbs.size(),"full state delivers EXP visual payload to client")
	var bad: Dictionary=snapshot.duplicate(true); bad.exp_orbs=[[1,NAN,0,0,0]]
	check(not view.update_state(bad) and view.state==snapshot,"malformed gems do not mutate accepted state")
	view.clear_state()
	check(view.exp_orbs.slots.is_empty(),"leave/rematch clears gem display pool")
	view.free()
	# Registry snapshot stays bounded without scanning scene groups.
	for index in DATA.MAX_ACTIVE+4: battle._spawn_exp_orb(point+Vector2(index,0),1)
	rows=room.exp_orb_visuals.snapshot()
	check(rows.size()<=DATA.MAX_ROWS and DATA.valid(rows),"overflow drops remain authoritative while visual snapshot stays bounded")
	snapshot=room.snapshot()
	check(JSON.stringify(snapshot).to_utf8_buffer().size()<=RULES.MAX_SNAPSHOT,"bounded gems fit snapshot payload budget")
	for player in room.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	room.free()
	print("ONLINE_EXP_ORB checks=",checks," failures=",failures)
	quit(1 if failures else 0)
