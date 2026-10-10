extends RefCounted

# Tuning stays here; elapsed time is computed in O(1), not one loop per minute.
const SECONDS_PER_PERCENT := 180
const MAX_PERCENT := 300
const MIN_PERCENT_EXCLUSIVE := 50
const GOLD_PER_PERCENT := 2
const RESEARCH_PER_PERCENT := 1
const CHECKPOINT_SECONDS := 60.0
const MAX_SECONDS := SECONDS_PER_PERCENT * MAX_PERCENT
const ICON_PATH := "res://assets/art/UI/lobby_tools/exploration_reward.png"
const BADGE_PATH := "res://assets/art/UI/lobby_tools/notification_dot.svg"
const GOLD_ICON_PATH := "res://assets/art/UI/lobby_header/coin.svg"
const RESEARCH_ICON_PATH := "res://assets/art/UI/lobby_footer/icon_research.svg"
