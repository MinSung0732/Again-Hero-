extends Node
## Authoritative adapter over the shipped Battle/Hero/monster/weapon code.
const RULES := preload("res://src/online/match_rules.gd")
const SKILLS := preload("res://src/data/demon_ultimate_catalog.gd")
const PRESENTATION := preload("res://src/online/presentation_snapshot.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const FIELD_INTERVAL := 0.25
const MUTATIONS := preload("res://src/data/mutation_catalog.gd")
var presentation = PRESENTATION.new()
var exp_orb_visuals = preload("res://src/online/exp_orb_registry.gd").new()
var battlefield_info := {}
var field_areas: Array = []
var field_fx: Array = []
var field_elapsed := 0.0
var field_attack_bonus := 0.0
var field_damage_fraction := 0.0
var field_heal_fraction := 0.0
var last_hero_level := 1
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
var selected_hero_augments: Array[String] = []
var public_hero_build: Dictionary = {}
var public_hero_build_dirty := true
var demon_holds: Array = []
var elite_cards: Array = []
var elite_pending: Array = []
var hero_kills := 0
var next_elite_kills := 0
var elite_every_kills := 0
var next_elite_serial := 0
var demon_augment_hint_counts: Dictionary = {}
var public_demon_hints: Dictionary = {"augment_hints":[]}
var public_demon_hints_dirty := true
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
var map_id := "plaza"
func set_loadouts(hero_loadout: Dictionary,demon_loadout: Dictionary) -> void:
	hero_id = String(hero_loadout.hero_id)
	roster = demon_loadout.team_ids.duplicate()
	skill_ids = demon_loadout.skill_ids.duplicate()
	transcendence_id = String(demon_loadout.transcendence_id)
func prepare() -> void:
	var map_data: Dictionary = MAPS.get_map(map_id)
	if map_data.is_empty(): finish("","invalid_map"); return
	configure_elite_thresholds(map_data.elite)
	world = SubViewport.new(); world.world_2d = World2D.new(); world.size = Vector2i(1080,1600)
	world.render_target_update_mode = SubViewport.UPDATE_DISABLED; add_child(world)
	var scene: PackedScene = load("res://src/battle/Battle.tscn")
	if scene == null: finish("","battle_load_failed"); return
	battle = scene.instantiate(); battle.online_match_mode = true
	battle.child_entered_tree.connect(presentation.track_field_item)
	battle.set_meta(preload("res://src/battle/exp_orb.gd").ONLINE_REGISTRY_META,exp_orb_visuals)
	battle.combat_popup_visuals_enabled = false
	battle.online_match_rules = {"roster":roster,"skill_ids":skill_ids,"transcendence_id":transcendence_id}
	battle.hero_player_mode = true; battle.hero_player_stage = String(map_data.stage_visual); battle.hero_player_hero_id = hero_id
	world.add_child(battle); battle.set_external_pause(true)
	battle.current_map_size = map_data.map_size
	battle.hero.configure_battlefield(battle.current_map_size)
	battle.hero.position = battle.current_map_size * 0.5
	var field = battle.get_node_or_null("Stage1Battlefield")
	if field != null:
		field.configure(battle.current_stage_id,battle.current_map_size,map_data.theme)
		field_areas = field.effect_areas
	battle.run_time_limit_seconds = float(map_data.duration_seconds)
	battle.run_metrics.reset(battle.run_time_limit_seconds,int(battle.hero.current_hp),int(battle.hero.max_hp))
	var modifiers: Dictionary = map_data.modifiers
	battle.hero.exp_gain_multiplier *= float(modifiers.get("hero_exp_multiplier",1.0))
	battle.command_power = RULES.OPENING_MANA
	battle.command_regen_per_second = RULES.MANA_PER_SECOND * float(modifiers.get("command_regen_multiplier",1.0))
	battle.set_allowed_monster_ids(roster)
	battlefield_info = {"stage":battle.current_stage_id,"bounds":[battle.current_map_size.x,battle.current_map_size.y],"map":map_id,"theme":map_data.theme}
	battle.online_visual_entity_exited.connect(presentation.forget_node)
	battle.online_combat_feedback.connect(_feedback)
	battle.online_cast_feedback.connect(func(cue: String,point: Vector2):
		if running and not finished and not connection_paused: feedback.publish(cue,point,0,Color.WHITE,tick))
	battle.demon_ultimate_used.connect(func(_id: String,_name: String,_message: String):
		if running and not finished and not connection_paused: feedback.publish("ultimate",battle.hero.position,0,Color(0.8,0.5,1.0),tick))
	battle.transcendent_summoned.connect(func(_id: String,actor: Node2D):
		if running and not finished and not connection_paused and is_instance_valid(actor): feedback.publish("transcend",actor.global_position,0,Color(1.0,0.75,0.35),tick))
	battle.demon_augment_ready.connect(_demon_offer)
	battle.online_hero_kill.connect(_on_hero_kill)
	battle.online_elite_requested.connect(_queue_elite)

	battle.battle_finished.connect(func(_message: String,demon_won: bool): finish("demon" if demon_won else "hero",_message))
	battle.hero.player_augment_requested.connect(_choice)
	battle.hero.augment_selected.connect(func(_level: int,_candidates: Array,chosen_name: String,_reason: String,_summary: String):
		selected_hero_augments.append(chosen_name)
		public_hero_build_dirty = true
		_refresh_hero_holds())
	battle.hero.progression_changed.connect(func(_level: int,_exp: int,_next: int): public_hero_build_dirty = true)
	battle.hero.progression_changed.connect(func(level: int,_exp: int,_next: int):
		if level > last_hero_level and running and not finished and not connection_paused:
			feedback.publish("level_up", battle.hero.position, level, Color.WHITE, tick)
		last_hero_level = level)
	last_hero_level = battle.hero.level
	battle.hero_chest_opened.connect(_chest_opened)
	battle.summon_result.connect(func(_id: String,_accepted: bool,message: String): last_action_message = message)
	is_prepared = true
func configure_elite_thresholds(config: Dictionary) -> void:
	next_elite_kills = maxi(1,int(config.first_kills))
	elite_every_kills = maxi(1,int(config.every_kills))
func _on_hero_kill() -> void:
	if not running or finished: return
	hero_kills += 1
	if hero_kills >= next_elite_kills:
		next_elite_kills += elite_every_kills
		_queue_elite(MUTATIONS.RANKED_KILL_EVENT)
func _queue_elite(event: Dictionary) -> void:
	if finished: return
	elite_pending.append(event)
	_open_pending_elite()
func _open_pending_elite() -> void:
	if finished or elite_pending.is_empty() or elite_cards.size() >= RULES.ELITE_CARD_LIMIT or battle.mutation_director.is_active(): return
	battle.online_open_mutation_choice(elite_pending[0])
	if battle.mutation_director.is_active(): elite_pending.pop_front()
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
	public_hero_build_dirty = true
	_refresh_hero_holds()
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
	# Offers are capped to what the client validates and can display.
	var fixed_candidates: Array = candidates.slice(0,RULES.MAX_OFFER_CANDIDATES).duplicate(true)
	var wire_candidates: Array = _wire_candidates(fixed_candidates)
	queue.append({"number":next_offer_number,"candidates":fixed_candidates,"wire_candidates":wire_candidates,"received":next_offer_number,"level":level})
	choice_revision += 1
	choice = hero_holds[0].candidates if not hero_holds.is_empty() else []
func _wire_candidates(candidates: Array) -> Array:
	var result: Array = []
	for candidate in candidates:
		var wire := {"id":String(candidate.get("id","")),"name":String(candidate.get("name","")),"description":String(candidate.get("description",""))}
		var comparison: Array = []
		for raw_row in candidate.get("compare",[]):
			if comparison.size() >= RULES.MAX_COMPARE_ROWS: break
			if not raw_row is Dictionary: continue
			var row: Dictionary = raw_row
			comparison.append({"label":String(row.get("label","")).substr(0,RULES.MAX_COMPARE_FIELD_LENGTH),"current":String(row.get("current","")).substr(0,RULES.MAX_COMPARE_FIELD_LENGTH),"next":String(row.get("next","")).substr(0,RULES.MAX_COMPARE_FIELD_LENGTH)})
		wire["compare"] = comparison
		for field in ["augment_type","monster_id","target_monster_id","current_stack","max_stack"]:
			if candidate.has(field): wire[field] = candidate[field]
		if bool(candidate.get("unavailable",false)): wire["unavailable"] = true
		result.append(wire)
	return result
# Held hero cards keep their ids but re-read level text after the build changes. A card that can no
# longer be taken is shown as unavailable; an offer with nothing left is replaced without spending a reroll.
func _refresh_hero_holds() -> void:
	var runtime = battle.hero.player_weapons
	if runtime == null or hero_holds.is_empty(): return
	var changed := false
	for index in hero_holds.size():
		var offer: Dictionary = hero_holds[index]
		var refreshed: Array = []
		var ids: Array = []
		var available := 0
		for candidate in offer.candidates:
			var id := String(candidate.get("id",""))
			ids.append(id)
			var card: Dictionary = runtime.offer_card(id)
			if card.is_empty(): card = {"id":id,"name":String(candidate.get("name","")),"description":RULES.UNAVAILABLE_AUGMENT_TEXT,"unavailable":true}
			else: available += 1
			refreshed.append(card)
		if available == 0: refreshed = runtime.candidates(ids)
		refreshed = refreshed.slice(0,RULES.MAX_OFFER_CANDIDATES)
		if refreshed == offer.candidates: continue
		offer.candidates = refreshed.duplicate(true)
		offer.wire_candidates = _wire_candidates(offer.candidates)
		hero_holds[index] = offer
		changed = true
	if changed:
		choice_revision += 1
		choice = hero_holds[0].candidates

func _refresh_demon_holds() -> void:
	var changed := false
	for index in demon_holds.size():
		var offer: Dictionary = demon_holds[index]
		var available := 0
		for candidate in offer.candidates:
			var id := String(candidate.get("id",""))
			var stacks := int(battle.demon_build_counts.get(id,0))
			var special := String(candidate.get("augment_type","")) == DEMON_AUGMENTS.TYPE_SPECIAL
			var maximum := int(candidate.get("max_stack",0))
			var selectable: bool = DEMON_AUGMENTS.can_acquire_special(id,battle.demon_special_augments) if special else maximum <= 0 or stacks < maximum
			candidate["current_stack"] = stacks
			candidate["compare"] = DEMON_AUGMENTS.compare(candidate,stacks)
			if selectable:
				candidate.erase("unavailable")
				available += 1
			else:
				candidate["unavailable"] = true
		# An older held offer may be exhausted by another pick (including exclusive
		# special groups). Refresh it without spending the player's reroll budget.
		if available == 0:
			var previous_level: int = battle.demon_active_augment_level
			var previous_ids: Array[String] = battle.demon_last_candidate_ids.duplicate()
			battle.demon_active_augment_level = int(offer.level)
			var replacement: Array = battle._roll_demon_augment_candidates(false)
			battle.demon_active_augment_level = previous_level
			battle.demon_last_candidate_ids = previous_ids
			if not replacement.is_empty(): offer.candidates = replacement.slice(0,RULES.MAX_OFFER_CANDIDATES).duplicate(true)
		offer.wire_candidates = _wire_candidates(offer.candidates)
		demon_holds[index] = offer
		changed = true
	if changed: choice_revision += 1
func _reroll_held(role: String,argument: Dictionary) -> bool:
	var number: Variant = argument.get("number",null)
	if not RULES.number(number) or float(number) != floorf(float(number)): return false
	var runtime = battle.hero.player_weapons
	if role == "hero" and (runtime == null or runtime.rerolls_remaining() <= 0): return false
	var queue: Array = hero_holds if role == "hero" else demon_holds
	for index in queue.size():
		var offer: Dictionary = queue[index]
		if int(offer.number) != int(number): continue
		# Each side spends its own solo reroll budget (research bonus is 0 in ranked).
		var next: Array = runtime.reroll(offer.candidates) if role == "hero" else battle.reroll_held_demon_augment(offer.candidates,int(offer.level))
		if next.is_empty(): return false
		offer.candidates = next.slice(0,RULES.MAX_OFFER_CANDIDATES).duplicate(true)
		offer.wire_candidates = _wire_candidates(offer.candidates)
		queue[index] = offer
		if role == "hero":
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
			if bool(candidate.get("unavailable",false)): return false
			if role == "hero": return battle.hero.choose_player_augment(id,offer.candidates)
			if not battle.choose_held_demon_augment(id,offer.candidates,int(offer.level)): return false
			var hint := _demon_augment_hint(DEMON_AUGMENTS.get_augment(id))
			demon_augment_hint_counts[hint] = int(demon_augment_hint_counts.get(hint,0)) + 1
			public_demon_hints_dirty = true
			_refresh_demon_holds()
			return true
	return false
func _demon_augment_hint(augment: Dictionary) -> String:
	var target := String(augment.get("target_type",""))
	if RULES.TARGET_HINT_LABELS.has(target): return String(RULES.TARGET_HINT_LABELS[target])
	var monster_id := String(augment.get("target_monster_id",augment.get("monster_id","")))
	if monster_id.is_empty(): return String(RULES.TARGET_HINT_LABELS.all_monsters)
	var monster: Dictionary = MONSTERS.get_monster(monster_id)
	if RULES.HINT_DETAIL == "monster": return "%s 강화" % String(monster.get("name","몬스터"))
	var effects: Dictionary = augment.get("effect_values",{})
	var role := String(augment.get("role_override",effects.get("role_override",monster.get("role",""))))
	return "%s 강화" % String(RULES.ROLE_HINT_LABELS.get(role,MONSTERS.get_role_label(role)))
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
	if kind == "reroll" and argument is Dictionary:
		return _reroll_held(role,argument)
	if role == "demon" and kind == "elite_choose" and argument is Dictionary:
		var id: Variant = argument.get("id",null)
		if not id is String or not battle.mutation_director.is_active() or id not in battle.mutation_director.get_candidates(): return false
		if elite_cards.size() >= RULES.ELITE_CARD_LIMIT: return false
		var card: Dictionary = battle.online_hold_mutation(id)
		if card.is_empty(): return false
		next_elite_serial += 1; card["serial"] = next_elite_serial; elite_cards.append(card)
		_open_pending_elite()
		return true
	if role == "demon" and kind == "elite_summon" and argument is Dictionary:
		var serial: Variant = argument.get("serial",null)
		var x: Variant = argument.get("x",null); var y: Variant = argument.get("y",null)
		if not RULES.number(serial) or float(serial) != floorf(float(serial)) or not RULES.point([x,y]): return false
		var point := Vector2(float(x),float(y))
		if not battle.is_spawn_position_valid(point): return false
		for index in elite_cards.size():
			var card: Dictionary = elite_cards[index]
			if int(card.serial) == int(serial):
				if not battle._spawn_selected_mutation(card.id,card.event,point): return false
				elite_cards.remove_at(index); _open_pending_elite(); return true
		return false
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
	if field_areas.is_empty(): return
	field_elapsed += delta
	if field_elapsed >= FIELD_INTERVAL:
		field_elapsed = fmod(field_elapsed, FIELD_INTERVAL)
		_update_field_effects()

func _update_field_effects() -> void:
	if not is_instance_valid(battle.hero): return
	var hero = battle.hero
	field_fx.clear()
	if hero.current_hp > 0 and not hero.is_dying:
		for area in field_areas:
			if hero.position.distance_squared_to(area.position) <= area.radius * area.radius and not field_fx.has(area.id):
				field_fx.append(area.id)
	var move_multiplier := 1.0
	var attack_bonus := 0.0
	var damage_rate := 0.0
	var heal_rate := 0.0
	for id in field_fx:
		var effect: Dictionary = THEMES.EFFECTS[id]
		if effect.target != "hero": continue
		match effect.stat:
			"move_speed": move_multiplier *= 1.0 + float(effect.value)
			"attack_speed": attack_bonus += float(effect.value)
			"damage_per_second": damage_rate += float(effect.value)
			"heal_per_second": heal_rate += float(effect.value)
	hero.set_meta("field_move_multiplier",move_multiplier)
	hero.common_attack_speed_bonus += attack_bonus - field_attack_bonus
	field_attack_bonus = attack_bonus
	field_damage_fraction = field_damage_fraction + float(hero.max_hp) * damage_rate * FIELD_INTERVAL if damage_rate > 0.0 else 0.0
	field_heal_fraction = field_heal_fraction + float(hero.max_hp) * heal_rate * FIELD_INTERVAL if heal_rate > 0.0 else 0.0
	var damage := int(field_damage_fraction)
	var healing := int(field_heal_fraction)
	field_damage_fraction -= damage; field_heal_fraction -= healing
	if damage > 0: hero.take_status_damage(damage)
	if healing > 0 and not finished and hero.current_hp > 0: hero.heal_direct(healing)
func finish(won: String,why: String) -> void:
	if finished: return
	finished = true; running = false; winner = won; reason = why
	field_fx.clear()
	if is_instance_valid(battle) and is_instance_valid(battle.hero):
		battle.hero.set_meta("field_move_multiplier",1.0)
		battle.hero.common_attack_speed_bonus -= field_attack_bonus
	field_attack_bonus = 0.0
	hero_holds.clear(); demon_holds.clear(); elite_cards.clear(); elite_pending.clear(); chest_receipts.clear(); choice = []
	if is_instance_valid(battle): battle.set_external_pause(true)
	completed.emit(winner,reason)
func snapshot(role: String = "") -> Dictionary:
	var profile = battle.get("combat_profile")
	var started: int = Time.get_ticks_usec() if profile != null and profile.enabled else 0
	var state := _build_snapshot()
	if not field_fx.is_empty(): state["field_fx"] = field_fx.duplicate()
	if started: profile.record(profile.Scope.NETWORK_SNAPSHOT,started)
	return snapshot_for_role(role,state)
func snapshot_for_role(role: String,state: Dictionary) -> Dictionary:
	var own := state.duplicate()
	if role == "hero":
		own.erase("demon_charge")
		own.erase("demon_charge_max")
		own.erase("demon_cooldowns")
		own.erase("demon_ready")
		own.erase("summon_costs")
		own.erase("demon_level")
		own.erase("demon_rerolls_left")
		own.erase("demon_reroll_limit")
		own.erase("demon_exp")
		own.erase("demon_exp_next")
		own.erase("transcend_ready")
		own.erase("transcend_used")
		own["augment_holds"] = _wire_holds(hero_holds)
		own["chest_receipts"] = chest_receipts.duplicate(true)
		own["hero_inventory"] = _hero_inventory()
		if public_demon_hints_dirty:
			var hints: Array = []
			for hint in demon_augment_hint_counts:
				var count := int(demon_augment_hint_counts[hint])
				hints.append("%s x%d" % [hint,count] if count > 1 else hint)
			public_demon_hints = {"augment_hints":hints}
			public_demon_hints_dirty = false
		own["demon_hints"] = public_demon_hints
	elif role == "demon":
		own["elite_choice"] = {"candidates": battle.mutation_director.get_candidates() if battle.mutation_director.is_active() else []}
		var cards: Array = []
		for card in elite_cards: cards.append([card.serial,card.id])
		own["elite_cards"] = cards
		own["elite_pending"] = elite_pending.size()
		own["augment_holds"] = _wire_holds(demon_holds)
		if public_hero_build_dirty:
			public_hero_build = _public_hero_build()
			public_hero_build_dirty = false
		own["hero_build"] = public_hero_build
	return own
func _public_hero_build() -> Dictionary:
	var inventory := _hero_inventory()
	if inventory.is_empty(): return {}
	return {"level":inventory.level,"weapons":inventory.weapons,"passives":inventory.passives,"augments":selected_hero_augments.duplicate()}
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
	for offer in queue: result.append({"number":offer.number,"level":offer.level,"candidates":offer.wire_candidates})
	return result

func _feedback(target: Node2D,amount: int,color: Color,healing: bool,critical: bool) -> void:
	if not running or finished or connection_paused: return
	var kind := "heal" if healing else "hero_hit" if target == battle.hero else "monster_hit"
	feedback.publish(kind,target.global_position,amount,color,tick,target.get_instance_id(),critical)
func _build_snapshot() -> Dictionary:
	var actors: Array = []; var shots: Array = []
	var visuals: Array = []
	var primitives: Array = []
	var hp := 0; var maximum := 1; var level := 1
	if is_instance_valid(battle.hero):
		hero_last = battle.hero.position; hp = battle.hero.current_hp; maximum = battle.hero.max_hp; level = battle.hero.level
		presentation.append_tree(battle.hero,0,visuals)
	# Reserve field-item commands before crowd/projectile presentation can fill the cap.
	presentation.append_field_items(visuals)
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
		actors.append([ids[instance].wire,String(actor.get("monster_type")),snappedf(actor.position.x,0.1),snappedf(actor.position.y,0.1),int(actor.get("current_hp")),int(actor.get("max_hp")),_monster_bars(actor)])
		presentation.append_tree(actor,int(ids[instance].wire),visuals)
	for id in battle.online_visual_projectiles: presentation.append_tree(battle.online_visual_projectiles[id],-1,visuals)
	for pool_key in battle.transient_fx_pools:
		for effect in battle.transient_fx_pools[pool_key]:
			if effect is Node2D and is_instance_valid(effect) and effect.visible:
				presentation.append_tree(effect,-1,visuals)
	if is_instance_valid(battle.hero) and battle.hero.player_weapons != null:
		var weapons = battle.hero.player_weapons
		for shot in weapons.projectiles:
			if not shot.active or shot.melee or shot.delay > 0.0: continue
			if shot.frames.is_empty():
				var shot_color: Color = shot.color
				shots.append([snappedf(shot.position.x,0.1),snappedf(shot.position.y,0.1),float(shot.get("visual_radius",28.0)),shot_color.r,shot_color.g,shot_color.b,shot_color.a]); continue
			var radius: float = shot.visual_radius
			presentation.append_texture(weapons._loop_frame(shot.frames,float(shot.age)),-1,Transform2D(Vector2(shot.direction).angle(),shot.position),Rect2(Vector2.ONE*-radius,Vector2.ONE*radius*2),Color.WHITE,visuals,battle.hero.z_index)
		presentation.append_weapon_areas(weapons,visuals)
		primitives = PRIMITIVES.capture(weapons)
		if weapons.native_skills != null:
			for pattern in weapons.native_skills.actors_by_pattern:
				for actor in weapons.native_skills.actors_by_pattern[pattern]:
					if is_instance_valid(actor) and not battle.online_visual_projectiles.has(actor.get_instance_id()): presentation.append_tree(actor,-1,visuals)
	presentation.append_field_item_bars(primitives)
	visuals.sort_custom(_visual_order)
	stale_wire_ids.clear()
	for instance in ids:
		if int(ids[instance].seen) != snapshot_revision: stale_wire_ids.append(instance)
	for instance in stale_wire_ids:
		ids.erase(instance); presentation.forget_node(instance)
	var demon_ready := {}
	var summon_costs := {}
	for id in roster: summon_costs[id] = battle.get_monster_cost(String(id))
	for id in skill_ids:
		var skill: Dictionary = SKILLS.get_skill(String(id))
		demon_ready[id] = battle.demon_ultimate_spawn_queue.is_empty() and battle.demon_ultimate_charge+0.001 >= float(skill.get("mana_cost",SKILLS.CHARGE_MAX)) and float(battle.demon_ultimate_cooldowns.get(id,0.0)) <= 0.001
	# Bounded snapshot serialization and presentation sort at10Hz, not physics Hz.
	return {"op":"state","tick":tick,"hero":[hero_last.x,hero_last.y,hp,maximum,level,_hero_bars()],"hero_archetype":String(battle.hero.hero_archetype) if is_instance_valid(battle.hero) else "","bounds":[battle.current_map_size.x,battle.current_map_size.y],"battlefield":battlefield_info,"seconds":battle.run_metrics.elapsed_seconds,"mana":battle.command_power,"summon_costs":summon_costs,"demon_level":battle.demon_level,"demon_rerolls_left":battle.demon_rerolls_left,"demon_reroll_limit":battle.demon_reroll_max,"demon_exp":battle.demon_exp,"demon_exp_next":battle.demon_exp_to_next_level,"demon_charge":battle.demon_ultimate_charge,"demon_charge_max":SKILLS.CHARGE_MAX,"demon_cooldowns":battle.demon_ultimate_cooldowns,"demon_ready":demon_ready,"transcend_ready":battle.transcendence.ready and not battle.transcendence.used,"transcend_used":battle.transcendence.used,"actors":actors,"exp_orbs":exp_orb_visuals.snapshot(),"shots":shots,"visuals":visuals,"primitives":primitives,"feedback":feedback.snapshot(),"feedback_cursor":feedback.sequence,"winner":winner,"reason":reason}

func _hero_bars() -> Array:
	var hero = battle.hero
	if not is_instance_valid(hero): return [0,0,0,0,0,-79,-64,-49]
	var painter = preload("res://src/ui/battle_bar_painter.gd")
	var presentation = preload("res://src/data/hero_presentation_catalog.gd")
	var rule: Dictionary = presentation.get_status_resource(hero.hero_archetype)
	var kind := 1 if rule["kind"] == &"cells" else 0
	var value := 0
	var capacity := 0
	if kind == 1:
		capacity = int(hero.call(rule["capacity_method"])) if rule.has("capacity_method") else int(hero.get(rule["capacity_property"]))
		value = int(hero._get_status_displayed_cells(rule,capacity))
	else:
		var maximum: float
		if rule.has("max_property"):
			maximum = maxf(float(hero.get(rule["max_property"])),float(rule["minimum_max"]))
		else:
			var config: Dictionary = hero.get(rule["config_property"])
			maximum = maxf(float(config.get(rule["max_key"],rule["default_max"])),float(rule["minimum_max"]))
		value = painter.quantize(float(hero.get(rule["value_property"]))/maximum)
	var shield := painter.quantize(hero.shield_hp/maxf(hero.shield_max_hp,1.0)) if hero.shield_hp > 0.0 else 0
	var layout: Vector4 = presentation.get_status_layout(hero.hero_archetype)
	var resource_y := layout.y
	var hp_y := layout.z
	var shield_y := layout.w
	if hero.player_controlled and hero.player_weapons != null and hero.player_weapons.identity != null:
		resource_y = hero.player_weapons.identity.status_resource_y
		hp_y = hero.player_weapons.identity.status_hp_y
		shield_y = hero.player_weapons.identity.status_shield_y
	return [painter.quantize(float(hero.current_hp)/maxf(float(hero.max_hp),1.0)),shield,kind,value,capacity,int(resource_y),int(hp_y),int(shield_y)]

func _monster_bars(actor: Node2D) -> Array:
	var painter = preload("res://src/ui/battle_bar_painter.gd")
	var common = preload("res://src/monsters/monster_runtime_common.gd")
	var layout = preload("res://src/data/monster_bar_layout_catalog.gd")
	var yellow := common.get_yellow_ratio(actor,layout.gauge_capacity(actor))
	var y: float = layout.y(actor)
	var canvas := actor.get_node_or_null("StatusLayer") as Node2D
	if canvas == null: canvas = actor
	var bars := [painter.quantize(float(actor.get("current_hp"))/maxf(float(actor.get("max_hp")),1.0)),painter.quantize(yellow) if yellow >= 0.0 else -1,int(round(y)),clampi(int(round(absf(canvas.global_scale.x)*100.0)),1,1024),clampi(int(round(absf(canvas.global_scale.y)*100.0)),1,1024)]
	var order: Array = common.sync_bar_order(actor)
	for kind in order:
		var kind_index: int = painter.SHIELD_KINDS.find(kind)
		if kind_index < 0: continue
		bars.append(kind_index)
		bars.append(painter.quantize(common.shield_value(actor,kind)/maxf(common.shield_value(actor,kind,true),1.0)))
	return bars

func _visual_order(a: Array,b: Array) -> bool:
	return PRESENTATION.visual_order(a,b)
