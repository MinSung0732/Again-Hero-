extends SceneTree
## Real species scenes and pooled projectiles: swaps, animation, rotation and recycling.
const H := preload("res://tests/frontier_monsters_smoke.gd")
const D := preload("res://src/data/frontier_monster_catalog.gd")
const C := preload("res://src/data/monster_catalog.gd")
const ART := preload("res://src/data/frontier_projectile_art_catalog.gd")
var checks := 0
var failures := 0

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var arena := H.Arena.new()
	root.add_child(arena)
	var target := H.Target.new()
	arena.add_child(target)
	arena.hero = target
	arena.registry.activate(target)
	target.position = Vector2(200,0)
	var ranged_count := 0
	for id in D.DEFINITIONS:
		var data: Dictionary = D.DEFINITIONS[id]
		if not data.behavior.get("projectile",false): continue
		ranged_count += 1
		check(data.behavior.get("projectile_art","") == id and ART.PROFILES.has(id),id+" catalog art selected")
		var actor = C.get_scene(id).instantiate()
		C.apply_runtime_base_stats(actor,id)
		actor.configure_combat_context(target,arena)
		arena.add_child(actor)
		actor.set_physics_process(false)
		actor._attack_target(target)
		var bolt = arena.bolts[0]
		bolt.set_physics_process(false)
		check(arena.bolts.size() == 1,id+" same bounded bolt reused")
		check(bolt.visual_frames == ART.PROFILES[id].frames,id+" correct shared resources")
		check(bolt.visual_frames.get_frame_count(&"projectile") == 4,id+" four frame loop")
		check(bolt.visual_frames.get_animation_loop(&"projectile"),id+" loops")
		check(bolt.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,id+" nearest filter")
		check(bolt.visual_frame == 0 and bolt.visual_clock == 0.0,id+" pool restarts first frame")
		check(bolt.rotation == 0.0 and bolt.is_visible(),id+" aims right and visible")
		check(bolt.speed == actor.projectile_speed and bolt.damage == actor.attack_damage,id+" unchanged gameplay stats")
		bolt._physics_process(.09)
		check(bolt.visual_frame == 1,id+" flight advances")
		bolt._physics_process(.25)
		check(bolt.visual_frame == 0,id+" four-frame loop wraps")
		var before: int = target.current_hp
		bolt._physics_process(2.0)
		check(target.current_hp == before-actor.attack_damage,id+" real swept collision damage once")
		check(not bolt.active and not bolt.is_visible() and not bolt.is_physics_processing(),id+" pool inactive hidden")
		check(bolt.visual_frames == null and bolt.visual_clock == 0.0 and bolt.visual_frame == 0,id+" visual references and time cleared")
		check(not bolt.is_in_group("monster_projectiles"),id+" group cleared")
		for skill in data.elite_skills:
			if skill.kind != "fan": continue
			check(actor.try_cast_elite_skill(skill),id+" real elite fan fires")
			var flying := 0
			var turned := 0
			for shot in arena.bolts:
				shot.set_physics_process(false)
				if not shot.active: continue
				flying += 1
				if absf(shot.rotation) > .001: turned += 1
				check(shot.visual_frames == ART.PROFILES[id].frames,id+" elite inherits art")
				check(is_equal_approx(shot.rotation,shot.direction.angle()),id+" fan art follows trajectory")
				shot._finish()
			check(flying == 3 and turned == 2,id+" all three fan directions")
		# Keep exactly one pooled instance between species; exercise art swaps.
		while arena.bolts.size() > 1:
			var extra = arena.bolts.pop_back()
			arena.pool.erase(extra)
			extra.free()
		actor.free()
	check(ranged_count == ART.PROFILES.size(),"every ranged species has art, no unused profiles")
	arena.free()
	print("FRONTIER_PROJECTILE_ART checks=",checks," failures=",failures)
	quit(1 if failures else 0)
