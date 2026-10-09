extends SceneTree
const COMBAT := preload("res://tests/shuten_doji_combat_smoke.gd")
const FIXTURE := preload("res://tests/manticore_combat_smoke.gd")
const SCENE := preload("res://src/monsters/ShutenDoji.tscn")
const AUDIO := preload("res://src/data/shuten_doji_audio_catalog.gd")
const SUMMON := preload("res://src/data/battle_summon_cinematic_catalog.gd")
const GACHA := preload("res://src/data/transcendent_cutscene_catalog.gd")
var failures := 0
class Target extends COMBAT.Target:
	var reject := false
	func take_damage(amount: int, source: Node = null) -> bool:
		return false if reject else super.take_damage(amount,source)
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SHUTEN_AUDIO: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var authority := FIXTURE.Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(0,0)
	authority.add_child(actor)
	actor.set_physics_process(false)
	actor.visual.set_physics_process(false)
	actor.arrival = 0
	var bank = actor.audio_bank
	check(bank.players.size()==9,"fixed nine combat voices")
	for cue in AUDIO.CUES:
		var p: AudioStreamPlayer = bank.players[cue]
		check(String(AUDIO.CUES[cue].path).begins_with(AUDIO.ROOT),"dedicated asset "+cue)
		check(p.stream is AudioStreamWAV and p.stream.get_length()>0.2,"PCM loaded "+cue)
		check(p.stream.format==AudioStreamWAV.FORMAT_16_BITS and not p.stream.stereo,"lossless mono import "+cue)
		check(p.bus==&"SFX" and p.max_polyphony==1,"SFX and bounded voices "+cue)
	actor.gauge = 100
	actor._cast_fog()
	actor._tick_fogs(2)
	check(bank.cooldowns.mist>0 and bank.played_count==1,"twelve fogs share one cast sound")
	actor._ignite()
	check(bank.cooldowns.ignite>0 and bank.played_count==2,"all fog explosions share one ignition sound")
	actor._cast_chain(target)
	check(bank.cooldowns.chain>0,"actual chain creation")
	actor._bind_chain(0,target)
	check(bank.cooldowns.bind>0,"accepted bind dispatch")
	var before: int = bank.played_count
	actor._bind_chain(0,target)
	check(bank.played_count==before,"immune bind has no duplicate sound")
	bank.stop_all()
	actor.attack_timer = 0
	actor._tick_motion(0.01)
	actor._tick_motion(0.31)
	check(bank.cooldowns.swing>0 and bank.cooldowns.hit>0,"base attack swing and accepted hit")
	bank.stop_all()
	actor.attack_remaining = 0
	actor.attack_timer = 0
	target.reject = true
	actor._tick_motion(0.01)
	before = bank.played_count
	actor._tick_motion(0.31)
	check(bank.played_count==before and bank.cooldowns.hit==0,"rejected damage has no impact sound")
	target.reject = false
	bank.stop_all()
	actor._start_revival()
	check(bank.cooldowns.release>0,"first revival emits Oni release")
	actor.revival_remaining = 0
	actor.released = true
	actor.attack_timer = 0
	actor.attack_remaining = 0
	actor._tick_motion(0.01)
	actor._tick_motion(0.31)
	check(bank.cooldowns.swing_released>0 and bank.cooldowns.hit_released>0,"released attacks use distinct flame layers")
	bank.stop_all()
	authority.external_pause = true
	check(not bank.play_cue("ignite"),"menu pause blocks playback")
	authority.external_pause = false
	var scale_before := Engine.time_scale
	Engine.time_scale = 0.25
	check(bank.play_cue("chain") and is_equal_approx(bank.players.chain.pitch_scale,0.25),"combat clock preserved")
	Engine.time_scale = scale_before
	bank.stop_all()
	check(GACHA.ENTRIES.shuten_doji.impact_sound_path==AUDIO.PRESENTATION_CUES.reveal.path,"gacha dedicated reveal")
	check(SUMMON.ENTRIES.shuten_doji.audio_cues==AUDIO.PRESENTATION_CUES and not SUMMON.ENTRIES.shuten_doji.death_audio_timeline.is_empty(),"summon and death dedicated cues")
	if "--mix-capture" in OS.get_cmdline_user_args():
		var master := AudioServer.get_bus_index(&"Master")
		var sfx := AudioServer.get_bus_index(&"SFX")
		AudioServer.set_bus_volume_db(master,0)
		AudioServer.set_bus_mute(master,false)
		AudioServer.set_bus_volume_db(sfx,0)
		AudioServer.set_bus_mute(sfx,false)
		var capture := AudioEffectCapture.new()
		capture.buffer_length = 2
		AudioServer.add_bus_effect(master,capture)
		var effect_index := AudioServer.get_bus_effect_count(master)-1
		var peak := 0.0
		var samples := 0
		for i in range(5):
			for cue in AUDIO.CUES: bank.play_cue(cue)
			await create_timer(0.2).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
				samples += 1
		check(peak>0.0001 and peak<0.85,"dense mixed output retains headroom")
		print("SHUTEN_AUDIO_MIX peak=",peak," samples=",samples)
		AudioServer.remove_bus_effect(master,effect_index)
	bank.stop_all()
	authority.queue_free()
	await process_frame
	print("SHUTEN_AUDIO: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
