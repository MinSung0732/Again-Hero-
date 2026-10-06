extends SceneTree

const BUFFS := preload("res://src/systems/monster_support_buff_runtime.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SUPPORT_SHIELD_VISUAL: " + message)

func is_shield_pixel(monster: Node2D, image: Image, x: float) -> bool:
	var point := monster.get_global_transform_with_canvas() * Vector2(x, -79)
	point *= Vector2(image.get_size()) / root.get_visible_rect().size
	var color := image.get_pixel(int(point.x), int(point.y))
	return color.g > 0.7 and color.b > 0.9 and color.r < 0.5

func rendered_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	var monster = load("res://src/monsters/Orc.tscn").instantiate()
	root.add_child(monster)
	monster.position = Vector2(300, 300)
	monster.set_physics_process(false)
	var buffs := BUFFS.new()
	check(not is_shield_pixel(monster, await rendered_image(), 25), "absent without buff")
	monster.max_hp = 1000
	monster.current_hp = 1000
	buffs.apply_courage(monster, 10, 0.15, 0.1)
	check(monster.get_meta("support_shield_hp") == 100, "actual shield ten percent HP")
	check(is_shield_pixel(monster, await rendered_image(), 25), "ten percent shield renders full visible row immediately")
	check(COMMON.consume_support_shield(monster, 50) == 0, "half shield absorbed")
	var image: Image = await rendered_image()
	check(is_shield_pixel(monster, image, -25) and not is_shield_pixel(monster, image, 25), "rendered bar shrinks with absorption")
	buffs.tick(10)
	check(monster.get_meta("support_shield_hp") == 50, "shield persists after attack buff expiry")
	check(COMMON.consume_support_shield(monster, 60) == 10, "remaining shield absorbed and excess damage returned")
	check(not is_shield_pixel(monster, await rendered_image(), -25), "row disappears at zero shield")
	monster.free()
	await process_frame
	print("SUPPORT_SHIELD_VISUAL: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
