extends SceneTree
const VIEW := preload("res://src/ui/lobby_exploration_rewards_view.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
var checks := 0
var failures := 0
var wallet_refreshes := 0
class Tray extends Control:
	func register_action(_id: StringName, _callback: Callable) -> void: pass
	func set_notification(_id: StringName, _active: bool) -> void: pass
class Service extends Node:
	signal changed
	var earned := false
	var credited := 0
	func snapshot() -> Dictionary:
		return {"success":true,"can_claim":earned,"full":false,"percent":51 if earned else 0,"seconds":9180 if earned else 0,"gold":102 if earned else 0,"research":51 if earned else 0}
	func claim() -> Dictionary:
		if not earned: return {"success":false,"reason":"below_threshold"}
		earned = false
		credited += 1
		changed.emit() # Real service also refreshes synchronously before returning.
		return {"success":true,"gold":102,"research":51}
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func refresh_wallet() -> void: wallet_refreshes += 1
func run() -> void:
	if AudioServer.get_bus_index("SFX")<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,"SFX")
	var parent := Control.new()
	root.add_child(parent)
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tray := Tray.new()
	parent.add_child(tray)
	var service := Service.new()
	parent.add_child(service)
	var view := VIEW.new()
	view.install(parent,tray,service,refresh_wallet)
	view.open()
	await process_frame
	var overlay_count := view._overlay.get_child_count()
	var feedback_count := view._feedback.get_child_count()
	check(feedback_count==2 and view._claim_audio.get_child_count()==1,"fixed labels and one retained player")
	check(view._feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE,"feedback does not consume touch")
	view._claim_reward()
	check(not view._feedback.active and view._claim_audio.played_count==0 and wallet_refreshes==0,"failed claim stays silent/no animation")
	# Actual game textures exist in repo; synthetic fixture texture tests drawing
	# without importing the entire game's asset/autoload tree.
	var image := Image.create(8,8,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	view._gold_icon.texture = texture
	view._research_icon.texture = texture
	view._feedback.textures[0] = texture
	view._feedback.textures[1] = texture
	service.earned = true
	view.refresh()
	view._claim_reward()
	check(service.credited==1 and wallet_refreshes==1,"one successful payout/one wallet refresh")
	check(view._feedback.active and view._claim_audio.played_count==1,"success starts animation and coin cue")
	check(view._feedback.amounts==PackedInt32Array([102,51]),"uses returned payout after snapshot reset")
	check(view._feedback.labels[0].text=="+102" and view._feedback.labels[1].text=="+51","both payout labels")
	check(view._claim.disabled,"spent reward disabled")
	view._feedback.set_process(false)
	var first: Vector2 = view._feedback.labels[0].position
	view._feedback._process(0.3)
	check(view._feedback.labels[0].position.y<first.y,"amount rises")
	view._feedback._process(0.8)
	check(view._feedback.labels[0].modulate.a>0 and view._feedback.labels[0].modulate.a<1,"amount fades")
	view._feedback._process(0.3)
	check(not view._feedback.active and not view._feedback.is_processing(),"idle process stops")
	for layout_size in [Vector2(1080,1920),Vector2(1920,1080),Vector2(360,640)]:
		view._overlay.size = layout_size
		view._layout_modal()
		await process_frame
		service.earned = true
		view.refresh()
		view._claim_audio.stop_all()
		view._claim_reward()
		view._feedback.set_process(false)
		var expected: Vector2 = view._gold_icon.get_global_transform_with_canvas()*(view._gold_icon.size*0.5)
		var actual: Vector2 = view._feedback.get_global_transform_with_canvas()*view._feedback.origins[0]
		check(expected.distance_to(actual)<0.01,"scaled modal origin aligns "+str(layout_size))
		check(view._overlay.get_child_count()==overlay_count and view._feedback.get_child_count()==feedback_count,"reuse creates no feedback nodes")
		view.close()
		check(not view._feedback.active and not view._claim_audio.players.claim.playing,"close stops feedback/sound")
		view.open()
	var player: AudioStreamPlayer = view._claim_audio.players.claim
	var stream := player.stream as AudioStreamWAV
	check(stream!=null and stream.mix_rate==44100 and stream.format==AudioStreamWAV.FORMAT_16_BITS,"coin PCM decodes")
	var peak := 0.0
	if stream!=null:
		var pcm := stream.data
		for i in range(0,pcm.size(),2): peak = maxf(peak,absf(float(pcm.decode_s16(i))/32768.0))
	check(peak>0.1 and peak<0.563,"coin is non-silent and peak bounded")
	check(player.bus==&"SFX" and player.volume_db==-13,"honors SFX bus/level")
	parent.free()
	BANK.streams.clear()
	await process_frame
	print("EXPLORATION_FEEDBACK: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
