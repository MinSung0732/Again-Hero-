extends RefCounted
class_name EliteMonsterSkillRuntime

const SPIDER_WEB_POOL_KEY := "elite_spider_web"

var battle: Node

var _skill_states: Dictionary = {}
var _stale_skill_ids: Array[int] = []
var _slime_arcs: Array = []
var _spider_webs: Array = []
var _monster_scratch: Array = []

var _spider_web_texture: Texture2D


func setup(authority: Node) -> void:
	battle = authority


func reset() -> void:
	for raw_arc in _slime_arcs:
		if typeof(raw_arc) != TYPE_DICTIONARY:
			continue
		var arc: Dictionary = raw_arc
		var monster = arc.get("monster")
		if is_instance_valid(monster):
			monster.set_meta("elite_skill_movement_lock", false)
			var collision := monster.get_node_or_null(
				"CollisionShape2D"
			) as CollisionShape2D
			if is_instance_valid(collision):
				collision.set_deferred("disabled", false)
	_slime_arcs.clear()

	for raw_web in _spider_webs:
		if typeof(raw_web) != TYPE_DICTIONARY:
			continue
		_recycle_web_visual(Dictionary(raw_web))
	_spider_webs.clear()

	for raw_id in _skill_states:
		var state_value = _skill_states.get(raw_id, {})
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		_cleanup_state(Dictionary(state_value))
	_skill_states.clear()
	_stale_skill_ids.clear()
	_monster_scratch.clear()


func register_elite(
	monster: Node2D,
	monster_id: String,
	raw_skills: Array
) -> void:
	if not is_instance_valid(monster) or raw_skills.is_empty():
		return

	var skills: Array = []
	for raw_skill in raw_skills:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill: Dictionary = Dictionary(raw_skill).duplicate(true)
		skill["_timer"] = maxf(
			float(skill.get("initial_cooldown", 0.0)),
			0.0
		)
		skill["_active"] = false
		skill["_active_timer"] = 0.0
		skills.append(skill)

	if skills.is_empty():
		return

	_skill_states[monster.get_instance_id()] = {
		"monster": monster,
		"monster_id": monster_id,
		"skills": skills,
	}


func tick(delta: float) -> void:
	if not is_instance_valid(battle):
		return

	_tick_slime_arcs(delta)
	_tick_spider_webs(delta)

	_stale_skill_ids.clear()
	for raw_id in _skill_states:
		var state_value = _skill_states.get(raw_id, {})
		if typeof(state_value) != TYPE_DICTIONARY:
			_stale_skill_ids.append(int(raw_id))
			continue

		var state: Dictionary = state_value
		var monster := state.get("monster") as Node2D
		if (
			not is_instance_valid(monster)
			or monster.is_queued_for_deletion()
			or int(monster.get("current_hp")) <= 0
		):
			_cleanup_state(state)
			_stale_skill_ids.append(int(raw_id))
			continue

		var skills_value = state.get("skills", [])
		if typeof(skills_value) != TYPE_ARRAY:
			continue
		var skills: Array = skills_value
		for raw_skill in skills:
			if typeof(raw_skill) != TYPE_DICTIONARY:
				continue
			var skill: Dictionary = raw_skill
			skill["_timer"] = maxf(
				float(skill.get("_timer", 0.0)) - delta,
				0.0
			)

			if bool(skill.get("_active", false)):
				_tick_active_skill(monster, skill, delta)
				continue

			if float(skill.get("_timer", 0.0)) <= 0.0:
				_cast_skill(monster, skill)

	for stale_id in _stale_skill_ids:
		_skill_states.erase(stale_id)
	_stale_skill_ids.clear()


func _cast_skill(monster: Node2D, skill: Dictionary) -> void:
	var skill_id := String(skill.get("id", ""))
	if skill_id.is_empty():
		return

	skill["_timer"] = maxf(float(skill.get("cooldown", 0.0)), 0.01)
	match skill_id:
		"elite_slime_proliferation":
			_begin_slime_proliferation(monster, skill)
		"elite_spider_web_nest":
			_create_spider_web(monster.global_position, skill)
		"elite_orc_frenzy":
			_begin_orc_frenzy(monster, skill)
		"elite_bomb_rat_vibration":
			_begin_bomb_rat_vibration(monster, skill)
		"elite_skeleton_ambush":
			_begin_skeleton_ambush(monster, skill)


