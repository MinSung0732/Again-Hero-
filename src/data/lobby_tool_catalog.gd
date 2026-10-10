extends RefCounted

# Order within each side follows this list. New tools need one entry and an action.
const ENTRIES := [
	{"id": &"daily", "title": "도전과제", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/daily_mission.png"},
	{"id": &"weekly", "title": "이벤트", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/weekly_mission.png", "empty_message": "아직 진행 중인 이벤트가 없습니다."},
	{"id": &"exploration", "title": "탐색보상", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/exploration_reward.png"},
	{"id": &"friends", "title": "친구목록", "side": &"right", "icon": "res://assets/art/UI/lobby_tools/friends.png"},
]
