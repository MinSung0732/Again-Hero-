extends Control

const STAMINA := preload("res://src/systems/stamina_store.gd")
var _stamina_entry_pending := false
var _battle_stamina_entry: Dictionary = {}
var _battle_started_ms := -1
var _battle_started_unix := -1.0
var _lobby_exit_pending := false
var _mobile_scroll_router := MOBILE_SCROLL_ROUTER.new()

signal demon_action_choice_selected(context: String, choice_id: String)

const FLOATING_TEXT := preload("res://src/ui/damage_number_spawner.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const TEAM_LOADOUT_STORE := preload("res://src/systems/team_loadout_store.gd")
var summon_cinematic = preload("res://src/ui/battle_summon_cinematic.gd").new()
var practice_controls = preload("res://src/ui/practice_battle_controls.gd").new()
var transcendence_view = preload("res://src/ui/transcendence_summon_view.gd").new()
const DEMON_ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const DEMON_SKILL_LOADOUT_STORE := preload(
	"res://src/systems/demon_skill_loadout_store.gd"
)
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const HERO_AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const SKILL_ART := preload("res://src/data/skill_icon_catalog.gd")
const HERO_SKILL_COOLDOWN_BADGE := preload("res://src/ui/hero_skill_cooldown_badge.gd")
const BATTLE_PIXEL_FRAME_ASSEMBLER := preload("res://src/ui/battle_pixel_frame_assembler.gd")
const PIXEL_PANEL_SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const MOBILE_SCROLL_ROUTER := preload("res://src/ui/mobile_scroll_router.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const STAGE_INTRO_DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
const HERO_REVEAL_CATALOG := preload("res://src/data/hero_reveal_catalog.gd")
const HERO_PORTRAIT_REFERENCE_PATH := "res://assets/art/heroes/stage1_mage/stage1_hero_portrait.png"
const TOUCH_HOLD_FRAME_DIR := "res://assets/art/UI/ui_gagebar_frames"
const TOUCH_HOLD_FRAME_COUNT := 8
const TOUCH_HOLD_DELAY := 0.18
const TOUCH_HOLD_FRAME_SECONDS := 0.08
const GAMEPLAY_SETTINGS_PATH := "user://gameplay_settings.cfg"
const CAMERA_DRAG_THRESHOLD := 12.0

const BATTLE_PIXEL_FRAME_LARGE_DIR := "res://assets/art/UI/01_large_left_panel"
const BATTLE_PIXEL_FRAME_TOP_RIGHT_DIR := "res://assets/art/UI/02_top_right_panel"
const BATTLE_PIXEL_FRAME_MEDIUM_DIR := "res://assets/art/UI/03_middle_right_panel"
const BATTLE_PIXEL_CENTER_LARGE := BATTLE_PIXEL_FRAME_LARGE_DIR + "/part_04.png"
const BATTLE_PIXEL_CENTER_DARK := "res://assets/art/UI/05_right_bars/part_02.png"
const BATTLE_PIXEL_BAR_BACKGROUND := "res://assets/art/UI/05_right_bars/part_02.png"

@onready var battle_viewport_container: SubViewportContainer = $BattleViewportContainer
@onready var battle_viewport: SubViewport = $BattleViewportContainer/BattleViewport
@onready var battle = $BattleViewportContainer/BattleViewport/Battle
@onready var hero_bgm_manager = $HeroBGMManager
@onready var hud_layer: CanvasLayer = $HUD
@onready var stage_intro_cutscene = $StageIntroCutscene
@onready var hero_reveal_cutscene = $HeroRevealCutscene
@onready var skill_unlock_cutscene = $SkillUnlockCutscene

@onready var subtitle_label: Label = $HUD/TopBar/Subtitle
@onready var stage_number_label: Label = $HUD/TopBar/StageNumber
@onready var stage_hero_name_label: Label = $HUD/TopBar/StageHeroName
@onready var run_timer_label: Label = $HUD/TopBar/RunTimer
@onready var stage_menu_button: Button = $HUD/TopBar/StageMenuButton
@onready var hero_hud_portrait: TextureRect = $HUD/TopBar/HeroPortrait
@onready var hero_level_label: Label = $HUD/TopBar/HeroLevel
@onready var hero_hp_bar: ProgressBar = $HUD/TopBar/HeroHPBar
@onready var hero_hp_label: Label = $HUD/TopBar/HeroHP
@onready var monsters_label: Label = $HUD/TopBar/Monsters
@onready var exp_label: Label = $HUD/TopBar/ExpLabel
@onready var exp_bar: ProgressBar = $HUD/TopBar/ExpBar
@onready var debug_balance_label: Label = $HUD/DebugBalance
@onready var hero_skill_cooldown_bar: HBoxContainer = $HUD/HeroSkillCooldownBar
@onready var touch_hold_indicator: TextureRect = $HUD/TouchHoldIndicator
@onready var battle_toast: Label = $HUD/BattleToast

@onready var monster_info_bookmark: Button = $HUD/MonsterInfoBookmark
@onready var monster_info_panel: PanelContainer = $HUD/MonsterInfoPanel
@onready var monster_info_close: Button = $HUD/MonsterInfoPanel/Root/Header/Close
@onready var monster_info_tabs: Array[Button] = [
	$HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Tabs/Tab1,
	$HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Tabs/Tab2,
	$HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Tabs/Tab3,
]
@onready var monster_info_portrait: TextureRect = $HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Portrait
@onready var monster_info_name: Label = $HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Name
@onready var monster_info_stats: Label = $HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/Stats
@onready var monster_info_normal: Label = $HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/NormalAugments
@onready var monster_info_special: Label = $HUD/MonsterInfoPanel/Root/Scroll/Margin/VBox/SpecialAugments

@onready var hero_info_bookmark: Button = $HUD/HeroInfoBookmark
@onready var hero_info_panel: PanelContainer = $HUD/HeroInfoPanel
@onready var hero_info_close: Button = $HUD/HeroInfoPanel/Root/Header/Close
@onready var hero_info_portrait: TextureRect = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/Portrait
@onready var hero_info_name: Label = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/Name
@onready var hero_info_stats: Label = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/Stats
@onready var hero_info_abilities: Label = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/Abilities
@onready var hero_info_build: RichTextLabel = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/Build
@onready var hero_info_ai: Label = $HUD/HeroInfoPanel/Root/Scroll/Margin/VBox/AI

@onready var build_label: Label = $HUD/BottomBar/BuildLabel
@onready var status_label: Label = $HUD/BottomBar/Status
@onready var placement_toggle: CheckButton = $HUD/BottomBar/PlacementModeToggle
@onready var demon_progress_label: Label = $HUD/DemonUltimatePanel/DemonProgressLabel
@onready var demon_exp_bar: ProgressBar = $HUD/DemonUltimatePanel/DemonExpBar
@onready var command_label: Label = $HUD/BottomBar/CommandLabel
@onready var command_bar: ProgressBar = $HUD/BottomBar/CommandBar
@onready var demon_ultimate_panel: Control = $HUD/DemonUltimatePanel
@onready var demon_level_label: Label = $HUD/DemonUltimatePanel/DemonLevelLabel
@onready var demon_ultimate_label: Label = $HUD/DemonUltimatePanel/UltimateLabel
@onready var demon_ultimate_bar: ProgressBar = $HUD/DemonUltimatePanel/UltimateBar
@onready var demon_ultimate_1: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate1
@onready var demon_ultimate_2: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate2
@onready var demon_ultimate_3: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate3
@onready var demon_ultimate_1_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate1/CooldownBar
@onready var demon_ultimate_2_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate2/CooldownBar
@onready var demon_ultimate_3_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate3/CooldownBar
@onready var demon_action_choice_grid: GridContainer = $HUD/DemonUltimatePanel/ActionChoiceGrid
@onready var summon_slot_1: Button = $HUD/BottomBar/SummonButtons/Slot1
@onready var summon_slot_2: Button = $HUD/BottomBar/SummonButtons/Slot2
@onready var summon_slot_3: Button = $HUD/BottomBar/SummonButtons/Slot3
@onready var summon_slot_icon_1: TextureRect = $HUD/BottomBar/SummonButtons/Slot1/Icon
@onready var summon_slot_icon_2: TextureRect = $HUD/BottomBar/SummonButtons/Slot2/Icon
@onready var summon_slot_icon_3: TextureRect = $HUD/BottomBar/SummonButtons/Slot3/Icon
@onready var summon_slot_name_1: Label = $HUD/BottomBar/SummonButtons/Slot1/Name
@onready var summon_slot_name_2: Label = $HUD/BottomBar/SummonButtons/Slot2/Name
@onready var summon_slot_name_3: Label = $HUD/BottomBar/SummonButtons/Slot3/Name
@onready var summon_slot_cost_1: Label = $HUD/BottomBar/SummonButtons/Slot1/Cost
@onready var summon_slot_cost_2: Label = $HUD/BottomBar/SummonButtons/Slot2/Cost
@onready var summon_slot_cost_3: Label = $HUD/BottomBar/SummonButtons/Slot3/Cost

@onready var pause_menu: Control = $HUD/PauseMenu
@onready var pause_stage_label: Label = $HUD/PauseMenu/MenuPanel/Margin/VBox/StageLabel
@onready var pause_time_label: Label = $HUD/PauseMenu/MenuPanel/Margin/VBox/TimeLabel
@onready var pause_resume_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/ResumeButton
@onready var pause_restart_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/RestartButton
@onready var pause_settings_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/SettingsButton
@onready var pause_lobby_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/LobbyButton

@onready var settings_overlay: Control = $HUD/SettingsOverlay
@onready var settings_close_button: Button = $HUD/SettingsOverlay/Panel/Margin/VBox/CloseButton
@onready var settings_tabs: TabContainer = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs
@onready var settings_bgm_slider: HSlider = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/BGMRow/Slider
@onready var settings_bgm_value: Label = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/BGMRow/Value
@onready var settings_bgm_mute: CheckBox = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/BGMMute
@onready var settings_sfx_slider: HSlider = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/SFXRow/Slider
@onready var settings_sfx_value: Label = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/SFXRow/Value
@onready var settings_sfx_mute: CheckBox = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Sound/SFXMute
@onready var settings_camera_lock: CheckBox = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Gameplay/CameraLock
@onready var settings_battle_frame: CheckBox = $HUD/SettingsOverlay/Panel/Margin/VBox/SettingsTabs/Gameplay/BattleFrame
@onready var bgm_player_a: AudioStreamPlayer = $HeroBGMManager/PlayerA
@onready var bgm_player_b: AudioStreamPlayer = $HeroBGMManager/PlayerB

@onready var demon_augment_panel: PanelContainer = $HUD/DemonAugmentPanel
@onready var demon_augment_title: Label = $HUD/DemonAugmentPanel/Margin/VBox/Title
@onready var demon_augment_trigger: Label = $HUD/DemonAugmentPanel/Margin/VBox/Trigger
@onready var demon_augment_guide: Label = $HUD/DemonAugmentPanel/Margin/VBox/Guide
@onready var demon_choice_0: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice0
@onready var demon_choice_1: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice1
@onready var demon_choice_2: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice2
@onready var demon_choice_icons: Array[TextureRect] = [
	$HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice0/Icon,
	$HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice1/Icon,
	$HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice2/Icon,
]
@onready var demon_reroll_button: Button = $HUD/DemonAugmentPanel/Margin/VBox/Actions/RerollButton
@onready var demon_confirm_button: Button = $HUD/DemonAugmentPanel/Margin/VBox/Actions/ConfirmButton
@onready var _demon_choice_buttons: Array[Button] = [demon_choice_0, demon_choice_1, demon_choice_2]

@onready var mutation_panel: PanelContainer = $HUD/MutationPanel
@onready var mutation_title: Label = $HUD/MutationPanel/Margin/VBox/Title
@onready var mutation_trigger: Label = $HUD/MutationPanel/Margin/VBox/Trigger
@onready var mutation_choice_0: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice0
@onready var mutation_choice_1: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice1
@onready var mutation_choice_2: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice2

@onready var result_panel: PanelContainer = $HUD/ResultPanel
@onready var result_title: Label = $HUD/ResultPanel/Margin/VBox/ResultTitle
@onready var result_reward: Label = $HUD/ResultPanel/Margin/VBox/ResultReward
@onready var result_message: Label = $HUD/ResultPanel/Margin/VBox/ResultMessage
@onready var result_analysis: Label = $HUD/ResultPanel/Margin/VBox/ResultAnalysisArea/ResultAnalysis
@onready var next_stage_button: Button = $HUD/ResultPanel/Margin/VBox/NextStageButton
@onready var stage_select_result_button: Button = $HUD/ResultPanel/Margin/VBox/ResultActions/StageSelectResultButton
@onready var restart_button: Button = $HUD/ResultPanel/Margin/VBox/ResultActions/RestartButton
var _result_reward_details := ""

var auto_placement: bool = true
var selected_monster_type: String = ""
var current_demon_candidates: Array = []
const DEMON_CHOICE_OPEN_GUARD_MS := 600
const DEMON_CHOICE_CONFIRM_GUARD_MS := 250
var _demon_choice_guard_until: int = 0
var _demon_confirm_guard_until: int = 0
var _demon_selected_index: int = -1
var _demon_rerolls_left: int = 0
var _pressed_choice_pointers: Dictionary = {}
var _blocked_choice_pointers: Dictionary = {}
var _blocked_confirm_pointers: Dictionary = {}
var _demon_choice_group := ButtonGroup.new()
var current_mutation_candidates: Array = []
var debug_refresh_timer: float = 0.0
var battle_loadout_ids: Array = []
var summon_slot_buttons: Array[Button] = []
var summon_slot_icons: Array[TextureRect] = []
var summon_slot_name_labels: Array[Label] = []
var summon_slot_cost_labels: Array[Label] = []
var monster_card_icon_cache: Dictionary = {}
var monster_mutation_icon_cache: Dictionary = {}
var demon_ultimate_charge_ready: bool = false
var demon_mana_current: float = 0.0
var demon_ultimate_cooldowns: Dictionary = {}
var demon_action_choice_active: bool = false
var demon_ultimate_ui_skills: Array[Dictionary] = []
var demon_ultimate_ui_buttons: Array[Button] = []
var demon_ultimate_ui_content: Array[Control] = []
var demon_ultimate_ui_cooldown_bars: Array[ProgressBar] = []
var demon_action_choice_context: String = ""
var demon_action_choice_ids: Array[String] = []
var demon_action_choice_actions: Array[Callable] = []
var demon_action_choice_buttons: Array[Button] = []
var monster_info_selected_index: int = 0
var monster_info_animating: bool = false
var hero_info_animating: bool = false
var hero_info_portrait_cache_path: String = ""
var hero_info_portrait_cache: Texture2D = null
var hero_skill_badges: Dictionary = {}
var hero_skill_hud_seen: Dictionary = {}
var hero_skill_hud_stale_ids: Array[String] = []
var hero_skill_hud_refresh_timer: float = 0.0
var _scene_load_path: String = ""
var _scene_load_pending: bool = false
var _stage_intro_active: bool = false
var _stage_intro_stage_id: String = ""
var _skill_unlock_cutscene_active: bool = false
var _touch_hold_frames: Array[Texture2D] = []
var _touch_hold_active: bool = false
var _touch_hold_elapsed: float = 0.0
var _touch_hold_frame_elapsed: float = 0.0
var _touch_hold_frame_index: int = 0
var _touch_hold_position: Vector2 = Vector2.ZERO
var _touch_pointer_id: int = -1
var camera_view_locked: bool = true
var battle_frame_enabled: bool = true
var gameplay_settings_path: String = GAMEPLAY_SETTINGS_PATH
var _camera_drag_active: bool = false
var _camera_drag_pointer_id: int = -1
var _camera_drag_distance: float = 0.0
var _pending_manual_spawn: bool = false
var _pending_manual_spawn_position: Vector2 = Vector2.ZERO
var _pending_manual_spawn_pointer_id: int = -1
var current_stage_hero_name: String = "용사"
var _battle_toast_timer: float = 0.0

func _ready() -> void:
	GameAudio.attach_battle(battle)
	_cache_demon_ultimate_ui_data()
	_ensure_demon_action_choice_capacity(5)
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	# Stage entry begins frozen and silent. The intro sequence owns the handoff
	# to gameplay so combat AI, cooldowns and the run timer cannot advance early.
	var entry_options := SceneTransition.consume_entry_options()
	_skip_entry_dialogue = (
		bool(entry_options.get("skip_stage_dialogue", false))
		and String(entry_options.get("stage_id", "")) == String(battle.current_stage_id)
	)
	battle.set_external_pause(true)
	_battle_stamina_entry = {} if battle.practice_mode else STAMINA.claim_battle_entry(String(battle.current_stage_id))
	hud_layer.visible = false
	stage_intro_cutscene.finished.connect(_on_stage_intro_finished)
	stage_intro_cutscene.dialogue_event.connect(
		_on_stage_intro_dialogue_event
	)
	hero_reveal_cutscene.finished.connect(_on_hero_reveal_finished)
	hero_reveal_cutscene.bgm_start_requested.connect(
		_on_hero_reveal_bgm_start_requested
	)
	skill_unlock_cutscene.finished.connect(_on_skill_unlock_cutscene_finished)
	get_viewport().size_changed.connect(_sync_skill_unlock_cutscene_frame)
	call_deferred("_sync_skill_unlock_cutscene_frame")
	call_deferred("_apply_battle_pixel_asset_frames")

	battle.stats_changed.connect(_on_stats_changed)
	battle.progression_changed.connect(_on_progression_changed)
	battle.hero_leveled_up.connect(_on_hero_leveled_up)
	battle.hero_augment_selected.connect(_on_hero_augment_selected)
	battle.conditional_skill_unlocked.connect(
		_on_conditional_skill_unlocked
	)
	battle.command_changed.connect(_on_command_changed)
	battle.population_changed.connect(_on_population_changed)
	battle.demon_progression_changed.connect(_on_demon_progression_changed)
	battle.summon_result.connect(_on_summon_result)
	practice_controls.install(self)
	transcendence_view.install(self)
	summon_cinematic.install(self)
	battle.demon_augment_ready.connect(_on_demon_augment_ready)
	battle.demon_augment_applied.connect(_on_demon_augment_applied)
	battle.demon_ultimate_changed.connect(_on_demon_ultimate_changed)
	battle.demon_ultimate_cooldowns_changed.connect(
		_on_demon_ultimate_cooldowns_changed
	)
	battle.demon_ultimate_used.connect(_on_demon_ultimate_used)
	battle.stage_event_triggered.connect(_on_stage_event_triggered)
	battle.mutation_choice_ready.connect(_on_mutation_choice_ready)
	battle.mutation_selected.connect(_on_mutation_selected)
	battle.mutation_spawn_result.connect(_on_mutation_spawn_result)
	battle.run_time_changed.connect(_on_run_time_changed)
	battle.battle_finished.connect(_on_battle_finished)

	stage_menu_button.pressed.connect(_on_stage_menu_pressed)
	monster_info_bookmark.pressed.connect(_toggle_monster_info)
	monster_info_close.pressed.connect(_close_monster_info)
	hero_info_bookmark.pressed.connect(_toggle_hero_info)
	hero_info_close.pressed.connect(_close_hero_info)
	for tab_index in range(monster_info_tabs.size()):
		monster_info_tabs[tab_index].pressed.connect(
			_on_monster_info_tab_pressed.bind(tab_index)
		)
	pause_resume_button.pressed.connect(_close_pause_menu)
	pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	pause_settings_button.pressed.connect(_open_settings_overlay)
	pause_lobby_button.pressed.connect(_on_lobby_pressed)

	settings_close_button.pressed.connect(_close_settings_overlay)
	if settings_tabs.get_tab_count() >= 2:
		settings_tabs.set_tab_title(0, "사운드")
		settings_tabs.set_tab_title(1, "게임플레이")
	settings_bgm_slider.value_changed.connect(_on_settings_bgm_level_changed)
	settings_sfx_slider.value_changed.connect(_on_settings_sfx_level_changed)
	settings_bgm_mute.toggled.connect(_on_settings_bgm_mute_toggled)
	settings_sfx_mute.toggled.connect(_on_settings_sfx_mute_toggled)
	settings_camera_lock.toggled.connect(_on_settings_camera_lock_toggled)
	settings_battle_frame.toggled.connect(_on_settings_battle_frame_toggled)
	_load_gameplay_settings()
	_sync_audio_settings_ui()
	_sync_gameplay_settings_ui()
	_apply_camera_view_mode()

	placement_toggle.toggled.connect(_on_placement_mode_toggled)

	summon_slot_buttons = [
		summon_slot_1,
		summon_slot_2,
		summon_slot_3,
	]
	summon_slot_icons = [
		summon_slot_icon_1,
		summon_slot_icon_2,
		summon_slot_icon_3,
	]
	summon_slot_name_labels = [
		summon_slot_name_1,
		summon_slot_name_2,
		summon_slot_name_3,
	]
	summon_slot_cost_labels = [
		summon_slot_cost_1,
		summon_slot_cost_2,
		summon_slot_cost_3,
	]
	_load_battle_loadout()
	_configure_battle_loadout_buttons()
	demon_choice_0.pressed.connect(_on_demon_choice_pressed.bind(0))
	demon_choice_1.pressed.connect(_on_demon_choice_pressed.bind(1))
	demon_choice_2.pressed.connect(_on_demon_choice_pressed.bind(2))
	demon_reroll_button.pressed.connect(_on_demon_reroll_pressed)
	demon_confirm_button.pressed.connect(_on_demon_confirm_pressed)
	mutation_choice_0.pressed.connect(_on_mutation_choice_pressed.bind(0))
	mutation_choice_1.pressed.connect(_on_mutation_choice_pressed.bind(1))
	mutation_choice_2.pressed.connect(_on_mutation_choice_pressed.bind(2))
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	stage_select_result_button.pressed.connect(_on_lobby_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	var snapshot: Dictionary = battle.get_snapshot()
	_apply_stage_snapshot(snapshot)

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
	_on_demon_progression_changed(
		int(snapshot.get("demon_level", 1)),
		float(snapshot.get("demon_exp", 0.0)),
		float(snapshot.get("demon_exp_to_next", 30.0))
	)
	_on_demon_ultimate_changed(
		float(snapshot.get("demon_ultimate_charge", 0.0)),
		float(snapshot.get("demon_ultimate_max", 100.0)),
		bool(snapshot.get("demon_ultimate_ready", false))
	)
	_on_demon_ultimate_cooldowns_changed(
		Dictionary(snapshot.get("demon_ultimate_cooldowns", {}))
	)
	_on_run_time_changed(
		float(snapshot.get("run_elapsed_seconds", 0.0)),
		float(snapshot.get("run_remaining_seconds", 0.0))
	)

	build_label.text = ""
	debug_balance_label.text = String(snapshot.get("debug_balance_summary", "[DEBUG]"))
	placement_toggle.button_pressed = true
	_on_placement_mode_toggled(true)
	call_deferred("_begin_prepared_stage_entry", snapshot)

	print("Again, Hero? stage/camera prototype loaded.")
	print("Finite world camera + persistent stage progression enabled.")

var _presentation_ready := false
var _skip_entry_dialogue := false


func prepare_presentation() -> void:
	if _presentation_ready:
		return
	await PresentationWarmup.prepare_common()
	await PresentationWarmup.prepare_scene("res://src/main/Main.tscn")
	await _warm_touch_hold_frames()
	await battle.prepare_spawn_resources()
	var snapshot: Dictionary = battle.get_snapshot()
	var reveal := HERO_REVEAL_CATALOG.get_reveal_data(
		String(snapshot.get("hero_id", "")), "", String(snapshot.get("hero_portrait_path", ""))
	)
	await hero_reveal_cutscene.warm_render_resources(String(reveal.get("portrait_path", "")))
	_presentation_ready = true


func _begin_prepared_stage_entry(snapshot: Dictionary) -> void:
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.is_transitioning():
		await transition.transition_completed
	else:
		# Running Main directly from the editor must also prepare the frames.
		await prepare_presentation()
	if is_inside_tree():
		_begin_stage_entry(snapshot)


func _apply_battle_pixel_asset_frames() -> void:
	# Use the original split PNG assets as tiled frame pieces.
	# Long edges tile instead of stretching, so corner pixel art keeps its shape.
	_replace_top_right_texture_frame(
		$HUD/TopBar/StageFrame,
		0.36
	)
	_replace_top_right_texture_frame(
		$HUD/TopBar/TimerFrame,
		0.28
	)
	_replace_texture_frame(
		$HUD/TopBar/HeroStatusFrame,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.50,
		BATTLE_PIXEL_CENTER_LARGE,
		28
	)
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_split_frame(
		hero_hud_portrait,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.28
	)
	for bar in [
		hero_hp_bar,
		exp_bar,
		demon_ultimate_bar,
		command_bar,
	]:
		BATTLE_PIXEL_FRAME_ASSEMBLER.apply_progress_background(
			bar,
			BATTLE_PIXEL_BAR_BACKGROUND,
			18.0,
			7.0
		)
	BATTLE_PIXEL_FRAME_ASSEMBLER.apply_progress_background(
		demon_exp_bar,
		BATTLE_PIXEL_BAR_BACKGROUND,
		12.0,
		4.0
	)
	_replace_button_frame(
		stage_menu_button,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		BATTLE_PIXEL_CENTER_DARK,
		18
	)
	_replace_texture_frame(
		$HUD/TopBar/MonsterFrame,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		BATTLE_PIXEL_CENTER_DARK,
		18
	)
	_replace_button_frame(
		monster_info_bookmark,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		BATTLE_PIXEL_CENTER_DARK,
		18
	)
	_replace_button_frame(
		hero_info_bookmark,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		BATTLE_PIXEL_CENTER_DARK,
		18
	)
	_replace_texture_frame_clean(
		$HUD/DemonUltimatePanel/Frame,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.34
	)
	_replace_texture_frame_clean(
		$HUD/BottomBar/AutoFrame,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.28
	)

	for button in [
		summon_slot_1,
		summon_slot_2,
		summon_slot_3,
	]:
		_replace_button_frame(
			button,
			BATTLE_PIXEL_FRAME_MEDIUM_DIR,
			0.44,
			BATTLE_PIXEL_CENTER_DARK,
			20
		)

	# Large modal windows use the original split PNG frame too.
	# Their internal MarginContainer nodes already provide safe content padding,
	# so the old SVG panel skin can be removed without changing layout semantics.
	_replace_panel_frame(
		$HUD/PauseMenu/MenuPanel,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.52
	)
	_replace_panel_frame(
		$HUD/SettingsOverlay/Panel,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.52
	)
	_replace_panel_frame(
		demon_augment_panel,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.52
	)
	_replace_panel_frame(
		mutation_panel,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.48
	)
	_replace_panel_frame(
		result_panel,
		BATTLE_PIXEL_FRAME_LARGE_DIR,
		0.52
	)
	_replace_panel_frame(
		monster_info_panel,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		0.0,
		4.0
	)
	_replace_panel_frame(
		hero_info_panel,
		BATTLE_PIXEL_FRAME_MEDIUM_DIR,
		0.34,
		0.0,
		4.0
	)
	# Keep existing split-art outer frames; theme the remaining plain inner boxes.
	PIXEL_PANEL_SKIN.apply_tree(hud_layer)
	PIXEL_PANEL_SKIN.apply_tree(stage_intro_cutscene)
	# Hero reveal has dedicated illustrated architecture; do not stack the
	# generic modal frame over its clean title/loading presentation.
	PIXEL_PANEL_SKIN.apply_tree(skill_unlock_cutscene)
	preload("res://src/ui/castle_battle_chrome.gd").rebuild(self)


func _replace_texture_frame(
	target: TextureRect,
	frame_dir: String,
	scale: float,
	center_texture_path: String,
	center_patch_margin: int
) -> void:
	if target == null:
		return
	target.texture = null
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_split_frame(
		target,
		frame_dir,
		scale,
		center_texture_path,
		center_patch_margin
	)


func _replace_top_right_texture_frame(
	target: TextureRect,
	scale: float
) -> void:
	if target == null:
		return
	target.texture = null
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_top_right_split_frame(
		target,
		BATTLE_PIXEL_FRAME_TOP_RIGHT_DIR,
		scale,
		Color(0.035, 0.032, 0.075, 0.98)
	)


func _replace_texture_frame_clean(
	target: TextureRect,
	frame_dir: String,
	scale: float
) -> void:
	if target == null:
		return
	target.texture = null
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_split_frame(
		target,
		frame_dir,
		scale,
		"",
		0,
		Color(0.035, 0.032, 0.075, 0.98)
	)


func _replace_button_frame(
	button: Button,
	frame_dir: String,
	scale: float,
	center_texture_path: String,
	center_patch_margin: int
) -> void:
	if button == null:
		return
	BATTLE_PIXEL_FRAME_ASSEMBLER.clear_button_style(button)
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_split_frame(
		button,
		frame_dir,
		scale,
		center_texture_path,
		center_patch_margin
	)
	button.button_down.connect(_on_pixel_asset_button_down.bind(button))
	button.button_up.connect(_on_pixel_asset_button_up.bind(button))


func _replace_panel_frame(
	panel: PanelContainer,
	frame_dir: String,
	scale: float,
	content_margin: float = 0.0,
	background_inset: float = 0.0
) -> void:
	if panel == null:
		return
	var clean_background := Color(0.035, 0.032, 0.075, 0.98)
	var uses_inset_background := background_inset > 0.0
	var panel_background := clean_background
	var overlay_background := Color(0.0, 0.0, 0.0, 0.0)
	if uses_inset_background:
		panel_background = Color(0.0, 0.0, 0.0, 0.0)
		overlay_background = clean_background
	BATTLE_PIXEL_FRAME_ASSEMBLER.clear_panel_style(panel)
	BATTLE_PIXEL_FRAME_ASSEMBLER.apply_clean_panel_background(
		panel,
		panel_background,
		content_margin
	)
	BATTLE_PIXEL_FRAME_ASSEMBLER.add_split_frame(
		panel,
		frame_dir,
		scale,
		"",
		0,
		overlay_background,
		background_inset
	)


func _on_pixel_asset_button_down(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var frame := button.get_node_or_null("PixelAssetFrame") as CanvasItem
	if frame != null:
		frame.modulate = Color(1.0, 0.68, 0.34, 1.0)


func _on_pixel_asset_button_up(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return
	var frame := button.get_node_or_null("PixelAssetFrame") as CanvasItem
	if frame != null:
		frame.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _process(delta: float) -> void:
	_mobile_scroll_router.step(delta)
	_update_demon_choice_guard()
	_update_touch_hold_feedback(delta)
	if _battle_toast_timer > 0.0:
		_battle_toast_timer = maxf(_battle_toast_timer - delta, 0.0)
		if _battle_toast_timer <= 0.0:
			battle_toast.hide()

	if _scene_load_pending:
		var load_status := ResourceLoader.load_threaded_get_status(_scene_load_path)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed = ResourceLoader.load_threaded_get(_scene_load_path)
			_scene_load_pending = false
			_lobby_exit_pending = false
			if packed is PackedScene:
				get_tree().change_scene_to_packed(packed)
				return
			status_label.text = "화면 전환에 실패했습니다."
			if is_instance_valid(battle):
				battle.set_external_pause(false)
		elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
			_scene_load_pending = false
			_lobby_exit_pending = false
			status_label.text = "화면 전환에 실패했습니다."
			if is_instance_valid(battle):
				battle.set_external_pause(false)
		elif load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_scene_load_pending = false
			_lobby_exit_pending = false
			status_label.text = "화면 전환에 실패했습니다."
			if is_instance_valid(battle):
				battle.set_external_pause(false)

	if _should_refresh_hero_skill_cooldown_hud():
		hero_skill_hud_refresh_timer -= delta
		if hero_skill_hud_refresh_timer <= 0.0:
			hero_skill_hud_refresh_timer = 0.05
			_refresh_hero_skill_cooldown_hud()
	else:
		hero_skill_hud_refresh_timer = 0.0

	debug_refresh_timer -= delta
	if debug_refresh_timer <= 0.0:
		debug_refresh_timer = 0.25
		if (
			is_instance_valid(debug_balance_label)
			and debug_balance_label.is_visible_in_tree()
			and is_instance_valid(battle)
			and battle.has_method("get_debug_balance_summary")
		):
			debug_balance_label.text = String(
				battle.call("get_debug_balance_summary")
			)

func _apply_stage_snapshot(snapshot: Dictionary) -> void:
	current_stage_hero_name = String(snapshot.get("hero_name", "용사"))
	stage_number_label.text = "Stage %d" % int(
		snapshot.get("stage_number", 1)
	)
	subtitle_label.text = String(
		snapshot.get("stage_name", "첫 번째 침입자")
	)
	stage_hero_name_label.text = current_stage_hero_name
	var portrait_path := String(snapshot.get("hero_portrait_path", ""))
	if portrait_path.is_empty():
		portrait_path = HERO_PORTRAIT_REFERENCE_PATH
	hero_hud_portrait.texture = _load_normalized_hero_portrait(portrait_path)


func _begin_stage_entry(snapshot: Dictionary) -> void:
	if battle.practice_mode:
		_start_battle_after_intro(String(battle.current_stage_id))
		return
	var stage_id := String(snapshot.get("stage_id", ""))
	if _skip_entry_dialogue:
		_skip_entry_dialogue = false
		_begin_hero_reveal(snapshot)
		return
	var dialogue := STAGE_INTRO_DIALOGUES.get_dialogue(stage_id)
	if stage_id in ["stage_1", "stage_5"] and not dialogue.is_empty():
		var hero_id := String(snapshot.get("hero_id", ""))
		var reveal_data := HERO_REVEAL_CATALOG.get_reveal_data(
			hero_id,
			String(snapshot.get("hero_name", "용사")),
			String(snapshot.get("hero_portrait_path", ""))
		)
		var identity_id := String(reveal_data.get("identity_id", hero_id))
		var true_name := String(reveal_data.get("true_name", "")).strip_edges()
		if (
			not true_name.is_empty()
			and STAGE_PROGRESS.is_hero_true_name_unlocked(stage_id, identity_id)
		):
			dialogue["hero_name"] = true_name
	if dialogue.is_empty():
		_begin_hero_reveal(snapshot)
		return

	_stage_intro_active = true
	_stage_intro_stage_id = stage_id
	hud_layer.visible = false

	# Dialogue can always be skipped, including the first encounter.
	stage_intro_cutscene.call("play_dialogue", dialogue)


func _on_stage_intro_dialogue_event(
	event_id: String,
	payload: Dictionary
) -> void:
	if event_id != "reveal_hero_true_name":
		return
	var identity_id := String(payload.get("identity_id", ""))
	var true_name := String(payload.get("true_name", "")).strip_edges()
	if identity_id.is_empty() or true_name.is_empty():
		return
	STAGE_PROGRESS.reveal_hero_true_name(identity_id)


func _on_stage_intro_finished(skipped: bool) -> void:
	if not _stage_intro_active:
		return

	if not _stage_intro_stage_id.is_empty():
		STAGE_PROGRESS.mark_stage_intro_seen(_stage_intro_stage_id)

	if skipped:
		# Let the SKIP button release finish on the hidden dialogue layer
		# before showing the reveal, so the same input cannot jump past it.
		call_deferred("_begin_hero_reveal_after_dialogue_skip")
		return

	_begin_hero_reveal(battle.get_snapshot())


func _begin_hero_reveal_after_dialogue_skip() -> void:
	if not _stage_intro_active:
		return
	_begin_hero_reveal(battle.get_snapshot())


func _begin_hero_reveal(snapshot: Dictionary) -> void:
	var stage_id := String(snapshot.get("stage_id", ""))
	var hero_id := String(snapshot.get("hero_id", ""))
	var reveal_data := HERO_REVEAL_CATALOG.get_reveal_data(
		hero_id,
		String(snapshot.get("hero_name", "용사")),
		String(snapshot.get("hero_portrait_path", ""))
	)
	reveal_data["stage_id"] = stage_id

	var identity_id := String(reveal_data.get("identity_id", hero_id))
	STAGE_PROGRESS.record_hero_encounter(
		stage_id,
		identity_id
	)
	reveal_data["true_name_unlocked"] = (
		STAGE_PROGRESS.is_hero_true_name_unlocked(
			stage_id,
			identity_id
		)
	)

	_stage_intro_active = true
	_stage_intro_stage_id = stage_id
	hud_layer.visible = false
	hero_reveal_cutscene.call("play_reveal", reveal_data)


func _on_hero_reveal_bgm_start_requested(stage_id: String) -> void:
	hero_bgm_manager.start_stage(stage_id)
	_force_apply_bgm_players(AudioSettings.bgm_level, AudioSettings.bgm_muted)


func _on_hero_reveal_finished() -> void:
	var stage_id := _stage_intro_stage_id
	_stage_intro_stage_id = ""
	_start_battle_after_intro(stage_id)


func _start_battle_after_intro(_stage_id: String) -> void:
	if _battle_started_ms < 0:
		battle.hero.center_camera_on_hero()
		_battle_started_ms = Time.get_ticks_msec()
		_battle_started_unix = Time.get_unix_time_from_system()
	_stage_intro_active = false
	hud_layer.visible = true
	battle.set_external_pause(false)
	TutorialFlow.battle_started(self)


func _sync_skill_unlock_cutscene_frame() -> void:
	if (
		not is_instance_valid(skill_unlock_cutscene)
		or not is_instance_valid(battle_viewport_container)
	):
		return
	if skill_unlock_cutscene.has_method("configure_battle_frame"):
		skill_unlock_cutscene.call(
			"configure_battle_frame",
			battle_viewport_container.get_global_rect()
		)


func _on_conditional_skill_unlocked(
	_skill_id: String,
	_skill_name: String,
	payload: Dictionary
) -> void:
	if _skill_unlock_cutscene_active:
		return
	if String(payload.get("cutscene_texture_path", "")).is_empty():
		return

	_skill_unlock_cutscene_active = true
	battle.set_external_pause(true)
	_sync_skill_unlock_cutscene_frame()
	skill_unlock_cutscene.call("play_unlock", payload)


func _on_skill_unlock_cutscene_finished() -> void:
	if not _skill_unlock_cutscene_active:
		return
	_skill_unlock_cutscene_active = false
	if is_instance_valid(battle) and not bool(battle.get("battle_over")):
		battle.set_external_pause(false)


func _handle_camera_pan_input(event: InputEvent) -> bool:
	if camera_view_locked or _camera_pan_blocked():
		return false

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _can_use_battle_pointer(touch.position):
				_begin_camera_drag(touch.index)
		elif touch.index == _camera_drag_pointer_id:
			_end_camera_drag()
		return false

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _camera_drag_active and drag.index == _camera_drag_pointer_id:
			_pan_camera_by_screen_delta(drag.relative)
			_end_touch_hold()
			get_viewport().set_input_as_handled()
			return true
		return false

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mouse.pressed:
			if _can_use_battle_pointer(mouse.position):
				_begin_camera_drag(-2)
		elif _camera_drag_pointer_id == -2:
			_end_camera_drag()
		return false

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (
			_camera_drag_active
			and _camera_drag_pointer_id == -2
			and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		):
			_pan_camera_by_screen_delta(motion.relative)
			_end_touch_hold()
			get_viewport().set_input_as_handled()
			return true

	return false


func _input(event: InputEvent) -> void:
	if TutorialFlow.blocks_input(event):
		return
	if TutorialFlow.modal_visible:
		return
	if _mobile_scroll_router.handle_input(event, self):
		_end_camera_drag()
		_end_touch_hold()
		_clear_pending_manual_spawn()
		get_viewport().set_input_as_handled()
		return
	if _guard_demon_choice_pointer(event):
		get_viewport().set_input_as_handled()
		return
	var camera_pan_consumed := _handle_camera_pan_input(event)
	_update_touch_hold_input(event)
	_finish_camera_drag_on_release(event)
	if camera_pan_consumed:
		return
	if _stage_intro_active or _skill_unlock_cutscene_active:
		return

	if event.is_action_pressed("ui_cancel"):
		if settings_overlay.visible:
			_close_settings_overlay()
		elif monster_info_panel.visible:
			_close_monster_info()
		elif hero_info_panel.visible:
			_close_hero_info()
		elif pause_menu.visible:
			_close_pause_menu()
		elif not demon_augment_panel.visible and not result_panel.visible:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	var detail_pointer := Vector2.ZERO
	var detail_pressed := false
	if event is InputEventScreenTouch:
		var detail_touch := event as InputEventScreenTouch
		detail_pressed = detail_touch.pressed
		detail_pointer = detail_touch.position
	elif event is InputEventMouseButton:
		var detail_mouse := event as InputEventMouseButton
		detail_pressed = (
			detail_mouse.pressed
			and detail_mouse.button_index == MOUSE_BUTTON_LEFT
		)
		detail_pointer = detail_mouse.position

	if detail_pressed:
		if (
			monster_info_panel.visible
			and not monster_info_panel.get_global_rect().has_point(
				detail_pointer
			)
		):
			_close_monster_info()
			get_viewport().set_input_as_handled()
			return
		if (
			hero_info_panel.visible
			and not hero_info_panel.get_global_rect().has_point(
				detail_pointer
			)
		):
			_close_hero_info()
			get_viewport().set_input_as_handled()
			return

	if (
		result_panel.visible
		or pause_menu.visible
		or settings_overlay.visible
		or demon_augment_panel.visible
		or mutation_panel.visible
		or auto_placement
		or selected_monster_type.is_empty()
	):
		return

	var pointer_position := Vector2.ZERO
	var is_pressed := false
	var is_released := false
	var pointer_id := -1

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		is_pressed = touch_event.pressed
		is_released = not touch_event.pressed
		pointer_position = touch_event.position
		pointer_id = touch_event.index
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		is_pressed = mouse_event.pressed
		is_released = not mouse_event.pressed
		pointer_position = mouse_event.position
		pointer_id = -2
	else:
		return

	if not camera_view_locked and is_released:
		if (
			_pending_manual_spawn
			and _pending_manual_spawn_pointer_id == pointer_id
		):
			if _camera_drag_distance < CAMERA_DRAG_THRESHOLD:
				_try_manual_spawn_at_screen_position(
					_pending_manual_spawn_position
				)
			_clear_pending_manual_spawn()
			get_viewport().set_input_as_handled()
		return

	if not is_pressed or not _can_use_battle_pointer(pointer_position):
		return

	if not camera_view_locked:
		_pending_manual_spawn = true
		_pending_manual_spawn_position = pointer_position
		_pending_manual_spawn_pointer_id = pointer_id
		return

	_try_manual_spawn_at_screen_position(pointer_position)


func _try_manual_spawn_at_screen_position(pointer_position: Vector2) -> void:
	var viewport_rect: Rect2 = battle_viewport_container.get_global_rect()
	if not viewport_rect.has_point(pointer_position):
		return

	var local_pointer := pointer_position - viewport_rect.position
	var viewport_size := Vector2(battle_viewport.size)
	var scale_factor := Vector2(
		viewport_size.x / maxf(viewport_rect.size.x, 1.0),
		viewport_size.y / maxf(viewport_rect.size.y, 1.0)
	)
	var subviewport_pointer := local_pointer * scale_factor
	var canvas_inverse := battle_viewport.get_canvas_transform().affine_inverse()
	var world_position: Vector2 = canvas_inverse * subviewport_pointer
	var battle_position: Vector2 = battle.to_local(world_position)
	var placement_error := String(
		battle.get_manual_spawn_error(
			selected_monster_type,
			battle_position
		)
	)

	if not placement_error.is_empty():
		if battle.is_manual_spawn_too_close_to_hero(battle_position):
			battle.show_manual_spawn_restricted_area()

		FLOATING_TEXT.show_text_at(
			battle,
			battle.to_global(battle_position),
			placement_error
		)
		get_viewport().set_input_as_handled()
		return

	battle.try_summon_at_position(selected_monster_type, battle_position)
	get_viewport().set_input_as_handled()


func _camera_pan_blocked() -> bool:
	return (
		_stage_intro_active
		or summon_cinematic.active
		or _skill_unlock_cutscene_active
		or result_panel.visible
		or pause_menu.visible
		or settings_overlay.visible
		or demon_augment_panel.visible
		or mutation_panel.visible
		or monster_info_panel.visible
		or hero_info_panel.visible
	)


func _can_use_battle_pointer(pointer_position: Vector2) -> bool:
	if not battle_viewport_container.get_global_rect().has_point(pointer_position):
		return false
	return not _is_pointer_over_battle_ui(pointer_position)


func _is_pointer_over_battle_ui(pointer_position: Vector2) -> bool:
	if is_instance_valid(transcendence_view.button) and transcendence_view.button.is_visible_in_tree() and transcendence_view.button.get_global_rect().has_point(pointer_position):
		return true
	if is_instance_valid(transcendence_view.unlock_button) and transcendence_view.unlock_button.is_visible_in_tree() and transcendence_view.unlock_button.get_global_rect().has_point(pointer_position):
		return true
	# Detail panels must win the initial touch before locked-camera manual
	# placement can consume it in _input(). Otherwise ScrollContainer misses
	# the press and only begins scrolling after a long hold/secondary drag.
	if (
		monster_info_panel.visible
		and monster_info_panel.get_global_rect().has_point(pointer_position)
	):
		return true
	if (
		hero_info_panel.visible
		and hero_info_panel.get_global_rect().has_point(pointer_position)
	):
		return true
	if (
		demon_ultimate_panel.visible
		and demon_ultimate_panel.get_global_rect().has_point(pointer_position)
	):
		return true
	if (
		hero_skill_cooldown_bar.visible
		and hero_skill_cooldown_bar.get_global_rect().has_point(pointer_position)
	):
		return true
	if (
		monster_info_bookmark.visible
		and monster_info_bookmark.get_global_rect().has_point(pointer_position)
	):
		return true
	if (
		hero_info_bookmark.visible
		and hero_info_bookmark.get_global_rect().has_point(pointer_position)
	):
		return true
	return false


func _begin_camera_drag(pointer_id: int) -> void:
	if _camera_drag_active:
		return
	_camera_drag_active = true
	_camera_drag_pointer_id = pointer_id
	_camera_drag_distance = 0.0


func _finish_camera_drag_on_release(event: InputEvent) -> void:
	if not _camera_drag_active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and touch.index == _camera_drag_pointer_id:
			_end_camera_drag()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if (
			mouse.button_index == MOUSE_BUTTON_LEFT
			and not mouse.pressed
			and _camera_drag_pointer_id == -2
		):
			_end_camera_drag()


func _end_camera_drag() -> void:
	_camera_drag_active = false
	_camera_drag_pointer_id = -1


func _clear_pending_manual_spawn() -> void:
	_pending_manual_spawn = false
	_pending_manual_spawn_position = Vector2.ZERO
	_pending_manual_spawn_pointer_id = -1


func _pan_camera_by_screen_delta(screen_delta: Vector2) -> void:
	if screen_delta.length_squared() <= 0.001:
		return

	_camera_drag_distance += screen_delta.length()
	var viewport_rect := battle_viewport_container.get_global_rect()
	var viewport_size := Vector2(battle_viewport.size)
	var battle_delta := Vector2(
		screen_delta.x * viewport_size.x / maxf(viewport_rect.size.x, 1.0),
		screen_delta.y * viewport_size.y / maxf(viewport_rect.size.y, 1.0)
	)
	var hero_node = battle.get("hero")
	if (
		is_instance_valid(hero_node)
		and hero_node.has_method("pan_camera_by_screen_delta")
	):
		hero_node.call("pan_camera_by_screen_delta", battle_delta)


func _warm_touch_hold_frames() -> void:
	if not _touch_hold_frames.is_empty():
		return
	_touch_hold_frames.clear()
	var slice_start := Time.get_ticks_usec()
	for index in range(1, TOUCH_HOLD_FRAME_COUNT + 1):
		if not is_inside_tree():
			return
		var texture := _load_ui_texture(
			"%s/gage_%02d.png" % [TOUCH_HOLD_FRAME_DIR, index]
		)
		if texture != null:
			_touch_hold_frames.append(texture)
		if Time.get_ticks_usec() - slice_start >= PresentationWarmup.MAIN_THREAD_BUDGET_US:
			await get_tree().process_frame
			slice_start = Time.get_ticks_usec()


func _update_touch_hold_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# _input() runs before Control._gui_input(). Never start the global
			# hold indicator when the touch began on an interactive battle HUD.
			if _is_pointer_over_battle_ui(touch.position):
				_end_touch_hold()
				return
			if (
				not camera_view_locked
				and _can_use_battle_pointer(touch.position)
			):
				_end_touch_hold()
				return
			if _touch_pointer_id < 0:
				_touch_pointer_id = touch.index
				_begin_touch_hold(touch.position)
		elif touch.index == _touch_pointer_id:
			_end_touch_hold()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			not camera_view_locked
			and _camera_drag_active
			and drag.index == _camera_drag_pointer_id
		):
			_end_touch_hold()
		elif drag.index == _touch_pointer_id:
			_touch_hold_position = drag.position
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		# Desktop fallback for testing; real touch takes priority.
		if _touch_pointer_id >= 0:
			return
		if mouse.pressed:
			if _is_pointer_over_battle_ui(mouse.position):
				_end_touch_hold()
				return
			if (
				not camera_view_locked
				and _can_use_battle_pointer(mouse.position)
			):
				_end_touch_hold()
				return
			_begin_touch_hold(mouse.position)
		else:
			_end_touch_hold()
	elif event is InputEventMouseMotion:
		if (
			not camera_view_locked
			and _camera_drag_active
			and _camera_drag_pointer_id == -2
		):
			_end_touch_hold()
		elif _touch_hold_active and _touch_pointer_id < 0:
			_touch_hold_position = (event as InputEventMouseMotion).position


func _begin_touch_hold(position: Vector2) -> void:
	_touch_hold_active = true
	_touch_hold_elapsed = 0.0
	_touch_hold_frame_elapsed = 0.0
	_touch_hold_frame_index = 0
	_touch_hold_position = position
	touch_hold_indicator.visible = false


func _end_touch_hold() -> void:
	_touch_hold_active = false
	_touch_hold_elapsed = 0.0
	_touch_hold_frame_elapsed = 0.0
	_touch_hold_frame_index = 0
	_touch_pointer_id = -1
	touch_hold_indicator.visible = false


func _update_touch_hold_feedback(delta: float) -> void:
	if not _touch_hold_active or _touch_hold_frames.is_empty():
		touch_hold_indicator.visible = false
		return
	if _stage_intro_active:
		touch_hold_indicator.visible = false
		return

	_touch_hold_elapsed += delta
	if _touch_hold_elapsed < TOUCH_HOLD_DELAY:
		touch_hold_indicator.visible = false
		return

	touch_hold_indicator.visible = true
	touch_hold_indicator.position = _touch_hold_position - touch_hold_indicator.size * 0.5
	touch_hold_indicator.texture = _touch_hold_frames[_touch_hold_frame_index]
	_touch_hold_frame_elapsed += delta
	if _touch_hold_frame_elapsed >= TOUCH_HOLD_FRAME_SECONDS:
		_touch_hold_frame_elapsed = fmod(
			_touch_hold_frame_elapsed,
			TOUCH_HOLD_FRAME_SECONDS
		)
		_touch_hold_frame_index = (
			_touch_hold_frame_index + 1
		) % _touch_hold_frames.size()


func _on_stage_menu_pressed() -> void:
	if demon_augment_panel.visible or result_panel.visible:
		return

	if pause_menu.visible:
		_close_pause_menu()
	else:
		_open_pause_menu()

func _open_pause_menu() -> void:
	if demon_augment_panel.visible or result_panel.visible:
		return

	var snapshot: Dictionary = battle.get_snapshot()
	pause_stage_label.text = "Stage %d · %s\n상대: %s" % [
		int(snapshot.get("stage_number", 1)),
		String(snapshot.get("stage_name", "스테이지")),
		String(snapshot.get("hero_name", "용사")),
	]
	pause_time_label.text = "남은 시간 %s" % _format_run_time(
		float(snapshot.get("run_remaining_seconds", 0.0))
	)

	battle.set_external_pause(true)
	pause_menu.show()

func _close_pause_menu() -> void:
	if not pause_menu.visible:
		return

	settings_overlay.hide()
	pause_menu.hide()
	if not result_panel.visible:
		battle.set_external_pause(false)
	if TutorialFlow.active() and TutorialFlow.coach != null:
		TutorialFlow.coach.show_next()


func _open_settings_overlay() -> void:
	_sync_audio_settings_ui()
	_sync_gameplay_settings_ui()
	settings_overlay.show()
	settings_overlay.move_to_front()


func _close_settings_overlay() -> void:
	settings_overlay.hide()


func _sync_audio_settings_ui() -> void:
	settings_bgm_slider.set_value_no_signal(float(AudioSettings.bgm_level))
	settings_sfx_slider.set_value_no_signal(float(AudioSettings.sfx_level))
	settings_bgm_mute.set_pressed_no_signal(AudioSettings.bgm_muted)
	settings_sfx_mute.set_pressed_no_signal(AudioSettings.sfx_muted)
	settings_bgm_value.text = str(AudioSettings.bgm_level)
	settings_sfx_value.text = str(AudioSettings.sfx_level)


func _load_gameplay_settings() -> void:
	var config := ConfigFile.new()
	if config.load(gameplay_settings_path) != OK:
		camera_view_locked = true
		battle_frame_enabled = true
		return
	camera_view_locked = bool(
		config.get_value("gameplay", "camera_view_locked", true)
	)
	battle_frame_enabled = bool(config.get_value("gameplay", "battle_frame_enabled", true))


func _save_gameplay_settings() -> void:
	var config := ConfigFile.new()
	config.load(gameplay_settings_path)
	config.set_value("gameplay", "camera_view_locked", camera_view_locked)
	config.set_value("gameplay", "battle_frame_enabled", battle_frame_enabled)
	config.save(gameplay_settings_path)


func _sync_gameplay_settings_ui() -> void:
	settings_camera_lock.set_pressed_no_signal(camera_view_locked)
	settings_battle_frame.set_pressed_no_signal(battle_frame_enabled)
	preload("res://src/ui/castle_battle_chrome.gd").apply_visibility(self, battle_frame_enabled)

func _on_settings_battle_frame_toggled(enabled: bool) -> void:
	battle_frame_enabled = enabled
	_clear_pending_manual_spawn()
	_end_camera_drag()
	preload("res://src/ui/castle_battle_chrome.gd").apply_visibility(self, enabled)
	_save_gameplay_settings()


func _on_settings_camera_lock_toggled(enabled: bool) -> void:
	camera_view_locked = enabled
	_clear_pending_manual_spawn()
	_end_camera_drag()
	_save_gameplay_settings()
	_apply_camera_view_mode()


func _apply_camera_view_mode() -> void:
	var hero_node = battle.get("hero")
	if (
		is_instance_valid(hero_node)
		and hero_node.has_method("set_camera_view_locked")
	):
		hero_node.call("set_camera_view_locked", camera_view_locked)


func _on_settings_bgm_level_changed(value: float) -> void:
	var level := int(round(value))
	settings_bgm_value.text = str(level)

	# Apply to the actual output path before persisting the setting.
	_force_apply_bgm_players(level, settings_bgm_mute.button_pressed)
	if hero_bgm_manager.has_method("set_user_bgm_level"):
		hero_bgm_manager.set_user_bgm_level(level)

	AudioSettings.set_bgm_level(level)


func _force_apply_bgm_players(level: int, muted: bool) -> void:
	AudioSettings.apply_bgm_level_to_bus(level, muted)

	for player in [bgm_player_a, bgm_player_b]:
		if not is_instance_valid(player):
			continue
		player.stream_paused = muted
		if muted:
			player.volume_db = -80.0
		elif player.playing:
			player.volume_db = 0.0


func _on_settings_sfx_level_changed(value: float) -> void:
	var level := int(round(value))
	settings_sfx_value.text = str(level)
	AudioSettings.set_sfx_level(level)


func _on_settings_bgm_mute_toggled(enabled: bool) -> void:
	# Same ordering as volume: touch the real players before persistence/signals.
	_force_apply_bgm_players(int(round(settings_bgm_slider.value)), enabled)
	if hero_bgm_manager.has_method("set_user_bgm_muted"):
		hero_bgm_manager.set_user_bgm_muted(enabled)

	AudioSettings.set_bgm_muted(enabled)


func _on_settings_sfx_mute_toggled(enabled: bool) -> void:
	AudioSettings.set_sfx_muted(enabled)


func _on_pause_restart_pressed() -> void:
	_restart_with_stamina(String(battle.current_stage_id), true)

func _on_stage_event_triggered(
	event_type: String,
	event_name: String,
	message: String
) -> void:
	status_label.text = message
	if event_type == "boss":
		run_timer_label.text = "BOSS · %s" % event_name

func _on_mutation_choice_ready(
	event_data: Dictionary,
	candidates: Array
) -> void:
	current_mutation_candidates = candidates.duplicate()
	mutation_panel.show()
	for slot_index in range(summon_slot_buttons.size()):
		summon_slot_buttons[slot_index].disabled = true
		_apply_summon_slot_availability(
			slot_index,
			true,
			false
		)

	mutation_title.text = String(
		event_data.get("ui_title", "돌연변이 선택")
	)
	mutation_trigger.text = String(
		event_data.get(
			"ui_description",
			"편성 몬스터 1종을 돌연변이로 투입합니다."
		)
	)

	var buttons: Array[Button] = [
		mutation_choice_0,
		mutation_choice_1,
		mutation_choice_2,
	]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index >= current_mutation_candidates.size():
			button.hide()
			continue

		button.show()
		var monster_id := String(current_mutation_candidates[index])
		button.text = ""

		var icon: TextureRect = button.get_node("Icon") as TextureRect
		var name_label: Label = button.get_node("Name") as Label
		var select_label: Label = button.get_node("Select") as Label
		icon.texture = _load_monster_mutation_icon(monster_id)
		name_label.text = _get_catalog_monster_name(monster_id)
		select_label.text = "선택"

	status_label.text = String(event_data.get("status_message", "Stage 이벤트: 돌연변이로 투입할 편성 몬스터를 선택하세요."))

func _on_mutation_choice_pressed(index: int) -> void:
	if index < 0 or index >= current_mutation_candidates.size():
		return

	var monster_id := String(current_mutation_candidates[index])
	mutation_panel.hide()
	current_mutation_candidates.clear()

	if battle.has_method("get_command_hud_state"):
		var command_state: Vector2 = battle.call("get_command_hud_state")
		_on_command_changed(command_state.x, command_state.y)

	battle.spawn_selected_mutation(monster_id)

func _on_mutation_spawn_result(
	success: bool,
	message: String
) -> void:
	if not success:
		status_label.text = message
		return
	status_label.text = message

func _on_mutation_selected(
	event_type: String,
	mutation_name: String
) -> void:
	if event_type == "miniboss":
		status_label.text = "%s 출현!" % mutation_name
	else:
		status_label.text = "%s 출현!" % mutation_name

func _on_run_time_changed(_elapsed_seconds: float, remaining_seconds: float) -> void:
	run_timer_label.text = "연습전투 · 제한 없음" if battle.practice_mode else "남은 시간 %s" % _format_run_time(remaining_seconds)

func _format_run_time(seconds: float) -> String:
	var total := maxi(int(ceil(seconds)), 0)
	var minutes := int(total / 60)
	var remaining := total % 60
	return "%02d:%02d" % [minutes, remaining]

func _on_stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int) -> void:
	hero_hp_bar.max_value = maxf(float(hero_max_hp), 1.0)
	hero_hp_bar.value = float(hero_hp)
	hero_hp_label.text = "HP ∞ · 연습 더미" if battle.practice_mode else "HP %d / %d" % [hero_hp, hero_max_hp]
	_update_population_label()
	monsters_label.tooltip_text = "전체 몬스터 %d · 증강/기술 추가 소환은 인구수 제외" % monsters_left
	hero_bgm_manager.update_hero_hp(hero_hp, hero_max_hp)
	if hero_info_panel.visible:
		_refresh_hero_info_panel()

func _on_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	hero_level_label.text = "Lv. %d   %s" % [level, current_stage_hero_name]
	exp_label.text = "EXP %d / %d" % [current_exp, exp_to_next_level]
	exp_bar.max_value = maxf(float(exp_to_next_level), 1.0)
	exp_bar.value = float(current_exp)
	if hero_info_panel.visible:
		_refresh_hero_info_panel()

func _on_demon_progression_changed(level: int, current_exp: float, exp_to_next_level: float) -> void:
	demon_level_label.text = "마왕 Lv.%d" % level
	demon_progress_label.text = "EXP %.1f / %.1f" % [
		current_exp,
		exp_to_next_level,
	]
	demon_exp_bar.max_value = maxf(exp_to_next_level, 1.0)
	demon_exp_bar.value = current_exp

	if monster_info_panel.visible:
		_refresh_monster_info_panel()

func _on_population_changed(_count: int, _capacity: int) -> void:
	_update_population_label()
	for index in range(mini(summon_slot_buttons.size(), battle_loadout_ids.size())):
		var cost: float = battle.get_monster_cost(String(battle_loadout_ids[index]))
		var cost_blocked: bool = battle.command_power + 0.001 < cost
		var blocked: bool = mutation_panel.visible or battle.is_population_full() or cost_blocked
		summon_slot_buttons[index].disabled = blocked
		_apply_summon_slot_availability(index, blocked, cost_blocked)

func _update_population_label() -> void:
	monsters_label.text = "인구 %d / %d" % [battle.get_population_count(), battle.get_population_limit()]

func _on_command_changed(current_value: float, max_value: float) -> void:
	_update_population_label()
	command_label.text = "지휘력 %d / %d" % [int(round(current_value)), int(round(max_value))]
	command_bar.max_value = maxf(max_value, 1.0)
	command_bar.value = current_value

	for slot_index in range(summon_slot_buttons.size()):
		var button := summon_slot_buttons[slot_index]
		if slot_index >= battle_loadout_ids.size():
			button.hide()
			button.disabled = true
			if slot_index < summon_slot_icons.size():
				summon_slot_icons[slot_index].texture = null
			continue

		var monster_id := String(battle_loadout_ids[slot_index])
		var cost: float = battle.get_monster_cost(monster_id)
		button.show()
		if slot_index < summon_slot_icons.size():
			summon_slot_icons[slot_index].texture = _load_monster_card_icon(
				monster_id
			)
		if slot_index < summon_slot_name_labels.size():
			summon_slot_name_labels[slot_index].text = (
				_get_catalog_monster_name(monster_id)
			)
		if slot_index < summon_slot_cost_labels.size():
			summon_slot_cost_labels[slot_index].text = "코스트 %.1f" % cost
		var cannot_summon: bool = (
			mutation_panel.visible
			or battle.is_population_full()
			or current_value + 0.001 < cost
		)
		button.disabled = cannot_summon
		_apply_summon_slot_availability(
			slot_index,
			cannot_summon,
			current_value + 0.001 < cost
		)

func _apply_summon_slot_availability(
	slot_index: int,
	disabled: bool,
	cost_blocked: bool
) -> void:
	if slot_index < 0 or slot_index >= summon_slot_buttons.size():
		return

	var button: Button = summon_slot_buttons[slot_index]
	button.modulate = (
		Color(0.43, 0.43, 0.49, 0.82)
		if disabled
		else Color(1, 1, 1, 1)
	)

	if slot_index < summon_slot_cost_labels.size():
		var cost_label: Label = summon_slot_cost_labels[slot_index]
		cost_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.56, 0.56, 1.0)
			if cost_blocked
			else Color(0.95, 0.9, 0.98, 1.0)
		)


func _load_battle_loadout() -> void:
	var valid_ids: Array = []
	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			if MONSTER_CATALOG.get_rarity(monster_id) != "transcendent":
				valid_ids.append(monster_id)

	var fallback_ids: Array = []
	for monster_id in valid_ids:
		fallback_ids.append(monster_id)
		if fallback_ids.size() >= TEAM_LOADOUT_STORE.MAX_SLOTS:
			break

	battle_loadout_ids = TEAM_LOADOUT_STORE.load_ids(
		valid_ids,
		fallback_ids
	)

	if battle.has_method("set_allowed_monster_ids"):
		battle.call("set_allowed_monster_ids", battle_loadout_ids)

func _configure_battle_loadout_buttons() -> void:
	for slot_index in range(summon_slot_buttons.size()):
		var button := summon_slot_buttons[slot_index]
		if slot_index >= battle_loadout_ids.size():
			button.hide()
			button.disabled = true
			continue

		var monster_id := String(battle_loadout_ids[slot_index])
		button.show()
		if slot_index < summon_slot_icons.size():
			summon_slot_icons[slot_index].texture = _load_monster_card_icon(
				monster_id
			)
		if slot_index < summon_slot_name_labels.size():
			summon_slot_name_labels[slot_index].text = (
				_get_catalog_monster_name(monster_id)
			)
		if slot_index < summon_slot_cost_labels.size():
			var catalog_data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
			var base_cost := 0.0
			if typeof(catalog_data) == TYPE_DICTIONARY:
				base_cost = float(catalog_data.get("base_cost", 0.0))
			summon_slot_cost_labels[slot_index].text = "코스트 %.1f" % base_cost
		button.pressed.connect(
			_on_summon_slot_pressed.bind(slot_index)
		)

func _toggle_monster_info() -> void:
	if monster_info_panel.visible:
		_close_monster_info()
	else:
		_open_monster_info()

func _open_monster_info() -> void:
	if monster_info_animating:
		return
	_hide_hero_info_immediate()
	if battle_loadout_ids.is_empty():
		return

	monster_info_selected_index = clampi(
		monster_info_selected_index,
		0,
		battle_loadout_ids.size() - 1
	)
	_refresh_monster_info_panel()
	monster_info_bookmark.hide()
	monster_info_panel.show()

	var target_position := monster_info_panel.position
	monster_info_panel.position = target_position + Vector2(500.0, 0.0)
	monster_info_animating = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		monster_info_panel,
		"position",
		target_position,
		0.22
	)
	tween.finished.connect(
		func() -> void:
			monster_info_animating = false
	)

