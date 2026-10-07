extends RefCounted

# Detection changes invalidate hero caches even within the same physics frame.
static var revision: int = 0


static func is_detectable(actor: Node) -> bool:
	return (
		is_instance_valid(actor)
		and not actor.is_queued_for_deletion()
		and not bool(actor.get_meta("hero_detection_hidden", false))
	)


static func set_hidden(actor: Node, hidden: bool) -> void:
	if bool(actor.get_meta("hero_detection_hidden", false)) == hidden:
		return
	actor.set_meta("hero_detection_hidden", hidden)
	revision += 1


static func filter_detectable(actors: Array) -> void:
	# Stable linear compaction: reuse the caller's scratch array, no remove_at loop.
	var write_index := 0
	for read_index in range(actors.size()):
		var actor = actors[read_index]
		if not is_detectable(actor):
			continue
		actors[write_index] = actor
		write_index += 1
	actors.resize(write_index)
