extends Node

const DATA := preload("res://src/data/hero_voice_catalog.gd")
signal cue_started(event: StringName)

var player: AudioStreamPlayer
var delay: Timer
var hero_id := ""
var streams: Dictionary = {}
var consumed: Dictionary = {}
var terminal := false
var enabled := true
var current_event: StringName = &""
var current_priority := -1
var backgrounded := false
var duck_effects: Dictionary = {}
var duck_tween: Tween
var _prepared := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.bus = AudioSettings.VOICE_BUS
	player.max_polyphony = 1
	player.pitch_scale = 1.0
	add_child(player)
	player.finished.connect(_finished)
	delay = Timer.new()
	delay.one_shot = true
	delay.ignore_time_scale = true
	add_child(delay)
	delay.timeout.connect(_start_pending)
	# Effects are independent of the bus volumes controlled by user settings.
	for bus in DATA.DUCK_DB:
		var index := AudioServer.get_bus_index(bus)
		if index < 0: continue
		var effect := AudioEffectAmplify.new()
		effect.volume_db = 0.0
		AudioServer.add_bus_effect(index, effect)
		duck_effects[bus] = effect
	AudioSettings.settings_changed.connect(_settings_changed)
	set_process(false)

func install(battle: Node) -> void:
	hero_id = String(battle.current_hero_profile.get("id", ""))
	enabled = not battle.practice_mode and not battle.tutorial_mode
	battle.hero_outcome_confirmed.connect(_on_outcome)
	battle.battle_finished.connect(_on_battle_finished)

func prepare() -> void:
	if _prepared or not enabled: return
	_prepared = true
	for event in DATA.EVENTS:
		var path := DATA.path_for(hero_id, event)
		var stream: AudioStreamWAV
		if not path.is_empty() and ResourceLoader.exists(path):
			var source := load(path) as AudioStreamWAV
			if source != null:
				stream = source.duplicate() as AudioStreamWAV
				stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		streams[event] = stream

func play_entry() -> bool:
	return _request(&"entry", "entry") if not terminal else false

func play_unlock(skill_id: String) -> bool:
	return _request(&"unlock", "unlock:" + skill_id) if not terminal else false

func _on_outcome(outcome: StringName) -> void:
	if terminal: return
	terminal = true
	stop()
	_request(outcome, "outcome")

func _on_battle_finished(_message: String, _won: bool) -> void:
	# Abandon/other non-combat exits do not imply a hero victory.
	if not terminal:
		terminal = true
		stop()

func _request(event: StringName, key: String) -> bool:
	if not enabled or consumed.has(key) or not DATA.EVENTS.has(event): return false
	consumed[key] = true
	prepare()
	var stream := streams.get(event) as AudioStream
	if stream == null or AudioSettings.sfx_muted or backgrounded: return false
	var cue: Dictionary = DATA.EVENTS[event]
	if current_priority > int(cue.priority): return false
	stop()
	current_event = event
	current_priority = int(cue.priority)
	player.stream = stream
	player.volume_db = float(cue.db)
	set_process(true)
	_duck(true)
	var seconds := float(cue.delay)
	if seconds > 0.0: delay.start(seconds)
	else: _start_pending()
	return true

func _start_pending() -> void:
	if current_event == &"" or not is_inside_tree(): return
	player.play()
	_sync_pause()
	cue_started.emit(current_event)

func _finished() -> void:
	current_event = &""
	current_priority = -1
	player.stream = null
	set_process(false)
	_duck(false)

func stop() -> void:
	delay.stop()
	player.stop()
	_finished()

func _duck(active: bool) -> void:
	if is_instance_valid(duck_tween): duck_tween.kill()
	duck_tween = create_tween().set_ignore_time_scale(true).set_parallel(true)
	for bus in duck_effects:
		duck_tween.tween_property(duck_effects[bus], "volume_db", float(DATA.DUCK_DB[bus]) if active else 0.0, DATA.DUCK_ATTACK_SECONDS if active else DATA.DUCK_RELEASE_SECONDS)

func _settings_changed() -> void:
	if AudioSettings.sfx_muted and current_event != &"": stop()

func _process(_delta: float) -> void:
	_sync_pause()

func _sync_pause() -> void:
	var paused := backgrounded or get_tree().paused
	player.stream_paused = paused
	delay.paused = paused

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
	else:
		return
	if is_instance_valid(player) and is_instance_valid(delay): _sync_pause()

func _exit_tree() -> void:
	if is_instance_valid(duck_tween): duck_tween.kill()
	# Remove only our own effects; never restore a stale user volume/mute value.
	for bus in duck_effects:
		var index := AudioServer.get_bus_index(bus)
		if index < 0: continue
		for slot in range(AudioServer.get_bus_effect_count(index) - 1, -1, -1):
			if AudioServer.get_bus_effect(index, slot) == duck_effects[bus]:
				AudioServer.remove_bus_effect(index, slot)
