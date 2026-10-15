extends SceneTree
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var rules = load("res://src/data/hero_control_spawn_catalog.gd")
	var policy = load("res://src/hero_mode/hero_control_spawn_budget.gd")
	var modes = load("res://src/data/hero_mode_catalog.gd")
	var budget = policy.new()
	check(budget.controls("spider",false) and budget.controls("ghost",false),"baseline slow/augmented controller roles counted")
	check(budget.controls("mud_golem",false) and budget.controls("satyr_shaman",false) and budget.controls("toxic_slime",false),"new innate control sources counted")
	check(not budget.controls("orc",false) and budget.controls("orc",true),"normal orc exempt; elite control counted")
	check(not budget.controls("skeleton_archer",false) and budget.controls("skeleton_archer",true),"normal archer exempt; arrow-rain slow counted")
	check(budget.controls("hobgoblin",false) and budget.controls("gumiho",false),"non-controller innate stun/charm counted")
	check(not budget.controls("slime",true),"non-control elite remains available")
	for difficulty in ["easy","hard"]:
		for stage in range(1,11):
			var rule: Dictionary = rules.stage_rule(stage)
			budget.reset()
			check(not budget.allows("spider",false,stage,float(rule.first)-0.1,100),"opening grace period")
			check(budget.allows("spider",false,stage,float(rule.first),100),"first controller unlocked on schedule")
			var elapsed: float = maxf(60.0,float(rule.first))
			var accepted := 0
			for index in 200:
				var id := "spider" if index%2 == 0 else "ghost"
				if budget.allows(id,false,stage,elapsed,100):
					budget.register(index+1,id,false,stage,elapsed); accepted += 1
					check(not budget.allows("spider",false,stage,elapsed,100),"global control spacing shared across sources")
				elapsed = minf(299.0,elapsed+float(rule.interval))
			check(accepted <= int(rule.limit) and budget.members.size() <= int(rule.limit),"stage aggregate cap")
			check(int(budget.species.get("spider",0)) <= int(rule.species),"species cap stops controller spam")
			var id: int = budget.members.keys()[0]
			budget.retire(id); var after: int = budget.members.size(); budget.retire(id)
			check(budget.members.size() == after,"death + tree exit retire once")
			budget.reset()
			budget.register(1,"spider",false,stage,60)
			check(not budget.allows("ghost",false,stage,100,2),"ratio cap limits control-heavy small waves")
			check(budget.choose("spider",["spider","ghost"],false,stage,0,50).is_empty(),"all-control roster cannot bypass grace")
			check(budget.choose("spider",["spider","slime","orc"],false,stage,0,50) in ["slime","orc"],"non-control substitution preserves ordinary supply")
			check(budget.choose("orc",["orc","slime"],true,stage,0,50) == "slime","event elites share pressure limit")
			budget.reset()
			for index in int(rule.species)+rules.LATE_SPECIES_BONUS:
				var time: float = 300.0+index*float(rule.interval)
				if budget.allows("spider",false,stage,time,200): budget.register(index+1,"spider",false,stage,time)
			check(int(budget.species.get("spider",0)) == mini(int(rule.species)+rules.LATE_SPECIES_BONUS,int(rule.limit)+rules.LATE_LIMIT_BONUS),"five-minute easing stays bounded")
			for id2 in modes.roster_for(stage,difficulty):
				if not budget.controls(id2,false): check(budget.allows(id2,false,stage,0,0),"non-control roster unaffected")
	# Actual factory/registry paths (fixture uses original scripts, selected art placeholders).
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle._monster_spawn_resources_warmed = true; battle.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(battle)
	battle.hero_player_mode = true; battle.current_stage_data.number = 1
	battle.hero_control_roster = modes.roster_for(1,"easy")
	var point := Vector2(1500,1200)
	check(battle._spawn_monster("spider",point) == null,"factory blocks early controller before allocation")
	for index in 25: battle._spawn_monster("slime",point+Vector2(index*10,0))
	check(battle.active_monsters.size() == 25,"ordinary population/EXP opportunities retained")
	battle.run_metrics.elapsed_seconds = 30.0
	var spider = battle._spawn_monster("spider",point)
	check(is_instance_valid(spider) and battle.hero_control_spawns.members.size() == 1,"real spawn registers control pressure")
	var clock: float = battle.hero_control_spawns.next_spawn
	check(battle._spawn_monster("spider",point) == null and battle.hero_control_spawns.next_spawn == clock,"rejected spawn cannot consume another interval")
	battle.run_metrics.elapsed_seconds = 42.0
	var orc = battle._spawn_monster("orc",point,0.0,false,{"elite_variant":true})
	check(is_instance_valid(orc) and battle.hero_control_spawns.members.size() == 2,"mixed elite control shares aggregate count")
	battle.run_metrics.elapsed_seconds = 54.0
	check(battle._spawn_monster("skeleton_archer",point,0.0,false,{"elite_variant":true}) == null,"alternate slow elite cannot bypass cap")
	var event_actor = battle.spawn_hero_encounter("spider",point,{"type":"encounter"})
	check(is_instance_valid(event_actor) and not battle.hero_control_spawns.controls(String(event_actor.get_meta("monster_id",event_actor.monster_type)),true),"event substitutes safe elite at full CC budget")
	var director = load("res://src/hero_mode/ai_demon_director.gd").new()
	director.install(battle); battle.command_power = 1000.0
	var before: int = battle.active_monsters.size()
	check(director._summon_on_map("spider",54.0),"real AI replaces capped controller with a non-control recruit")
	check(battle.active_monsters.size() == before+1 and battle.hero_control_spawns.members.size() == 2,"substitution preserves supply without adding CC")
	check(director._special("orc",false,54.0),"scheduled elite substitutes rather than disappearing")
	check(battle.hero_control_spawns.members.size() == 2,"scheduled elite cannot bypass CC cap")
	spider.take_damage(999999)
	check(battle.hero_control_spawns.members.size() == 1,"death frees pressure without waiting for death animation")
	spider.free(); check(battle.hero_control_spawns.members.size() == 1,"tree cleanup cannot double-decrement")
	orc.free(); check(battle.hero_control_spawns.members.is_empty(),"despawn frees pressure")
	var normal_orc = battle._spawn_monster("orc",point)
	battle._apply_special_monster_modifiers(normal_orc,"orc",{"type":"elite"})
	check(battle.hero_control_spawns.members.size() == 1,"direct elite promotion starts tracking")
	battle._apply_special_monster_modifiers(normal_orc,"orc",{"type":"elite"})
	check(battle.hero_control_spawns.members.size() == 1,"repeated promotion is idempotent")
	battle.hero_control_spawns.next_spawn = 9999
	battle.run_metrics.elapsed_seconds = 900.0
	var boss = battle.spawn_hero_encounter("orc",point,{"type":"boss","target_hp":11800,"target_damage":32})
	check(is_instance_valid(boss) and boss.max_hp == 11800,"mandatory final boss cannot be starved by CC admission")
	battle.hero_player_mode = false; battle.run_metrics.elapsed_seconds = 0
	check(is_instance_valid(battle._spawn_monster("spider",point)),"demon mode keeps its existing summon rules")
	battle.queue_free(); await process_frame
	print("HERO_CONTROL_SPAWN checks=",checks," failures=",failures)
	quit(1 if failures else 0)