func _close_monster_info() -> void:
	if not monster_info_panel.visible or monster_info_animating:
		return

	monster_info_animating = true
	var target_position := monster_info_panel.position + Vector2(500.0, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		monster_info_panel,
		"position",
		target_position,
		0.18
	)
	tween.finished.connect(
		func() -> void:
			monster_info_panel.hide()
			monster_info_panel.position -= Vector2(500.0, 0.0)
			monster_info_bookmark.show()
			monster_info_animating = false
	)

func _toggle_hero_info() -> void:
	if hero_info_panel.visible:
		_close_hero_info()
	else:
		_open_hero_info()

func _open_hero_info() -> void:
	if hero_info_animating:
		return
	_hide_monster_info_immediate()
	_refresh_hero_info_panel()
	hero_info_bookmark.hide()
	hero_info_panel.show()

	var target_position := hero_info_panel.position
	hero_info_panel.position = target_position + Vector2(500.0, 0.0)
	hero_info_animating = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		hero_info_panel,
		"position",
		target_position,
		0.22
	)
	tween.finished.connect(
		func() -> void:
			hero_info_animating = false
	)

func _close_hero_info() -> void:
	if not hero_info_panel.visible or hero_info_animating:
		return

	hero_info_animating = true
	var target_position := hero_info_panel.position + Vector2(500.0, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		hero_info_panel,
		"position",
		target_position,
		0.18
	)
	tween.finished.connect(
		func() -> void:
			hero_info_panel.hide()
			hero_info_panel.position -= Vector2(500.0, 0.0)
			hero_info_bookmark.show()
			hero_info_animating = false
	)

