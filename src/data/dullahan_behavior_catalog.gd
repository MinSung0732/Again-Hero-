extends RefCounted

const BASE := {"max_hp": 420, "move_speed": 58.0, "attack_damage": 32, "attack_range": 88.0, "attack_cooldown": 1.2, "exp_reward": 90}
const PASSIVE := {"revive_hp_ratio": 0.15, "lifesteal_ratio": 0.40}
const DANGER := {"threshold": 0.20, "cooldown": 20.0, "speed_multiplier": 3.25, "escape_distance": 300.0, "escape_timeout": 2.0, "rest_duration": 3.0, "recover_hp_ratio": 0.50}

const NORMAL_VISUAL := {"mode": "frames", "asset_dir": "res://assets/art/monsters/Dullahan/frames", "target_height": 230.0, "animations": {
	"idle": {"prefix":"idle", "count":4, "fps":6.0, "loop":true},
	"move": {"prefix":"walk", "count":6, "fps":9.0, "loop":true},
	"attack": {"prefix":"atk", "count":6, "fps":12.0, "loop":false},
	"hit": {"prefix":"hit", "count":2, "fps":12.0, "loop":false},
	"death": {"prefix":"dead", "count":4, "fps":10.0, "loop":false},
}}
