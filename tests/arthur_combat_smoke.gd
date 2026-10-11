extends SceneTree
const SCENE := preload("res://src/monsters/Arthur.tscn")
const DATA := preload("res://src/data/arthur_behavior_catalog.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const BLESSING := preload("res://src/systems/arthur_blessing.gd")
const GATE := preload("res://src/monsters/arthur_avalon_gate.gd")
var failures := 0
var checks := 0
class Target extends Node2D:
	var current_hp := 1000000
	var dying := false
	var damage := 0
	var invulnerable := false
	func take_damage(amount: int, _source: Node) -> bool:
		if invulnerable: return false
		damage += amount
		return true
	func take_status_damage(amount: int, _source: Node) -> bool:
		damage += amount
		return true
class Ally extends Node2D:
	var current_hp := 1000
	var max_hp := 2000
	var dying := false
	var attack_cooldown := 2.0
class Authority extends Node2D:
	var hero: Node2D
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var command_regen_per_second := 25.0
	var active_monsters: Dictionary = {}
	var enemies: Array = []
	func fill_active_enemy_summons(out: Array) -> void:
		out.clear()
		out.append_array(enemies)
	func fill_monsters_near(_point: Vector2, _radius: float, out: Array) -> void:
		out.clear()
		for id in active_monsters: out.append(active_monsters[id])
	func get_transcendent_aura_modifier(_actor: Node2D, _kind: String) -> float: return 1.0
	func invalidate_monster_spatial_grid() -> void: pass
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ARTHUR: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var runtime = RUNTIME.new()
	runtime.configure("arthur",DATA.RULES)
	for i in range(39): runtime.record_summon("tank")
	for i in range(50): runtime.record_ally_death()
	check(not runtime.ready,"39/50 locked")
	runtime.record_summon("")
	check(not runtime.ready,"augment summon excluded")
	check(runtime.record_summon("tank"),"40/50 ready")
	runtime.consume()
	check(not runtime.ready and not runtime.record_summon("tank"),"single summon")
	var authority := Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	var secondary := Target.new()
	authority.add_child(secondary)
	authority.enemies.append(secondary)
	var ally := Ally.new()
	authority.add_child(ally)
	authority.active_monsters[ally.get_instance_id()] = ally
	for level in range(6):
		var actor = SCENE.instantiate()
		actor.configure_combat_context(target,authority)
		actor.configure_transcendence(40,level)
		authority.add_child(actor)
		actor.set_physics_process(false)
		authority.active_monsters[actor.get_instance_id()] = actor
		check(actor.max_hp==2600 and actor.attack_damage==230,"snapshot level "+str(level))
		check(actor.get_gauge_regen()==15 and actor.move_speed==300 and actor.attack_cooldown==1.75,"base/regen")
		check(is_equal_approx(actor.block_chance(),0.15 if level==0 else 0.30 if level==1 else 0.50),"block tiers")
		actor._physics_process(0.01)
		check(int(ally.get_meta("support_shield_hp",0))==520,"arrival shield")
		actor._physics_process(0.01)
		check(int(ally.get_meta("support_shield_hp",0))==520,"arrival once")
		actor.arrival_remaining = 0
		actor.gauge = 150
		actor._try_cast()
		check(actor.gauge==100 and actor.excalibur_remaining==10 and actor.cooldowns[0]==50,"Excalibur cost/cooldown")
		actor.position = Vector2.ZERO
		target.position = Vector2(100,0)
		ally.position = Vector2(50,0)
		if level>=5: actor.current_hp = 2100
		actor._start_dash_channel()
		check(actor.channel.active and actor.visual.animation==&"skill" and actor.visual._one_shot_locked,"channel held skill")
		actor.visual._physics_process(0.1)
		check(actor.visual.animation==&"skill" and actor.visual.frame==0,"pending locomotion cannot override held skill")
		actor.channel.tick(0.5,false)
		actor._finish_channel()
		check(actor.collision_layer==0 and actor.collision_mask==0,"collision ignored")
		check(actor.visual.animation==&"skill" and actor.fx_age[0]==0,"rush holds skill and starts effect")
		check(actor.dash_trail.ages.size()==DATA.DASH_TRAIL_POOL and actor.dash_trail.ages.count(0.0)==1,"retained trail begins once")
		var trail_children: int = actor.dash_trail.get_child_count()
		check(actor.front_effects.z_as_relative==false and actor.front_effects.z_index==DATA.COMBAT_EFFECT_Z,"foreground effect layer")
		target.damage = 0
		secondary.damage = 0
		secondary.position = Vector2(500,0)
		target.invulnerable = false
		actor._tick_dash(1000.0/900.0)
		check(actor.dash_trail.ages.count(0.0)==DATA.DASH_TRAIL_POOL,"large tick trail work bounded to pool")
		check(actor.dash_trail.get_child_count()==trail_children,"rush creates no trail nodes")
		var first_trail: Vector2 = actor.dash_trail.poses[actor.dash_trail.next_slot].origin
		var next_trail: Vector2 = actor.dash_trail.poses[(actor.dash_trail.next_slot+1)%DATA.DASH_TRAIL_POOL].origin
		check(is_equal_approx(first_trail.distance_to(next_trail),DATA.DASH_TRAIL_SPACING),"spaced world trail snapshots")
		check(actor.dash_trail.textures[0]==actor.visual.sprite_frames.get_frame_texture(&"skill",0),"trail shares actual skill texture")
		actor.dash_trail.tick(DATA.DASH_TRAIL_LIFETIME)
		check(actor.dash_trail.ages.count(-1.0)==DATA.DASH_TRAIL_POOL and actor.dash_trail.textures[0]==null,"trail fade expires and releases texture slots")
		check(target.damage==575,"first swept hit")
		check(secondary.damage==575,"all enemies on path are hit")
		check(int(ally.get_meta("support_shield_hp",0))==910,"dash shields once")
		if level>=5:
			target.invulnerable = true
			actor._tick_dash(1000.0/1350.0)
			actor._tick_dash(1000.0/1350.0)
			check(target.damage==1495,"two 80percent rushes bypass invulnerability")
		check(not actor.dash_collision_disabled and (level<5 or actor.current_hp==2175),"collision restored and three-hit missingHP heal")
		check(actor.attack_timer==0,"haste cooldown advances during rush, no extra end delay")
		check(not actor.visual._one_shot_locked,"rush restores locomotion lock")
		actor.position = Vector2.ZERO
		ally.position = Vector2.ZERO
		target.invulnerable = false
		actor.cast_blessing()
		var capacity := 3400 if level>=4 else 2000
		check(int(ally.get_meta("arthur_blessing_hp"))==capacity,"recipient maxHP blessing")
		var blessing = ally.get_node("ArthurBlessing")
		check(blessing.remaining==(5 if level>=4 else 3),"duration tiers")
		target.damage = 0
		ally.set_meta("support_shield_hp",0)
		check(COMMON.consume_support_shield(ally,capacity)==0,"blessing absorption")
		await process_frame
		check(target.damage==capacity/2,"break reflects once")
		actor.cast_blessing()
		blessing.clear()
		target.damage = 0
		check(int(ally.get_meta("arthur_blessing_hp"))==0 and target.damage==0,"expiration no reflect")
		var gate = GATE.new()
		gate.setup(authority,actor,40 if level>=3 else 30)
		authority.add_child(gate)
		gate.set_physics_process(false)
		check(gate.z_index==0 and not gate is CollisionObject2D,"gate shares decor depth without collision")
		ally.current_hp = 1000
		gate._refresh_members()
		check(is_equal_approx(ally.attack_cooldown,2.0/1.5),"gate haste")
		check(is_equal_approx(COMMON.get_external_movement_multiplier(ally),1.25),"gate speed")
		for i in range(50): gate._physics_process(0.1)
		check(ally.current_hp==1050,"missing HP five percent over five seconds")
		ally.position = Vector2(601,0)
		gate._refresh_members()
		check(ally.attack_cooldown==2 and not ally.get_meta("arthur_gate_active"),"exit restores")
		ally.position = Vector2.ZERO
		ally.current_hp = ally.max_hp
		gate._refresh_members()
		for i in range(50): gate._physics_process(0.1)
		check(int(ally.get_meta("support_shield_hp",0))==100,"full HP shield conversion")
		gate.age = gate.duration
		gate._physics_process(0.01)
		check(ally.attack_cooldown==2 and gate.buffed_count==0,"expiration restores buffs")
		gate.free()
		ally.set_meta("support_shield_hp",0)
		ally.set_meta("support_shield_capacity",0)
		authority.active_monsters.erase(actor.get_instance_id())
		actor.free()
	authority.free()
	print("ARTHUR_COMBAT: %s (%d checks)"%["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
