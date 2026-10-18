extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const OLD_CATALOG=preload("res://catalog_before.gd")
const KEYS=[&"augment_raw_max_hp",&"augment_raw_attack_damage",&"augment_raw_move_speed",&"augment_raw_attack_cooldown"]
var checks=0
var failures=0
var profile:Dictionary
var missing=false
func check(ok,label):
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize():call_deferred("run")
func setup(script,kind,values,multiplier,stack):
	var owner=script.new()
	root.add_child(owner)
	if multiplier != null:owner.configs={"ghost":{"ghost_death_empower":multiplier}}
	var dead=owner.Actor.new();dead.name="dead";owner.add_child(dead)
	owner.active_monsters[0]=dead
	owner.ghost_death_buff_candidates.append(dead)
	if kind==0:return [owner,dead]
	for index in range(4):
		var actor=owner.Actor.new();actor.name="candidate%d"%index;owner.add_child(actor)
		actor.set_meta("ghost_death_empower_stacks",stack)
		for k in range(KEYS.size()):
			if not missing or k!=index:actor.set_meta(KEYS[k],values[k])
		owner.active_monsters[index+1]=actor
		if index==1 and kind in [2,3]:actor.current_hp=0
		if index==2 and kind in [2,3]:actor.current_hp=-1
		if index==3 and kind in [2,3]:actor.queue_free()
		if index==0 and kind==3:actor.current_hp=0
	var invalid=owner.Actor.new();owner.active_monsters[99]=invalid;invalid.free()
	owner.active_monsters[100]=null
	return [owner,dead]
func snapshot(owner):
	var state=[]
	for actor in owner.get_children():
		var stats=[]
		for key in KEYS:stats.append(actor.get_meta(key,0.0))
		state.append([actor.name,stats,actor.get_meta("ghost_death_empower_stacks",0)])
	var candidates=[]
	for actor in owner.ghost_death_buff_candidates:candidates.append(actor.name)
	return [owner.events.duplicate(true),state,candidates,randi(),randi(),randi()]
func run():
	missing="--missing-raw" in OS.get_cmdline_user_args()
	profile=CATALOG.MONSTERS["ghost"]["death_reactions"]
	var saved=profile.duplicate(true)
	# Only the new ghost policy may differ in the authoring data.
	var old=OLD_CATALOG.MONSTERS.duplicate(true)
	var current=CATALOG.MONSTERS.duplicate(true)
	current["ghost"]["death_reactions"].erase("ally_empower")
	check(old==current,"authoring unchanged outside ghost policy")
	var configs=[null,{},{"unused":true}, {"stat_multiplier":-2.0},{"stat_multiplier":0.0},{"stat_multiplier":1.0},{"stat_multiplier":1.1},{"stat_multiplier":2.5}]
	var values=[[100.0,12.0,50.0,1.0],[0.0,-1.0,0.5,0.01],[1.0,1.0,1.0,0.1],[9.125,0.25,2.75,0.11]]
	for kind in range(4):
		for config in configs:
			for stats in values:
				for stack in [0,3]:
					for random_seed in range(4):
						var a=setup(BEFORE,kind,stats,config,stack)
						var b=setup(AFTER,kind,stats,config,stack)
						for repeat in range(2):
							seed(random_seed+repeat*991)
							a[0].invoke(a[1],profile)
							var expected=snapshot(a[0])
							seed(random_seed+repeat*991)
							b[0].invoke(b[1],profile)
							check(expected==snapshot(b[0]),"state/events/RNG mismatch %s/%s/%s"%[kind,config,stats])
						a[0].free();b[0].free()
	check(profile==saved,"shared profile unchanged")
	if not missing:
		var pair=setup(AFTER,2,[100.0,12.0,50.0,1.0],{"unused":true},0)
		pair[0].invoke(pair[1],profile)
		var target=pair[0].get_node("candidate0")
		check(is_equal_approx(target.get_meta(KEYS[0]),110.0),"default multiplier sanity")
		check(target.get_meta("ghost_death_empower_stacks")==1,"one stack")
		var custom=profile.duplicate(true)
		custom.ally_empower.owner_id=&"fixture_owner"
		custom.ally_empower.augment_id=&"fixture_augment"
		custom.ally_empower.multiplier_key=&"fixture_factor"
		custom.ally_empower.raw_stats=[{"metadata":&"fixture_stat","minimum":9.0,"inverse":true}]
		custom.ally_empower.stack_metadata=&"fixture_stack"
		pair[0].configs={"fixture_owner":{"fixture_augment":{"fixture_factor":3.0}}}
		target.set_meta("fixture_stat",12.0)
		pair[0].invoke(pair[1],custom)
		check(target.get_meta("fixture_stat")==9.0 and target.get_meta("fixture_stack")==1,"custom rule bindings")
		check(target.get_meta("ghost_death_empower_stacks")==1,"custom rule leaves legacy keys")
		pair[0].free()
	print("GHOST_EMPOWER checks=%d failures=%d missing=%s"%[checks,failures,missing])
	quit(1 if failures else 0)
