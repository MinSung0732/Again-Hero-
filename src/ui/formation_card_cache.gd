extends RefCounted

# Only collection controls are cached. No combat scenes or animation frames.
var host: Control
var storage: Control
var cards: Dictionary = {}
var generation := 0
var pending := false
var created_count := 0
var max_created_in_slice := 0

func install(lobby: Control) -> void:
	host = lobby
	storage = Control.new()
	storage.name = "FormationCardCache"
	storage.hide()
	host.add_child(storage)

func clear_grid() -> void:
	generation += 1
	pending = false
	if is_instance_valid(host._team_upgrade_feedback):
		host._team_upgrade_feedback.stop()
		host._team_upgrade_feedback.reparent(host, false)
	for child in host.team_monster_grid.get_children():
		if child.has_meta("collection_cache_id"):
			child.reset_for_cache()
			child.reparent(storage, false)
		else:
			host.team_monster_grid.remove_child(child)
			child.queue_free()

func _signature(id: String) -> Array:
	return [id in host.team_available_ids, id in host.team_selected_ids,
		host.monster_collection_state.get(id, {}).duplicate()]

func rebuild(ids: Array) -> void:
	clear_grid()
	var visible_ids: Array[String] = []
	for raw_id in ids:
		var id := String(raw_id)
		var unlocked: bool = id in host.team_available_ids
		if host.formation_unlock_filter == "unlocked" and not unlocked:
			continue
		if host.formation_unlock_filter == "locked" and unlocked:
			continue
		visible_ids.append(id)
	host.get_node(host.TEAM_FORMATION_VIEW.PATH + "/EmptyCollection").visible = visible_ids.is_empty()
	# A warm collection can be reattached immediately without allocations or I/O.
	var cold := false
	for id in visible_ids:
		if not cards.has(id):
			cold = true
			break
	pending = cold
	_populate(visible_ids, generation, cold)

func _populate(ids: Array[String], token: int, cold: bool) -> void:
	if cold and cards.is_empty():
		# Paint the selected tab before decoding icons/building its first cards.
		await host.get_tree().process_frame
	var slice_start := Time.get_ticks_usec()
	var slice_created := 0
	for id in ids:
		if not is_instance_valid(host) or not host.is_inside_tree() or token != generation:
			return
		var signature := _signature(id)
		var entry: Dictionary = cards.get(id, {})
		var card: Control = entry.get("card")
		if not is_instance_valid(card) or entry.get("signature") != signature:
			if is_instance_valid(card):
				card.get_parent().remove_child(card)
				card.queue_free()
			card = host._create_team_monster_card(id)
			card.set_meta("collection_cache_id", id)
			cards[id] = {"card": card, "signature": signature}
			created_count += 1
			slice_created += 1
			max_created_in_slice = maxi(max_created_in_slice, slice_created)
		# Capacity changes affect all buttons, including otherwise unchanged cards.
		var action := card.get_meta("team_action") as Button
		var selected: bool = id in host.team_selected_ids
		action.disabled = id not in host.team_available_ids or (selected and host.team_selected_ids.size() <= 1) or (not selected and host.team_selected_ids.size() >= host.TEAM_MAX_SLOTS)
		if card.get_parent() != null:
			card.reparent(host.team_monster_grid, false)
		else:
			host.team_monster_grid.add_child(card)
		# Never construct the entire cold collection in the button's input frame.
		if cold and (slice_created >= 3 or Time.get_ticks_usec() - slice_start >= 3000):
			await host.get_tree().process_frame
			slice_start = Time.get_ticks_usec()
			slice_created = 0
	if token == generation:
		pending = false
