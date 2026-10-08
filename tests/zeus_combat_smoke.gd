extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const DATA := preload("res://src/data/zeus_behavior_catalog.gd")
const FX := preload("res://src/ui/zeus_combat_effects.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const TEAM := preload("res://src/systems/team_loadout_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero
var zeus

func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("ZEUS_COMBAT: "+message)
func hit_reset() -> void:
	hero.invulnerability_timer = 0
	hero.paralysis_timer = 0
	hero.paralysis_ratio = 0
	hero.current_hp = hero.max_hp
	hero.shield_hp = 0
func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{name}",name))

func run() -> void:
	root.size = Vector2i(540,960)
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	var folder := "user://zeus_combat_"+Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	state.zeus = {"unlocked":true,"level":0,"shards":0}
	COLLECTION.save_state(state)
	check(LOADOUT.save_id("zeus"),"register actual Zeus")
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1000,1000)
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	battle.command_power = 9999
	battle.demon_exp_to_next_level = 1000000
	check(CATALOG.get_species("zeus") == "divine_humanoid" and CATALOG.get_role("zeus") == "ranged" and CATALOG.get_base_cost("zeus") == 0,"classification/free summon")
	check(preload("res://src/data/demon_augment_catalog.gd").get_monster_normal_augments("zeus","").is_empty() and not CATALOG.MONSTERS.zeus.can_be_elite and not CATALOG.MONSTERS.zeus.can_be_giant,"no augment/elite/giant")
	for i in range(8):
		var ally = battle._spawn_monster("slime",Vector2(300+i*40,500))
		ally.set_physics_process(false)
	check(battle.raw_allied_summons == 8,"raw successful spawn events")
	check(not battle.try_summon_transcendent(),"locked before spending")
	battle.transcendence.record_command(499)
	battle.transcendence.record_mana(249)
	check(not battle.transcendence.ready,"AND boundaries")
	battle.transcendence.record_mana(1)
	check(not battle.transcendence.ready,"mana alone insufficient")
	check(battle.try_summon("slime"),"actual command spending")
	check(battle.transcendence.ready and battle.transcendence.command_spent >= 500,"successful paid summon unlocks")
	var cost_before: float = battle.command_power
	check(battle.try_summon_transcendent(),"actual free Zeus summon")
	zeus = battle.transcendent_actor
	zeus.set_physics_process(false)
	zeus.position = hero.position+Vector2(180,0)
	check(battle.command_power == cost_before and battle.transcendence.used,"free once")
	check(not battle.try_summon_transcendent() and battle._spawn_monster("zeus",Vector2.ZERO) == null,"one per battle and bypass rejection")
	check(zeus.summon_snapshot == 9 and zeus.max_hp == int(round(1200+9*2.5)) and zeus.attack_damage == int(round(150+9*0.6)),"raw snapshot formula")
	check(zeus.move_speed == 290 and is_equal_approx(zeus.attack_range,237.5) and is_equal_approx(zeus.attack_cooldown,1.3),"movement/range/1.3-second interval")
	var hp_before: int = zeus.max_hp
	var attack_before: int = zeus.attack_damage
	battle.monster_hp_multiplier = 100
	battle.monster_damage_multiplier = 100
	battle.demon_level = 20
	battle._refresh_alive_monsters_for_demon_level()
	battle._refresh_alive_monsters_for_augments()
	check(zeus.max_hp == hp_before and zeus.attack_damage == attack_before,"stats immune to research/global augments/levels")
	check(battle.get_monster_run_detail("zeus").attack_damage == zeus.attack_damage,"info shows real snapshot")
	zeus.skill_cooldowns.fill(100)
	zeus.gauge = 0
	battle.command_regen_per_second = 6
	check(zeus.get_gauge_regen() == 6,"buffed command regen100%")
	battle.command_regen_per_second = 40
	check(zeus.get_gauge_regen() == 15,"regen cap15")
	battle.external_pause = true
	zeus._physics_process(1)
	check(zeus.gauge == 0,"pause freezes gauge")
	battle.external_pause = false
	zeus.attack_timer = 100
	zeus._physics_process(1)
	check(zeus.gauge == 15,"one second regen")
	# Harassment keeps a hysteresis band and still attacks while retreating.
	check(CATALOG.MONSTERS.zeus.combat_style == "ranged_harasser","data driven combat style")
	hit_reset()
	zeus.position = hero.position+Vector2(100,0)
	zeus.attack_timer = 0
	zeus._physics_process(1.0/60.0)
	check(zeus.keeping_distance and zeus.velocity.x > 0 and hero.current_hp == hero.max_hp-zeus.attack_damage,"retreat while attacking")
	zeus.position = hero.position+Vector2(185,0)
	zeus._physics_process(1.0/60.0)
	check(zeus.keeping_distance and zeus.velocity.x > 0,"retreat persists through inner band")
	zeus.position = hero.position+Vector2(212,0)
	zeus._physics_process(1.0/60.0)
	check(not zeus.keeping_distance and zeus.velocity == Vector2.ZERO,"stop at safe distance")
	zeus.position = hero.position+Vector2(185,0)
	zeus._physics_process(1.0/60.0)
	check(zeus.velocity == Vector2.ZERO,"no jitter on reentering band")
	zeus.position = hero.position+Vector2(350,0)
	zeus._physics_process(1.0/60.0)
	check(zeus.velocity.x < 0,"approach beyond basic range")
	zeus.position = hero.position+Vector2(180,0)
	# Damage accepts the real hero pipeline, including shield and invulnerability.
	hit_reset()
	zeus._fire_projectile(Vector2.LEFT)
	check(hero.current_hp == hero.max_hp-zeus.attack_damage,"instant basic strike")
	hit_reset()
	hero.invulnerability_timer = 1
	zeus._fire_projectile(Vector2.LEFT)
	check(hero.current_hp == hero.max_hp,"Lv0 respects invulnerability")
	zeus.transcend_level = 1
	zeus._fire_projectile(Vector2.LEFT)
	check(hero.current_hp == hero.max_hp-int(round(zeus.attack_damage*0.5)),"Lv1 half damage against invulnerable")
	hit_reset()
	check(hero.apply_paralysis(0.75,2) and is_equal_approx(hero.get_paralysis_attack_multiplier(),0.25),"paralysis slows attack rate")
	check(not hero.apply_paralysis(0.3,2) and hero.paralysis_ratio == 0.75,"weak status cannot overwrite")
	check(hero.apply_paralysis(0.9,2) and hero.paralysis_ratio == 0.9,"strongest refresh")
	hero.attack_timer = 1
	hero._physics_process(0.5)
	check(is_equal_approx(hero.attack_timer,0.95),"actual hero timer slowed")
	hero._physics_process(2.1)
	check(hero.paralysis_timer == 0 and hero.paralysis_ratio == 0,"status expires")
	hit_reset()
	zeus.transcend_level = 0
	zeus.gauge = 100
	zeus.skill_cooldowns = PackedFloat32Array([0,100,100])
	zeus._try_cast()
	check(zeus.charge_remaining == 2 and zeus.gauge == 70 and zeus.skill_cooldowns[0] == 20,"skill1 cost/charge/cooldown")
	check(zeus.combat_sfx.players.charge.playing,"real cast starts charging audio")
	var position_before: Vector2 = zeus.position
	zeus._physics_process(1)
	check(zeus.position == position_before and zeus.charge_remaining == 1,"charge stationary")
	zeus._physics_process(1)
	check(zeus.thunder_elapsed == 0 and hero.current_hp == hero.max_hp,"focus ends before warned strike")
	check(not zeus.combat_sfx.players.charge.playing,"release stops focus audio")
	zeus._tick_thunder(0.05)
	check(zeus.thunder_warned == 1 and zeus.thunder_struck == 0,"warning before first impact")
	hero.global_position = zeus.thunder_points[0]
	zeus._tick_thunder(0.20)
	check(hero.current_hp == hero.max_hp-zeus.attack_damage*2 and is_equal_approx(hero.paralysis_ratio,0.3),"each thunder200/status within radius")
	check(zeus.combat_sfx.players.thunder.playing,"existing lightning sound on impact")
	var frozen_elapsed: float = zeus.thunder_elapsed
	battle.external_pause = true
	zeus._physics_process(1)
	check(zeus.thunder_elapsed == frozen_elapsed,"pause freezes storm")
	battle.external_pause = false
	for index in range(1,12):
		zeus._tick_thunder(0.05)
		var warning_point: Vector2 = zeus.thunder_points[index]
		check(warning_point.distance_to(zeus.thunder_center) <= DATA.THUNDER_AREA_RADIUS-DATA.THUNDER_HIT_RADIUS+0.001,"random full hit circle contained")
		hero.global_position = warning_point
		hero.invulnerability_timer = 0
		zeus._tick_thunder(0.20)
		check(zeus.thunder_points[index] == warning_point,"announced strike stays fixed while tracking")
	check(hero.current_hp == hero.max_hp-zeus.attack_damage*2*12,"all12 individually use200% coefficient")
	check(zeus.thunder_struck == 12 and zeus.thunder_tracks == 5,"12 strikes and five tracking updates in three seconds")
	zeus._tick_thunder(0.5)
	check(zeus.thunder_elapsed < 0,"storm cleanup")
	hit_reset()
	zeus.transcend_level = 2
	hero.invulnerability_timer = 1
	zeus._release_thunder()
	zeus._strike_thunder(hero.global_position)
	check(hero.current_hp == hero.max_hp-int(round(zeus.attack_damage*2.35)),"Lv2 each thunder235 ignores immunity")
	zeus.thunder_elapsed = -1
	hit_reset()
	zeus.set_meta("support_shield_hp",0)
	hero.apply_paralysis(0.3,2)
	zeus._fire_projectile(Vector2.LEFT)
	hero.invulnerability_timer = 0
	zeus._fire_projectile(Vector2.LEFT)
	var shield_gain := int(round(zeus.max_hp*0.01))
	check(int(zeus.get_meta("support_shield_hp")) == shield_gain*2,"paralyzed basic hits stack1% own maxHP shield")
	var saved_hp: int = zeus.current_hp
	zeus.take_damage(shield_gain)
	check(zeus.current_hp == saved_hp and int(zeus.get_meta("support_shield_hp")) == shield_gain,"shield absorbs damage before HP")
	hit_reset()
	zeus.transcend_level = 0
	hero.apply_paralysis(0.3,2)
	hero.invulnerability_timer = 1
	zeus._fire_projectile(Vector2.LEFT)
	check(int(zeus.get_meta("support_shield_hp")) == shield_gain,"rejected hit grants no shield")
	hit_reset()
	zeus._strike_thunder(hero.global_position+Vector2(60.1,0))
	check(hero.current_hp == hero.max_hp,"outside individual circle misses")
	hit_reset()
	hero.position = Vector2(1000,1000)
	zeus.position = hero.position+Vector2(180,0)
	zeus.set_meta("support_shield_hp",0)
	zeus.transcend_level = 2
	zeus.gauge = 100
	zeus.skill_cooldowns = PackedFloat32Array([100,0,100])
	zeus._try_cast()
	check(zeus.gauge == 70 and zeus.crown_remaining == 15 and zeus.skill_cooldowns[1] == 45,"crown cost/duration/cooldown")
	check(zeus.combat_sfx.players.crown.playing,"buff start plays crown once")
	zeus.current_hp = 500
	zeus._tick_crown(15)
	check(zeus.current_hp == 500+3*int(round(zeus.max_hp*0.03)) and zeus.crown_heals == 3,"three crown healing beats")
	zeus.crown_remaining = 15
	zeus.transcend_level = 3
	check(zeus.apply_paralysis_to(hero,0.3) and is_equal_approx(hero.paralysis_ratio,0.45),"crown multiplies paralysis by1.5")
	check(hero.ultimate_cooldown_timer >= 10 and hero.channel_cooldown_timer >= 10 and hero.shield_cooldown_timer >= 10,"Lv3 all skills impose10")
	for archetype in ["ranged_kiter","rogue_combo","sword_shield","pistol_gunner","berserker_madness","archmage_elementalist","alchemist_chemical","summoner_gatekeeper","cleric_purifier","grand_sage_astra"]:
		hero.hero_archetype = archetype
		for property in hero._get_external_skill_cooldown_properties():
			hero.set(property,3)
		hero.impose_all_skill_cooldowns(10)
		for property in hero._get_external_skill_cooldown_properties():
			check(float(hero.get(property)) >= 10,"all cooldowns " + archetype)
	hero.hero_archetype = "ranged_kiter"
	# Slashes use swept collision and a reusable projectile with a fixed-size trail.
	hit_reset()
	zeus.crown_remaining = 0
	zeus.transcend_level = 2
	zeus.gauge = 100
	zeus.skill_cooldowns = PackedFloat32Array([100,100,0])
	zeus._try_cast()
	check(zeus.gauge == 50 and zeus.skill_cooldowns[2] == 15,"slash cost/cooldown")
	check(zeus.combat_sfx.players.slash.playing,"real pooled slash launch sound")
	var shot
	for child in battle.get_children():
		if child.get_script() == preload("res://src/monsters/zeus_slash.gd") and child.active:
			shot = child
	check(is_instance_valid(shot),"actual pooled slash")
	shot.set_physics_process(false)
	hero.invulnerability_timer = 1
	shot._physics_process(0.4)
	check(hero.current_hp == hero.max_hp-int(round(zeus.attack_damage*1.75)) and hero.paralysis_ratio == 0.20,"swept slash175/ignore immunity/paralysis")
	check(zeus.combat_sfx.players.slash_hit.playing,"accepted projectile hit sound")
	var after_hit: int = hero.current_hp
	shot._physics_process(0.1)
	check(hero.current_hp == after_hit,"one hit per projectile")
	shot._physics_process(3)
	check(not shot.active,"expires at1500")
	var reused = battle.acquire_projectile(load("res://src/monsters/ZeusSlash.tscn"),"zeus_slash")
	check(reused == shot,"projectile pool reuse")
	battle.recycle_projectile(reused,"zeus_slash")
	zeus.gauge = 0
	zeus.transcend_level = 0
	zeus.on_ally_death(zeus.global_position+Vector2(276,0))
	zeus._tick_orbs(1)
	check(zeus.gauge == 0,"diameter550 outside")
	zeus.on_ally_death(zeus.global_position+Vector2(275,0))
	zeus._tick_orbs(1)
	check(is_equal_approx(zeus.gauge,0.01),"orb base0.01")
	zeus.gauge = 0
	zeus.transcend_level = 4
	zeus.absorb_orb()
	check(is_equal_approx(zeus.gauge,0.02),"Lv4 orb doubles")
	zeus.transcend_level = 5
	zeus.current_hp = zeus.max_hp-600
	zeus.absorb_orb()
	zeus.absorb_orb()
	zeus.absorb_orb()
	check(zeus.current_hp == zeus.max_hp-599,"Lv5 fractional missing health accumulates")
	var ally = battle._spawn_monster("slime",zeus.position+Vector2(0,100))
	ally.set_physics_process(false)
	zeus.gauge = 0
	ally.take_damage(100000)
	zeus._tick_orbs(1)
	check(is_equal_approx(zeus.gauge,0.02),"actual ally death delivers orb")
	check(zeus.summon_snapshot == 9,"later summons do not change snapshot")
	for kind in DATA.EFFECTS:
		var pack := FX.get_pack(kind)
		check(pack.frames.size() == DATA.EFFECTS[kind].last-DATA.EFFECTS[kind].first+1,"exact authored frames " + kind)
		check(FX.get_pack(kind) == pack,"shared frame pack cache")
	if "--capture" in OS.get_cmdline_user_args():
		battle.position = Vector2(-700,-600)
		zeus.position = hero.position+Vector2(-180,140)
		zeus.gauge = 70
		zeus.charge_remaining = 0.7
		zeus.crown_remaining = 10
		zeus.crown_elapsed = 5
		zeus.on_ally_death(zeus.global_position+Vector2(100,90))
		zeus._tick_orbs(0.5)
		zeus.queue_redraw()
		await capture("charge")
		zeus.charge_remaining = 0
		zeus._show_pillar("thunder",hero.global_position)
		zeus.pillar_remaining = 0.25
		zeus.queue_redraw()
		await capture("thunder")
		zeus._release_thunder()
		zeus._tick_thunder(0.6)
		zeus.queue_redraw()
		await capture("storm")
		var preview = battle.acquire_projectile(load("res://src/monsters/ZeusSlash.tscn"),"zeus_slash")
		preview.global_position = zeus.global_position
		preview.setup(Vector2.RIGHT,zeus,hero)
		preview.set_physics_process(false)
		for i in range(12):
			preview._physics_process(0.025)
		await capture("slash")
	battle.free()
	# Guest legacy slots stay readable; account slots share the accepted team file.
	check(TEAM.save_ids(["slime"],CATALOG.ORDER) and LOADOUT.load_id() == "zeus","ordinary team save preserves transcendent")
	check(LOADOUT.save_id("") and TEAM.load_ids(CATALOG.ORDER,[]) == ["slime"] and LOADOUT.load_id() == "","unregister preserves ordinary team")
	var legacy := ConfigFile.new()
	legacy.set_value("loadout","monster_id","zeus")
	legacy.save(folder.path_join("transcendence_loadout.cfg"))
	var config := ConfigFile.new()
	config.set_value("team","monster_ids","slime")
	config.save(folder.path_join("team_loadout.cfg"))
	check(LOADOUT.load_id() == "zeus","legacy guest registration readable")
	check(LOADOUT.save_id("") and LOADOUT.load_id() == "","explicit unregister overrides legacy")
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var account := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(account),"isolated account")
	var account_folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var account_state := COLLECTION.load_state()
	account_state.zeus = {"unlocked":true,"level":0,"shards":0}
	check(COLLECTION.save_state(account_state) and LOADOUT.save_id("zeus"),"account registration succeeds")
	check(TEAM.save_ids(["slime"],CATALOG.ORDER) and SCOPE.valid_payload(SCOPE.files),"account payload valid/team save")
	check(SCOPE.select_account(account) and LOADOUT.load_id() == "zeus" and TEAM.load_ids(CATALOG.ORDER,[]) == ["slime"],"account registration reload persists")
	check(LOADOUT.save_id("") and SCOPE.select_account(account) and LOADOUT.load_id() == "" and TEAM.load_ids(CATALOG.ORDER,[]) == ["slime"],"account unregister/reload preserves team")
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(account_folder):
		DirAccess.remove_absolute(account_folder.path_join(file))
	DirAccess.remove_absolute(account_folder)
	print("ZEUS_COMBAT: FAIL" if failed else "ZEUS_COMBAT: PASS")
	quit(1 if failed else 0)
