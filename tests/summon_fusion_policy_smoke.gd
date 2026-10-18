extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const OLD=preload("res://catalog_before.gd")
var checks=0
var failures=0
var profile:Dictionary
func check(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run")
func setup(script,config,count,mode,failed):
	var owner=script.new();root.add_child(owner)
	if config!=null:owner.configs={"kobolt":{"kobolt_giant_fusion":config}}
	owner.spawn_failure_call=failed;owner.spawn_mutates=true
	var primary
	for index in range(count):
		var actor=owner.Actor.new();actor.name="actor%d"%index;owner.add_child(actor)
		actor.position=Vector2(100+index*10,100)
		owner.active_monsters[actor.get_instance_id()]=actor
		owner.monster_summon_costs[actor.get_instance_id()]=float(index)+0.25
		if mode%2==0 and index==1:owner.direct_population_ids[actor.get_instance_id()]=true
		owner.active_elite_skeletons[actor.get_instance_id()]=true
		owner.monsters_alive+=1;owner.query.append(actor)
		if index==0:primary=actor
		if index==1:
			match mode:
				1:actor.monster_type="slime"
				2:actor.current_hp=0
				3:actor.set_meta("visual_variant","elite")
				4:actor.set_meta("giant_monster",true)
				5:actor.set_meta("kobolt_fusion",true)
				6:actor.set_meta("spawn_source","kobolt_fusion")
				7:actor.set_meta("giant_size_multiplier",1.0011)
				8:actor.queue_free()
				9:actor.position=Vector2(280.01,100)
				10:actor.position=Vector2(280,100)
				11:actor.set_meta("giant_size_multiplier",1.001)
	owner.fusion_candidates.append(primary);owner.fusion_scratch.append(primary)
	owner.query.append(null)
	return [owner,primary]
func names(values):
	var result=[]
	for actor in values:result.append(actor.name if is_instance_valid(actor) else "invalid")
	return result
func snapshot(owner,result):
	var actors=[]
	for actor in owner.get_children():
		var id=actor.get_instance_id()
		actors.append([actor.name,actor.monster_type,actor.global_position,actor.is_queued_for_deletion(),actor.get_meta("giant_monster",false),actor.get_meta("kobolt_fusion",false),actor.get_meta("spawn_source",""),owner.monster_summon_costs.get(id,-1),owner.direct_population_ids.has(id),owner.active_monsters.has(id),owner.active_elite_skeletons.has(id)])
	return [owner.events.duplicate(true),actors,result.name if is_instance_valid(result) else "invalid",owner.monsters_alive,owner.monster_spatial_grid_physics_frame,names(owner.fusion_scratch),names(owner.fusion_candidates),randi()]
func run():
	profile=CATALOG.get_summon_fusion_profile("kobolt")
	var saved=profile.duplicate(true)
	var current=CATALOG.MONSTERS.duplicate(true);current.kobolt.erase("summon_fusion")
	check(current==OLD.MONSTERS,"unrelated authoring unchanged")
	for id in CATALOG.ORDER:
		check((not CATALOG.get_summon_fusion_profile(id).is_empty())==(id=="kobolt"),"opt-in "+id)
	check(CATALOG.get_summon_fusion_profile("unknown").is_empty(),"unknown opt-out")
	var configs=[null,{}, {"unused":true},{"required_count":0,"radius":-1},{"required_count":2,"radius":180.0},{"required_count":3.9,"radius":20.0},{"required_count":6,"radius":200.0}]
	for config in configs:
		for count in [0,1,2,3,4,6]:
			for mode in range(12):
				for failed in [-1,1]:
					var a=setup(BEFORE,config,count,mode,failed)
					var b=setup(AFTER,config,count,mode,failed)
					seed(991)
					var result=a[0].invoke(a[1],profile)
					var expected=snapshot(a[0],result)
					seed(991)
					result=b[0].invoke(b[1],profile)
					check(expected==snapshot(b[0],result),"fusion mismatch %s/%d/%d/%d"%[config,count,mode,failed])
					a[0].free();b[0].free()
	for mode in range(12):
		var a=setup(BEFORE,{"unused":true},4,mode,-1)
		var b=setup(AFTER,{"unused":true},4,mode,-1)
		var primary_a=a[0].get_node("actor1")
		var primary_b=b[0].get_node("actor1")
		check(a[0].candidate(primary_a,profile)==b[0].candidate(primary_b,profile),"primary candidate gate")
		seed(2)
		var result_a=a[0].invoke(primary_a,profile)
		var expected=snapshot(a[0],result_a)
		seed(2)
		var result_b=b[0].invoke(primary_b,profile)
		check(expected==snapshot(b[0],result_b),"primary rejection/acceptance")
		a[0].free();b[0].free()
	# Run whole production summon owner: primary spawn, fusion and XP/messages.
	for id in ["kobolt","slime","zeus"]:
		for failed in [-1,1,2]:
			for count in [0,3,5]:
				var snapshots=[]
				for script in [BEFORE,AFTER]:
					var pair=setup(script,{"unused":true},count,0,failed)
					var owner=pair[0];owner.append_primary=true
					seed(5)
					var ok=owner._perform_summon(id,Vector2(100,100),10.0,true)
					snapshots.append([ok,owner.command_power,snapshot(owner,null)])
					owner.free()
				check(snapshots[0]==snapshots[1],"summon mismatch "+id)
	# Independent result sanity and profile rebinding.
	var pair=setup(AFTER,{"unused":true},4,0,-1)
	var fused=pair[0].invoke(pair[1],profile)
	check(is_instance_valid(fused) and fused.get_meta("kobolt_fusion",false),"default4 fusion")
	check(fused.position==Vector2(115,100),"average position")
	check(pair[0].monster_summon_costs[fused.get_instance_id()]==7.0,"summed cost")
	check(pair[0].monsters_alive==1 and pair[0].direct_population_ids.has(fused.get_instance_id()),"population transfer")
	check(not pair[0].candidate(fused,profile),"fusion chain blocked")
	pair[0].free()
	pair=setup(AFTER,null,2,0,-1)
	var custom=profile.duplicate(true);custom.monster_id="fixture";custom.augment_id=&"fixture_fusion";custom.count_key=&"count";custom.radius_key=&"range";custom.fusion_marker=&"fixture_marker";custom.spawn_source="fixture_source"
	for actor in pair[0].get_children():actor.monster_type="fixture"
	pair[0].configs={"fixture":{"fixture_fusion":{"count":2,"range":200}}}
	fused=pair[0].invoke(pair[1],custom)
	check(is_instance_valid(fused) and fused.monster_type=="fixture" and fused.get_meta("fixture_marker",false) and fused.get_meta("spawn_source","")=="fixture_source","custom content bindings")
	pair[0].free()
	check(profile==saved,"shared profile unchanged by spawn adapter")
	print("SUMMON_FUSION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
