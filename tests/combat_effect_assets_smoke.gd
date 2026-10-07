extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("COMBAT_FX: " + message)

func effect(actor: Node, kind: String):
	return actor.get_node_or_null("StatusFX_" + kind)

func flush(fx: Node) -> void:
	fx._visibility_check_timer = 0.0
	fx._process(0.0)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://effect_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	hero.max_hp = 10000
	hero.current_hp = 10000
	hero.position = Vector2(1000, 1000)
	var succubus = battle._spawn_monster("succubus", Vector2(1200, 1000))
	var shaman = battle._spawn_monster("powwow_mummy", Vector2(1300, 1000))
	var ally = battle._spawn_monster("slime", Vector2(1400, 1000))
	var knight = battle._spawn_monster("dullahan", Vector2(1500, 1000))
	for actor in [succubus, shaman, ally, knight]:
		actor.set_physics_process(false)
	check(hero.apply_charm(succubus, 2.0), "actual charm")
	check(hero.apply_petrify(2.5), "actual petrify")
	check(hero.apply_bleed(5.0, succubus), "actual bleed")
	check(hero.apply_healing_reduction(2.0, 0.3), "actual healing reduction")
	for kind in ["charm", "petrify", "bleed", "healing_reduction"]:
		check(effect(hero, kind) != null and effect(hero, kind).visible, "accepted status immediately shows " + kind)
		check(effect(hero, kind).speed_scale == 0.0, "paused status animation freezes " + kind)
	var count: int = hero.get_child_count()
	check(not hero.apply_bleed(5.0, succubus) and hero.get_child_count() == count, "rejected reapplication creates no extra visual")
	hero.charm_timer = 0.0
	hero.petrify_timer = 0.0
	hero.bleed_timer = 0.0
	hero.healing_reduction_timer = 0.0
	for kind in ["charm", "petrify", "bleed", "healing_reduction"]:
		flush(effect(hero, kind))
		check(not effect(hero, kind).visible and not effect(hero, kind).is_processing(), "expired status stops polling " + kind)
	shaman._apply_buff(ally, 0)
	shaman._apply_buff(ally, 2)
	check(effect(ally, "support_courage").visible and effect(ally, "support_agility").visible, "actual courage and agility")
	var courage = effect(ally, "support_courage")
	shaman._apply_buff(ally, 0)
	check(effect(ally, "support_courage") == courage, "buff refresh reuses node")
	ally.set_meta("visual_lod_suspended", true)
	flush(courage)
	check(not courage.visible, "offscreen effect suspends")
	ally.set_meta("visual_lod_suspended", false)
	flush(courage)
	check(courage.visible, "active offscreen effect resumes")
	battle.support_buff_runtime.tick(11.0)
	flush(courage)
	flush(effect(ally, "support_agility"))
	check(not courage.visible and not effect(ally, "support_agility").visible, "buff expiry hides both")
	ally.current_hp = int(ally.max_hp / 2)
	var hp: int = ally.current_hp
	shaman._apply_buff(ally, 1)
	check(ally.current_hp > hp and effect(ally, "support_heal").visible, "actual recovery pulse")
	var healing = effect(ally, "support_heal")
	ally.current_hp = ally.max_hp
	shaman._apply_buff(ally, 1)
	check(effect(ally, "support_heal") == healing, "zero recovery creates no new effect")
	knight.current_hp = int(knight.max_hp * 0.1)
	knight.danger_state = 1
	knight.state_timer = 0.0
	knight._tick_danger(0.0)
	check(knight.danger_state == 2 and effect(knight, "dullahan_regen").visible, "actual rest regeneration starts aura")
	knight._tick_danger(4.0)
	flush(effect(knight, "dullahan_regen"))
	check(knight.danger_state == 0 and not effect(knight, "dullahan_regen").visible, "rest end hides aura")
	var cut: Dictionary = {}
	for skill in CATALOG.MONSTERS.succubus.elite_skills:
		if String(skill.get("kind", "")) == "cut":
			cut = skill
	hero.charm_immunity_timer = 100.0
	hero.invulnerability_timer = 0.0
	hp = hero.current_hp
	check(succubus.try_cast_elite_skill(cut), "actual elite cut")
	check(hero.current_hp < hp and effect(hero, "succubus_cut").visible, "cut damage and visual")
	for child in hero.get_children():
		if child is FX and child.effect_type == "slow":
			check(child.sprite_frames.get_frame_count("fx") == 8 and child.scale == Vector2(0.2, 0.2), "updated eight-frame slow and canvas scaling")
	for kind in FX.CATALOG.EFFECTS:
		check(FX._frames_cache[kind].get_frame_count("fx") == 8, "all uploaded frames loaded " + kind)
	# AnimatedSprite2D itself completes the one-shot clips and keeps their nodes.
	ally.move_speed = 0.0
	ally.attack_timer = 1000.0
	ally.set_physics_process(true)
	flush(healing)
	await create_timer(0.8).timeout
	check(not healing.visible and not healing.is_processing(), "one-shot animation completion sleeps reusable node")
	ally.set_physics_process(false)
	ally.current_hp = int(ally.max_hp / 2)
	shaman._apply_buff(ally, 1)
	check(effect(ally, "support_heal") == healing and healing.visible and healing.frame == 0, "repeat heal restarts same node")
	var another = FX.show_on(ally, "succubus_cut")
	check(is_same(another.sprite_frames, effect(hero, "succubus_cut").sprite_frames), "frame resources shared across actors")
	ally.current_hp = 0
	flush(healing)
	check(not healing.visible, "death hides pulse")
	if "--capture" in OS.get_cmdline_user_args():
		await gallery(hero)
	battle.free()
	await create_timer(0.2).timeout
	print("COMBAT_FX: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)

func gallery(hero: Node) -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var back := ColorRect.new()
	back.color = Color(0.09, 0.08, 0.13)
	back.size = Vector2(1080, 1920)
	layer.add_child(back)
	var kinds: Array = FX.CATALOG.EFFECTS.keys()
	kinds.append("slow")
	for index in range(kinds.size()):
		var kind: String = kinds[index]
		var center := Vector2(280 + (index % 2) * 520, 230 + (index / 2) * 340)
		var body := Sprite2D.new()
		body.texture = hero.hero_sprite.sprite_frames.get_frame_texture("idle", 0)
		body.scale = hero.hero_sprite.scale
		body.offset = hero.hero_sprite.offset
		body.centered = hero.hero_sprite.centered
		body.position = center + hero.hero_sprite.position
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.add_child(body)
		var visual := FX.new()
		layer.add_child(visual)
		visual.setup(hero, kind)
		visual.position += center
		visual.frame = 4
		visual.visible = true
		visual.set_process(false)
		var label := Label.new()
		label.text = kind
		label.position = center + Vector2(-150, 120)
		label.add_theme_font_size_override("font_size", 30)
		layer.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var arguments := OS.get_cmdline_user_args()
	var output := arguments[arguments.find("--capture") + 1]
	check(root.get_texture().get_image().save_png(output) == OK, "native render capture")
	layer.free()
