extends RefCounted
## Shared AI tuning for how a hero seeks battlefield pickups while fighting.
## Personality scaling stays in hero profile `ai_settings`
## (heal_item_desire / heal_risk_tolerance / heal_detour_weight).
## Paired *_FROM/*_TO values are lerp endpoints; *_SPAN keeps ratio divisors
## exact instead of deriving them from subtraction.

# --- Heal item goal selection ---------------------------------------------
const HEAL_CLEAR_HP_RATIO := 0.60
const HEAL_COMMIT_HP_RATIO := 0.40
const HEAL_RETARGET_INTERVAL_MIN := 0.22
const HEAL_RETARGET_INTERVAL_MAX := 0.38
const HEAL_GOAL_CRITICAL_HP_RATIO := 0.45
const HEAL_GOAL_CRITICAL_SPAN := 0.35
const HEAL_DETOUR_MAX_DISTANCE := 520.0
const HEAL_PATH_DANGER_RADIUS := 260.0
const HEAL_ITEM_DANGER_RADIUS := 220.0
const HEAL_PATH_DANGER_WEIGHT := 0.70
const HEAL_DISTANCE_PENALTY_DIVISOR := 1050.0
const HEAL_DISTANCE_PENALTY_CAP := 2.2
const HEAL_DANGER_SCALE_FROM := 1.0
const HEAL_DANGER_SCALE_TO := 0.22
const HEAL_RISK_SCALE_FROM := 1.30
const HEAL_RISK_SCALE_TO := 0.50
const HEAL_SCORE_FROM := 4.2
const HEAL_SCORE_TO := 7.2
const HEAL_MIN_SCORE := 0.05

# Desire by HP ratio. First band whose hp_min <= hp wins; banded entries lerp
# from->to as HP falls from hp_max over span. The last band is the floor.
const HEAL_DESIRE_BANDS: Array[Dictionary] = [
	{"hp_min": 0.60, "value": 0.0},
	{"hp_min": 0.45, "hp_max": 0.60, "span": 0.15, "from": 0.20, "to": 0.48},
	{"hp_min": 0.30, "hp_max": 0.45, "span": 0.15, "from": 0.62, "to": 0.88},
	{"hp_min": 0.15, "hp_max": 0.30, "span": 0.15, "from": 1.00, "to": 1.18},
	{"hp_min": 0.0, "value": 1.30},
]

# --- Heal item steering ---------------------------------------------------
const HEAL_STEER_CROWD_RADIUS := 240.0
const HEAL_STEER_DANGER_RADIUS := 210.0
const HEAL_STEER_CRITICAL_HP_RATIO := 0.50
const HEAL_STEER_CRITICAL_SPAN := 0.20
const HEAL_CLOSE_COMMIT_DISTANCE := 220.0
const HEAL_CLOSE_COMMIT_SPAN := 150.0
const HEAL_WEIGHT_CRITICAL_FROM := 1.10
const HEAL_WEIGHT_CRITICAL_TO := 1.75
const HEAL_WEIGHT_CLOSE_FROM := 1.0
const HEAL_WEIGHT_CLOSE_TO := 1.65
const HEAL_WEIGHT_CAP := 2.60
const HEAL_COMBAT_WEIGHT_FLOOR := 0.38
const HEAL_COMBAT_WEIGHT_REDUCTION := 0.45
const HEAL_COMBAT_WEIGHT_COMMITTED := 0.16
const HEAL_COMMIT_CRITICAL_FROM := 0.55
const HEAL_COMMIT_CRITICAL_TO := 1.0
const HEAL_AVOID_BASE := 0.55
const HEAL_AVOID_DANGER_WEIGHT := 0.28
const HEAL_AVOID_RISK_FROM := 1.12
const HEAL_AVOID_RISK_TO := 0.68
const HEAL_AVOID_CRITICAL_FROM := 1.0
const HEAL_AVOID_CRITICAL_TO := 0.35
const HEAL_AVOID_CLOSE_FROM := 1.0
const HEAL_AVOID_CLOSE_TO := 0.18
const HEAL_FINAL_APPROACH_DISTANCE := 95.0
const HEAL_FINAL_APPROACH_KEEP := 0.28
const HEAL_FINAL_APPROACH_PULL := 1.45
const HEAL_TURN_SPEED_FROM := 4.2
const HEAL_TURN_SPEED_TO := 8.5

# Chest/magnet detours yield to a committed potion at or below this HP.
const HEAL_PRIORITY_HP_RATIO := 0.45

# --- Treasure chest -------------------------------------------------------
const CHEST_RETARGET_INTERVAL := 0.45
const CHEST_WEIGHT_FROM := 0.22
const CHEST_WEIGHT_TO := 0.42
const CHEST_WEIGHT_DISTANCE := 1100.0
const CHEST_TURN_SPEED := 2.4

# --- Magnet item ----------------------------------------------------------
const MAGNET_RETARGET_INTERVAL := 0.30
const MAGNET_WEIGHT_FROM := 0.24
const MAGNET_WEIGHT_TO := 0.38
const MAGNET_WEIGHT_DISTANCE := 720.0
const MAGNET_DANGER_RADIUS := 210.0
const MAGNET_DANGER_DAMPING := 0.22
const MAGNET_TURN_SPEED := 3.2


static func heal_desire_for_hp(hp_ratio: float) -> float:
	for band in HEAL_DESIRE_BANDS:
		if hp_ratio < float(band.hp_min):
			continue
		if band.has("value"):
			return float(band.value)
		return lerpf(
			float(band.from),
			float(band.to),
			(float(band.hp_max) - hp_ratio) / float(band.span)
		)
	return float(HEAL_DESIRE_BANDS[-1].get("value", 0.0))
