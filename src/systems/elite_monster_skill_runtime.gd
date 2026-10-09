extends RefCounted
class_name EliteMonsterSkillRuntime
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const SPIDER_WEB_POOL_KEY := "elite_spider_web"
const SKELETON_ARCHER_RAIN_LINE_POOL_KEY := "elite_skeleton_archer_rain_line"
const SKELETON_ARCHER_RAIN_ARROW_POOL_KEY := "elite_skeleton_archer_rain_arrow"
const GOBLIN_COMMANDER_AURA_POOL_KEY := "elite_goblin_commander_aura"
const GOBLIN_THROWER_BOMB_POOL_KEY := "goblin_thrower_elite_bomb"
const GOBLIN_THROWER_BOMB_SCENE := preload(
	"res://src/monsters/GoblinThrowerBomb.tscn"
)

var battle: Node

var _skill_states: Dictionary = {}
var _stale_skill_ids: Array[int] = []
var _slime_arcs: Array = []
var _spider_webs: Array = []
var _skeleton_archer_rain_arrows: Array = []
var _monster_scratch: Array = []

var _spider_web_texture: Texture2D
var _skeleton_archer_rain_arrow_texture: Texture2D
var _skeleton_archer_rain_arrow_texture_path: String = ""


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

	for raw_arrow in _skeleton_archer_rain_arrows:
		if typeof(raw_arrow) != TYPE_DICTIONARY:
			continue
		_recycle_skeleton_archer_rain_arrow(Dictionary(raw_arrow))
	_skeleton_archer_rain_arrows.clear()

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
		if bool(skill.get("passive", false)):
			_activate_passive_skill(monster, skill)
			if bool(skill.get("runtime_tick", false)):
				skill["_timer"] = 0.0
				skill["_active"] = true
				skill["_active_timer"] = 0.0
				skills.append(skill)
			continue
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


func _activate_passive_skill(
	monster: Node2D,
	skill: Dictionary
) -> void:
	if String(skill.get("runtime", "")) == "monster" and monster.has_method("configure_elite_passive"):
		monster.call("configure_elite_passive", skill)
		return
	match String(skill.get("id", "")):
		"elite_bat_poison_fang":
			monster.set_meta("elite_bat_poison_fang_active", true)
			monster.set_meta(
				"elite_bat_poison_duration",
				maxf(float(skill.get("duration", 3.0)), 0.1)
			)
			monster.set_meta(
				"elite_bat_poison_hp_ratio",
				maxf(
					float(skill.get("total_current_hp_ratio", 0.05)),
					0.0
				)
			)
			monster.set_meta(
				"elite_bat_poison_tick_interval",
				maxf(float(skill.get("tick_interval", 0.50)), 0.05)
			)
		"elite_goblin_commander":
			_begin_goblin_commander(monster, skill)


func tick(delta: float) -> void:
	if not is_instance_valid(battle):
		return

	_tick_slime_arcs(delta)
	_tick_spider_webs(delta)
	_tick_skeleton_archer_rain_arrows(delta)

	_stale_skill_ids.clear()
	for raw_id in _skill_states:
		var state_value = _skill_states.get(raw_id, {})
		if typeof(state_value) != TYPE_DICTIONARY:
			_stale_skill_ids.append(int(raw_id))
			continue

		var state: Dictionary = state_value
		var monster_value = state.get("monster")
		var monster: Node2D = monster_value if is_instance_valid(monster_value) else null
		if (
			not is_instance_valid(monster)
			or monster.is_queued_for_deletion()
		):
			_cleanup_state(state)
			_stale_skill_ids.append(int(raw_id))
			continue

		var current_hp_value = monster.get("current_hp")
		if current_hp_value != null and int(current_hp_value) <= 0:
			if bool(monster.get_meta("elite_skill_reviving", false)):
				continue
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
	if String(skill.get("id", "")).is_empty() or bool(skill.get("_used", false)): return
	if not skill.has("_pending_status_action"):
		skill["_pending_status_action"] = STATUS_SCOPE.Token.new()
	skill["_status_action"] = skill["_pending_status_action"]
	var previous_action := STATUS_SCOPE.begin(battle.get("hero") as Node,skill["_status_action"])
	_status_scoped_cast_skill(monster,skill)
	STATUS_SCOPE.finish(battle.get("hero") as Node,previous_action)
	if float(skill.get("_timer",0.0)) > 0.0 or bool(skill.get("_active",false)):
		skill.erase("_pending_status_action")

