extends SceneTree
const DATA := preload("res://src/data/summoner_audio_catalog.gd")
const AUDIO := preload("res://src/audio/summoner_audio.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
class Victim extends Node2D:
	var hits := 0
	func take_damage(_amount: int) -> void:
		hits += 1
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SUMMONER_AUDIO: "+message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var world := Node2D.new()
	root.add_child(world)
	var hero = load("res://src/hero/Hero.tscn").instantiate()
	hero.configure_profile(PROFILES.get_profile("summoner_hero"))
	world.add_child(hero)
	hero.set_physics_process(false)
	hero._ensure_summoner_runtime()
	await process_frame
	var target := Victim.new()
	world.add_child(target)
	hero._summoner_basic_attack(target)
	var deadline: int = hero.summoner_basic_audio_next_ms
	hero._summoner_basic_attack(target)
	hero._summoner_basic_attack(target)
	check(target.hits == 3 and hero.summoner_basic_audio_next_ms == deadline,"audio coalescing does not suppress hitscan damage")
	check(hero.summoner_basic_audio.stream.resource_path == DATA.BASIC and hero.summoner_basic_audio.stream.get_length() <= .201 and hero.summoner_basic_audio.volume_db == DATA.BASIC_DB,"real profile loads short quiet basic attack")
	var summons: Array[Node] = []
	var voices: Array[AudioStreamPlayer] = []
	for name in ["Gatekeeper","Scout","Hound","Watcher","OpenGate"]:
		var actor = load("res://src/hero/Summoner"+name+".tscn").instantiate()
		world.add_child(actor)
		summons.append(actor)
		actor.activate(Vector2.ZERO,hero,{})
		actor.set_physics_process(false)
		voices.append(actor.opening_audio if name == "OpenGate" else actor.summon_audio)
	var playing := 0
	for voice in voices:
		if voice.playing:
			playing += 1
		check(voice.stream.resource_path == DATA.PORTAL and voice.volume_db == DATA.PORTAL_DB,"all actual summon/opening paths use quiet edited portal")
	check(playing == 1,"five simultaneous summons play exactly one portal")
	hero.set_meta("summoner_portal_next_ms",0)
	check(not AUDIO.play_portal(hero,voices[1]),"active voice also prevents overlap even after cooldown reset")
	voices[0].stop()
	check(AUDIO.play_portal(hero,voices[1]),"a later portal still has audible skill feedback")
	if "--mix-capture" in OS.get_cmdline_user_args():
		var saved: Array = []
		for bus_name in ["Master","SFX","BGM"]:
			var bus := AudioServer.get_bus_index(bus_name)
			saved.append([bus,AudioServer.get_bus_volume_db(bus),AudioServer.is_bus_mute(bus)])
			AudioServer.set_bus_volume_db(bus,0)
			AudioServer.set_bus_mute(bus,false)
		var capture := AudioEffectCapture.new()
		AudioServer.add_bus_effect(0,capture)
		var effect_index := AudioServer.get_bus_effect_count(0)-1
		var game_audio = root.get_node("GameAudio")
		game_audio.enter_frontend(hero,"lobby")
		var peak := 0.0
		for i in range(30):
			hero._summoner_basic_attack(target)
			for voice in voices:
				AUDIO.play_portal(hero,voice)
			if i%5 == 0:
				game_audio.battle_bank.play_cue("summon")
				for actor in summons.slice(0,4):
					actor.attack_audio.play()
			await create_timer(.06).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		check(peak > .0001 and peak < .8,"basic, portal, follower attacks, ordinary summon and BGM mixture has headroom")
		print("SUMMONER_AUDIO_MIX peak=",peak)
		AudioServer.remove_bus_effect(0,effect_index)
		for setting in saved:
			AudioServer.set_bus_volume_db(setting[0],setting[1])
			AudioServer.set_bus_mute(setting[0],setting[2])
		game_audio.stop_frontend()
	world.queue_free()
	await process_frame
	print("SUMMONER_AUDIO ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
