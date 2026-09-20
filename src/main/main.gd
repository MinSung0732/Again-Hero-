extends Control

@onready var battle = $Battle
@onready var hero_level_label: Label = $TopBar/HeroLevel
@onready var hero_hp_label: Label = $TopBar/HeroHP
@onready var monsters_label: Label = $TopBar/Monsters
@onready var exp_label: Label = $TopBar/ExpLabel
@onready var exp_bar: ProgressBar = $TopBar/ExpBar
@onready var status_label: Label = $BottomBar/Status
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = $ResultPanel/Margin/VBox/ResultTitle
@onready var result_message: Label = $ResultPanel/Margin/VBox/ResultMessage
@onready var restart_button: Button = $ResultPanel/Margin/VBox/RestartButton

func _ready() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	battle.stats_changed.connect(_on_stats_changed)
	battle.progression_changed.connect(_on_progression_changed)
	battle.hero_leveled_up.connect(_on_hero_leveled_up)
	battle.battle_finished.connect(_on_battle_finished)
	restart_button.pressed.connect(_on_restart_pressed)

	var snapshot: Dictionary = battle.get_snapshot()
	_on_stats_changed(
		int(snapshot.get("hero_hp", 0)),
		int(snapshot.get("hero_max_hp", 0)),
		int(snapshot.get("monsters_left", 0))
	)
	_on_progression_changed(
		int(snapshot.get("hero_level", 1)),
		int(snapshot.get("hero_exp", 0)),
		int(snapshot.get("hero_exp_to_next", 50))
	)

	print("Again, Hero? portrait prototype loaded.")
	print("Hero EXP / level progression enabled.")

func _on_stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int) -> void:
	hero_hp_label.text = "용사 HP %d / %d" % [hero_hp, hero_max_hp]
	monsters_label.text = "슬라임 %d" % monsters_left

func _on_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	hero_level_label.text = "Lv.%d" % level
	exp_label.text = "EXP %d / %d" % [current_exp, exp_to_next_level]
	exp_bar.max_value = maxf(float(exp_to_next_level), 1.0)
	exp_bar.value = float(current_exp)

func _on_hero_leveled_up(new_level: int) -> void:
	status_label.text = "용사 Lv.%d 도달!\n다음 단계에서는 레벨업마다 AI가 증강을 선택합니다." % new_level

func _on_battle_finished(message: String, player_won: bool) -> void:
	if player_won:
		result_title.text = "HERO SLAIN"
		status_label.text = "용사를 쓰러뜨렸습니다.\n첫 번째 전투 시스템 검증 성공!"
	else:
		result_title.text = "EXPERIMENT FAILED"
		status_label.text = "용사가 슬라임을 전멸시켰습니다.\n다음 실험에서는 용사 성장과 증강을 확장합니다."

	result_message.text = message
	result_panel.show()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
