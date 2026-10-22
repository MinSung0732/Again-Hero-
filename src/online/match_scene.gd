extends Control
const RULES := preload("res://src/online/match_rules.gd")
const CONFIG := preload("res://src/online/online_config.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const PAD := preload("res://src/hero_mode/hero_move_pad.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
const LOADING := preload("res://src/online/match_loading_view.gd")
const RANKED := preload("res://src/data/ranked_rules.gd")
var loading
var local_preparing := false
var waiting_for_start := false
var load_revision := 0
const METRICS := preload("res://src/data/online_metrics_catalog.gd")
var metrics_panel: VBoxContainer
var metrics_label: Label
var metrics_left := 0.0
var client
var view
var status: Label
var ranking_row: HBoxContainer
var ranking_icon: TextureRect
var ranking_label: Label
var action_notice: Label
var choices: VBoxContainer
var action_row: HBoxContainer
var queue_button: Button
var endpoint: LineEdit
var test_code: LineEdit
var disconnect_button: Button
var reconnect_button: Button
var initial_local_test := false
var pad
var role := "hero"
var selected_monster := "slime"
var movement := Vector2.ZERO
var input_left := 0.0
var last_tick := -1
var revision := -1
var initial_owner := ""
var ended := false
var connection_waiting := false
var wait_deadline := 0
var wait_seconds := -1
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var options: Dictionary = SceneTransition.consume_entry_options()
	role = String(options.get("role","hero")); initial_owner = LoginGateway.user_id
	initial_local_test = LocalTestMode.is_online_match_allowed()
	var rows := VBoxContainer.new(); add_child(rows); rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.offset_left = 24; rows.offset_right = -24; rows.offset_top = 35; rows.offset_bottom = -30
	_label(rows,"랭킹 매칭",34)
	_label(rows,"견습마도사 ↔ 마왕 · 3분 생존 · 보상/스테미너 변동 없음",22)
	status = _label(rows,"마왕으로 대기합니다." if role == "demon" else "용사로 대기합니다.",26)
	ranking_row = HBoxContainer.new(); ranking_row.visible = false; rows.add_child(ranking_row)
	ranking_icon = TextureRect.new(); ranking_icon.custom_minimum_size = Vector2(56,56)
	ranking_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ranking_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ranking_row.add_child(ranking_icon)
	ranking_label = _label(ranking_row,"",22)
	action_notice = _label(rows,"용사: WASD/방향키 또는 전장 드래그 · 마왕: 몬스터 선택 후 전장 터치",22)
	endpoint = LineEdit.new(); endpoint.placeholder_text = "대전 서버 주소 (wss://...)"; endpoint.text = CONFIG.endpoint()
	endpoint.custom_minimum_size.y = 72; endpoint.add_theme_font_size_override("font_size",25); rows.add_child(endpoint)
	if initial_local_test:
		_label(rows,"로컬 테스트 · 서버에 표시된 입장코드를 입력하세요",22)
		test_code = LineEdit.new(); test_code.secret = true
		test_code.placeholder_text = "테스트 서버 입장코드"; test_code.max_length = LOCAL_ACCESS.TICKET_BYTES * 2
		test_code.custom_minimum_size.y = 72; test_code.add_theme_font_size_override("font_size",25); rows.add_child(test_code)
	queue_button = _button(rows,"매칭 시작",_join)
	if initial_local_test:
		var connection_tests := HBoxContainer.new(); rows.add_child(connection_tests)
		disconnect_button = _button(connection_tests,"연결 끊기 (테스트)",_test_connection.bind(true))
		reconnect_button = _button(connection_tests,"재접속",_test_connection.bind(false))
		disconnect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reconnect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		disconnect_button.disabled = true; reconnect_button.disabled = true
	if initial_local_test:
		var show_metrics := _button(rows,"연결 측정 보기",_toggle_metrics)
		show_metrics.custom_minimum_size.y=56
		metrics_panel=VBoxContainer.new(); rows.add_child(metrics_panel); metrics_panel.visible=false
		metrics_label=_label(metrics_panel,"측정 대기 중…",19)
		var metric_actions := HBoxContainer.new(); metrics_panel.add_child(metric_actions)
		var copy_metrics := _button(metric_actions,"측정값 복사",_copy_metrics)
		var reset_metrics := _button(metric_actions,"측정 초기화",_reset_metrics)
		for button in [copy_metrics,reset_metrics]:
			button.custom_minimum_size.y=56; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	view = VIEW.new(); view.size_flags_vertical = Control.SIZE_EXPAND_FILL; view.custom_minimum_size.y = 400; rows.add_child(view)
	view.placement.connect(func(point: Vector2):
		if role == "demon" and not ended and not local_preparing and not waiting_for_start and not connection_waiting and not client.reconnecting: client.command("summon",{"id":selected_monster,"point":[point.x,point.y]}))
	action_row = HBoxContainer.new(); rows.add_child(action_row)
	if role == "demon":
		for id in RULES.ROSTER:
			var button := _button(action_row,String(MONSTERS.get_monster(id).get("name",id)),_select_monster.bind(id))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.add_theme_font_size_override("font_size",21)
	else:
		pad = PAD.new(); add_child(pad); pad.set_mode(PAD.MODE_FREE)
		pad.input_surface = view; pad.movement_changed.connect(func(value: Vector2): movement = value)
	choices = VBoxContainer.new(); rows.add_child(choices)
	_button(rows,"매칭 취소 · 로비로",_leave)
	loading = LOADING.new(); add_child(loading); loading.cancelled.connect(_leave)
	client = CLIENT.new(); add_child(client); client.event_received.connect(_event)
	client.connection_recovering.connect(func(active: bool,remaining: float):
		if ended: return
		movement = Vector2.ZERO
		if active: view.feedback.pause_feedback(); view.pause_motion()
		_set_controls(not active and not connection_waiting)
		if active:
			status.text = "테스트 연결 끊김 · 재접속 버튼을 누르세요. 상대의 유예 시간 내에 복귀하세요." if client.test_transport_paused else "연결 복구 중… 잠시 기다려 주세요."
			queue_button.disabled = true)
	client.connection_closed.connect(func(message: String):
		if not ended: status.text = message
		view.feedback.pause_feedback(); view.pause_motion()
		queue_button.disabled = false; ended = true; load_revision += 1; loading.finish(); _set_controls(false))
func _label(parent: Node,value: String,font: int) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font); parent.add_child(label); return label
func _button(parent: Node,value: String,callback: Callable) -> Button:
	var button := Button.new(); button.text = value; button.custom_minimum_size.y = 76
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; button.add_theme_font_size_override("font_size",25)
	parent.add_child(button); button.pressed.connect(callback); return button
