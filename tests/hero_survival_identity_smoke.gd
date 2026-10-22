extends SceneTree
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SURVIVAL_IDENTITY: "+label)
func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("again-hero-identity-"+label+".png"))
func actor(battle, position: Vector2):
	var result = battle._spawn_monster("orc",position,0,false,{})
	result.max_hp = 1000000; result.current_hp = 1000000; result.set_physics_process(false)
	return result
func relocate(node, position: Vector2) -> void:
	node.global_position = position
	preload("res://src/monsters/monster_runtime_common.gd").notify_forced_position_change(node)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://hero_identity_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	for id in CHARACTERS.ORDER:
		var battle = load("res://src/battle/Battle.tscn").instantiate()
		battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = String(id)
		root.add_child(battle); battle.set_external_pause(true)
		var hero = battle.hero; var runtime = hero.player_weapons; var identity = runtime.identity
		check(identity != null and not identity.spec.is_empty(),"identity installed: "+String(id))
		check(identity.status_resource_y < identity.status_hp_y and identity.status_hp_y < identity.status_shield_y and identity.status_shield_y <= -49,"three status rows above actual body: "+String(id))
		check(hero.status_overlay != null and hero.status_overlay.z_index == 100,"world status overlay connected: "+String(id))
		var target = actor(battle,hero.global_position+Vector2(80,0))
		await physics_frame
		var sounds: int = identity.audio_serial
		runtime._cast(identity.starter)
		check(identity.audio_serial > sounds,"original basic audio invoked: "+String(id))
		var playing := false
		for child in hero.get_children():
			if child is AudioStreamPlayer and child.bus == &"SFX" and child.stream != null and child.playing: playing = true
		check(playing,"actual existing SFX player started: "+String(id))
		if identity.audio != null: check(identity.audio.stream != null and identity.audio.bus == &"SFX","existing stream on SFX bus")
		# Exercise every persistent field against padded real spatial-grid cells. Since
		# 2026-10-15 every poison weapon is a delivery emitter (sigil/trail/aura/lob/trap...).
		var outside = actor(battle,hero.global_position+Vector2(800,0))
		for weapon_id in DATA.weapon_pool(String(id)):
			var data: Dictionary = DATA.WEAPONS[weapon_id]
			if String(data.pattern) != "poison": continue
			for field in runtime.fields: field.left = 0.0
			for slot in runtime.delivery.slots: slot.left = 0.0
			runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add(String(weapon_id))
			hero.alchemist_gas = hero.alchemist_gas_max
			relocate(target,hero.global_position+Vector2(50,0)); relocate(outside,hero.global_position+Vector2(800,0))
			await physics_frame
			runtime._cast(String(weapon_id)); runtime.cooldowns[weapon_id] = 999.0
			var field: Dictionary = {}
			for slot in runtime.delivery.slots:
				if slot.id == weapon_id and float(slot.left) > 0.0: field = slot; break
			check(not field.is_empty(),"actual field spawned: "+String(weapon_id))
			if field.is_empty(): continue
			# Let the warning/landing phase finish so the emitter sits at its final circle; keep
			# both probes away meanwhile so a trap is still armed for the boundary check.
			relocate(target,hero.global_position+Vector2(2000,0)); relocate(outside,hero.global_position+Vector2(2000,0))
			await physics_frame
			runtime.tick(float(field.warning)+0.01)
			relocate(target,field.origin+Vector2(float(field.radius)-1,0)); relocate(outside,field.origin+Vector2(float(field.radius)+1,0))
			await physics_frame
			var candidates: Array = []; battle.fill_monsters_near(field.origin,float(field.radius),candidates)
			check(outside in candidates,"real grid includes outside-circle candidate: "+String(weapon_id))
			var inside_hp: int = target.current_hp; var outside_hp: int = outside.current_hp
			field.tick = 0.0; runtime.tick(0.01)
			check(target.current_hp < inside_hp and outside.current_hp == outside_hp,"only visible circle damages, including chemical basic: "+String(weapon_id))
			if float(field.left) > 0.0:
				hero.silence_timer = 10.0; var lifetime: float = field.left; field.tick = 0.0
				runtime.tick(0.1)
				check(float(field.left) < lifetime and outside.current_hp == outside_hp,"silence does not freeze existing field or extend damage outside")
				hero.silence_timer = 0.0
		for field in runtime.fields: field.left = 0.0
		for slot in runtime.delivery.slots: slot.left = 0.0
		runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add(identity.starter)
		relocate(target,hero.global_position+Vector2(80,0)); relocate(outside,hero.global_position+Vector2(2000,0))
		await physics_frame
		match String(id):
			"ranged_rookie", "swift_hunter":
				var signature: String = identity.spec.signature; runtime.add(signature)
				hero.ultimate_charge = 100; runtime.cooldowns[signature] = 99
				identity.tick(0.1); check(float(runtime.cooldowns[signature]) == 0,"full gauge releases equipped signature")
				runtime._cast(signature); check(hero.ultimate_charge == 0,"actual signature consumes gauge")
				if id == "swift_hunter":
					var first: int = hero.rogue_combo_index
					for repeat in 3+maxi(hero.rogue_bonus_combo_hits,0): runtime._cast(identity.starter)
					check(hero.rogue_combo_index == first,"original combo and bonus-hit count cycle")
			"sword_shield_hero":
				for repeat in 4: actor(battle,hero.global_position+Vector2(repeat*15+30,20))
				await physics_frame
				hero.ultimate_charge = 100; identity.tick(0.1)
				check(hero.fighter_guard_active and hero.shield_hp > 0 and hero.shield_max_hp > 0,"native charge guard and blue shield actually activate")
			"pistol_hero":
				hero.gunner_config.quickdraw_chance = 0.0; hero.gunner_ammo = hero.gunner_magazine_size; hero.gunner_reloading = false
				for shot in runtime.projectiles: shot.active = false
				for repeat in 4: runtime._cast(identity.starter)
				check(hero.gunner_ammo == 0 and hero.gunner_reloading and hero.gunner_magazine_size == 12,"12 actual bullets, four 3-shot bursts, then reload")
				check(hero.shield_hp > 0 and hero.shield_max_hp > 0,"empty magazine shield restored")
				var serial: int = identity.audio_serial; runtime._cast(identity.starter)
				check(identity.audio_serial == serial and hero.gunner_ammo == 0,"reloading cannot fire or consume negative ammo")
				var reload: float = hero.gunner_reload_timer; await create_timer(0.15).timeout
				check(hero.gunner_reload_timer == reload,"pause freezes actual reload")
				identity.tick(reload+0.01)
				check(hero.gunner_ammo == 12 and not hero.gunner_reloading,"reload refills actual ammunition")
				runtime.add("pistol_hero_ricochet"); runtime._cast("pistol_hero_ricochet")
				check(hero.gunner_ammo == 11,"ricochet shares the same displayed magazine")
				hero.gunner_config.backstep_base_chance = 1.0; hero.shield_hp = 0; hero.invulnerability_timer = 0
				var position: Vector2 = hero.global_position; hero.take_damage(1)
				check(hero.gunner_backstep_cooldown > 0 and hero.global_position != position,"original hit dodge restored")
			"archmage_hero":
				var previous := ""
				for repeat in 6:
					runtime._cast(identity.starter)
					check(hero.archmage_last_element != previous,"original non-repeating six-element basic"); previous = hero.archmage_last_element
				check(hero.ultimate_charge > 0,"elemental basic charges actual gauge")
			"madness_hero":
				hero.ultimate_charge = 99; hero.notify_monster_kill("orc")
				check(hero.berserker_madness_active,"actual kill triggers original madness")
				check(identity.cooldown_multiplier() < 0.5,"madness speeds actual equipped attacks")
				var before_blink: Vector2 = hero.global_position; runtime._cast(identity.starter)
				check(hero.global_position != before_blink,"original madness targeting blink restored")
				hero.current_hp = hero.max_hp/4
				check(identity.attack_damage() > hero.attack_damage,"missing HP increases actual weapon damage")
				hero.current_hp = 1; hero.shield_hp = 0; hero.invulnerability_timer = 0
				hero.take_damage(10000)
				check(hero.berserker_reviving and hero.berserker_revive_used and not battle.battle_over,"one-time revival replaces premature defeat")
				var left: float = identity.revive_left; await create_timer(0.15).timeout
				check(identity.revive_left == left and hero.current_hp == 0,"modal pause freezes revival")
				hero._physics_process_actions(left+0.01)
				check(not hero.berserker_reviving and hero.current_hp > 0,"revival completes on combat time")
				hero.shield_hp = 0; hero.invulnerability_timer = 0; hero.take_damage(100000)
				check(not hero.berserker_reviving,"second death cannot revive again")
			"chemical_hero":
				hero.alchemist_gas = 0; var serial: int = identity.audio_serial; runtime._cast(identity.starter)
				check(identity.audio_serial == serial,"zero gas stops basic casting")
				var material = hero.alchemist_material_pool[0]
				for repeat in int(hero.alchemist_philosopher_config.required_materials):
					material.activate(hero.global_position,float(hero.alchemist_config.gas_per_material)); hero._collect_nearby_alchemy_materials()
				check(hero.alchemist_materials_collected == 24 and hero.alchemist_gas > 0,"real pooled pickups refill gas and progress 24 materials")
				identity.tick(1.0); identity.tick(0.2)
				check(hero.alchemist_philosopher_channeling,"native philosopher channel unlocks from real collection")
				var hp_before: int = hero.max_hp; identity.tick(2.0)
				check(hero.alchemist_transformed and hero.max_hp > hp_before,"native permanent transformation applies")
				var mixture: Dictionary = hero.alchemist_config.mixture_field
				var original_rate := float(mixture.gas_cost)/maxf(float(mixture.cooldown),0.1)
				check(is_equal_approx(float(identity.gas_costs.chemical_hero_poison_flask),original_rate*float(DATA.WEAPONS.chemical_hero_poison_flask.cooldown)),"fast survival field preserves original gas budget per second")
				check(not identity.can_cast(identity.starter,"poison"),"transformation disables original vial basic")
				hero.velocity = Vector2(270,0); hero.position += Vector2(100,0); identity.tick(0.3)
				var trail := false
				for poison in hero.alchemist_poison_pool:
					if poison.active: trail = true
				check(trail,"manual movement leaves real native poison trail")
				var transformed_speed: float = hero.move_speed
				runtime.add("survival_mobility")
				check(hero.move_speed >= transformed_speed*(1.0+float(DATA.PASSIVES.survival_mobility.value))-0.01,"later passive upgrade preserves transformed speed")
			"summoner_hero":
				for repeat in 8: runtime._cast(identity.starter)
				identity.tick(0.1)
				check(hero._get_active_summon_count() == 3 and hero._get_summoner_slot_capacity() == 3,"actual summon slots remain capped")
				check(hero.shield_hp > 0,"native full-slot shield restored")
			"purifier_hero":
				hero.ultimate_charge = 99; hero.notify_monster_kill("orc"); identity.tick(0.1); identity.tick(1.1)
				check(hero.purifier_protection_active and hero.shield_hp > 0,"real kill gauge triggers shield layers")
			"sage_astra":
				for node in identity.native_actors:
					if node.active: battle.recycle_projectile(node,String(node.get_meta("identity_pool_key","")))
				hero.sage_attack_serial = 0
				for repeat in 3: runtime._cast(identity.starter)
				var piercing := 0; var basics := 0
				for node in identity.native_actors:
					if node.active:
						if node.projectile_mode == 1: piercing += 1
						else: basics += 1
				check(basics == 2 and piercing == 1,"third actual projectile is native piercing shot")
				var hp_before: int = hero.max_hp
				for repeat in 9:
					hero.ultimate_charge = 20; hero.sage_skill3_cooldown_timer = 0; identity.tick(0.01)
				check(hero.sage_condensation_completion_count == 1 and hero.max_hp > hp_before,"original 8-stack condensation and permanent growth")
				hero.sage_phase_active = false; hero.sage_phase_cooldown_timer = 0; identity.tick(0.01)
				check(hero.sage_phase_active,"native periodic phase passive restored")
				hero.target = target; hero.ultimate_charge = 100; hero.sage_skill3_cooldown_timer = 999
				var pillar_pool: int = battle.projectile_pools.sage_ice_pillar.size(); identity.tick(0.01)
				check(battle.projectile_pools.sage_ice_pillar.size() == pillar_pool,"passive bridge cannot cast unowned AI skills")
				hero._unlock_conditional_skill("sage_skill_6","흑점","test",1,1,{})
				hero.sage_config.skill_6.trigger_chance = 1.0
				var node_count: int = battle.get_child_count()
				hero.player_controlled = false
				hero._on_sage_skill_hit(target.global_position)
				hero.player_controlled = true
				check(battle.projectile_pools.sage_blackspot_explosion.size() == 7,"shared AI/player Hero path acquires actual Node2D blackspot")
				var active_effect: Node2D
				for effect in hero.sage_blackspot_effects:
					if int(effect.state) == 1: active_effect = effect; break
				active_effect._physics_process(0.4)
				check(not active_effect.damage_applied,"paused blackspot cannot pay damage")
				var before_impact: int = target.current_hp
				battle.set_external_pause(false); hero.set_physics_process(false); target.set_physics_process(false)
				await create_timer(0.35).timeout; battle.set_external_pause(true)
				check(active_effect.damage_applied and target.current_hp < before_impact,"restored Node2D blackspot actually damages the enemy")
				node_count = battle.get_child_count()
				for repeat in 20: hero._on_sage_skill_hit(target.global_position)
				check(battle.get_child_count() == node_count and battle.projectile_pools.sage_blackspot_explosion.is_empty(),"blackspot saturation never instantiates fallback actors")
		if not identity.native_actors.is_empty():
			var nodes: int = battle.get_child_count()
			for repeat in 100: runtime._cast(identity.starter)
			check(battle.get_child_count() == nodes and identity.native_actors.size() == identity.native_pool_size,"native basic saturation never allocates")
			for node in identity.native_actors:
				if node.active:
					# Hero mode pauses the whole battle subtree (process_mode) since 2026-10-17.
					check(not node.can_process(),"spawned basic remains paused")
					var bounds: Rect2 = node.get_meta("survival_visual_bounds",Rect2())
					var radius: float = node.visual_diameter*0.5 if String(id) == "sage_astra" else node.get_node("CollisionShape2D").shape.radius
					check(bounds.size.length()*0.5*node.projectile_sprite.scale.x <= radius+0.01,"native visible opaque bounds fit actual collision circle")
		battle.queue_free(); await process_frame
	await ui_capture()
	print("HERO_SURVIVAL_IDENTITY_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
func ui_capture() -> void:
	var config := ConfigFile.new()
	# Each hero unlocks with the demon easy clear of its origin stage (2026-10-14); stage 3 opens the mode.
	for id in CHARACTERS.ORDER: config.set_value("cleared",CHARACTERS.stage_for_hero(String(id)),true)
	SCOPE.save_config(config,"user://stage_progress.cfg")
	for id in ["chemical_hero","pistol_hero"]:
		var paid := STAMINA.try_enter("stage_1",true,-1,false)
		root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":id,"hero_entry":paid})
		var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(scene)
		if not scene.entry_ready: await scene.entry_started
		scene._pause(); scene.overlay.hide()
		var hero = scene.battle.hero; hero.shield_hp = 90; hero.shield_max_hp = 180
		hero.current_hp = hero.max_hp*3/4
		if id == "chemical_hero": hero.alchemist_gas = 130; hero.alchemist_materials_collected = 8
		else: hero.gunner_ammo = 7
		scene._refresh_hud(); await process_frame
		check(scene.status.text.contains("가스" if id == "chemical_hero" else "탄약"),"real top HUD shows live character resource")
		await capture(String(id)); scene.queue_free(); await process_frame
