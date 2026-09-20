extends Control

@onready var battle = $Battle
@onready var hero_level_label: Label = $TopBar/HeroLevel
@onready var hero_hp_label: Label = $TopBar/HeroHP
@onready var monsters_label: Label = $TopBar/Monsters
@onready var exp_label: Label = $TopBar/ExpLabel
@onready var exp_bar: ProgressBar = $TopBar/ExpBar

@onready var build_label: Label = $BottomBar/BuildLabel
@onready var status_label: Label = $BottomBar/Status
@onready var command_label: Label = $BottomBar/CommandLabel
@onready var command_bar: ProgressBar = $BottomBar/CommandBar
@onready var slime_button: Button = $BottomBar/SummonButtons/SlimeButton
@onready var spider_button: Button = $BottomBar/SummonButtons/SpiderButton
@onready var orc_button: Button = $BottomBar/SummonButtons/OrcButton

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
	battle.hero_augment_selected.connect(_on_hero_augment_selected)
	battle.command_changed.connect(_on_command_changed)
	battle.summon_result.connect(_on_summon_result)
	battle.battle_finished.connect(_on_battle_finished)

	slime_button.pressed.connect(_on_summon_pressed.bind("slime"))
	spider_button.pressed.connect(_on_summon_pressed.bind("spider"))
	orc_button.pressed.connect(_on_summon_pressed.bind("orc"))
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
	_on_command_changed(
		float(snapshot.get("command_power", 0.0)),
		float(snapshot.get("command_max", 100.0))
	)

	build_label.text = "용사 빌드: %s" % String(snapshot.get("hero_build_summary", "아직 선택 없음"))
	status_label.text = "지휘력을 사용해 원하는 몬스터를 소환하세요."

	print("Again, Hero? portrait prototype loaded.")
	print("Demon commander summon controls enabled.")

func _on_stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int) -> void:
	hero_hp_label.text = "용사 HP %d / %d" % [hero_hp, hero_max_hp]
	monsters_label.text = "몬스터 %d" % monsters_left

func _on_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	hero_level_label.text = "Lv.%d" % level
	exp_label.text = "EXP %d / %d" % [current_exp, exp_to_next_level]
	exp_bar.max_value = maxf(float(exp_to_next_level), 1.0)
	exp_bar.value = float(current_exp)

func _on_command_changed(current_value: float, max_value: float) -> void:
	command_label.text = "지휘력 %d / %d" % [int(round(current_value)), int(round(max_value))]
	command_bar.max_value = maxf(max_value, 1.0)
	command_bar.value = current_value

	slime_button.disabled = current_value + 0.001 < battle.get_monster_cost("slime")
	spider_button.disabled = current_value + 0.001 < battle.get_monster_cost("spider")
	orc_button.disabled = current_value + 0.001 < battle.get_monster_cost("orc")

func _on_summon_pressed(monster_type: String) -> void:
	battle.try_summon(monster_type)

func _on_summon_result(_monster_type: String, success: bool, message: String) -> void:
	if success:
		status_label.text = "%s\n스폰 위치는 현재 자동 선택됩니다." % message
	else:
		status_label.text = message

func _on_hero_leveled_up(new_level: int) -> void:
	status_label.text = "용사 Lv.%d 도달!\nAI가 증강 후보를 평가합니다." % new_level

func _on_hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String) -> void:
	var candidate_names: PackedStringArray = []
	for candidate in candidates:
		candidate_names.append(String(candidate.get("name", "?")))

	build_label.text = "용사 빌드: %s" % build_summary
	status_label.text = "Lv.%d 후보: %s\nAI → %s · %s" % [
		level,
		" / ".join(candidate_names),
		chosen_name,
		reason,
	]

func _on_battle_finished(message: String, player_won: bool) -> void:
	slime_button.disabled = true
	spider_button.disabled = true
	orc_button.disabled = true

	if player_won:
		result_title.text = "HERO SLAIN"
		status_label.text = "용사를 쓰러뜨렸습니다. 마왕 승리!"
	else:
		result_title.text = "EXPERIMENT FAILED"
		status_label.text = "이번 실험이 종료되었습니다."

	result_message.text = message
	result_panel.show()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
