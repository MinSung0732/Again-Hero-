extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BUFF_SCALE: " + message)

func pixels(sprite: AnimatedSprite2D, animation: String, all_frames: bool = false) -> Rect2:
	var result := Rect2()
	for index in range(sprite.sprite_frames.get_frame_count(animation) if all_frames else 1):
		var texture := sprite.sprite_frames.get_frame_texture(animation, index)
		var bounds := Rect2(texture.get_image().get_used_rect())
		if sprite.flip_h:
			bounds.position.x = texture.get_width() - bounds.end.x
		if sprite.flip_v:
			bounds.position.y = texture.get_height() - bounds.end.y
		if sprite.centered:
			bounds.position -= texture.get_size() * 0.5
		bounds.position += sprite.offset
		var global_bounds := Rect2(sprite.global_transform * bounds.position, Vector2.ZERO)
		for corner in [bounds.end, Vector2(bounds.end.x, bounds.position.y), Vector2(bounds.position.x, bounds.end.y)]:
			global_bounds = global_bounds.expand(sprite.global_transform * corner)
		result = result.merge(global_bounds) if result.has_area() else global_bounds
	return result

func validate(actor: Node2D, kind: String, fx: Node) -> void:
	var body := pixels(actor.get_node("Visual"), "idle")
	var aura := pixels(fx, "fx", true)
	check(aura.size.x >= body.size.x * 1.19, "visible buff surrounds body width " + kind)
	check(absf(aura.get_center().x - body.get_center().x) < 0.1, "buff horizontally centered on actual pixels " + kind)
	if String(FX.CATALOG.MONSTER_BUFF_LAYOUTS[kind].anchor) == "feet":
		check(absf(aura.end.y - (body.end.y + body.size.y * 0.08)) < 0.1, "ground aura anchored at actual feet " + kind)
	else:
		check(aura.size.y >= body.size.y * 1.14, "body burst covers body height " + kind)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://buff_scale_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	battle.hero.set_physics_process(false)
	for id in CATALOG.ORDER:
		var actor = battle._spawn_monster(id, Vector2(1200, 1000))
		actor.set_physics_process(false)
		for variant in ["normal", "elite"]:
			if variant == "elite":
				battle._apply_elite_monster_visual(actor, id)
			for kind in ["support_courage", "support_agility", "support_heal"]:
				actor.set_meta("support_damage_multiplier", 1.15)
				actor.set_meta("support_speed_multiplier", 1.5)
				var fx = FX.show_on(actor, kind)
				validate(actor, kind, fx)
				actor.scale = Vector2(1.7, 1.7)
				validate(actor, kind, fx)
				actor.scale = Vector2.ONE
				actor.get_node("Visual").flip_h = true
				fx._visibility_check_timer = 0.0
				fx._process(0.0)
				validate(actor, kind, fx)
				actor.get_node("Visual").flip_h = false
		var cache_count: int = FX._texture_bounds_cache.size()
		var children: int = actor.get_child_count()
		for repeat in range(16):
			FX.show_on(actor, "support_heal")
		check(FX._texture_bounds_cache.size() == cache_count and actor.get_child_count() == children, "repeat uses cached bounds and nodes " + id)
		actor.free()
	if "--capture" in OS.get_cmdline_user_args():
		await gallery(battle)
	battle.free()
	await create_timer(0.2).timeout
	print("BUFF_SCALE: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)

func gallery(battle: Node) -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var back := ColorRect.new()
	back.size = Vector2(1080, 1920)
	back.color = Color(0.09, 0.08, 0.13)
	layer.add_child(back)
	var rows := [["slime", "support_courage"], ["mummy", "support_agility"], ["dullahan", "dullahan_regen"], ["kraken", "support_heal"], ["orc", "orc_rage"]]
	for row in range(rows.size()):
		for column in range(2):
			var id: String = rows[row][0]
			var kind: String = rows[row][1]
			var actor = battle._spawn_monster(id, Vector2(1200, 1000))
			actor.set_physics_process(false)
			if column == 1:
				battle._apply_elite_monster_visual(actor, id)
			actor.reparent(layer)
			actor.position = Vector2(280 + column * 520, 230 + row * 340)
			actor.set_meta("support_damage_multiplier", 1.15)
			actor.set_meta("support_speed_multiplier", 1.5)
			var fx
			if kind == "dullahan_regen":
				actor.danger_state = 2
			if kind == "orc_rage":
				actor.set_meta("orc_berserk_visual_active", true)
				for child in actor.get_children():
					if child is FX and child.effect_type == kind:
						fx = child
				fx._visibility_check_timer = 0.0
				fx._process(0.0)
			else:
				fx = FX.show_on(actor, kind)
			fx.stop()
			fx.frame = 4
			fx.visible = true
			fx.set_process(false)
			var label := Label.new()
			label.text = id + (" elite" if column == 1 else " normal") + "\n" + kind
			label.position = actor.position + Vector2(-170, 120)
			label.add_theme_font_size_override("font_size", 28)
			layer.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	check(root.get_texture().get_image().save_png(args[args.find("--capture") + 1]) == OK, "real monster render capture")
	layer.free()
