extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const MAP := preload("res://src/data/hero_map_assault_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
var checks := 0
func check(ok: bool,info: String) -> void:
	checks += 1
	assert(ok,info)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	seed(57015)
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := BASE.Hero.new(); hero.position = Vector2(900,1200); arena.add_child(hero)
	var enemy := BASE.Target.new(); arena.add_child(enemy); arena.targets.append(enemy)
	var empty_frames: Array[Texture2D] = []
	for id in DATA.weapon_pool(hero.hero_id): RUNTIME.ART.cache[String(DATA.WEAPONS[id].effect_dir)] = empty_frames
	var runtime := RUNTIME.new(); runtime.install(hero)
	var delivery = runtime.delivery
	for owner in DATA.HERO_WEAPONS:
		var styles := {}
		for id in DATA.weapon_pool(owner):
			var data: Dictionary = DATA.WEAPONS[id]
			var rule := DATA.DELIVERY.spec(id,data)
			styles[String(rule.get("mode",data.pattern))] = true
		check(styles.size() >= 2,"multiple thematic attack styles "+owner)
	check(DATA.DELIVERY.spec("pistol_hero_suppressor",DATA.WEAPONS.pistol_hero_suppressor).mode == "sentry","gunner keeps physical sentry")
	check(DATA.DELIVERY.spec("madness_hero_heart_chain",DATA.WEAPONS.madness_hero_heart_chain).is_empty(),"berserker is no longer a magic turret")
	hero.damage_poison_tracker = BASE.Clearable.new(); hero.burn_runtime = BASE.Clearable.new()
	for weapon in DATA.WEAPONS:
		if DATA.DELIVERY.spec(weapon,DATA.WEAPONS[weapon]).is_empty(): continue
		for rank in [1,3,6,10]:
			for emitter in delivery.slots: emitter.left = 0.0
			runtime.levels[weapon] = rank; runtime.resolved.clear()
			enemy.position = hero.position+Vector2(60,0)
			runtime._cast(weapon)
			var found := false
			for emitter in delivery.slots:
				if emitter.left > 0.0 and emitter.id == weapon: found = true
			check(found,"real cast creates retained emitter "+weapon+str(rank))
	for emitter in delivery.slots: emitter.left = 0.0
	# Real orbit collision: the center and empty annular gaps never receive contact damage.
	var id := "ranged_rookie_satellite_orbs"
	runtime.add(id); var stats := runtime.stats_for(id)
	check(delivery.cast(id,stats,hero.position,100,240,1),"orbit delivery handled")
	var slot: Dictionary = delivery.slots[0]
	enemy.position = hero.position; var hp := enemy.current_hp
	delivery.tick(0.01); check(enemy.current_hp == hp,"orbit does not hit center")
	var contact: Vector2 = delivery.orbit_point(slot,0)
	check(delivery.orbit_contact(slot,contact),"visible orbit body matches hit geometry")
	var gap := hero.position+Vector2.from_angle(delivery.clock*2.4+PI/int(slot.count))*float(slot.orbit_radius)
	check(not delivery.orbit_contact(slot,gap),"gaps between satellites remain safe")
	enemy.position = contact; slot.tick = 0.0; delivery.tick(0.001)
	check(enemy.current_hp < hp,"real contact damages")
	for index in 100: delivery.cast(id,stats,hero.position,100,240,1)
	var active := 0
	for emitter in delivery.slots:
		if emitter.left > 0.0: active += 1
	check(active == 1 and delivery.slots.size() == 24,"repeat casts bounded and retained")
	# Target sigils remain in world space under displacement.
	id = "ranged_rookie_pulse_staff"; runtime.add(id); stats = runtime.stats_for(id)
	delivery.cast(id,stats,hero.position,100,300,1)
	for emitter in delivery.slots:
		if emitter.id != id or emitter.left <= 0: continue
		var anchor: Vector2 = emitter.origin
		enemy.position = anchor; hp = enemy.current_hp
		delivery.tick(0.3); check(enemy.current_hp == hp,"warning has no damage")
		hero.position += Vector2(100,100)
		check(emitter.origin == anchor,"fear/displacement cannot drag map zones")
		delivery.tick(0.4); delivery.tick(0.01)
		check(enemy.current_hp < hp,"zone damages after telegraph")
		break
	# Both global cap and timed phase cap grow. Placement is bounded away from the player.
	for stage in range(1,11):
		check(MODE.monster_limit(stage) == 144+8*(stage-1),"stage cap "+str(stage))
	for plan in MAP.PLANS:
		var far := 0; var sectors := {}
		for index in 240:
			var point := arena._clamp_manual_spawn_position(MAP.point(plan,index,Vector2(900,1200),Vector2.RIGHT,arena.current_map_size))
			check(point.x >= 70 and point.y >= 70 and point.x <= 1730 and point.y <= 2330,"inside map")
			if point.distance_to(Vector2(900,1200)) >= MAP.MIN_DISTANCE: far += 1
			sectors[Vector2i(int(point.x/450),int(point.y/600))] = true
		check(far >= 180 and sectors.size() >= 4,"map distribution "+plan)
	for value in [-999,0,1,30,900,INF]:
		if is_finite(value): check(MODE.monster_limit(int(value)) <= 216,"bounded cap")
	arena.queue_free(); await process_frame
	print("HERO_SURVIVAL_VARIETY PASS checks=",checks)
	quit()