func _hide_hero_info_immediate() -> void:
	if hero_info_panel.visible:
		hero_info_panel.hide()
	hero_info_bookmark.show()
	hero_info_animating = false

func _hide_monster_info_immediate() -> void:
	if monster_info_panel.visible:
		monster_info_panel.hide()
	monster_info_bookmark.show()
	monster_info_animating = false

func _should_refresh_hero_skill_cooldown_hud() -> bool:
	if not is_instance_valid(hud_layer) or not hud_layer.visible:
		return false
	if _skill_unlock_cutscene_active:
		return false
	if (
		pause_menu.visible
		or demon_augment_panel.visible
		or mutation_panel.visible
		or result_panel.visible
	):
		return false
	return true


func _refresh_hero_skill_cooldown_hud() -> void:
	if not is_instance_valid(hero_skill_cooldown_bar):
		return
	if not is_instance_valid(battle):
		hero_skill_cooldown_bar.hide()
		return

	var raw_skills: Array = []
	if battle.has_method("get_hero_skill_cooldown_hud"):
		var raw_skill_state = battle.call(
			"get_hero_skill_cooldown_hud"
		)
		if raw_skill_state is Array:
			raw_skills = raw_skill_state
	elif battle.has_method("get_snapshot"):
		var snapshot: Dictionary = battle.get_snapshot()
		var fallback_skills = snapshot.get(
			"hero_skill_cooldowns",
			[]
		)
		if fallback_skills is Array:
			raw_skills = fallback_skills
	else:
		hero_skill_cooldown_bar.hide()
		return

	var was_visible := hero_skill_cooldown_bar.visible
	hero_skill_hud_seen.clear()
	for raw_skill in raw_skills:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill: Dictionary = raw_skill
		var skill_id := String(skill.get("id", ""))
		if skill_id.is_empty():
			continue
		hero_skill_hud_seen[skill_id] = true

		var badge: Control = hero_skill_badges.get(skill_id)
		if not is_instance_valid(badge):
			badge = HERO_SKILL_COOLDOWN_BADGE.new()
			hero_skill_badges[skill_id] = badge
			hero_skill_cooldown_bar.add_child(badge)
			badge.call("configure", skill)
		else:
			badge.call("update_state", skill)

	hero_skill_hud_stale_ids.clear()
	for raw_id in hero_skill_badges:
		var skill_id := String(raw_id)
		if hero_skill_hud_seen.has(skill_id):
			continue
		hero_skill_hud_stale_ids.append(skill_id)

	for skill_id in hero_skill_hud_stale_ids:
		var stale_badge = hero_skill_badges.get(skill_id)
		if is_instance_valid(stale_badge):
			stale_badge.queue_free()
		hero_skill_badges.erase(skill_id)

	var has_skills := not hero_skill_hud_seen.is_empty()
	hero_skill_cooldown_bar.visible = has_skills
	if has_skills and not was_visible:
		hero_skill_cooldown_bar.z_index = 120
		hero_skill_cooldown_bar.move_to_front()


