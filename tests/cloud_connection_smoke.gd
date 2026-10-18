extends SceneTree
var checks := 0
var failures := 0
var normal_delay_done := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func normal_delay(owner: Node) -> void:
	await preload("res://src/systems/combat_delay.gd").wait(owner,0.15)
	normal_delay_done = true
func run() -> void:
	var cloud := root.get_node("CloudStore")
	var overlay := root.get_node("CloudConnectionOverlay")
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	cloud.stop()
	cloud._set_connection(true,"서버에 연결 중입니다",false,false)
	check(not paused and overlay.visible, "short writes fence UI without pausing combat")
	await create_timer(0.1).timeout
	cloud._set_connection(false)
	check(not paused and not overlay.visible, "fast acknowledgement never introduces a simulation pause")
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var host := Node.new()
	root.add_child(host)
	current_scene = host
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true
	battle.hero_player_stage = "stage_8"
	battle.hero_player_hero_id = "summoner_hero"
	battle._monster_spawn_resources_warmed = true
	host.add_child(battle)
	battle.set_external_pause(true)
	await process_frame
	var hero = battle.hero
	hero.apply_poison(2.0,0.5,0.1)
	var timer := Timer.new()
	battle.add_child(timer)
	timer.start(3.0)
	var elapsed: float = battle.run_metrics.elapsed_seconds
	var hp: int = hero.current_hp
	var time_left := timer.time_left
	var simulation_clock: int = battle.combat_time_msec()
	cloud._set_connection(true)
	check(paused and overlay.visible, "connection blocks input and pauses tree immediately")
	check(battle.flow_pause_manager.get_reasons_for("combat").has("cloud_connection"), "network owns independent battle pause")
	check(not overlay._view.progress_bar.visible and not overlay._view.progress_label.visible, "connection never invents percentage progress")
	var indicator = overlay._view._indicator
	var first_step: int = indicator.step
	await create_timer(0.3).timeout
	check(indicator.step != first_step, "indicator animates during global pause")
	check(battle.run_metrics.elapsed_seconds == elapsed and battle.combat_time_msec() == simulation_clock, "simulation and boss clocks frozen")
	check(hero.current_hp == hp and not battle.battle_over, "pending poison cannot defeat paused hero")
	check(is_equal_approx(timer.time_left,time_left), "owned timers frozen")
	battle.set_external_pause(false)
	check(battle.is_combat_simulation_paused(), "menu resume cannot release network pause")
	battle.set_external_pause(true)
	await create_timer(0.6).timeout
	check(overlay._view.modulate.a == 1.0, "long connection shows new archive background")
	check(overlay._view.background.texture == overlay.VIEW.CONNECTION, "actual generated reconnect asset applied")
	cloud._set_connection(false)
	check(not paused and not overlay.visible and battle.is_combat_simulation_paused(), "reconnect preserves pre-existing settings pause")
	battle.set_external_pause(false)
	await create_timer(0.18).timeout
	check(battle.run_metrics.elapsed_seconds > elapsed, "battle resumes after all reasons release")
	check(battle.combat_time_msec()-simulation_clock < 400, "reconnect does not catch up wall-clock damage")
	battle.set_external_pause(true)
	battle.queue_free()
	await process_frame
	var normal = load("res://src/battle/Battle.tscn").instantiate()
	normal._monster_spawn_resources_warmed = true
	host.add_child(normal)
	normal.set_external_pause(true)
	normal_delay(normal.hero)
	cloud._set_connection(true)
	var normal_clock: int = normal.combat_time_msec()
	await create_timer(0.3).timeout
	check(normal.combat_time_msec() == normal_clock, "demon mode absolute status clock freezes too")
	check(not normal_delay_done, "demon mode delayed hits freeze with connection")
	cloud._set_connection(false)
	await create_timer(0.2).timeout
	check(normal_delay_done, "demon delayed action resumes after connection")
	check(normal.combat_time_msec()-normal_clock < 350, "demon clock excludes network wait")
	paused = true
	cloud._set_connection(true)
	cloud._set_connection(false)
	check(paused, "pre-existing global pause preserved")
	paused = false
	cloud._set_connection(true,"다른 기기에서 로그인했습니다.",true)
	cloud._retry_later()
	check(cloud.terminal and overlay._return.visible and paused, "terminal sessions cannot auto-resume")
	cloud.stop()
	check(not paused and not overlay.visible, "leaving session releases owned pause")
	var loading = overlay.VIEW.new()
	root.add_child(loading)
	loading.configure("화면 이동 중","다음 던전을 준비합니다.")
	check(loading.background.texture == loading.PORTAL and loading.progress_bar.visible, "scene loading uses generated portal with real progress")
	loading.queue_free()
	host.queue_free()
	await process_frame
	print("CLOUD_CONNECTION_SMOKE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
