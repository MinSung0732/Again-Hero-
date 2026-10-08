extends Control

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const RELIC_CATALOG := preload("res://src/data/relic_catalog.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const MUTATION_CATALOG := preload("res://src/data/mutation_catalog.gd")
const SHOP_CATALOG := preload("res://src/data/shop_catalog.gd")
const SHOP_STOREFRONT_ART := preload("res://src/ui/shop_storefront_art.gd")
const MONSTER_COLLECTION_STORE := preload("res://src/systems/monster_collection_store.gd")
const SHOP_SUMMON_HISTORY_STORE := preload(
	"res://src/systems/shop_summon_history_store.gd"
)
const TEAM_LOADOUT_STORE := preload("res://src/systems/team_loadout_store.gd")
const TRANSCENDENCE_DATA := preload("res://src/data/transcendence_catalog.gd")
var _transcendence_entry_confirm = null
var shop_popup_view = preload("res://src/ui/shop_popup_view.gd").new()
var transcendence_view = preload("res://src/ui/transcendence_formation_view.gd").new()
const FORMATION_DRAG_CARD := preload("res://src/ui/formation_drag_card.gd")
const TEAM_FORMATION_VIEW := preload("res://src/ui/team_formation_view.gd")
const MONSTER_UPGRADE_FEEDBACK := preload("res://src/ui/monster_upgrade_feedback.gd")
const PIXEL_PANEL_SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const FORMATION_PRESET_MODEL := preload("res://src/systems/formation_preset_model.gd")
const GACHA_REVEAL_OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
const DEMON_ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const DEMON_SKILL_LOADOUT_STORE := preload(
	"res://src/systems/demon_skill_loadout_store.gd"
)

const STAMINA := preload("res://src/systems/stamina_store.gd")
const STAMINA_RULES := preload("res://src/data/stamina_catalog.gd")
var stamina_view: RefCounted
var _battle_entry_pending := false
var _stamina_entry: Dictionary = {}

const BATTLE_SCENE_PATH := "res://src/main/Main.tscn"
const TEAM_MAX_SLOTS := 3
const HERO_PORTRAIT_REFERENCE_PATH := "res://assets/art/heroes/stage1_mage/stage1_hero_portrait.png"

const UI_FRAME_LARGE_DIR := "res://assets/art/UI/01_large_left_panel"
const UI_FRAME_MEDIUM_DIR := "res://assets/art/UI/03_middle_right_panel"
const UI_CARD_FRAME_DIR := "res://assets/art/UI/uicardframes"
const UI_HEADER_CARD_PATH := UI_CARD_FRAME_DIR + "/ui1.png"
const UI_CONTENT_CARD_PATH := UI_CARD_FRAME_DIR + "/ui9.png"
const UI_STAGE_CARD_FRAME_PATH := UI_CARD_FRAME_DIR + "/ui10_clean_frame.png"
const UI_BATTLE_HUD_DIR := "res://assets/art/UI/battle_hud_v2"
const UI_LOBBY_HEADER_DIR := "res://assets/art/UI/lobby_header"
const UI_HEADER_LEFT_WING_PATH := UI_LOBBY_HEADER_DIR + "/left_wing.svg"
const UI_HEADER_RIGHT_WING_PATH := UI_LOBBY_HEADER_DIR + "/right_wing.svg"
const UI_HEADER_COIN_PATH := UI_LOBBY_HEADER_DIR + "/coin.svg"
const UI_HEADER_PLUS_PATH := UI_LOBBY_HEADER_DIR + "/plus.svg"
const UI_LOBBY_FOOTER_DIR := "res://assets/art/UI/lobby_footer"
const UI_LOBBY_NAV_FRAME_PATH := UI_LOBBY_FOOTER_DIR + "/nav_frame.svg"
const UI_LOBBY_NAV_TAB_PATH := UI_LOBBY_FOOTER_DIR + "/tab_normal.svg"
const UI_LOBBY_NAV_TAB_ACTIVE_PATH := UI_LOBBY_FOOTER_DIR + "/tab_active.svg"
const UI_LOBBY_NAV_SHOP_ICON_PATH := UI_LOBBY_FOOTER_DIR + "/icon_shop.svg"
const UI_LOBBY_NAV_TEAM_ICON_PATH := UI_LOBBY_FOOTER_DIR + "/icon_team.svg"
const UI_LOBBY_NAV_MAIN_ICON_PATH := UI_LOBBY_FOOTER_DIR + "/icon_main.svg"
const UI_LOBBY_NAV_RESEARCH_ICON_PATH := UI_LOBBY_FOOTER_DIR + "/icon_research.svg"
const UI_LOBBY_NAV_OTHER_ICON_PATH := UI_LOBBY_FOOTER_DIR + "/icon_other.svg"
const UI_LOBBY_STAGE_DIR := "res://assets/art/UI/lobby_stage"
const UI_LOBBY_STAGE_TITLE_PATH := UI_LOBBY_STAGE_DIR + "/section_title.svg"
const UI_LOBBY_STAGE_META_PATH := UI_LOBBY_STAGE_DIR + "/stage_meta.svg"
const UI_LOBBY_STAGE_PORTRAIT_PATH := UI_LOBBY_STAGE_DIR + "/portrait_frame.svg"
const UI_LOBBY_STAGE_INFO_PATH := UI_LOBBY_STAGE_DIR + "/info_panel.svg"
const UI_LOBBY_STAGE_ENTER_PATH := UI_LOBBY_STAGE_DIR + "/enter_button.svg"
const UI_LOBBY_STAGE_ENTER_PRESSED_PATH := UI_LOBBY_STAGE_DIR + "/enter_button_pressed.svg"
const UI_MODAL_PANEL_PATH := UI_BATTLE_HUD_DIR + "/modal_panel.svg"
const UI_LOGO_PATH := "res://assets/art/UI/logo/AgainHeroLogo.png"
const UI_LOBBY_BACKGROUND_PATH := "res://assets/art/background/mainlobby_background.png"

@onready var title_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/Title
@onready var resource_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ResourceLabel
@onready var progress_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ProgressLabel

@onready var shop_tab: Control = $SafeArea/Layout/Content/ShopTab
@onready var shop_scroll: ScrollContainer = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll
@onready var shop_gold_label: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BalancePanel/BalanceMargin/BalanceRow/Gold
@onready var shop_research_points_label: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BalancePanel/BalanceMargin/BalanceRow/ResearchPoints
@onready var shop_single_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/MonsterSection/Margin/VBox/BuyRow/SingleButton
@onready var shop_multi_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/MonsterSection/Margin/VBox/BuyRow/MultiButton
@onready var shop_relic_single_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/RelicSection/Margin/VBox/BuyRow/SingleButton
@onready var shop_relic_multi_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/RelicSection/Margin/VBox/BuyRow/MultiButton
@onready var shop_history_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/MonsterSection/Margin/VBox/InfoRow/HistoryButton
@onready var shop_rates_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/MonsterSection/Margin/VBox/InfoRow/RatesButton
@onready var shop_status_label: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/Status
@onready var shop_result_overlay: Control = $ShopResultOverlay
@onready var shop_result_panel: PanelContainer = $ShopResultOverlay/Panel
@onready var shop_result_label: Label = $ShopResultOverlay/Panel/Margin/VBox/ResultScroll/Result
@onready var shop_result_close_button: Button = $ShopResultOverlay/Panel/Margin/VBox/Header/CloseButton
@onready var shop_rates_overlay: Control = $ShopRatesOverlay
@onready var shop_rates_panel: PanelContainer = $ShopRatesOverlay/Panel
@onready var shop_rates_text: Label = $ShopRatesOverlay/Panel/Margin/VBox/RatesPanel/Margin/Scroll/Rates
@onready var shop_rates_close_button: Button = $ShopRatesOverlay/Panel/Margin/VBox/Header/CloseButton
@onready var shop_banner_slide: Control = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide
@onready var shop_banner_badge: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerTop/Badge
@onready var shop_banner_dots: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerTop/Dots
@onready var shop_banner_title: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerTitle
@onready var shop_banner_description: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerDescription
@onready var shop_banner_footer: Label = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerFooter/FooterText
@onready var shop_banner_prev_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerFooter/PrevButton
@onready var shop_banner_next_button: Button = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel/BannerViewport/BannerSlide/BannerMargin/BannerVBox/BannerFooter/NextButton
@onready var shop_package_grid: GridContainer = $SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/PackageSection/Margin/VBox/PackageGrid

@onready var team_tab: Control = $SafeArea/Layout/Content/TeamTab
@onready var main_tab: Control = $SafeArea/Layout/Content/MainTab
@onready var research_tab: Control = $SafeArea/Layout/Content/ResearchTab
@onready var other_tab: Control = $SafeArea/Layout/Content/OtherTab
@onready var other_settings_tab_button: Button = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/Tabs/SettingsTabButton
@onready var other_account_tab_button: Button = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/Tabs/AccountTabButton
@onready var other_settings_panel: VBoxContainer = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel
@onready var other_account_panel: VBoxContainer = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/AccountPanel
@onready var bgm_slider: HSlider = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/BGMRow/Slider
@onready var bgm_value_label: Label = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/BGMRow/Value
@onready var bgm_mute_check: CheckBox = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/BGMMute
@onready var sfx_slider: HSlider = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/SFXRow/Slider
@onready var sfx_value_label: Label = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/SFXRow/Value
@onready var sfx_mute_check: CheckBox = $SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/SFXMute

@onready var shop_button: Button = $BottomNav/NavMargin/NavButtons/ShopButton
@onready var team_button: Button = $BottomNav/NavMargin/NavButtons/TeamButton
@onready var main_button: Button = $BottomNav/NavMargin/NavButtons/MainButton
@onready var research_button: Button = $BottomNav/NavMargin/NavButtons/ResearchButton
@onready var other_button: Button = $BottomNav/NavMargin/NavButtons/OtherButton

@onready var team_summary_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/Summary
@onready var team_slot_1_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot1Button
@onready var team_slot_2_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot2Button
@onready var team_slot_3_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot3Button
@onready var team_mode_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/ModeTabs/TeamModeButton
@onready var skill_mode_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/ModeTabs/SkillModeButton
@onready var formation_list_title: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/ListTitle
@onready var formation_cost_low_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/CostSortButtons/LowButton
@onready var formation_cost_high_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/CostSortButtons/HighButton
@onready var team_monster_grid: GridContainer = $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterScroll/MonsterGrid
@onready var team_status_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/Status

@onready var monster_detail_overlay: Control = $MonsterDetailOverlay
@onready var monster_detail_panel: PanelContainer = $MonsterDetailOverlay/Panel
@onready var monster_detail_title: Label = $MonsterDetailOverlay/Panel/Margin/VBox/Header/Title
@onready var monster_detail_close_button: Button = $MonsterDetailOverlay/Panel/Margin/VBox/Header/CloseButton
@onready var monster_detail_normal_panel: PanelContainer = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel
@onready var monster_detail_normal_badge: Label = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/Badge
@onready var monster_detail_normal_portrait_frame: PanelContainer = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/PortraitFrame
@onready var monster_detail_normal_portrait: TextureRect = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/PortraitFrame/PortraitMargin/Portrait
@onready var monster_detail_normal_name: Label = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/Name
@onready var monster_detail_normal_stats: RichTextLabel = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/Stats
@onready var monster_detail_specials: Label = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/NormalPanel/Margin/VBox/Specials
@onready var monster_detail_elite_panel: PanelContainer = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel
@onready var monster_detail_elite_badge: Label = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/Badge
@onready var monster_detail_elite_portrait_frame: PanelContainer = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/PortraitFrame
@onready var monster_detail_elite_portrait: TextureRect = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/PortraitFrame/PortraitMargin/Portrait
@onready var monster_detail_elite_name: Label = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/Name
@onready var monster_detail_elite_stats: RichTextLabel = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/Stats
@onready var monster_detail_elite_skills: RichTextLabel = $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel/Margin/VBox/Skills

@onready var stage_card: PanelContainer = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard
@onready var prev_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/PrevButton
@onready var next_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/NextButton
@onready var stage_selector_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StageMetaBox/StageNumber
@onready var stage_name_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StageMetaBox/StageName
@onready var portrait_texture: TextureRect = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame/FrameMargin/PortraitInner/PortraitTexture
@onready var portrait_placeholder: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame/FrameMargin/PortraitInner/PortraitPlaceholder
@onready var portrait_badge: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame/FrameMargin/PortraitInner/PortraitBadge
@onready var hero_name_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/HeroName
@onready var stage_description_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/BottomPanel/StageDescription
@onready var stage_status_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/BottomPanel/StageStatus
@onready var stage_reward_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/BottomPanel/StageReward
@onready var enter_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/BottomPanel/EnterButton

@onready var stage_select_overlay: Control = $StageSelectOverlay
@onready var stage_select_panel: PanelContainer = $StageSelectOverlay/Panel
@onready var stage_select_close_button: Button = $StageSelectOverlay/Panel/Margin/VBox/Header/CloseButton
@onready var stage_select_grid: GridContainer = $StageSelectOverlay/Panel/Margin/VBox/StageGrid

@onready var research_points_label: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/Points
@onready var research_status_label: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/Status
@onready var research_mode_button: Button = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ModeTabs/ResearchModeButton
@onready var relic_mode_button: Button = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ModeTabs/RelicModeButton
@onready var research_content: VBoxContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent
@onready var research_detail_panel: PanelContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel
@onready var research_detail_name: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/Name
@onready var research_detail_level: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/Level
@onready var research_detail_effect: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/Effect
@onready var research_detail_description: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/Description
@onready var research_detail_cost: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/ActionRow/Cost
@onready var research_upgrade_button: Button = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/DetailPanel/Margin/VBox/ActionRow/UpgradeButton
@onready var research_list: VBoxContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchContent/ResearchScroll/ResearchList
@onready var relic_content: VBoxContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent
@onready var relic_detail_panel: PanelContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel
@onready var relic_detail_icon: TextureRect = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/IconPanel/Icon
@onready var relic_detail_placeholder: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/IconPanel/Placeholder
@onready var relic_detail_name: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/Info/Name
@onready var relic_detail_level: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/Info/Level
@onready var relic_detail_effect: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/Info/Effect
@onready var relic_detail_gauge: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/Info/GaugeText
@onready var relic_upgrade_button: Button = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/DetailPanel/Margin/HBox/Info/UpgradeButton
@onready var relic_grid: GridContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/RelicScroll/RelicList/RelicGrid
@onready var relic_empty_label: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/RelicScroll/RelicList/Empty
@onready var relic_filter_buttons: Array[Button] = [
	$SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/FilterTabs/AllButton,
	$SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/FilterTabs/AttackButton,
	$SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/FilterTabs/DefenseButton,
	$SafeArea/Layout/Content/ResearchTab/ResearchLayout/RelicContent/FilterTabs/UtilityButton,
]

var stage_ids: Array[String] = []
var selected_stage_index: int = 0
var current_tab: String = "main"
var _team_formation_view = TEAM_FORMATION_VIEW.new()
var _team_upgrade_feedback: Node2D
var _formation_card_cache = preload("res://src/ui/formation_card_cache.gd").new()
var _shop_storefront_art = SHOP_STOREFRONT_ART.new()
var _shop_test_draw_view = preload("res://src/ui/shop_test_draw_view.gd").new()
var _shop_pickup_view = preload("res://src/ui/shop_pickup_view.gd").new()
var research_view_mode: String = "research"
var selected_research_id: String = ""
var research_buttons_by_id: Dictionary = {}
var selected_relic_id: String = ""
var selected_relic_category: String = "all"
var relic_progress_state: Dictionary = {}

const SHOP_BANNER_AUTO_SECONDS := 5.5
const SHOP_BANNER_SLIDE_DISTANCE := 150.0
const SHOP_BANNER_SLIDE_OUT_SECONDS := 0.18
const SHOP_BANNER_SLIDE_IN_SECONDS := 0.24
var shop_banner_index: int = 0
var shop_banner_timer: float = SHOP_BANNER_AUTO_SECONDS
var shop_last_result_text: String = ""
var shop_summon_history: Array = []
var _shop_reveal_pickup_id := ""
var gacha_reveal_overlay: GachaRevealOverlay
var _shop_scroll_touch_index: int = -1
var _detail_scroll_touch_index := -1
var _detail_scroll_position := 0.0
var _shop_banner_transitioning := false
var _shop_banner_tween: Tween

const STAGE_SWIPE_THRESHOLD := 72.0
const STAGE_SLIDE_DISTANCE := 118.0
const STAGE_SLIDE_OUT_DURATION := 0.16
const STAGE_SLIDE_IN_DURATION := 0.24
const STAGE_SCALE_OUT := Vector2(0.94, 0.94)
const STAGE_SCALE_IN_START := Vector2(0.91, 0.91)

var _stage_swipe_active := false
var _stage_swipe_start := Vector2.ZERO
var _stage_transition_running := false
var _stage_pending_index := -1
var _stage_pending_direction := 0
var _stage_card_origin := Vector2.ZERO
var _stage_card_base_modulate := Color.WHITE
var _portrait_texture_cache: Dictionary = {}
var _portrait_reference_image: Image
var _portrait_reference_rect := Rect2i()
var _presentation_ready := false
var settings_view: RefCounted
var main_modes_view: RefCounted
var gameplay_settings_path := "user://gameplay_settings.cfg"
var _portrait_normalization_count := 0
var _monster_icon_texture_cache: Dictionary = {}
var stage_selector_buttons: Array[Button] = []
var _scene_load_path: String = ""
var _scene_load_pending: bool = false

var monster_collection_state: Dictionary = {}
var team_catalog_ids: Array = []
var team_available_ids: Array = []
var team_selected_ids: Array = []
var demon_skill_catalog_ids: Array = []
var demon_skill_selected_ids: Array = []
var formation_mode: String = "team"
var formation_cost_descending := false
var formation_sort_criterion := "cost"
var formation_unlock_filter := "all"

var panel_style := StyleBoxFlat.new()
var header_style := StyleBoxFlat.new()
var content_frame_style := StyleBoxFlat.new()
var stage_card_style := StyleBoxFlat.new()
var portrait_outer_style := StyleBoxFlat.new()
var portrait_inner_style := StyleBoxFlat.new()
var nav_style := StyleBoxFlat.new()
var nav_active_style := StyleBoxFlat.new()
var nav_button_style: StyleBox = StyleBoxFlat.new()
var nav_button_active_style: StyleBox = StyleBoxFlat.new()
var primary_button_style := StyleBoxFlat.new()
var secondary_button_style := StyleBoxFlat.new()
var primary_button_disabled_style := StyleBoxFlat.new()
var secondary_button_disabled_style := StyleBoxFlat.new()
var formation_card_style := StyleBoxFlat.new()
var formation_card_selected_style := StyleBoxFlat.new()
var stage_selector_item_style := StyleBoxFlat.new()
var stage_selector_current_style := StyleBoxFlat.new()
var stage_selector_disabled_style := StyleBoxFlat.new()

func _process(delta: float) -> void:
	_tick_shop_banner(delta)
	if not _scene_load_pending:
		return

	var status := ResourceLoader.load_threaded_get_status(_scene_load_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed = ResourceLoader.load_threaded_get(_scene_load_path)
		_scene_load_pending = false
		if packed is PackedScene:
			var error := get_tree().change_scene_to_packed(packed)
			if error != OK:
				_refund_failed_stamina_entry()
			return
		_refund_failed_stamina_entry()
		enter_stage_button.disabled = false
		_refresh_stage_card()
	elif (
		status == ResourceLoader.THREAD_LOAD_FAILED
		or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	):
		_scene_load_pending = false
		_refund_failed_stamina_entry()
		enter_stage_button.disabled = false
		_refresh_stage_card()


func _ready() -> void:
	GameAudio.enter_frontend(self, "lobby")
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	_build_styles()
	_apply_styles()
	_apply_asset_frames()
	_apply_new_ui_assets()
	_apply_lobby_visual_polish()
	_setup_gacha_reveal_overlay()
	_connect_navigation()
	_setup_cloud_account()
	load("res://src/ui/coupon_dialog.gd").new().install(self)
	settings_view = load("res://src/ui/lobby_settings_view.gd").new()
	settings_view.install(self)
	var normalization := MONSTER_COLLECTION_STORE.normalize_maxed()
	if not bool(normalization.get("success", false)):
		push_warning("최대 강화 조각의 연구 포인트 전환을 저장하지 못했습니다.")
	shop_summon_history = SHOP_SUMMON_HISTORY_STORE.load_entries()
	_refresh_shop_summon_history()

	stage_ids = STAGE_CATALOG.get_ordered_stage_ids()
	if stage_ids.is_empty():
		stage_ids.append("stage_1")

	var saved_stage_id := String(
		STAGE_PROGRESS.load_state().get("current_stage_id", stage_ids[0])
	)
	var saved_index := stage_ids.find(saved_stage_id)
	selected_stage_index = saved_index if saved_index >= 0 else 0
	_setup_stage_selector_buttons()
	PIXEL_PANEL_SKIN.apply_tree(self)
	main_modes_view = load("res://src/ui/lobby_main_modes_view.gd").new()
	main_modes_view.install(self)
	stamina_view = load("res://src/ui/lobby_stamina_view.gd").new()
	stamina_view.install(self)

	_formation_card_cache.install(self)
	_switch_tab("main")
	_refresh_header()
	_refresh_stage_card()
	TutorialFlow.call_deferred("install_lobby", self)

func _setup_cloud_account() -> void:
	var guide := other_account_panel.get_node("Guide") as Label
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.text = "게스트 저장은 이 기기에만 보관됩니다." if LoginGateway.user_id.is_empty() else "계정 저장 · 변경 후 자동 동기화됩니다."
	CloudStore.status_changed.connect(func(message: String): guide.text = message)
	LoginGateway.login_unavailable.connect(func(message: String): guide.text = message)
	var sync := other_account_panel.get_node("KakaoLogin") as Button
	sync.text = "클라우드 저장 동기화"
	sync.disabled = LoginGateway.local_guest_active
	sync.pressed.connect(func():
		sync.disabled = true
		if CloudStore.conflict:
			get_tree().change_scene_to_file("res://src/startup/Startup.tscn")
		else:
			await CloudStore.flush()
			sync.disabled = false
	)
	var logout_button := other_account_panel.get_node("GoogleLogin") as Button
	logout_button.text = "계정 로그인" if LoginGateway.local_guest_active else "로그아웃 / 계정 변경"
	logout_button.disabled = false
	logout_button.pressed.connect(func():
		logout_button.disabled = true
		var cover := ColorRect.new()
		cover.color = Color(0, 0, 0, 0.65)
		cover.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(cover)
		cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var message := Label.new()
		message.text = "저장 확인 후 계정을 종료합니다…"
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		message.add_theme_font_size_override("font_size", 30)
		cover.add_child(message)
		message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if await LoginGateway.logout():
			get_tree().change_scene_to_file("res://src/startup/Startup.tscn")
		else:
			cover.queue_free()
			logout_button.disabled = false
	)
	other_account_panel.get_node("AppLogin").hide()

func _build_styles() -> void:
	panel_style = _make_style(
		Color("171423"),
		Color("4d405f"),
		3,
		26
	)
	header_style = _make_style(
		Color("130f1c"),
		Color("6d557b"),
		3,
		22
	)
	content_frame_style = _make_style(
		Color("0f0c16"),
		Color("5b486b"),
		3,
		26
	)
	content_frame_style.content_margin_left = 22.0
	content_frame_style.content_margin_top = 22.0
	content_frame_style.content_margin_right = 22.0
	content_frame_style.content_margin_bottom = 22.0
	stage_card_style = _make_style(
		Color("21182a"),
		Color("a57938"),
		5,
		30
	)
	portrait_outer_style = _make_style(
		Color("0e0b14"),
		Color("d4a84e"),
		8,
		26
	)
	portrait_inner_style = _make_style(
		Color("12162a"),
		Color("695227"),
		3,
		18
	)
	nav_style = _make_style(
		Color("100d17"),
		Color("3f334d"),
		2,
		0
	)
	nav_active_style = _make_style(
		Color("191321"),
		Color("765a89"),
		2,
		0
	)
	nav_button_style = _make_style(
		Color("12101c"),
		Color("554562"),
		2,
		14
	)
	nav_button_active_style = _make_style(
		Color("3b2147"),
		Color("f2c34f"),
		4,
		14
	)
	for style in [nav_button_style, nav_button_active_style]:
		style.content_margin_top = 60.0
		style.content_margin_bottom = 8.0
	primary_button_style = _make_style(
		Color("6c3b87"),
		Color("d4af52"),
		4,
		18
	)
	secondary_button_style = _make_style(
		Color("282133"),
		Color("685674"),
		3,
		18
	)
	primary_button_disabled_style = (
		primary_button_style.duplicate() as StyleBoxFlat
	)
	primary_button_disabled_style.bg_color = (
		primary_button_disabled_style.bg_color.darkened(0.38)
	)
	primary_button_disabled_style.border_color = (
		primary_button_disabled_style.border_color.darkened(0.28)
	)
	secondary_button_disabled_style = (
		secondary_button_style.duplicate() as StyleBoxFlat
	)
	secondary_button_disabled_style.bg_color = (
		secondary_button_disabled_style.bg_color.darkened(0.22)
	)
	secondary_button_disabled_style.border_color = (
		secondary_button_disabled_style.border_color.darkened(0.22)
	)
	formation_card_style = stage_card_style.duplicate() as StyleBoxFlat
	formation_card_selected_style = primary_button_style.duplicate() as StyleBoxFlat
	for style in [formation_card_style, formation_card_selected_style]:
		style.content_margin_left = 2.0
		style.content_margin_top = 2.0
		style.content_margin_right = 2.0
		style.content_margin_bottom = 2.0

func _make_style(
	background: Color,
	border: Color,
	border_width: int,
	corner_radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 16.0
	style.content_margin_top = 12.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 12.0
	return style

func _apply_styles() -> void:
	var header_backing := _make_style(
		Color("130f1c"),
		Color(0, 0, 0, 0),
		0,
		22
	)
	var content_backing := _make_style(
		Color("0f0c16"),
		Color(0, 0, 0, 0),
		0,
		26
	)
	var card_backing := _make_style(
		Color("21182a"),
		Color(0, 0, 0, 0),
		0,
		30
	)
	var dark_backing := _make_style(
		Color("12162a"),
		Color(0, 0, 0, 0),
		0,
		18
	)

	$SafeArea/Layout/Header.add_theme_stylebox_override(
		"panel",
		header_backing
	)
	$SafeArea/Layout/Content/ContentFrame.add_theme_stylebox_override(
		"panel",
		content_backing
	)
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard.add_theme_stylebox_override(
		"panel",
		card_backing
	)
	# ui10 자체의 상단 사각 프레임을 테두리로 사용한다.
	# 초상화 컨테이너에는 추가 금색/내부 테두리를 그리지 않는다.
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame.add_theme_stylebox_override(
		"panel",
		StyleBoxEmpty.new()
	)
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame/FrameMargin/PortraitInner.add_theme_stylebox_override(
		"panel",
		StyleBoxEmpty.new()
	)
	$BottomNav.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var stage_nav_style := _make_style(
		Color("171321"),
		Color("6f5a7b"),
		2,
		18
	)
	stage_nav_style.content_margin_left = 8.0
	stage_nav_style.content_margin_right = 8.0
	stage_nav_style.content_margin_top = 8.0
	stage_nav_style.content_margin_bottom = 8.0

	for button in [prev_stage_button, next_stage_button]:
		button.add_theme_stylebox_override("normal", stage_nav_style)
		button.add_theme_stylebox_override("hover", secondary_button_style)
		button.add_theme_stylebox_override("pressed", primary_button_style)
		button.add_theme_color_override("font_color", Color("f1e8f4"))

	shop_single_button.add_theme_stylebox_override(
		"normal",
		secondary_button_style
	)
	shop_single_button.add_theme_stylebox_override(
		"hover",
		primary_button_style
	)
	shop_single_button.add_theme_stylebox_override(
		"pressed",
		primary_button_style
	)
	shop_multi_button.add_theme_stylebox_override(
		"normal",
		primary_button_style
	)
	shop_multi_button.add_theme_stylebox_override(
		"hover",
		primary_button_style
	)
	shop_multi_button.add_theme_stylebox_override(
		"pressed",
		primary_button_style
	)

	var enter_style := _make_style(
		Color("71348c"),
		Color("efc44f"),
		3,
		18
	)
	enter_style.content_margin_top = 10.0
	enter_style.content_margin_bottom = 10.0
	enter_stage_button.add_theme_stylebox_override("normal", enter_style)
	enter_stage_button.add_theme_stylebox_override("hover", primary_button_style)
	enter_stage_button.add_theme_stylebox_override("pressed", primary_button_style)
	enter_stage_button.custom_minimum_size = Vector2(420.0, 76.0)
	enter_stage_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for button in [team_slot_1_button, team_slot_2_button, team_slot_3_button]:
		button.add_theme_stylebox_override("normal", stage_card_style)
		button.add_theme_stylebox_override("hover", stage_card_style)
		button.add_theme_stylebox_override("pressed", primary_button_style)

	var detail_normal_style := _make_style(
		Color("211629"),
		Color("76528a"),
		2,
		24
	)
	var detail_elite_style := _make_style(
		Color("11172a"),
		Color("a57938"),
		2,
		24
	)
	var detail_portrait_style := _make_style(
		Color("0d0a14"),
		Color("9c7534"),
		2,
		16
	)
	monster_detail_panel.add_theme_stylebox_override("panel", header_backing)
	monster_detail_normal_panel.add_theme_stylebox_override("panel", detail_normal_style)
	monster_detail_elite_panel.add_theme_stylebox_override("panel", detail_elite_style)
	monster_detail_normal_portrait_frame.add_theme_stylebox_override(
		"panel",
		detail_portrait_style
	)
	monster_detail_elite_portrait_frame.add_theme_stylebox_override(
		"panel",
		detail_portrait_style
	)
	monster_detail_title.add_theme_color_override("font_outline_color", Color("2a132d"))
	monster_detail_title.add_theme_constant_override("outline_size", 6)
	for badge in [monster_detail_normal_badge, monster_detail_elite_badge]:
		badge.add_theme_color_override("font_outline_color", Color("0b0710"))
		badge.add_theme_constant_override("outline_size", 4)
	monster_detail_close_button.add_theme_stylebox_override("normal", secondary_button_style)
	monster_detail_close_button.add_theme_stylebox_override("hover", primary_button_style)
	monster_detail_close_button.add_theme_stylebox_override("pressed", primary_button_style)


func _apply_asset_frames() -> void:
	_install_bottom_nav_frame()

	# 팝업만 별도 프레임을 사용한다. 카드 내부 중첩 장식은 피한다.
	_add_asset_frame(
		monster_detail_panel,
		UI_FRAME_MEDIUM_DIR,
		Vector2(62.0, 61.0),
		Vector2(62.0, 61.0),
		Vector2(62.0, 60.0),
		Vector2(62.0, 60.0),
		38.0,
		37.0,
		34.0,
		34.0
	)



func _install_bottom_nav_frame() -> void:
	var bottom_nav := $BottomNav as PanelContainer
	if bottom_nav == null:
		return

	for stale_name in ["AssetFrame", "BottomNavFrame"]:
		var stale := bottom_nav.get_node_or_null(stale_name)
		if stale != null:
			bottom_nav.remove_child(stale)
			stale.free()

	var frame_texture := _load_svg_texture_direct(UI_LOBBY_NAV_FRAME_PATH)
	if frame_texture == null:
		return
	var tab_texture := _load_svg_texture_direct(UI_LOBBY_NAV_TAB_PATH)
	var active_tab_texture := _load_svg_texture_direct(
		UI_LOBBY_NAV_TAB_ACTIVE_PATH
	)

	var frame := TextureRect.new()
	frame.name = "BottomNavFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = frame_texture
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.z_index = 0
	bottom_nav.add_child(frame)
	bottom_nav.move_child(frame, 0)

	if tab_texture != null:
		nav_button_style = _make_nav_tab_style(tab_texture)
	if active_tab_texture != null:
		nav_button_active_style = _make_nav_tab_style(active_tab_texture)


func _make_nav_tab_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 20.0
	style.texture_margin_top = 20.0
	style.texture_margin_right = 20.0
	style.texture_margin_bottom = 20.0
	style.content_margin_left = 12.0
	style.content_margin_top = 60.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	return style


func _make_svg_style(
	path: String,
	texture_margin_x: float,
	texture_margin_y: float,
	content_margin_x: float = 0.0,
	content_margin_y: float = 0.0
) -> StyleBoxTexture:
	var texture := _load_svg_texture_direct(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margin_x
	style.texture_margin_top = texture_margin_y
	style.texture_margin_right = texture_margin_x
	style.texture_margin_bottom = texture_margin_y
	style.content_margin_left = content_margin_x
	style.content_margin_top = content_margin_y
	style.content_margin_right = content_margin_x
	style.content_margin_bottom = content_margin_y
	return style


func _add_asset_frame(
	target: Control,
	frame_dir: String,
	top_left_size: Vector2,
	top_right_size: Vector2,
	bottom_left_size: Vector2,
	bottom_right_size: Vector2,
	top_height: float,
	bottom_height: float,
	left_width: float,
	right_width: float
) -> void:
	if target == null:
		return

	var overlay := Control.new()
	overlay.name = "AssetFrame"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 8
	target.add_child(overlay)

	_add_frame_piece(
		overlay,
		frame_dir + "/part_01.png",
		Vector2.ZERO,
		top_left_size,
		Vector2.ZERO,
		Vector2.ZERO
	)
	_add_frame_piece(
		overlay,
		frame_dir + "/part_02.png",
		Vector2(1.0, 0.0),
		top_right_size,
		Vector2(-top_right_size.x, 0.0),
		Vector2.ZERO
	)
	_add_frame_piece_stretched(
		overlay,
		frame_dir + "/part_03.png",
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(top_left_size.x, 0.0),
		Vector2(-top_right_size.x, top_height)
	)
	_add_frame_piece_stretched(
		overlay,
		frame_dir + "/part_05.png",
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(0.0, top_left_size.y),
		Vector2(left_width, -bottom_left_size.y)
	)
	_add_frame_piece_stretched(
		overlay,
		frame_dir + "/part_06.png",
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(-right_width, top_right_size.y),
		Vector2(0.0, -bottom_right_size.y)
	)
	_add_frame_piece(
		overlay,
		frame_dir + "/part_07.png",
		Vector2(0.0, 1.0),
		bottom_left_size,
		Vector2(0.0, -bottom_left_size.y),
		Vector2.ZERO
	)
	_add_frame_piece(
		overlay,
		frame_dir + "/part_08.png",
		Vector2(1.0, 1.0),
		bottom_right_size,
		Vector2(-bottom_right_size.x, -bottom_right_size.y),
		Vector2.ZERO
	)
	_add_frame_piece_stretched(
		overlay,
		frame_dir + "/part_09.png",
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(bottom_left_size.x, -bottom_height),
		Vector2(-bottom_right_size.x, 0.0)
	)

func _add_frame_piece(
	parent: Control,
	texture_path: String,
	anchor: Vector2,
	piece_size: Vector2,
	offset: Vector2,
	extra_offset: Vector2
) -> void:
	if not ResourceLoader.exists(texture_path):
		return
	var piece := TextureRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.texture = load(texture_path)
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_SCALE
	piece.anchor_left = anchor.x
	piece.anchor_top = anchor.y
	piece.anchor_right = anchor.x
	piece.anchor_bottom = anchor.y
	piece.offset_left = offset.x + extra_offset.x
	piece.offset_top = offset.y + extra_offset.y
	piece.offset_right = piece.offset_left + piece_size.x
	piece.offset_bottom = piece.offset_top + piece_size.y
	parent.add_child(piece)

func _add_frame_piece_stretched(
	parent: Control,
	texture_path: String,
	anchor_start: Vector2,
	anchor_end: Vector2,
	offset_start: Vector2,
	offset_end: Vector2
) -> void:
	if not ResourceLoader.exists(texture_path):
		return
	var piece := TextureRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.texture = load(texture_path)
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_SCALE
	piece.anchor_left = anchor_start.x
	piece.anchor_top = anchor_start.y
	piece.anchor_right = anchor_end.x
	piece.anchor_bottom = anchor_end.y
	piece.offset_left = offset_start.x
	piece.offset_top = offset_start.y
	piece.offset_right = offset_end.x
	piece.offset_bottom = offset_end.y
	parent.add_child(piece)

func _load_png_texture_direct(path: String) -> Texture2D:
	var cached := PresentationWarmup.get_texture(path)
	if cached != null:
		return cached
	var image := Image.new()
	var load_error := image.load(path)
	if load_error != OK or image.is_empty():
		push_warning("UI PNG load failed: %s / error=%s" % [path, load_error])
		return null
	return ImageTexture.create_from_image(image)


func _load_ui_texture_resource(path: String) -> Texture2D:
	var resource := load(path)
	if resource is Texture2D:
		return resource as Texture2D
	if path.get_extension().to_lower() == "svg":
		return _load_svg_texture_direct(path)
	push_warning("UI texture resource load failed: %s" % path)
	return null


func _load_svg_texture_direct(path: String) -> Texture2D:
	var cached := PresentationWarmup.get_texture(path)
	if cached != null:
		return cached
	if not FileAccess.file_exists(path):
		push_warning("UI SVG file missing: %s" % path)
		return null
	var svg_text := FileAccess.get_file_as_string(path)
	if svg_text.is_empty():
		push_warning("UI SVG file empty: %s" % path)
		return null
	var image := Image.new()
	var load_error := image.load_svg_from_string(svg_text, 1.0)
	if load_error != OK or image.is_empty():
		push_warning("UI SVG load failed: %s / error=%s" % [path, load_error])
		return null
	return ImageTexture.create_from_image(image)


func _load_png_texture_cropped(path: String) -> Texture2D:
	var cached := PresentationWarmup.get_cropped(path)
	if cached != null:
		return cached
	var image := Image.new()
	var load_error := image.load(path)
	if load_error != OK or image.is_empty():
		push_warning("UI PNG crop load failed: %s / error=%s" % [path, load_error])
		return null

	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return ImageTexture.create_from_image(image)

	var cropped := image.get_region(used_rect)
	return ImageTexture.create_from_image(cropped)


func _load_png_texture_top_region(path: String, height_ratio: float) -> Texture2D:
	var image := Image.new()
	var load_error := image.load(path)
	if load_error != OK or image.is_empty():
		push_warning("UI PNG region load failed: %s / error=%s" % [path, load_error])
		return null

	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return ImageTexture.create_from_image(image)

	var cropped_used := image.get_region(used_rect)
	var region_height := maxi(1, int(round(cropped_used.get_height() * clampf(height_ratio, 0.1, 1.0))))
	var top_region := cropped_used.get_region(
		Rect2i(0, 0, cropped_used.get_width(), region_height)
	)
	return ImageTexture.create_from_image(top_region)


func _apply_content_card_skin(content_frame: PanelContainer) -> void:
	if content_frame == null:
		return

	var texture := _load_png_texture_cropped(UI_CONTENT_CARD_PATH)
	if texture == null:
		return

	var texture_size := texture.get_size()
	var margin_x := maxi(1, int(round(texture_size.x * 0.13)))
	var margin_y := maxi(1, int(round(texture_size.y * 0.075)))

	var content_skin := StyleBoxTexture.new()
	content_skin.texture = texture
	content_skin.texture_margin_left = margin_x
	content_skin.texture_margin_top = margin_y
	content_skin.texture_margin_right = margin_x
	content_skin.texture_margin_bottom = margin_y
	# 0 margin keeps this decorative skin out of layout/minimum-size calculations.
	content_skin.content_margin_left = 0.0
	content_skin.content_margin_top = 0.0
	content_skin.content_margin_right = 0.0
	content_skin.content_margin_bottom = 0.0
	content_frame.add_theme_stylebox_override("panel", content_skin)


func _apply_header_card_skin(header: Control) -> void:
	if header == null:
		return

	# The previous full-width ui1 frame forced the logo, resource text and
	# decorative rails into the same strip. Keep the Header layout footprint,
	# but let dedicated left/right HUD plates and the center logo own the art.
	header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _apply_new_ui_assets() -> void:
	# Decorative frame skins are applied as StyleBoxTexture so they never resize
	# the verified StageCard/content layout.
	_apply_content_card_skin($SafeArea/Layout/Content/ContentFrame)

	title_label.visible = false

	var header := $SafeArea/Layout/Header as PanelContainer
	_apply_header_card_skin(header)

	var header_margin := $SafeArea/Layout/Header/HeaderMargin as MarginContainer
	header_margin.visible = false

	var existing_gold_plate := header.get_node_or_null("HeaderGoldPlate")
	if existing_gold_plate == null:
		existing_gold_plate = header.get_node_or_null(
			"HeaderSlots/HeaderGoldPlate"
		)
	if existing_gold_plate != null and resource_label.get_parent() == existing_gold_plate:
		existing_gold_plate.remove_child(resource_label)
		header.add_child(resource_label)
	var existing_progress_plate := header.get_node_or_null("HeaderProgressPlate")
	if existing_progress_plate == null:
		existing_progress_plate = header.get_node_or_null(
			"HeaderSlots/HeaderProgressPlate"
		)
	if (
		existing_progress_plate != null
		and progress_label.get_parent() == existing_progress_plate
	):
		existing_progress_plate.remove_child(progress_label)
		header.add_child(progress_label)

	for stale_name in [
		"HeaderBackdrop",
		"HeaderSlots",
		"HeaderGoldPlate",
		"HeaderProgressPlate",
		"HeaderCenterSlot",
		"HeaderCenterMask",
		"HeaderLogoBackplate",
		"HeaderLogo",
	]:
		var stale := header.get_node_or_null(stale_name)
		if stale != null:
			header.remove_child(stale)
			stale.free()

	var left_wing_texture := _load_ui_texture_resource(
		UI_HEADER_LEFT_WING_PATH
	)
	var right_wing_texture := _load_ui_texture_resource(
		UI_HEADER_RIGHT_WING_PATH
	)
	var coin_texture := _load_ui_texture_resource(UI_HEADER_COIN_PATH)
	var plus_texture := _load_ui_texture_resource(UI_HEADER_PLUS_PATH)

	# PanelContainer forces every direct Control child to its full rect. Place one
	# full-size overlay under it, then anchor the three real slots inside that plain
	# Control so their boundaries are actually respected at runtime.
	var slots_root := Control.new()
	slots_root.name = "HeaderSlots"
	slots_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header.add_child(slots_root)

	# Keep the header in three non-overlapping slots. Each slot owns its art and
	# content so long values and the center logo cannot push into a neighbour.
	var gold_plate := Control.new()
	gold_plate.name = "HeaderGoldPlate"
	gold_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_plate.anchor_left = 0.005
	gold_plate.anchor_top = 0.0
	gold_plate.anchor_right = 0.40
	gold_plate.anchor_bottom = 1.0
	gold_plate.clip_contents = true
	gold_plate.z_index = 0
	slots_root.add_child(gold_plate)

	var center_slot := Control.new()
	center_slot.name = "HeaderCenterSlot"
	center_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_slot.anchor_left = 0.25
	center_slot.anchor_top = 0.0
	center_slot.anchor_right = 0.75
	center_slot.anchor_bottom = 1.0
	center_slot.clip_contents = false
	center_slot.z_index = 0
	slots_root.add_child(center_slot)

	var progress_plate := Control.new()
	progress_plate.name = "HeaderProgressPlate"
	progress_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_plate.anchor_left = 0.60
	progress_plate.anchor_top = 0.0
	progress_plate.anchor_right = 0.995
	progress_plate.anchor_bottom = 1.0
	progress_plate.clip_contents = true
	progress_plate.z_index = 0
	slots_root.add_child(progress_plate)

	if left_wing_texture != null:
		var left_wing := TextureRect.new()
		left_wing.name = "Wing"
		left_wing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_wing.texture = left_wing_texture
		left_wing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		left_wing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		left_wing.stretch_mode = TextureRect.STRETCH_SCALE
		left_wing.anchor_left = 0.0
		left_wing.anchor_top = 0.22
		left_wing.anchor_right = 1.0
		left_wing.anchor_bottom = 0.82
		left_wing.z_index = 0
		gold_plate.add_child(left_wing)

	if right_wing_texture != null:
		var right_wing := TextureRect.new()
		right_wing.name = "Wing"
		right_wing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right_wing.texture = right_wing_texture
		right_wing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		right_wing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		right_wing.stretch_mode = TextureRect.STRETCH_SCALE
		right_wing.anchor_left = 0.0
		right_wing.anchor_top = 0.22
		right_wing.anchor_right = 1.0
		right_wing.anchor_bottom = 0.82
		right_wing.z_index = 0
		progress_plate.add_child(right_wing)

	# Keep the original labels as hidden state holders. The visible HUD uses
	# dedicated two-line labels so title/value typography can be tuned separately.
	resource_label.visible = false
	progress_label.visible = false

	var gold_title := Label.new()
	gold_title.name = "HeaderGoldTitle"
	gold_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_title.text = "골드"
	gold_title.anchor_left = 0.0
	gold_title.anchor_top = 0.52
	gold_title.anchor_right = 0.53
	gold_title.anchor_bottom = 0.52
	gold_title.offset_left = 58.0
	gold_title.offset_top = -29.0
	gold_title.offset_right = 0.0
	gold_title.offset_bottom = -4.0
	gold_title.clip_text = true
	gold_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	gold_title.add_theme_font_size_override("font_size", 17)
	gold_title.add_theme_color_override("font_color", Color("eee6f2"))
	gold_title.add_theme_color_override("font_outline_color", Color("171027"))
	gold_title.add_theme_constant_override("outline_size", 2)
	gold_title.z_index = 3
	gold_plate.add_child(gold_title)

	var gold_value := Label.new()
	gold_value.name = "HeaderGoldValue"
	gold_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_value.text = _format_shop_number(_get_shop_gold())
	gold_value.anchor_left = 0.0
	gold_value.anchor_top = 0.52
	gold_value.anchor_right = 0.53
	gold_value.anchor_bottom = 0.52
	gold_value.offset_left = 58.0
	gold_value.offset_top = 0.0
	gold_value.offset_right = 0.0
	gold_value.offset_bottom = 31.0
	gold_value.clip_text = true
	gold_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	gold_value.add_theme_font_size_override("font_size", 23)
	gold_value.add_theme_color_override("font_color", Color("ffe28a"))
	gold_value.add_theme_color_override("font_outline_color", Color("171027"))
	gold_value.add_theme_constant_override("outline_size", 2)
	gold_value.z_index = 3
	gold_plate.add_child(gold_value)

	if coin_texture != null:
		var coin_icon := TextureRect.new()
		coin_icon.name = "HeaderCoinIcon"
		coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin_icon.texture = coin_texture
		coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin_icon.anchor_left = 0.0
		coin_icon.anchor_top = 0.52
		coin_icon.anchor_right = 0.0
		coin_icon.anchor_bottom = 0.52
		coin_icon.offset_left = 16.0
		coin_icon.offset_top = -17.0
		coin_icon.offset_right = 50.0
		coin_icon.offset_bottom = 17.0
		coin_icon.z_index = 3
		gold_plate.add_child(coin_icon)

	if plus_texture != null:
		var plus_button := TextureButton.new()
		plus_button.name = "HeaderPlusButton"
		plus_button.texture_normal = plus_texture
		plus_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plus_button.ignore_texture_size = true
		plus_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		plus_button.anchor_left = 0.0
		plus_button.anchor_top = 0.52
		plus_button.anchor_right = 0.0
		plus_button.anchor_bottom = 0.52
		plus_button.offset_left = 52.0
		plus_button.offset_top = -16.0
		plus_button.offset_right = 84.0
		plus_button.offset_bottom = 16.0
		plus_button.tooltip_text = "상점"
		plus_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		plus_button.z_index = 3
		plus_button.pressed.connect(_switch_tab.bind("shop"))
		gold_plate.add_child(plus_button)

	var progress_title := Label.new()
	progress_title.name = "HeaderProgressTitle"
	progress_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_title.text = "최고 해금"
	progress_title.anchor_left = 0.40
	progress_title.anchor_top = 0.52
	progress_title.anchor_right = 0.94
	progress_title.anchor_bottom = 0.52
	progress_title.offset_left = 0.0
	progress_title.offset_top = -29.0
	progress_title.offset_right = 0.0
	progress_title.offset_bottom = -4.0
	progress_title.clip_text = true
	progress_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	progress_title.add_theme_font_size_override("font_size", 17)
	progress_title.add_theme_color_override("font_color", Color("eee6f2"))
	progress_title.add_theme_color_override("font_outline_color", Color("171027"))
	progress_title.add_theme_constant_override("outline_size", 2)
	progress_title.z_index = 3
	progress_plate.add_child(progress_title)

	var progress_value := Label.new()
	progress_value.name = "HeaderProgressValue"
	progress_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_value.text = "Stage 1"
	progress_value.anchor_left = 0.40
	progress_value.anchor_top = 0.52
	progress_value.anchor_right = 0.94
	progress_value.anchor_bottom = 0.52
	progress_value.offset_left = 0.0
	progress_value.offset_top = 0.0
	progress_value.offset_right = 0.0
	progress_value.offset_bottom = 31.0
	progress_value.clip_text = true
	progress_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	progress_value.add_theme_font_size_override("font_size", 23)
	progress_value.add_theme_color_override("font_color", Color("ffe28a"))
	progress_value.add_theme_color_override("font_outline_color", Color("171027"))
	progress_value.add_theme_constant_override("outline_size", 2)
	progress_value.z_index = 3
	progress_plate.add_child(progress_value)

	var logo_texture := _load_png_texture_direct(UI_LOGO_PATH)
	if logo_texture != null:
		var logo := TextureRect.new()
		logo.name = "HeaderLogo"
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.texture = logo_texture
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.anchor_left = -0.14
		logo.anchor_top = 0.0
		logo.anchor_right = 1.14
		logo.anchor_bottom = 1.0
		logo.offset_top = -8.0
		logo.offset_bottom = 8.0
		logo.z_index = 10
		center_slot.add_child(logo)

	var stage_card := $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard
	# Dungeon entry uses a dedicated clean outer frame.
	# Internal section dividers are drawn by code so they cannot overlap content.
	var stage_texture := _load_png_texture_direct(
		UI_STAGE_CARD_FRAME_PATH
	)
	if stage_card != null and stage_texture != null:
		var old_stage_skin := stage_card.get_node_or_null("StageCardSkin")
		if old_stage_skin != null:
			old_stage_skin.queue_free()

		var stage_skin := TextureRect.new()
		stage_skin.name = "StageCardSkin"
		stage_skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_skin.texture = stage_texture
		stage_skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stage_skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stage_skin.stretch_mode = TextureRect.STRETCH_SCALE
		stage_skin.set_anchors_preset(Control.PRESET_FULL_RECT)
		stage_skin.offset_left = 0.0
		stage_skin.offset_top = 0.0
		stage_skin.offset_right = 0.0
		stage_skin.offset_bottom = 0.0
		stage_card.add_child(stage_skin)
		stage_card.move_child(stage_skin, 0)

	var arrow_texture := _load_png_texture_direct(UI_CARD_FRAME_DIR + "/ui8.png")
	if arrow_texture != null:
		_apply_arrow_texture(prev_stage_button, arrow_texture, false)
		_apply_arrow_texture(next_stage_button, arrow_texture, true)
		_refresh_stage_nav_buttons()



func _set_lobby_label_style(
	path: NodePath,
	font_size: int,
	color: Color
) -> void:
	var label := get_node_or_null(path) as Label
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _apply_lobby_button_skin(
	button: Button,
	primary: bool = false,
	font_size: int = 24
) -> void:
	if button == null:
		return

	var normal_style := primary_button_style if primary else secondary_button_style
	button.add_theme_stylebox_override("normal", PIXEL_PANEL_SKIN.button_style(normal_style))
	button.add_theme_stylebox_override("hover", PIXEL_PANEL_SKIN.button_style(primary_button_style))
	button.add_theme_stylebox_override("pressed", PIXEL_PANEL_SKIN.button_style(primary_button_style))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override(
		"font_color",
		Color("fff0c2") if primary else Color("eee7f2")
	)
	button.add_theme_color_override("font_hover_color", Color("fff5d7"))
	button.add_theme_color_override("font_pressed_color", Color("ffe29a"))
	button.add_theme_color_override("font_disabled_color", Color("756f7c"))
	if shop_tab.is_ancestor_of(button) or shop_result_overlay.is_ancestor_of(button) or shop_rates_overlay.is_ancestor_of(button):
		preload("res://src/ui/shop_frame_skin.gd").apply_button(button, primary)



func _apply_enter_stage_button_skin() -> void:
	if enter_stage_button == null:
		return

	# A single cached nine-patch frame avoids baked-in lines behind the label.
	var frames = preload("res://src/ui/commerce_frame_skin.gd")
	var normal := frames.style("shop_button_frame", 18)
	var hover := frames.style("shop_button_frame", 18, Color("fff8df"))
	var pressed := frames.style("shop_button_frame", 18, Color("c5a6d7"))
	var disabled := frames.style("shop_button_frame", 18, Color("827489"))
	enter_stage_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	enter_stage_button.add_theme_stylebox_override("normal", normal)
	enter_stage_button.add_theme_stylebox_override("hover", hover)
	enter_stage_button.add_theme_stylebox_override("pressed", pressed)
	enter_stage_button.add_theme_stylebox_override("disabled", disabled)
	enter_stage_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	enter_stage_button.add_theme_font_size_override("font_size", 34)
	enter_stage_button.add_theme_color_override("font_color", Color("fff1ca"))
	enter_stage_button.add_theme_color_override("font_hover_color", Color("fff8df"))
	enter_stage_button.add_theme_color_override("font_pressed_color", Color("ffe3a0"))
	enter_stage_button.add_theme_color_override("font_disabled_color", Color("8f8495"))


func _install_lobby_background() -> void:
	var texture := _load_png_texture_direct(UI_LOBBY_BACKGROUND_PATH)
	if texture == null:
		return

	var backdrop := get_node_or_null("LobbyBackground") as TextureRect
	if backdrop == null:
		backdrop = TextureRect.new()
		backdrop.name = "LobbyBackground"
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(backdrop)
		move_child(backdrop, 0)

	backdrop.texture = texture
	backdrop.modulate = Color(0.84, 0.72, 0.92, 0.98)


func _make_hud_panel_style(
	background: Color,
	border: Color,
	border_width: int = 2,
	corner_radius: int = 12
) -> StyleBoxFlat:
	var style := _make_style(
		background,
		border,
		border_width,
		corner_radius
	)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _install_stage_entry_hud() -> void:
	var section_header := $SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox as Control
	var section_title := $SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox/SectionTitle as Label
	var section_subtitle := $SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox/SectionSubtitle as Label
	var stage_layout := $SafeArea/Layout/Content/MainTab/StageLayout as VBoxContainer
	var stage_meta := $SafeArea/Layout/Content/MainTab/StageLayout/StageMetaBox as Control
	var stage_picker := $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker as HBoxContainer
	var stage_card_slot := $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot as Control
	var card_margin := $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin as MarginContainer
	var portrait_frame := $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCardSlot/StageCard/CardMargin/CardVBox/TopPanel/PortraitFrame as PanelContainer
	var portrait_inner := portrait_texture.get_parent() as PanelContainer
	var bottom_panel := stage_description_label.get_parent() as Control

	# Header and stage meta used to overflow their VBox slots. Keep every label
	# inside its own reserved area so the whole screen reads as one HUD.
	stage_layout.offset_top = 54.0
	stage_layout.offset_bottom = -18.0
	stage_layout.add_theme_constant_override("separation", 6)

	section_header.custom_minimum_size = Vector2(0.0, 108.0)
	section_title.offset_top = 24.0
	section_title.offset_bottom = 60.0
	section_subtitle.offset_top = 64.0
	section_subtitle.offset_bottom = 98.0

	var old_section_frame := section_header.get_node_or_null("SectionHudFrame")
	if old_section_frame != null:
		section_header.remove_child(old_section_frame)
		old_section_frame.free()
	var section_texture := _load_svg_texture_direct(UI_LOBBY_STAGE_TITLE_PATH)
	if section_texture != null:
		var section_frame := TextureRect.new()
		section_frame.name = "SectionHudFrame"
		section_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		section_frame.texture = section_texture
		section_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		section_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		section_frame.stretch_mode = TextureRect.STRETCH_SCALE
		section_frame.anchor_left = 0.08
		section_frame.anchor_top = 0.0
		section_frame.anchor_right = 0.92
		section_frame.anchor_bottom = 1.0
		section_header.add_child(section_frame)
		section_header.move_child(section_frame, 0)

	stage_meta.custom_minimum_size = Vector2(0.0, 100.0)
	stage_selector_button.anchor_left = 0.25
	stage_selector_button.anchor_right = 0.75
	stage_selector_button.offset_left = 0.0
	stage_selector_button.offset_top = 2.0
	stage_selector_button.offset_right = 0.0
	stage_selector_button.offset_bottom = 46.0
	stage_name_label.offset_top = 50.0
	stage_name_label.offset_bottom = 94.0
	stage_name_label.clip_text = true
	stage_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	stage_picker.add_theme_constant_override("separation", 6)
	prev_stage_button.custom_minimum_size = Vector2(92.0, 200.0)
	next_stage_button.custom_minimum_size = Vector2(92.0, 200.0)
	stage_card_slot.custom_minimum_size = Vector2(826.0, 1200.0)
	stage_card_slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stage_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var meta_plate := stage_meta.get_node_or_null("StageMetaPlate") as Panel
	if meta_plate == null:
		meta_plate = Panel.new()
		meta_plate.name = "StageMetaPlate"
		meta_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meta_plate.anchor_left = 0.12
		meta_plate.anchor_top = 0.02
		meta_plate.anchor_right = 0.88
		meta_plate.anchor_bottom = 0.98
		meta_plate.add_theme_stylebox_override(
			"panel",
			_make_hud_panel_style(
				Color(0.055, 0.035, 0.075, 0.84),
				Color(0.78, 0.55, 0.22, 0.92),
				2,
				10
			)
		)
		stage_meta.add_child(meta_plate)
		stage_meta.move_child(meta_plate, 0)

		var connector := Control.new()
		connector.name = "StageConnector"
		connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
		connector.anchor_left = 0.5
		connector.anchor_top = 1.0
		connector.anchor_right = 0.5
		connector.anchor_bottom = 1.0
		connector.offset_left = -18.0
		connector.offset_top = -2.0
		connector.offset_right = 18.0
		connector.offset_bottom = 28.0
		connector.z_index = 3
		meta_plate.add_child(connector)

		var connector_gem := ColorRect.new()
		connector_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		connector_gem.color = Color("bd67da")
		connector_gem.anchor_left = 0.5
		connector_gem.anchor_top = 0.58
		connector_gem.anchor_right = 0.5
		connector_gem.anchor_bottom = 0.58
		connector_gem.offset_left = -6.0
		connector_gem.offset_top = -6.0
		connector_gem.offset_right = 6.0
		connector_gem.offset_bottom = 6.0
		connector_gem.rotation = PI * 0.25
		connector.add_child(connector_gem)

		for ratio in [0.06, 0.94]:
			var jewel := ColorRect.new()
			jewel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			jewel.color = Color("bb63d9")
			jewel.anchor_left = ratio
			jewel.anchor_top = 0.48
			jewel.anchor_right = ratio
			jewel.anchor_bottom = 0.48
			jewel.offset_left = -6.0
			jewel.offset_top = -6.0
			jewel.offset_right = 6.0
			jewel.offset_bottom = 6.0
			jewel.rotation = PI * 0.25
			meta_plate.add_child(jewel)

	var meta_style := _make_svg_style(
		UI_LOBBY_STAGE_META_PATH,
		30.0,
		22.0,
		8.0,
		6.0
	)
	if meta_style != null:
		meta_plate.add_theme_stylebox_override("panel", meta_style)

	for stale_name in ["SectionTitlePlate", "HeaderRuleLeft", "HeaderRuleRight"]:
		var stale_header_node := section_header.get_node_or_null(stale_name)
		if stale_header_node != null:
			section_header.remove_child(stale_header_node)
			stale_header_node.free()

	card_margin.add_theme_constant_override("margin_left", 18)
	card_margin.add_theme_constant_override("margin_right", 18)
	card_margin.add_theme_constant_override("margin_bottom", 28)

	portrait_frame.anchor_left = 0.140
	portrait_frame.anchor_top = 0.080
	portrait_frame.anchor_right = 0.860
	portrait_frame.anchor_bottom = 0.525
	var portrait_style := _make_svg_style(
		UI_LOBBY_STAGE_PORTRAIT_PATH,
		30.0,
		30.0,
		14.0,
		14.0
	)
	if portrait_style != null:
		portrait_frame.add_theme_stylebox_override("panel", portrait_style)

	var hero_name_plate := hero_name_label.get_parent().get_node_or_null(
		"HeroNamePlate"
	) as Panel
	if hero_name_plate == null:
		hero_name_plate = Panel.new()
		hero_name_plate.name = "HeroNamePlate"
		hero_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_name_plate.anchor_left = 0.28
		hero_name_plate.anchor_top = 0.515
		hero_name_plate.anchor_right = 0.72
		hero_name_plate.anchor_bottom = 0.580
		hero_name_plate.add_theme_stylebox_override(
			"panel",
			_make_hud_panel_style(
				Color(0.05, 0.035, 0.07, 0.94),
				Color(0.78, 0.56, 0.23, 0.96),
				2,
				8
			)
		)
		hero_name_plate.z_index = 2
		hero_name_label.get_parent().add_child(hero_name_plate)
		hero_name_label.get_parent().move_child(hero_name_plate, 1)

		for data in [
			["NameGemLeft", 0.08],
			["NameGemRight", 0.92],
		]:
			var gem := ColorRect.new()
			gem.name = String(data[0])
			gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
			gem.color = Color("d8a94d")
			gem.anchor_left = float(data[1])
			gem.anchor_top = 0.5
			gem.anchor_right = float(data[1])
			gem.anchor_bottom = 0.5
			gem.offset_left = -4.0
			gem.offset_top = -4.0
			gem.offset_right = 4.0
			gem.offset_bottom = 4.0
			gem.rotation = PI * 0.25
			hero_name_plate.add_child(gem)

	hero_name_label.anchor_left = 0.25
	hero_name_label.anchor_top = 0.518
	hero_name_label.anchor_right = 0.75
	hero_name_label.anchor_bottom = 0.578
	hero_name_label.clip_text = true
	hero_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hero_name_label.z_index = 3

	if portrait_inner != null:
		var old_portrait_backdrop := portrait_inner.get_node_or_null(
			"PortraitBackdrop"
		)
		if old_portrait_backdrop != null:
			portrait_inner.remove_child(old_portrait_backdrop)
			old_portrait_backdrop.free()
		var old_portrait_glow := portrait_inner.get_node_or_null("PortraitGlow")
		if old_portrait_glow != null:
			portrait_inner.remove_child(old_portrait_glow)
			old_portrait_glow.free()

	portrait_texture.z_index = 1
	portrait_placeholder.z_index = 2
	portrait_badge.z_index = 2

	bottom_panel.anchor_left = 0.145
	bottom_panel.anchor_top = 0.590
	bottom_panel.anchor_right = 0.855
	bottom_panel.anchor_bottom = 0.920

	var description_backing := bottom_panel.get_node_or_null(
		"DescriptionBacking"
	) as Panel
	if description_backing == null:
		description_backing = Panel.new()
		description_backing.name = "DescriptionBacking"
		description_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description_backing.anchor_left = 0.035
		description_backing.anchor_top = 0.015
		description_backing.anchor_right = 0.965
		description_backing.anchor_bottom = 0.285
		description_backing.add_theme_stylebox_override(
			"panel",
			_make_hud_panel_style(
				Color(0.045, 0.032, 0.065, 0.44),
				Color(0, 0, 0, 0),
				0,
				8
			)
		)
		bottom_panel.add_child(description_backing)
		bottom_panel.move_child(description_backing, 0)
	var description_style := _make_svg_style(
		UI_LOBBY_STAGE_INFO_PATH,
		24.0,
		18.0,
		10.0,
		8.0
	)
	if description_style != null:
		description_backing.add_theme_stylebox_override(
			"panel",
			description_style
		)

	var info_backing := bottom_panel.get_node_or_null("EntryInfoBacking") as Panel
	if info_backing == null:
		info_backing = Panel.new()
		info_backing.name = "EntryInfoBacking"
		info_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_backing.anchor_left = 0.035
		info_backing.anchor_top = 0.315
		info_backing.anchor_right = 0.965
		info_backing.anchor_bottom = 0.565
		info_backing.add_theme_stylebox_override(
			"panel",
			_make_hud_panel_style(
				Color(0.060, 0.040, 0.082, 0.50),
				Color(0, 0, 0, 0),
				0,
				6
			)
		)
		bottom_panel.add_child(info_backing)
		bottom_panel.move_child(info_backing, 1)

		for split_ratio in [0.280, 0.720]:
			var divider := ColorRect.new()
			divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
			divider.color = Color(0.67, 0.48, 0.22, 0.55)
			divider.z_index = 1
			divider.anchor_left = split_ratio
			divider.anchor_top = 0.24
			divider.anchor_right = split_ratio
			divider.anchor_bottom = 0.76
			divider.offset_left = -1.0
			divider.offset_right = 1.0
			divider.offset_top = 0.0
			divider.offset_bottom = 0.0
			info_backing.add_child(divider)
	var info_style := _make_svg_style(
		UI_LOBBY_STAGE_INFO_PATH,
		24.0,
		18.0,
		10.0,
		8.0
	)
	if info_style != null:
		info_backing.add_theme_stylebox_override("panel", info_style)

	stage_description_label.anchor_left = 0.095
	stage_description_label.anchor_top = 0.055
	stage_description_label.anchor_right = 0.905
	stage_description_label.anchor_bottom = 0.250
	stage_description_label.offset_left = 0.0
	stage_description_label.offset_top = 0.0
	stage_description_label.offset_right = 0.0
	stage_description_label.offset_bottom = 0.0
	stage_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_description_label.clip_text = true
	stage_description_label.max_lines_visible = 3
	stage_description_label.text_overrun_behavior = (
		TextServer.OVERRUN_TRIM_ELLIPSIS
	)

	stage_status_label.anchor_top = 0.355
	stage_status_label.anchor_bottom = 0.525
	stage_reward_label.anchor_top = 0.355
	stage_reward_label.anchor_bottom = 0.525
	stage_status_label.clip_text = true
	stage_reward_label.clip_text = true

	var repeat_label := bottom_panel.get_node_or_null("RepeatReward") as Label
	if repeat_label == null:
		repeat_label = Label.new()
		repeat_label.name = "RepeatReward"
		repeat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		repeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		repeat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		repeat_label.add_theme_color_override("font_color", Color("d7c8df"))
		bottom_panel.add_child(repeat_label)
	repeat_label.anchor_top = 0.355
	repeat_label.anchor_bottom = 0.525
	repeat_label.add_theme_font_size_override("font_size", 17)
	repeat_label.clip_text = true
	# Share the panel's column boundaries; outer columns get symmetric inset padding.
	var info_width := info_backing.anchor_right - info_backing.anchor_left
	for column in [
		[stage_status_label, 0.0, 0.280, 24.0, 8.0],
		[stage_reward_label, 0.280, 0.720, 8.0, 8.0],
		[repeat_label, 0.720, 1.0, 8.0, 24.0],
	]:
		var label: Label = column[0]
		label.anchor_left = info_backing.anchor_left + info_width * float(column[1])
		label.anchor_right = info_backing.anchor_left + info_width * float(column[2])
		label.offset_left = float(column[3])
		label.offset_right = -float(column[4])
		label.offset_top = 0.0
		label.offset_bottom = 0.0

	enter_stage_button.anchor_left = 0.090
	enter_stage_button.anchor_top = 0.580
	enter_stage_button.anchor_right = 0.910
	enter_stage_button.anchor_bottom = 0.730
	enter_stage_button.custom_minimum_size = Vector2(0.0, 76.0)

	stage_description_label.add_theme_font_size_override("font_size", 18)
	stage_status_label.add_theme_font_size_override("font_size", 17)
	stage_reward_label.add_theme_font_size_override("font_size", 17)
	stage_status_label.add_theme_color_override("font_color", Color("ded3e4"))
	stage_reward_label.add_theme_color_override("font_color", Color("f0cb68"))

	var stale_footer := $SafeArea/Layout/Content/MainTab.get_node_or_null(
		"StageFooterOrnament"
	)
	if stale_footer != null:
		stale_footer.get_parent().remove_child(stale_footer)
		stale_footer.free()


func _install_stage_selector_modal() -> void:
	var trigger_normal := _make_svg_style(
		UI_LOBBY_STAGE_ENTER_PATH,
		30.0,
		16.0,
		18.0,
		2.0
	)
	var trigger_pressed := _make_svg_style(
		UI_LOBBY_STAGE_ENTER_PRESSED_PATH,
		30.0,
		16.0,
		18.0,
		2.0
	)
	if trigger_normal != null:
		stage_selector_button.add_theme_stylebox_override("normal", trigger_normal)
		stage_selector_button.add_theme_stylebox_override("hover", trigger_normal)
	if trigger_pressed != null:
		stage_selector_button.add_theme_stylebox_override("pressed", trigger_pressed)
	stage_selector_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	stage_selector_button.add_theme_font_size_override("font_size", 25)
	stage_selector_button.add_theme_color_override("font_color", Color("fff0bd"))
	stage_selector_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	stage_selector_button.add_theme_color_override("font_pressed_color", Color("ffe080"))

	var modal_style := _make_svg_style(
		UI_MODAL_PANEL_PATH,
		34.0,
		34.0,
		18.0,
		18.0
	)
	if modal_style != null:
		stage_select_panel.add_theme_stylebox_override("panel", modal_style)
	else:
		stage_select_panel.add_theme_stylebox_override("panel", header_style)

	stage_select_close_button.add_theme_stylebox_override(
		"normal",
		secondary_button_style
	)
	stage_select_close_button.add_theme_stylebox_override(
		"hover",
		primary_button_style
	)
	stage_select_close_button.add_theme_stylebox_override(
		"pressed",
		primary_button_style
	)
	stage_select_close_button.add_theme_stylebox_override(
		"focus",
		StyleBoxEmpty.new()
	)

	stage_selector_item_style = _make_hud_panel_style(
		Color("100d1e"),
		Color("8b4aa3"),
		3,
		10
	)
	stage_selector_current_style = _make_hud_panel_style(
		Color("5b2472"),
		Color("ffd04f"),
		4,
		10
	)
	stage_selector_disabled_style = _make_hud_panel_style(
		Color("17131e"),
		Color("4a3c50"),
		2,
		10
	)


func _apply_lobby_visual_polish() -> void:
	# Keep the 1080x1920 logical layout intact and only refine presentation.
	# This makes the pass safe for the existing 540x960 window override and
	# avoids changing touch targets or tab behavior.
	_install_lobby_background()
	_install_stage_entry_hud()
	_install_stage_selector_modal()

	var background := $Background as ColorRect
	var backdrop_glow := $BackdropGlow as ColorRect
	background.color = Color(0.025, 0.018, 0.04, 0.43)
	backdrop_glow.color = Color(0.19, 0.08, 0.28, 0.12)
	backdrop_glow.anchor_bottom = 0.72

	var safe_area := $SafeArea as MarginContainer
	safe_area.add_theme_constant_override("margin_left", 28)
	safe_area.add_theme_constant_override("margin_right", 28)

	var header := $SafeArea/Layout/Header as PanelContainer
	header.custom_minimum_size = Vector2(0.0, 206.0)

	var layout := $SafeArea/Layout as VBoxContainer
	layout.add_theme_constant_override("separation", 10)

	var bottom_nav := $BottomNav as PanelContainer
	bottom_nav.offset_left = 18.0
	bottom_nav.offset_right = -18.0

	var nav_margin := $BottomNav/NavMargin as MarginContainer
	nav_margin.add_theme_constant_override("margin_left", 34)
	nav_margin.add_theme_constant_override("margin_top", 22)
	nav_margin.add_theme_constant_override("margin_right", 34)
	nav_margin.add_theme_constant_override("margin_bottom", 24)

	var nav_buttons := $BottomNav/NavMargin/NavButtons as HBoxContainer
	nav_buttons.add_theme_constant_override("separation", 8)

	resource_label.add_theme_font_size_override("font_size", 20)
	resource_label.add_theme_color_override("font_color", Color("f5d16d"))
	resource_label.remove_theme_stylebox_override("normal")
	progress_label.add_theme_font_size_override("font_size", 19)
	progress_label.add_theme_color_override("font_color", Color("ded1e4"))
	progress_label.remove_theme_stylebox_override("normal")

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox/SectionTitle",
		38,
		Color("f7edf8")
	)
	_set_lobby_label_style(
		^"SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox/SectionSubtitle",
		23,
		Color("9f91aa")
	)
	stage_selector_button.add_theme_font_size_override("font_size", 25)
	stage_selector_button.add_theme_color_override("font_color", Color("fff0bd"))
	stage_selector_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	stage_selector_button.add_theme_color_override("font_pressed_color", Color("ffe080"))
	stage_name_label.add_theme_font_size_override("font_size", 40)
	stage_name_label.add_theme_color_override("font_color", Color("fff6e5"))
	hero_name_label.add_theme_font_size_override("font_size", 30)
	hero_name_label.add_theme_color_override("font_color", Color("f2d486"))
	stage_description_label.add_theme_font_size_override("font_size", 18)
	stage_description_label.add_theme_color_override("font_color", Color("eee7f0"))
	stage_status_label.add_theme_font_size_override("font_size", 17)
	stage_status_label.add_theme_color_override("font_color", Color("d6cadc"))
	stage_reward_label.add_theme_font_size_override("font_size", 17)
	stage_reward_label.add_theme_color_override("font_color", Color("e6c66d"))
	_apply_enter_stage_button_skin()

	_apply_shop_storefront_skin()

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/TeamTab/TeamLayout/Title",
		40,
		Color("ffe7a3")
	)
	var team_title_plate := (
		$SafeArea/Layout/Content/TeamTab/TitlePlate as Panel
	)
	var title_frames = preload("res://src/ui/commerce_frame_skin.gd")
	team_title_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	team_title_plate.add_theme_stylebox_override("panel", title_frames.style("shop_featured_frame", 8))
	$SafeArea/Layout/Content/TeamTab/TeamLayout.offset_top = 27.0

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/TeamTab/TeamLayout/Guide",
		23,
		Color("aa9bb4")
	)
	_set_lobby_label_style(
		^"SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/ListTitle",
		28,
		Color("ead8ef")
	)
	team_summary_label.add_theme_color_override("font_color", Color("d8c7de"))
	team_status_label.add_theme_color_override("font_color", Color("918799"))
	for slot_button in [team_slot_1_button, team_slot_2_button, team_slot_3_button]:
		_apply_lobby_button_skin(slot_button, false, 20)
	_apply_lobby_button_skin(team_mode_button, true, 23)
	_apply_lobby_button_skin(skill_mode_button, false, 23)
	_refresh_formation_cost_sort_buttons()
	_team_formation_view.apply(self)
	transcendence_view.install(self)

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/ResearchTab/ResearchLayout/Title",
		40,
		Color("ffe7a3")
	)
	var research_title_plate := (
		$SafeArea/Layout/Content/ResearchTab/TitlePlate as Panel
	)
	research_title_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	research_title_plate.add_theme_stylebox_override("panel", title_frames.style("shop_featured_frame", 8))
	$SafeArea/Layout/Content/ResearchTab/ResearchLayout.offset_top = 27.0

	research_points_label.add_theme_font_size_override("font_size", 28)
	research_points_label.add_theme_color_override("font_color", Color("f3cf72"))
	research_status_label.add_theme_color_override("font_color", Color("918799"))
	var research_detail_style := _make_hud_panel_style(
		Color(0.055, 0.040, 0.075, 0.97),
		Color("c99136"),
		3,
		18
	)
	var relic_detail_style := _make_hud_panel_style(
		Color(0.050, 0.038, 0.070, 0.97),
		Color("8d629d"),
		3,
		18
	)
	research_detail_panel.add_theme_stylebox_override("panel", research_detail_style)
	relic_detail_panel.add_theme_stylebox_override("panel", relic_detail_style)
	var relic_icon_panel := relic_detail_icon.get_parent() as PanelContainer
	relic_icon_panel.add_theme_stylebox_override(
		"panel",
		_make_hud_panel_style(Color("100b17"), Color("a77cbd"), 2, 14)
	)
	_apply_lobby_button_skin(research_mode_button, true, 22)
	_apply_lobby_button_skin(relic_mode_button, false, 22)
	_apply_lobby_button_skin(research_upgrade_button, true, 22)
	_apply_lobby_button_skin(relic_upgrade_button, true, 21)
	for filter_button in relic_filter_buttons:
		_apply_lobby_button_skin(filter_button, false, 18)

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/Title",
		40,
		Color("fff4dd")
	)
	_set_lobby_label_style(
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/SettingsPanel/AudioTitle",
		28,
		Color("ead8ef")
	)
	_set_lobby_label_style(
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/AccountPanel/AccountTitle",
		28,
		Color("ead8ef")
	)

	_apply_lobby_button_skin(other_settings_tab_button, true, 24)
	other_settings_tab_button.add_theme_stylebox_override("disabled", primary_button_style)
	other_settings_tab_button.add_theme_color_override(
		"font_disabled_color",
		Color("ffe7a8")
	)
	_apply_lobby_button_skin(other_account_tab_button, false, 24)

	for raw_path in [
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/AccountPanel/KakaoLogin",
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/AccountPanel/GoogleLogin",
		^"SafeArea/Layout/Content/OtherTab/OtherMargin/VBox/AccountPanel/AppLogin",
	]:
		var login_button := get_node_or_null(raw_path) as Button
		_apply_lobby_button_skin(login_button, false, 24)

	for nav_button in [
		shop_button,
		team_button,
		main_button,
		research_button,
		other_button,
	]:
		nav_button.custom_minimum_size = Vector2(0.0, 120.0)
		nav_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	for icon_data in [
		[shop_button, UI_LOBBY_NAV_SHOP_ICON_PATH],
		[team_button, UI_LOBBY_NAV_TEAM_ICON_PATH],
		[main_button, UI_LOBBY_NAV_MAIN_ICON_PATH],
		[research_button, UI_LOBBY_NAV_RESEARCH_ICON_PATH],
		[other_button, UI_LOBBY_NAV_OTHER_ICON_PATH],
	]:
		_install_nav_button_icon(
			icon_data[0] as Button,
			String(icon_data[1])
		)


