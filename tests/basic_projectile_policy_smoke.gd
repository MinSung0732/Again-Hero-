extends SceneTree
const BEFORE := preload("res://tests/BasicBefore.tscn")
const AFTER := preload("res://src/hero/HeroProjectile.tscn")
const VOLLEY := preload("res://src/hero/projectile_volley.gd")
var checks := 0
var failed := false
class Target extends Node2D:
	var hp := 10000
	var total := 0
	var hits := 0
	var reflect := false
	var reflection_calls := 0
	var kinds: Array = []
	var on_hit: Callable
	func take_damage(amount: int) -> void:
		hp -= amount; total += amount; hits += 1
		kinds.append(get_meta("incoming_attack_kind", "none"))
		if on_hit.is_valid(): on_hit.call()
	func try_reflect_projectile(_projectile, _damage, _source) -> bool:
		reflection_calls+=1
		return reflect
	func reset() -> void:
		hp=10000; total=0; hits=0; reflection_calls=0; kinds.clear(); reflect=false; on_hit=Callable()
	func state() -> Array: return [hp,total,hits,reflection_calls,kinds.duplicate()]
class Caster extends Node2D:
	var targets: Array = []
	var factor := 1.5
	var multiplier_calls := 0
	var spatial_calls := 0
	func get_purifier_holy_damage_multiplier(_target: Node) -> float:
		multiplier_calls+=1
		return factor
	func _get_monster_nodes_near(_origin,_radius) -> Array:
		spatial_calls+=1
		return targets
class Arena extends Node2D:
	var releases := 0
	func recycle_projectile(projectile: Node, key: String) -> void:
		assert(key=="hero_basic_projectile")
		releases+=1
		projectile.deactivate_for_pool()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failed=true; push_error(message)
func _initialize() -> void: run.call_deferred()
func snapshot(shot, targets: Array, caster: Caster, arena: Arena) -> Dictionary:
	var states: Array=[]
	for t in targets: states.append(t.state())
	return {"targets":states,"active":shot.active,"impacted":shot.has_impacted,"physics":shot.is_physics_processing(),"sprite":shot.projectile_sprite.visible,"animation":shot.projectile_sprite.animation,"scale":shot.projectile_sprite.scale,"rotation":shot.rotation,"holy_calls":caster.multiplier_calls,"spatial_calls":caster.spatial_calls,"releases":arena.releases}
func prepare(shot, caster, targets, arena, id, amount, radius, ratio, volley=null) -> void:
	for t in targets:t.reset()
	caster.multiplier_calls=0; caster.spatial_calls=0; arena.releases=0
	shot.position=Vector2.ZERO
	shot.setup(Vector2(2,1),amount,680,420,id,radius,ratio,volley)
	shot.set_physics_process(false)
