extends SceneTree
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SURVIVAL_REVISION: "+label)
func ticket(stage: String) -> Dictionary:
	var paid := STAMINA.try_enter(stage,true,-1,false)
	check(bool(paid.success),"test ticket")
	return STAMINA.claim_battle_entry(stage)
func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("again-hero-"+name+".png"))
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://survival_revision_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	# Locked legacy selection must not migrate into a clear or unlock.
	var config := ConfigFile.new(); config.set_value("hero_loadout","battle_stage","stage_10")
	check(SCOPE.save_config(config,STORE.PATH) == OK,"legacy selection fixture")
	check(STORE.selected_battle_stage() == "stage_1" and not STORE.select_battle_stage("stage_2"),"legacy free maps no longer bypass progression")
	# Hero mode opens after demon easy stage 3; the apprentice needs demon stage 1 (2026-10-14).
	var milestone := ConfigFile.new()
	for stage_id in ["stage_1","stage_2","stage_3","stage_10"]: milestone.set_value("cleared",stage_id,true)
	check(SCOPE.save_config(milestone,"user://stage_progress.cfg") == OK,"demon easy3 opens hero mode")
	var entry := ticket("stage_1")
	check(not STORE.award_run("stage_1",entry,899.0,100,true).success,"early victory rejected")
	check(STORE.award_run("stage_1",entry,200.0,100,false).success and not STORE.hard_stage_unlocked("stage_1"),"abandonment cannot unlock hero hard")
	entry = ticket("stage_1")
	var blocked_journal := original_scope_path()+"/gameplay_transaction.json.tmp"
	check(DirAccess.make_dir_recursive_absolute(blocked_journal) == OK,"block only the isolated transaction write")
	check(not STORE.award_run("stage_1",entry,900,100,true).success and not STORE.hard_stage_unlocked("stage_1"),"actual failed save cannot unlock hero hard")
	check(DirAccess.remove_absolute(blocked_journal) == OK,"restore isolated transaction target")
	var reward := STORE.award_run("stage_1",entry,900,100,true)
	check(reward.success and int(reward.research) == 252,"victory and reward commit together")
	# Battlefields open one at a time through contiguous easy wins (2026-10-15).
	check(STORE.highest_battle_stage() == 2 and STORE.battle_stage_cleared("stage_1") and STORE.hard_stage_unlocked("stage_1"),"victory records easy clear and opens matching hard")
	check(STORE.award_run("stage_1",entry,900,100,true).research == 0 and STORE.highest_battle_stage() == 2,"duplicate receipt cannot pay or unlock twice")
	var campaign := ConfigFile.new(); SCOPE.load_config(campaign,"user://stage_progress.cfg")
	check(int(campaign.get_value("progress","highest_unlocked_stage",1)) == 1 and bool(campaign.get_value("cleared","stage_10",false)) and not bool(campaign.get_value("cleared","stage_4",false)),"hero wins do not advance demon campaign")
	var original := SCOPE.guest_directory; SCOPE.guest_directory += "_other"; DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(STORE.highest_battle_stage() == 0,"progression account isolation")
	SCOPE.guest_directory = original
	for number in range(2,11):
		var stage := "stage_%d" % number
		check(STORE.battle_stage_unlocked(stage),"next stage enters: "+stage)
		entry = ticket(stage)
		check(STORE.award_run(stage,entry,900,200,true).success,"ordered victory: "+stage)
	check(STORE.highest_battle_stage() == 10 and not STORE.battle_stage_unlocked("stage_11"),"final stage bounded")
	# Shared authored panel keeps the same controls for both battle modes.
	var main = load("res://src/main/Main.tscn").instantiate()
	check(main.get_node("HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/BGMRow/Slider") != null,"demon settings paths survive extraction")
	main.free()
	var paid := STAMINA.try_enter("stage_1",true,-1,false)
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"ranged_rookie","hero_entry":paid})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(scene)
	if not scene.entry_ready: await scene.entry_started
	check(is_instance_valid(scene.battle),"actual HeroMode entry")
	scene.gameplay_settings_path = original+"/gameplay.cfg"
	var audio := root.get_node("AudioSettings")
	var previous_audio_path: String = audio.config_path
	var previous_audio := [audio.bgm_level,audio.sfx_level,audio.bgm_muted,audio.sfx_muted]
	audio.config_path = original+"/audio.cfg"
	scene._pause(); scene._open_settings()
	var tabs: TabContainer = scene.settings_panel.get_node("Panel/Margin/VBox/SettingsTabs")
	check(tabs.get_tab_count() == 2 and tabs.get_node("Gameplay/CameraLock").disabled and tabs.get_node("Gameplay/CameraLock").button_pressed,"full settings with locked checked camera")
	tabs.current_tab = 1
	await capture("hero-settings")
	var paused_clock: float = scene.battle.run_metrics.elapsed_seconds
	await create_timer(0.15).timeout
	check(scene.battle.run_metrics.elapsed_seconds == paused_clock and not scene.pad.enabled,"settings freeze simulation and movement")
	scene._set_battle_frame(false)
	check(not scene.battle_frame.visible and scene.get_node("BattleView").offset_left == 0,"frame toggle affects actual battlefield")
	var saved := ConfigFile.new(); saved.load(scene.gameplay_settings_path)
	check(saved.get_value("gameplay","battle_frame_enabled",true) == false and not saved.has_section_key("gameplay","camera_view_locked"),"frame saves without overwriting demon camera preference")
	scene._set_audio_level(3,true); scene._set_audio_level(4,false)
	scene._set_audio_mute(true,true); scene._set_audio_mute(true,false)
	check(audio.bgm_level == 3 and audio.sfx_level == 4 and audio.bgm_muted and audio.sfx_muted,"both sound sliders and mute switches apply")
	check(scene.get_node("HeroBGMManager")._user_muted and tabs.get_node("Sound/BGMRow/Value").text == "3","actual BGM manager and UI update")
	audio.set_bgm_level(previous_audio[0]); audio.set_sfx_level(previous_audio[1]); audio.set_bgm_muted(previous_audio[2]); audio.set_sfx_muted(previous_audio[3])
	audio.config_path = previous_audio_path
	scene._set_battle_frame(true); scene._resume()
	check(scene.pad.enabled and not scene.settings_panel.visible and not scene.battle.external_pause,"resume closes settings and unpauses")
	await capture("hero-battle")
	scene.queue_free(); await process_frame
	# Every kit casts all six weapons using the real Hero/Battle actors.
	for hero_id in WEAPONS.HERO_WEAPONS:
		var battle = load("res://src/battle/Battle.tscn").instantiate()
		battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = String(hero_id)
		root.add_child(battle); battle.set_external_pause(true)
		var hero = battle.hero; var runtime = hero.player_weapons
		var target = battle._spawn_monster("orc",hero.position+Vector2(120,0),0.0,false,{})
		target.set_physics_process(false); target.max_hp = 100000; target.current_hp = 100000
		await physics_frame
		var patterns: Dictionary = {}
		for id in WEAPONS.weapon_pool(hero_id):
			if runtime.identity != null:
				if runtime.identity.archetype == "pistol_gunner": hero.gunner_ammo = hero.gunner_magazine_size; hero.gunner_reloading = false; hero.gunner_reload_timer = 0
				# Like ammo above: each weapon is judged alone, so earlier casts must not starve its gas.
				if runtime.identity.archetype == "alchemist_chemical": hero.alchemist_gas = hero.alchemist_gas_max
				for actor in runtime.identity.native_actors:
					if is_instance_valid(actor) and actor.active: battle.recycle_projectile(actor,String(actor.get_meta("identity_pool_key","")))
			runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.cooldowns.clear()
			for field in runtime.fields: field.left = 0.0
			for shot in runtime.projectiles: shot.active = false
			# Delivery emitters (2026-10-15) persist like fields; clear them so each weapon is judged alone.
			for slot in runtime.delivery.slots: slot.left = 0.0
			check(runtime.add(String(id)),"equips own weapon: "+String(id))
			patterns[WEAPONS.WEAPONS[id].pattern] = true
			var weapon: Dictionary = WEAPONS.WEAPONS[id]
			var distance: float = float(weapon.range)*float(weapon.get("orbit_ratio",0.7)) if String(weapon.pattern) == "orbit" else 120.0
			if String(weapon.pattern) == "poison" and bool(weapon.get("field_follow",false)): distance = minf(distance,float(weapon.range)*float(weapon.get("field_radius_ratio",0.45))*0.5)
			# Persistent delivery emitters (2026-10-15) damage inside clampf(reach*0.32,45,180).
			var delivery_rule: Dictionary = runtime.DELIVERY.RULES.spec(String(id),weapon)
			var delivery_reach: float = GEOMETRY.reach(runtime.stats_for(String(id)),1,false)
			if not delivery_rule.is_empty():
				distance = delivery_reach*float(weapon.get("orbit_ratio",0.7)) if String(delivery_rule.mode) == "orbit" else minf(distance,clampf(delivery_reach*0.32,45.0,180.0)*0.5)
			# Since 2026-10-16 summoner non-summon weapons cast from a rotating active summon;
			# park the summons on the hero so the cast origin is the hero for this probe.
			if String(weapon.owner) == "summoner_hero" and String(weapon.pattern) != "summon":
				for key in battle.active_hero_summons:
					var summon = battle.active_hero_summons[key]
					if is_instance_valid(summon): summon.global_position = hero.global_position
			target.position = hero.position+Vector2(distance,0)
			preload("res://src/monsters/monster_runtime_common.gd").notify_forced_position_change(target)
			await physics_frame
			# Summon weapons ship their own effect sequence since 2026-10-14; only native scenes reuse art.
			var uses_native_art: bool = runtime.native_skills.SCENES.has(String(weapon.pattern))
			check(runtime.art[id].is_empty() if uses_native_art else not runtime.art[id].is_empty(),"native art reused or shipped sequence cached: "+String(id))
			var before: int = target.current_hp
			runtime.tick(0.01)
			for step in 12: runtime.tick(0.1)
			# Delivery emitters hit after their warning/landing delay or when an orbiting orb's
			# contact tick lines up with the target; give them up to 3 more seconds.
			if not delivery_rule.is_empty():
				for step in 60:
					if target.current_hp < before: break
					runtime.tick(0.05)
			var native_basic: bool = runtime.identity != null and runtime.identity.spec.has("native_basic") and id == runtime.identity.starter
			var native: bool = native_basic or String(WEAPONS.WEAPONS[id].pattern) in ["piercer","meteor","ice_pillar","singularity","summon"]
			if native_basic:
				battle.set_external_pause(false); hero.set_physics_process(false); target.set_physics_process(false)
				await create_timer(1.0).timeout
				battle.set_external_pause(true)
				check(target.current_hp < before,"original native basic attack actually hits")
			if native and not native_basic and String(weapon.pattern) != "summon":
				var pool_key: String = runtime.native_skills.SCENES[String(weapon.pattern)][1]
				var capacity: int = runtime.native_skills.SCENES[String(weapon.pattern)][2]
				check(battle.projectile_pools[pool_key].size() < capacity,"original native skill activates: "+String(id))
				for actor in runtime.native_skills.actors_by_pattern[String(weapon.pattern)]:
					var active: bool = bool(actor.active) if String(weapon.pattern) == "piercer" or String(weapon.pattern) == "ice_pillar" else int(actor.state) != 0
					if not active: continue
					check(bool(actor.get_meta("survival_geometry",false)),"survival-only geometry cannot affect demon actors")
					if String(weapon.pattern) != "ice_pillar":
						var bounds: Rect2 = actor.get_meta("survival_visual_bounds",Rect2())
						check(bounds.has_area(),"native alpha bounds warmed before combat")
						if String(weapon.pattern) == "piercer":
							var size: Vector2 = bounds.size*actor.visual.scale
							check(size.x <= 116.001 and size.y <= 56.001,"piercing visual inside real collision rectangle")
					if actor.visual is AnimatedSprite2D: check(actor.visual.sprite_frames.get_frame_count(actor.visual.animation) > 0,"native animation has real textures: "+String(id))
					else: check(actor.visual.texture != null,"native effect has real texture: "+String(id))
				# Baseline at the pause itself: the manual ticks above also run identity skills
				# (e.g. the sage's periodic phase), which may legitimately hit before this point.
				var paused_hp: int = target.current_hp
				await create_timer(0.1).timeout
				check(target.current_hp == paused_hp,"paused native skill cannot deal damage: "+String(id))
				battle.set_external_pause(false); hero.set_physics_process(false); target.set_physics_process(false)
				await create_timer(1.6).timeout
				battle.set_external_pause(true)
				check(target.current_hp < before,"original native skill actually hits: "+String(id))
				runtime.levels[id] = WEAPONS.MAX_LEVEL; runtime.evolved[id] = true
				runtime._cast(String(id))
				var nodes_before: int = battle.get_child_count()
				runtime._cast(String(id))
				check(battle.get_child_count() == nodes_before,"evolved native saturation never allocates: "+String(id))
				if weapon.has("native_radius"):
					var largest := 0.0
					for actor in runtime.native_skills.actors_by_pattern[String(weapon.pattern)]:
						largest = maxf(largest,float(actor.impact_radius) if String(weapon.pattern) == "meteor" else float(actor.effect_radius))
					check(largest >= (float(weapon.native_radius)+10.0*float(weapon.native_radius_per_level))*1.25,"native evolution actually grows radius: "+String(id))
			check(target.current_hp < before or native,"real weapon damage or native actor activation: "+String(id))
			check(runtime.projectiles.size() == 64 and runtime.effects.size() == 48 and runtime.fields.size() == 8,"fixed effect/shot limits: "+String(id))
			if String(WEAPONS.WEAPONS[id].pattern) == "summon": check(hero._get_active_summon_count() > 0 and hero._get_active_summon_count() <= 3,"real summon count bounded")
		check(patterns.size() >= 3,"kit has at least three distinct actions: "+String(hero_id))
		if String(hero_id) == "summoner_hero":
			check(hero._get_active_summon_count() <= 3,"summoner saturation bounded across weapons")
			var chest = load("res://src/battle/TreasureChest.tscn").instantiate()
			battle.add_child(chest); chest.position = hero.position+Vector2(40,0)
			battle._register_treasure_chest(chest)
			await physics_frame
			var chest_hp: int = chest.current_hp
			runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.add("summoner_hero_gate_hound")
			runtime._cast("summoner_hero_gate_hound")
			check(chest.current_hp < chest_hp,"all-summon build can still open a nearby chest")
		battle.queue_free(); await process_frame
	print("HERO_SURVIVAL_REVISION_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
func original_scope_path() -> String:
	return SCOPE.guest_directory.trim_suffix("/")
