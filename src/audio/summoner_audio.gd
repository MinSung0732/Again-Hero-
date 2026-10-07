extends RefCounted
const DATA := preload("res://src/data/summoner_audio_catalog.gd")

# A shared budget on the owning hero prevents pooled summons from stacking portals.
static func play_portal(owner: Node, player: AudioStreamPlayer) -> bool:
	if not is_instance_valid(owner) or not is_instance_valid(player) or player.stream == null:
		return false
	if Time.get_ticks_msec() < int(owner.get_meta("summoner_portal_next_ms", 0)):
		return false
	var previous: Variant = owner.get_meta("summoner_portal_voice") if owner.has_meta("summoner_portal_voice") else null
	if previous is WeakRef:
		var voice = previous.get_ref()
		if is_instance_valid(voice) and voice.playing:
			return false
	player.volume_db = DATA.PORTAL_DB
	player.max_polyphony = 1
	player.pitch_scale = 1.0
	player.play()
	owner.set_meta("summoner_portal_next_ms", Time.get_ticks_msec()+DATA.PORTAL_INTERVAL_MS)
	owner.set_meta("summoner_portal_voice", weakref(player))
	return true