func _install_nav_button_icon(button: Button, icon_path: String) -> void:
	if button == null:
		return
	var old_icon := button.get_node_or_null("NavIcon")
	if old_icon != null:
		button.remove_child(old_icon)
		old_icon.free()

	var icon_texture := _load_svg_texture_direct(icon_path)
	if icon_texture == null:
		return
	var icon := TextureRect.new()
	icon.name = "NavIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = icon_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_left = 0.5
	icon.anchor_top = 0.0
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.0
	icon.offset_left = -24.0
	icon.offset_top = 24.0
	icon.offset_right = 24.0
	icon.offset_bottom = 68.0
	icon.z_index = 2
	button.add_child(icon)


func _apply_arrow_texture(button: Button, texture: Texture2D, flip_h: bool) -> void:
	if button == null:
		return

	button.text = ""
	# ArrowSkin owns the artwork in every state; native button boxes must stay clear.
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)

	var old := button.get_node_or_null("ArrowSkin")
	if old != null:
		old.queue_free()

	var skin := TextureRect.new()
	skin.name = "ArrowSkin"
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.texture = texture
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skin.offset_left = 2.0
	skin.offset_top = 4.0
	skin.offset_right = -2.0
	skin.offset_bottom = -4.0
	skin.flip_h = flip_h
	button.add_child(skin)


