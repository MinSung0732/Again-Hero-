extends SceneTree
const HEAL := preload("res://src/battle/heal_item.gd")
const SCENE := preload("res://src/battle/HealItem.tscn")
var checks := 0
var failures := 0
class HeroSpy extends Node2D:
	var healing: Array = []
	func collect_heal_item(amount: int) -> void: healing.append(amount)
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://expected.json"))
	var packed := OS.get_cmdline_user_args().has("--packed")
	var hero := HeroSpy.new(); hero.add_to_group("hero"); hero.position = Vector2(1000,1000); root.add_child(hero)
	var first = SCENE.instantiate(); first.set_physics_process(false); root.add_child(first)
	var frames: SpriteFrames = first.visual.sprite_frames
	check(first.visual.visible and first.visual.is_playing(),"real actor starts animation")
	check(frames.get_frame_count("float") == expected.size() and frames.get_animation_speed("float") == 8.0 and frames.get_animation_loop("float"),"frame count/order/loop/speed")
	for index in expected.size():
		var data: Dictionary = expected[index]
		check(FileAccess.file_exists(data.path) != packed,"source PNG presence matches test mode")
		check(ResourceLoader.exists(data.path),"imported PNG path resolves without raw image load")
		var texture: Texture2D = frames.get_frame_texture("float",index)
		check(is_same(texture,ResourceLoader.load(data.path)),"actor uses shared imported texture")
		check(texture.get_size() == Vector2(data.width,data.height),"original frame dimensions")
		var image := texture.get_image()
		if image.is_compressed(): check(image.decompress() == OK,"readable compressed image")
		image.convert(Image.FORMAT_RGBA8)
		var rect := image.get_used_rect()
		check(rect == Rect2i(int(data.rect[0]),int(data.rect[1]),int(data.rect[2]),int(data.rect[3])),"original visible bounds")
		var pixels := image.get_data()
		var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(pixels)
		check(hash.finish().hex_encode() == data.sha256,"all original PNG RGBA pixels preserved")
	var visible_height := float(expected[0].rect[3])
	check(first.visual.scale.is_equal_approx(Vector2.ONE * first.target_visible_height / visible_height),"54px visible-height normalization")
	for index in 16:
		var item = SCENE.instantiate(); item.set_physics_process(false); root.add_child(item)
		check(is_same(item.visual.sprite_frames,frames),"all drops reuse one static SpriteFrames cache")
		item.free()
	check(first._load_texture("res://not_present.png") == null,"missing resource fails softly")
	check(first._load_texture("res://src/battle/HealItem.tscn") == null,"wrong resource type rejected")
	hero.position = first.position; first._physics_process(0.01)
	check(first.collected and hero.healing == [HEAL.HEAL_AMOUNT],"pickup still grants original healing once")
	first._physics_process(0.01)
	check(hero.healing.size() == 1,"collected item cannot grant twice")
	await process_frame
	hero.free()
	print("HEAL_RESOURCE_PASS packed=%s checks=%d failures=%d" % [packed,checks,failures])
	quit(1 if failures else 0)