func _refresh_hero_info_panel() -> void:
	if battle == null:
		return

	var snapshot: Dictionary = {}
	if battle.has_method("get_hero_info_hud"):
		var raw_hero_info = battle.call("get_hero_info_hud")
		if typeof(raw_hero_info) == TYPE_DICTIONARY:
			snapshot = raw_hero_info
	if snapshot.is_empty() and battle.has_method("get_snapshot"):
		snapshot = battle.get_snapshot()
	if snapshot.is_empty():
		return
	var hero_name := String(snapshot.get("hero_name", "용사"))
	var hero_archetype := String(
		snapshot.get("hero_archetype", "")
	)

	hero_info_name.text = "%s · Lv.%d" % [
		hero_name,
		int(snapshot.get("hero_level", 1)),
	]
	hero_info_portrait.texture = _load_normalized_hero_portrait(
		String(snapshot.get("hero_portrait_path", ""))
	)

	var stat_lines: PackedStringArray = []
	stat_lines.append(
		"HP  %d / %d" % [
			int(snapshot.get("hero_hp", 0)),
			int(snapshot.get("hero_max_hp", 0)),
		]
	)
	stat_lines.append(
		"공격력  %d" % int(snapshot.get("hero_attack_damage", 0))
	)
	stat_lines.append(
		"이동속도  %.0f" % float(snapshot.get("hero_move_speed", 0.0))
	)
	stat_lines.append(
		"공격 간격  %.2f초"
		% float(snapshot.get("hero_attack_cooldown", 0.0))
	)
	stat_lines.append(
		"공격 사거리  %.0f"
		% float(snapshot.get("hero_attack_range", 0.0))
	)
	hero_info_stats.text = "\n".join(stat_lines)

	var ability_lines: PackedStringArray = []
	if hero_archetype == "rogue_combo":
		ability_lines.append("3단 찌르기 · 약진/넉백 연계")
		ability_lines.append(
			"난도질 쉴드  최대 HP %.0f%%"
			% (
				float(snapshot.get("hero_slash_shield_ratio", 0.0))
				* 100.0
			)
		)
		ability_lines.append(
			"피흡  실제 피해의 %.0f%%"
			% (
				float(snapshot.get("hero_lifesteal_ratio", 0.0))
				* 100.0
			)
		)
		ability_lines.append(
			"급습-암살 처형선  일반 몬스터 HP %.0f%%"
			% (
				float(snapshot.get("hero_execute_ratio", 0.0))
				* 100.0
			)
		)
	else:
		ability_lines.append(
			"원거리 투사체 속도  %.0f"
			% float(snapshot.get("hero_projectile_speed", 0.0))
		)
		ability_lines.append("거리 유지형 전투 AI")
	hero_info_abilities.text = "\n".join(ability_lines)

	var build_counts: Dictionary = Dictionary(
		snapshot.get("hero_build_counts", {})
	)
	var build_lines: PackedStringArray = []
	for raw_id in build_counts.keys():
		var augment_id := String(raw_id)
		var stacks := int(build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue
		var augment := HERO_AUGMENTS.get_augment(augment_id)
		var augment_name := String(augment.get("name", augment_id))
		var catalog_max := int(augment.get("max_stack", 0))
		var effective_max := HERO_AUGMENTS.get_effective_max_stack(
			augment_id,
			hero_archetype,
			catalog_max
		)
		if effective_max > 0 and stacks >= effective_max:
			build_lines.append(
				"[color=#F6C945]%s · MAX[/color]" % augment_name
			)
		else:
			build_lines.append("%s x%d" % [augment_name, stacks])
	hero_info_build.text = (
		"아직 선택한 용사 증강 없음"
		if build_lines.is_empty()
		else "\n".join(build_lines)
	)

	hero_info_ai.text = "%s\n%s" % [
		String(snapshot.get("hero_ai_observation", "AI 관측 정보 없음")),
		String(snapshot.get("hero_recent_offense", "최근 공세 기록 없음")),
	]

func _load_normalized_hero_portrait(path: String) -> Texture2D:
	if (
		not path.is_empty()
		and path == hero_info_portrait_cache_path
		and hero_info_portrait_cache != null
	):
		return hero_info_portrait_cache

	var source := _load_ui_texture(path)
	if source == null:
		return null
	var reference := _load_ui_texture(
		HERO_PORTRAIT_REFERENCE_PATH
	)
	if reference == null:
		hero_info_portrait_cache_path = path
		hero_info_portrait_cache = source
		return source

	var source_image := source.get_image()
	var reference_image := reference.get_image()
	if (
		source_image == null
		or source_image.is_empty()
		or reference_image == null
		or reference_image.is_empty()
	):
		hero_info_portrait_cache_path = path
		hero_info_portrait_cache = source
		return source

	var source_rect := _get_visible_alpha_rect(source_image)
	var reference_rect := _get_visible_alpha_rect(reference_image)
	if source_rect.size.y <= 0 or reference_rect.size.y <= 0:
		hero_info_portrait_cache_path = path
		hero_info_portrait_cache = source
		return source

	var cropped := source_image.get_region(source_rect)
	var scale_ratio := (
		float(reference_rect.size.y)
		/ float(maxi(source_rect.size.y, 1))
	)
	var target_width := maxi(
		1,
		int(round(float(source_rect.size.x) * scale_ratio))
	)
	var target_height := reference_rect.size.y
	cropped.resize(
		target_width,
		target_height,
		Image.INTERPOLATE_NEAREST
	)

	var canvas := Image.create(
		reference_image.get_width(),
		reference_image.get_height(),
		false,
		Image.FORMAT_RGBA8
	)
	canvas.fill(Color(0, 0, 0, 0))
	var center := Vector2i(
		reference_rect.position.x + reference_rect.size.x / 2,
		reference_rect.position.y + reference_rect.size.y / 2
	)
	var paste := Vector2i(
		center.x - target_width / 2,
		center.y - target_height / 2
	)
	canvas.blit_rect(
		cropped,
		Rect2i(Vector2i.ZERO, cropped.get_size()),
		paste
	)
	var normalized := ImageTexture.create_from_image(canvas)
	hero_info_portrait_cache_path = path
	hero_info_portrait_cache = normalized
	return normalized

func _get_visible_alpha_rect(
	image: Image,
	_alpha_threshold: float = 0.05
) -> Rect2i:
	# Hero portraits are nearest-neighbor pixel art with binary transparency.
	# Run the alpha-bounds scan in the engine instead of GDScript per pixel.
	return image.get_used_rect()

func _load_ui_texture(path: String) -> Texture2D:
	var cached := PresentationWarmup.get_texture(path)
	if cached != null:
		return cached
	if path.is_empty():
		return null
	# Prefer Godot's imported/resource cache. Raw PNG decoding is kept only
	# as a fallback for unimported development assets.
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null

func _on_monster_info_tab_pressed(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= battle_loadout_ids.size():
		return
	monster_info_selected_index = tab_index
	_refresh_monster_info_panel()

func _refresh_monster_info_panel() -> void:
	for index in range(monster_info_tabs.size()):
		var tab := monster_info_tabs[index]
		if index >= battle_loadout_ids.size():
			tab.hide()
			continue

		tab.show()
		var tab_monster_id := String(battle_loadout_ids[index])
		tab.text = _get_catalog_monster_name(tab_monster_id)
		tab.disabled = index == monster_info_selected_index

	if (
		monster_info_selected_index < 0
		or monster_info_selected_index >= battle_loadout_ids.size()
	):
		return

	var monster_id := String(
		battle_loadout_ids[monster_info_selected_index]
	)
	var detail := _build_monster_info_direct(monster_id)

	monster_info_name.text = String(
		detail.get("name", _get_catalog_monster_name(monster_id))
	)
	monster_info_portrait.texture = _load_monster_info_icon(monster_id)

	var stat_lines: PackedStringArray = []
	stat_lines.append(
		"현재 스탯 · 마왕 Lv.%d"
		% int(detail.get("demon_level", 1))
	)
	stat_lines.append(
		"생산비용  %.1f" % float(detail.get("cost", 0.0))
	)
	stat_lines.append(
		"마왕 EXP  %.1f" % float(detail.get("summon_exp", 0.0))
	)

	if detail.has("max_hp"):
		stat_lines.append("최대 HP  %d" % int(detail["max_hp"]))
	if detail.has("attack_damage"):
		stat_lines.append("공격력  %d" % int(detail["attack_damage"]))
	if detail.has("explosion_damage"):
		stat_lines.append("자폭 피해  %d" % int(detail["explosion_damage"]))
	if detail.has("move_speed"):
		stat_lines.append("이동속도  %.0f" % float(detail["move_speed"]))
	if detail.has("attack_cooldown"):
		stat_lines.append(
			"공격 간격  %.2f초" % float(detail["attack_cooldown"])
		)
	if detail.has("self_destruct_fuse"):
		stat_lines.append(
			"자폭 준비  %.2f초" % float(detail["self_destruct_fuse"])
		)
	if detail.has("explosion_radius"):
		stat_lines.append(
			"폭발 반경  %.0f" % float(detail["explosion_radius"])
		)

	monster_info_stats.text = "\n".join(stat_lines)

	var normal_lines: PackedStringArray = []
	for raw_entry in detail.get("normal_augments", []):
		var entry: Dictionary = raw_entry
		var augment_name := String(entry.get("name", "일반증강"))
		var prefix := "%s " % _get_catalog_monster_name(monster_id)
		if augment_name.begins_with(prefix):
			augment_name = augment_name.trim_prefix(prefix)
		normal_lines.append(
			"%s Lv.%d" % [
				augment_name,
				int(entry.get("level", 0)),
			]
		)
	monster_info_normal.text = (
		"아직 획득한 몬스터 일반증강 없음"
		if normal_lines.is_empty()
		else "\n".join(normal_lines)
	)

	var special_lines: PackedStringArray = []
	for raw_entry in detail.get("special_augments", []):
		var entry: Dictionary = raw_entry
		special_lines.append(
			"★ %s" % String(entry.get("name", "특수증강"))
		)
	monster_info_special.text = (
		"아직 획득한 특수증강 없음"
		if special_lines.is_empty()
		else "\n".join(special_lines)
	)

func _build_monster_info_direct(monster_id: String) -> Dictionary:
	if (
		is_instance_valid(battle)
		and battle.has_method("get_monster_run_detail")
	):
		var runtime_detail = battle.call(
			"get_monster_run_detail",
			monster_id
		)
		if (
			typeof(runtime_detail) == TYPE_DICTIONARY
			and not Dictionary(runtime_detail).is_empty()
		):
			return Dictionary(runtime_detail).duplicate(true)

	var catalog_entry = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(catalog_entry) != TYPE_DICTIONARY:
		return {
			"name": _get_catalog_monster_name(monster_id),
			"cost": 0.0,
			"summon_exp": 0.0,
			"demon_level": 1,
			"normal_augments": [],
			"special_augments": [],
		}

	var base_stats = catalog_entry.get("base_stats", {})
	if typeof(base_stats) != TYPE_DICTIONARY:
		base_stats = {}

	var detail := {
		"name": String(catalog_entry.get("name", monster_id)),
		"cost": float(catalog_entry.get("base_cost", 0.0)),
		"summon_exp": float(catalog_entry.get("summon_exp", 0.0)),
		"demon_level": 1,
		"normal_augments": [],
		"special_augments": [],
	}

	var global_hp := 1.0
	var global_damage := 1.0
	var global_speed := 1.0
	var global_attack_speed := 1.0
	var level_hp := 1.0
	var level_damage := 1.0
	var level_speed := 1.0

	if is_instance_valid(battle):
		detail["demon_level"] = int(battle.get("demon_level"))
		detail["cost"] = battle.get_monster_cost(monster_id)

		var value = battle.get("monster_hp_multiplier")
		if value != null:
			global_hp = float(value)

		value = battle.get("monster_damage_multiplier")
		if value != null:
			global_damage = float(value)

		value = battle.get("monster_speed_multiplier")
		if value != null:
			global_speed = float(value)

		value = battle.get("monster_attack_speed_multiplier")
		if value != null:
			global_attack_speed = float(value)

		if battle.has_method("_get_demon_level_monster_hp_multiplier"):
			level_hp = float(
				battle.call("_get_demon_level_monster_hp_multiplier")
			)
		if battle.has_method(
			"_get_demon_level_monster_damage_multiplier"
		):
			level_damage = float(
				battle.call(
					"_get_demon_level_monster_damage_multiplier"
				)
			)
		if battle.has_method(
			"_get_demon_level_monster_speed_multiplier"
		):
			level_speed = float(
				battle.call(
					"_get_demon_level_monster_speed_multiplier"
				)
			)

	var hp_aug := _get_battle_monster_multiplier(monster_id, "hp")
	var damage_aug := _get_battle_monster_multiplier(
		monster_id,
		"damage"
	)
	var speed_aug := _get_battle_monster_multiplier(monster_id, "speed")
	var cooldown_aug := _get_battle_monster_multiplier(
		monster_id,
		"attack_cooldown"
	)

	if base_stats.has("max_hp"):
		detail["max_hp"] = maxi(
			1,
			int(round(
				float(base_stats["max_hp"])
				* global_hp
				* hp_aug
				* level_hp
			))
		)

	if base_stats.has("attack_damage"):
		detail["attack_damage"] = maxi(
			1,
			int(round(
				float(base_stats["attack_damage"])
				* global_damage
				* damage_aug
				* level_damage
			))
		)

	if base_stats.has("move_speed"):
		detail["move_speed"] = (
			float(base_stats["move_speed"])
			* global_speed
			* speed_aug
			* level_speed
		)

	if base_stats.has("attack_cooldown"):
		detail["attack_cooldown"] = maxf(
			0.10,
			float(base_stats["attack_cooldown"])
			* global_attack_speed
			* cooldown_aug
		)

	if base_stats.has("explosion_damage"):
		detail["explosion_damage"] = maxi(
			1,
			int(round(
				float(base_stats["explosion_damage"])
				* global_damage
				* damage_aug
				* level_damage
			))
		)

	if base_stats.has("explosion_radius"):
		detail["explosion_radius"] = float(
			base_stats["explosion_radius"]
		)

	if base_stats.has("self_destruct_fuse"):
		detail["self_destruct_fuse"] = maxf(
			0.10,
			float(base_stats["self_destruct_fuse"])
			* global_attack_speed
		)

	if is_instance_valid(battle):
		var build_counts = battle.get("demon_build_counts")
		if typeof(build_counts) == TYPE_DICTIONARY:
			for raw_augment in DEMON_AUGMENTS.get_monster_normal_augments(
				monster_id,
				String(catalog_entry.get("name", monster_id))
			):
				var augment: Dictionary = raw_augment
				var augment_id := String(augment.get("id", ""))
				var augment_level := int(
					build_counts.get(augment_id, 0)
				)
				if augment_level <= 0:
					continue
				detail["normal_augments"].append({
					"name": String(
						augment.get("name", augment_id)
					),
					"level": augment_level,
				})

		var special_ids = battle.get("demon_special_augments")
		if typeof(special_ids) == TYPE_ARRAY:
			for raw_id in special_ids:
				var augment_id := String(raw_id)
				var augment := DEMON_AUGMENTS.get_augment(augment_id)
				if String(augment.get("monster_id", "")) != monster_id:
					continue
				detail["special_augments"].append({
					"id": augment_id,
					"name": String(
						augment.get("name", augment_id)
					),
				})

	return detail

func _get_battle_monster_multiplier(
	monster_id: String,
	stat_name: String
) -> float:
	if (
		not is_instance_valid(battle)
		or not battle.has_method("_get_monster_augment_multiplier")
	):
		return 1.0

	return float(
		battle.call(
			"_get_monster_augment_multiplier",
			monster_id,
			stat_name
		)
	)

func _load_monster_card_icon(monster_id: String) -> Texture2D:
	if monster_card_icon_cache.has(monster_id):
		return monster_card_icon_cache.get(monster_id) as Texture2D

	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return null

	var path := String(data.get("card_icon_path", ""))
	var texture := _load_ui_texture(path)
	if texture == null:
		return null

	var display_texture: Texture2D = texture
	var image := texture.get_image()
	if image != null and not image.is_empty():
		var used_rect := image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				used_rect.position,
				used_rect.size
			)
			display_texture = atlas

	monster_card_icon_cache[monster_id] = display_texture
	return display_texture


func _load_monster_mutation_icon(monster_id: String) -> Texture2D:
	if monster_mutation_icon_cache.has(monster_id):
		return monster_mutation_icon_cache.get(monster_id) as Texture2D

	var profile := MONSTER_CATALOG.get_elite_visual_profile(monster_id)
	if profile.is_empty():
		return _load_monster_card_icon(monster_id)

	var asset_dir := String(profile.get("asset_dir", ""))
	var animations = profile.get("animations", {})
	if asset_dir.is_empty() or typeof(animations) != TYPE_DICTIONARY:
		return _load_monster_card_icon(monster_id)

	var idle_data = animations.get("idle", {})
	if typeof(idle_data) != TYPE_DICTIONARY:
		return _load_monster_card_icon(monster_id)

	var idle: Dictionary = idle_data
	var path := ""
	match String(profile.get("mode", "")):
		"frames":
			var prefix := String(idle.get("prefix", "idle"))
			path = "%s/%s_01.png" % [asset_dir, prefix]
		"sequence":
			var start_frame := maxi(int(idle.get("start", 1)), 1)
			path = "%s/frame_%02d.png" % [asset_dir, start_frame]
		_:
			return _load_monster_card_icon(monster_id)

	var texture := _load_ui_texture(path)
	if texture == null:
		return _load_monster_card_icon(monster_id)

	var display_texture: Texture2D = texture
	var image := texture.get_image()
	if image != null and not image.is_empty():
		var used_rect := image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				used_rect.position,
				used_rect.size
			)
			display_texture = atlas

	monster_mutation_icon_cache[monster_id] = display_texture
	return display_texture