func _input(event: InputEvent) -> void:
	if is_instance_valid(_transcendence_entry_confirm) and _transcendence_entry_confirm.visible:
		_stage_swipe_active = false
		if event.is_action_pressed("ui_cancel"):
			_transcendence_entry_confirm.hide()
			get_viewport().set_input_as_handled()
		return
	if TutorialFlow.blocks_input(event):
		return
	if stamina_view != null and stamina_view.handle_info_input(event):
		get_viewport().set_input_as_handled()
		return
	if main_modes_view != null and is_instance_valid(main_modes_view.unlock_feedback):
		return
	if TutorialFlow.modal_visible:
		return
	if (
		is_instance_valid(gacha_reveal_overlay)
		and gacha_reveal_overlay.is_presenting()
	):
		_shop_scroll_touch_index = -1
		_stage_swipe_active = false
		if event.is_action_pressed("ui_cancel"):
			gacha_reveal_overlay.skip_to_results()
		return
	if shop_rates_overlay.visible:
		_shop_scroll_touch_index = -1
		_stage_swipe_active = false
		if event.is_action_pressed("ui_cancel"):
			_close_shop_rates_modal()
		return
	if shop_result_overlay.visible:
		_shop_scroll_touch_index = -1
		_stage_swipe_active = false
		if event.is_action_pressed("ui_cancel"):
			_close_shop_result_modal()
		return

	if monster_detail_overlay.visible:
		_handle_monster_detail_touch_scroll(event)
		return
	_handle_shop_touch_scroll(event)

	if stage_select_overlay.visible:
		_stage_swipe_active = false
		if event.is_action_pressed("ui_cancel"):
			_close_stage_selector()
		return
	if current_tab != "main" or stage_card == null:
		_stage_swipe_active = false
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if stage_card.get_global_rect().has_point(event.position):
				_stage_swipe_active = true
				_stage_swipe_start = event.position
		elif _stage_swipe_active:
			_try_stage_swipe(event.position)
			_stage_swipe_active = false
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			if stage_card.get_global_rect().has_point(event.position):
				_stage_swipe_active = true
				_stage_swipe_start = event.position
		elif _stage_swipe_active:
			_try_stage_swipe(event.position)
			_stage_swipe_active = false


