extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const REEL := preload("res://src/ui/hero_chest_reel.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
var checks := 0
var failures := 0
class Target extends Node2D:
	var current_hp := 1000000
	var max_hp := 1000000
	func take_damage(amount: int) -> bool: current_hp -= amount; return true
class Arena extends Node2D:
	var actors: Array = []
	var generation := 1
	func get_battle_entity_handle(actor: Node) -> Vector3i: return Vector3i(actors.find(actor)+1,generation,1)
	func resolve_battle_entity(handle: Vector3i) -> Node:
		return actors[handle.x-1] if handle.y == generation and handle.x > 0 and handle.x <= actors.size() else null
class Fighter extends Node2D:
	signal health_changed(current: int, maximum: int)
	var hero_id := "ranged_rookie"
	var build_counts: Dictionary = {}
	var max_hp := 1200
	var current_hp := 600
	var attack_damage := 100
	var move_speed := 270.0
	var exp_pickup_radius := 150.0
	var exp_gain_multiplier := 1.0
	var player_move_input := Vector2.RIGHT
	var hero_sprite: AnimatedSprite2D
	var attack_pose_timer := 0.0
	var shield_hp := 0.0
	var silence_timer := 0.0
	var imposed_skill_cooldown := 0.0
	var petrify_timer := 0.0
	var poison_timer := 0.0
	var poison_tick_timer := 0.0
	var poison_damage_remaining := 0
	var poison_ticks_remaining := 0
	var poison_source: Node
	var damage_poison_tracker: Dictionary = {}
	var burn_runtime: Dictionary = {}
	var slow_timer := 0.0
	var move_multiplier := 1.0
	func _fill_monster_nodes_near(origin: Vector2, radius: float, output: Array) -> void:
		output.clear()
		for actor in get_parent().actors:
			# Deliberately broad, like Battle's padded spatial grid.
			output.append(actor)
	func heal_direct(amount: int) -> int: current_hp = mini(current_hp+amount,max_hp); return amount
	func _damage_treasure_chests(_origin: Vector2, _radius: float, _damage: int) -> void: pass
	func _face_attack_direction(_x: float) -> void: pass
	func _set_poison_flash(_active: bool) -> void: pass
	func get_paralysis_attack_multiplier() -> float: return 1.0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("HERO_PRESENTATION_RANGE: "+message)
func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("again-hero-"+name+".png"))
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://hero_presentation_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	# Every cell must contain a complete, centered symbol with clear edge padding.
	var ids: Array = DATA.WEAPONS.keys(); ids.append_array(DATA.PASSIVES.keys())
	for id in ids:
		var icon := ICONS.texture(String(id)) as AtlasTexture
		# Unique v2 weapon icons (icon_index_v2) use 64px cells; the original sheets use 128px.
		var cell := 64 if DATA.WEAPONS.get(id,{}).has("icon_index_v2") else 128
		check(icon != null and icon.region.size == Vector2(cell,cell) and icon.filter_clip,"normalized cached atlas: "+String(id))
		var image := icon.atlas.get_image().get_region(Rect2i(icon.region))
		var used := image.get_used_rect()
		var pad := cell*9/128
		check(Rect2i(pad,pad,cell-2*pad,cell-2*pad).encloses(used) and used.has_area(),"entire icon fits with padding: "+String(id))
		check(Rect2(used).get_center().distance_to(Vector2(cell,cell)*0.5) <= 2.0*cell/128,"icon centered: "+String(id))
		check(ICONS.texture(String(id)) == icon,"texture reused: "+String(id))
	# All 60 items, each possible slot and upgrade/evolution/recovery landing.
	for owner in CHARACTERS.ORDER:
		var pool: Array = DATA.weapon_pool(String(owner)).slice(0,3)
		for id in DATA.weapon_pool(String(owner)):
			for mode in 2:
				var owned := pool.duplicate(); owned[0] = id
				var receipt := {"id":id,"name":String(DATA.WEAPONS[id].evolution) if mode else String(DATA.WEAPONS[id].name)+" Lv.2"}
				var reel := REEL.new(); root.add_child(reel); reel.size = Vector2(844,258); reel.configure(owned,receipt)
				reel.advance(0.91); reel.advance(0.999); reel.advance(1)
				check(reel.displayed_id == id and reel.center_label.text == receipt.name,"receipt is exact landing: "+String(id))
				# Card reel (2026-10-14/16): five reusable cards; the landed center card fills the fixed marker.
				check(reel.cards[REEL.CENTER_SLOT].get_rect() == reel._selection_rect() and reel.get_child_count() == REEL.CARD_COUNT,"stable center row / bounded side animation nodes")
				reel.free()
	for size in range(1,4):
		var pool: Array = DATA.weapon_pool().slice(0,size)
		for id in pool:
			var reel := REEL.new(); root.add_child(reel); reel.configure(pool,{"id":id,"name":String(id)})
			reel.advance(1); check(reel.displayed_id == id,"all owned slot indices land correctly"); reel.free()
		var reel := REEL.new(); root.add_child(reel); reel.configure(pool,{"id":"survival_restore","name":"생명의 축복"})
		reel.advance(1); check(reel.displayed_id == "survival_restore" and reel.center_label.text == "생명의 축복","recovery has its own actual landing"); reel.free()
	# Radial detection cannot accept an actor outside the rendered radius.
	for id in DATA.WEAPONS:
		var data: Dictionary = DATA.WEAPONS[id]
		for rank in [1,10]:
			for evolution in [false,true]:
				var radius := GEOMETRY.reach(data,rank,evolution)
				check(not GEOMETRY.contains(String(data.pattern),Vector2(radius+0.1,0),Vector2.RIGHT,radius,rank,data),"outer boundary rejects: "+String(id))
	var radius := 400.0; var half_angle := acos(GEOMETRY.SLASH_DOT)
	check(GEOMETRY.contains("slash",Vector2.from_angle(half_angle-0.001)*390,Vector2.RIGHT,radius,1,{}),"slash includes visible edge")
	check(not GEOMETRY.contains("slash",Vector2.from_angle(half_angle+0.001)*390,Vector2.RIGHT,radius,1,{}),"slash excludes outside edge")
	check(GEOMETRY.contains("beam",Vector2(200,44.9),Vector2.RIGHT,radius,1,{}),"beam uses full displayed half width")
	check(not GEOMETRY.contains("beam",Vector2(200,45.1),Vector2.RIGHT,radius,1,{}),"beam width outside rejected")
	for point in GEOMETRY.beam(radius,45): check(point.length() <= radius+0.001 and absf(point.y) <= 45.001,"beam outline inside hit strip and circle")
	for distance in [179.9,180.1,379.9,380.1]:
		check(GEOMETRY.contains("orbit",Vector2(distance,0),Vector2.RIGHT,radius,1,{}) == (distance >= 180 and distance <= 380),"ring uses drawn inner/outer bounds")
	actual_hits()
	await actual_ui()
	print("HERO_PRESENTATION_RANGE_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
func actual_hits() -> void:
	var arena := Arena.new(); root.add_child(arena)
	var hero := Fighter.new(); arena.add_child(hero)
	var anchor := Target.new(); arena.add_child(anchor); arena.actors.append(anchor)
	var boundary := Target.new(); arena.add_child(boundary); arena.actors.append(boundary)
	for id in DATA.WEAPONS:
		var data: Dictionary = DATA.WEAPONS[id]; var pattern := String(data.pattern)
		if pattern not in ["slash","beam","orbit","nova","frost","guard","heal"]: continue
		# Persistent delivery emitters (2026-10-15: lob/sigil/orbit/bombard...) hit over time
		# through their own slot radius; hero_survival_variety/hero_weapon_remake cover them.
		if not RUNTIME.DELIVERY.RULES.spec(String(id),data).is_empty(): continue
		hero.hero_id = String(data.owner)
		var runtime := RUNTIME.new(); runtime.install(hero)
		runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add(String(id))
		var radius := GEOMETRY.reach(data,1,false)
		anchor.position = Vector2(20,0)
		var inside := Vector2(radius-1,0); var outside := Vector2(radius+1,0)
		if pattern == "slash":
			inside = Vector2.from_angle(acos(GEOMETRY.SLASH_DOT)-0.001)*(radius-1)
			outside = Vector2.from_angle(acos(GEOMETRY.SLASH_DOT)+0.001)*(radius-1)
		elif pattern == "beam":
			inside = Vector2(radius*0.5,GEOMETRY.beam_half_width(1)-0.01)
			outside = Vector2(radius*0.5,GEOMETRY.beam_half_width(1)+0.01)
			var lines := mini(5,int(data.get("fan_lines",1)))
			if lines > 1:
				# Fan beams fire rays 0.32 rad apart; probe the outer edge of the outermost ray.
				var aim := Vector2.RIGHT.rotated(-(lines-1)*0.5*0.32)
				var outward := aim.rotated(-PI/2)
				inside = aim*radius*0.5+outward*(GEOMETRY.beam_half_width(1)-0.01)
				outside = aim*radius*0.5+outward*(GEOMETRY.beam_half_width(1)+0.01)
		elif pattern == "orbit":
			inside = Vector2(GEOMETRY.orbit_outer(radius,float(data.get("orbit_ratio",0.7)))-0.01,0)
			outside = Vector2(GEOMETRY.orbit_outer(radius,float(data.get("orbit_ratio",0.7)))+0.01,0)
		boundary.position = outside; boundary.current_hp = 1000000
		runtime._cast(String(id)); check(boundary.current_hp == 1000000,"real cast excludes outside visible boundary: "+String(id))
		boundary.position = inside
		runtime._cast(String(id)); check(boundary.current_hp < 1000000,"real cast includes inside visible boundary: "+String(id))
		if pattern in ["nova","frost","guard","heal","orbit","slash","beam"]:
			var effect: Dictionary = runtime.effects[posmod(runtime.effect_cursor-1,runtime.effects.size())]
			check(is_equal_approx(float(effect.radius),GEOMETRY.beam_half_width(1) if pattern == "beam" else radius),"real draw footprint uses hit radius/width")
	# A fleeing target cannot drag a homing shot beyond the cast range.
	var runtime := RUNTIME.new(); hero.hero_id = "ranged_rookie"; runtime.install(hero)
	boundary.current_hp = 1000000; boundary.position = Vector2(100,0)
	runtime._launch_projectile(boundary,Vector2.ZERO,100,1,Color.WHITE,{},0,false,200)
	boundary.position = Vector2(1000,0); runtime._tick_projectiles(1)
	check(boundary.current_hp == 1000000 and not runtime.projectiles[0].active and float(runtime.projectiles[0].traveled) == 200,"homing shot stops at actual visible travel limit")
	# Following emitters move their drawn center and hit center together. Since 2026-10-15
	# rune_ring is a fixed sigil; the hero-following area is the blood_thorns aura emitter.
	var follow_id := "madness_hero_blood_thorns"
	hero.hero_id = "madness_hero"; runtime = RUNTIME.new(); runtime.install(hero)
	runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add(follow_id)
	hero.position = Vector2.ZERO; anchor.position = Vector2(20,0)
	runtime._cast(follow_id)
	var field: Dictionary = {}
	for slot in runtime.delivery.slots:
		if slot.id == follow_id and float(slot.left) > 0.0: field = slot
	check(not field.is_empty() and field.mode == "aura","fixture is a following field")
	hero.position = Vector2(500,500); anchor.position = hero.position; boundary.position = Vector2(-500,-500)
	runtime.cooldowns[follow_id] = 100
	var before := anchor.current_hp; runtime.tick(0.1)
	check(not field.is_empty() and Vector2(field.origin) == hero.global_position and anchor.current_hp < before,"following field visual center is actual damage origin")
	if not field.is_empty(): runtime.tick(float(field.left)+0.1); check(float(field.left) == 0,"field disappears when its actual lifetime expires")
	arena.free()
func actual_ui() -> void:
	# Hero mode opens after demon easy stage 3 (2026-10-14 unlock rules).
	var unlocks := ConfigFile.new()
	for stage_id in ["stage_1","stage_2","stage_3"]: unlocks.set_value("cleared",stage_id,true)
	check(SCOPE.save_config(unlocks,"user://stage_progress.cfg") == OK,"isolated hero mode unlock")
	var paid := STAMINA.try_enter("stage_1",true,-1,false)
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"ranged_rookie","hero_entry":paid})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(scene)
	if not scene.entry_ready: await scene.entry_started
	scene._pause()
	var manager = scene.get_node("HeroBGMManager")
	for id in CHARACTERS.ORDER:
		manager.start_hero_loop(String(id))
		check(manager.current_stage_id == CHARACTERS.stage_for_hero(String(id)) and manager.current_phase == manager.Phase.BATTLE,"hero determines music independently of battlefield: "+String(id))
		check(manager._stage_streams.size() == 1 and manager.player_a.stream is AudioStreamOggVorbis and manager.player_a.stream.loop and (manager.player_a.playing or manager.player_a.stream_paused),"only dedicated battle segment loops, respecting saved mute")
		manager.update_hero_hp(1,1000); check(manager.current_phase == manager.Phase.BATTLE,"low HP cannot interrupt hero loop")
	manager.start_stage("stage_1"); check(not manager.hero_loop_only and manager.current_phase == manager.Phase.INTRO,"demon intro unchanged")
	manager.update_hero_hp(5,100); check(manager.current_phase == manager.Phase.FINAL,"demon HP phases unchanged")
	manager.start_hero_loop("ranged_rookie")
	scene.overlay.hide(); scene._refresh_hud()
	await process_frame
	check(scene.hp.has_theme_stylebox_override("fill") and scene.xp.has_theme_stylebox_override("fill"),"HP/EXP fills styled")
	check(scene.get_node("HeroHUD").find_child("HeroPortrait",true,false).texture != null,"actual selected hero portrait")
	check(scene.get_node("HeroHUD").get_rect().end.y <= scene.get_node("BattleView").offset_top,"HUD does not cover battlefield")
	await capture("hero-hud-revised")
	var runtime = scene.battle.hero.player_weapons
	for id in DATA.weapon_pool().slice(1,3): runtime.add(String(id))
	for repeat in 3:
		scene._queue_chest(); scene._begin_roulette(); scene.roulette_tween.kill()
		var before: Dictionary = runtime.levels.duplicate()
		scene._roulette_tick(0.54); await capture("hero-reel-spinning")
		scene._finish_roulette(); await process_frame
		var receipt: Dictionary = scene.roulette_receipt
		check(scene.roulette_reel.displayed_id == receipt.id and scene.roulette_label.text == receipt.name,"actual final item equals applied receipt")
		for id in runtime.weapon_ids: check(int(runtime.levels[id]) == int(before[id])+(1 if id == receipt.id else 0),"only displayed item upgraded")
		# Redesigned chest reel modal (2026-10-14) is capped at 920x740.
		check(scene.overlay.size.y <= 740 and scene.get_global_rect().encloses(scene.overlay.get_global_rect()),"compact modal fits viewport (%s)" % scene.overlay.size)
		check(scene.overlay.get_global_rect().encloses(scene.roulette_reel.get_global_rect()),"reel stays inside modal")
		scene._finish_roulette(); check(int(runtime.levels[receipt.id]) == int(before[receipt.id])+1,"duplicate finish cannot grant twice")
		await capture("hero-reel-result"); scene._close_roulette(); scene._pause()
	var first: String = runtime.weapon_ids[0]
	while int(runtime.levels[first]) < DATA.MAX_LEVEL: runtime.add(first)
	scene._queue_chest(); scene._begin_roulette(); scene.roulette_tween.kill(); scene._finish_roulette()
	check(scene.roulette_receipt.evolution and runtime.evolved.has(first) and scene.roulette_reel.displayed_id == first,"evolution lands on real evolved weapon")
	scene._close_roulette(); scene._pause()
	for id in runtime.weapon_ids:
		while int(runtime.levels[id]) < DATA.MAX_LEVEL: runtime.add(String(id))
		runtime.evolved[id] = true
	scene.battle.hero.current_hp = scene.battle.hero.max_hp/2
	scene._queue_chest(); scene._begin_roulette(); scene.roulette_tween.kill(); scene._finish_roulette()
	check(scene.roulette_receipt.id == "survival_restore" and scene.roulette_reel.displayed_id == "survival_restore","fully evolved recovery matches landing")
	scene._close_roulette(); scene._pause()
	# Show long names and all passive icons using the real augment card UI.
	scene._show_choices([{"id":"sage_astra_absolute_zero","name":"빙점의 구체 Lv.10","description":DATA.description("sage_astra_absolute_zero",10)},{"id":"summoner_hero_gate_hound","name":"이계 투견 수호체 Lv.10","description":DATA.description("summoner_hero_gate_hound",10)},{"id":"survival_magnet","name":"경험치 획득 반경 Lv.10","description":DATA.description("survival_magnet",10)}])
	await create_timer(0.3).timeout; await capture("hero-augments-revised")
	# Render the actual Hero draw path with each shared ground footprint.
	scene.overlay.hide()
	for spec in [["ranged_rookie","ranged_rookie_pulse_staff"],["sword_shield_hero","sword_shield_hero_longsword"],["sword_shield_hero","sword_shield_hero_piercing_spear"],["sword_shield_hero","sword_shield_hero_blade_ring"]]:
		for effect in runtime.effects: effect.left = 0.0
		for field in runtime.fields: field.left = 0.0
		runtime.available_weapons = DATA.weapon_pool(String(spec[0]))
		runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add(String(spec[1]))
		runtime._cast(String(spec[1])); scene.battle.hero.queue_redraw()
		await capture("hero-range-"+String(DATA.WEAPONS[spec[1]].pattern))
	scene.queue_free(); await process_frame
