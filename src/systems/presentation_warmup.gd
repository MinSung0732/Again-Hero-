extends Node

# Strong references retain only shared entry effects + the destination screen.
# Never scan/load every stage's sprites or a whole assets tree into RAM.
signal progress_changed(completed: int, total: int)

const STARTUP := preload("res://src/data/startup_catalog.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
const REVEAL := preload("res://src/data/hero_reveal_catalog.gd")
const HEROES := preload("res://src/data/hero_profiles.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const LOAD_BATCH_SIZE := 4
const MAIN_THREAD_BUDGET_US := 4000
const LOADING_DIR := "res://assets/art/UI/loading/loadingframes"

var _common: Dictionary = {}
var _destination: Dictionary = {}
var _cropped: Dictionary = {}
var _busy := false
var texture_load_count := 0


func get_texture(path: String) -> Texture2D:
	return _common.get(path, _destination.get(path)) as Texture2D


func get_cropped(path: String) -> Texture2D:
	return _cropped.get(path) as Texture2D


func prepare_common() -> bool:
	var paths: Array[String] = []
	for portrait_path in preload("res://src/systems/player_profile.gd").PORTRAITS.values():
		paths.append(portrait_path)
	paths.append("res://assets/art/UI/prologue/ruined_throne.png")
	for index in range(1, 9):
		paths.append("%s/loading_logo_%02d.png" % [LOADING_DIR, index])
	return await _prepare(paths, true)


func prepare_scene(scene_path: String) -> bool:
	if _busy:
		return false
	var paths: Array[String] = []
	var dirs: Array[String] = []
	if scene_path == STARTUP.LOBBY_PATH:
		paths.assign([
			STARTUP.LOGO_PATH,
			"res://assets/art/background/mainlobby_background.png",
			"res://assets/art/UI/uicardframes/ui9.png",
			"res://assets/art/UI/uicardframes/ui10_clean_frame.png",
			"res://assets/art/UI/uicardframes/ui8.png",
		])
		dirs.assign(["lobby_header", "lobby_footer", "lobby_stage", "main_modes", "shop", "01_large_left_panel", "03_middle_right_panel"])
		paths.append("res://assets/art/heroes/stage1_mage/stage1_hero_portrait.png")
		paths.append("res://assets/art/UI/settings_v2/amethyst_thumb.png")
		paths.append("res://assets/art/UI/clean_frames/transcendent_card_frame.png")
		for frame_path in preload("res://src/ui/formation_rarity_frames.gd").PATHS.values():
			paths.append(frame_path)
		for monster_id in preload("res://src/data/transcendence_catalog.gd").get_ids():
			paths.append(preload("res://src/data/profile_cosmetic_catalog.gd").path(monster_id, "banner"))
		for banner_path in preload("res://src/data/profile_cosmetic_catalog.gd").BANNERS.values():
			paths.append(banner_path)
		dirs.append("profile_v1")
		paths.append_array(preload("res://src/systems/player_profile.gd").appearance_resource_paths())
		paths.append("res://assets/art/effects/gatcha/summoning_chamber.png")
		paths.append("res://assets/art/effects/gatcha/gacha_button_texture.tres")
		paths.append("res://assets/art/effects/gatcha/gacha_panel_frame.png")
		paths.append("res://assets/art/effects/gatcha/gacha_reward_card.png")
		for rarity_id in SHOP.RARITY_ORDER:
			var rarity := SHOP.get_rarity(rarity_id)
			if float(rarity.get("weight", 0.0)) > 0.0:
				paths.append(String(rarity.get("door_sheet_path", "")))
		for monster_id in MONSTERS.ORDER:
			var monster := MONSTERS.get_monster(monster_id)
			paths.append(MONSTERS.get_ui_icon_path(monster_id))
	elif scene_path == "res://src/main/Main.tscn":
		paths.append("res://assets/art/UI/hero_reveal_v2/reveal_chamber.png")
		# Shared height reference used by every hero profile during _ready().
		paths.append("res://assets/art/heroes/stage1_mage/stage1_mage_spritesheet.png")
		dirs.assign(["ui_gagebar_frames", "01_large_left_panel", "02_top_right_panel", "03_middle_right_panel", "05_right_bars", "battle_castle_v3"])
	else:
		return true
	for dir_name in dirs:
		var dir_path := "res://assets/art/UI/" + dir_name
		for filename in DirAccess.get_files_at(dir_path):
			if filename.get_extension().to_lower() in ["png", "svg"]:
				paths.append(dir_path.path_join(filename))
	var state := PROGRESS.load_state()
	if scene_path == STARTUP.LOBBY_PATH:
		# Warm both future previews: dark locked portrait, then silhouette.
		# Only portraits, never all combat frames.
		var preview_number := int(state.get("highest_unlocked_stage", 1)) + 2
		for id in STAGES.get_ordered_stage_ids():
			var browse_stage := STAGES.get_stage(id)
			if int(browse_stage.get("number", 1)) <= preview_number:
				paths.append(String(browse_stage.get("portrait_path", "")))
	var stage_id := String(state.get("current_stage_id", "stage_1"))
	var stage := STAGES.get_stage(stage_id)
	var portrait := String(stage.get("portrait_path", ""))
	if not portrait.is_empty():
		paths.append(portrait)
	if scene_path == "res://src/main/Main.tscn":
		var profile := HEROES.get_profile(String(stage.get("hero_id", "")))
		_append_texture_directory(String(profile.get("sprite_frame_dir", "")), paths)
		paths.append(String(profile.get("sprite_sheet_path", "")))
		var reveal := REVEAL.get_reveal_data(String(stage.get("hero_id", "")), "", portrait)
		paths.append(String(reveal.get("portrait_path", "")))
		var dialogue := DIALOGUES.get_dialogue(stage_id)
		paths.append(String(dialogue.get("hero_dialogue_portrait_path", dialogue.get("hero_portrait_path", ""))))
		paths.append_array(preload("res://src/systems/player_profile.gd").appearance_resource_paths())
	# Drop the old destination only; references held by the current scene survive.
	var retained: Dictionary = {}
	for path in paths:
		if _destination.has(path):
			retained[path] = _destination[path]
	_destination = retained
	for cached_path in _cropped.keys():
		if not retained.has(cached_path):
			_cropped.erase(cached_path)
	var ready := await _prepare(paths, false)
	if scene_path == STARTUP.LOBBY_PATH:
		# The old raw-PNG crop created another GPU texture inside Lobby._ready().
		_busy = true
		var source := get_texture("res://assets/art/UI/uicardframes/ui9.png")
		if source != null:
			var image := source.get_image()
			var used := image.get_used_rect()
			if used.has_area():
				var cropped := AtlasTexture.new()
				cropped.atlas = source
				cropped.region = Rect2(used)
				_cropped[source.resource_path] = cropped
		# Collection icons used to be decoded/cropped again on the team button's
		# input frame. Prepare atlas regions here; reuse the imported GPU textures.
		var crop_slice_start := Time.get_ticks_usec()
		for monster_id in MONSTERS.ORDER:
			var monster := MONSTERS.get_monster(monster_id)
			var icon_path := MONSTERS.get_ui_icon_path(monster_id)
			var icon := get_texture(icon_path)
			if icon == null or monster.has("card_icon_region") or _cropped.has(icon_path):
				continue
			var icon_image := icon.get_image()
			if icon_image != null:
				var used := icon_image.get_used_rect()
				var cropped := AtlasTexture.new()
				cropped.atlas = icon
				cropped.filter_clip = true
				cropped.region = Rect2(used) if used.has_area() else Rect2(Vector2.ZERO, icon.get_size())
				_cropped[icon_path] = cropped
			if Time.get_ticks_usec() - crop_slice_start >= MAIN_THREAD_BUDGET_US:
				await get_tree().process_frame
				crop_slice_start = Time.get_ticks_usec()
		_busy = false
	return ready


func _append_texture_directory(directory: String, paths: Array[String]) -> void:
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory):
		return
	for filename in DirAccess.get_files_at(directory):
		if filename.get_extension().to_lower() in ["png", "svg"]:
			paths.append(directory.path_join(filename))
	for child in DirAccess.get_directories_at(directory):
		_append_texture_directory(directory.path_join(child), paths)


# Expected O(p) membership checks, preserving first occurrence/load order.
static func unique_paths(paths: Array[String]) -> Array[String]:
	var unique: Array[String] = []
	var seen: Dictionary = {}
	for path in paths:
		if path.is_empty() or seen.has(path):
			continue
		seen[path] = true
		unique.append(path)
	return unique


func _prepare(paths: Array[String], shared: bool) -> bool:
	if _busy:
		return false
	_busy = true
	var unique := unique_paths(paths)
	var completed := 0
	progress_changed.emit(0, unique.size())
	# Bound in-flight reads and GPU work. Preserve every previously warmed path.
	# The headless dummy texture backend cannot initialize concurrent Images.
	var batch_size := 1 if DisplayServer.get_name() == "headless" else LOAD_BATCH_SIZE
	for batch_start in range(0, unique.size(), batch_size):
		var batch_end := mini(batch_start + batch_size, unique.size())
		var requested: Dictionary = {}
		for index in range(batch_start, batch_end):
			var path := unique[index]
			if get_texture(path) == null and ResourceLoader.exists(path):
				var error := ResourceLoader.load_threaded_request(path, "Texture2D")
				if error == OK:
					requested[path] = true
		var slice_start := Time.get_ticks_usec()
		for index in range(batch_start, batch_end):
			var path := unique[index]
			if get_texture(path) == null:
				var texture := await _load_texture(path, requested.has(path))
				if texture != null:
					if shared:
						_common[path] = texture
					else:
						_destination[path] = texture
			completed += 1
			progress_changed.emit(completed, unique.size())
			if Time.get_ticks_usec() - slice_start >= MAIN_THREAD_BUDGET_US:
				await get_tree().process_frame
				slice_start = Time.get_ticks_usec()
	_busy = false
	return true


func _load_texture(path: String, already_requested: bool = false) -> Texture2D:
	if not ResourceLoader.exists(path):
		# New raw PNGs can be used in the desktop/editor before import finishes.
		# Decode here during loading, not on the first frame of combat.
		if path.get_extension().to_lower() == "png" and FileAccess.file_exists(path):
			var image := Image.load_from_file(path)
			if image != null and not image.is_empty():
				texture_load_count += 1
				return ImageTexture.create_from_image(image)
		push_warning("Optional presentation resource missing: " + path)
		return null
	if not already_requested and ResourceLoader.load_threaded_request(path, "Texture2D") != OK:
		return null
	while is_inside_tree():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var texture := ResourceLoader.load_threaded_get(path) as Texture2D
			if texture != null:
				texture_load_count += 1
			return texture
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return null
		await get_tree().process_frame
	return null
