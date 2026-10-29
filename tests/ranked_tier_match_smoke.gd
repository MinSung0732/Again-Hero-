extends SceneTree
const RANKED := preload("res://src/data/ranked_rules.gd")
const RULES := preload("res://src/online/match_rules.gd")
const QUEUE := preload("res://src/online/match_queue.gd")
const STORE := preload("res://src/online/ranked_result_store.gd")
func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); quit(1); assert(ok, message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for row in [[999,0],[1000,0],[1099,0],[1100,1],[2299,11],[2300,12],[2500,13],[3299,15],[3300,16]]:
		check(RANKED.tier_index(row[0]) == row[1], "tier boundary %s" % row[0])
	var q = QUEUE.new()
	q.enqueue(1,"h1","hero",2,0.0); q.enqueue(2,"h2","hero",3,1.0)
	q.enqueue(3,"d1","demon",3,2.0); q.enqueue(4,"d2","demon",2,3.0)
	check(q.pair(30.0) == [1,4], "same tier hero FIFO")
	check(q.pair(30.0) == [2,3], "remaining same tier")
	q.enqueue(5,"h3","hero",2,0.0); q.enqueue(6,"d3","demon",3,1.0)
	check(q.pair(RULES.MATCH_TIER_EXPAND_SECONDS - 0.1).is_empty(), "before expansion")
	check(q.pair(RULES.MATCH_TIER_EXPAND_SECONDS) == [5,6], "after expansion")
	q.enqueue(7,"h4","hero",2,0.0); q.enqueue(8,"d4","demon",4,0.0)
	check(q.pair(10000.0).is_empty(), "never expand beyond range")
	q.enqueue(10,"d5","demon",-1,2.0)
	check(q.pair(10000.0).is_empty(), "rated and unrated cannot pair")
	q.enqueue(9,"h5","hero",-1,1.0)
	check(q.pair(10000.0) == [9,10], "unrated isolated and FIFO")
	q.enqueue(11,"h6","hero",-1,3.0); q.enqueue(12,"h7","hero",-1,4.0)
	q.enqueue(13,"d6","demon",-1,5.0); q.enqueue(14,"d7","demon",-1,6.0)
	check(q.pair(10000.0) == [11,13] and q.pair(10000.0) == [12,14], "unrated FIFO")
	var store = STORE.new(); root.add_child(store)
	check(await store.fetch_mmr("missing", "demon") == int(RANKED.data().initial_mmr), "unconfigured default")
	store.endpoint = "https://example.invalid"; store.service_key = "fixture"
	var uid := "00000000-0000-4000-8000-000000000001"
	var expires := Time.get_ticks_msec() / 1000.0 + 60.0
	store.mmr_cache[uid + ":demon"] = {"mmr":1200,"expires":expires}
	store.mmr_cache[uid + ":hero"] = {"mmr":1800,"expires":expires}
	check(await store.fetch_mmr(uid, "demon") == 1200 and await store.fetch_mmr(uid, "hero") == 1800, "role caches are independent")
	store.service_key = ""
	await store.record("fixture",uid,uid,"hero","kill",{})
	check(not store.mmr_cache.has(uid + ":demon") and not store.mmr_cache.has(uid + ":hero"), "record invalidates each role")
	store.queue_free()
	print("ranked tier matching passed")
	quit()
