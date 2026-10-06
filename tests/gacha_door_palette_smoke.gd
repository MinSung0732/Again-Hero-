extends SceneTree

const SHOP := preload("res://src/data/shop_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("GACHA_DOOR_PALETTE: " + message)

func run() -> void:
	# Sample the actual authored beam, not filenames or duplicated path constants.
	for id in SHOP.RARITY_ORDER:
		var texture: Texture2D = load(SHOP.get_rarity(id).door_sheet_path)
		var sheet := texture.get_image()
		for index in [19, 28, 29]:
			var origin := Vector2i((index % 6) * 512, (index / 6) * 512)
			var light := sheet.get_pixelv(origin + Vector2i(260, 250))
			check(light.a > 0.9, "opaque beam " + id)
			match id:
				"common": check(absf(light.r-light.g) < 0.1 and absf(light.g-light.b) < 0.1, "white beam")
				"uncommon": check(light.r > light.b + 0.05 and light.g > light.b + 0.05, "yellow beam")
				"rare": check(light.b > light.r + 0.05, "blue beam")
				"legendary": check(light.r > light.g + 0.05 and light.b > light.g + 0.05, "purple beam")
				"transcendent": check(light.g > light.r + 0.05 and light.g > light.b + 0.05, "green beam")
	var overlay = load("res://src/ui/gacha_reveal_overlay.gd").new()
	root.add_child(overlay)
	for id in ["common", "uncommon"]:
		overlay.present([{"monster_id":"slime", "name":"테스트", "rarity":id, "shards":2}])
		check(overlay._highest_rarity_id() == id, "actual result determines opening")
		var deadline := Time.get_ticks_msec() + 15000
		while (not overlay._door_sprite.is_playing() or overlay._door_sprite.frame < 19) and Time.get_ticks_msec() < deadline:
			await process_frame
		var atlas := overlay._door_sprite.sprite_frames.get_frame_texture("open", 19) as AtlasTexture
		check(atlas != null and atlas.atlas.resource_path == SHOP.get_rarity(id).door_sheet_path, "actual selected door sheet " + id)
		if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{rarity}", id))
		while overlay._phase == "door" and Time.get_ticks_msec() < deadline:
			await process_frame
		var flash: Color = overlay._flash.color
		var expected: Color = SHOP.get_rarity(id).color
		check(Vector3(flash.r,flash.g,flash.b).is_equal_approx(Vector3(expected.r,expected.g,expected.b)), "final flash matches result " + id)
		overlay.skip_to_results()
		overlay._confirm()
	for i in range(1000):
		check(SHOP.roll_rarity(float(i)/1000.0) in ["common", "uncommon"], "empty rarity cannot select opening")
	overlay.free()
	await create_timer(0.2).timeout
	print("GACHA_DOOR_PALETTE_SMOKE_FAILED" if failed else "GACHA_DOOR_PALETTE_SMOKE_OK")
	quit(1 if failed else 0)