func _handle_shop_touch_scroll(event: InputEvent) -> void:
	if (
		current_tab != "shop"
		or not is_instance_valid(shop_tab)
		or not shop_tab.visible
		or not is_instance_valid(shop_scroll)
	):
		_shop_scroll_touch_index = -1
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if shop_scroll.get_global_rect().has_point(event.position):
				_shop_scroll_touch_index = event.index
			else:
				_shop_scroll_touch_index = -1
		elif event.index == _shop_scroll_touch_index:
			_shop_scroll_touch_index = -1
		return

	if (
		event is InputEventScreenDrag
		and event.index == _shop_scroll_touch_index
	):
		shop_scroll.scroll_vertical -= int(round(event.relative.y))


func _handle_monster_detail_touch_scroll(event: InputEvent) -> void:
	var scroll := $MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll as ScrollContainer
	if event is InputEventScreenTouch:
		if event.pressed:
			if _detail_scroll_touch_index < 0 and scroll.get_global_rect().has_point(event.position):
				_detail_scroll_touch_index = event.index
				_detail_scroll_position = float(scroll.scroll_vertical)
				scroll.scroll_vertical = scroll.scroll_vertical
				get_viewport().set_input_as_handled()
		elif event.index == _detail_scroll_touch_index:
			_detail_scroll_touch_index = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _detail_scroll_touch_index:
		var bar := scroll.get_v_scroll_bar()
		_detail_scroll_position = clampf(_detail_scroll_position - event.relative.y, 0.0, maxf(bar.max_value - bar.page, 0.0))
		scroll.scroll_vertical = int(round(_detail_scroll_position))
		get_viewport().set_input_as_handled()
	elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		# Raw touch owns this region. Its emulated mouse must not scroll twice.
		if _detail_scroll_touch_index >= 0 or scroll.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()


func _try_stage_swipe(end_position: Vector2) -> void:
	var delta := end_position - _stage_swipe_start
	if absf(delta.x) < STAGE_SWIPE_THRESHOLD:
		return
	if absf(delta.x) <= absf(delta.y):
		return
	_change_stage(1 if delta.x < 0.0 else -1)


func _connect_navigation() -> void:
	# Only intentional navigation/selection controls opt into quiet feedback.
	for button in [shop_button, team_button, main_button, research_button, other_button, other_settings_tab_button, other_account_tab_button, research_mode_button, relic_mode_button, prev_stage_button, next_stage_button, stage_selector_button, enter_stage_button, team_mode_button, skill_mode_button]:
		button.set_meta("audio_cue", "click")
	shop_button.pressed.connect(_switch_tab.bind("shop"))
	team_button.pressed.connect(_on_team_tab_pressed)
	main_button.pressed.connect(_switch_tab.bind("main"))
	research_button.pressed.connect(_switch_tab.bind("research"))
	other_button.pressed.connect(_switch_tab.bind("other"))

	other_settings_tab_button.pressed.connect(_show_other_settings)
	other_account_tab_button.pressed.connect(_show_other_account)
	research_mode_button.pressed.connect(_show_research_mode.bind("research"))
	relic_mode_button.pressed.connect(_show_research_mode.bind("relic"))
	research_upgrade_button.pressed.connect(_purchase_selected_research)
	relic_upgrade_button.pressed.connect(_show_relic_upgrade_placeholder)
	var relic_categories: Array[String] = RELIC_CATALOG.CATEGORY_ORDER
	for index in range(mini(relic_filter_buttons.size(), relic_categories.size())):
		relic_filter_buttons[index].pressed.connect(
			_select_relic_category.bind(relic_categories[index])
		)
	bgm_slider.value_changed.connect(_on_bgm_level_changed)
	sfx_slider.value_changed.connect(_on_sfx_level_changed)
	bgm_mute_check.toggled.connect(_on_bgm_mute_toggled)
	sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	_sync_audio_settings_ui()

	prev_stage_button.pressed.connect(_change_stage.bind(-1))
	next_stage_button.pressed.connect(_change_stage.bind(1))
	stage_selector_button.pressed.connect(_open_stage_selector)
	stage_select_close_button.pressed.connect(_close_stage_selector)
	$StageSelectOverlay/Dim.gui_input.connect(_on_stage_selector_dim_input)
	enter_stage_button.pressed.connect(_enter_selected_stage)

	shop_single_button.get_node("SummonButton").connect(
		"confirmed", _open_monster_boxes.bind(1)
	)
	shop_multi_button.get_node("SummonButton").connect(
		"confirmed", _open_monster_boxes.bind(SHOP_CATALOG.MULTI_DRAW_COUNT)
	)
	shop_relic_single_button.pressed.connect(
		_show_shop_placeholder.bind("유물 소환 시스템은 아직 준비 중입니다.")
	)
	shop_relic_multi_button.pressed.connect(
		_show_shop_placeholder.bind("유물 10+1 소환 시스템은 아직 준비 중입니다.")
	)
	shop_banner_prev_button.pressed.connect(_change_shop_banner.bind(-1))
	shop_banner_next_button.pressed.connect(_change_shop_banner.bind(1))
	shop_history_button.pressed.connect(_show_shop_result_modal)
	shop_rates_button.pressed.connect(_show_shop_rates_modal)
	shop_result_close_button.pressed.connect(_close_shop_result_modal)
	$ShopResultOverlay/Dim.gui_input.connect(_on_shop_result_dim_input)
	shop_rates_close_button.pressed.connect(_close_shop_rates_modal)
	$ShopRatesOverlay/Dim.gui_input.connect(_on_shop_rates_dim_input)

	team_slot_1_button.pressed.connect(_on_team_slot_pressed.bind(0))
	team_slot_2_button.pressed.connect(_on_team_slot_pressed.bind(1))
	team_slot_3_button.pressed.connect(_on_team_slot_pressed.bind(2))
	for slot_button in [team_slot_1_button, team_slot_2_button, team_slot_3_button]:
		slot_button.connect("formation_item_dropped", _on_formation_item_dropped)
	team_mode_button.pressed.connect(_show_formation_mode.bind("team"))
	skill_mode_button.pressed.connect(_show_formation_mode.bind("skill"))
	formation_cost_low_button.pressed.connect(
		_on_formation_cost_sort_selected.bind(false)
	)
	formation_cost_high_button.pressed.connect(
		_on_formation_cost_sort_selected.bind(true)
	)
	var criteria := $SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/SortCriteria
	criteria.get_node("CostButton").pressed.connect(_on_formation_sort_criterion_selected.bind("cost"))
	criteria.get_node("RarityButton").pressed.connect(_on_formation_sort_criterion_selected.bind("rarity"))
	var unlock_filters := $SafeArea/Layout/Content/TeamTab/TeamLayout/UnlockFilters
	for pair in [["AllButton", "all"], ["UnlockedButton", "unlocked"], ["LockedButton", "locked"]]:
		unlock_filters.get_node(pair[0]).pressed.connect(_on_formation_unlock_filter_selected.bind(pair[1]))
	monster_detail_close_button.pressed.connect(_close_monster_detail)
	_ignore_monster_detail_content_input($MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare)
	$MonsterDetailOverlay/Dim.gui_input.connect(_on_monster_detail_dim_input)


func _setup_gacha_reveal_overlay() -> void:
	if is_instance_valid(gacha_reveal_overlay):
		return
	gacha_reveal_overlay = GACHA_REVEAL_OVERLAY.new()
	gacha_reveal_overlay.name = "GachaRevealOverlay"
	add_child(gacha_reveal_overlay)
	gacha_reveal_overlay.retry_requested.connect(_retry_monster_boxes)
	gacha_reveal_overlay.confirmed.connect(func():
		if TutorialFlow.step == "draw_done" and TutorialFlow.locks_lobby():
			TutorialFlow.draw_presented())


func _on_team_tab_pressed() -> void:
	if not TutorialFlow.permits_tab("team"):
		return
	current_tab = "team"
	_refresh_header()
	formation_mode = "team"
	_close_monster_detail()
	_close_shop_result_modal()
	_close_shop_rates_modal()

	shop_tab.hide()
	team_tab.show()
	main_tab.hide()
	research_tab.hide()
	other_tab.hide()

	_setup_team_preview()
	_setup_demon_skill_preview()
	_refresh_formation_mode()

	_refresh_nav_button(shop_button, false)
	_refresh_nav_button(team_button, true)
	_refresh_nav_button(main_button, false)
	_refresh_nav_button(research_button, false)
	_refresh_nav_button(other_button, false)

func _switch_tab(tab_id: String) -> void:
	if stamina_view != null:
		stamina_view.close_info()
	if not TutorialFlow.permits_tab(tab_id):
		return
	current_tab = tab_id
	if tab_id != "shop":
		_shop_scroll_touch_index = -1
		_reset_shop_banner_motion()
		_close_shop_result_modal()
		_close_shop_rates_modal()

	shop_tab.visible = tab_id == "shop"
	team_tab.visible = tab_id == "team"
	main_tab.visible = tab_id == "main"
	research_tab.visible = tab_id == "research"
	other_tab.visible = tab_id == "other"

	if tab_id == "shop":
		_rebuild_shop_list()
	elif tab_id == "research":
		_rebuild_research_list()
	elif tab_id == "other":
		_sync_audio_settings_ui()
		if settings_view != null:
			settings_view.show_menu()
		else:
			_show_other_settings()

	_refresh_nav_button(shop_button, tab_id == "shop")
	_refresh_nav_button(team_button, tab_id == "team")
	_refresh_nav_button(main_button, tab_id == "main")
	_refresh_nav_button(research_button, tab_id == "research")
	_refresh_nav_button(other_button, tab_id == "other")
	_refresh_header()

func _show_other_settings() -> void:
	if settings_view != null:
		settings_view.show_page("sound")
		return
	other_settings_panel.show()
	other_account_panel.hide()
	other_settings_tab_button.disabled = true
	other_account_tab_button.disabled = false
	_apply_lobby_button_skin(other_settings_tab_button, true, 24)
	_apply_lobby_button_skin(other_account_tab_button, false, 24)


func _show_other_account() -> void:
	if settings_view != null:
		settings_view.show_page("account")
		return
	other_settings_panel.hide()
	other_account_panel.show()
	other_settings_tab_button.disabled = false
	other_account_tab_button.disabled = true
	_apply_lobby_button_skin(other_settings_tab_button, false, 24)
	_apply_lobby_button_skin(other_account_tab_button, true, 24)
	other_account_tab_button.add_theme_stylebox_override("disabled", PIXEL_PANEL_SKIN.button_style(primary_button_style))
	other_account_tab_button.add_theme_color_override(
		"font_disabled_color",
		Color("ffe7a8")
	)


func _sync_audio_settings_ui() -> void:
	bgm_slider.set_value_no_signal(float(AudioSettings.bgm_level))
	sfx_slider.set_value_no_signal(float(AudioSettings.sfx_level))
	bgm_mute_check.set_pressed_no_signal(AudioSettings.bgm_muted)
	sfx_mute_check.set_pressed_no_signal(AudioSettings.sfx_muted)
	bgm_value_label.text = str(AudioSettings.bgm_level)
	sfx_value_label.text = str(AudioSettings.sfx_level)


func _on_bgm_level_changed(value: float) -> void:
	var level := int(round(value))
	bgm_value_label.text = str(level)
	AudioSettings.set_bgm_level(level)


func _on_sfx_level_changed(value: float) -> void:
	var level := int(round(value))
	sfx_value_label.text = str(level)
	AudioSettings.set_sfx_level(level)


func _on_bgm_mute_toggled(enabled: bool) -> void:
	AudioSettings.set_bgm_muted(enabled)


func _on_sfx_mute_toggled(enabled: bool) -> void:
	AudioSettings.set_sfx_muted(enabled)


func _refresh_nav_button(button: Button, selected: bool) -> void:
	var style := PIXEL_PANEL_SKIN.button_style(nav_button_active_style if selected else nav_button_style)
	if style is StyleBoxFlat:
		style.bg_color = Color("523068") if selected else Color("281832")
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_font_size_override("font_size", 27 if selected else 23)
	button.add_theme_color_override(
		"font_color",
		Color("ffe7a8") if selected else Color("c9bfce")
	)
	button.add_theme_color_override(
		"font_hover_color",
		Color("fff1c7") if selected else Color("eee7f2")
	)
	button.add_theme_color_override("font_outline_color", Color("100b18"))
	button.add_theme_constant_override("outline_size", 3 if selected else 2)
	var icon := button.get_node_or_null("NavIcon") as TextureRect
	if icon != null:
		icon.modulate = Color.WHITE if selected else Color("b7adc2")


func _apply_shop_storefront_skin() -> void:
	var title_plate := $SafeArea/Layout/Content/ShopTab/TitlePlate as Panel
	var title_plate_style := _make_style(
		Color("171020"),
		Color("c99136"),
		3,
		18
	)
	title_plate_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	title_plate_style.shadow_size = 8
	title_plate_style.shadow_offset = Vector2(0.0, 4.0)
	title_plate.add_theme_stylebox_override("panel", title_plate_style)

	var banner_style := _make_hud_panel_style(
		Color("25122f"),
		Color("d3a043"),
		3,
		18
	)
	banner_style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	banner_style.shadow_size = 8
	banner_style.shadow_offset = Vector2(0.0, 4.0)

	var balance_style := _make_hud_panel_style(
		Color(0.055, 0.040, 0.075, 0.94),
		Color(0.47, 0.35, 0.55, 0.92),
		2,
		12
	)
	var summon_style := _make_hud_panel_style(
		Color(0.075, 0.047, 0.092, 0.96),
		Color(0.75, 0.55, 0.23, 0.95),
		3,
		18
	)
	var relic_style := _make_hud_panel_style(
		Color(0.050, 0.041, 0.064, 0.96),
		Color(0.34, 0.30, 0.38, 0.92),
		2,
		18
	)
	var package_style := _make_hud_panel_style(
		Color(0.050, 0.037, 0.068, 0.96),
		Color(0.45, 0.34, 0.52, 0.95),
		2,
		18
	)
	for data in [
		[
			^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BalancePanel",
			balance_style,
		],
		[
			^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/BannerPanel",
			banner_style,
		],
		[
			^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/MonsterSection",
			summon_style,
		],
		[
			^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/RelicSection",
			relic_style,
		],
		[
			^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/PackageSection",
			package_style,
		],
	]:
		var panel := get_node_or_null(data[0]) as PanelContainer
		if panel != null:
			panel.add_theme_stylebox_override("panel", data[1] as StyleBox)

	_set_lobby_label_style(
		^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/Title",
		40,
		Color("fff4dd")
	)
	_set_lobby_label_style(
		^"SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/Guide",
		21,
		Color("aa9bb4")
	)
	shop_gold_label.add_theme_color_override("font_color", Color("f4cf68"))
	shop_research_points_label.add_theme_color_override(
		"font_color",
		Color("d5a9ef")
	)
	shop_status_label.add_theme_color_override("font_color", Color("918799"))

	var badge_style := _make_hud_panel_style(
		Color("4c293f"),
		Color("d6a64c"),
		1,
		8
	)
	shop_banner_badge.add_theme_stylebox_override("normal", badge_style)
	shop_banner_badge.add_theme_constant_override("outline_size", 2)
	shop_banner_badge.add_theme_color_override(
		"font_outline_color",
		Color("160d1b")
	)

	_apply_lobby_button_skin(shop_banner_prev_button, false, 24)
	_apply_lobby_button_skin(shop_banner_next_button, false, 24)
	_apply_lobby_button_skin(shop_single_button, false, 23)
	_apply_lobby_button_skin(shop_multi_button, true, 23)
	_apply_lobby_button_skin(shop_history_button, false, 21)
	_apply_lobby_button_skin(shop_rates_button, false, 21)
	_apply_lobby_button_skin(shop_relic_single_button, false, 23)
	_apply_lobby_button_skin(shop_relic_multi_button, false, 23)
	shop_relic_single_button.add_theme_stylebox_override(
		"disabled",
		secondary_button_disabled_style
	)
	shop_relic_multi_button.add_theme_stylebox_override(
		"disabled",
		secondary_button_disabled_style
	)

	var result_modal_style := _make_hud_panel_style(
		Color(0.045, 0.035, 0.060, 0.98),
		Color("c99843"),
		3,
		20
	)
	shop_result_panel.add_theme_stylebox_override("panel", result_modal_style)
	_apply_lobby_button_skin(shop_result_close_button, false, 22)
	shop_rates_panel.add_theme_stylebox_override("panel", result_modal_style)
	_apply_lobby_button_skin(shop_rates_close_button, false, 22)
	$ShopRatesOverlay/Panel/Margin/VBox/RatesPanel.add_theme_stylebox_override(
		"panel",
		preload("res://src/ui/shop_frame_skin.gd").plain_content_style(14)
	)
	_shop_storefront_art.apply(self)
	_shop_pickup_view.install(self)
	_shop_test_draw_view.install(self)
	shop_popup_view.install(self)


