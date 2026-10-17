extends Node
## Authoritative adapter over the shipped Battle/Hero/monster/weapon code.
const RULES := preload("res://src/online/match_rules.gd")
signal completed(winner: String,reason: String)
var battle
var world: SubViewport
var is_prepared := false
var running := false
var finished := false
var winner := ""
var reason := ""
var move_age := 0.0
var choice_age := 0.0
var choice_revision := 0
var choice: Array = []
var tick := 0
var hero_last := Vector2.ZERO
var ids := {}
var next_id := 0
var snapshot_revision := 0
var stale_wire_ids: Array[int] = []
var last_action_message := ""
func prepare() -> void:
	world = SubViewport.new(); world.world_2d = World2D.new(); world.size = Vector2i(1080,1600)
	world.render_target_update_mode = SubViewport.UPDATE_DISABLED; add_child(world)
	var scene: PackedScene = load("res://src/battle/Battle.tscn")
	if scene == null: finish("","battle_load_failed"); return
	battle = scene.instantiate(); battle.online_match_mode = true
	battle.combat_popup_visuals_enabled = false
	battle.online_match_rules = {"population":RULES.POPULATION,"roster":RULES.ROSTER}
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = RULES.HERO
	world.add_child(battle); battle.set_external_pause(true)
	battle.run_time_limit_seconds = RULES.DURATION
	battle.run_metrics.reset(RULES.DURATION,int(battle.hero.current_hp),int(battle.hero.max_hp))
	battle.command_power = RULES.OPENING_MANA; battle.command_regen_per_second = RULES.MANA_PER_SECOND
	battle.set_allowed_monster_ids(RULES.ROSTER)
	battle.battle_finished.connect(func(_message: String,demon_won: bool): finish("demon" if demon_won else "hero",_message))
	battle.hero.player_augment_requested.connect(_choice)
	battle.summon_result.connect(func(_id: String,_accepted: bool,message: String): last_action_message = message)
	is_prepared = true
func start() -> void:
	if not is_prepared or finished: return
	running = true; battle.set_external_pause(false); battle.hero.player_input_suspended = false
func _choice(candidates: Array) -> void:
	choice_revision += 1; choice = candidates; choice_age = 0.0
func apply(role: String,kind: String,argument: Variant) -> bool:
	last_action_message = "사용할 수 없는 행동입니다."
	if not running or finished or not is_instance_valid(battle.hero): return false
	if role == "hero" and kind == "move" and RULES.point(argument,1.0):
		var direction := Vector2(float(argument[0]),float(argument[1]))
		if direction.length_squared() > 1.001: return false
		battle.hero.set_player_move_input(direction); move_age = 0.0; return true
	if role == "hero" and kind == "choose" and argument is Dictionary:
		if not RULES.number(argument.get("revision",null)) or argument.revision != choice_revision or not argument.get("id",null) is String: return false
		var accepted: bool = battle.hero.choose_player_augment(argument.id)
		if accepted and battle.hero.player_augment_candidates.is_empty(): choice = []; choice_revision += 1
		return accepted
	if role == "demon" and kind == "summon" and argument is Dictionary:
		if not argument.get("id",null) is String: return false
		var id: String = argument.id; var point: Variant = argument.get("point",null)
		if id not in RULES.ROSTER or not RULES.point(point): return false
		return battle.try_summon_at_position(id,Vector2(point[0],point[1]))
	return false
func step(delta: float) -> void:
	if not running or finished: return
	tick += 1; move_age += delta
	if move_age > RULES.INPUT_TIMEOUT and is_instance_valid(battle.hero): battle.hero.set_player_move_input(Vector2.ZERO)
	if not choice.is_empty():
		choice_age += delta
		if choice_age >= RULES.CHOICE_TIMEOUT: apply("hero","choose",{"revision":choice_revision,"id":String(choice[0].id)})
	if battle.demon_augment_selection_active and not battle.demon_augment_candidates.is_empty(): battle.choose_demon_augment(String(battle.demon_augment_candidates[0].id))
	if battle.mutation_director.is_active():
		var candidates: Array = battle.mutation_director.get_candidates()
		if not candidates.is_empty(): battle.try_choose_mutation(String(candidates[0]))
func finish(won: String,why: String) -> void:
	if finished: return
	finished = true; running = false; winner = won; reason = why
	if is_instance_valid(battle): battle.set_external_pause(true)
	completed.emit(winner,reason)
func snapshot() -> Dictionary:
	var profile = battle.get("combat_profile")
	var started: int = Time.get_ticks_usec() if profile != null and profile.enabled else 0
	var state := _build_snapshot()
	if started: profile.record(profile.Scope.NETWORK_SNAPSHOT,started)
	return state

func _build_snapshot() -> Dictionary:
	var actors: Array = []; var shots: Array = []
	var hp := 0; var maximum := 1; var level := 1
	if is_instance_valid(battle.hero):
		hero_last = battle.hero.position; hp = battle.hero.current_hp; maximum = battle.hero.max_hp; level = battle.hero.level
		var weapons = battle.hero.player_weapons
		if weapons != null:
			for shot in weapons.projectiles:
				if shot.active: shots.append([snappedf(shot.position.x,0.1),snappedf(shot.position.y,0.1)])
	snapshot_revision += 1
	for raw_id in battle.active_monsters:
		var raw = battle.active_monsters[raw_id]
		var actor := raw as Node2D
		if not is_instance_valid(actor) or actor.is_queued_for_deletion(): continue
		var instance := actor.get_instance_id()
		var generation: Vector3i = battle.get_battle_entity_handle(actor)
		if not ids.has(instance) or ids[instance].generation != generation:
			next_id += 1; ids[instance] = {"wire":next_id,"generation":generation,"seen":snapshot_revision}
		else: ids[instance].seen = snapshot_revision
		actors.append([ids[instance].wire,String(actor.get("monster_type")),snappedf(actor.position.x,0.1),snappedf(actor.position.y,0.1),int(actor.get("current_hp")),int(actor.get("max_hp"))])
	stale_wire_ids.clear()
	for instance in ids:
		if int(ids[instance].seen) != snapshot_revision: stale_wire_ids.append(instance)
	for instance in stale_wire_ids: ids.erase(instance)
	# Bounded O(n) serialization at10Hz, outside the combat hot frame.
	return {"op":"state","tick":tick,"hero":[hero_last.x,hero_last.y,hp,maximum,level],"bounds":[battle.current_map_size.x,battle.current_map_size.y],"seconds":battle.run_metrics.elapsed_seconds,"mana":battle.command_power,"actors":actors,"shots":shots,"choice_revision":choice_revision,"choices":choice,"winner":winner,"reason":reason}