func _load_monster_info_icon(monster_id: String) -> Texture2D:
	return _load_monster_card_icon(monster_id)

func _on_summon_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= battle_loadout_ids.size():
		return
	if slot_index < summon_slot_buttons.size():
		_flash_button_feedback(summon_slot_buttons[slot_index])

	var monster_id := String(battle_loadout_ids[slot_index])
	_on_summon_pressed(monster_id)

func _get_catalog_monster_name(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return monster_id
	return String(data.get("name", monster_id))

func _is_monster_equipped(monster_id: String) -> bool:
	return monster_id in battle_loadout_ids

func _set_default_battle_status() -> void:
	if auto_placement:
		placement_toggle.text = "자동 배치"
		status_label.text = "용사 주변 반경에 소환"
	elif selected_monster_type.is_empty():
		placement_toggle.text = "수동 배치"
		status_label.text = "카드 선택 후 전장을 터치"
	else:
		placement_toggle.text = "수동 배치"
		status_label.text = "%s 선택됨 · 전장을 터치" % _get_monster_name(selected_monster_type)


func _show_battle_toast(message: String, duration: float = 1.4) -> void:
	if message.is_empty():
		return
	battle_toast.text = message
	battle_toast.show()
	_battle_toast_timer = maxf(duration, 0.2)


func _flash_button_feedback(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return

	var feedback_target: CanvasItem = button
	var pixel_frame := button.get_node_or_null("PixelAssetFrame") as CanvasItem
	if pixel_frame != null:
		feedback_target = pixel_frame

	feedback_target.modulate = Color(1.0, 0.72, 0.42, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(
		feedback_target,
		"modulate",
		Color(1.0, 1.0, 1.0, 1.0),
		0.16
	)


func _on_placement_mode_toggled(auto_enabled: bool) -> void:
	auto_placement = auto_enabled
	_set_default_battle_status()

func _on_summon_pressed(monster_type: String) -> void:
	if mutation_panel.visible:
		status_label.text = "돌연변이 선택 중에는 몬스터를 소환할 수 없습니다."
		return

	if not _is_monster_equipped(monster_type):
		status_label.text = "%s은(는) 현재 팀에 편성되지 않았습니다." % _get_catalog_monster_name(monster_type)
		return

	if auto_placement:
		battle.try_summon(monster_type)
		return

	selected_monster_type = monster_type
	status_label.text = "수동 배치: %s 선택됨 · 현재 보이는 전장을 터치해 연속 배치하세요." % _get_monster_name(monster_type)

func _on_summon_result(_monster_type: String, success: bool, message: String) -> void:
	_show_battle_toast(message, 1.2 if success else 1.8)
	_set_default_battle_status()

func _on_demon_ultimate_changed(
	current_value: float,
	max_value: float,
	ready: bool
) -> void:
	demon_ultimate_charge_ready = ready
	demon_mana_current = current_value
	demon_ultimate_bar.max_value = maxf(max_value, 1.0)
	demon_ultimate_bar.value = current_value
	if not demon_action_choice_active:
		demon_ultimate_label.text = "필살기   %d / %d" % [
			int(round(current_value)),
			int(round(max_value)),
		]
	_refresh_demon_ultimate_buttons()

func _cache_demon_ultimate_ui_data() -> void:
	demon_ultimate_ui_skills.clear()
	demon_ultimate_ui_buttons.clear()
	demon_ultimate_ui_cooldown_bars.clear()

	demon_ultimate_ui_buttons.append(demon_ultimate_1)
	demon_ultimate_ui_buttons.append(demon_ultimate_2)
	demon_ultimate_ui_buttons.append(demon_ultimate_3)
	demon_ultimate_ui_cooldown_bars.append(demon_ultimate_1_cooldown)
	demon_ultimate_ui_cooldown_bars.append(demon_ultimate_2_cooldown)
	demon_ultimate_ui_cooldown_bars.append(demon_ultimate_3_cooldown)

	var valid_skill_ids: Array = DEMON_ULTIMATES.get_ordered_ids()
	var selected_skill_ids := DEMON_SKILL_LOADOUT_STORE.load_ids(
		valid_skill_ids,
		valid_skill_ids
	)
	for raw_id in selected_skill_ids:
		var skill_id := String(raw_id)
		var skill := DEMON_ULTIMATES.get_skill(skill_id)
		if skill.is_empty():
			skill = {"id": skill_id}
		demon_ultimate_ui_skills.append(skill)

	for index in demon_ultimate_ui_buttons.size():
		var button := demon_ultimate_ui_buttons[index]
		var active := index < demon_ultimate_ui_skills.size()
		button.visible = active
		if not active:
			continue
		var skill_id := String(
			demon_ultimate_ui_skills[index].get("id", "")
		)
		button.icon = null
		button.text = ""
		var content := preload("res://src/ui/demon_skill_button_content.gd").new()
		content.name = "SkillContent"
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.configure(SKILL_ART.texture("demon","demon",skill_id),"%d %s" % [index+1,String(demon_ultimate_ui_skills[index].get("name","마력 기술"))])
		demon_ultimate_ui_content.append(content)
		button.pressed.connect(
			_on_demon_ultimate_pressed.bind(skill_id)
		)


func _ensure_demon_action_choice_capacity(required_count: int) -> void:
	while demon_action_choice_buttons.size() < maxi(required_count, 0):
		var button_index := demon_action_choice_buttons.size()
		var button := Button.new()
		button.name = "Choice%d" % (button_index + 1)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_color_override(
			"font_color",
			Color(0.96, 0.91, 1.0, 1.0)
		)
		button.add_theme_color_override(
			"font_pressed_color",
			Color(1.0, 0.88, 0.4, 1.0)
		)
		button.add_theme_color_override(
			"font_disabled_color",
			Color(0.48, 0.45, 0.54, 0.9)
		)
		for style_name in ["normal", "hover", "pressed", "disabled"]:
			var style_box := demon_ultimate_1.get_theme_stylebox(style_name)
			if style_box != null:
				button.add_theme_stylebox_override(style_name, style_box)
		button.pressed.connect(
			_on_demon_action_choice_button_pressed.bind(button_index)
		)
		demon_action_choice_grid.add_child(button)
		button.hide()
		demon_action_choice_buttons.append(button)


func _show_demon_action_choices(
	title: String,
	context: String,
	choices: Array
) -> void:
	var choice_count := choices.size()
	if choice_count <= 0:
		return

	_ensure_demon_action_choice_capacity(choice_count)
	demon_action_choice_active = true
	demon_action_choice_context = context
	demon_action_choice_ids.clear()
	demon_action_choice_actions.clear()

	var column_count := choice_count
	if choice_count > 5:
		column_count = ceili(float(choice_count) / 2.0)
	demon_action_choice_grid.columns = maxi(column_count, 1)
	var row_count := ceili(
		float(choice_count) / float(demon_action_choice_grid.columns)
	)
	var font_size := 22
	if choice_count >= 5:
		font_size = 20
	if row_count > 1:
		font_size = 17

	for choice_index in range(choice_count):
		var choice: Dictionary = choices[choice_index]
		var choice_id := String(choice.get("id", "choice_%d" % choice_index))
		var action := Callable()
		var raw_action = choice.get("action", Callable())
		if typeof(raw_action) == TYPE_CALLABLE:
			action = raw_action
		demon_action_choice_ids.append(choice_id)
		demon_action_choice_actions.append(action)

		var button := demon_action_choice_buttons[choice_index]
		button.text = String(choice.get("text", choice_id))
		button.disabled = bool(choice.get("disabled", false))
		button.add_theme_font_size_override(
			"font_size",
			int(choice.get("font_size", font_size))
		)
		button.show()

	for button_index in range(
		choice_count,
		demon_action_choice_buttons.size()
	):
		demon_action_choice_buttons[button_index].hide()

	$HUD/DemonUltimatePanel/UltimateButtons.hide()
	demon_ultimate_bar.hide()
	demon_action_choice_grid.show()
	demon_ultimate_label.text = title
	demon_ultimate_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.78, 0.28, 1.0)
	)


func _hide_demon_action_choices() -> void:
	demon_action_choice_active = false
	demon_action_choice_grid.hide()
	for button in demon_action_choice_buttons:
		button.hide()
	demon_action_choice_context = ""
	demon_action_choice_ids.clear()
	demon_action_choice_actions.clear()


func _on_demon_action_choice_button_pressed(button_index: int) -> void:
	if button_index < 0 or button_index >= demon_action_choice_ids.size():
		return
	var button := demon_action_choice_buttons[button_index]
	_flash_button_feedback(button)
	var choice_id := demon_action_choice_ids[button_index]
	demon_action_choice_selected.emit(
		demon_action_choice_context,
		choice_id
	)
	var action := demon_action_choice_actions[button_index]
	if action.is_valid():
		action.call()


func _on_demon_ultimate_cooldowns_changed(cooldowns: Dictionary) -> void:
	demon_ultimate_cooldowns.clear()
	for raw_id in cooldowns:
		demon_ultimate_cooldowns[raw_id] = cooldowns[raw_id]
	_refresh_demon_ultimate_buttons()


func _refresh_demon_ultimate_buttons() -> void:
	var ui_count := mini(
		demon_ultimate_ui_skills.size(),
		demon_ultimate_ui_buttons.size()
	)
	ui_count = mini(
		ui_count,
		demon_ultimate_ui_cooldown_bars.size()
	)

	for index in ui_count:
		var skill: Dictionary = demon_ultimate_ui_skills[index]
		var skill_id := String(skill.get("id", ""))
		var button: Button = demon_ultimate_ui_buttons[index]
		var bar: ProgressBar = demon_ultimate_ui_cooldown_bars[index]
		var cooldown_max := maxf(float(skill.get("cooldown", 0.0)), 0.0)
		var remaining := maxf(
			float(demon_ultimate_cooldowns.get(skill_id, 0.0)),
			0.0
		)
		var implemented := bool(skill.get("implemented", false))

		bar.max_value = maxf(cooldown_max, 0.1)
		bar.value = remaining
		bar.visible = remaining > 0.001

		var content: Control = demon_ultimate_ui_content[index]
		if not implemented:
			button.disabled = true
			content.update_state("준비중",false)
			continue
		var mana_cost := maxf(float(skill.get("mana_cost",100)),0)
		var ready := demon_mana_current+0.001 >= mana_cost and remaining <= 0.001
		button.disabled = not ready
		var status := "쿨 %.1f초" % remaining if remaining > 0.001 else "비용 %d · %s" % [roundi(mana_cost),("방향 선택" if skill_id == "line_assault" else "사용 가능") if ready else "부족"]
		content.update_state(status,ready)
		button.tooltip_text = "%s\n%s" % [String(skill.get("name","마력 기술")),status]

func _on_demon_ultimate_pressed(skill_id: String) -> void:
	for index in demon_ultimate_ui_skills.size():
		if String(demon_ultimate_ui_skills[index].get("id", "")) != skill_id:
			continue
		if index < demon_ultimate_ui_buttons.size():
			_flash_button_feedback(demon_ultimate_ui_buttons[index])
		break

	if skill_id == "line_assault":
		var skill := DEMON_ULTIMATES.get_skill("line_assault")
		var mana_cost := maxf(float(skill.get("mana_cost", 40.0)), 0.0)
		var ultimate_state: Dictionary = {}
		if battle.has_method("get_demon_ultimate_hud_state"):
			var raw_ultimate_state = battle.call(
				"get_demon_ultimate_hud_state",
				"line_assault"
			)
			if typeof(raw_ultimate_state) == TYPE_DICTIONARY:
				ultimate_state = raw_ultimate_state
		var current_charge := float(
			ultimate_state.get("charge", demon_mana_current)
		)
		if current_charge + 0.001 < mana_cost:
			status_label.text = "마력이 부족합니다. 일직선 공세는 코스트 %d가 필요합니다." % int(round(mana_cost))
			return
		var remaining := float(
			ultimate_state.get(
				"cooldown",
				demon_ultimate_cooldowns.get("line_assault", 0.0)
			)
		)
		if remaining > 0.001:
			status_label.text = "일직선 공세 쿨타임 %.1f초" % remaining
			return
		_open_demon_direction_select()
		return

	if battle.try_use_demon_ultimate(skill_id):
		return

	var skill := DEMON_ULTIMATES.get_skill(skill_id)
	if skill.is_empty():
		return
	if not bool(skill.get("implemented", false)):
		status_label.text = "%s은(는) 다음 단계에서 구현합니다." % String(
			skill.get("name", "마력 기술")
		)
	else:
		var mana_cost := maxf(float(skill.get("mana_cost", 100.0)), 0.0)
		status_label.text = "마력이 부족합니다. %s은(는) 코스트 %d가 필요합니다." % [String(skill.get("name", "마력 기술")), int(round(mana_cost))]

func _open_demon_direction_select() -> void:
	var direction_choices: Array = [
		{
			"id": "east",
			"text": "동쪽 ▶",
			"action": Callable(
				self,
				"_on_demon_line_direction_pressed"
			).bind("east"),
		},
		{
			"id": "west",
			"text": "◀ 서쪽",
			"action": Callable(
				self,
				"_on_demon_line_direction_pressed"
			).bind("west"),
		},
		{
			"id": "north",
			"text": "▲ 북쪽",
			"action": Callable(
				self,
				"_on_demon_line_direction_pressed"
			).bind("north"),
		},
		{
			"id": "south",
			"text": "▼ 남쪽",
			"action": Callable(
				self,
				"_on_demon_line_direction_pressed"
			).bind("south"),
		},
		{
			"id": "cancel",
			"text": "취소",
			"action": Callable(self, "_close_demon_direction_select"),
		},
	]
	_show_demon_action_choices(
		"일직선 공세 · 방향 선택",
		"line_direction",
		direction_choices
	)
	_show_battle_toast("일직선 공세 · 발사 방향을 선택하세요", 1.2)

func _close_demon_direction_select() -> void:
	_hide_demon_action_choices()
	demon_ultimate_bar.show()
	$HUD/DemonUltimatePanel/UltimateButtons.show()
	demon_ultimate_label.remove_theme_color_override("font_color")
	if battle.has_method("get_demon_ultimate_hud_state"):
		var raw_ultimate_state = battle.call(
			"get_demon_ultimate_hud_state"
		)
		if typeof(raw_ultimate_state) == TYPE_DICTIONARY:
			var ultimate_state: Dictionary = raw_ultimate_state
			_on_demon_ultimate_changed(
				float(ultimate_state.get("charge", demon_mana_current)),
				float(ultimate_state.get("max", 100.0)),
				bool(
					ultimate_state.get(
						"ready",
						demon_ultimate_charge_ready
					)
				)
			)

func _on_demon_line_direction_pressed(direction: String) -> void:
	var direction_name: String = String({
		"east": "동쪽",
		"west": "서쪽",
		"north": "북쪽",
		"south": "남쪽",
	}.get(direction, direction))
	if battle.try_use_demon_ultimate("line_assault", direction):
		_show_battle_toast(
			"일직선 공세 · %s 발동" % String(direction_name),
			1.0
		)
		_close_demon_direction_select()
		return

	_show_battle_toast("일직선 공세를 발동할 수 없습니다.", 1.2)
	_set_default_battle_status()
	_close_demon_direction_select()

func _on_demon_ultimate_used(
	_skill_id: String,
	skill_name: String,
	message: String
) -> void:
	var toast_message: String = message
	if toast_message.is_empty():
		toast_message = "%s 발동" % skill_name
	_show_battle_toast(toast_message, 1.2)
	_set_default_battle_status()

func _on_demon_augment_ready(candidates: Array, rerolls_left: int, demon_level: int) -> void:
	current_demon_candidates = candidates.duplicate(true)
	_demon_selected_index = -1
	_demon_rerolls_left = rerolls_left
	_demon_choice_guard_until = Time.get_ticks_msec() + DEMON_CHOICE_OPEN_GUARD_MS
	_demon_confirm_guard_until = 0
	_blocked_choice_pointers = _pressed_choice_pointers.duplicate()
	_blocked_confirm_pointers.clear()
	_end_touch_hold()
	_clear_pending_manual_spawn()
	demon_augment_panel.show()

	var is_special := false
	if not current_demon_candidates.is_empty():
		is_special = (
			String(
				current_demon_candidates[0].get("augment_type", "normal")
			)
			== "special"
		)

	if is_special:
		demon_augment_title.text = "마왕의 특수증강"
		demon_augment_trigger.text = (
			"마왕 Lv.%d · 편성 몬스터 특수증강 1개 선택"
			% demon_level
		)
	else:
		demon_augment_title.text = "마왕의 개입"
		demon_augment_trigger.text = (
			"마왕 Lv.%d · 일반증강 1개 선택"
			% demon_level
		)

	var buttons: Array[Button] = [demon_choice_0, demon_choice_1, demon_choice_2]
	for index in range(buttons.size()):
		buttons[index].toggle_mode = true
		buttons[index].button_group = _demon_choice_group
		# Radio selection changes on press, without a transient second highlight
		# or unchecking/rechecking the already selected card on release.
		buttons[index].action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		buttons[index].set_pressed_no_signal(false)
		buttons[index].disabled = true
		if index >= current_demon_candidates.size():
			buttons[index].visible = false
			continue

		buttons[index].visible = true
		var candidate: Dictionary = current_demon_candidates[index]
		var candidate_type := String(
			candidate.get("augment_type", "normal")
		)

		demon_choice_icons[index].texture = null
		demon_choice_icons[index].visible = false
		buttons[index].text = ""

		var name_label: Label = buttons[index].get_node("Name") as Label
		var description_label: Label = buttons[index].get_node(
			"Description"
		) as Label
		var level_label: Label = buttons[index].get_node("Level") as Label
		name_label.text = ""
		description_label.text = ""
		level_label.text = ""

		if candidate_type == "special":
			var monster_id := String(candidate.get("monster_id", ""))
			_apply_augment_monster_icon(
				demon_choice_icons[index],
				monster_id
			)
			name_label.text = _wrap_augment_card_text(
				String(candidate.get("name", "특수증강")),
				14
			)
			description_label.text = _wrap_augment_card_text(
				String(candidate.get("description", "")),
				16
			)
			level_label.text = "특수 · %s" % (
				_get_catalog_monster_name(monster_id)
			)
		else:
			var target_monster_id := String(
				candidate.get("target_monster_id", "")
			)
			if not target_monster_id.is_empty():
				_apply_augment_monster_icon(
					demon_choice_icons[index],
					target_monster_id
				)

			var current_stack := int(candidate.get("current_stack", 0))
			var max_stack := int(candidate.get("max_stack", 1))
			var next_stack := mini(current_stack + 1, max_stack)
			name_label.text = _wrap_augment_card_text(
				String(candidate.get("name", "증강")),
				14
			)
			description_label.text = _wrap_augment_card_text(
				String(candidate.get("description", "")),
				16
			)
			level_label.text = "%d/%d" % [
				next_stack,
				max_stack,
			]

		if demon_choice_icons[index].visible:
			name_label.offset_top = 122.0
			name_label.offset_bottom = 176.0
			description_label.offset_top = 180.0
		else:
			name_label.offset_top = 64.0
			name_label.offset_bottom = 118.0
			description_label.offset_top = 126.0

	var reroll_max := 3
	if battle.has_method("get_demon_reroll_max"):
		reroll_max = int(battle.call("get_demon_reroll_max"))
	demon_reroll_button.text = "↻ 새로고침 %d / %d" % [rerolls_left, reroll_max]
	demon_reroll_button.disabled = true
	demon_confirm_button.disabled = true
	demon_confirm_button.text = "증강을 먼저 선택하세요"
	demon_augment_guide.text = (
		"특수증강 레벨입니다. 편성 몬스터의 전투 방식을 강화하세요."
		if is_special
		else "일반증강 레벨입니다. 마왕 운영 또는 편성 몬스터를 강화하세요."
	)
	demon_augment_guide.text += "\n카드 선택 후 ‘적용’을 눌러 확정하세요."
	status_label.text = "특수증강 선택 중" if is_special else "일반증강 선택 중"

func _apply_augment_monster_icon(
	icon_rect: TextureRect,
	monster_id: String
) -> void:
	icon_rect.texture = null
	icon_rect.visible = false

	if monster_id.is_empty():
		return

	var texture := _load_monster_info_icon(monster_id)
	if texture == null:
		return

	var display_texture: Texture2D = texture
	var image := texture.get_image()
	if image != null and not image.is_empty():
		var used_rect := image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				used_rect.position,
				used_rect.size
			)
			display_texture = atlas

	icon_rect.texture = display_texture
	icon_rect.visible = true