func _status_scoped_cast_skill(monster: Node2D, skill: Dictionary) -> void:
	var skill_id := String(skill.get("id", ""))
	if skill_id.is_empty():
		return
	if bool(skill.get("_used", false)):
		return
	if String(skill.get("runtime", "")) == "monster":
		if monster.has_method("try_cast_elite_skill") and bool(monster.call("try_cast_elite_skill", skill)):
			battle.get_node("/root/GameAudio").play_battle("elite_skill", battle)
			skill["_timer"] = maxf(float(skill.get("cooldown", 0.0)), 0.01)
			skill["_used"] = bool(skill.get("once", false))
		else:
			skill["_timer"] = maxf(float(skill.get("retry_interval", 0.0)), 0.0)
		return

	# A blocked possession retains readiness; it does not spend HP/cooldown.
	if skill_id == "elite_banshee_possession":
		var target := battle.get("hero") as Node2D
		if not is_instance_valid(target) or not target.has_method("can_receive_possession") or not bool(target.call("can_receive_possession")):
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
		"elite_skeleton_archer_arrow_rain":
			_begin_skeleton_archer_arrow_rain(monster, skill)
		"elite_kobolt_fighting_spirit":
			_begin_kobolt_fighting_spirit(monster, skill)
		"elite_ghost_fear":
			_cast_ghost_fear(monster, skill)
		"elite_banshee_possession":
			var target := battle.get("hero") as Node2D
			var cost := int(round(float(monster.get("max_hp")) * float(skill.get("self_max_hp_cost", 0.20))))
			monster.set("current_hp", maxi(int(monster.get("current_hp")) - cost, 1))
			target.call("apply_fear", monster, float(skill.get("duration", 2.0)), 1.0)
			monster.queue_redraw()
		"elite_goblin_thrower_bombardment":
			_begin_goblin_thrower_bombardment(monster, skill)
		_:
			return
	battle.get_node("/root/GameAudio").play_battle("elite_skill", battle)


func _tick_active_skill(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var previous_action := STATUS_SCOPE.begin(battle.get("hero") as Node,skill.get("_status_action"))
	_status_scoped_tick_active_skill(monster,skill,delta)
	STATUS_SCOPE.finish(battle.get("hero") as Node,previous_action)

func _status_scoped_tick_active_skill(
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
		"elite_skeleton_archer_arrow_rain":
			_tick_skeleton_archer_arrow_rain(monster, skill, delta)
		"elite_kobolt_fighting_spirit":
			_tick_kobolt_fighting_spirit(monster, skill, delta)
		"elite_goblin_commander":
			_tick_goblin_commander(monster, skill, delta)
		"elite_goblin_thrower_bombardment":
			_tick_goblin_thrower_bombardment(monster, skill, delta)
		_:
			skill["_active"] = false




func _begin_goblin_thrower_bombardment(
	monster: Node2D,
	skill: Dictionary
) -> void:
	if not is_instance_valid(battle):
		return
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero):
		return
	skill["_active"] = true
	skill["_remaining_bombs"] = maxi(
		int(skill.get("bomb_count", 10)),
		1
	)
	skill["_bomb_timer"] = 0.0
	skill["_center"] = hero.global_position
	_tick_goblin_thrower_bombardment(monster, skill, 0.0)


func _tick_goblin_thrower_bombardment(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var remaining := maxi(
		int(skill.get("_remaining_bombs", 0)),
		0
	)
	if remaining <= 0:
		skill["_active"] = false
		return

	var bomb_timer := maxf(
		float(skill.get("_bomb_timer", 0.0)) - delta,
		0.0
	)
	if bomb_timer > 0.0:
		skill["_bomb_timer"] = bomb_timer
		return

	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero):
		skill["_active"] = false
		return
	if not battle.has_method("acquire_projectile"):
		skill["_active"] = false
		return

	var pooled = battle.call(
		"acquire_projectile",
		GOBLIN_THROWER_BOMB_SCENE,
		GOBLIN_THROWER_BOMB_POOL_KEY
	)
	if pooled is Area2D:
		var bomb := pooled as Area2D
		var center: Vector2 = skill.get(
			"_center",
			hero.global_position
		)
		var radius := maxf(
			float(skill.get("radius", 110.0)),
			1.0
		)
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * radius
		var landing := (
			center
			+ Vector2.from_angle(angle) * distance
		)
		var damage := maxi(
			int(round(
				float(maxi(int(monster.get("attack_damage")), 1))
				* maxf(
					float(skill.get("damage_multiplier", 1.50)),
					0.0
				)
			)),
			1
		)
		bomb.call(
			"setup",
			monster.global_position,
			landing,
			damage,
			maxf(float(skill.get("projectile_speed", 650.0)), 1.0),
			maxf(float(skill.get("fuse_duration", 1.0)), 0.05),
			maxf(float(skill.get("explosion_radius", 52.0)), 1.0),
			monster,
			hero
		)

	remaining -= 1
	skill["_remaining_bombs"] = remaining
	if remaining <= 0:
		skill["_active"] = false
		return
	skill["_bomb_timer"] = maxf(
		float(skill.get("bomb_interval", 0.15)),
		0.01
	)

func _cast_ghost_fear(
	monster: Node2D,
	skill: Dictionary
) -> void:
	if not is_instance_valid(battle):
		return
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero) or not hero.has_method("apply_fear"):
		return
	hero.call(
		"apply_fear",
		monster,
		maxf(float(skill.get("duration", 1.5)), 0.05),
		maxf(float(skill.get("move_speed_multiplier", 1.50)), 1.0)
	)