func run() -> void:
	if "--missing-art" in OS.get_cmdline_user_args():
		run_missing_art()
		return
	var arena:=Arena.new(); root.add_child(arena)
	var caster:=Caster.new(); arena.add_child(caster); caster.add_to_group("hero")
	var targets: Array=[]
	for i in 4:
		var target:=Target.new(); arena.add_child(target); target.add_to_group("treasure_chests" if i==3 else "monsters")
		target.position=Vector2(20+40*i,0); targets.append(target)
	caster.targets=targets.slice(0,3)
	var old=BEFORE.instantiate(); var current=AFTER.instantiate(); arena.add_child(old); arena.add_child(current)
	var scenarios:=0
	for id in ["","ranged_rookie","purifier_hero","future_hero"]:
		for amount in [0,1,7,34,101]:
			for radius in [0.0,64.0,100.0]:
				for ratio in [-0.5,0.0,0.5,1.0,1.5]:
					caster.factor=0.5+float(scenarios%4)*0.5
					prepare(old,caster,targets,arena,id,amount,radius,ratio)
					old._on_body_entered(targets[0]); var expected:=snapshot(old,targets,caster,arena)
					prepare(current,caster,targets,arena,id,amount,radius,ratio)
					current._on_body_entered(targets[0]); check(snapshot(current,targets,caster,arena)==expected,"direct/splash/rounding/pool parity scenario "+str(scenarios))
					scenarios+=1
	for id in ["ranged_rookie","purifier_hero","future_hero"]:
		prepare(old,caster,targets,arena,id,34,100,0.5); targets[0].reflect=true
		old._on_body_entered(targets[0]); var expected:=snapshot(old,targets,caster,arena)
		prepare(current,caster,targets,arena,id,34,100,0.5); targets[0].reflect=true
		current._on_body_entered(targets[0]); check(snapshot(current,targets,caster,arena)==expected,"reflection skips splash and recycles: "+id)
		prepare(old,caster,targets,arena,id,34,0,0); old._on_body_entered(targets[3]); expected=snapshot(old,targets,caster,arena)
		prepare(current,caster,targets,arena,id,34,0,0); current._on_body_entered(targets[3]); check(snapshot(current,targets,caster,arena)==expected,"chest never receives holy target multiplier: "+id)
		prepare(old,caster,targets,arena,id,34,0,0); old._check_chest_sweep(Vector2(100,0),Vector2(180,0)); expected=snapshot(old,targets,caster,arena)
		prepare(current,caster,targets,arena,id,34,0,0); current._check_chest_sweep(Vector2(100,0),Vector2(180,0)); check(snapshot(current,targets,caster,arena)==expected,"actual chest sweep parity: "+id)
		prepare(old,caster,targets,arena,id,34,0,0); old._physics_process(1.0); expected=snapshot(old,targets,caster,arena)
		prepare(current,caster,targets,arena,id,34,0,0); current._physics_process(1.0); check(snapshot(current,targets,caster,arena)==expected,"movement and range expiry: "+id)
	prepare(old,caster,targets,arena,"purifier_hero",100,100,0.5); caster.factor=1.5
	targets[0].on_hit=func():caster.factor=2.0
	old._on_body_entered(targets[0]); var callback_expected:=snapshot(old,targets,caster,arena)
	prepare(current,caster,targets,arena,"purifier_hero",100,100,0.5); caster.factor=1.5
	targets[0].on_hit=func():caster.factor=2.0
	current._on_body_entered(targets[0])
	check(snapshot(current,targets,caster,arena)==callback_expected and targets[1].total==100,"damage callback changes remain visible to subsequent splash targets")
	# Direct source ID writes are supported by existing tests/callers.
	prepare(current,caster,targets,arena,"ranged_rookie",100,0,0)
	current.source_hero_id="purifier_hero"; caster.factor=1.5
	current._on_body_entered(targets[0])
	check(targets[0].total==150,"identity setter updates combat policy before next pooled setup")
	var record:=VOLLEY.new()
	prepare(current,caster,targets,arena,"ranged_rookie",100,0,0,record)
	current._on_body_entered(targets[0]); current.setup(Vector2.RIGHT,100,680,420,"ranged_rookie",0,0,record)
	current._on_body_entered(targets[0])
	check(targets[0].hits==1 and current.active and not current.has_impacted,"shared volley rejects repeat without retiring sibling")
	current._on_body_entered(targets[1]); check(targets[1].total==100,"sibling can claim another target")
	current.setup(Vector2.RIGHT,100,680,420,"purifier_hero")
	var frames=current.projectile_sprite.sprite_frames
	check(frames.get_frame_count("fly")==6 and frames.get_frame_count("impact")==4 and frames.get_animation_speed("fly")==14.0 and frames.get_animation_speed("impact")==18.0,"holy frame order/count/rates preserved")
	var second=AFTER.instantiate(); arena.add_child(second); second.setup(Vector2.RIGHT,34,680,420,"purifier_hero")
	check(second.projectile_sprite.sprite_frames==frames,"instances reuse one immutable SpriteFrames per profile")
	second._on_body_entered(targets[2]); second._on_projectile_animation_finished()
	check(not second.active,"impact completion recycles pooled projectile")
	current.setup(Vector2.RIGHT,34,680,420,"ranged_rookie")
	check(current._impact_animation.is_empty() and current._damage_multiplier_method.is_empty() and current.projectile_sprite.scale==Vector2.ONE,"holy-to-rookie reuse resets policy and scale")
	check(current.projectile_sprite.sprite_frames.get_frame_count("fly")==4 and current.projectile_sprite.sprite_frames.get_animation_speed("fly")==12.0,"rookie visual data preserved")
	current.setup(Vector2.RIGHT,34,680,420,"future_hero")
	check(not current.projectile_sprite.visible and current.projectile_sprite.sprite_frames==null,"unknown hero retains circle fallback")
	check(current._frames_cache.size()==2,"known profiles alone occupy shared frame cache")
	arena.free()
	print("BASIC_PROJECTILE_POLICY scenarios=",scenarios," checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func run_missing_art() -> void:
	var arena:=Arena.new(); root.add_child(arena)
	var caster:=Caster.new(); arena.add_child(caster); caster.add_to_group("hero")
	var target:=Target.new(); arena.add_child(target); target.add_to_group("monsters"); caster.targets=[target]
	var old=BEFORE.instantiate(); var current=AFTER.instantiate(); arena.add_child(old); arena.add_child(current)
	for id in ["ranged_rookie","purifier_hero"]:
		prepare(old,caster,[target],arena,id,34,0,0)
		old._on_body_entered(target); var expected:=snapshot(old,[target],caster,arena)
		prepare(current,caster,[target],arena,id,34,0,0)
		check(not current.projectile_sprite.visible and current.projectile_sprite.sprite_frames==null,"missing flight images use circle fallback")
		current._on_body_entered(target)
		check(snapshot(current,[target],caster,arena)==expected and not current.active,"missing impact images preserve hit and pool release")
	arena.free()
	print("BASIC_PROJECTILE_MISSING_ART checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
