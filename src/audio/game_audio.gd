extends Node
const DATA := preload("res://src/data/game_audio_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var ui_bank: Node
var battle_bank: Node
var music: AudioStreamPlayer
var frontend_stream: AudioStream
var dialogue_stream: AudioStreamWAV
var music_owner: WeakRef
var battle_owner: WeakRef
var music_mode := ""
var fade: Tween
var suppress_click_until := 0
var backgrounded := false
var last_demon_level := 0
var result_owner: WeakRef

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_bank = BANK.new()
	add_child(ui_bank)
	ui_bank.honor_tree_pause = false
	ui_bank.configure(DATA.ui_cues())
	battle_bank = BANK.new()
	add_child(battle_bank)
	battle_bank.configure(DATA.BATTLE_CUES, null, true)
	music = AudioStreamPlayer.new()
	music.bus = &"BGM"
	add_child(music)
	if ResourceLoader.exists(DATA.FRONTEND_BGM):
		var stream := load(DATA.FRONTEND_BGM) as AudioStreamOggVorbis
		if stream != null:
			music.stream = stream.duplicate()
			music.stream.loop = true
			frontend_stream = music.stream
	get_tree().node_added.connect(_watch_button)

func _watch_button(node: Node) -> void:
	if node is BaseButton:
		# UI creation only; no hover/scroll/slider ticking and no per-frame tree scan.
		# Reparenting emits node_added again; retain a single callback per button.
		for connection in node.pressed.get_connections():
			if connection.callable.get_object() == self and connection.callable.get_method() == &"_button_pressed":
				return
		node.pressed.connect(_button_pressed.bind(weakref(node)))

func _button_pressed(reference: WeakRef) -> void:
	var button: BaseButton = reference.get_ref()
	if not is_instance_valid(button) or button.disabled or Time.get_ticks_msec() < suppress_click_until:
		return
	var cue := String(button.get_meta("audio_cue", ""))
	if not cue.is_empty():
		# Run after the action so committed feedback can suppress this press.
		call_deferred("_play_button_feedback", reference, cue)

func _play_button_feedback(reference: WeakRef, cue: String) -> void:
	if reference.get_ref() == null or Time.get_ticks_msec() < suppress_click_until:
		return
	ui_bank.play_cue(cue)

func feedback(cue: String) -> void:
	if cue != "click":
		suppress_click_until = Time.get_ticks_msec()+100
		ui_bank.stop_cue("click")
	if cue not in DATA.CONTEXT.SILENT_UI:
		ui_bank.play_cue(cue)

func enter_frontend(owner: Node, mode: String) -> void:
	if music.stream != frontend_stream:
		_cancel_music_fade()
		music.stop()
		music.stream = frontend_stream
	music_owner = weakref(owner)
	music_mode = mode
	if music.stream == null:
		return
	if not music.playing:
		music.volume_db = -80.0
		music.play()
	_fade_music(float(DATA.FRONTEND_DB.get(mode, -3.0)), false)

func _cancel_music_fade() -> void:
	if is_instance_valid(fade):
		fade.kill()
		fade = null

func play_dialogue_bgm(owner: Node) -> void:
	# Ownership lasts until the cutscene ends, even if the one-shot song ends.
	# Repeated calls/pages must never restart an already owned dialogue track.
	if music_mode == "dialogue" and music_owner != null and music_owner.get_ref() == owner:
		return
	if dialogue_stream == null:
		var path := String(DATA.DIALOGUE_BGM.path)
		if not ResourceLoader.exists(path):
			return
		var source := load(path) as AudioStreamWAV
		if source == null:
			return
		dialogue_stream = source.duplicate()
		dialogue_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_cancel_music_fade()
	music.stop()
	music.stream = dialogue_stream
	music_owner = weakref(owner)
	music_mode = "dialogue"
	music.volume_db = float(DATA.DIALOGUE_BGM.db)
	music.stream_paused = backgrounded or get_tree().paused
	music.play(0.0)

func stop_dialogue_bgm(owner: Node) -> void:
	# A removed old cutscene cannot fade a new scene's music.
	if music_mode != "dialogue" or music_owner == null or music_owner.get_ref() != owner:
		return
	music_owner = null
	music_mode = ""
	_fade_music(-80.0, true, float(DATA.DIALOGUE_BGM.fade_out_seconds))

func _fade_music(db: float, stop_when_finished: bool, seconds: float = 0.45) -> void:
	_cancel_music_fade()
	fade = create_tween().set_ignore_time_scale(true)
	fade.tween_property(music, "volume_db", db, seconds)
	if stop_when_finished:
		fade.tween_callback(music.stop)

func stop_frontend() -> void:
	music_owner = null
	music_mode = ""
	_fade_music(-80.0, true)

func attach_battle(battle: Node) -> void:
	if battle_owner != null and battle_owner.get_ref() == battle:
		return
	result_owner = null
	stop_frontend()
	battle_bank.stop_all()
	battle_bank.authority = battle
	battle_owner = weakref(battle)
	last_demon_level = int(battle.demon_level)
	battle.summon_result.connect(_summon)
	battle.demon_ultimate_used.connect(_ultimate)
	battle.demon_augment_applied.connect(_augment_applied)
	battle.demon_progression_changed.connect(_demon_progression)
	battle.mutation_selected.connect(_mutation_selected)
	battle.tree_exiting.connect(_battle_exiting.bind(weakref(battle)))

func _battle_exiting(reference: WeakRef) -> void:
	if battle_owner != null and battle_owner.get_ref() == reference.get_ref():
		battle_bank.stop_all()
		battle_bank.authority = null
		battle_owner = null
		if music_mode == "result":
			stop_frontend()

func play_battle(cue: String, authority: Node) -> void:
	if battle_owner != null and battle_owner.get_ref() == authority:
		battle_bank.play_cue(cue)

func _summon(id: String, success: bool, _message: String) -> void:
	if not success:
		feedback("denied")
	elif MONSTERS.get_rarity(id) != "transcendent":
		battle_bank.play_cue("summon")

func _ultimate(_id: String, _name: String, _message: String) -> void:
	battle_bank.stop_cue("summon")
	battle_bank.play_cue("ultimate")

func _augment_applied(_name: String, _summary: String) -> void:
	feedback("click")

func _demon_progression(level: int, _exp: float, _next_exp: float) -> void:
	if level > last_demon_level:
		feedback("demon_level")
	last_demon_level = level

func _mutation_selected(_type: String, _name: String) -> void:
	feedback("click")

func battle_result(owner: Node, won: bool) -> void:
	if result_owner != null and result_owner.get_ref() == owner:
		return
	result_owner = weakref(owner)
	battle_bank.stop_all()
	ui_bank.stop_all()
	feedback("victory" if won else "defeat")
	enter_frontend(owner, "result")

func _process(_delta: float) -> void:
	if is_instance_valid(music):
		music.stream_paused = backgrounded or get_tree().paused
		if music_owner != null and not is_instance_valid(music_owner.get_ref()):
			if music_mode == "dialogue":
				music_owner = null
				music_mode = ""
				_fade_music(-80.0, true, float(DATA.DIALOGUE_BGM.fade_out_seconds))
			else:
				stop_frontend()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
