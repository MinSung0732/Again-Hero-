extends SceneTree
const SFX := preload("res://src/data/monster_sfx_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for group in SFX.GROUPS:
		for kind in SFX.GROUPS[group]: assert(ResourceLoader.exists(SFX.GROUPS[group][kind]))
	for id in MONSTERS.get_ids():
		var death := SFX.cue_for(id, "death", MONSTERS.get_attack_type(id))
		assert(death.is_empty() if id in SFX.EXCLUDED else not death.is_empty())
	var bank = BANK.new(); root.add_child(bank); bank.configure(SFX.audio_cues())
	var cue := SFX.cue_for("goblin", "death", "melee")
	for i in 100: bank.play_cue(cue)
	assert(bank.played_count == 1)
	var ids := SFX.audio_cues().keys()
	var buffer = BUFFER.new(); buffer.publish("monster_sfx", Vector2.ZERO, ids.find(cue)+1, Color.WHITE, 1)
	var rows: Array = JSON.parse_string(JSON.stringify(buffer.snapshot()))
	assert(DATA.valid_events(rows, buffer.sequence, 1))
	assert(SFX.cue_from_index(int(rows[0][5])) == cue)
	print("PASS monster_sfx_smoke")
	quit()