func _select_monster(id: String) -> void:
	selected_monster = id
	action_notice.text = "소환 선택: %s · 전장 터치로 배치" % String(MONSTERS.get_monster(id).get("name",id))
func _join() -> void:
	if LocalTestMode.is_online_match_allowed() != initial_local_test: status.text = "테스트 모드가 변경되었습니다. 로비에서 다시 입장하세요."; return
	if initial_local_test:
		if not LOCAL_ACCESS.valid_hex(test_code.text.strip_edges(),LOCAL_ACCESS.TICKET_BYTES): status.text = "서버에 표시된 테스트 입장코드를 입력하세요."; return
	elif LoginGateway.user_id.is_empty() or LoginGateway.access_token.is_empty(): status.text = "Google 또는 카카오 로그인이 필요합니다."; return
	if not RULES.endpoint_valid(endpoint.text.strip_edges()): status.text = "공용 대전 서버 주소(wss://)를 입력해 주세요."; return
	ended = false; last_tick = -1; revision = -1; connection_waiting = false
	ranking_row.hide()
	view.clear_state()
	if pad != null: pad.enabled = true; pad.reset()
	var error: int = client.join_local_test(endpoint.text.strip_edges(),test_code.text.strip_edges(),role) if initial_local_test else client.join(endpoint.text.strip_edges(),LoginGateway.access_token,role)
	if test_code != null and error == OK: test_code.clear()
	status.text = "서버에 연결 중..." if error == OK else "서버에 연결하지 못했습니다."
	queue_button.disabled = error == OK
	if error == OK: loading.begin(role); _set_controls(false)
