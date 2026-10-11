extends SceneTree
# Isolated real audio bank/PCM check; no assertion of audible device playback.
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const DATA := preload("res://src/data/izanami_audio_catalog.gd")
var checks := 0
var failures := 0
class Authority extends Node:
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	if AudioServer.get_bus_index("SFX")<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,"SFX")
	var authority := Authority.new()
	root.add_child(authority)
	var bank := BANK.new()
	root.add_child(bank)
	bank.configure(DATA.CUES,authority,true)
	check(bank.players.size()==6 and bank.get_child_count()==6,"six fixed cue players")
	for id in DATA.CUES:
		var player: AudioStreamPlayer = bank.players[id]
		var stream := player.stream as AudioStreamWAV
		check(stream!=null and stream.get_length()>0.4,id+" decodes")
		if stream==null: continue
		check(stream.mix_rate==44100 and stream.format==AudioStreamWAV.FORMAT_16_BITS,id+" PCM16 44.1kHz")
		var pcm := stream.data
		var peak := 0.0
		var sum_squared := 0.0
		for i in range(0,pcm.size(),2):
			var sample := float(pcm.decode_s16(i))/32768.0
			peak = maxf(peak,absf(sample))
			sum_squared += sample*sample
		var rms := sqrt(sum_squared/maxf(pcm.size()/2.0,1))
		check(peak>0.1 and peak<=0.71,id+" audible waveform range/no clipping")
		check(rms>0.025,id+" excludes almost silent excerpts")
		check(player.bus==&"SFX" and player.volume_db==float(DATA.CUES[id].db),id+" user bus/volume")
		check(bank.play_cue(id),id+" routed playback request")
		check(not bank.play_cue(id),id+" repeat throttled")
	bank._process(2)
	for id in DATA.CUES: check(bank.play_cue(id),id+" cooldown reusable")
	check(bank.get_child_count()==6,"replay allocates no players")
	authority.external_pause = true
	bank._process(0.1)
	check(not bank.play_cue("haunt") and bank.players.haunt.stream_paused,"battle pause blocks/suspends")
	authority.external_pause = false
	bank.application_paused = true
	check(not bank.play_cue("spirits"),"background blocks")
	bank.application_paused = false
	bank.stop_all()
	check(bank.cooldowns.fire==0 and not bank.players.fire.playing,"stop clears playback/cooldown")
	var source := FileAccess.get_file_as_string("res://src/monsters/izanami.gd")
	for id in DATA.CUES: check(source.contains('_audio("'+id+'")'),id+" actual actor hook")
	check(source.contains("fire_sound_started[i] = 1"),"fire emission has per-slot once guard")
	check(source.contains("if is_instance_valid(audio_bank): audio_bank.stop_all()"),"death stop wired")
	bank.free()
	authority.free()
	BANK.streams.clear()
	await process_frame
	print("IZANAMI_AUDIO: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