func _wrap_augment_card_text(
	value: String,
	max_chars_per_line: int
) -> String:
	var max_chars := maxi(max_chars_per_line, 4)
	var words := value.split(" ", false)
	var lines: PackedStringArray = []
	var current_line := ""

	for raw_word in words:
		var word := String(raw_word)
		if word.length() > max_chars:
			if not current_line.is_empty():
				lines.append(current_line)
				current_line = ""
			var start := 0
			while start < word.length():
				lines.append(
					word.substr(start, mini(max_chars, word.length() - start))
				)
				start += max_chars
			continue

		var candidate := word
		if not current_line.is_empty():
			candidate = "%s %s" % [current_line, word]

		if candidate.length() > max_chars:
			if not current_line.is_empty():
				lines.append(current_line)
			current_line = word
		else:
			current_line = candidate

	if not current_line.is_empty():
		lines.append(current_line)

	return "\n".join(lines)

func _on_demon_choice_pressed(index: int) -> void:
	if not _can_select_demon_choice() or index < 0 or index >= current_demon_candidates.size():
		return
	if _demon_selected_index == index:
		return
	_demon_selected_index = index
	_demon_confirm_guard_until = Time.get_ticks_msec() + DEMON_CHOICE_CONFIRM_GUARD_MS
	for button_index in range(_demon_choice_buttons.size()):
		_demon_choice_buttons[button_index].set_pressed_no_signal(button_index == index)
	demon_confirm_button.text = "선택한 증강 적용"
	demon_confirm_button.disabled = true

