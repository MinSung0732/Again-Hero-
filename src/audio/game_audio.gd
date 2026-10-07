extends Node
const DATA := preload("res://src/data/game_audio_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var ui_bank: Node
var battle_bank: Node
var music: AudioStreamPlayer
var music_owner: WeakRef
var battle_owner: WeakRef
var music_mode := ""
var fade: Tween
var suppress_click_until := 0
var backgrounded := false
var last_demon_level := 0

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
	var cue := String(button.get_meta("audio_cue", "click"))
	if not cue.is_empty():
		ui_bank.play_cue(cue)

func feedback(cue: String) -> void:
	if cue != "click":
		suppress_click_until = Time.get_ticks_msec()+100
		ui_bank.stop_cue("click")
	if cue not in DATA.CONTEXT.SILENT_UI:
		ui_bank.play_cue(cue)

func enter_frontend(owner: Node, mode: String) -> void:
	music_owner = weakref(owner)
	music_mode = mode
	if music.stream == null:
		return
	if not music.playing:
		music.volume_db = -80.0
		music.play()
	_fade_music(float(DATA.FRONTEND_DB.get(mode, -3.0)), false)

func _fade_music(db: float, stop_when_finished: bool) -> void:
	if is_instance_valid(fade):
		fade.kill()
	fade = create_tween().set_ignore_time_scale(true)
	fade.tween_property(music, "volume_db", db, 0.45)
	if stop_when_finished:
		fade.tween_callback(music.stop)

func stop_frontend() -> void:
	music_owner = null
	music_mode = ""
	_fade_music(-80.0, true)

func attach_battle(battle: Node) -> void:
	if battle_owner != null and battle_owner.get_ref() == battle:
		return
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
	battle_bank.stop_all()
	ui_bank.stop_all()
	feedback("victory" if won else "defeat")
	enter_frontend(owner, "result")

func _process(_delta: float) -> void:
	if is_instance_valid(music):
		music.stream_paused = backgrounded or get_tree().paused
		if music_owner != null and not is_instance_valid(music_owner.get_ref()):
			stop_frontend()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
