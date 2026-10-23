extends Node
## Authoritative adapter over the shipped Battle/Hero/monster/weapon code.
const RULES := preload("res://src/online/match_rules.gd")
const SKILLS := preload("res://src/data/demon_ultimate_catalog.gd")
const PRESENTATION := preload("res://src/online/presentation_snapshot.gd")
var presentation = PRESENTATION.new()
var battlefield_info := {}
const PRIMITIVES := preload("res://src/online/primitive_mirror.gd")
var feedback = preload("res://src/online/feedback_buffer.gd").new()
signal completed(winner: String,reason: String)
var battle
var world: SubViewport
var is_prepared := false
var running := false
var finished := false
var connection_paused := false
var input_suspended_before_disconnect := false
var winner := ""
var reason := ""
var move_age := 0.0
var choice_revision := 0
var choice: Array = []
var hero_holds: Array = []
var chest_receipts: Array = []
var demon_holds: Array = []
var next_offer_number := 0
var tick := 0
var hero_last := Vector2.ZERO
var ids := {}
var next_id := 0
var snapshot_revision := 0
var stale_wire_ids: Array[int] = []
var last_action_message := ""
var hero_id := preload("res://src/data/hero_character_catalog.gd").DEFAULT_HERO
var roster: Array = RULES.ROSTER.duplicate() # Isolated room fixtures; the server sets the verified roster before prepare().
var skill_ids: Array = []
var transcendence_id := ""
func set_loadouts(hero_loadout: Dictionary,demon_loadout: Dictionary) -> void:
	hero_id = String(hero_loadout.hero_id)
	roster = demon_loadout.team_ids.duplicate()
	skill_ids = demon_loadout.skill_ids.duplicate()
	transcendence_id = String(demon_loadout.transcendence_id)
func prepare() -> void:
	world = SubViewport.new(); world.world_2d = World2D.new(); world.size = Vector2i(1080,1600)
	world.render_target_update_mode = SubViewport.UPDATE_DISABLED; add_child(world)
	var scene: PackedScene = load("res://src/battle/Battle.tscn")
	if scene == null: finish("","battle_load_failed"); return
	battle = scene.instantiate(); battle.online_match_mode = true
	battle.combat_popup_visuals_enabled = false
	battle.online_match_rules = {"population":RULES.POPULATION,"roster":roster,"skill_ids":skill_ids,"transcendence_id":transcendence_id}
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = hero_id
	world.add_child(battle); battle.set_external_pause(true)
	battle.run_time_limit_seconds = RULES.DURATION
	battle.run_metrics.reset(RULES.DURATION,int(battle.hero.current_hp),int(battle.hero.max_hp))
	battle.command_power = RULES.OPENING_MANA; battle.command_regen_per_second = RULES.MANA_PER_SECOND
	battle.set_allowed_monster_ids(roster)
	battlefield_info = {"stage":battle.current_stage_id,"bounds":[battle.current_map_size.x,battle.current_map_size.y]}
	battle.online_visual_entity_exited.connect(presentation.forget_node)
	battle.online_combat_feedback.connect(_feedback)
	battle.online_cast_feedback.connect(func(cue: String,point: Vector2):
		if running and not finished and not connection_paused: feedback.publish(cue,point,0,Color.WHITE,tick))
	battle.demon_ultimate_used.connect(func(_id: String,_name: String,_message: String):
		if running and not finished and not connection_paused: feedback.publish("cast",battle.hero.position,0,Color(0.8,0.5,1.0),tick))
	battle.transcendent_summoned.connect(func(_id: String,actor: Node2D):
		if running and not finished and not connection_paused and is_instance_valid(actor): feedback.publish("transcend",actor.global_position,0,Color(1.0,0.75,0.35),tick))
	battle.demon_augment_ready.connect(_demon_offer)

	battle.battle_finished.connect(func(_message: String,demon_won: bool): finish("demon" if demon_won else "hero",_message))
	battle.hero.player_augment_requested.connect(_choice)
	battle.hero_chest_opened.connect(_chest_opened)
	battle.summon_result.connect(func(_id: String,_accepted: bool,message: String): last_action_message = message)
	is_prepared = true
func start() -> void:
	if not is_prepared or finished: return
	running = true; battle.set_external_pause(connection_paused); battle.hero.player_input_suspended = connection_paused
