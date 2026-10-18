extends Node2D
## Bounded telegraphs, four spawns per tick, eight reusable physical walls.
const DATA := preload("res://src/data/hero_mode_catalog.gd")
var battle
var roster: Array = []
var next_event := DATA.EVENT_FIRST
var event_index := 0
var kind := ""
var warning := 0.0
var points: Array[Vector2] = []
var cursor := 0
var walls: Array[StaticBody2D] = []
var wall_time := 0.0
var finale := false
var boss: Node2D
var boss_retry := 0.0
var boss_started := false
var boss_elapsed := 0.0
func boss_remaining() -> float:
	return maxf(0.0,DATA.BOSS_TIME_LIMIT-boss_elapsed)
var notice := ""
func install(host) -> void:
	battle = host
	roster = DATA.roster_for(int(battle.current_stage_data.get("number",1)),battle.campaign_difficulty)
	for index in 8:
		var wall := StaticBody2D.new(); wall.collision_layer = 2; wall.collision_mask = 1
		var shape := CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = Vector2(80,44); shape.shape = rect
		wall.add_child(shape); add_child(wall); shape.disabled = true; wall.hide(); walls.append(wall)
func _clear_walls() -> void:
	wall_time = 0.0; notice = ""
	for wall in walls: wall.hide(); wall.get_child(0).set_deferred("disabled",true)
	queue_redraw()
func tick(delta: float) -> void:
	if battle.battle_over or battle.external_pause: return
	if battle.has_method("is_combat_simulation_paused") and battle.is_combat_simulation_paused(): return
	var clock: float = battle.run_metrics.elapsed_seconds
	if clock >= DATA.DURATION:
		if not finale: finale = true; points.clear(); _clear_walls()
		if boss_started:
			# A lethal hit can queue victory until end-of-frame; it wins over timeout.
			if is_instance_valid(boss) and int(boss.get("current_hp"))<=0: return
			boss_elapsed += maxf(0.0,delta)
			if boss_elapsed >= DATA.BOSS_TIME_LIMIT:
				battle.finish_hero_boss_timeout(); return
		boss_retry -= delta
		if not is_instance_valid(boss) and boss_retry <= 0:
			boss_retry = 3.0
			var stage := int(battle.current_stage_data.get("number",1))
			var spawn_point: Vector2 = DATA.boss_position(battle.hero.position,battle.current_map_size)
			boss = battle.spawn_hero_encounter(DATA.boss_for(stage,battle.campaign_difficulty),spawn_point,DATA.boss_data(stage,battle.campaign_difficulty))
			if is_instance_valid(boss): boss_started = true
			notice = "최종 보스 · 처치하면 클리어" if is_instance_valid(boss) else "보스 출현 대기 · 남은 적을 처치하세요"
		return
	if wall_time > 0:
		wall_time -= delta
		if wall_time <= 0: _clear_walls()
	if points.is_empty() and clock >= next_event:
		kind = String(DATA.EVENT_KINDS[event_index%DATA.EVENT_KINDS.size()])
		var gap_angle := float(event_index)*PI*0.5
		event_index += 1
		next_event = clock+(DATA.OPENING_EVENT_INTERVAL if clock < DATA.OPENING_END else DATA.EVENT_INTERVAL)
		points = DATA.encounter_points(kind,battle.hero.position,battle.current_map_size,DATA.OPENING_EVENT_RADIUS if clock < DATA.OPENING_END else 430.0,gap_angle)
		if battle.has_method("_clamp_manual_spawn_position"):
			var filtered: Array[Vector2] = []
			for point in points:
				var corrected: Vector2 = battle._clamp_manual_spawn_position(point)
				if corrected.distance_squared_to(battle.hero.position) >= 180*180 and corrected not in filtered: filtered.append(corrected)
			points = filtered
		cursor = 0; warning = DATA.EVENT_WARNING
		notice = String(DATA.EVENT_NAMES[kind])+" · 출현 예고"; queue_redraw()
	if points.is_empty(): return
	warning -= delta
	if warning > 0: return
	if kind == "barricade":
		_clear_walls()
		for index in mini(points.size(),walls.size()):
			if points[index].distance_squared_to(battle.hero.position) < 180*180: continue
			walls[index].position = points[index]; walls[index].show(); walls[index].get_child(0).set_deferred("disabled",false)
		wall_time = DATA.BARRIER_SECONDS; points.clear(); notice = "바리케이드 · 열린 통로로 이동하세요"; queue_redraw(); return
	for index in 4:
		if cursor >= points.size(): points.clear(); notice = ""; queue_redraw(); break
		battle.spawn_hero_encounter(String(roster[cursor%roster.size()]),points[cursor],{"type":"encounter","name":DATA.EVENT_NAMES[kind],"hp_multiplier":1.0,"damage_multiplier":1.0,"speed_multiplier":1.0,"exp_multiplier":1.0,"visual_scale":1.0})
		cursor += 1
func _draw() -> void:
	if warning > 0:
		for point in points: draw_arc(point,36,0,TAU,20,Color("edbe65"),3)
	for wall in walls:
		if wall.visible:
			draw_rect(Rect2(wall.position-Vector2(40,22),Vector2(80,44)),Color("66503e"))
			draw_rect(Rect2(wall.position-Vector2(40,22),Vector2(80,44)),Color("d9b56c"),false,3)
