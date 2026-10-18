extends SceneTree
const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
class FakeCutscene extends Control:
	signal finished
	var played: Array[String] = []
	var cancellations := 0
	func play(id: String) -> void: played.append(id)
	func cancel() -> void: cancellations += 1
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var overlay := OVERLAY.new()
	root.add_child(overlay)
	overlay._cutscene.queue_free()
	var fake := FakeCutscene.new()
	overlay.add_child(fake)
	overlay._cutscene = fake
	fake.finished.connect(overlay._on_cutscene_finished)
	var ordinary := {"monster_id":"slime","name":"슬라임","rarity":"common","shards":1}
	var zeus := {"monster_id":"zeus","name":"제우스","rarity":"transcendent","shards":1}
	var arthur := {"monster_id":"arthur","name":"아서왕","rarity":"transcendent","shards":1}
	overlay.present([ordinary])
	overlay.skip_to_results()
	assert(overlay._phase == "result" and fake.played.is_empty())
	overlay.present([ordinary,zeus,ordinary,arthur,zeus])
	overlay.skip_to_results()
	assert(overlay._phase == "cutscene" and fake.played == ["zeus"])
	var token: int = overlay._sequence_token
	var cancellations := fake.cancellations
	for tap in 20: overlay.skip_to_results()
	assert(overlay._sequence_token == token and fake.cancellations == cancellations)
	fake.finished.emit()
	assert(fake.played == ["zeus","arthur"] and overlay._phase == "cutscene")
	fake.finished.emit()
	assert(fake.played == ["zeus","arthur","zeus"])
	fake.finished.emit()
	assert(overlay._phase == "result" and overlay._result_grid.get_child_count() == 5)
	fake.played.clear()
	overlay.present([zeus,ordinary,arthur])
	overlay._sequence_token += 1 # Cancel the fixture's pending opening coroutine.
	overlay._show_reveal(0)
	fake.finished.emit()
	assert(overlay._phase == "reveal")
	overlay.skip_to_results()
	assert(fake.played == ["zeus","arthur"])
	fake.finished.emit()
	assert(overlay._phase == "result")
	overlay.present([ordinary])
	assert(not overlay._skip_normal_reveals and overlay._cutscene_seen.is_empty())
	overlay.skip_to_results()
	assert(overlay._phase == "result")
	print("PASS skip queues unseen transcendent reveals, repeated skips, reuse")
	overlay.queue_free()
	quit()
