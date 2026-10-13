extends RefCounted
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
var battle
var think_remaining := 0.0
var observation_remaining := 0.0
var rotation := 0
var preferred: Array = []
var plan := "탐색 공세 · 용사 빌드를 관찰 중"
func install(host) -> void:
	battle = host
	battle.set_allowed_monster_ids(DATA.ROSTER)
func _observe() -> void:
	preferred.clear()
	var tags := AUGMENTS.get_build_tag_counts(battle.hero.build_counts)
	for tag in DATA.COUNTERS:
		if int(tags.get(tag,0)) > 0:
			preferred = DATA.COUNTERS[tag].duplicate()
			plan = "빌드 관측 · "+AUGMENTS.get_tag_label(tag)+"에 대응하는 공세"
			return
	plan = "탐색 공세 · 여러 역할로 압박"
func _select_ai_reward() -> bool:
	if battle.demon_augment_selection_active:
		var candidates: Array = battle.demon_augment_candidates
		if not candidates.is_empty():
			battle.choose_demon_augment(String(candidates[randi_range(0,candidates.size()-1)].get("id","")))
		return true
	if battle.mutation_director.is_active():
		var candidates: Array = battle.mutation_director.get_candidates()
		if not candidates.is_empty(): battle.try_choose_mutation(String(candidates[randi_range(0,candidates.size()-1)]))
		return true
	return false
func tick(delta: float) -> void:
	if battle.battle_over or battle.external_pause or not is_instance_valid(battle.hero): return
	if _select_ai_reward() or battle.is_combat_simulation_paused(): return
	observation_remaining -= delta
	if observation_remaining <= 0.0:
		observation_remaining = DATA.OBSERVE_INTERVAL
		_observe()
	think_remaining -= delta
	if think_remaining > 0.0: return
	think_remaining = DATA.THINK_INTERVAL
	if battle.get_population_count() >= DATA.MONSTER_LIMIT: return
	var elapsed: float = battle.run_metrics.elapsed_seconds
	var pool: Array = DATA.ROSTER
	var available := mini(3+int(elapsed/35.0),pool.size())
	var id := String(pool[rotation%available])
	rotation += 1
	# Partial observation and inertia: keep exploring rather than perfect countering.
	if elapsed > 25.0 and not preferred.is_empty() and randf() < 0.55:
		id = String(preferred[rotation%preferred.size()])
	if battle.command_power >= battle.get_monster_cost(id): battle.try_summon(id)
