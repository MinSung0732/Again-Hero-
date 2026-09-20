extends Control

@onready var battle = $Battle
@onready var hero_hp_label: Label = $TopBar/HeroHP
@onready var monsters_label: Label = $TopBar/Monsters
@onready var status_label: Label = $BottomBar/Status
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = $ResultPanel/Margin/VBox/ResultTitle
@onready var result_message: Label = $ResultPanel/Margin/VBox/ResultMessage
@onready var restart_button: Button = $ResultPanel/Margin/VBox/RestartButton

func _ready() -> void:
	battle.stats_changed.connect(_on_stats_changed)
	battle.battle_finished.connect(_on_battle_finished)
	restart_button.pressed.connect(_on_restart_pressed)

	var snapshot: Dictionary = battle.get_snapshot()
	_on_stats_changed(
		int(snapshot.get("hero_hp", 0)),
		int(snapshot.get("hero_max_hp", 0)),
		int(snapshot.get("monsters_left", 0))
	)

	print("Again, Hero? Milestone 1 loaded.")
	print("Hero vs Slime auto battle started.")

func _on_stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int) -> void:
	hero_hp_label.text = "용사 HP %d / %d" % [hero_hp, hero_max_hp]
	monsters_label.text = "슬라임 %d" % monsters_left

func _on_battle_finished(message: String, player_won: bool) -> void:
	if player_won:
		result_title.text = "HERO SLAIN"
		status_label.text = "용사를 쓰러뜨렸습니다. 첫 번째 전투 시스템 검증 성공!"
	else:
		result_title.text = "EXPERIMENT FAILED"
		status_label.text = "용사가 슬라임을 전멸시켰습니다. 다음 단계에서는 더 강한 공세를 설계합니다."

	result_message.text = message
	result_panel.show()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