func _on_demon_confirm_pressed() -> void:
	if not _can_select_demon_choice() or not _blocked_confirm_pointers.is_empty() or Time.get_ticks_msec() < _demon_confirm_guard_until:
		return
	var index := _demon_selected_index
	if index < 0 or index >= current_demon_candidates.size():
		return

	var candidate: Dictionary = current_demon_candidates[index]
	var augment_id: String = String(candidate.get("id", ""))
	# Applying can synchronously open a queued level's next modal. Never hide it
	# after choose_demon_augment returns, or erase its newly generated candidates.
	var previous_candidates := current_demon_candidates
	demon_augment_panel.hide()
	current_demon_candidates = []
	_demon_selected_index = -1
	if battle.choose_demon_augment(augment_id):
		if battle.has_method("get_command_hud_state"):
			var command_state: Vector2 = battle.call(
				"get_command_hud_state"
			)
			_on_command_changed(command_state.x, command_state.y)
	else:
		_on_demon_augment_ready(previous_candidates, _demon_rerolls_left, battle.demon_level)

func _on_demon_reroll_pressed() -> void:
	if not _can_select_demon_choice() or _demon_rerolls_left <= 0:
		return
	battle.reroll_demon_augments()

func _can_select_demon_choice() -> bool:
	return demon_augment_panel.visible and Time.get_ticks_msec() >= _demon_choice_guard_until and _blocked_choice_pointers.is_empty()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# The OS may swallow finger/mouse release while switching applications.
		_pressed_choice_pointers.clear()
		_blocked_choice_pointers.clear()
		_blocked_confirm_pointers.clear()
		_demon_choice_guard_until = Time.get_ticks_msec() + DEMON_CHOICE_OPEN_GUARD_MS