func _tick_active_skill(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	match String(skill.get("id", "")):
		"elite_slime_proliferation":
			_tick_slime_proliferation(monster, skill, delta)
		"elite_orc_frenzy":
			_tick_orc_frenzy(monster, skill, delta)
		"elite_bomb_rat_vibration":
			_tick_bomb_rat_vibration(monster, skill, delta)
		"elite_skeleton_ambush":
			_tick_skeleton_ambush(monster, skill, delta)
		_:
			skill["_active"] = false


func _begin_slime_proliferation(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = true
	skill["_remaining"] = maxi(int(skill.get("spawn_count", 12)), 0)
	skill["_spawn_timer"] = 0.0
	_tick_slime_proliferation(monster, skill, 0.0)


func _tick_slime_proliferation(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var remaining := maxi(int(skill.get("_remaining", 0)), 0)
	if remaining <= 0:
		skill["_active"] = false
		return

	var spawn_timer := maxf(
		float(skill.get("_spawn_timer", 0.0)) - delta,
		0.0
	)
	if spawn_timer > 0.0:
		skill["_spawn_timer"] = spawn_timer
		return

	var direction := Vector2.from_angle(randf_range(0.0, TAU))
	var distance := randf_range(
		maxf(float(skill.get("launch_distance_min", 105.0)), 1.0),
		maxf(float(skill.get("launch_distance_max", 190.0)), 1.0)
	)
	var start := monster.global_position + direction * 18.0
	var landing := start + direction * distance
	var child = battle.call(
		"spawn_elite_slime_minion",
		start,
		landing
	)
	if child is Node2D:
		_begin_slime_arc(
			child as Node2D,
			start,
			(child as Node2D).get_meta(
				"elite_arc_landing_position",
				landing
			),
			maxf(float(skill.get("arc_duration", 0.55)), 0.10),
			maxf(float(skill.get("arc_height", 82.0)), 0.0)
		)

	remaining -= 1
	skill["_remaining"] = remaining
	skill["_spawn_timer"] = maxf(
		float(skill.get("spawn_interval", 0.25)),
		0.01
	)
	if remaining <= 0:
		skill["_active"] = false


func _begin_slime_arc(
	monster: Node2D,
	start: Vector2,
	landing: Vector2,
	duration: float,
	height: float
) -> void:
	monster.set_meta("elite_skill_movement_lock", true)
	var collision := monster.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if is_instance_valid(collision):
		collision.set_deferred("disabled", true)
	_slime_arcs.append({
		"monster": monster,
		"start": start,
		"landing": landing,
		"elapsed": 0.0,
		"duration": duration,
		"height": height,
	})


func _tick_slime_arcs(delta: float) -> void:
	for index in range(_slime_arcs.size() - 1, -1, -1):
		var raw_arc = _slime_arcs[index]
		if typeof(raw_arc) != TYPE_DICTIONARY:
			_slime_arcs.remove_at(index)
			continue
		var arc: Dictionary = raw_arc
		var monster := arc.get("monster") as Node2D
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			_slime_arcs.remove_at(index)
			continue

		var duration := maxf(float(arc.get("duration", 0.55)), 0.01)
		var elapsed := minf(float(arc.get("elapsed", 0.0)) + delta, duration)
		arc["elapsed"] = elapsed
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var start: Vector2 = arc.get("start", monster.global_position)
		var landing: Vector2 = arc.get("landing", monster.global_position)
		var height := maxf(float(arc.get("height", 0.0)), 0.0)
		var arc_offset := -4.0 * height * t * (1.0 - t)
		monster.global_position = start.lerp(landing, t) + Vector2(0.0, arc_offset)

		if t + 0.0001 < 1.0:
			continue

		monster.global_position = landing
		monster.set_meta("elite_skill_movement_lock", false)
		var collision := monster.get_node_or_null(
			"CollisionShape2D"
		) as CollisionShape2D
		if is_instance_valid(collision):
			collision.set_deferred("disabled", false)
		_slime_arcs.remove_at(index)


func _create_spider_web(center: Vector2, skill: Dictionary) -> void:
	var fx: Sprite2D
	if battle.has_method("acquire_transient_fx"):
		var pooled = battle.call(
			"acquire_transient_fx",
			SPIDER_WEB_POOL_KEY,
			"sprite"
		)
		if pooled is Sprite2D:
			fx = pooled as Sprite2D

	var effect_path := String(skill.get("effect_path", ""))
	if _spider_web_texture == null and not effect_path.is_empty():
		_spider_web_texture = ResourceLoader.load(effect_path) as Texture2D

	var radius := maxf(float(skill.get("radius", 250.0)), 1.0)
	if is_instance_valid(fx):
		fx.global_position = center
		fx.z_index = -1
		fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fx.texture = _spider_web_texture
		fx.modulate = Color(1.0, 1.0, 1.0, 0.86)
		if _spider_web_texture != null:
			var source_diameter := maxf(
				float(maxi(
					_spider_web_texture.get_width(),
					_spider_web_texture.get_height()
				)),
				1.0
			)
			var scale_value := radius * 2.0 / source_diameter
			fx.scale = Vector2.ONE * scale_value

	_spider_webs.append({
		"center": center,
		"radius": radius,
		"remaining": maxf(float(skill.get("duration", 5.0)), 0.01),
		"tick_timer": 0.0,
		"tick_interval": maxf(float(skill.get("tick_interval", 0.20)), 0.05),
		"hero_slow_multiplier": clampf(
			float(skill.get("hero_slow_multiplier", 0.50)),
			0.01,
			1.0
		),
		"monster_speed_multiplier": maxf(
			float(skill.get("monster_speed_multiplier", 1.15)),
			1.0
		),
		"fx": fx,
	})


func _tick_spider_webs(delta: float) -> void:
	for index in range(_spider_webs.size() - 1, -1, -1):
		var raw_web = _spider_webs[index]
		if typeof(raw_web) != TYPE_DICTIONARY:
			_spider_webs.remove_at(index)
			continue
		var web: Dictionary = raw_web
		var remaining := maxf(float(web.get("remaining", 0.0)) - delta, 0.0)
		web["remaining"] = remaining
		if remaining <= 0.0:
			_recycle_web_visual(web)
			_spider_webs.remove_at(index)
			continue

		var tick_timer := maxf(float(web.get("tick_timer", 0.0)) - delta, 0.0)
		if tick_timer > 0.0:
			web["tick_timer"] = tick_timer
			continue

		var tick_interval := maxf(float(web.get("tick_interval", 0.20)), 0.05)
		web["tick_timer"] = tick_interval
		var center: Vector2 = web.get("center", Vector2.ZERO)
		var radius := maxf(float(web.get("radius", 250.0)), 1.0)
		var radius_sq := radius * radius

		var hero := battle.get("hero") as Node2D
		if (
			is_instance_valid(hero)
			and center.distance_squared_to(hero.global_position) <= radius_sq
			and hero.has_method("apply_slow")
		):
			hero.call(
				"apply_slow",
				float(web.get("hero_slow_multiplier", 0.50)),
				tick_interval * 1.35
			)

		_monster_scratch.clear()
		if battle.has_method("fill_monsters_near"):
			battle.call(
				"fill_monsters_near",
				center,
				radius,
				_monster_scratch
			)
		var speed_multiplier := maxf(
			float(web.get("monster_speed_multiplier", 1.15)),
			1.0
		)
		var buff_until := Time.get_ticks_msec() + int(round(
			tick_interval * 1.50 * 1000.0
		))
		for raw_monster in _monster_scratch:
			if not is_instance_valid(raw_monster):
				continue
			var monster := raw_monster as Node2D
			if monster == null:
				continue
			if center.distance_squared_to(monster.global_position) > radius_sq:
				continue
			monster.set_meta(
				"elite_spider_web_speed_multiplier",
				maxf(
					float(monster.get_meta(
						"elite_spider_web_speed_multiplier",
						1.0
					)),
					speed_multiplier
				)
			)
			monster.set_meta(
				"elite_spider_web_speed_until",
				maxi(
					int(monster.get_meta(
						"elite_spider_web_speed_until",
						0
					)),
					buff_until
				)
			)
		_monster_scratch.clear()


func _recycle_web_visual(web: Dictionary) -> void:
	var fx = web.get("fx")
	if (
		is_instance_valid(fx)
		and is_instance_valid(battle)
		and battle.has_method("recycle_transient_fx")
	):
		battle.call("recycle_transient_fx", fx, SPIDER_WEB_POOL_KEY)


func _begin_orc_frenzy(monster: Node2D, skill: Dictionary) -> void:
	skill["_active"] = true
	skill["_active_timer"] = maxf(
		float(skill.get("max_charge_duration", 2.5)),
		0.10
	)
	monster.set_meta("elite_skill_movement_lock", true)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		visual.modulate = Color(1.0, 0.30, 0.30, 1.0)


func _tick_orc_frenzy(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero):
		_finish_orc_frenzy(monster, skill)
		return

	var active_timer := maxf(
		float(skill.get("_active_timer", 0.0)) - delta,
		0.0
	)
	skill["_active_timer"] = active_timer
	if active_timer <= 0.0:
		_finish_orc_frenzy(monster, skill)
		return

	var offset := hero.global_position - monster.global_position
	var distance_sq := offset.length_squared()
	var hit_radius := maxf(float(monster.get("attack_range")), 1.0)
	if distance_sq <= hit_radius * hit_radius:
		if monster.has_method("_visual_call"):
			monster.call("_visual_call", &"play_attack")
		var attack_damage := maxi(int(monster.get("attack_damage")), 1)
		var damage := maxi(
			int(round(
				float(attack_damage)
				* float(skill.get("damage_multiplier", 1.50))
			)),
			1
		)
		if hero.has_method("take_damage"):
			hero.call("take_damage", damage, monster)
		if hero.has_method("apply_slow"):
			hero.call(
				"apply_slow",
				float(skill.get("slow_multiplier", 0.01)),
				maxf(float(skill.get("slow_duration", 1.0)), 0.05)
			)
		_finish_orc_frenzy(monster, skill)
		return

	if distance_sq <= 0.001:
		return
	var direction := offset.normalized()
	var speed := maxf(float(monster.get("move_speed")), 1.0)
	var speed_multiplier := maxf(
		float(skill.get("charge_speed_multiplier", 5.0)),
		1.0
	)
	monster.global_position += direction * speed * speed_multiplier * delta
	if monster.has_method("_update_visual_motion"):
		monster.call("_update_visual_motion", direction.x, true)


func _finish_orc_frenzy(monster: Node2D, skill: Dictionary) -> void:
	skill["_active"] = false
	skill["_active_timer"] = 0.0
	if not is_instance_valid(monster):
		return
	monster.set_meta("elite_skill_movement_lock", false)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
	if monster.has_method("_update_visual_motion"):
		monster.call("_update_visual_motion", 0.0, false)


func _begin_bomb_rat_vibration(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = true
	skill["_active_timer"] = maxf(float(skill.get("duration", 4.0)), 0.05)
	monster.set_meta("elite_vibration_speed_active", true)
	monster.set_meta(
		"elite_vibration_speed_multiplier",
		maxf(float(skill.get("move_speed_multiplier", 3.0)), 1.0)
	)
	var shield_max := maxi(
		int(round(
			float(maxi(int(monster.get("max_hp")), 1))
			* maxf(
				float(skill.get("shield_max_hp_multiplier", 1.50)),
				0.0
			)
		)),
		0
	)
	monster.set_meta("elite_shield_max_hp", shield_max)
	monster.set_meta("elite_shield_hp", shield_max)
	if monster.has_method("queue_redraw"):
		monster.call("queue_redraw")


func _tick_bomb_rat_vibration(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var active_timer := maxf(
		float(skill.get("_active_timer", 0.0)) - delta,
		0.0
	)
	skill["_active_timer"] = active_timer
	if active_timer > 0.0:
		return
	skill["_active"] = false
	if is_instance_valid(monster):
		monster.set_meta("elite_vibration_speed_active", false)


func _begin_skeleton_ambush(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = true
	skill["_active_timer"] = maxf(
		float(skill.get("duration", 2.0)),
		0.05
	)
	monster.set_meta("elite_skeleton_ambush_active", true)
	monster.set_meta(
		"elite_skeleton_ambush_damage_taken_multiplier",
		clampf(float(skill.get("damage_taken_multiplier", 0.50)), 0.0, 1.0)
	)
	monster.set_meta(
		"elite_skeleton_ambush_attack_multiplier",
		maxf(float(skill.get("attack_damage_multiplier", 1.50)), 1.0)
	)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		var opacity := clampf(float(skill.get("opacity", 0.32)), 0.05, 1.0)
		visual.modulate = Color(0.38, 0.42, 0.55, opacity)


func _tick_skeleton_ambush(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	if not bool(monster.get_meta("elite_skeleton_ambush_active", false)):
		skill["_active"] = false
		skill["_active_timer"] = 0.0
		return
	var active_timer := maxf(
		float(skill.get("_active_timer", 0.0)) - delta,
		0.0
	)
	skill["_active_timer"] = active_timer
	if active_timer > 0.0:
		return
	_finish_skeleton_ambush(monster, skill)


func _finish_skeleton_ambush(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = false
	skill["_active_timer"] = 0.0
	if not is_instance_valid(monster):
		return
	monster.set_meta("elite_skeleton_ambush_active", false)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE


func _cleanup_state(state: Dictionary) -> void:
	var monster := state.get("monster") as Node2D
	var skills_value = state.get("skills", [])
	if typeof(skills_value) != TYPE_ARRAY:
		return
	for raw_skill in skills_value:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill: Dictionary = raw_skill
		match String(skill.get("id", "")):
			"elite_orc_frenzy":
				if bool(skill.get("_active", false)):
					_finish_orc_frenzy(monster, skill)
			"elite_bomb_rat_vibration":
				if is_instance_valid(monster):
					monster.set_meta("elite_vibration_speed_active", false)
			"elite_skeleton_ambush":
				if bool(skill.get("_active", false)):
					_finish_skeleton_ambush(monster, skill)
