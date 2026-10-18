extends Control
const RULES := preload("res://src/online/match_rules.gd")
const CONFIG := preload("res://src/online/online_config.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const PAD := preload("res://src/hero_mode/hero_move_pad.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var client
var view
var status: Label
var action_notice: Label
var choices: VBoxContainer
var action_row: HBoxContainer
var queue_button: Button
var endpoint: LineEdit
var pad
var role := "hero"
var selected_monster := "slime"
var movement := Vector2.ZERO
var input_left := 0.0
var last_tick := -1
var revision := -1
var initial_owner := ""
var ended := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var options: Dictionary = SceneTransition.consume_entry_options()
	role = String(options.get("role","hero")); initial_owner = LoginGateway.user_id
	var rows := VBoxContainer.new(); add_child(rows); rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.offset_left = 24; rows.offset_right = -24; rows.offset_top = 35; rows.offset_bottom = -30
	_label(rows,"랭킹 매칭 · 연결 테스트",34)
	_label(rows,"견습마도사 ↔ 마왕 · 3분 생존 · 점수/보상/스테미너 변동 없음",22)
	status = _label(rows,"마왕으로 대기합니다." if role == "demon" else "용사로 대기합니다.",26)
	action_notice = _label(rows,"용사: WASD/방향키 또는 전장 드래그 · 마왕: 몬스터 선택 후 전장 터치",22)
	endpoint = LineEdit.new(); endpoint.placeholder_text = "대전 서버 주소 (wss://...)"; endpoint.text = CONFIG.endpoint()
	endpoint.custom_minimum_size.y = 72; endpoint.add_theme_font_size_override("font_size",25); rows.add_child(endpoint)
	queue_button = _button(rows,"매칭 시작",_join)
	view = VIEW.new(); view.size_flags_vertical = Control.SIZE_EXPAND_FILL; view.custom_minimum_size.y = 400; rows.add_child(view)
	view.placement.connect(func(point: Vector2):
		if role == "demon" and not ended: client.command("summon",{"id":selected_monster,"point":[point.x,point.y]}))
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
	client = CLIENT.new(); add_child(client); client.event_received.connect(_event)
	client.connection_closed.connect(func(message: String):
		if not ended: status.text = message
		queue_button.disabled = false; ended = true)
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
	if LoginGateway.user_id.is_empty() or LoginGateway.access_token.is_empty(): status.text = "Google 또는 카카오 로그인이 필요합니다."; return
	if not RULES.endpoint_valid(endpoint.text.strip_edges()): status.text = "공용 대전 서버 주소(wss://)를 입력해 주세요."; return
	ended = false; last_tick = -1; revision = -1
	if pad != null: pad.enabled = true; pad.reset()
	var error: int = client.join(endpoint.text.strip_edges(),LoginGateway.access_token,role)
	status.text = "서버에 연결 중..." if error == OK else "서버에 연결하지 못했습니다."
	queue_button.disabled = error == OK
func _event(event: Dictionary) -> void:
	match String(event.get("op","")):
		"queued": status.text = "상대 역할 플레이어를 찾는 중..."
		"matched":
			status.text = "매칭 완료 · 전투 준비 중..."
			client.send({"op":"ready","match":client.match_id})
		"state":
			if ended or event.get("match","") != client.match_id or not RULES.number(event.get("tick",null)): return
			if not RULES.number(event.get("seconds",null)) or not RULES.number(event.get("mana",null)) or not RULES.number(event.get("choice_revision",null)): return
			if not event.get("choices",null) is Array or event.choices.size() > 4: return
			for option in event.choices:
				if not option is Dictionary or not option.get("id",null) is String or not option.get("name",null) is String: return
			if int(event.tick) <= last_tick or not view.update_state(event): return
			last_tick = int(event.tick)
			status.text = "%s · %.0f초 · 용사 HP %d/%d · 지휘력 %.0f" % ["마왕" if role == "demon" else "용사",maxf(0,RULES.DURATION-float(event.seconds)),int(event.hero[2]),int(event.hero[3]),float(event.mana)]
			if role == "hero" and int(event.choice_revision) != revision:
				revision = int(event.choice_revision)
				for child in choices.get_children(): choices.remove_child(child); child.queue_free()
				for option in event.choices: _button(choices,String(option.name),_choose.bind(String(option.id),revision))
		"result":
			if event.get("match","") != client.match_id: return
			ended = true; movement = Vector2.ZERO
			for child in choices.get_children(): child.queue_free()
			status.text = "대전 종료 · "+("무효 경기" if String(event.get("winner","")).is_empty() else "승리" if event.winner == role else "패배")+"\n테스트 경기 · 점수/보상 변동 없음"
			if pad != null: pad.enabled = false; pad.reset()
		"action":
			if event.get("match","") == client.match_id and event.get("message",null) is String: action_notice.text = event.message
		"error":
			ended = true
			status.text = String(RULES.ERROR_MESSAGES.get(event.get("reason","unknown"),"매칭 요청을 처리하지 못했습니다."))
func _choose(id: String,choice_revision: int) -> void: client.command("choose",{"id":id,"revision":choice_revision})
func _process(delta: float) -> void:
	if client == null: return
	if not ended and LoginGateway.user_id != initial_owner: client.close(); status.text = "계정이 변경되어 대전을 종료했습니다."; ended = true
	if ended or role != "hero" or client.match_id.is_empty(): return
	input_left -= delta
	if input_left > 0: return
	input_left = 0.05
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := keyboard.limit_length(1.0) if keyboard.length_squared() > 0 else movement
	client.command("move",[direction.x,direction.y])
func _leave() -> void:
	if client != null: client.close()
	if role == "hero": get_tree().set_meta("hero_lobby_return",true)
	SceneTransition.change_scene("res://src/lobby/Lobby.tscn","로비 준비 중...")
func _exit_tree() -> void:
	if client != null: client.close()
