extends RefCounted

# Order within each side follows this list. New tools need one entry and an action.
const ENTRIES := [
	{"id": &"daily", "title": "도전과제", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/daily_mission.png"},
	{"id": &"weekly", "title": "이벤트", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/weekly_mission.png", "empty_message": "아직 진행 중인 이벤트가 없습니다."},
	{"id": &"exploration", "title": "탐색보상", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/exploration_reward.png"},
	{"id": &"friends", "title": "친구목록", "side": &"right", "icon": "res://assets/art/UI/lobby_tools/friends.png"},
]

const SIDES := [&"left", &"right"]
const SIDE_TITLES := {&"left": "미션 · 이벤트", &"right": "친구 · 커뮤니티"}
const BUTTON_SIZE := Vector2(104, 108)
const GAP := 8.0
const EDGE_MARGIN := 8.0
const TOP_OFFSET := 190.0
const DIRECT_LIMIT := 3
const BADGE_PATH := "res://assets/art/UI/lobby_tools/notification_dot.svg"
const MORE_TITLE := "더보기"
const TOOL_TITLE := "도구"
const EMPTY_MESSAGE := "이 기능은 준비 중입니다.\n업데이트 후 이 버튼에서 이용할 수 있습니다."
const CLOSE_TITLE := "닫기"