func _tick_shop_banner(delta: float) -> void:
	if (
		current_tab != "shop"
		or not is_instance_valid(shop_tab)
		or not shop_tab.visible
		or shop_result_overlay.visible
		or shop_rates_overlay.visible
		or _shop_banner_transitioning
		or SHOP_CATALOG.get_banner_count() <= 1
	):
		return
	shop_banner_timer = maxf(shop_banner_timer - delta, 0.0)
	if shop_banner_timer > 0.0:
		return
	_change_shop_banner(1)


func _change_shop_banner(direction: int) -> void:
	var count := SHOP_CATALOG.get_banner_count()
	if count <= 0 or _shop_banner_transitioning:
		return
	var next_index := (
		((shop_banner_index + direction) % count) + count
	) % count
	shop_banner_timer = SHOP_BANNER_AUTO_SECONDS
	if next_index == shop_banner_index:
		return

	_shop_banner_transitioning = true
	var slide_direction := 1 if direction >= 0 else -1
	_shop_banner_tween = create_tween()
	_shop_banner_tween.set_trans(Tween.TRANS_QUAD)
	_shop_banner_tween.set_ease(Tween.EASE_IN)
	_shop_banner_tween.tween_property(
		shop_banner_slide,
		"position",
		Vector2(-slide_direction * SHOP_BANNER_SLIDE_DISTANCE, 0.0),
		SHOP_BANNER_SLIDE_OUT_SECONDS
	)
	_shop_banner_tween.parallel().tween_property(
		shop_banner_slide,
		"modulate:a",
		0.0,
		SHOP_BANNER_SLIDE_OUT_SECONDS
	)
	_shop_banner_tween.tween_callback(
		Callable(self, "_prepare_shop_banner_slide_in").bind(
			next_index,
			slide_direction
		)
	)
	_shop_banner_tween.set_ease(Tween.EASE_OUT)
	_shop_banner_tween.tween_property(
		shop_banner_slide,
		"position",
		Vector2.ZERO,
		SHOP_BANNER_SLIDE_IN_SECONDS
	)
	_shop_banner_tween.parallel().tween_property(
		shop_banner_slide,
		"modulate:a",
		1.0,
		SHOP_BANNER_SLIDE_IN_SECONDS
	)
	_shop_banner_tween.finished.connect(_finish_shop_banner_slide)


func _prepare_shop_banner_slide_in(
	next_index: int,
	direction: int
) -> void:
	shop_banner_index = next_index
	_refresh_shop_banner()
	shop_banner_slide.position = Vector2(
		direction * SHOP_BANNER_SLIDE_DISTANCE,
		0.0
	)


func _finish_shop_banner_slide() -> void:
	shop_banner_slide.position = Vector2.ZERO
	shop_banner_slide.modulate.a = 1.0
	_shop_banner_transitioning = false


func _reset_shop_banner_motion() -> void:
	if _shop_banner_tween != null and _shop_banner_tween.is_valid():
		_shop_banner_tween.kill()
	_shop_banner_transitioning = false
	shop_banner_slide.position = Vector2.ZERO
	shop_banner_slide.modulate.a = 1.0


func _refresh_shop_banner() -> void:
	var count := SHOP_CATALOG.get_banner_count()
	if count <= 0:
		shop_banner_badge.text = "NOTICE"
		shop_banner_title.text = "상점 준비 중"
		shop_banner_description.text = "표시할 상점 배너가 없습니다."
		shop_banner_footer.text = ""
		shop_banner_dots.text = ""
		return

	shop_banner_index = (
		(shop_banner_index % count) + count
	) % count
	var data := SHOP_CATALOG.get_banner(shop_banner_index)
	_shop_storefront_art.refresh_banner(data)
	shop_banner_badge.text = String(data.get("badge", "EVENT"))
	shop_banner_title.text = String(data.get("title", "마왕 상점"))
	shop_banner_description.text = String(data.get("description", ""))
	shop_banner_footer.text = String(data.get("footer", ""))

	var dots := PackedStringArray()
	for index in range(count):
		dots.append("◆" if index == shop_banner_index else "◇")
	shop_banner_dots.text = "  ".join(dots)


func _rebuild_shop_packages() -> void:
	for child in shop_package_grid.get_children():
		shop_package_grid.remove_child(child)
		child.free()

	for raw_data in SHOP_CATALOG.get_packages():
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = raw_data
		var button := Button.new()
		var featured := bool(data.get("featured", false))
		var enabled := bool(data.get("enabled", false))
		var emphasized := enabled and featured
		button.custom_minimum_size = Vector2(0.0, 148.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = (
			Control.MOUSE_FILTER_STOP
			if enabled
			else Control.MOUSE_FILTER_IGNORE
		)
		button.text = "%s  %s\n%s\n%s" % [
			String(data.get("badge", "PACKAGE")),
			String(data.get("title", "상품")),
			String(data.get("reward_text", "")),
			String(data.get("price_text", "준비 중")),
		]
		_apply_lobby_button_skin(button, emphasized, 20)
		button.disabled = not enabled
		button.add_theme_stylebox_override(
			"disabled",
			secondary_button_disabled_style
		)
		if enabled:
			button.pressed.connect(
				_on_shop_package_pressed.bind(
					String(data.get("id", ""))
				)
			)
		shop_package_grid.add_child(button)
		_shop_storefront_art.decorate_package(button, data)


func _on_shop_package_pressed(package_id: String) -> void:
	var data := SHOP_CATALOG.get_package(package_id)
	if data.is_empty():
		return
	shop_status_label.text = "%s · 실제 구매 시스템 연결 전입니다." % String(
		data.get("title", "패키지")
	)


func _show_shop_placeholder(message: String) -> void:
	shop_status_label.text = message


func _format_shop_number(value: int) -> String:
	var digits := str(maxi(value, 0))
	var result := ""
	var group_count := 0

	for index in range(digits.length() - 1, -1, -1):
		if group_count > 0 and group_count % 3 == 0:
			result = "," + result
		result = digits.substr(index, 1) + result
		group_count += 1

	return result

func _rebuild_shop_list() -> void:
	_shop_test_draw_view.refresh()
	_shop_pickup_view.refresh()
	shop_gold_label.text = "골드  %s" % _format_shop_number(
		_get_shop_gold()
	)
	shop_research_points_label.text = "연구 포인트  %s" % _format_shop_number(
		STAGE_PROGRESS.get_research_points()
	)
	shop_single_button.text = "몬스터 소환 1회\n%s 골드" % _format_shop_number(
		SHOP_CATALOG.SINGLE_DRAW_COST
	)
	shop_multi_button.text = "추천 · 몬스터 소환 10+1회\n%s 골드" % _format_shop_number(
		SHOP_CATALOG.MULTI_DRAW_COST
	)
	_shop_storefront_art.set_product_copy(shop_single_button, shop_single_button.text)
	_shop_storefront_art.set_product_copy(
		shop_multi_button,
		"몬스터 소환 10+1회\n%s 골드" % _format_shop_number(SHOP_CATALOG.MULTI_DRAW_COST)
	)
	shop_relic_single_button.text = "유물 소환 1회\n준비 중"
	shop_relic_multi_button.text = "유물 소환 10+1회\n준비 중"

	shop_rates_text.text = _build_shop_rate_text()
	shop_status_label.text = "로컬 테스트 · 골드 차감 없음" if LocalTestMode.active else "소환 비용만큼 골드가 사용됩니다."
	shop_history_button.disabled = shop_last_result_text.is_empty()
	shop_history_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if shop_history_button.disabled
		else Control.MOUSE_FILTER_STOP
	)
	_reset_shop_banner_motion()
	shop_banner_timer = SHOP_BANNER_AUTO_SECONDS
	_refresh_shop_banner()
	_rebuild_shop_packages()


func _build_shop_rate_text(pickup_id: String = "") -> String:
	var lines := PackedStringArray()
	if not pickup_id.is_empty():
		lines.append("픽업: %s · 초월 내 가중치 3배\n초월 등급 확률 0.5%%는 일반 소환과 같습니다." % MONSTER_CATALOG.get_monster_name(pickup_id))
	for rarity in SHOP_CATALOG.RARITY_ORDER:
		var probability := SHOP_CATALOG.get_effective_probability(rarity)
		var data := SHOP_CATALOG.get_rarity(rarity)
		lines.append("%s %.3f%% · 조각 %d~%d" % [SHOP_CATALOG.get_rarity_label(rarity), probability, data.get("shard_min", 1), data.get("shard_max", 1)])
		for id in SHOP_CATALOG.get_monster_pool(rarity):
			lines.append("  %s %.3f%%" % [MONSTER_CATALOG.get_monster_name(id), SHOP_CATALOG.get_monster_probability(id, pickup_id)])
		if bool(data.get("unlock_on_first_draw", false)):
			lines.append("첫 획득 즉시 해금 · 이후 조각 지급")
	return "\n".join(lines)


func _show_shop_result_modal() -> void:
	if shop_last_result_text.is_empty():
		return
	_close_shop_rates_modal()
	shop_result_label.text = shop_last_result_text
	shop_popup_view.show_history(shop_summon_history)
	shop_result_overlay.show()


func _close_shop_result_modal() -> void:
	if is_instance_valid(shop_result_overlay):
		shop_result_overlay.hide()


func _show_shop_rates_modal(pickup_id: String = "") -> void:
	shop_rates_text.text = _build_shop_rate_text(pickup_id)
	shop_popup_view.show_rates(pickup_id)
	_close_shop_result_modal()
	shop_rates_overlay.show()


func _close_shop_rates_modal() -> void:
	if is_instance_valid(shop_rates_overlay):
		shop_rates_overlay.hide()


func _on_shop_result_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_shop_result_modal()
	elif event is InputEventScreenTouch and event.pressed:
		_close_shop_result_modal()


func _on_shop_rates_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_shop_rates_modal()
	elif event is InputEventScreenTouch and event.pressed:
		_close_shop_rates_modal()


func _refresh_shop_summon_history() -> void:
	var lines: PackedStringArray = []
	var display_number := 1
	for index in range(shop_summon_history.size() - 1, -1, -1):
		var entry = shop_summon_history[index]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var monster_id := String(entry.get("monster_id", ""))
		var rarity_id := String(entry.get("rarity", ""))
		var unlock_text := " · 신규 해금" if bool(entry.get("unlocked", false)) else ""
		var converted := int(entry.get("research_points", 0))
		if converted > 0:
			unlock_text += " → 연구 포인트 +%d" % converted
		lines.append(
			"%03d. %s [%s]  %s%s" % [
				display_number,
				_team_monster_name(monster_id),
				SHOP_CATALOG.get_rarity_label(rarity_id),
				"첫 획득" if bool(entry.get("first_draw_unlock", false)) else "+%d 조각" % maxi(int(entry.get("shards", 0)), 0),
				unlock_text,
			]
		)
		display_number += 1

	shop_last_result_text = "\n".join(lines)
	shop_result_label.text = (
		shop_last_result_text
		if not shop_last_result_text.is_empty()
		else "아직 소환 내역이 없습니다."
	)
	shop_history_button.disabled = shop_last_result_text.is_empty()
	shop_history_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if shop_history_button.disabled
		else Control.MOUSE_FILTER_STOP
	)


func _get_shop_gold() -> int:
	return SHOP_CATALOG.TEST_GOLD if LocalTestMode.active else STAGE_PROGRESS.get_gold()

func _refresh_shop_summon_buttons() -> void:
	_shop_test_draw_view.refresh()
	_shop_pickup_view.refresh()
	var gold := _get_shop_gold()
	for pair in [[shop_single_button, SHOP_CATALOG.SINGLE_DRAW_COST], [shop_multi_button, SHOP_CATALOG.MULTI_DRAW_COST]]:
		var button := pair[0].get_node_or_null("SummonButton") as Button
		if button == null:
			continue
		button.disabled = gold < int(pair[1])
		# Spending can disable the button while an emulated touch pointer is still
		# over it. A new tooltip then leaks onto the successful reveal overlay.
		button.tooltip_text = ""
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND


func _retry_monster_boxes(draw_count: int) -> void:
	_open_monster_boxes(draw_count, _shop_reveal_pickup_id)

func _open_monster_boxes(draw_count: int, pickup_id: String = "") -> void:
	if not pickup_id.is_empty():
		var pickup := preload("res://src/data/pickup_catalog.gd")
		if not pickup.can_draw() or pickup_id != String(pickup.current().get("monster_id", "")) or TutorialFlow.locks_lobby():
			return
	if TutorialFlow.locks_lobby() and (not TutorialFlow.tutorial_draw_pending() or draw_count != SHOP_CATALOG.MULTI_DRAW_COUNT):
		return
	if draw_count != 1 and draw_count != SHOP_CATALOG.MULTI_DRAW_COUNT:
		return
	if is_instance_valid(gacha_reveal_overlay) and gacha_reveal_overlay.is_presenting():
		return
	var cost: int = SHOP_CATALOG.SINGLE_DRAW_COST if draw_count == 1 else SHOP_CATALOG.MULTI_DRAW_COST
	if _get_shop_gold() < cost:
		_refresh_shop_summon_buttons()
		shop_status_label.text = "골드가 부족합니다."
		return

	var new_history_entries: Array = []
	var reveal_entries: Array = []
	var rolls: Array = []

	for _draw_index in range(draw_count):
		var roll := _roll_monster_shard(pickup_id)
		if roll.is_empty():
			shop_status_label.text = "소환 데이터 오류 · 보상은 지급되지 않았습니다."
			return
		rolls.append(roll)
	var batch := MONSTER_COLLECTION_STORE.award_shard_batch(rolls, 0 if LocalTestMode.active else cost, TutorialFlow.tutorial_draw_pending())
	if not bool(batch.get("success", false)):
		shop_status_label.text = "소환 보상 저장 실패 · 저장 공간을 확인해 주세요."
		return
	_shop_reveal_pickup_id = pickup_id
	monster_collection_state = batch.state
	for history_entry in batch.awards:
		var monster_id := String(history_entry.monster_id)
		new_history_entries.append(history_entry)
		var reveal_entry: Dictionary = history_entry.duplicate()
		reveal_entry["name"] = MONSTER_CATALOG.get_monster_name(monster_id)
		reveal_entry["icon"] = _team_monster_card_icon(monster_id)
		reveal_entries.append(reveal_entry)

	shop_summon_history = SHOP_SUMMON_HISTORY_STORE.append_entries(
		new_history_entries
	)
	_refresh_shop_summon_history()
	shop_status_label.text = "로컬 테스트 · 골드 차감 없음" if LocalTestMode.active else "%s 골드 사용" % _format_shop_number(cost)
	_refresh_header()
	if not reveal_entries.is_empty() and is_instance_valid(gacha_reveal_overlay):
		_close_shop_result_modal()
		_close_shop_rates_modal()
		gacha_reveal_overlay.configure_retry(draw_count, cost, _get_shop_gold)
		gacha_reveal_overlay.present(reveal_entries)
		if TutorialFlow.tutorial_draw_pending():
			gacha_reveal_overlay._skip_button.hide()
			gacha_reveal_overlay._retry_draw_count = 0
			TutorialFlow.draw_started()

func _roll_monster_shard(pickup_id: String = "") -> Dictionary:
	var forced_id: String = LocalTestMode.forced_gacha_monster(_shop_test_draw_view.selected_id)
	if TutorialFlow.locks_lobby():
		forced_id = ""
	var rarity_id := "transcendent" if not forced_id.is_empty() else _roll_shop_rarity()
	if rarity_id.is_empty():
		return {}

	var candidates := SHOP_CATALOG.get_monster_pool(rarity_id)

	if candidates.is_empty():
		return {}

	var selected_id := forced_id if not forced_id.is_empty() else SHOP_CATALOG.roll_monster(rarity_id, randf(), pickup_id)
	var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
	var min_shards := maxi(int(rarity_data.get("shard_min", 1)), 1)
	var max_shards := maxi(int(rarity_data.get("shard_max", min_shards)), min_shards)

	return {
		"monster_id": selected_id,
		"rarity": rarity_id,
		"shards": randi_range(min_shards, max_shards),
		"source": "pickup" if not pickup_id.is_empty() else "summon",
		"pickup_id": pickup_id,
	}

func _roll_shop_rarity() -> String:
	return SHOP_CATALOG.roll_rarity(randf())

func _setup_team_preview() -> void:
	team_catalog_ids.clear()
	team_available_ids.clear()
	team_selected_ids.clear()
	monster_collection_state = MONSTER_COLLECTION_STORE.load_state()
	_clear_team_monster_cards()

	team_status_label.text = "Catalog 원본 데이터 확인 중"

	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if not MONSTER_CATALOG.MONSTERS.has(monster_id):
			continue
		if TRANSCENDENCE_DATA.is_transcendent(monster_id):
			continue

		team_catalog_ids.append(monster_id)
		team_available_ids.append(monster_id)

		if team_selected_ids.size() < TEAM_MAX_SLOTS:
			team_selected_ids.append(monster_id)

	team_status_label.text = "Catalog %d종 확인" % team_catalog_ids.size()

	if team_catalog_ids.is_empty():
		team_summary_label.text = "등록된 몬스터 없음"
		team_status_label.text = "MonsterCatalog ORDER/MONSTERS에 등록된 몬스터가 없습니다."
		return

	_restore_saved_team_selection(false, monster_collection_state)


func _setup_demon_skill_preview() -> void:
	demon_skill_catalog_ids.clear()
	for raw_id in DEMON_ULTIMATES.get_ordered_ids():
		var skill_id := String(raw_id)
		var skill := DEMON_ULTIMATES.get_skill(skill_id)
		if skill.is_empty() or not bool(skill.get("implemented", false)):
			continue
		demon_skill_catalog_ids.append(skill_id)

	demon_skill_selected_ids = DEMON_SKILL_LOADOUT_STORE.load_ids(
		demon_skill_catalog_ids,
		demon_skill_catalog_ids
	)

func _restore_saved_team_selection(refresh: bool = true, saved_collection: Dictionary = {}) -> void:
	if saved_collection.is_empty():
		saved_collection = MONSTER_COLLECTION_STORE.load_state()
	var unlocked_ids := MONSTER_COLLECTION_STORE.get_unlocked_ids(
		saved_collection
	)

	if not unlocked_ids.is_empty():
		monster_collection_state = saved_collection
		team_available_ids.clear()
		for raw_id in unlocked_ids:
			if not TRANSCENDENCE_DATA.is_transcendent(String(raw_id)):
				team_available_ids.append(String(raw_id))

	var fallback_ids: Array = []
	for raw_id in team_selected_ids:
		var monster_id := String(raw_id)
		if monster_id not in team_available_ids:
			continue
		fallback_ids.append(monster_id)
		if fallback_ids.size() >= TEAM_MAX_SLOTS:
			break

	if fallback_ids.is_empty():
		for raw_id in team_available_ids:
			fallback_ids.append(String(raw_id))
			if fallback_ids.size() >= TEAM_MAX_SLOTS:
				break

	var saved_ids = TEAM_LOADOUT_STORE.load_ids(
		team_available_ids,
		fallback_ids
	)

	team_selected_ids.clear()
	for raw_id in saved_ids:
		team_selected_ids.append(String(raw_id))

	if refresh:
		_refresh_team_preview()
	if formation_mode == "team":
		team_status_label.text = "카드 터치: 상세정보 · 길게 누르기: 드래그 편성"


func _show_formation_mode(mode: String) -> void:
	if mode not in ["team", "skill", "transcendence"]:
		return
	formation_mode = mode
	_refresh_formation_mode()


func _on_formation_cost_sort_selected(descending: bool) -> void:
	if formation_cost_descending == descending:
		return
	formation_cost_descending = descending
	_refresh_formation_mode()


func _refresh_formation_cost_sort_buttons() -> void:
	var criteria := $SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader/SortCriteria
	criteria.visible = formation_mode == "team"
	_apply_lobby_button_skin(criteria.get_node("CostButton"), formation_sort_criterion == "cost", 19)
	_apply_lobby_button_skin(criteria.get_node("RarityButton"), formation_sort_criterion == "rarity", 19)
	_apply_lobby_button_skin(
		formation_cost_low_button,
		not formation_cost_descending,
		19
	)
	_apply_lobby_button_skin(
		formation_cost_high_button,
		formation_cost_descending,
		19
	)

func _on_formation_sort_criterion_selected(criterion: String) -> void:
	if criterion not in ["cost", "rarity"] or criterion == formation_sort_criterion:
		return
	formation_sort_criterion = criterion
	_refresh_formation_mode()
	($SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterScroll as ScrollContainer).scroll_vertical = 0


func _on_formation_unlock_filter_selected(filter_id: String) -> void:
	if filter_id not in ["all", "unlocked", "locked"] or formation_unlock_filter == filter_id:
		return
	formation_unlock_filter = filter_id
	_refresh_formation_mode()
	($SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterScroll as ScrollContainer).scroll_vertical = 0

func _refresh_formation_unlock_filters(showing_team: bool) -> void:
	var row := $SafeArea/Layout/Content/TeamTab/TeamLayout/UnlockFilters
	row.visible = showing_team
	for pair in [["AllButton", "all"], ["UnlockedButton", "unlocked"], ["LockedButton", "locked"]]:
		_apply_lobby_button_skin(row.get_node(pair[0]), formation_unlock_filter == pair[1], 23)
	if not showing_team:
		$SafeArea/Layout/Content/TeamTab/TeamLayout/EmptyCollection.hide()


func _formation_cost_before(left_id: Variant, right_id: Variant) -> bool:
	var left := String(left_id)
	var right := String(right_id)
	if formation_mode == "team":
		var left_unlocked := left in team_available_ids
		var right_unlocked := right in team_available_ids
		if left_unlocked != right_unlocked:
			return left_unlocked
		if formation_sort_criterion == "rarity":
			var left_rank := SHOP_CATALOG.get_rarity_rank(MONSTER_CATALOG.get_rarity(left))
			var right_rank := SHOP_CATALOG.get_rarity_rank(MONSTER_CATALOG.get_rarity(right))
			if left_rank != right_rank:
				return left_rank > right_rank if formation_cost_descending else left_rank < right_rank
	var left_cost := _formation_item_cost(left)
	var right_cost := _formation_item_cost(right)
	if is_equal_approx(left_cost, right_cost):
		return left < right
	return left_cost > right_cost if formation_cost_descending else left_cost < right_cost


func _formation_item_cost(item_id: String) -> float:
	if formation_mode == "skill":
		return float(DEMON_ULTIMATES.get_skill(item_id).get("mana_cost", 0.0))
	return MONSTER_CATALOG.get_base_cost(item_id)


func _sorted_formation_ids(source_ids: Array) -> Array:
	var sorted_ids: Array = source_ids.duplicate()
	sorted_ids.sort_custom(_formation_cost_before)
	return sorted_ids


