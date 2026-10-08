extends SceneTree
const SCENE := preload("res://src/monsters/Bulgasal.tscn")
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var failures := 0
class Target extends Node2D:
	var current_hp := 1000000
	var invulnerable := true
	var damage_taken := 0
	var hits := 0
	var stunned := 0.0
	var slowed := 1.0
	var slow_seconds := 0.0
	func take_damage(amount: int, source: Node) -> bool:
		return false if invulnerable else take_followup_damage(amount,source)
	func take_followup_damage(amount: int, _source: Node) -> bool:
		damage_taken += amount
		hits += 1
		return true
	func apply_stun(seconds: float) -> void: stunned = seconds
	func apply_slow(ratio: float, seconds: float) -> void:
		slowed = ratio
		slow_seconds = seconds
	func apply_healing_reduction(_seconds: float, _ratio: float) -> bool: return true
class Authority extends Node2D:
	var hero: Node2D
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var command_regen_per_second := 0.0
	var current_map_size := Vector2(2000,2000)
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BULGASAL_UPGRADE: "+message)
func run() -> void:
	var authority := Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	for level in range(6):
		var actor = SCENE.instantiate()
		actor.configure_combat_context(target,authority)
		actor.configure_transcendence(0,level)
		authority.add_child(actor)
		actor.set_physics_process(false)
		actor.pillars.set_physics_process(false)
		actor._set_phase("idle")
		actor.position = Vector2(500,500)
		target.position = actor.position
		target.invulnerable = true
		target.damage_taken = 0
		actor.resolve_rock_impact(target.position)
		check(target.damage_taken==(390 if level>=1 else 0),"level%d rock immunity bypass"%level)
		check(actor.fragment_states.count(1)==(8 if level>=2 else 0),"level%d eight fragments"%level)
		check(actor.pillars.states.size()==(13 if level>=3 else 8),"level%d fixed pool"%level)
		check(is_equal_approx(actor.get_eat_shield_ratio(),0.07 if level>=3 else 0.05),"level%d eat ratio"%level)
		actor.pillars.states[0]=2
		actor.pillars.shatter(0,true,true)
		check(int(actor.get_meta("support_shield_hp"))==int(round(1850*(0.07 if level>=3 else 0.05))),"level%d actual eaten shield"%level)
		actor.set_meta("support_shield_hp",0)
		actor.collision_layer=2
		actor.collision_mask=15
		actor._set_phase("burrow")
		var hp_before: int = actor.current_hp
		actor.take_damage(100)
		check(actor.current_hp==hp_before-(0 if level>=4 else 40),"level%d burrow damage immunity"%level)
		check(TARGETS.is_detectable(actor)==(level<4),"level%d burrow detection"%level)
		check(actor.collision_layer==(0 if level>=4 else 2) and actor.collision_mask==(12 if level>=4 else 15),"level%d burrow collision/terrain"%level)
		actor.pillars.states[0]=2
		actor.pillars.bodies[0].position=actor.position+Vector2(20,40)
		actor.pillars.bodies[0].collision_layer=3
		target.invulnerable=false
		var before: int = target.damage_taken
		actor._move_direction(Vector2.RIGHT,100,0.4)
		check(actor.pillars.states[0]==3 and target.damage_taken==before+195,"level%d swept burrow pillar aftershock"%level)
		actor.pillars.shatter_segment(actor.position,actor.position+Vector2(40,0))
		check(target.damage_taken==before+195,"pillar damage once")
		actor._end_burrow()
		check(actor.collision_layer==2 and actor.collision_mask==15 and TARGETS.is_detectable(actor),"level%d restore collision/detection"%level)
		actor.channel.begin(2)
		actor._set_phase("channel")
		check(COMMON.can_be_forced_moved(actor)==(level<5),"level%d common forced movement"%level)
		check(COMMON.can_receive_movement_slow(actor)==(level<5),"level%d common movement effect"%level)
		actor.apply_stun(1)
		actor.apply_silence(1)
		check(actor.channel.active==(level>=5),"level%d channel control immunity"%level)
		check(actor.get_leap_radius()==(250 if level>=5 else 125),"level%d stomp radius"%level)
		if level>=5:
			actor.set_meta("forced_movement_lock_until",Time.get_ticks_msec()+10000)
			actor.set_meta("stun_active",true)
			actor._physics_process(2)
			check(actor.phase=="launch","Lv5 focus completes despite control flags")
			actor.remove_meta("stun_active")
			actor.remove_meta("forced_movement_lock_until")
			actor.landing_position=actor.position
			actor._set_phase("land")
			target.position=actor.position+Vector2(200,0)
			before=target.damage_taken
			actor._physics_process(0.25)
			check(target.damage_taken==before+585,"actual upgraded landing outside original radius")
		actor.fragment_states.fill(0)
		actor._set_phase("idle")
		if level>=2:
			target.invulnerable=true
			target.position=Vector2(500,500)
			actor.resolve_rock_impact(target.position)
			var overlap_hits: int=target.hits
			before=target.damage_taken
			actor._tick_fragments(0.1)
			check(target.hits==overlap_hits+1 and target.damage_taken==before+195,"eight overlapping fragments share exactly one damage hit")
			check(actor.fragment_states.count(2)==8,"all eight fragment effects still burst")
			actor.resolve_rock_impact(Vector2(500,500))
			check(not actor.fragment_hit,"next cast resets shared hit guard")
			target.invulnerable=true
			target.position=Vector2(800,500)
			actor.resolve_rock_impact(Vector2(500,500))
			before=target.damage_taken
			actor._tick_fragments(0.5)
			check(target.damage_taken==before+195 and target.stunned==1,"swept fragment inner half damage/stun no tunneling")
			before=target.damage_taken
			actor._tick_fragments(0.1)
			check(target.damage_taken==before,"fragment hits once")
			target.position=Vector2(500,200)
			actor._tick_fragments(0.3)
			check(target.damage_taken==before,"moving into another ray later cannot receive a second hit")
			target.position=Vector2(625,500)
			actor._resolve_rock_area(Vector2(500,500),0.5)
			check(target.slowed==0.75 and target.slow_seconds==1,"halved slow reduction and duration")
			target.position=Vector2(651,500)
			before=target.damage_taken
			actor._resolve_rock_area(Vector2(500,500),0.5)
			check(target.damage_taken==before,"half outer radius excludes151")
			actor.resolve_rock_impact(Vector2(500,500))
			authority.external_pause=true
			actor._physics_process(1)
			check(actor.fragment_distances[0]==0,"pause freezes fragments")
			authority.external_pause=false
			actor._tick_fragments(2)
			actor._tick_fragments(0.6)
			check(actor.fragment_states.count(0)==8,"fixed fragment pool expires")
		for cue in actor.audio_bank.players:
			var player: AudioStreamPlayer=actor.audio_bank.players[cue]
			check(player.stream!=null and player.stream.get_length()>0 and player.bus==&"SFX" and player.max_polyphony==1,"loaded SFX "+cue)
		actor.audio_bank.stop_all()
		var sounds: int=actor.audio_bank.played_count
		actor.play_pillar_sound(false)
		for index in range(13): actor.play_pillar_sound(false)
		check(actor.audio_bank.played_count==sounds+1,"pillar batch does not amplify13 sounds")
		actor._set_phase("burrow")
		actor._begin_death()
		check(not actor.burrow_phased and TARGETS.is_detectable(actor) and actor.fragment_states.count(0)==8,"death clears immunity/fragments")
		actor.pillars.queue_free()
		actor.queue_free()
		await process_frame
	var wall := StaticBody2D.new()
	wall.collision_layer=8
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size=Vector2(20,400)
	shape.shape=rectangle
	wall.add_child(shape)
	authority.add_child(wall)
	wall.position=Vector2(600,500)
	var phased = SCENE.instantiate()
	phased.configure_combat_context(target,authority)
	phased.configure_transcendence(0,4)
	authority.add_child(phased)
	phased.set_physics_process(false)
	phased.position=Vector2(500,500)
	phased._set_phase("burrow")
	await physics_frame
	phased._move_direction(Vector2.RIGHT,10000,1.0/60.0)
	check(phased.position.x<=568.1,"Lv4 phasing still collides with actual arena wall")
	check(phased.position.x>500,"phased body moved toward wall")
	phased._end_burrow()
	authority.queue_free()
	await process_frame
	print("BULGASAL_TRANSCENDENCE: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
