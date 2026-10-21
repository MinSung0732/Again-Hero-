extends RefCounted
## Generic ("shield" kind) monster shields, tracked per source so damage can
## spend them in a defined order (2026-10-21 design):
##   1. conditional ranged/melee shields (handled by the caller first)
##   2. generic shields: expiring ones first by remaining time (Arthur's
##      blessing is the only expiring one), then permanent ones newest first
##      (own spawn shield, support/self shields per source)
##   3. per-monster elite shields (handled by each monster afterwards)
##
## `support_shield_hp` stays the authoritative total that bars, AI and tests
## read. Entries live in `support_shield_entries` {source: {hp, seq}}. Any
## total not covered by entries (set directly by legacy code or tests) is an
## untracked portion treated as the newest grant, so nothing is ever lost.
const ENTRIES_META := &"support_shield_entries"
const TOTAL_META := &"support_shield_hp"
const CAPACITY_META := &"support_shield_capacity"
const SPAWN_SEQ_META := &"temporary_shield_seq"
const UNTRACKED := ""
# Shared read-only empty view: monsters without tracked entries allocate nothing per hit.
const NO_ENTRIES := {}

static var _seq := 0


static func next_seq() -> int:
	_seq += 1
	return _seq


## add: hp += amount. refresh_max: hp = max(hp, amount) for that source only,
## so a source never stacks with itself. reset_capacity mirrors writers that
## sized the bar to the new total instead of keeping the larger capacity.
static func grant(actor: Node, source: String, amount: int, refresh_max: bool = false, reset_capacity: bool = false) -> void:
	if source == UNTRACKED:
		source = "support"  # The empty key is reserved for the untracked portion.
	var entries := _reconciled_entries(actor, true)
	var entry: Dictionary = entries.get(source, {})
	var previous := int(entry.get("hp", 0))
	var hp := maxi(previous, amount) if refresh_max else previous + maxi(amount, 0)
	entries[source] = {"hp": hp, "seq": next_seq()}
	var total := int(actor.get_meta(TOTAL_META, 0)) + hp - previous
	actor.set_meta(TOTAL_META, total)
	actor.set_meta(CAPACITY_META, total if reset_capacity else maxi(total, int(actor.get_meta(CAPACITY_META, 0))))


static func clear(actor: Node) -> void:
	actor.set_meta(TOTAL_META, 0)
	if actor.has_meta(ENTRIES_META):
		actor.remove_meta(ENTRIES_META)


## Spends generic shields in order and returns the damage left for HP.
## Allocation-free on the hot path: candidates are picked one by one.
static func consume(owner: Node, amount: int, receipt, receipt_revision: int, on_absorbed: Callable) -> int:
	if amount <= 0:
		return amount
	# Expiring first: Arthur's blessing is the only timed generic shield.
	if int(owner.get_meta("arthur_blessing_hp", 0)) > 0:
		var blessing := owner.get_node_or_null("ArthurBlessing")
		if blessing != null:
			amount = blessing.absorb(amount, receipt, receipt_revision)
	var spawn_generic := String(owner.get_meta("temporary_shield_kind", "")) == "shield"
	while amount > 0:
		var best_source := UNTRACKED
		var best_seq := -1
		var best_is_spawn := false
		if spawn_generic and int(owner.get_meta("temporary_shield_hp", 0)) > 0:
			best_seq = int(owner.get_meta(SPAWN_SEQ_META, 0))
			best_is_spawn = true
		var total := int(owner.get_meta(TOTAL_META, 0))
		var tracked := 0
		var entries: Dictionary = _reconciled_entries(owner, false)
		for source in entries:
			var entry: Dictionary = entries[source]
			var hp := int(entry.hp)
			tracked += hp
			if hp > 0 and int(entry.seq) > best_seq:
				best_seq = int(entry.seq)
				best_source = source
				best_is_spawn = false
		var untracked := total - tracked
		if untracked > 0:
			# A direct write to the total (legacy code/tests) happened after the
			# last tracked grant, so it is the newest permanent shield.
			best_source = UNTRACKED
			best_is_spawn = false
		elif best_seq < 0:
			break
		var absorbed := 0
		if best_is_spawn:
			var spawn_hp := int(owner.get_meta("temporary_shield_hp", 0))
			absorbed = mini(amount, spawn_hp)
			owner.set_meta("temporary_shield_hp", spawn_hp - absorbed)
		else:
			var available := untracked if best_source == UNTRACKED else int(entries[best_source].hp)
			absorbed = mini(amount, available)
			if best_source != UNTRACKED:
				var remaining := available - absorbed
				if remaining > 0: entries[best_source].hp = remaining
				else: entries.erase(best_source)
			owner.set_meta(TOTAL_META, total - absorbed)
		if absorbed <= 0:
			break
		amount -= absorbed
		if receipt != null:
			receipt.record_shield(absorbed, receipt_revision)
		on_absorbed.call(owner, absorbed)
	return amount


## Entries for `actor`, trimmed so they never exceed the authoritative total
## (legacy code may lower or zero the total directly). Oldest are trimmed first.
static func _reconciled_entries(actor: Node, create: bool) -> Dictionary:
	if not actor.has_meta(ENTRIES_META):
		if not create:
			return NO_ENTRIES
		actor.set_meta(ENTRIES_META, {})
	var entries: Dictionary = actor.get_meta(ENTRIES_META)
	if entries.is_empty():
		return entries
	var total := int(actor.get_meta(TOTAL_META, 0))
	var tracked := 0
	for source in entries:
		tracked += int(entries[source].hp)
	while tracked > total and not entries.is_empty():
		var oldest := UNTRACKED
		var oldest_seq := -1
		for source in entries:
			if oldest_seq < 0 or int(entries[source].seq) < oldest_seq:
				oldest_seq = int(entries[source].seq)
				oldest = source
		var excess := tracked - total
		var hp := int(entries[oldest].hp)
		if hp <= excess:
			entries.erase(oldest)
			tracked -= hp
		else:
			entries[oldest].hp = hp - excess
			tracked = total
	return entries
