extends RefCounted
const HEROES := preload("res://src/data/hero_profiles.gd")
## Selection copy only: changes at the offered rank and short, mechanical tags.
const PATTERN_TAGS := {
	"bolt":["투사체"],"burst":["투사체","연사"],"combo":["근접","연격"],"slash":["근접","광역"],
	"beam":["직선","관통"],"chain":["연쇄"],"poison":["장판","지속"],"nova":["광역","파동"],
	"frost":["광역","둔화"],"orbit":["회전","접촉"],"guard":["보호막"],"heal":["회복"],
	"summon":["소환"],"piercer":["투사체","관통"],"ice_pillar":["설치","냉기"],
	"meteor":["낙하","폭발"],"singularity":["장판","흡인"],"capsule":["직선","광역"],
}
const DELIVERY_TAGS := {"sigil":["설치","장판"],"trail":["이동","장판"],"sentry":["설치","자동사격"],"orbit":["회전","접촉"],"consecrate":["이동","성역"],"lob":["투척","장판"],"lob_burst":["투척","폭발"],"aura":["오라","지속"],"bombard":["포격","장판"],"fault":["전방","균열"],"trap":["설치","반응"]}
const FLIGHT_TAGS := {"straight":"직진","curve":"곡선","lance":"관통","return":"왕복","bounce":"도탄","fan":"산탄"}
const MAX_TAGS := {"command":"협공","counter":"반격","cross":"교차파","detonating_trail":"기폭","fork":"분열","front_echo":"후속파","mark":"각인","orbit":"궤도변형","reactive_zone":"반응장판","reap":"처치추격","relay_turret":"기동포대","return":"왕복","sanctuary":"성역"}
const EXTRA_FIELDS := {
	"bonus_hits":["추가 타격",1.0,"회"],"fan_lines":["방향",1.0,"개"],"orbit_count":["회전체",1.0,"개"],
	"pulse_count":["후속파",1.0,"회"],"pulse_ratio":["후속 피해",100.0,"%"],"splash_ratio":["폭발 피해",100.0,"%"],
	"splash_radius":["폭발 반경",1.0,""],"finish_ratio":["마무리 피해",100.0,"%"],"finish_radius":["마무리 반경",1.0,""],
	"field_count":["지대",1.0,"개"],"field_duration":["지속",1.0,"초"],"field_interval":["타격 간격",1.0,"초"],
	"slow_multiplier":["이동 배율",100.0,"%"],"slow_duration":["둔화 지속",1.0,"초"],
	"lifesteal":["흡혈",100.0,"%"],"execute_ratio":["처형선",100.0,"%"],"shield_duration":["보호막 지속",1.0,"초"],
	"cast_shield":["시전 보호막",100.0,"%"],"cast_heal":["시전 회복",100.0,"%"],"chain_radius":["연결 거리",1.0,""],
	"chain_growth":["연쇄 가산",100.0,"%"],"native_combo_bonus":["추가 연격",1.0,"타"],"projectile_speed":["탄속",1.0,""],
	"hit_interval":["연타 간격",1.0,"초"],"field_radius_ratio":["지대 반경",100.0,"%"],
	"low_hp_bonus":["빈사 피해",100.0,"%"],"hp_cost":["HP 소모",100.0,"%"],
	"sage_interval":["천체 주기",1.0,""],"fall_duration":["낙하 시간",1.0,"초"],"pulse_interval":["파동 간격",1.0,"초"],
	"pull_step":["흡인 거리",1.0,""],"orbit_ratio":["공전 반경",100.0,"%"],"orbit_speed":["공전 속도",1.0,""],
}
const SUMMON_FIELDS := {
	"hits_per_attack":["연격",1.0,"타"],"hit_interval":["연격 간격",1.0,"초"],"attack_cooldown":["공격 간격",1.0,"초"],"move_speed":["이속",1.0,""],
	"projectile_speed":["탄속",1.0,""],"attack_range":["공격 거리",1.0,""],"second_hit_bonus_ratio":["후속타 가산",100.0,"%"],
	"focus_damage_bonus":["집중 가산",100.0,"%"],"focus_attack_speed_bonus":["집중 공속",100.0,"%"],
	"consecutive_damage_bonus_per_step":["연속 가산",100.0,"%"],
}
const MAX_FIELDS := {"awakening_wings":["추가탄",1.0,"발"],"awakening_pierces":["관통",1.0,"체"],"awakening_bounces":["도탄",1.0,"회"],"awakening_command_rounds":["협공",1.0,"회"],"native_radius_scale":["기술 반경",1.0,"배"]}