func _event(event: Dictionary) -> void:
	match String(event.get("op","")):
		"queued": status.text = "상대 역할 플레이어를 찾는 중..."
		"matched":
			last_tick = -1; revision = -1; view.resume_motion()
			_refresh_connection_test_controls()
			status.text = "기존 경기로 복귀했습니다." if event.get("resumed",false) else "매칭 완료 · 전투 준비 중..."
			if event.has("feedback_cursor") and not view.FEEDBACK_DATA.valid_cursor(event.feedback_cursor): return
			view.feedback.reset(int(event.get("feedback_cursor",0)))
			load_revision += 1
			local_preparing = true; waiting_for_start = true; _set_controls(false)
			loading.begin(role); loading.show_phase("loading")
			_prepare_match(event,load_revision)
		"connection":
			if event.get("match","") != client.match_id or ended or not event.get("paused",null) is bool or not RULES.number(event.get("remaining",null),RULES.RECONNECT_GRACE): return
			connection_waiting = event.paused
			if connection_waiting: view.feedback.pause_feedback(); view.pause_motion()
			wait_deadline = Time.get_ticks_msec() + int(maxf(0.0,float(event.remaining))*1000.0); wait_seconds = -1
			_set_controls(not connection_waiting and not client.reconnecting)
			if not connection_waiting:
				view.resume_motion(); status.text = "연결이 복구되어 전투를 재개합니다."
		"state":
			if local_preparing: return
			if ended or event.get("match","") != client.match_id or not RULES.number(event.get("tick",null)): return
			if not RULES.number(event.get("seconds",null)) or not RULES.number(event.get("mana",null)) or not RULES.number(event.get("choice_revision",null)): return
			if not event.get("choices",null) is Array or event.choices.size() > 4: return
			for option in event.choices:
				if not option is Dictionary or not option.get("id",null) is String or not option.get("name",null) is String: return
			if int(event.tick) <= last_tick or not view.update_state(event): return
			last_tick = int(event.tick)
			view.feedback.suspended = waiting_for_start or connection_waiting or client.reconnecting
			if waiting_for_start and last_tick > 0 and not connection_waiting and not client.reconnecting:
				waiting_for_start = false; view.feedback.suspended = false; loading.finish(); _set_controls(true)
			if event.has("feedback"): view.feedback.consume(event.feedback,event.feedback_cursor,event.tick)
			if not connection_waiting: status.text = "%s · %.0f초 · 용사 HP %d/%d · 지휘력 %.0f" % ["마왕" if role == "demon" else "용사",maxf(0,RULES.DURATION-float(event.seconds)),int(event.hero[2]),int(event.hero[3]),float(event.mana)]
			if role == "hero" and int(event.choice_revision) != revision:
				revision = int(event.choice_revision)
				for child in choices.get_children(): choices.remove_child(child); child.queue_free()
				for option in event.choices: _button(choices,String(option.name),_choose.bind(String(option.id),revision))
				_set_controls(not connection_waiting and not client.reconnecting)
		"result":
			if event.get("match","") != client.match_id or ended: return
			if event.has("feedback"): view.feedback.consume(event.feedback,event.get("feedback_cursor",null),event.get("tick",null))
			view.feedback.result(String(event.get("winner","")),role); view.pause_motion()
			load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
			ended = true; movement = Vector2.ZERO; connection_waiting = false; queue_button.disabled = false
			_set_controls(false)
			for child in choices.get_children(): child.queue_free()
			status.text = "대전 종료 · "+("무효 경기" if String(event.get("winner","")).is_empty() else "승리" if event.winner == role else "패배")
			var ranking: Variant = event.get("ranking",null)
			if event.get("rated",false) == true and ranking is Dictionary and RULES.number(ranking.get("mmr",null)) and RULES.number(ranking.get("delta",null)):
				var tier_id := String(ranking.get("tier",""))
				var icon := RANKED.icon_path(tier_id)
				if not icon.is_empty() and ResourceLoader.exists(icon):
					ranking_icon.texture = load(icon)
					ranking_label.text = "MMR %s%d → %d · %s" % ["+" if int(ranking.delta) >= 0 else "",int(ranking.delta),int(ranking.mmr),RANKED.display_name(tier_id)]
					ranking_row.show()
			if not ranking_row.visible:
				status.text += "\n점수 변동 없음"
			if pad != null: pad.enabled = false; pad.reset()
		"action":
			if event.get("match","") == client.match_id and event.get("message",null) is String: action_notice.text = event.message
		"error":
			view.feedback.pause_feedback(); view.pause_motion()
			load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
			ended = true
			_set_controls(false)
			status.text = String(RULES.ERROR_MESSAGES.get(event.get("reason","unknown"),"매칭 요청을 처리하지 못했습니다."))
func _prepare_match(event: Dictionary,serial: int) -> void:
	var current := func(): return is_inside_tree() and serial == load_revision and not ended and not client.reconnecting
	await get_tree().process_frame
	if not current.call(): return
	if event.has("battlefield"):
		var progress := func(value: float):
			if current.call(): loading.show_phase("loading",value)
		var prepared: bool = await view.prepare_battlefield_async(event.battlefield,current,progress)
		if not current.call(): return
		if not prepared:
			ended = true; local_preparing = false; waiting_for_start = false; loading.finish()
			client.close(); status.text = "전장 정보를 준비하지 못했습니다."; _set_controls(false); return
	local_preparing = false; loading.show_phase("waiting",1.0)
	client.send({"op":"ready","match":client.match_id})
func _set_controls(enabled: bool) -> void:
	enabled = enabled and not local_preparing and not waiting_for_start
	_refresh_connection_test_controls()
	if not enabled: movement = Vector2.ZERO
	if pad != null:
		pad.enabled = enabled
		if not enabled: pad.reset()
	for button in action_row.get_children(): button.disabled = not enabled
	for button in choices.get_children(): button.disabled = not enabled
