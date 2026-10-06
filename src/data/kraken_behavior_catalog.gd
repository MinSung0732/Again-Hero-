extends RefCounted

const BASE := {"max_hp": 155, "move_speed": 0.0, "attack_damage": 66, "attack_range": 1000.0, "attack_cooldown": 5.0, "exp_reward": 95}
const ATTACK := {"count": 3, "duration": 2.0, "scatter_radius": 100.0, "hit_radius": 115.0, "growth_hits": 3, "growth_per_stack": 0.001}
const DEATH := {"count": 8, "radius": 155.0, "damage_divisor": 3.0}
const NORMAL_VISUAL := {"mode": "frames", "asset_dir": "res://assets/art/monsters/Kraken/frames", "target_height": 150.0, "animations": {
	"idle": {"prefix":"idle", "count":6, "fps":6.0, "loop":true},
	"attack": {"prefix":"atk", "count":5, "fps":10.0, "loop":false},
	"hit": {"prefix":"hit", "count":2, "fps":12.0, "loop":false},
	"death": {"prefix":"dead", "count":4, "fps":10.0, "loop":false},
}}
