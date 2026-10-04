extends RefCounted

const LOBBY_PATH := "res://src/lobby/Lobby.tscn"
const CASTLE_PATH := "res://assets/art/UI/startup/moon_castle.png"
const CAMP_PATH := "res://assets/art/UI/startup/moon_camp.png"
const LOGO_PATH := "res://assets/art/UI/logo/AgainHeroLogo.png"
const CORE_RESOURCES := [
	"res://src/ui/game_theme.tres",
	"res://assets/art/UI/loading/loadingframes/loading_logo_01.png",
	"res://assets/art/UI/lobby_footer/nav_frame.svg",
]
const PROVIDERS := [
	{"id": "google", "label": "Google로 로그인", "color": Color("f4f0f8"), "ink": Color("21182f")},
	{"id": "kakao", "label": "카카오로 로그인", "color": Color("fee500"), "ink": Color("241d13")},
]
const TIPS := [
	"용사의 빌드를 관찰하고, 몬스터 조합으로 대응하세요.",
	"몬스터 카드를 길게 누르면 원하는 편성 칸으로 옮길 수 있어요.",
	"몬스터 조각을 모으면 HP와 공격력을 강화할 수 있어요.",
	"연구 효과는 다음 던전 도전부터 적용됩니다.",
]
