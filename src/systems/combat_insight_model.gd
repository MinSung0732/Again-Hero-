extends RefCounted
const EXPERIENCE := preload("res://src/data/campaign_experience_catalog.gd")
const HERO_AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const STRATEGY := preload("res://src/data/first_minute_strategy_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
static var _name_tags: Dictionary = {}
var stage_id := ""
var objective := "용사의 선택을 보고 군단 조합을 바꿔 보세요."
var last_choice := ""
var last_choice_time := -999.0
var counter := ""
var last_sample := -1
var samples_time := PackedFloat64Array()
var samples_damage := PackedInt64Array()
var head := 0
var count := 0
var lowest_hp_ratio := 1.0
var current_window_damage := 0
var previous_window_damage := 0
var choice_count := 0
var roster: Array = []
var successful_summons := 0
var last_summon := ""
var summon_before_choice := ""
var switched_after_choice := false
var decision_reason := ""
var recommended_id := ""
var auto_placement := true
var available_command := 0.0
var recommended_cost := 0.0
var population_full := false
func reset(id: String) -> void:
	stage_id = id
	objective = EXPERIENCE.objective(id)
	counter = objective; last_choice = ""; last_choice_time = -999.0; choice_count = 0
	last_sample = -1; head = 0; count = 0; lowest_hp_ratio = 1.0
	current_window_damage = 0; previous_window_damage = 0
	samples_time.resize(21); samples_damage.resize(21); samples_time.fill(0); samples_damage.fill(0)
	roster.clear(); successful_summons = 0; last_summon = ""; summon_before_choice = ""
	switched_after_choice = false; decision_reason = ""; recommended_id = ""
	available_command = 0.0; recommended_cost = 0.0; population_full = false; auto_placement = true
func configure_roster(ids: Array) -> void:
	roster = ids.duplicate()
func record_summon(id: String) -> void:
	if id not in roster: return
	successful_summons += 1
	last_summon = id
	if choice_count > 0 and not summon_before_choice.is_empty() and id != summon_before_choice:
		switched_after_choice = true
func record_choice(name: String,elapsed: float,reason: String = "",chosen_tags: Array = []) -> void:
	if _name_tags.is_empty():
		for augment in HERO_AUGMENTS.AUGMENTS: _name_tags[String(augment.get("name",""))] = augment.get("tags",[])
	last_choice = name; last_choice_time = elapsed; choice_count += 1
	var tags: Array = chosen_tags if not chosen_tags.is_empty() else _name_tags.get(name,[])
	counter = EXPERIENCE.counter_hint(tags,objective)
	decision_reason = reason; summon_before_choice = last_summon; switched_after_choice = false
	recommended_id = ""
	for tag in EXPERIENCE.COUNTER_PRIORITY:
		if tag not in tags: continue
		for role in STRATEGY.RESPONSE_ROLES.get(tag,[]):
			for raw_id in roster:
				var id := String(raw_id)
				if MONSTERS.get_role(id) == role:
					recommended_id = id
					return
func detail_copy() -> String:
	return STRATEGY.LOOP if decision_reason.is_empty() else "용사의 실제 선택 근거\n"+decision_reason
func sample(elapsed: float,total_hp_damage: int,current_hp: int,max_hp: int) -> bool:
	lowest_hp_ratio = minf(lowest_hp_ratio,clampf(float(current_hp)/maxf(float(max_hp),1.0),0.0,1.0))
	var second := int(floor(elapsed))
	if second == last_sample: return false
	last_sample = second
	samples_time[head] = elapsed; samples_damage[head] = maxi(total_hp_damage,0)
	head = (head+1)%21; count = mini(count+1,21)
	var at_ten := _damage_at(elapsed-10.0)
	var at_twenty := _damage_at(elapsed-20.0)
	current_window_damage = maxi(total_hp_damage-at_ten,0)
	previous_window_damage = maxi(at_ten-at_twenty,0)
	return true
func _damage_at(time: float) -> int:
	var value := 0
	var closest := -1.0
	for i in count:
		if samples_time[i] <= time and samples_time[i] >= closest:
			closest = samples_time[i]; value = samples_damage[i]
	return value
func headline(elapsed: float) -> String:
	if not last_choice.is_empty() and elapsed-last_choice_time < 8.0: return "용사 선택 · "+last_choice+"  › 상세"
	if roster.is_empty(): return "편성 없음 · 로비에서 군단을 편성하세요"
	if successful_summons == 0: return STRATEGY.GOAL
	if last_choice.is_empty() and elapsed < 60.0: return "관찰 · 몬스터를 처치한 용사는 성장합니다"
	if switched_after_choice: return "공세 변경 후 관찰 · 최근 10초 HP 피해 %d" % current_window_damage
	if elapsed < 20.0: return "최근 10초 · 용사 HP 피해 %d" % current_window_damage
	return "최근 10초 HP 피해 %d  ·  직전 10초 대비 %+d" % [current_window_damage,current_window_damage-previous_window_damage]
func hint(elapsed: float) -> String:
	if roster.is_empty(): return "메뉴 → 로비 복귀 → 팀편성에서 몬스터를 추가하세요."
	if population_full: return "인구가 가득 찼습니다. 빈자리가 생기면 다음 공세를 보내세요."
	if successful_summons == 0:
		return "자동 배치 · 하단 카드를 누르면 소환, 지휘력은 자동 회복" if auto_placement else "수동 배치 · 카드 선택 → 용사와 떨어진 전장 터치"
	if last_choice.is_empty() and elapsed < 60.0:
		return STRATEGY.LOOP if elapsed >= 12.0 else STRATEGY.role_tip(MONSTERS.get_role(last_summon))
	if not recommended_id.is_empty() and not switched_after_choice:
		var name := MONSTERS.get_monster_name(recommended_id)
		if available_command+0.001 < recommended_cost:
			return "%s 공세 준비 · 지휘력 %.0f / %.0f, 자동 회복 중" % [name,available_command,recommended_cost]
		return "금색 카드 · %s을 섞고 HP 피해 변화를 관찰하세요." % name
	return counter
func result_note(won: bool) -> String:
	if won: return String(EXPERIENCE.profile(stage_id).get("next","다음 용사의 새 패턴에 맞춰 군단을 준비하세요."))
	if lowest_hp_ratio <= 0.2: return "용사 체력을 %d%%까지 압박했습니다. 같은 조합에서 공세를 잇는 타이밍을 바꿔 보세요." % int(round(lowest_hp_ratio*100.0))
	if successful_summons == 0: return "다음 실험 · 하단 몬스터 카드를 눌러 첫 공세를 보내세요."
	var observation := "용사 선택 · "+last_choice+"\n" if not last_choice.is_empty() else ""
	if not recommended_id.is_empty():
		return observation+"다음 실험 · "+MONSTERS.get_monster_name(recommended_id)+"을 섞어 대응을 시험하세요."
	return observation+"다음 실험 · "+counter