func set_connection_paused(value: bool) -> void:
	if connection_paused == value: return
	connection_paused = value
	if not is_prepared or finished: return
	if value: input_suspended_before_disconnect = battle.hero.player_input_suspended
	battle.hero.set_player_move_input(Vector2.ZERO)
	battle.hero.player_input_suspended = true if value else input_suspended_before_disconnect
	battle.set_external_pause(value or not running)
func _choice(candidates: Array) -> void:
	_hold("hero",candidates,0)
	_enforce_hold_limit("hero")
func _chest_opened() -> void:
	if finished or not is_instance_valid(battle.hero) or battle.hero.player_weapons == null: return
	var runtime = battle.hero.player_weapons
	var receipt: Dictionary = runtime.roll_chest()
	if not runtime.apply_chest(receipt): return
	# The server applies the reward before sending a display-only receipt.
	chest_receipts.append({"serial":int(receipt.serial),"id":String(receipt.id),"kind":String(receipt.kind),"name":String(receipt.name),"description":String(receipt.description),"evolution":bool(receipt.evolution)})
	if chest_receipts.size() > RULES.CHEST_HISTORY_LIMIT: chest_receipts.pop_front()
func _demon_offer(candidates: Array,_rerolls: int,level: int) -> void:
	_hold("demon",candidates,level)
	battle.bank_online_demon_augment()
	_enforce_hold_limit("demon")
func _hold(role: String,candidates: Array,level: int) -> void:
	if finished or candidates.is_empty(): return
	next_offer_number += 1
	var queue: Array = hero_holds if role == "hero" else demon_holds
	var fixed_candidates: Array = candidates.duplicate(true)
	var wire_candidates: Array = _wire_candidates(fixed_candidates)
	queue.append({"number":next_offer_number,"candidates":fixed_candidates,"wire_candidates":wire_candidates,"received":next_offer_number,"level":level})
	choice_revision += 1
	choice = hero_holds[0].candidates if not hero_holds.is_empty() else []
func _wire_candidates(candidates: Array) -> Array:
	var result: Array = []
	for candidate in candidates:
		result.append({"id":String(candidate.get("id","")),"name":String(candidate.get("name","")),"description":String(candidate.get("description",""))})
	return result
func _reroll_held(argument: Dictionary) -> bool:
	var number: Variant = argument.get("number",null)
	if not RULES.number(number) or float(number) != floorf(float(number)): return false
	var runtime = battle.hero.player_weapons
	if runtime == null or runtime.rerolls_remaining() <= 0: return false
	for index in hero_holds.size():
		var offer: Dictionary = hero_holds[index]
		if int(offer.number) != int(number): continue
		var next: Array = runtime.reroll(offer.candidates)
		if next.is_empty(): return false
		offer.candidates = next.duplicate(true)
		offer.wire_candidates = _wire_candidates(offer.candidates)
		hero_holds[index] = offer
		choice_revision += 1
		choice = hero_holds[0].candidates if not hero_holds.is_empty() else []
		return true
	return false
func _enforce_hold_limit(role: String) -> void:
	var queue: Array = hero_holds if role == "hero" else demon_holds
	while queue.size() > RULES.AUGMENT_HOLD_LIMIT:
		var oldest: Dictionary = queue.pop_front()
		for candidate in oldest.candidates:
			if _apply_offer(role,oldest,String(candidate.get("id",""))): break
		choice_revision += 1
		choice = hero_holds[0].candidates if not hero_holds.is_empty() else []
func _apply_offer(role: String,offer: Dictionary,id: String) -> bool:
	for candidate in offer.candidates:
		if String(candidate.get("id","")) == id:
			if role == "hero": return battle.hero.choose_player_augment(id,offer.candidates)
			return battle.choose_held_demon_augment(id,offer.candidates,int(offer.level))
	return false
func _select_offer(role: String,argument: Dictionary) -> bool:
	var number: Variant = argument.get("number",null)
	var id: Variant = argument.get("id",null)
	if not RULES.number(number) or float(number) != floorf(float(number)) or not id is String: return false
	var queue: Array = hero_holds if role == "hero" else demon_holds
	for index in queue.size():
		var offer: Dictionary = queue[index]
		if int(offer.number) != int(number): continue
		queue.remove_at(index)
		if not _apply_offer(role,offer,id):
			queue.insert(index,offer)
			return false
		choice_revision += 1
		choice = hero_holds[0].candidates if not hero_holds.is_empty() else []
		return true
	return false