func _refresh_formation_mode() -> void:
	var showing_team := formation_mode == "team"
	var showing_transcendence := formation_mode == "transcendence"
	_refresh_formation_cost_sort_buttons()
	_refresh_formation_unlock_filters(showing_team)
	_apply_lobby_button_skin(team_mode_button, showing_team, 23)
	_apply_lobby_button_skin(skill_mode_button, formation_mode == "skill", 23)
	team_mode_button.disabled = showing_team
	skill_mode_button.disabled = formation_mode == "skill"
	team_mode_button.add_theme_stylebox_override("disabled", PIXEL_PANEL_SKIN.button_style(primary_button_style))
	skill_mode_button.add_theme_stylebox_override("disabled", PIXEL_PANEL_SKIN.button_style(primary_button_style))
	team_mode_button.add_theme_color_override("font_disabled_color", Color("fff0d2"))
	skill_mode_button.add_theme_color_override("font_disabled_color", Color("fff0d2"))
	transcendence_view.refresh(showing_transcendence)
	if showing_transcendence:
		_clear_team_monster_cards()
		return
	if showing_team:
		formation_list_title.text = "보유 몬스터 목록"
		_team_formation_view.heading(self, "◇  편성된 몬스터  ◇")
		_refresh_team_preview()
		team_status_label.text = "카드 터치: 상세정보 · 길게 누르기: 드래그 편성"
	else:
		formation_list_title.text = "마왕 스킬 목록 · 코스트"
		_team_formation_view.heading(self, "◇  편성된 스킬  ◇")
		_refresh_demon_skill_preview()
		team_status_label.text = "버튼 또는 스킬 카드를 길게 눌러 원하는 슬롯에 놓아 편성합니다."


func _refresh_team_preview() -> void:
	if formation_mode != "team":
		return
	_refresh_team_slot(team_slot_1_button, 0)
	_refresh_team_slot(team_slot_2_button, 1)
	_refresh_team_slot(team_slot_3_button, 2)

	var skill_names := PackedStringArray()
	for skill_id in demon_skill_selected_ids:
		skill_names.append(String(DEMON_ULTIMATES.get_skill(String(skill_id)).get("name", skill_id)))
	team_summary_label.text = "스킬 %d / %d · %s" % [
		demon_skill_selected_ids.size(), TEAM_MAX_SLOTS, " / ".join(skill_names)
	]
	_team_formation_view.heading(
		self, "◇  편성된 몬스터  %d / %d  ◇" % [team_selected_ids.size(), TEAM_MAX_SLOTS]
	)

	_rebuild_team_monster_cards()

func _clear_team_monster_cards() -> void:
	_formation_card_cache.clear_grid()

func _rebuild_team_monster_cards() -> void:
	_formation_card_cache.rebuild(_sorted_formation_ids(team_catalog_ids))

func _create_team_monster_card(monster_id: String) -> Control:
	var available := monster_id in team_available_ids
	var selected := monster_id in team_selected_ids
	var data := MONSTER_CATALOG.get_monster(monster_id)

	var card := FORMATION_DRAG_CARD.new()
	card.custom_minimum_size = Vector2(0.0, 400.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.configure_drag("monster", monster_id, _team_monster_name(monster_id), _team_monster_card_icon(monster_id))
	card.drag_enabled = available
	card.modulate = Color.WHITE if available else Color(0.52, 0.52, 0.52, 1.0)
	card.tapped.connect(_open_monster_detail.bind(monster_id))
	var card_style := (
		formation_card_selected_style if selected else formation_card_style
	).duplicate() as StyleBoxFlat
	# Every visual state reserves the same padding; border accents are cosmetic.
	for side in ["left", "right", "top", "bottom"]:
		card_style.set("content_margin_" + side, 2.0)
	card.add_theme_stylebox_override(
		"panel",
		card_style
	)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)

	var portrait := TextureRect.new()
	portrait.name = "MonsterPortrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(104.0, 116.0)
	portrait.texture = _team_monster_card_icon(monster_id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top_row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(copy)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = _team_monster_name(monster_id)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.clip_text = true
	title.custom_minimum_size.y = 58.0
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color("ffe29a") if selected else Color("f0e9f3")
	)
	copy.add_child(title)

	var info := Label.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.custom_minimum_size = Vector2(0.0, 26.0)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_theme_font_size_override("font_size", 18)
	info.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.clip_text = true
	var required := MONSTER_CATALOG.get_shards_required(monster_id)
	var shards := MONSTER_COLLECTION_STORE.get_shards(
		monster_id,
		monster_collection_state
	)
	var upgrade_level := MONSTER_COLLECTION_STORE.get_upgrade_level(
		monster_id,
		monster_collection_state
	)
	var maxed := MONSTER_COLLECTION_STORE.is_maxed(monster_id, monster_collection_state)
	if available:
		info.text = "Lv.%d · %s\n코스트 %.1f" % [
			upgrade_level,
			SHOP_CATALOG.get_rarity_label(MONSTER_CATALOG.get_rarity(monster_id)),
			float(data.get("base_cost", 0.0)),
		]
	else:
		info.text = "잠김 · %s\n코스트 %.1f" % [
			SHOP_CATALOG.get_rarity_label(MONSTER_CATALOG.get_rarity(monster_id)),
			float(data.get("base_cost", 0.0)),
		]
		info.add_theme_color_override("font_color", Color("8c8590"))
	copy.add_child(info)

	var shard_bar := ProgressBar.new()
	shard_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_bar.custom_minimum_size = Vector2(0.0, 28.0)
	shard_bar.min_value = 0.0
	shard_bar.max_value = float(required)
	shard_bar.value = float(required if maxed else mini(shards, required))
	shard_bar.show_percentage = false
	var shard_background := StyleBoxFlat.new()
	shard_background.bg_color = Color("25222d")
	shard_background.corner_radius_top_left = 5
	shard_background.corner_radius_top_right = 5
	shard_background.corner_radius_bottom_left = 5
	shard_background.corner_radius_bottom_right = 5
	var shard_fill := StyleBoxFlat.new()
	shard_fill.bg_color = Color("58bf78") if maxed or shards >= required else Color("77727d")
	shard_fill.corner_radius_top_left = 5
	shard_fill.corner_radius_top_right = 5
	shard_fill.corner_radius_bottom_left = 5
	shard_fill.corner_radius_bottom_right = 5
	shard_bar.add_theme_stylebox_override("background", shard_background)
	shard_bar.add_theme_stylebox_override("fill", shard_fill)
	vbox.add_child(shard_bar)

	var shard_label := Label.new()
	shard_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shard_label.text = "최대강화" if maxed else "[ %d / %d ]" % [shards, required]
	if not available:
		shard_label.text = "해금 %d / %d" % [shards, required]
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shard_label.add_theme_font_size_override("font_size", 17)
	shard_label.add_theme_color_override("font_color", Color("f4eff7"))
	shard_bar.add_child(shard_label)

	var actions := VBoxContainer.new()
	actions.name = "CardActions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	vbox.add_child(actions)

	var team_button := Button.new()
	team_button.name = "TeamAction"
	card.set_meta("team_action", team_button)
	team_button.custom_minimum_size = Vector2(0.0, 84.0)
	team_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	team_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_button.add_theme_font_size_override("font_size", 28)
	team_button.text = "편성 해제" if selected else "팀 편성"
	team_button.clip_text = true
	team_button.disabled = (
		not available
		or (selected and team_selected_ids.size() <= 1)
		or (not selected and team_selected_ids.size() >= TEAM_MAX_SLOTS)
	)
	team_button.add_theme_stylebox_override(
		"normal",
		primary_button_style if selected else secondary_button_style
	)
	team_button.add_theme_stylebox_override(
		"disabled",
		(
			primary_button_disabled_style
			if selected
			else secondary_button_disabled_style
		)
	)
	team_button.add_theme_color_override(
		"font_disabled_color",
		Color("9a8fa1")
	)
	team_button.add_theme_stylebox_override("hover", primary_button_style)
	team_button.add_theme_stylebox_override("pressed", primary_button_style)
	team_button.pressed.connect(_toggle_team_monster.bind(monster_id))
	actions.add_child(team_button)
	_team_formation_view.fit_action(team_button)

	var upgrade_profile := MONSTER_CATALOG.get_rarity_upgrade_profile(monster_id)
	var upgrade_configured := bool(upgrade_profile.get("configured", false))
	var upgrade_button := Button.new()
	upgrade_button.name = "UpgradeAction"
	upgrade_button.custom_minimum_size = Vector2(0.0, 84.0)
	upgrade_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button.add_theme_font_size_override("font_size", 28)
	upgrade_button.text = "강화하기"
	upgrade_button.clip_text = true
	if maxed:
		upgrade_button.text = "최대강화"
		upgrade_button.tooltip_text = "Lv.%d · 이후 조각은 1개당 연구 포인트 %d로 전환됩니다." % [MONSTER_CATALOG.get_max_upgrade_level(monster_id), MONSTER_CATALOG.get_shard_research_points(monster_id)]
	elif not upgrade_configured:
		upgrade_button.text = "준비 중"
		upgrade_button.tooltip_text = "이 등급의 강화 효과는 준비 중입니다."
	elif not available:
		upgrade_button.text = "해금 필요"
		upgrade_button.tooltip_text = "조각 %d개를 모으면 자동 해금됩니다." % required
	upgrade_button.disabled = (
		maxed or not upgrade_configured
		or not available
		or shards < required
	)
	upgrade_button.add_theme_stylebox_override("normal", primary_button_style)
	upgrade_button.add_theme_stylebox_override("hover", primary_button_style)
	upgrade_button.add_theme_stylebox_override("pressed", primary_button_style)
	upgrade_button.add_theme_stylebox_override("disabled", primary_button_disabled_style)
	upgrade_button.add_theme_color_override("font_disabled_color", Color("9a8fa1"))
	upgrade_button.pressed.connect(_upgrade_team_monster.bind(monster_id))
	actions.add_child(upgrade_button)
	_team_formation_view.fit_action(upgrade_button)
	if not upgrade_button.disabled:
		card_style.bg_color = Color("171020", 0.96)
		card_style.set_corner_radius_all(14)
	var badge := _team_formation_view.label(vbox, "최대강화" if maxed else ("강화 가능" if not upgrade_button.disabled else ("편성 중" if selected else "")), 19)
	badge.name = "UpgradeBadge"
	badge.custom_minimum_size.y = 26.0
	badge.add_theme_color_override("font_color", Color("ffe09a"))
	vbox.move_child(badge, 0)

	PIXEL_PANEL_SKIN.apply_tree(card)
	# Apply after the common panel skin so the authored gold cannot override rarity.
	card_style.border_color = _team_formation_view.rarity_border_color(MONSTER_CATALOG.get_rarity(monster_id))
	card_style.set_corner_radius_all(0)
	card.add_theme_stylebox_override("panel", _team_formation_view.rarity_card_style(MONSTER_CATALOG.get_rarity(monster_id), card_style))
	_team_formation_view.apply_card_frame(card, MONSTER_CATALOG.get_rarity(monster_id))
	return card


func _upgrade_team_monster(monster_id: String) -> Dictionary:
	var result := MONSTER_COLLECTION_STORE.try_upgrade(monster_id)
	GameAudio.feedback("upgrade" if bool(result.get("success", false)) else "denied")
	var updated_state = result.get("state", {})
	if typeof(updated_state) == TYPE_DICTIONARY:
		monster_collection_state = updated_state
	if bool(result.get("success", false)):
		team_status_label.text = "%s %s 완료 · Lv.%d" % [
			_team_monster_name(monster_id),
			"초월" if MONSTER_CATALOG.get_rarity(monster_id) == "transcendent" else "강화",
			int(result.get("level", 0)),
		]
		if int(result.get("research_points", 0)) > 0:
			team_status_label.text += " · 연구 +%d P" % int(result.research_points)
		_refresh_header()
	else:
		var reason := String(result.get("reason", ""))
		var reason_text: String = String({
			"locked": "먼저 몬스터를 해금해야 합니다.",
			"not_configured": "이 등급의 강화 효과는 준비 중입니다.",
			"not_enough_shards": "강화에 필요한 조각이 부족합니다.",
			"save_failed": "강화 정보 저장에 실패했습니다.",
			"max_level": "최대 %s Lv.%d에 도달했습니다." % ["초월" if MONSTER_CATALOG.get_rarity(monster_id) == "transcendent" else "강화", MONSTER_CATALOG.get_max_upgrade_level(monster_id)],
		}.get(reason, "몬스터를 강화할 수 없습니다."))
		team_status_label.text = reason_text
	_refresh_team_preview()
	if bool(result.get("success", false)):
		_play_team_upgrade_feedback(monster_id, int(result.get("level", 0)))
	return result

func _play_team_upgrade_feedback(monster_id: String, new_level: int) -> void:
	for card in team_monster_grid.get_children():
		if card.get("formation_id") != monster_id:
			continue
		if not is_instance_valid(_team_upgrade_feedback):
			_team_upgrade_feedback = MONSTER_UPGRADE_FEEDBACK.new()
			card.add_child(_team_upgrade_feedback)
		else:
			_team_upgrade_feedback.reparent(card, false)
		_team_upgrade_feedback.restart(new_level)
		return

func _refresh_team_slot(button: Button, slot_index: int) -> void:
	if slot_index < team_selected_ids.size():
		var monster_id := String(team_selected_ids[slot_index])
		button.disabled = false
		var info := "Lv.%d · %s\n코스트 %.1f" % [
			MONSTER_COLLECTION_STORE.get_upgrade_level(monster_id, monster_collection_state),
			SHOP_CATALOG.get_rarity_label(MONSTER_CATALOG.get_rarity(monster_id)),
			_team_monster_cost(monster_id)
		]
		_team_formation_view.refresh_slot(
			button, _team_monster_card_icon(monster_id), _team_monster_name(monster_id),
			info, team_selected_ids.size() > 1, MONSTER_CATALOG.get_rarity(monster_id)
		)
	else:
		button.icon = null
		button.text = "%d\n빈 슬롯" % (slot_index + 1)
		button.disabled = false
		_team_formation_view.refresh_slot(button, null, "빈 슬롯", "길게 눌러 놓으세요", false)

func _on_team_slot_pressed(slot_index: int) -> void:
	if formation_mode == "skill":
		_on_demon_skill_slot_pressed(slot_index)
		return
	if slot_index < 0 or slot_index >= team_selected_ids.size():
		return
	_open_monster_detail(String(team_selected_ids[slot_index]))

func _remove_formation_slot(slot_index: int) -> void:
	if formation_mode == "skill":
		_on_demon_skill_slot_pressed(slot_index)
	elif slot_index >= 0 and slot_index < team_selected_ids.size():
		_remove_team_monster(String(team_selected_ids[slot_index]))

func get_formation_snapshot() -> Dictionary:
	return FORMATION_PRESET_MODEL.snapshot(team_selected_ids, demon_skill_selected_ids)

func _toggle_team_monster(monster_id: String) -> void:
	if monster_id in team_selected_ids:
		_remove_team_monster(monster_id)
	else:
		_add_team_monster(monster_id)


func _refresh_demon_skill_preview() -> void:
	if formation_mode != "skill":
		return
	_refresh_demon_skill_slot(team_slot_1_button, 0)
	_refresh_demon_skill_slot(team_slot_2_button, 1)
	_refresh_demon_skill_slot(team_slot_3_button, 2)

	var selected_names: Array[String] = []
	for raw_id in demon_skill_selected_ids:
		var skill := DEMON_ULTIMATES.get_skill(String(raw_id))
		selected_names.append(String(skill.get("name", raw_id)))
	team_summary_label.text = "스킬 %d / %d · %s" % [
		demon_skill_selected_ids.size(),
		TEAM_MAX_SLOTS,
		" / ".join(selected_names),
	]

	_clear_team_monster_cards()
	for raw_id in _sorted_formation_ids(demon_skill_catalog_ids):
		team_monster_grid.add_child(
			_create_demon_skill_card(String(raw_id))
		)


func _refresh_demon_skill_slot(button: Button, slot_index: int) -> void:
	button.icon = null
	if slot_index < demon_skill_selected_ids.size():
		var skill_id := String(demon_skill_selected_ids[slot_index])
		var skill := DEMON_ULTIMATES.get_skill(skill_id)
		button.text = "%d  ◆\n%s\n코스트 %d · 탭해서 해제" % [
			slot_index + 1,
			String(skill.get("name", skill_id)),
			int(round(float(skill.get("mana_cost", 0.0)))),
		]
		button.disabled = false
		_team_formation_view.refresh_slot(button, null, String(skill.get("name", skill_id)), "마왕 스킬\n코스트 %d" % int(skill.get("mana_cost", 0)), demon_skill_selected_ids.size() > 1)
	else:
		button.text = "%d\n빈 슬롯" % (slot_index + 1)
		button.disabled = false
		_team_formation_view.refresh_slot(button, null, "빈 슬롯", "스킬을 놓으세요", false)


