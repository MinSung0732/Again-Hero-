extends Node2D
const R := preload("res://rules.gd")
const CONNECTION := preload("res://connection.gd")
var connection = CONNECTION.new()
var status: Label
var frame := 0
var shown_snapshots := -1

func _ready():
	Engine.physics_ticks_per_second = R.TICK_RATE
	if "--server" in OS.get_cmdline_user_args():
		var result: int = connection.host()
		print("PROBE_SERVER ",result)
		if result != OK:get_tree().quit(1)
		return
	var panel := VBoxContainer.new()
	panel.position = Vector2(20,20)
	add_child(panel)
	var join_button := Button.new()
	join_button.text = "로컬 테스트 서버 접속"
	join_button.pressed.connect(func():connection.join())
	panel.add_child(join_button)
	status = Label.new()
	panel.add_child(status)
	var help := Label.new()
	help.text = "첫 접속: 용사 / WASD·방향키 이동, Space 공격\n두 번째 접속: 마왕 / 마우스 왼쪽 클릭 소환\n테스트 규칙: 용사 6처치 승리 / 마왕 용사 HP0 승리\n종료·연결 끊김 후 서버부터 다시 실행"
	panel.add_child(help)

func _physics_process(_delta):
	connection.step()
	if connection.server:return
	frame += 1
	if connection.role == R.HERO and frame % 3 == 0:
		var axis := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		connection.send_input(R.MOVE,axis)
	if status != null and shown_snapshots != connection.snapshots:
		shown_snapshots = connection.snapshots
		status.text = "역할 %s | 서버 tick %d | 용사 HP %d | 마력 %.1f | 처치 %d | 결과 %d" % ["용사" if connection.role == R.HERO else ("마왕" if connection.role == R.DEMON else "대기"),connection.world.tick,connection.world.hero_hp,connection.world.mana,connection.world.kills,connection.world.winner]
	queue_redraw()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		connection.send_input(R.ATTACK)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and connection.role == R.DEMON:
		connection.send_input(R.SUMMON,get_global_mouse_position())

func _draw():
	draw_rect(Rect2(0,0,R.WIDTH,R.HEIGHT),Color(0.08,0.07,0.12))
	draw_circle(connection.world.hero_position,20,Color.CORNFLOWER_BLUE)
	for i in R.CAPACITY:
		if connection.world.hp[i] <= 0:continue
		draw_circle(Vector2(connection.world.x[i],connection.world.y[i]),16,Color.TOMATO)
		draw_arc(Vector2(connection.world.x[i],connection.world.y[i]),20,-PI/2,-PI/2+TAU*connection.world.hp[i]/R.MONSTER_HP,16,Color.LIME_GREEN,3)

func _exit_tree():connection.close()
