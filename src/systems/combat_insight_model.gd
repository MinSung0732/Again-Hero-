extends RefCounted
const EXPERIENCE := preload("res://src/data/campaign_experience_catalog.gd")
const HERO_AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
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
func reset(id: String) -> void:
	stage_id = id
	objective = EXPERIENCE.objective(id)
	counter = objective; last_choice = ""; last_choice_time = -999.0; choice_count = 0
	last_sample = -1; head = 0; count = 0; lowest_hp_ratio = 1.0
	current_window_damage = 0; previous_window_damage = 0
	samples_time.resize(21); samples_damage.resize(21); samples_time.fill(0); samples_damage.fill(0)
func record_choice(name: String,elapsed: float) -> void:
	if _name_tags.is_empty():
		for augment in HERO_AUGMENTS.AUGMENTS: _name_tags[String(augment.get("name",""))] = augment.get("tags",[])
	last_choice = name; last_choice_time = elapsed; choice_count += 1
	counter = EXPERIENCE.counter_hint(_name_tags.get(name,[]),objective)
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
	if elapsed < 10.0: return "첫 공세를 보내세요 · 카드 선택 → 전장 터치"
	if elapsed < 20.0: return "최근 10초 · 용사 HP 피해 %d" % current_window_damage
	return "최근 10초 HP 피해 %d  ·  직전 10초 대비 %+d" % [current_window_damage,current_window_damage-previous_window_damage]
func hint(elapsed: float) -> String:
	var rules := EXPERIENCE.profile(stage_id)
	if last_choice.is_empty() and elapsed < 10.0 and not rules.is_empty(): return objective+"  첫 엘리트 %d초" % int(rules.events[0])
	return counter
func result_note(won: bool) -> String:
	if won: return String(EXPERIENCE.profile(stage_id).get("next","다음 용사의 새 패턴에 맞춰 군단을 준비하세요."))
	if lowest_hp_ratio <= 0.2: return "용사 체력을 %d%%까지 압박했습니다. 같은 조합에서 공세를 잇는 타이밍을 바꿔 보세요." % int(round(lowest_hp_ratio*100.0))
	return "다음 실험 · "+counter