func _update_demon_choice_guard() -> void:
	if not demon_augment_panel.visible:
		return
	var ready := _can_select_demon_choice()
	for button in _demon_choice_buttons:
		button.disabled = not ready
	demon_reroll_button.disabled = not ready or _demon_rerolls_left <= 0
	demon_confirm_button.disabled = not ready or _demon_selected_index < 0 or not _blocked_confirm_pointers.is_empty() or Time.get_ticks_msec() < _demon_confirm_guard_until

func _guard_demon_choice_pointer(event: InputEvent) -> bool:
	var pointer_id := -2
	var pressed := false
	if event is InputEventScreenTouch:
		pointer_id = event.index
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
	else:
		return false
	var blocked := _blocked_choice_pointers.has(pointer_id) or _blocked_confirm_pointers.has(pointer_id)
	var guarding := demon_augment_panel.visible and Time.get_ticks_msec() < _demon_choice_guard_until
	var confirm_guarding := (
		demon_augment_panel.visible
		and Time.get_ticks_msec() < _demon_confirm_guard_until
		and demon_confirm_button.get_global_rect().has_point(event.position)
	)
	if pressed:
		_pressed_choice_pointers[pointer_id] = true
		if guarding:
			_blocked_choice_pointers[pointer_id] = true
		elif confirm_guarding:
			_blocked_confirm_pointers[pointer_id] = true
	else:
		_pressed_choice_pointers.erase(pointer_id)
		_blocked_choice_pointers.erase(pointer_id)
		_blocked_confirm_pointers.erase(pointer_id)
	return demon_augment_panel.visible and (blocked or guarding or confirm_guarding)

func _on_demon_augment_applied(augment_name: String, _build_summary: String) -> void:
	_show_battle_toast("마왕 증강 · %s" % augment_name, 1.6)
	_set_default_battle_status()
	if monster_info_panel.visible:
		_refresh_monster_info_panel()

func _get_monster_name(monster_type: String) -> String:
	match monster_type:
		"spider":
			return "거미"
		"orc":
			return "오크"
		_:
			return "슬라임"

func _on_hero_leveled_up(_new_level: int) -> void:
	# 용사 레벨은 상단 HUD와 용사정보 패널에서만 확인한다.
	if hero_info_panel.visible:
		_refresh_hero_info_panel()

func _on_hero_augment_selected(
	_level: int,
	_candidates: Array,
	_chosen_name: String,
	_reason: String,
	_build_summary: String
) -> void:
	# 용사 증강 선택은 AI가 백그라운드에서 처리한다.
	# 마왕의 소환/스킬 상태 영역에는 후보나 선택 이유를 출력하지 않는다.
	build_label.text = ""
	if hero_info_panel.visible:
		_refresh_hero_info_panel()

func _on_battle_finished(message: String, player_won: bool) -> void:
	hero_bgm_manager.stop_bgm()
	GameAudio.battle_result(self, player_won)
	settings_overlay.hide()
	pause_menu.hide()
	hero_skill_cooldown_bar.hide()
	demon_augment_panel.hide()
	mutation_panel.hide()
	monster_info_panel.hide()
	monster_info_bookmark.hide()
	monster_info_animating = false
	hero_info_panel.hide()
	hero_info_bookmark.hide()
	hero_info_animating = false
	for summon_button in summon_slot_buttons:
		summon_button.disabled = true
	demon_ultimate_1.disabled = true
	demon_ultimate_2.disabled = true
	demon_ultimate_3.disabled = true
	_hide_demon_action_choices()
	placement_toggle.disabled = true

	if player_won:
		result_title.text = "승리 · 스테이지 클리어"
		result_title.add_theme_color_override("font_color", Color("ffe09a"))
		status_label.text = "용사를 쓰러뜨렸습니다. 스테이지 클리어!"
		next_stage_button.visible = battle.can_go_to_next_stage()
	else:
		result_title.text = "패배 · 실험 종료"
		result_title.add_theme_color_override("font_color", Color("ffb2b8"))
		status_label.text = "이번 실험이 종료되었습니다."
		next_stage_button.visible = false

	var copy := preload("res://src/ui/battle_result_copy.gd").format_message(message)
	result_message.text = copy.headline
	result_reward.text = copy.reward
	result_reward.visible = not result_reward.text.is_empty()
	_result_reward_details = copy.details
	result_analysis.text = "전투 분석 불러오는 중..."
	$HUD/ResultBackdrop.show()
	_style_result_actions()
	result_panel.show()
	result_panel.move_to_front()

	call_deferred("_populate_run_result_analysis")

func _style_result_actions() -> void:
	var primary: Button = next_stage_button if next_stage_button.visible else restart_button
	for button in [next_stage_button, stage_select_result_button, restart_button]:
		var emphasized: bool = button == primary
		button.add_theme_color_override("font_color", Color("fff0c9") if emphasized else Color("eee8f5"))
		for state in ["normal", "hover", "pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("50246e") if emphasized else Color("21182f")
			if state != "normal":
				style.bg_color = style.bg_color.lightened(0.15)
			style.border_color = Color("e9be62") if emphasized else Color("89739e")
			style.set_border_width_all(2)
			style.set_content_margin_all(12)
			button.add_theme_stylebox_override(state, PIXEL_PANEL_SKIN.button_style(style))

func _populate_run_result_analysis() -> void:
	if not is_instance_valid(result_analysis):
		return

	if battle != null and battle.has_method("get_run_analysis_summary"):
		var summary = battle.call("get_run_analysis_summary")
		if summary != null:
			result_analysis.text = preload("res://src/ui/battle_result_copy.gd").format_analysis(String(summary), _result_reward_details)
			return

	result_analysis.text = "Run 분석을 불러오지 못했습니다."

func _on_next_stage_pressed() -> void:
	if battle.can_go_to_next_stage():
		_restart_with_stamina(String(battle.current_stage_data.get("next_stage_id", "")))

func _on_lobby_pressed() -> void:
	if _lobby_exit_pending or _scene_load_pending or SceneTransition.is_transitioning():
		return
	var elapsed := Time.get_ticks_msec() - _battle_started_ms if _battle_started_ms >= 0 else -1
	if _battle_started_unix >= 0.0 and elapsed >= 0:
		# Monotonic protects clock rollback; wall time also counts Android deep sleep.
		elapsed = maxi(elapsed, int((Time.get_unix_time_from_system() - _battle_started_unix) * 1000.0))
	var refund := STAMINA.refund_early_exit(_battle_stamina_entry, elapsed)
	if not bool(refund.get("success", false)):
		_show_stamina_notice("스테미너 반환을 저장하지 못했습니다. 다시 눌러 주세요.")
		return
	_lobby_exit_pending = true
	TutorialFlow.returning_to_lobby()
	_begin_threaded_scene_change("res://src/lobby/Lobby.tscn", "로비 이동 중...")


func _begin_threaded_scene_change(path: String, message: String) -> void:
	if _scene_load_pending or path.is_empty():
		return

	if is_instance_valid(battle):
		battle.set_external_pause(true)

	status_label.text = message
	var transition := get_node_or_null("/root/SceneTransition")
	if (
		is_instance_valid(transition)
		and transition.has_method("change_scene")
		and bool(transition.call("change_scene", path, message))
	):
		return

	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		get_tree().change_scene_to_file(path)
		return

	_scene_load_path = path
	_scene_load_pending = true

func _on_restart_pressed() -> void:
	_restart_with_stamina(String(battle.current_stage_id), true)

func _restart_with_stamina(stage_id: String, skip_dialogue: bool = false) -> void:
	if _stamina_entry_pending or _scene_load_pending or SceneTransition.is_transitioning():
		return
	if battle.practice_mode:
		if LocalTestMode.request_practice_battle():
			if not SceneTransition.change_scene("res://src/main/Main.tscn","연습전투 다시 시작..."):
				LocalTestMode.practice_requested = false
		return
	var exempt := LocalTestMode.active or TutorialFlow.active()
	var skill_ids := DEMON_ULTIMATES.get_ordered_ids()
	var selected_skills := DEMON_SKILL_LOADOUT_STORE.load_ids(skill_ids, skill_ids)
	var formation_reason := preload("res://src/systems/dungeon_entry_policy.gd").blocked_reason(battle_loadout_ids, selected_skills, exempt)
	if not formation_reason.is_empty():
		_show_stamina_notice(formation_reason)
		return
	var entry := STAMINA.try_enter(stage_id, exempt)
	if not bool(entry.get("success", false)):
		var message := "스테미너가 부족합니다. 로비의 + 버튼에서 충전 상품을 확인하세요." if entry.get("reason") == "insufficient" else "저장을 확인하고 다시 시도해 주세요."
		_show_stamina_notice(message)
		return
	_stamina_entry_pending = true
	var accepted := SceneTransition.change_scene(
		"res://src/main/Main.tscn", "전투 불러오는 중...",
		{"stage_id": stage_id, "skip_stage_dialogue": skip_dialogue}
	)
	if not accepted:
		STAMINA.refund_failed_entry(entry)
		_stamina_entry_pending = false
		_show_stamina_notice("전투를 불러오지 못했습니다. 다시 시도해 주세요.")

func _show_stamina_notice(message: String) -> void:
	var panel := get_node_or_null("StaminaNotice") as AcceptDialog
	if panel == null:
		panel = AcceptDialog.new()
		panel.name = "StaminaNotice"
		panel.title = "스테미너"
		panel.dialog_autowrap = true
		panel.ok_button_text = "확인"
		panel.add_theme_font_size_override("font_size", 27)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("160e24")
		style.border_color = Color("eac14d")
		style.set_border_width_all(3)
		style.set_content_margin_all(20)
		panel.add_theme_stylebox_override("panel", PIXEL_PANEL_SKIN.skin_style(style))
		var button := panel.get_ok_button()
		button.add_theme_font_size_override("font_size", 27)
		button.custom_minimum_size.y = 72
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, PIXEL_PANEL_SKIN.button_style(style))
		add_child(panel)
	panel.dialog_text = message
	panel.popup_centered(Vector2i(700, 230))
