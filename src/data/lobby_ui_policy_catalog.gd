extends RefCounted

const DEFAULT_SETTINGS_TAB := "game"
const NOTICE_PATH := "user://notification_settings.cfg"
const GAMEPLAY_SECTION := "gameplay"
const OTHER_ENTRIES := [["profile", "프로필"], ["mailbox", "우편함"], ["demon_book", "마왕도감"], ["hero_book", "용사도감"], ["rank_history", "랭킹기록"], ["practice", "연습전투"], ["settings", "설정"]]
const MENU_ARROW := "  ›"
const COMING_SOON := "\n준비 중"
const OTHER_ACTIONS := {
	"profile": {"method": "show_profile"},
	"mailbox": {"method": "show_mailbox"},
	"demon_book": {"method": "show_demon_codex"},
	"hero_book": {"method": "show_hero_codex"},
	"practice": {"method": "_enter_practice_battle", "target": "lobby", "visible_if": "is_practice_allowed", "text": "연습전투  ›\n무한 체력 도망 더미 · 등록한 초월 기술 확인"},
	"settings": {"method": "_open_settings"},
}
const TABS := [["game", "게임"], ["sound", "소리"], ["notice", "알림"], ["account", "계정"], ["misc", "기타"]]
const TAB_HOSTS := {
	"sound": {"button": "other_settings_tab_button", "page": "other_settings_panel", "override_label": true},
	"account": {"button": "other_account_tab_button", "page": "other_account_panel", "account_header": true},
}
const OTHER_VIEWS := {
	"profile": {"property": "profile_view", "back_height": 88.0},
	"mailbox": {"property": "mailbox_view", "back_height": 88.0},
	"hero_book": {"property": "hero_codex_view", "back_height": 88.0},
	"demon_book": {"property": "demon_codex_view", "back_height": 56.0},
}
const DEFAULT_BACK_HEIGHT := 88.0
const TAB_BUTTON_HEIGHT := 102.0
const MENU_BUTTON_HEIGHT := 132.0
const GAME_OPTIONS := [
	{"key": "camera_view_locked", "title": "화면 고정", "description": "켜면 용사를 따라갑니다. 끄면 드래그로 화면을 이동합니다.", "default": true, "force_in_hero": true},
	{"key": "battle_frame_enabled", "title": "배틀 프레임", "description": "전장 주변의 마왕성 장식 프레임을 표시합니다.", "default": true},
]

static func game_option(key: String) -> Dictionary:
	# Bounded settings metadata, consulted only on a UI action, never per frame.
	for option in GAME_OPTIONS:
		if option.key == key: return option
	return {}