func _begin_goblin_commander(monster: Node2D, skill: Dictionary) -> void:
	skill["_active"] = true
	skill["_tick_timer"] = 0.0
	skill["_shield_timer"] = 0.0
	skill["_line_fx"] = _create_goblin_commander_aura(monster, skill)


func _create_goblin_commander_aura(
	monster: Node2D,
	skill: Dictionary
) -> Line2D:
	if not is_instance_valid(battle) or not battle.has_method("acquire_transient_fx"):
		return null
	var pooled = battle.call("acquire_transient_fx", GOBLIN_COMMANDER_AURA_POOL_KEY, "line")
	if not (pooled is Line2D):
		return null
	var line := pooled as Line2D
	line.clear_points()
	line.global_position = monster.global_position
	line.z_index = 1
	line.width = maxf(float(skill.get("line_width", 2.0)), 1.0)
	line.default_color = Color(0.48, 0.92, 0.42, 0.72)
	line.antialiased = false
	var radius := maxf(float(skill.get("radius", 300.0)), 1.0)
	var segments := maxi(int(skill.get("line_segments", 48)), 16)
	for index in range(segments + 1):
		var angle := TAU * float(index) / float(segments)
		line.add_point(Vector2.from_angle(angle) * radius)
	return line


func _tick_goblin_commander(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	if not is_instance_valid(monster):
		return

	var line := skill.get("_line_fx") as Line2D
	if is_instance_valid(line):
		line.global_position = monster.global_position

	var aura_timer := maxf(float(skill.get("_tick_timer", 0.0)) - delta, 0.0)
	var shield_timer := maxf(float(skill.get("_shield_timer", 0.0)) - delta, 0.0)
	skill["_tick_timer"] = aura_timer
	skill["_shield_timer"] = shield_timer
	if aura_timer > 0.0 and shield_timer > 0.0:
		return

	var radius := maxf(float(skill.get("radius", 300.0)), 1.0)
	var radius_sq := radius * radius
	var aura_interval := maxf(float(skill.get("aura_tick_interval", 0.20)), 0.05)
	var refresh_shield := shield_timer <= 0.0
	if aura_timer <= 0.0:
		skill["_tick_timer"] = aura_interval
	if refresh_shield:
		skill["_shield_timer"] = maxf(
			float(skill.get("shield_refresh_interval", 5.0)),
			0.10
		)

	_monster_scratch.clear()
	if battle.has_method("fill_monsters_near"):
		battle.call("fill_monsters_near", monster.global_position, radius, _monster_scratch)

	var speed_multiplier := maxf(float(skill.get("speed_multiplier", 1.15)), 1.0)
	var speed_until := Time.get_ticks_msec() + int(round(aura_interval * 1.50 * 1000.0))
	var shield_ratio := maxf(float(skill.get("shield_max_hp_ratio", 0.10)), 0.0)

	for raw_monster in _monster_scratch:
		var target := raw_monster as Node2D
		if (
			not is_instance_valid(target)
			or target.is_queued_for_deletion()
			or String(target.get_meta("monster_family", "")) != "goblin"
		):
			continue
		var hp_value = target.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if monster.global_position.distance_squared_to(target.global_position) > radius_sq:
			continue

		target.set_meta("elite_goblin_commander_speed_until", speed_until)
		target.set_meta("elite_goblin_commander_speed_multiplier", speed_multiplier)
		if refresh_shield and shield_ratio > 0.0:
			var max_hp_value = target.get("max_hp")
			if max_hp_value != null:
				var shield_amount := maxi(
					int(round(float(max_hp_value) * shield_ratio)),
					1
				)
				target.set_meta("elite_shield_max_hp", shield_amount)
				target.set_meta("elite_shield_hp", shield_amount)
				if target.has_method("queue_redraw"):
					target.call("queue_redraw")
	_monster_scratch.clear()


func _finish_goblin_commander(skill: Dictionary) -> void:
	var line := skill.get("_line_fx") as Line2D
	if (
		is_instance_valid(line)
		and is_instance_valid(battle)
		and battle.has_method("recycle_transient_fx")
	):
		battle.call("recycle_transient_fx", line, GOBLIN_COMMANDER_AURA_POOL_KEY)
	skill["_line_fx"] = null
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
		"status_action":skill["_status_action"] if skill.has("_status_action") else STATUS_SCOPE.Token.new(),
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
			var previous_action := STATUS_SCOPE.begin(hero,web.get("status_action"))
			hero.call(
				"apply_slow",
				float(web.get("hero_slow_multiplier", 0.50)),
				tick_interval * 1.35
			)
			STATUS_SCOPE.finish(hero,previous_action)

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


func _begin_kobolt_fighting_spirit(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = true
	skill["_active_timer"] = maxf(
		float(skill.get("duration", 5.0)),
		0.05
	)
	monster.set_meta("elite_kobolt_fighting_spirit_active", true)
	monster.set_meta(
		"elite_kobolt_fighting_spirit_attack_speed_multiplier",
		maxf(float(skill.get("attack_speed_multiplier", 1.60)), 1.0)
	)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		var tint: Color = skill.get(
			"tint",
			Color(1.0, 0.68, 0.68, 1.0)
		)
		visual.modulate = tint


func _tick_kobolt_fighting_spirit(
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
	_finish_kobolt_fighting_spirit(monster, skill)


func _finish_kobolt_fighting_spirit(
	monster: Node2D,
	skill: Dictionary
) -> void:
	skill["_active"] = false
	skill["_active_timer"] = 0.0
	if not is_instance_valid(monster):
		return
	monster.set_meta("elite_kobolt_fighting_spirit_active", false)
	var visual := monster.get_node_or_null("Visual") as CanvasItem
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE


func _begin_skeleton_archer_arrow_rain(
	monster: Node2D,
	skill: Dictionary
) -> void:
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero):
		return
	skill["_active"] = true
	skill["_center"] = hero.global_position
	skill["_remaining_waves"] = maxi(int(skill.get("wave_count", 3)), 1)
	skill["_wave_index"] = 0
	skill["_wave_timer"] = maxf(
		float(skill.get("telegraph_delay", 0.25)),
		0.0
	)
	skill["_line_fx"] = _create_skeleton_archer_rain_line(
		hero.global_position,
		skill
	)


func _tick_skeleton_archer_arrow_rain(
	monster: Node2D,
	skill: Dictionary,
	delta: float
) -> void:
	var remaining := maxi(int(skill.get("_remaining_waves", 0)), 0)
	if remaining <= 0:
		_finish_skeleton_archer_arrow_rain(skill)
		return

	var wave_timer := maxf(
		float(skill.get("_wave_timer", 0.0)) - delta,
		0.0
	)
	if wave_timer > 0.0:
		skill["_wave_timer"] = wave_timer
		return

	var center: Vector2 = skill.get("_center", monster.global_position)
	var radius := maxf(float(skill.get("radius", 137.5)), 1.0)
	var wave_index := maxi(int(skill.get("_wave_index", 0)), 0)
	_spawn_skeleton_archer_rain_visuals(center, radius, skill)
	_apply_skeleton_archer_rain_hit(
		monster,
		center,
		radius,
		skill,
		wave_index
	)

	remaining -= 1
	skill["_remaining_waves"] = remaining
	skill["_wave_index"] = wave_index + 1
	if remaining <= 0:
		_finish_skeleton_archer_arrow_rain(skill)
		return
	skill["_wave_timer"] = maxf(
		float(skill.get("wave_interval", 0.35)),
		0.01
	)


func _create_skeleton_archer_rain_line(
	center: Vector2,
	skill: Dictionary
) -> Line2D:
	if not battle.has_method("acquire_transient_fx"):
		return null
	var pooled = battle.call(
		"acquire_transient_fx",
		SKELETON_ARCHER_RAIN_LINE_POOL_KEY,
		"line"
	)
	if not (pooled is Line2D):
		return null
	var line := pooled as Line2D
	line.clear_points()
	line.global_position = center
	line.z_index = 5
	line.width = maxf(float(skill.get("line_width", 2.0)), 1.0)
	line.default_color = Color(0.95, 0.78, 0.42, 0.78)
	var radius := maxf(float(skill.get("radius", 137.5)), 1.0)
	var segments := maxi(int(skill.get("line_segments", 32)), 12)
	for index in range(segments + 1):
		var angle := TAU * float(index) / float(segments)
		line.add_point(Vector2.from_angle(angle) * radius)
	return line


func _spawn_skeleton_archer_rain_visuals(
	center: Vector2,
	radius: float,
	skill: Dictionary
) -> void:
	var texture := _get_skeleton_archer_rain_arrow_texture(skill)
	if texture == null:
		return
	var arrow_count := maxi(int(skill.get("arrows_per_wave", 12)), 1)
	var fall_distance := maxf(
		float(skill.get("arrow_fall_distance", 170.0)),
		1.0
	)
	var fall_duration := maxf(
		float(skill.get("arrow_fall_duration", 0.22)),
		0.05
	)
	var source_size := maxf(
		float(maxi(texture.get_width(), texture.get_height())),
		1.0
	)
	var target_size := maxf(float(skill.get("arrow_target_size", 52.0)), 1.0)
	var visual_scale := target_size / source_size

	for index in range(arrow_count):
		if not battle.has_method("acquire_transient_fx"):
			break
		var pooled = battle.call(
			"acquire_transient_fx",
			SKELETON_ARCHER_RAIN_ARROW_POOL_KEY,
			"sprite"
		)
		if not (pooled is Sprite2D):
			continue
		var sprite := pooled as Sprite2D
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * radius
		var landing := center + Vector2.from_angle(angle) * distance
		var start := landing + Vector2(0.0, -fall_distance)
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.global_position = start
		sprite.rotation = PI * 0.5
		sprite.scale = Vector2.ONE * visual_scale
		sprite.modulate = Color.WHITE
		sprite.z_index = 6
		_skeleton_archer_rain_arrows.append({
			"sprite": sprite,
			"start": start,
			"landing": landing,
			"elapsed": 0.0,
			"duration": fall_duration,
		})


func _tick_skeleton_archer_rain_arrows(delta: float) -> void:
	for index in range(_skeleton_archer_rain_arrows.size() - 1, -1, -1):
		var raw_arrow = _skeleton_archer_rain_arrows[index]
		if typeof(raw_arrow) != TYPE_DICTIONARY:
			_skeleton_archer_rain_arrows.remove_at(index)
			continue
		var arrow: Dictionary = raw_arrow
		var sprite := arrow.get("sprite") as Sprite2D
		if not is_instance_valid(sprite):
			_skeleton_archer_rain_arrows.remove_at(index)
			continue
		var duration := maxf(float(arrow.get("duration", 0.22)), 0.01)
		var elapsed := minf(float(arrow.get("elapsed", 0.0)) + delta, duration)
		arrow["elapsed"] = elapsed
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var start: Vector2 = arrow.get("start", sprite.global_position)
		var landing: Vector2 = arrow.get("landing", sprite.global_position)
		sprite.global_position = start.lerp(landing, t)
		if t + 0.0001 < 1.0:
			continue
		_recycle_skeleton_archer_rain_arrow(arrow)
		_skeleton_archer_rain_arrows.remove_at(index)


func _apply_skeleton_archer_rain_hit(
	monster: Node2D,
	center: Vector2,
	radius: float,
	skill: Dictionary,
	wave_index: int
) -> void:
	var previous_action := STATUS_SCOPE.begin(battle.get("hero") as Node,skill.get("_status_action"))
	_status_scoped_apply_skeleton_archer_rain_hit(monster,center,radius,skill,wave_index)
	STATUS_SCOPE.finish(battle.get("hero") as Node,previous_action)

func _status_scoped_apply_skeleton_archer_rain_hit(
	monster: Node2D,
	center: Vector2,
	radius: float,
	skill: Dictionary,
	wave_index: int
) -> void:
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero):
		return
	if center.distance_squared_to(hero.global_position) > radius * radius:
		return
	var damage := maxi(
		int(round(
			float(maxi(int(monster.get("attack_damage")), 1))
			* maxf(float(skill.get("damage_multiplier", 1.30)), 0.0)
		)),
		1
	)
	var damage_applied := false
	if wave_index > 0 and hero.has_method("take_followup_damage"):
		damage_applied = bool(hero.call(
			"take_followup_damage",
			damage,
			monster
		))
	elif hero.has_method("take_damage"):
		damage_applied = bool(hero.call("take_damage", damage, monster))
	if damage_applied and hero.has_method("apply_slow"):
		hero.call(
			"apply_slow",
			clampf(float(skill.get("slow_multiplier", 0.75)), 0.01, 1.0),
			maxf(float(skill.get("slow_duration", 1.0)), 0.05)
		)


func _get_skeleton_archer_rain_arrow_texture(
	skill: Dictionary
) -> Texture2D:
	var path := String(skill.get("arrow_texture_path", ""))
	if path.is_empty():
		return null
	if (
		_skeleton_archer_rain_arrow_texture != null
		and _skeleton_archer_rain_arrow_texture_path == path
	):
		return _skeleton_archer_rain_arrow_texture
	_skeleton_archer_rain_arrow_texture = ResourceLoader.load(path) as Texture2D
	_skeleton_archer_rain_arrow_texture_path = path
	return _skeleton_archer_rain_arrow_texture


func _recycle_skeleton_archer_rain_arrow(arrow: Dictionary) -> void:
	var sprite = arrow.get("sprite")
	if (
		is_instance_valid(sprite)
		and is_instance_valid(battle)
		and battle.has_method("recycle_transient_fx")
	):
		battle.call(
			"recycle_transient_fx",
			sprite,
			SKELETON_ARCHER_RAIN_ARROW_POOL_KEY
		)


func _finish_skeleton_archer_arrow_rain(skill: Dictionary) -> void:
	skill["_active"] = false
	skill["_remaining_waves"] = 0
	skill["_wave_timer"] = 0.0
	var line = skill.get("_line_fx")
	if (
		is_instance_valid(line)
		and is_instance_valid(battle)
		and battle.has_method("recycle_transient_fx")
	):
		battle.call(
			"recycle_transient_fx",
			line,
			SKELETON_ARCHER_RAIN_LINE_POOL_KEY
		)
	skill["_line_fx"] = null


func _cleanup_state(state: Dictionary) -> void:
	var monster_value = state.get("monster")
	var monster: Node2D = monster_value if is_instance_valid(monster_value) else null
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
			"elite_skeleton_archer_arrow_rain":
				if bool(skill.get("_active", false)):
					_finish_skeleton_archer_arrow_rain(skill)
			"elite_kobolt_fighting_spirit":
				if bool(skill.get("_active", false)):
					_finish_kobolt_fighting_spirit(monster, skill)
			"elite_goblin_commander":
				_finish_goblin_commander(skill)