func apply(role: String,kind: String,argument: Variant) -> bool:
	last_action_message = "사용할 수 없는 행동입니다."
	if not running or finished or connection_paused or not is_instance_valid(battle.hero): return false
	if role == "hero" and kind == "move" and RULES.point(argument,1.0):
		var direction := Vector2(float(argument[0]),float(argument[1]))
		if direction.length_squared() > 1.001: return false
		battle.hero.set_player_move_input(direction); move_age = 0.0; return true
	if role == "hero" and kind == "choose" and argument is Dictionary:
		return _select_offer(role,argument)
	if role == "hero" and kind == "reroll" and argument is Dictionary:
		return _reroll_held(argument)
	if role == "demon" and kind == "summon" and argument is Dictionary:
		# RULES.SUMMON_PLACEMENT: 랭크전 소환은 좌표를 지정한 수동 배치만 허용.
		if not argument.get("id",null) is String: return false
		var id: String = argument.id; var point: Variant = argument.get("point",null)
		if id not in roster or not RULES.point(point): return false
		var accepted: bool = battle.try_summon_at_position(id,Vector2(point[0],point[1]))
		if accepted: feedback.publish("summon",Vector2(point[0],point[1]),0,Color(0.8,0.5,1.0),tick)
		return accepted
	if role == "demon" and kind == "skill" and argument is Dictionary:
		var id: Variant = argument.get("id",null)
		var direction: Variant = argument.get("direction","")
		if not id is String or id not in skill_ids or not direction is String or direction not in ["","east","west","north","south"]: return false
		if argument.has("point") and not RULES.point(argument.point): return false
		var accepted: bool = battle.try_use_demon_ultimate(id,direction)
		if accepted: last_action_message = "마왕 스킬을 사용했습니다."
		return accepted
	if role == "demon" and kind == "demon_choose" and argument is Dictionary:
		return _select_offer(role,argument)
	if role == "demon" and kind == "transcend" and argument is Dictionary:
		var point: Variant = argument.get("point",null)
		if transcendence_id.is_empty() or not RULES.point(point): return false
		var accepted: bool = battle.try_summon_transcendent_at_position(Vector2(point[0],point[1]))
		if accepted: last_action_message = "초월 몬스터를 소환했습니다."
		return accepted
	return false
func step(delta: float) -> void:
	if not running or finished or connection_paused: return
	tick += 1; move_age += delta
	if move_age > RULES.INPUT_TIMEOUT and is_instance_valid(battle.hero): battle.hero.set_player_move_input(Vector2.ZERO)
	if battle.mutation_director.is_active():
		var candidates: Array = battle.mutation_director.get_candidates()
		if not candidates.is_empty(): battle.try_choose_mutation(String(candidates[0]))
func finish(won: String,why: String) -> void:
	if finished: return
	finished = true; running = false; winner = won; reason = why
	hero_holds.clear(); demon_holds.clear(); chest_receipts.clear(); choice = []
	if is_instance_valid(battle): battle.set_external_pause(true)
	completed.emit(winner,reason)
func snapshot(role: String = "") -> Dictionary:
	var profile = battle.get("combat_profile")
	var started: int = Time.get_ticks_usec() if profile != null and profile.enabled else 0
	var state := _build_snapshot()
	if started: profile.record(profile.Scope.NETWORK_SNAPSHOT,started)
	return snapshot_for_role(role,state)
func snapshot_for_role(role: String,state: Dictionary) -> Dictionary:
	var own := state.duplicate()
	if role == "hero":
		own["augment_holds"] = _wire_holds(hero_holds)
		own["chest_receipts"] = chest_receipts.duplicate(true)
		own["hero_inventory"] = _hero_inventory()
	elif role == "demon": own["augment_holds"] = _wire_holds(demon_holds)
	return own
func _hero_inventory() -> Dictionary:
	if not is_instance_valid(battle.hero) or battle.hero.player_weapons == null: return {}
	var hero = battle.hero
	var runtime = hero.player_weapons
	var weapons: Array = []
	var passives: Array = []
	for id in runtime.weapon_ids:
		weapons.append([String(id),int(runtime.levels.get(id,0)),runtime.evolved.has(id)])
	for id in runtime.passives:
		passives.append([String(id),int(runtime.passives[id])])
	return {"level":int(hero.level),"exp":int(hero.current_exp),"exp_next":int(hero.exp_to_next_level),"rerolls_left":runtime.rerolls_remaining(),"reroll_limit":int(runtime.reroll_limit),"weapons":weapons,"passives":passives}
