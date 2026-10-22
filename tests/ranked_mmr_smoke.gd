extends SceneTree
const RANKED := preload("res://src/data/ranked_rules.gd")
const SERVER := preload("res://src/online/match_server.gd")
const STORE := preload("res://src/online/ranked_result_store.gd")
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check(RANKED.delta(true,0.0) == 10 and RANKED.delta(true,1.0) == 30,"win boundaries")
	check(RANKED.delta(false,0.0) == -10 and RANKED.delta(false,1.0) == -25,"loss boundaries")
	check(RANKED.delta(true,0.5) == 20 and RANKED.delta(false,0.5) == -18,"round half margin")
	var demon_left := RANKED.margins("hero","opponent_left",0,180,0)
	check(RANKED.delta(true,demon_left.hero) == 20 and RANKED.delta(false,demon_left.demon) == -25,"leaver penalty")
	check(is_equal_approx(RANKED.margins("demon","kill",45,180,0).demon,0.75),"demon time margin")
	check(is_equal_approx(RANKED.margins("hero","survived",180,180,0.6).hero,0.6),"hero HP margin")
	# The loser shares the match's decisiveness: a fast kill costs the hero more.
	var fast_kill := RANKED.margins("demon","kill",45,180,0)
	check(is_equal_approx(fast_kill.hero,0.75) and RANKED.delta(true,fast_kill.demon) == 25 and RANKED.delta(false,fast_kill.hero) == -21,"decisive loss costs more")
	var close_win := RANKED.margins("hero","survived",180,180,0.05)
	check(RANKED.delta(true,close_win.hero) == 11 and RANKED.delta(false,close_win.demon) == -11,"close result moves both less")
	for sample in [[999,"bronze_1"],[1000,"bronze_1"],[1099,"bronze_1"],[1100,"bronze_2"],[2599,"diamond_4"],[2600,"demon_lord"]]:
		check(RANKED.tier(sample[0]) == sample[1],"tier at %d" % sample[0])
	check(RANKED.tier(2600,100) == "hero" and RANKED.tier(2600,101) == "demon_lord","server top 100")
	var server = SERVER.new(); root.add_child(server)
	server.result_store = STORE.new(); server.add_child(server.result_store)
	server.result_store.endpoint = "https://example.invalid"; server.result_store.service_key = "fixture"
	var demon_uid := "00000000-0000-4000-8000-000000000001"
	var hero_uid := "00000000-0000-4000-8000-000000000002"
	var match_data := {"seats":{"demon":{"uid":demon_uid},"hero":{"uid":hero_uid}},"result_started":false}
	check(server._result_can_record(match_data,"demon","kill"),"eligible rated match")
	match_data.result_started = true
	check(not server._result_can_record(match_data,"demon","kill"),"duplicate match id guard")
	match_data.result_started = false
	server.test_auth = true
	check(not server._result_can_record(match_data,"demon","kill"),"test auth unrated")
	server.test_auth = false; server.local_test_ticket = "fixture"
	check(not server._result_can_record(match_data,"demon","kill"),"invitation unrated")
	server.local_test_ticket = ""
	check(not server._result_can_record(match_data,"","both_disconnected"),"void unrated")
	check(not server._result_can_record(match_data,"hero","ready_timeout"),"preparation unrated")
	check(not server._result_can_record(match_data,"hero","practice"),"practice unrated")
	server.result_store.service_key = ""
	check(not server._result_can_record(match_data,"hero","survived"),"missing credentials unrated")
	server.queue_free()
	print("ranked_mmr_smoke PASS %d checks" % checks)
	quit()
