extends RefCounted

# Order within each side follows this list. New tools need one entry and an action.
const ENTRIES := [
	{"id": &"daily", "title": "일일미션", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/daily_mission.png"},
	{"id": &"weekly", "title": "주간미션", "side": &"left", "icon": "res://assets/art/UI/lobby_tools/weekly_mission.png"},
	{"id": &"friends", "title": "친구목록", "side": &"right", "icon": "res://assets/art/UI/lobby_tools/friends.png"},
]