func _wire_holds(queue: Array) -> Array:
	var result: Array = []
	for offer in queue: result.append({"number":offer.number,"candidates":offer.wire_candidates})
	return result

func _feedback(target: Node2D,amount: int,color: Color,healing: bool) -> void:
	if not running or finished or connection_paused: return
	var kind := "heal" if healing else "hero_hit" if target == battle.hero else "monster_hit"
	feedback.publish(kind,target.global_position,amount,Color(1.0,0.45,0.4) if kind=="hero_hit" else color,tick)
func _build_snapshot() -> Dictionary:
	var actors: Array = []; var shots: Array = []
	var visuals: Array = []
	var primitives: Array = []
	var hp := 0; var maximum := 1; var level := 1
	if is_instance_valid(battle.hero):
		hero_last = battle.hero.position; hp = battle.hero.current_hp; maximum = battle.hero.max_hp; level = battle.hero.level
		presentation.append_tree(battle.hero,0,visuals)
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
		presentation.append_tree(actor,int(ids[instance].wire),visuals)
	for id in battle.online_visual_projectiles: presentation.append_tree(battle.online_visual_projectiles[id],-1,visuals)
	if is_instance_valid(battle.hero) and battle.hero.player_weapons != null:
		var weapons = battle.hero.player_weapons
		for shot in weapons.projectiles:
			if not shot.active or shot.melee or shot.delay > 0.0: continue
			if shot.frames.is_empty() or not shot.has("visual_radius"):
				shots.append([snappedf(shot.position.x,0.1),snappedf(shot.position.y,0.1)]); continue
			var radius: float = shot.visual_radius
			presentation.append_texture(weapons._loop_frame(shot.frames,float(shot.age)),-1,Transform2D(Vector2(shot.direction).angle(),shot.position),Rect2(Vector2.ONE*-radius,Vector2.ONE*radius*2),Color.WHITE,visuals,battle.hero.z_index)
		presentation.append_weapon_areas(weapons,visuals)
		primitives = PRIMITIVES.capture(weapons)
		if weapons.native_skills != null:
			for pattern in weapons.native_skills.actors_by_pattern:
				for actor in weapons.native_skills.actors_by_pattern[pattern]:
					if is_instance_valid(actor) and not battle.online_visual_projectiles.has(actor.get_instance_id()): presentation.append_tree(actor,-1,visuals)
	visuals.sort_custom(_visual_order)
	stale_wire_ids.clear()
	for instance in ids:
		if int(ids[instance].seen) != snapshot_revision: stale_wire_ids.append(instance)
	for instance in stale_wire_ids:
		ids.erase(instance); presentation.forget_node(instance)
	var demon_ready := {}
	for id in skill_ids:
		var skill: Dictionary = SKILLS.get_skill(String(id))
		demon_ready[id] = battle.demon_ultimate_spawn_queue.is_empty() and battle.demon_ultimate_charge+0.001 >= float(skill.get("mana_cost",SKILLS.CHARGE_MAX)) and float(battle.demon_ultimate_cooldowns.get(id,0.0)) <= 0.001
	# Bounded snapshot serialization and presentation sort at10Hz, not physics Hz.
	return {"op":"state","tick":tick,"hero":[hero_last.x,hero_last.y,hp,maximum,level],"bounds":[battle.current_map_size.x,battle.current_map_size.y],"battlefield":battlefield_info,"seconds":battle.run_metrics.elapsed_seconds,"mana":battle.command_power,"demon_charge":battle.demon_ultimate_charge,"demon_charge_max":SKILLS.CHARGE_MAX,"demon_cooldowns":battle.demon_ultimate_cooldowns,"demon_ready":demon_ready,"transcend_ready":battle.transcendence.ready and not battle.transcendence.used,"transcend_used":battle.transcendence.used,"actors":actors,"shots":shots,"visuals":visuals,"primitives":primitives,"feedback":feedback.snapshot(),"feedback_cursor":feedback.sequence,"winner":winner,"reason":reason}

func _visual_order(a: Array,b: Array) -> bool:
	return PRESENTATION.visual_order(a,b)