static func tags(data: Dictionary, delivery: Dictionary, flight: Dictionary) -> String:
	var list: Array = DELIVERY_TAGS.get(String(delivery.get("mode","")),PATTERN_TAGS.get(String(data.pattern),["공격"])).duplicate()
	var path := String(FLIGHT_TAGS.get(String(flight.get("kind","")),""))
	if not path.is_empty() and not list.has(path): list.append(path)
	if String(data.pattern) == "summon":
		list.append("근접" if String(data.summon_kind) in ["hound","scout"] else "원거리")
		if float(data.get("summon_area_radius",0.0)) > 0.0: list.append("광역")
	elif float(data.get("splash_ratio",0.0)) > 0.0 and not list.has("폭발"): list.append("폭발")
	if float(data.get("lifesteal",0.0)) > 0.0: list.append("흡혈")
	if float(data.get("slow_duration",0.0)) > 0.0 and not list.has("둔화"): list.append("둔화")
	var mechanic := String(data.get("max_mechanic",{}).get("mechanic",""))
	if MAX_TAGS.has(mechanic) and not list.has(MAX_TAGS[mechanic]): list.push_front(MAX_TAGS[mechanic])
	var text := ""
	for tag in list.slice(0,4): text += (" " if not text.is_empty() else "")+"#"+String(tag)
	return text

static func number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value,roundf(value)) else ("%.2f" % value).trim_suffix("0")

static func changes(before: Dictionary, after: Dictionary, _rank: int) -> String:
	var pattern := String(after.pattern)
	var core: Array[String] = []
	if pattern not in ["guard","heal"]:
		var gain := (float(after.power)*float(after.damage_scale)/(float(before.power)*float(before.damage_scale))-1.0)*100.0
		core.append(("소환 피해" if pattern == "summon" else "피해")+" +%.1f%%" % gain)
	if pattern != "summon": core.append("사거리 +%.1f%%" % ((float(after.reach_scale)/float(before.reach_scale)-1.0)*100.0))
	core.append(("재소환" if pattern == "summon" else "간격")+" -%.1f%%" % ((1.0-float(after.cooldown_scale)/float(before.cooldown_scale))*100.0))
	var extra: Array[String] = []
	if pattern in ["guard","heal"]:
		var key := "shield_ratio" if pattern == "guard" else "heal_ratio"
		var rank_steps := float(after.growth_rank)-float(before.growth_rank)
		var gain := (float(after.get(key,.04 if pattern == "guard" else .015))-float(before.get(key,.04 if pattern == "guard" else .015))+rank_steps*(.006 if pattern == "guard" else .002))*100.0
		extra.append(("보호막" if pattern == "guard" else "회복량")+" +최대 HP의 "+number(gain)+"%")
	if pattern == "summon":
		extra.append("소환 유지 %s → %s초" % [number(before.summon_duration),number(after.summon_duration)])
		if after.has("summon_hp_ratio"): extra.append("소환 HP +%s%%p" % number((after.summon_hp_ratio-before.summon_hp_ratio)*100.0))
		if float(after.summon_area_radius) != float(before.summon_area_radius):
			extra.append("%s: 반경%s · %s%% · +%d체" % [after.summon_area_label,number(after.summon_area_radius),number(after.summon_area_ratio*100.0),after.summon_area_targets])
		var old_config: Dictionary = HEROES.PROFILES[String(after.owner)].summoner[String(after.summon_kind)].duplicate()
		var new_config := old_config.duplicate()
		old_config.merge(before.get("summon_patch",{}),true)
		new_config.merge(after.get("summon_patch",{}),true)
		_append_fields(extra,old_config,new_config,SUMMON_FIELDS)
	else:
		_append_fields(extra,before,after,EXTRA_FIELDS)
		if bool(after.get("cleanse",false)) and not bool(before.get("cleanse",false)): extra.append("상태이상 해제 추가")
	_append_fields(extra,before,after,MAX_FIELDS,true)
	var text := " · ".join(core)
	for index in range(0,extra.size(),2): text += "\n"+" · ".join(extra.slice(index,mini(index+2,extra.size())))
	return text

static func _append_fields(list: Array[String], before: Dictionary, after: Dictionary, fields: Dictionary, absolute: bool = false) -> void:
	for field in fields:
		if not after.has(field): continue
		if field == "bonus_hits" and String(after.get("pattern","")) not in ["bolt","burst","combo","chain","meteor","piercer","ice_pillar"]: continue
		# A dormant splash radius is not an actual new mechanic.
		if String(field).begins_with("splash") and float(after.get("splash_ratio",0.0)) <= 0.0: continue
		var fallback := 1.0 if field == "slow_multiplier" else .45 if field == "field_radius_ratio" else .7 if field == "orbit_ratio" else 3.0 if field == "orbit_speed" else 0.0
		var old := float(before.get(field,fallback))
		var value := float(after[field])
		if is_equal_approx(old,value): continue
		var row: Array = fields[field]
		if absolute: list.append("%s %s%s" % [row[0],number(value*row[1]),row[2]])
		elif field == "slow_multiplier": list.append("둔화 +%s%%p" % number((old-value)*100.0))
		else: list.append("%s %s%s%s" % [row[0],"+" if value > old else "",number((value-old)*row[1]),"%p" if row[2] == "%" else row[2]])