func _create_demon_skill_card(skill_id: String) -> Control:
	var skill := DEMON_ULTIMATES.get_skill(skill_id)
	var selected := skill_id in demon_skill_selected_ids
	var card := FORMATION_DRAG_CARD.new()
	card.custom_minimum_size = Vector2(0.0, 246.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.configure_drag(
		"skill",
		skill_id,
		String(skill.get("name", skill_id))
	)
	card.add_theme_stylebox_override(
		"panel",
		formation_card_selected_style if selected else formation_card_style
	)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var symbol := Label.new()
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	symbol.text = "◆"
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.add_theme_font_size_override("font_size", 46)
	symbol.add_theme_color_override("font_color", Color("f2c34f"))
	vbox.add_child(symbol)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = String(skill.get("name", skill_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override(
		"font_color",
		Color("ffe29a") if selected else Color("f0e9f3")
	)
	vbox.add_child(title)

	var info := Label.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.text = "코스트 %d · 쿨 %.0f초\n%s" % [
		int(round(float(skill.get("mana_cost", 0.0)))),
		float(skill.get("cooldown", 0.0)),
		String(skill.get("description", "")),
	]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 17)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(info)

	var select_button := Button.new()
	select_button.custom_minimum_size = Vector2(0.0, 50.0)
	select_button.add_theme_font_size_override("font_size", 18)
	select_button.text = "편성 해제" if selected else "스킬 편성"
	select_button.disabled = (
		(selected and demon_skill_selected_ids.size() <= 1)
		or (
			not selected
			and demon_skill_selected_ids.size() >= TEAM_MAX_SLOTS
		)
	)
	select_button.add_theme_stylebox_override(
		"normal",
		primary_button_style if selected else secondary_button_style
	)
	select_button.add_theme_stylebox_override(
		"disabled",
		(
			primary_button_disabled_style
			if selected
			else secondary_button_disabled_style
		)
	)
	select_button.add_theme_color_override(
		"font_disabled_color",
		Color("9a8fa1")
	)
	select_button.add_theme_stylebox_override("hover", primary_button_style)
	select_button.add_theme_stylebox_override("pressed", primary_button_style)
	select_button.pressed.connect(_toggle_demon_skill.bind(skill_id))
	vbox.add_child(select_button)
	PIXEL_PANEL_SKIN.apply_tree(card)
	return card


func _on_demon_skill_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= demon_skill_selected_ids.size():
		return
	_remove_demon_skill(String(demon_skill_selected_ids[slot_index]))


func _on_formation_item_dropped(
	slot_index: int,
	dropped_kind: String,
	item_id: String
) -> void:
	if slot_index < 0 or slot_index >= TEAM_MAX_SLOTS:
		return
	if dropped_kind == "monster":
		if formation_mode != "team":
			return
		_place_monster_in_slot(item_id, slot_index)
	elif dropped_kind == "skill":
		if formation_mode != "skill":
			return
		_place_demon_skill_in_slot(item_id, slot_index)


func _place_monster_in_slot(monster_id: String, slot_index: int) -> void:
	if monster_id not in team_available_ids:
		team_status_label.text = "아직 사용할 수 없는 몬스터입니다."
		return
	_move_or_replace_slot(team_selected_ids, monster_id, slot_index)
	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_selected_ids,
		team_available_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = "%d번 슬롯에 %s 편성 · %s" % [
		slot_index + 1,
		_team_monster_name(monster_id),
		"저장 완료" if saved else "저장 실패",
	]
	_refresh_team_preview()


func _place_demon_skill_in_slot(skill_id: String, slot_index: int) -> void:
	if skill_id not in demon_skill_catalog_ids:
		team_status_label.text = "사용할 수 없는 마왕 스킬입니다."
		return
	_move_or_replace_slot(demon_skill_selected_ids, skill_id, slot_index)
	var saved := DEMON_SKILL_LOADOUT_STORE.save_ids(
		demon_skill_selected_ids,
		demon_skill_catalog_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = "%d번 슬롯에 %s 스킬 편성 · %s" % [
		slot_index + 1,
		String(DEMON_ULTIMATES.get_skill(skill_id).get("name", skill_id)),
		"저장 완료" if saved else "저장 실패",
	]
	_refresh_demon_skill_preview()


func _move_or_replace_slot(selected_ids: Array, item_id: String, slot_index: int) -> void:
	var previous_index := selected_ids.find(item_id)
	if previous_index >= 0:
		selected_ids.remove_at(previous_index)
	elif slot_index < selected_ids.size():
		selected_ids.remove_at(slot_index)

	var insertion_index := mini(slot_index, selected_ids.size())
	selected_ids.insert(insertion_index, item_id)


func _toggle_demon_skill(skill_id: String) -> void:
	if skill_id in demon_skill_selected_ids:
		_remove_demon_skill(skill_id)
	else:
		_add_demon_skill(skill_id)


func _remove_demon_skill(skill_id: String) -> void:
	if skill_id not in demon_skill_selected_ids:
		return
	if demon_skill_selected_ids.size() <= 1:
		team_status_label.text = "최소 1개의 마왕 스킬은 편성해야 합니다."
		return
	demon_skill_selected_ids.erase(skill_id)
	var saved := DEMON_SKILL_LOADOUT_STORE.save_ids(
		demon_skill_selected_ids,
		demon_skill_catalog_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = "%s 스킬 해제 · %s" % [
		String(DEMON_ULTIMATES.get_skill(skill_id).get("name", skill_id)),
		"저장 완료" if saved else "저장 실패",
	]
	_refresh_demon_skill_preview()


func _add_demon_skill(skill_id: String) -> void:
	if skill_id in demon_skill_selected_ids:
		return
	if skill_id not in demon_skill_catalog_ids:
		team_status_label.text = "사용할 수 없는 마왕 스킬입니다."
		return
	if demon_skill_selected_ids.size() >= TEAM_MAX_SLOTS:
		team_status_label.text = "스킬 편성 슬롯은 최대 %d칸입니다." % TEAM_MAX_SLOTS
		return
	demon_skill_selected_ids.append(skill_id)
	var saved := DEMON_SKILL_LOADOUT_STORE.save_ids(
		demon_skill_selected_ids,
		demon_skill_catalog_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = "%s 스킬 편성 · %s" % [
		String(DEMON_ULTIMATES.get_skill(skill_id).get("name", skill_id)),
		"저장 완료" if saved else "저장 실패",
	]
	_refresh_demon_skill_preview()


func _ignore_monster_detail_content_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_monster_detail_content_input(child)


func _open_monster_detail(monster_id: String) -> void:
	if monster_id.is_empty():
		return
	if not MONSTER_CATALOG.MONSTERS.has(monster_id):
		return

	_populate_monster_detail(monster_id)
	_detail_scroll_touch_index = -1
	var list := $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterScroll as ScrollContainer
	list.scroll_vertical = list.scroll_vertical
	$MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll.scroll_vertical = 0
	monster_detail_overlay.show()
	monster_detail_overlay.move_to_front()

func _close_monster_detail() -> void:
	_detail_scroll_touch_index = -1
	monster_detail_overlay.hide()

func _on_monster_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_monster_detail()
	elif event is InputEventScreenTouch and event.pressed:
		_close_monster_detail()

func _populate_monster_detail(monster_id: String) -> void:
	var data := MONSTER_CATALOG.get_monster(monster_id)
	if data.is_empty():
		return

	var monster_name := String(data.get("name", monster_id))
	var role_label := MONSTER_CATALOG.get_role_label(
		String(data.get("role", ""))
	)
	var species_label := MONSTER_CATALOG.get_species_label(
		String(data.get("species", ""))
	)
	var grade_label := MONSTER_CATALOG.get_grade_label(
		String(data.get("grade", "normal"))
	)
	var elite_allowed := bool(data.get("can_be_elite", true))
	$MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel.visible = elite_allowed
	$MonsterDetailOverlay/Panel/Margin/VBox/Guide.text = "일반과 엘리트의 전투 능력을 한눈에 비교합니다." if elite_allowed else "엘리트·대형몹 없음 · 기본 능력과 특수증강"
	var elite_skills := MONSTER_CATALOG.get_elite_skills(monster_id)
	var base_stats := _read_monster_base_stats(monster_id)
	var mutation := MUTATION_CATALOG.get_profile("mutation_1")

	monster_detail_title.text = "%s 상세 정보" % monster_name
	monster_detail_normal_badge.text = grade_label
	monster_detail_elite_badge.text = "엘리트 · %s 등급 기술 %d개" % [
		grade_label,
		elite_skills.size(),
	]
	monster_detail_normal_name.text = monster_name
	monster_detail_elite_name.text = "엘리트 %s" % monster_name
	monster_detail_normal_portrait.texture = _team_monster_card_icon(monster_id)
	monster_detail_elite_portrait.texture = _load_elite_preview(monster_id)

	monster_detail_normal_stats.text = _build_normal_detail_text(
		monster_id,
		role_label,
		data,
		base_stats
	)
	monster_detail_specials.text = _build_special_augment_text(monster_id)
	monster_detail_elite_stats.text = _build_elite_detail_text(
		monster_id,
		role_label,
		data,
		base_stats,
		mutation
	)
	monster_detail_elite_skills.text = _build_elite_skill_text(monster_id)

func _read_monster_base_stats(monster_id: String) -> Dictionary:
	return MONSTER_CATALOG.get_base_stats(monster_id)


func _build_normal_detail_text(
	monster_id: String,
	role_label: String,
	data: Dictionary,
	stats: Dictionary
) -> String:
	if not bool(data.get("combat_enabled", true)):
		return "[center][color=#f0cb68]초월 · 전투 능력 준비 중[/color]\n\n%s[/center]" % data.get("description", "")
	var lines: PackedStringArray = []
	var identity_parts: PackedStringArray = [
		MONSTER_CATALOG.get_grade_label(String(data.get("grade", "normal"))),
		MONSTER_CATALOG.get_species_label(String(data.get("species", ""))),
		role_label,
	]
	var attack_type := String(data.get("attack_type", ""))
	if not attack_type.is_empty():
		identity_parts.append(
			MONSTER_CATALOG.get_attack_type_label(attack_type)
		)
	lines.append("[center][color=#c9b6d3]%s[/color][/center]" % " · ".join(identity_parts))
	lines.append("[center][color=#f0cb68]코스트 %.1f[/color]   [color=#bdb0c5]마왕 EXP %.1f[/color][/center]" % [
		float(data.get("base_cost", 0.0)),
		float(data.get("summon_exp", 0.0)),
	])
	lines.append("")
	lines.append("[color=#8f8098]전투 능력[/color]")
	lines.append("[table=2]")

	var hp_value = stats.get("max_hp")
	if hp_value != null:
		lines.append(_format_stat_meter(
			"체력",
			_stat_level(float(hp_value), [60.0, 90.0, 130.0, 180.0]),
			"69d88a"
		))

	var damage_value = stats.get("attack_damage")
	var explosion_damage = stats.get("explosion_damage")
	if damage_value != null:
		var hits_per_attack := maxi(
			int(stats.get("hits_per_attack", 1)),
			1
		)
		var total_damage := float(damage_value) * float(hits_per_attack)
		lines.append(_format_stat_meter(
			"공격",
			_stat_level(total_damage, [6.0, 10.0, 18.0, 30.0]),
			"e36d73"
		))
	elif explosion_damage != null:
		lines.append(_format_stat_meter(
			"자폭",
			_stat_level(float(explosion_damage), [12.0, 24.0, 40.0, 65.0]),
			"e36d73"
		))

	var speed_value = stats.get("move_speed")
	if speed_value != null:
		var speed_number := float(speed_value)
		lines.append(_format_stat_meter(
			"기동",
			0 if speed_number <= 0.0 else _stat_level(
				speed_number,
				[70.0, 110.0, 150.0, 210.0]
			),
			"61c7df",
			"고정" if speed_number <= 0.0 else ""
		))

	var cooldown_value = stats.get("attack_cooldown")
	if cooldown_value != null:
		var attacks_per_second := 1.0 / maxf(float(cooldown_value), 0.01)
		lines.append(_format_stat_meter(
			"공속",
			_stat_level(attacks_per_second, [0.7, 1.0, 1.35, 1.8]),
			"f0c85b"
		))

	var range_value = stats.get("attack_range")
	if range_value != null and monster_id != "bomb_rat":
		lines.append(_format_stat_meter(
			"사거리",
			_stat_level(float(range_value), [70.0, 140.0, 260.0, 500.0]),
			"b68ae8"
		))
	lines.append("[/table]")

	var extra_parts: PackedStringArray = []
	var fuse_value = stats.get("self_destruct_fuse")
	if fuse_value != null:
		extra_parts.append("자폭 준비 %.2f초" % float(fuse_value))
	var explosion_radius = stats.get("explosion_radius")
	if explosion_radius != null:
		extra_parts.append("폭발 반경 %.0f" % float(explosion_radius))

	var slow_value = stats.get("slow_multiplier")
	var slow_duration = stats.get("slow_duration")
	if slow_value != null and slow_duration != null:
		extra_parts.append(
			"둔화 %.0f%% / %.1f초" % [
				(1.0 - float(slow_value)) * 100.0,
				float(slow_duration),
			]
		)
	if not extra_parts.is_empty():
		lines.append("")
		lines.append("[color=#aaa0b0]%s[/color]" % " · ".join(extra_parts))

	var description := String(data.get("description", ""))
	if not description.is_empty():
		lines.append("")
		lines.append("[color=#aaa0b0]%s[/color]" % description)
	return "\n".join(lines)


func _stat_level(value: float, thresholds: Array) -> int:
	var level := 1
	for threshold in thresholds:
		if value >= float(threshold):
			level += 1
	return clampi(level, 1, 5)


func _format_stat_meter(
	label: String,
	level: int,
	fill_color: String,
	note: String = ""
) -> String:
	var filled_count := clampi(level, 0, 5)
	var filled := "■".repeat(filled_count)
	var empty := "■".repeat(5 - filled_count)
	var suffix := "  [color=#9b90a2]%s[/color]" % note if not note.is_empty() else ""
	return "[cell][color=#d8cedd]%s[/color]  [/cell][cell][color=#%s]%s[/color][color=#403747]%s[/color]%s[/cell]" % [
		label,
		fill_color,
		filled,
		empty,
		suffix,
	]

func _build_special_augment_text(monster_id: String) -> String:
	var lines: PackedStringArray = []
	for raw_augment in DEMON_AUGMENTS.get_special_augments_for_monster(
		monster_id
	):
		var augment: Dictionary = raw_augment
		lines.append("◆ %s\n  %s" % [
			String(augment.get("name", "특수증강")),
			String(augment.get("description", "")),
		])

	if lines.is_empty():
		return "등록된 특수증강이 없습니다."
	return "\n".join(lines)

func _build_elite_detail_text(
	monster_id: String,
	role_label: String,
	data: Dictionary,
	stats: Dictionary,
	mutation: Dictionary
) -> String:
	var hp_multiplier := float(mutation.get("hp_multiplier", 1.0))
	var damage_multiplier := float(
		mutation.get("damage_multiplier", 1.0)
	)
	var speed_multiplier := float(mutation.get("speed_multiplier", 1.0))
	var attack_speed_multiplier := float(
		mutation.get("attack_speed_multiplier", 1.0)
	)
	var visual_scale := float(mutation.get("visual_scale", 1.0))

	var lines: PackedStringArray = []
	var identity_parts: PackedStringArray = [
		"엘리트",
		MONSTER_CATALOG.get_species_label(String(data.get("species", ""))),
		role_label,
	]
	var attack_type := String(data.get("attack_type", ""))
	if not attack_type.is_empty():
		identity_parts.append(MONSTER_CATALOG.get_attack_type_label(attack_type))
	lines.append("[center][color=#e3bd64]%s[/color][/center]" % " · ".join(identity_parts))
	lines.append("[center][color=#bdb0c5]기본 돌연변이 · 기술 %d개[/color][/center]" % MONSTER_CATALOG.get_elite_skills(monster_id).size())
	lines.append("")
	lines.append("[color=#d9b45b]엘리트 전투 능력[/color]")
	lines.append("[table=2]")
	var hp_value = stats.get("max_hp")
	if hp_value != null:
		lines.append(_format_stat_meter(
			"체력",
			_stat_level(
				float(hp_value) * hp_multiplier,
				[60.0, 90.0, 130.0, 180.0]
			),
			"69d88a"
		))

	var damage_value = stats.get("attack_damage")
	var explosion_damage = stats.get("explosion_damage")
	if damage_value != null:
		var hits_per_attack := maxi(int(stats.get("hits_per_attack", 1)), 1)
		lines.append(_format_stat_meter(
			"공격",
			_stat_level(
				float(damage_value) * float(hits_per_attack) * damage_multiplier,
				[6.0, 10.0, 18.0, 30.0]
			),
			"e36d73"
		))
	elif explosion_damage != null:
		lines.append(_format_stat_meter(
			"자폭",
			_stat_level(
				float(explosion_damage) * damage_multiplier,
				[12.0, 24.0, 40.0, 65.0]
			),
			"e36d73"
		))

	var speed_value = stats.get("move_speed")
	if speed_value != null:
		var elite_speed := float(speed_value) * speed_multiplier
		lines.append(_format_stat_meter(
			"기동",
			0 if elite_speed <= 0.0 else _stat_level(
				elite_speed,
				[70.0, 110.0, 150.0, 210.0]
			),
			"61c7df",
			"고정" if elite_speed <= 0.0 else ""
		))

	var cooldown_value = stats.get("attack_cooldown")
	if cooldown_value != null:
		var attacks_per_second := attack_speed_multiplier / maxf(
			float(cooldown_value),
			0.01
		)
		lines.append(_format_stat_meter(
			"공속",
			_stat_level(attacks_per_second, [0.7, 1.0, 1.35, 1.8]),
			"f0c85b"
		))

	var range_value = stats.get("attack_range")
	if range_value != null and monster_id != "bomb_rat":
		lines.append(_format_stat_meter(
			"사거리",
			_stat_level(float(range_value), [70.0, 140.0, 260.0, 500.0]),
			"b68ae8"
		))
	lines.append("[/table]")

	lines.append("[color=#8f8495]크기 ×%.2f[/color]" % visual_scale)
	return "\n".join(lines)


func _build_elite_skill_text(monster_id: String) -> String:
	var lines: PackedStringArray = []
	var elite_skills := MONSTER_CATALOG.get_elite_skills(monster_id)
	if elite_skills.is_empty():
		lines.append("등록된 엘리트 기술이 없습니다.")
	else:
		for raw_skill in elite_skills:
			if typeof(raw_skill) != TYPE_DICTIONARY:
				continue
			var skill: Dictionary = raw_skill
			lines.append("[color=#ffe29a]◆ %s[/color]" % String(
				skill.get("name", "엘리트 기술")
			))
			if bool(skill.get("passive", false)):
				lines.append("  [color=#b89ac7]상시 패시브[/color]")
			else:
				lines.append(
					"  [color=#b89ac7]선쿨 %.1f초 · 쿨 %.1f초[/color]" % [
						maxf(float(skill.get("initial_cooldown", 0.0)), 0.0),
						maxf(float(skill.get("cooldown", 0.0)), 0.0),
					]
				)
			var description := String(skill.get("description", ""))
			if not description.is_empty():
				lines.append("  %s" % description)
	return "\n".join(lines)

func _load_elite_preview(monster_id: String) -> Texture2D:
	var profile := MONSTER_CATALOG.get_elite_visual_profile(monster_id)
	if profile.is_empty():
		return _team_monster_card_icon(monster_id)

	var asset_dir := String(profile.get("asset_dir", ""))
	var animations = profile.get("animations", {})
	if asset_dir.is_empty() or typeof(animations) != TYPE_DICTIONARY:
		return _team_monster_card_icon(monster_id)

	var idle = animations.get("idle", {})
	if typeof(idle) != TYPE_DICTIONARY:
		return _team_monster_card_icon(monster_id)

	var path := ""
	var mode := String(profile.get("mode", ""))
	if mode == "frames":
		var prefix := String(idle.get("prefix", "idle"))
		path = "%s/%s_%02d.png" % [asset_dir, prefix, 1]
	elif mode == "sequence":
		var start_index := int(idle.get("start", 1))
		path = "%s/frame_%02d.png" % [asset_dir, start_index]

	var texture := _load_texture(path)
	if texture != null:
		return texture
	return _team_monster_card_icon(monster_id)

func _remove_team_monster(monster_id: String) -> void:
	if monster_id not in team_selected_ids:
		return

	if team_selected_ids.size() <= 1:
		team_status_label.text = "최소 1종은 편성해야 합니다."
		return

	team_selected_ids.erase(monster_id)
	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_selected_ids,
		team_available_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = (
		"%s 편성 해제 · 저장 완료" % _team_monster_name(monster_id)
		if saved
		else "%s 편성 해제 · 저장 실패" % _team_monster_name(monster_id)
	)
	_refresh_team_preview()

func _add_team_monster(monster_id: String) -> void:
	if monster_id in team_selected_ids:
		return

	if monster_id not in team_available_ids:
		team_status_label.text = "아직 사용할 수 없는 몬스터입니다."
		return

	if team_selected_ids.size() >= TEAM_MAX_SLOTS:
		team_status_label.text = "편성 슬롯은 최대 %d칸입니다." % TEAM_MAX_SLOTS
		return

	team_selected_ids.append(monster_id)
	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_selected_ids,
		team_available_ids
	)
	get_node("/root/GameAudio").feedback("formation" if saved else "denied")
	team_status_label.text = (
		"%s 편성 추가 · 저장 완료" % _team_monster_name(monster_id)
		if saved
		else "%s 편성 추가 · 저장 실패" % _team_monster_name(monster_id)
	)
	_refresh_team_preview()

func _team_collection_card_text(monster_id: String) -> String:
	if monster_id not in team_available_ids:
		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		var required := 1
		if typeof(data) == TYPE_DICTIONARY:
			required = MONSTER_CATALOG.get_shards_required(monster_id)

		var shards := MONSTER_COLLECTION_STORE.get_shards(
			monster_id,
			monster_collection_state
		)
		return "%s\n[잠김]\n조각 %d / %d" % [
			_team_monster_name(monster_id),
			shards,
			required,
		]

	var state_text := (
		"[편성 중] · 탭해서 해제"
		if monster_id in team_selected_ids
		else "탭해서 편성"
	)
	return "%s\n%s · 코스트 %.0f\n%s" % [
		_team_monster_name(monster_id),
		_team_monster_role_label(monster_id),
		_team_monster_cost(monster_id),
		state_text,
	]

func _team_monster_card_icon(monster_id: String) -> Texture2D:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return null

	var icon_path := MONSTER_CATALOG.get_ui_icon_path(monster_id)
	if icon_path.is_empty():
		return null
	var icon_region = data.get("card_icon_region")
	var cache_key := icon_path
	if typeof(icon_region) == TYPE_RECT2:
		cache_key += ":%s" % icon_region
	if _monster_icon_texture_cache.has(cache_key):
		return _monster_icon_texture_cache[cache_key] as Texture2D

	var texture: Texture2D = null
	if (
		typeof(icon_region) != TYPE_RECT2
		and icon_path.get_extension().to_lower() == "png"
	):
		texture = _load_png_texture_cropped(icon_path)
	if texture == null:
		texture = _load_texture(icon_path)
	if texture == null:
		return null

	if typeof(icon_region) == TYPE_RECT2:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.filter_clip = true
		atlas.region = icon_region
		_monster_icon_texture_cache[cache_key] = atlas
		return atlas

	_monster_icon_texture_cache[cache_key] = texture
	return texture

func _team_monster_name(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return monster_id
	return String(data.get("name", monster_id))

func _team_monster_role_label(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var role_id := String(data.get("role", ""))
	return String(MONSTER_CATALOG.ROLE_LABELS.get(role_id, role_id))

func _team_monster_cost(monster_id: String) -> float:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return 0.0
	return float(data.get("base_cost", 0.0))

func _refresh_header() -> void:
	_refresh_shop_summon_buttons()
	if stamina_view != null:
		stamina_view.refresh()
	# The shop has its own full-width storefront; retain the shared frame elsewhere.
	$SafeArea/Layout/Content/ContentFrame.visible = current_tab != "shop"
	var state := STAGE_PROGRESS.load_state()
	var highest := int(state.get("highest_unlocked_stage", 1))
	var gold_text := _format_shop_number(_get_shop_gold())

	title_label.text = "용사, 또 너야?"
	resource_label.text = "골드  %s" % gold_text
	progress_label.text = "최고 해금  Stage %d" % highest

	var gold_value := get_node_or_null(
		^"SafeArea/Layout/Header/HeaderSlots/HeaderGoldPlate/HeaderGoldValue"
	) as Label
	if gold_value != null:
		gold_value.text = gold_text

	var progress_value := get_node_or_null(
		^"SafeArea/Layout/Header/HeaderSlots/HeaderProgressPlate/HeaderProgressValue"
	) as Label
	if progress_value != null:
		progress_value.text = (
			_format_shop_number(STAGE_PROGRESS.get_research_points())
			if current_tab == "shop" else "Stage %d" % highest
		)
	var progress_title := get_node_or_null(
		^"SafeArea/Layout/Header/HeaderSlots/HeaderProgressPlate/HeaderProgressTitle"
	) as Label
	if progress_title != null:
		progress_title.text = "연구 포인트" if current_tab == "shop" else "최고 해금"

func _change_stage(direction: int) -> void:
	if main_modes_view != null and main_modes_view.ranked:
		main_modes_view.change_character(direction)
		return
	if stage_ids.is_empty() or _stage_transition_running:
		return

	var max_browsable_index := _get_max_browsable_stage_index()
	var target_index := clampi(
		selected_stage_index + direction,
		0,
		max_browsable_index
	)
	if target_index == selected_stage_index:
		return
	_start_stage_transition(target_index, signi(direction))


func _open_stage_selector() -> void:
	if main_modes_view != null and main_modes_view.ranked:
		return
	if stage_ids.is_empty() or _stage_transition_running:
		return
	_refresh_stage_selector_buttons(_get_max_browsable_stage_index())
	stage_select_overlay.show()
	stage_select_overlay.move_to_front()


func _close_stage_selector() -> void:
	stage_select_overlay.hide()


func _on_stage_selector_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_stage_selector()
	elif event is InputEventScreenTouch and event.pressed:
		_close_stage_selector()


func _on_stage_selected(target_index: int) -> void:
	if stage_ids.is_empty() or _stage_transition_running:
		return
	var max_browsable_index := _get_max_browsable_stage_index()
	if target_index < 0 or target_index > max_browsable_index:
		return
	_close_stage_selector()
	if target_index == selected_stage_index:
		return
	var direction := 1 if target_index > selected_stage_index else -1
	_start_stage_transition(target_index, direction)


func _start_stage_transition(target_index: int, direction: int) -> void:
	if direction == 0:
		return

	_stage_transition_running = true
	_stage_pending_index = target_index
	_stage_pending_direction = direction
	_stage_card_origin = stage_card.position
	_stage_card_base_modulate = stage_card.modulate

	stage_card.pivot_offset = stage_card.size * 0.5

	var meta_box := stage_selector_button.get_parent() as Control
	if meta_box != null:
		meta_box.pivot_offset = meta_box.size * 0.5

	var fade_out := _stage_card_base_modulate
	fade_out.a = 0.0

	var tween_out := create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(
		stage_card,
		"position",
		_stage_card_origin + Vector2(-float(direction) * STAGE_SLIDE_DISTANCE, 0.0),
		STAGE_SLIDE_OUT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_out.tween_property(
		stage_card,
		"scale",
		STAGE_SCALE_OUT,
		STAGE_SLIDE_OUT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_out.tween_property(
		stage_card,
		"modulate",
		fade_out,
		STAGE_SLIDE_OUT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if meta_box != null:
		tween_out.tween_property(
			meta_box,
			"scale",
			Vector2(0.96, 0.96),
			STAGE_SLIDE_OUT_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween_out.tween_property(
			meta_box,
			"modulate:a",
			0.0,
			STAGE_SLIDE_OUT_DURATION
		)

	tween_out.finished.connect(_on_stage_slide_out_finished)


func _on_stage_slide_out_finished() -> void:
	selected_stage_index = _stage_pending_index
	_refresh_stage_card()

	var start_modulate := _stage_card_base_modulate
	start_modulate.a = 0.0
	stage_card.position = _stage_card_origin + Vector2(
		float(_stage_pending_direction) * STAGE_SLIDE_DISTANCE,
		0.0
	)
	stage_card.scale = STAGE_SCALE_IN_START
	stage_card.modulate = start_modulate
	stage_card.pivot_offset = stage_card.size * 0.5

	var meta_box := stage_selector_button.get_parent() as Control
	if meta_box != null:
		meta_box.pivot_offset = meta_box.size * 0.5
		meta_box.scale = Vector2(0.96, 0.96)
		meta_box.modulate.a = 0.0

	var tween_in := create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(
		stage_card,
		"position",
		_stage_card_origin,
		STAGE_SLIDE_IN_DURATION
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(
		stage_card,
		"scale",
		Vector2.ONE,
		STAGE_SLIDE_IN_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(
		stage_card,
		"modulate",
		_stage_card_base_modulate,
		STAGE_SLIDE_IN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if meta_box != null:
		tween_in.tween_property(
			meta_box,
			"scale",
			Vector2.ONE,
			STAGE_SLIDE_IN_DURATION
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_in.tween_property(
			meta_box,
			"modulate:a",
			1.0,
			STAGE_SLIDE_IN_DURATION
		)

	tween_in.finished.connect(_on_stage_slide_finished)


func _on_stage_slide_finished() -> void:
	stage_card.position = _stage_card_origin
	stage_card.scale = Vector2.ONE
	stage_card.modulate = _stage_card_base_modulate

	var meta_box := stage_selector_button.get_parent() as Control
	if meta_box != null:
		meta_box.scale = Vector2.ONE
		meta_box.modulate.a = 1.0

	_stage_transition_running = false
	_stage_pending_index = -1
	_stage_pending_direction = 0


func _get_max_browsable_stage_index() -> int:
	if stage_ids.is_empty():
		return 0

	var progress_state := STAGE_PROGRESS.load_state()
	var highest_unlocked := int(
		progress_state.get("highest_unlocked_stage", 1)
	)
	var preview_stage_number := highest_unlocked + 2
	var max_index := 0

	for index in range(stage_ids.size()):
		var stage := STAGE_CATALOG.get_stage(stage_ids[index])
		var stage_number := int(stage.get("number", index + 1))
		if stage_number <= preview_stage_number:
			max_index = index
		else:
			break

	return mini(max_index, stage_ids.size() - 1)


func _refresh_stage_nav_buttons() -> void:
	var max_browsable_index := _get_max_browsable_stage_index()
	var can_go_prev := selected_stage_index > 0
	var can_go_next := selected_stage_index < max_browsable_index

	prev_stage_button.disabled = not can_go_prev
	next_stage_button.disabled = not can_go_next

	var prev_arrow := prev_stage_button.get_node_or_null("ArrowSkin") as CanvasItem
	if prev_arrow != null:
		# Stage 1 has no previous destination: keep the button slot for layout
		# symmetry, but hide the arrow completely.
		prev_arrow.visible = can_go_prev
		if can_go_prev:
			prev_arrow.modulate = Color.WHITE

	_set_stage_arrow_visual(next_stage_button, can_go_next)
	_refresh_stage_selector_buttons(max_browsable_index)


func _setup_stage_selector_buttons() -> void:
	stage_selector_buttons.clear()
	for index in range(stage_ids.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 142.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 23)
		button.add_theme_color_override("font_outline_color", Color("0a0610"))
		button.add_theme_constant_override("outline_size", 3)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.set_meta("audio_cue", "click")
		button.pressed.connect(_on_stage_selected.bind(index))
		stage_select_grid.add_child(button)
		stage_selector_buttons.append(button)


func _refresh_stage_selector_buttons(max_browsable_index: int) -> void:
	if stage_selector_buttons.size() != stage_ids.size():
		return
	for index in range(stage_ids.size()):
		var stage := STAGE_CATALOG.get_stage(stage_ids[index])
		var stage_number := int(stage.get("number", index + 1))
		var display_name := String(stage.get("display_name", "미지의 침입자"))
		if stage_number > int(STAGE_PROGRESS.load_state().get("highest_unlocked_stage", 1)) + 1:
			display_name = "???"
		var button := stage_selector_buttons[index]
		var unlocked := STAGE_PROGRESS.is_stage_unlocked(stage_number)
		var cleared := STAGE_PROGRESS.is_stage_cleared(stage_ids[index])
		var selectable := index <= max_browsable_index
		var selected := index == selected_stage_index
		var state_text := "잠김"
		if selected:
			state_text = "◆ 현재 선택 ◆"
		elif cleared:
			state_text = "토벌 완료"
		elif unlocked:
			state_text = "입장 가능"
		elif selectable:
			state_text = "미리보기"
		button.text = "STAGE %02d\n%s\n%s" % [
			stage_number,
			display_name,
			state_text,
		]
		button.disabled = not selectable
		var normal_style: StyleBox = (
			stage_selector_current_style
			if selected
			else stage_selector_item_style
		)
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", stage_selector_current_style)
		button.add_theme_stylebox_override("pressed", stage_selector_current_style)
		button.add_theme_stylebox_override("disabled", stage_selector_disabled_style)
		button.add_theme_color_override(
			"font_color",
			Color("fff0b4") if selected else Color("eee4f1")
		)
		button.add_theme_color_override("font_hover_color", Color("ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("ffe079"))
		button.add_theme_color_override("font_disabled_color", Color("6f6673"))
		PIXEL_PANEL_SKIN.apply(button)


func _set_stage_arrow_visual(button: Button, enabled: bool) -> void:
	if button == null:
		return

	var arrow_skin := button.get_node_or_null("ArrowSkin") as CanvasItem
	if arrow_skin == null:
		return

	arrow_skin.visible = true
	arrow_skin.modulate = (
		Color.WHITE
		if enabled
		else Color(0.42, 0.42, 0.48, 0.58)
	)


func _refresh_stage_card() -> void:
	stage_selector_button.disabled = false
	if stage_ids.is_empty():
		return

	selected_stage_index = clampi(
		selected_stage_index,
		0,
		_get_max_browsable_stage_index()
	)

	var stage_id := stage_ids[selected_stage_index]
	var stage := STAGE_CATALOG.get_stage(stage_id)
	var stage_number := int(stage.get("number", selected_stage_index + 1))
	var hero_profile := HERO_PROFILES.get_profile(
		String(stage.get("hero_id", ""))
	)
	var hero_name := String(hero_profile.get("display_name", "정체불명의 용사"))
	var unlocked := STAGE_PROGRESS.is_stage_unlocked(stage_number)
	var cleared := STAGE_PROGRESS.is_stage_cleared(stage_id)
	var reward_claimed := STAGE_PROGRESS.is_reward_claimed(stage_id)
	var reward := int(stage.get("first_clear_reward", 0))
	var run_reward_multiplier := float(stage.get("run_reward_multiplier", 1.0))
	var duration_seconds := float(stage.get("run_duration_seconds", 0.0))
	var minutes := int(round(duration_seconds / 60.0))

	stage_selector_button.text = "STAGE %02d  ·  목록 선택" % stage_number
	stage_name_label.text = String(stage.get("display_name", "미지의 침입자"))
	hero_name_label.text = hero_name
	stage_description_label.text = String(
		stage.get(
			"lobby_description",
			"이 침입자의 전투 패턴을 관찰하고 카운터를 준비하세요."
		)
	)

	var entry_state := (
		"클리어 완료"
		if cleared
		else ("입장 가능" if unlocked else "잠김")
	)
	var time_text := "제한 %d분" % minutes if minutes > 0 else "시간 제한 없음"
	stage_status_label.text = "%s\n%s" % [entry_state, time_text]

	if not STAGE_PROGRESS.is_gold_reward_claimed(stage_id):
		stage_reward_label.text = "최초 보상\n골드%d" % int(STAGE_CATALOG.CLEAR_GOLD_REWARDS.stage_first_clear)
		if not reward_claimed and reward > 0:
			stage_reward_label.text += " · 연구%d" % reward
	elif reward_claimed:
		stage_reward_label.text = "최초 보상\n획득 완료"
	elif reward > 0:
		stage_reward_label.text = "최초 보상\n연구 +%d" % reward
	else:
		stage_reward_label.text = "최초 보상\n-"

	var repeat_label := stage_description_label.get_parent().get_node_or_null(
		"RepeatReward"
	) as Label
	if repeat_label != null:
		repeat_label.text = "반복 보상\n×%.2f" % run_reward_multiplier

	enter_stage_button.disabled = not unlocked
	var entry_cost: int = 0 if LocalTestMode.active or TutorialFlow.active() else STAMINA_RULES.ENTRY_COST
	enter_stage_button.text = "던전 입장" if unlocked else "스테이지 잠김"
	if stamina_view != null:
		stamina_view.configure_entry(unlocked, entry_cost)

	_refresh_stage_nav_buttons()

	portrait_badge.visible = false
	_apply_portrait(String(stage.get("portrait_path", "")), hero_name)
	var highest := int(STAGE_PROGRESS.load_state().get("highest_unlocked_stage", 1))
	var silhouette := stage_number > highest + 1
	portrait_texture.self_modulate = Color.BLACK if silhouette else (Color(0.28,0.25,0.33,1) if not unlocked else Color.WHITE)
	portrait_badge.visible = not unlocked
	portrait_badge.text = "미지의 침입자" if silhouette else "잠김 · Stage %d 클리어 필요" % (stage_number-1)
	var lock_icon := portrait_texture.get_node_or_null("StageLock")
	if lock_icon == null:
		lock_icon = load("res://src/ui/stage_lock_icon.gd").new()
		lock_icon.name = "StageLock"
		portrait_texture.add_child(lock_icon)
		lock_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_icon.offset_left = -32
		lock_icon.offset_right = 32
		lock_icon.offset_top = -120
		lock_icon.offset_bottom = -40
	lock_icon.visible = not unlocked and not silhouette
	if not unlocked:
		enter_stage_button.text = "Stage %d 클리어 필요" % (stage_number-1)
		stage_status_label.text = "잠김\nStage %d 클리어 필요" % (stage_number-1)
	if silhouette:
		hero_name_label.text = "???"
		stage_name_label.text = "미지의 침입자"
		stage_description_label.text = "앞선 스테이지를 클리어하면 정체가 밝혀집니다."
	if main_modes_view != null:
		main_modes_view.refresh()

func prepare_presentation() -> void:
	if _presentation_ready:
		return
	await _precache_stage_portraits()
	_refresh_stage_card()
	_presentation_ready = true
	if main_modes_view != null:
		main_modes_view.schedule_unlock()

func _check_mode_unlock_feedback() -> void:
	if main_modes_view != null:
		main_modes_view.show_pending_unlock()


func _precache_stage_portraits() -> void:
	if stage_ids.is_empty():
		return

	var max_index := _get_max_browsable_stage_index()
	for index in range(max_index + 1):
		var stage := STAGE_CATALOG.get_stage(stage_ids[index])
		var portrait_path := String(stage.get("portrait_path", ""))
		if portrait_path.is_empty():
			continue
		if not _portrait_texture_cache.has(portrait_path):
			var texture := _load_texture(portrait_path)
			if texture == null:
				continue
			_portrait_texture_cache[portrait_path] = _normalize_hero_portrait_texture(texture)
		# Upload/render the FINAL normalized texture below the transition cover.
		# Preloading the original PNG alone does not prepare this derived image.
		portrait_texture.texture = _portrait_texture_cache[portrait_path] as Texture2D
		portrait_texture.visible = portrait_texture.texture != null
		if DisplayServer.get_name() == "headless":
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw


func _apply_portrait(path: String, hero_name: String) -> void:
	var normalized_texture: Texture2D = null

	if not path.is_empty() and _portrait_texture_cache.has(path):
		normalized_texture = _portrait_texture_cache[path] as Texture2D
	else:
		var texture := _load_texture(path)
		normalized_texture = _normalize_hero_portrait_texture(texture)
		if not path.is_empty() and normalized_texture != null:
			_portrait_texture_cache[path] = normalized_texture

	portrait_texture.texture = normalized_texture
	portrait_texture.visible = normalized_texture != null
	portrait_placeholder.visible = normalized_texture == null
	portrait_placeholder.text = "%s\n\n초상화 준비 중" % hero_name


func _normalize_hero_portrait_texture(
	source_texture: Texture2D
) -> Texture2D:
	if source_texture == null:
		return null
	_portrait_normalization_count += 1

	var source_image := source_texture.get_image()
	if source_image == null or source_image.is_empty():
		return source_texture

	if _portrait_reference_image == null:
		var reference_texture := _load_texture(HERO_PORTRAIT_REFERENCE_PATH)
		if reference_texture != null:
			_portrait_reference_image = reference_texture.get_image()
			_portrait_reference_rect = _get_alpha_visible_rect(_portrait_reference_image)
	var reference_image := _portrait_reference_image
	if reference_image == null or reference_image.is_empty():
		return source_texture

	var source_rect := _get_alpha_visible_rect(source_image)
	var reference_rect := _portrait_reference_rect
	if (
		source_rect.size.x <= 0
		or source_rect.size.y <= 0
		or reference_rect.size.x <= 0
		or reference_rect.size.y <= 0
	):
		return source_texture

	var cropped := source_image.get_region(source_rect)
	if cropped == null or cropped.is_empty():
		return source_texture

	var target_height := reference_rect.size.y
	var scale_ratio := (
		float(target_height)
		/ float(maxi(source_rect.size.y, 1))
	)
	var target_width := maxi(
		1,
		int(round(
			float(source_rect.size.x)
			* scale_ratio
		))
	)

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

	var target_center := Vector2i(
		reference_rect.position.x
			+ reference_rect.size.x / 2,
		reference_rect.position.y
			+ reference_rect.size.y / 2
	)
	var paste_position := Vector2i(
		target_center.x - target_width / 2,
		target_center.y - target_height / 2
	)
	canvas.blit_rect(
		cropped,
		Rect2i(Vector2i.ZERO, cropped.get_size()),
		paste_position
	)

	return ImageTexture.create_from_image(canvas)

func _get_alpha_visible_rect(
	image: Image,
	alpha_threshold: float = 0.05
) -> Rect2i:
	if image == null or image.is_empty():
		return Rect2i()

	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= alpha_threshold:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return Rect2i()

	return Rect2i(
		min_x,
		min_y,
		max_x - min_x + 1,
		max_y - min_y + 1
	)

func _load_texture(path: String) -> Texture2D:
	var prepared := PresentationWarmup.get_texture(path)
	if prepared != null:
		return prepared
	if path.is_empty():
		return null

	# Lobby portraits are loaded only a handful of times and then cached.
	# Prefer the source image so a fresh git pull cannot show a stale
	# .godot/imported texture from another machine/project state.
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)

	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource

	return null

func _refund_failed_stamina_entry() -> void:
	if not _battle_entry_pending:
		return
	if not STAMINA.refund_failed_entry(_stamina_entry):
		push_warning("입장 실패 스테미너 복원 저장 실패")
	_battle_entry_pending = false
	_stamina_entry = {}
	_refresh_stage_card()
	if stamina_view != null:
		stamina_view.refresh()

func _enter_selected_stage(allow_unregistered: bool = false) -> void:
	if _battle_entry_pending or _scene_load_pending or SceneTransition.is_transitioning():
		return
	if main_modes_view != null and main_modes_view.blocks_entry():
		return
	if stage_ids.is_empty():
		return

	var stage_id := stage_ids[selected_stage_index]
	var stage := STAGE_CATALOG.get_stage(stage_id)
	if stage.is_empty():
		return

	var stage_number := int(stage.get("number", 999))
	if not STAGE_PROGRESS.is_stage_unlocked(stage_number):
		return

	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var exempt := LocalTestMode.active or TutorialFlow.active()
	var formation_reason := preload("res://src/systems/dungeon_entry_policy.gd").blocked_reason(team_selected_ids, demon_skill_selected_ids, exempt)
	if not formation_reason.is_empty():
		stamina_view.show_info(formation_reason)
		return
	if not allow_unregistered and not TutorialFlow.active() and preload("res://src/systems/transcendence_loadout_store.gd").load_id().is_empty():
		if not is_instance_valid(_transcendence_entry_confirm):
			_transcendence_entry_confirm = preload("res://src/ui/transcendence_entry_confirm.gd").new()
			_transcendence_entry_confirm.install(self)
		_transcendence_entry_confirm.open(_enter_selected_stage.bind(true))
		return
	_stamina_entry = STAMINA.try_enter(stage_id, exempt)
	if not bool(_stamina_entry.get("success", false)):
		stamina_view.show_info("스테미너가 부족합니다." if _stamina_entry.get("reason") == "insufficient" else "저장을 확인하고 다시 시도해 주세요.")
		return
	_battle_entry_pending = true
	enter_stage_button.disabled = true
	await stamina_view.play_entry_cost(int(_stamina_entry.get("charged", 0)))
	if is_inside_tree():
		_begin_threaded_scene_change(BATTLE_SCENE_PATH)


func _begin_threaded_scene_change(path: String) -> void:
	if _scene_load_pending or path.is_empty():
		return

	var transition := get_node_or_null("/root/SceneTransition")
	if (
		is_instance_valid(transition)
		and transition.has_method("change_scene")
		and bool(transition.call(
			"change_scene",
			path,
			"던전 불러오는 중..."
		))
	):
		enter_stage_button.disabled = true
		enter_stage_button.text = "던전 준비 중..."
		return

	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		if get_tree().change_scene_to_file(path) != OK:
			_refund_failed_stamina_entry()
		return

	_scene_load_path = path
	_scene_load_pending = true
	enter_stage_button.disabled = true
	enter_stage_button.text = "던전 준비 중..."

func _rebuild_research_list() -> void:
	for child in research_list.get_children():
		research_list.remove_child(child)
		child.free()
	research_buttons_by_id.clear()

	var research_points := STAGE_PROGRESS.get_research_points()
	research_points_label.text = "보유 연구 포인트  %s" % _format_shop_number(
		research_points
	)

	var research_ids: Array[String] = RESEARCH_CATALOG.get_ordered_ids()
	if selected_research_id.is_empty() and not research_ids.is_empty():
		selected_research_id = research_ids[0]

	for research_id in research_ids:
		var data := RESEARCH_CATALOG.get_research(research_id)
		if data.is_empty():
			continue

		var level := STAGE_PROGRESS.get_research_level(research_id)
		var max_level := int(data.get("max_level", 0))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 112)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		var selected := research_id == selected_research_id
		_apply_lobby_button_skin(button, selected, 21)

		if level >= max_level:
			button.text = "%s    Lv.%d / %d\n%s    ·    연구 완료" % [
				String(data.get("name", research_id)),
				level,
				max_level,
				RESEARCH_CATALOG.get_effect_summary(research_id, level),
			]
		else:
			var cost := RESEARCH_CATALOG.get_cost(research_id, level)
			button.text = "%s    Lv.%d / %d\n%s    ·    비용 %s" % [
				String(data.get("name", research_id)),
				level,
				max_level,
				RESEARCH_CATALOG.get_effect_summary(research_id, level),
				_format_shop_number(cost),
			]
		button.set_meta("audio_cue", "click")
		button.pressed.connect(_select_research.bind(research_id))

		research_list.add_child(button)
		research_buttons_by_id[research_id] = button

	_refresh_research_detail()
	_rebuild_relic_grid()
	_refresh_research_mode_buttons()


func _show_research_mode(mode: String) -> void:
	research_view_mode = "relic" if mode == "relic" else "research"
	research_content.visible = research_view_mode == "research"
	relic_content.visible = research_view_mode == "relic"
	_refresh_research_mode_buttons()
	if research_view_mode == "research":
		research_status_label.text = "연구를 선택하고 상단에서 강화합니다."
		_refresh_research_detail()
	else:
		research_status_label.text = "유물 데이터·소환·강화 시스템 추가 대기 중"
		_rebuild_relic_grid()


func _refresh_research_mode_buttons() -> void:
	_apply_lobby_button_skin(
		research_mode_button,
		research_view_mode == "research",
		22
	)
	_apply_lobby_button_skin(
		relic_mode_button,
		research_view_mode == "relic",
		22
	)


func _select_research(research_id: String) -> void:
	if RESEARCH_CATALOG.get_research(research_id).is_empty():
		return
	selected_research_id = research_id
	_refresh_research_card_styles()
	_refresh_research_detail()


func _refresh_research_card_styles() -> void:
	for raw_id in research_buttons_by_id:
		var research_id := String(raw_id)
		var button := research_buttons_by_id.get(research_id) as Button
		if not is_instance_valid(button):
			continue
		_apply_lobby_button_skin(
			button,
			research_id == selected_research_id,
			21
		)


func _refresh_research_detail() -> void:
	var data := RESEARCH_CATALOG.get_research(selected_research_id)
	if data.is_empty():
		research_detail_name.text = "연구를 선택하세요"
		research_detail_level.text = "Lv.0 / 0"
		research_detail_effect.text = "현재 효과를 표시합니다."
		research_detail_description.text = "아래 연구 목록에서 항목을 선택하세요."
		research_detail_cost.text = "필요 포인트  -"
		research_upgrade_button.disabled = true
		return

	var level := STAGE_PROGRESS.get_research_level(selected_research_id)
	var max_level := int(data.get("max_level", 0))
	research_detail_name.text = String(data.get("name", selected_research_id))
	research_detail_level.text = "Lv.%d / %d" % [level, max_level]
	research_detail_description.text = String(data.get("description", ""))
	if level >= max_level:
		research_detail_effect.text = RESEARCH_CATALOG.get_effect_summary(
			selected_research_id,
			level
		)
		research_detail_cost.text = "최대 레벨 달성"
		research_upgrade_button.text = "연구 완료"
		research_upgrade_button.disabled = true
		return

	var cost := RESEARCH_CATALOG.get_cost(selected_research_id, level)
	research_detail_effect.text = "현재  %s\n다음  %s" % [
		RESEARCH_CATALOG.get_effect_summary(selected_research_id, level),
		RESEARCH_CATALOG.get_effect_summary(selected_research_id, level + 1),
	]
	research_detail_cost.text = "필요 포인트  %s" % _format_shop_number(cost)
	research_upgrade_button.text = "강화하기"
	research_upgrade_button.disabled = STAGE_PROGRESS.get_research_points() < cost
	research_upgrade_button.add_theme_stylebox_override(
		"disabled",
		PIXEL_PANEL_SKIN.button_style(primary_button_disabled_style)
	)


func _purchase_selected_research() -> void:
	var data := RESEARCH_CATALOG.get_research(selected_research_id)
	if data.is_empty():
		return

	var level := STAGE_PROGRESS.get_research_level(selected_research_id)
	var max_level := int(data.get("max_level", 0))
	var cost := RESEARCH_CATALOG.get_cost(selected_research_id, level)
	var result := STAGE_PROGRESS.try_purchase_research(
		selected_research_id,
		cost,
		max_level
	)

	if bool(result.get("success", false)):
		research_status_label.text = "%s Lv.%d 연구 완료" % [
			String(data.get("name", selected_research_id)),
			int(result.get("level", level + 1)),
		]
	else:
		research_status_label.text = "연구 포인트가 부족하거나 이미 완료된 연구입니다."
	GameAudio.feedback("research" if bool(result.get("success", false)) else "denied")

	_refresh_header()
	_rebuild_research_list.call_deferred()


func _select_relic_category(category_id: String) -> void:
	if category_id not in RELIC_CATALOG.CATEGORY_ORDER:
		return
	selected_relic_category = category_id
	_rebuild_relic_grid()


func _rebuild_relic_grid() -> void:
	for child in relic_grid.get_children():
		relic_grid.remove_child(child)
		child.free()

	for index in range(mini(
		relic_filter_buttons.size(),
		RELIC_CATALOG.CATEGORY_ORDER.size()
	)):
		var category_id := String(RELIC_CATALOG.CATEGORY_ORDER[index])
		_apply_lobby_button_skin(
			relic_filter_buttons[index],
			category_id == selected_relic_category,
			18
		)

	var relic_ids := RELIC_CATALOG.get_ordered_ids(selected_relic_category)
	relic_empty_label.visible = relic_ids.is_empty()
	for relic_id in relic_ids:
		var data := RELIC_CATALOG.get_relic(relic_id)
		if data.is_empty():
			continue
		relic_grid.add_child(_create_relic_card(relic_id, data))

	if not selected_relic_id.is_empty():
		var selected_data := RELIC_CATALOG.get_relic(selected_relic_id)
		if (
			selected_data.is_empty()
			or (
				selected_relic_category != "all"
				and String(selected_data.get("category", "utility"))
				!= selected_relic_category
			)
		):
			selected_relic_id = ""
	_refresh_relic_detail()


func _create_relic_card(relic_id: String, data: Dictionary) -> Button:
	var progress := _get_relic_progress(relic_id)
	var fragments := maxi(int(progress.get("fragments", 0)), 0)
	var required := maxi(int(data.get("required_fragments", 30)), 1)
	var can_upgrade := fragments >= required

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 220)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_lobby_button_skin(card, relic_id == selected_relic_id, 16)
	card.set_meta("audio_cue", "click")
	card.pressed.connect(_select_relic.bind(relic_id))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12.0
	content.offset_top = 12.0
	content.offset_right = -12.0
	content.offset_bottom = -12.0
	content.add_theme_constant_override("separation", 5)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, 104)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path := String(data.get("icon_path", ""))
	if not icon_path.is_empty():
		icon.texture = _load_texture(icon_path)
	content.add_child(icon)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.text = String(data.get("name", relic_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(name_label)

	var gauge := ProgressBar.new()
	gauge.custom_minimum_size = Vector2(0, 24)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.max_value = float(required)
	gauge.value = float(mini(fragments, required))
	gauge.show_percentage = false
	gauge.add_theme_stylebox_override(
		"background",
		_make_hud_panel_style(Color("17131d"), Color("51485a"), 1, 7)
	)
	gauge.add_theme_stylebox_override(
		"fill",
		_make_hud_panel_style(
			Color("4faa70") if can_upgrade else Color("77727d"),
			Color("7de09b") if can_upgrade else Color("9a949f"),
			1,
			7
		)
	)
	content.add_child(gauge)

	var gauge_label := Label.new()
	gauge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_label.add_theme_font_size_override("font_size", 15)
	gauge_label.text = "[ %d / %d ]" % [fragments, required]
	gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(gauge_label)
	PIXEL_PANEL_SKIN.apply_tree(card)
	return card


func _get_relic_progress(relic_id: String) -> Dictionary:
	var progress = relic_progress_state.get(relic_id, {})
	if typeof(progress) != TYPE_DICTIONARY:
		return {"level": 0, "fragments": 0}
	return progress


func _select_relic(relic_id: String) -> void:
	if RELIC_CATALOG.get_relic(relic_id).is_empty():
		return
	selected_relic_id = relic_id
	_rebuild_relic_grid()


func _refresh_relic_detail() -> void:
	var data := RELIC_CATALOG.get_relic(selected_relic_id)
	if data.is_empty():
		relic_detail_icon.texture = null
		relic_detail_placeholder.show()
		relic_detail_name.text = "유물을 선택하세요"
		relic_detail_level.text = "Lv.0"
		relic_detail_effect.text = (
			"유물 소환에서 조각을 획득하면 효과를 확인할 수 있습니다."
		)
		relic_detail_gauge.text = "[ 0 / 30 ]"
		relic_upgrade_button.text = "조각 부족"
		relic_upgrade_button.disabled = true
		return

	var progress := _get_relic_progress(selected_relic_id)
	var level := maxi(int(progress.get("level", 0)), 0)
	var fragments := maxi(int(progress.get("fragments", 0)), 0)
	var required := maxi(int(data.get("required_fragments", 30)), 1)
	var icon_path := String(data.get("icon_path", ""))
	relic_detail_icon.texture = (
		_load_texture(icon_path) if not icon_path.is_empty() else null
	)
	relic_detail_placeholder.visible = relic_detail_icon.texture == null
	relic_detail_name.text = String(data.get("name", selected_relic_id))
	relic_detail_level.text = "Lv.%d" % level
	relic_detail_effect.text = String(data.get("effect_text", "효과 정보 준비 중"))
	relic_detail_gauge.text = "[ %d / %d ]" % [fragments, required]
	relic_upgrade_button.disabled = fragments < required
	relic_upgrade_button.text = (
		"완성하기" if level <= 0 and fragments >= required
		else "레벨업" if fragments >= required
		else "조각 부족"
	)
	relic_upgrade_button.add_theme_stylebox_override(
		"disabled",
		primary_button_disabled_style
	)


func _show_relic_upgrade_placeholder() -> void:
	research_status_label.text = "유물 강화 저장 시스템은 다음 단계에서 연결합니다."

func _enter_practice_battle() -> void:
	if _scene_load_pending or _battle_entry_pending or SceneTransition.is_transitioning():
		return
	if not LocalTestMode.request_practice_battle():
		return
	if not SceneTransition.change_scene(BATTLE_SCENE_PATH,"연습전투 준비 중..."):
		LocalTestMode.practice_requested = false