func _refresh_connection_test_controls() -> void:
	if disconnect_button == null: return
	var allowed: bool = not ended and LocalTestMode.is_online_match_allowed() and client.local_test_connection and not client.match_id.is_empty() and not client.resume_token.is_empty() and not client.result_received
	disconnect_button.disabled = not allowed or client.reconnecting or client.socket == null or client.socket.get_ready_state() != WebSocketPeer.STATE_OPEN
	reconnect_button.disabled = not allowed or not client.test_transport_paused
func _test_connection(disconnected: bool) -> void:
	if initial_local_test and not ended and client.set_local_test_disconnected(disconnected):
		_refresh_connection_test_controls()
func _choose(id: String,choice_revision: int) -> void:
	if not ended and not connection_waiting and not client.reconnecting: client.command("choose",{"id":id,"revision":choice_revision})
func _process(delta: float) -> void:
	if client == null: return
	if metrics_panel!=null and metrics_panel.visible:
		metrics_left-=delta
		if metrics_left<=0:
			metrics_left=METRICS.PANEL_SECONDS; _refresh_metrics()
	if not ended and LocalTestMode.is_online_match_allowed() != initial_local_test: client.close(); view.feedback.pause_feedback(); view.pause_motion(); status.text = "테스트 모드가 변경되어 대전을 종료했습니다."; ended = true; _set_controls(false)
	if not ended and LoginGateway.user_id != initial_owner: client.close(); view.feedback.pause_feedback(); view.pause_motion(); status.text = "계정이 변경되어 대전을 종료했습니다."; ended = true; _set_controls(false)
	if connection_waiting and not ended and not client.reconnecting:
		var seconds := maxi(0,int(ceil(float(wait_deadline-Time.get_ticks_msec())/1000.0)))
		if seconds != wait_seconds:
			wait_seconds = seconds
			status.text = "상대 연결 복구 대기 · %d초 · 전투 일시정지" % seconds if seconds > 0 else "재접속 결과를 확인하고 있습니다…"
	if ended and loading.visible:
		load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
	if ended or local_preparing or waiting_for_start or connection_waiting or client.reconnecting or role != "hero" or client.match_id.is_empty(): return
	input_left -= delta
	if input_left > 0: return
	input_left = 0.05
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := keyboard.limit_length(1.0) if keyboard.length_squared() > 0 else movement
	client.command("move",[direction.x,direction.y])
func _leave() -> void:
	load_revision += 1; ended = true; view.feedback.pause_feedback(); view.pause_motion(); loading.finish()
	if client != null: client.close()
	if role == "hero": get_tree().set_meta("hero_lobby_return",true)
	SceneTransition.change_scene("res://src/lobby/Lobby.tscn","로비 준비 중...")
func _exit_tree() -> void:
	load_revision += 1
	if client != null: client.close()

func _toggle_metrics() -> void:
	if metrics_panel==null: return
	metrics_panel.visible=not metrics_panel.visible; metrics_left=0
func _metric_text(sample: Dictionary) -> String:
	return "미측정" if sample.count==0 else "%.1f / %.1f ms" % [sample.mean_ms,sample.p95_ms]
func _refresh_metrics() -> void:
	var data: Dictionary = client.metrics.report(role)
	metrics_label.text="FPS %d · RTT 평균/P95 %s\n수신간격 평균/P95 %s\n입력 처리 확인 평균/P95 %s\n수신 %.1f / 송신 %.1f KiB/s (본문)" % [Engine.get_frames_per_second(),_metric_text(data.rtt),_metric_text(data.state_gap),_metric_text(data.input_confirmation),data.rx_kib_s,data.tx_kib_s]
	if not data.server.is_empty():
		var value: Dictionary=data.server
		var snapshot_text := "미측정" if value.snapshot_samples==0 else "%.2f ms" % value.snapshot_ms
		var encode_text := "미측정" if value.encode_samples==0 else "%.2f ms" % value.encode_ms
		metrics_label.text+="\n서버 전체 물리 %.2f ms · 스냅샷/인코딩 평균 %s / %s\n방 %d · 연결 %d · 몬스터 %d · 투사체 %d · 상태 %.1f KiB" % [value.physics_ms,snapshot_text,encode_text,value.rooms,value.peers,value.actors,value.projectiles,value.snapshot_bytes/1024.0]
func _metrics_json() -> String:
	return JSON.stringify(client.metrics.report(role),"\t")
func _copy_metrics() -> void:
	if DisplayServer.get_name()!="headless": DisplayServer.clipboard_set(_metrics_json())
	action_notice.text="측정값을 복사했습니다." if DisplayServer.get_name()!="headless" else "현재 환경에서는 클립보드를 사용할 수 없습니다."

func _reset_metrics() -> void:
	client.metrics.reset(); metrics_left=0
