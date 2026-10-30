extends Node
# Fixed players and a shared stream cache: no allocation on attack or absorption.
static var streams: Dictionary = {}
var players: Dictionary = {}
var cues: Dictionary = {}
var cooldowns: Dictionary = {}
var authority: Node
var scaled_clock := false
var application_paused := false
var honor_tree_pause := true
var played_count := 0
var catalog_key := ""

func configure(data: Dictionary, battle: Node = null, combat_clock: bool = false, key: String = "") -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	authority = battle
	catalog_key = key
	scaled_clock = combat_clock
	cues = data
	for id in data:
		var cue: Dictionary = data[id]
		var path := String(cue.path)
		if not streams.has(path):
			# Imported resources survive PCK export; raw loading also supports editor tests.
			streams[path] = load(path) if ResourceLoader.exists(path) else AudioStreamWAV.load_from_file(path)
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.stream = streams[path]
		player.volume_db = float(cue.db)
		player.max_polyphony = 1
		add_child(player)
		players[id] = player
		cooldowns[id] = 0.0

func is_blocked() -> bool:
	return application_paused or (honor_tree_pause and get_tree().paused) or (is_instance_valid(authority) and (authority.battle_over or authority.external_pause or authority.demon_augment_selection_active))

func play_cue(id: String) -> bool:
	if not players.has(id) or is_blocked() or float(cooldowns[id]) > 0.0:
		return false
	if not catalog_key.is_empty() and is_instance_valid(authority) and authority.has_signal("online_transcendent_sfx") and authority.get("online_match_mode") == true:
		cooldowns[id] = float(cues[id].get("interval", 0.0))
		authority.emit_signal("online_transcendent_sfx", catalog_key, id)
		return true
	var player: AudioStreamPlayer = players[id]
	if player.stream == null:
		return false
	player.set_meta("base_pitch", float(cues[id].get("pitch", 1.0)) * randf_range(1.0-float(cues[id].get("pitch_jitter", 0.0)), 1.0+float(cues[id].get("pitch_jitter", 0.0))))
	player.pitch_scale = float(player.get_meta("base_pitch")) * (maxf(Engine.time_scale, 0.01) if scaled_clock else 1.0)
	player.stream_paused = false
	player.play()
	cooldowns[id] = float(cues[id].get("interval", 0.0))
	played_count += 1
	return true

func stop_cue(id: String) -> void:
	if players.has(id):
		players[id].stop()

func stop_all() -> void:
	for id in players:
		players[id].stop()
		cooldowns[id] = 0.0

func _process(delta: float) -> void:
	var blocked := is_blocked()
	for id in players:
		var player: AudioStreamPlayer = players[id]
		player.stream_paused = blocked
		if not blocked:
			cooldowns[id] = maxf(float(cooldowns[id])-delta, 0.0)
			if scaled_clock:
				player.pitch_scale = float(player.get_meta("base_pitch", cues[id].get("pitch", 1.0)))*maxf(Engine.time_scale, 0.01)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		application_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		application_paused = false
