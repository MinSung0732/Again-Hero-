extends SceneTree
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const CHARS := preload("res://src/data/hero_character_catalog.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok,label):
	checks += 1
	if not ok: failures += 1; push_error(label)
func run():
	check(CHARS.STARTING_STATS.size() == 10,"ten complete character budgets")
	var seen := {}
	var table := "hero\tunlock_stage\thp\tattack\tspeed\tpickup\tstarter_period\tstarter_range\n"
	for id in CHARS.ORDER:
		var source := PROFILES.get_profile(id); var original := source.duplicate(true)
		var profile := WEAPONS.profile_for_survival(source)
		var starter: Dictionary = WEAPONS.WEAPONS[WEAPONS.STARTERS[id]]
		check(source == original and source == PROFILES.get_profile(id),"campaign profile unmodified "+id)
		for key in MODE.BASE_HERO_STATS:
			check(profile[key] == MODE.starting_stats(id)[key],"exact starting value "+id+key)
		check(profile.level_growth.is_empty(),"survival leveling unchanged "+id)
		check(profile.id == id and profile.archetype == source.archetype and profile.sprite_frame_dir == source.sprite_frame_dir,"identity retained "+id)
		for key in source:
			if key not in MODE.BASE_HERO_STATS and key != "level_growth": check(profile[key] == source[key],"native gimmick retained "+id+key)
		check(profile.max_hp >= 980 and profile.max_hp <= 1500 and profile.attack_damage >= 22 and profile.attack_damage <= 30,"bounded HP and attack budget")
		check(profile.move_speed >= 245 and profile.move_speed <= 315 and profile.exp_pickup_radius >= 135 and profile.exp_pickup_radius <= 180,"bounded mobility and pickup budget")
		var signature := "%s/%s/%s/%s" % [profile.max_hp,profile.attack_damage,profile.move_speed,profile.exp_pickup_radius]
		check(not seen.has(signature),"distinct role budget "+id); seen[signature] = true
		# Same character on every battlefield/difficulty uses this identical profile.
		for stage in range(1,11):
			for difficulty in ["easy","hard"]:
				var staged := source.duplicate(true)
				staged.max_hp *= (1.0+stage*0.1)*(1.6 if difficulty == "hard" else 1.0)
				staged.attack_damage *= (1.0+stage*0.055)*(1.35 if difficulty == "hard" else 1.0)
				var result := WEAPONS.profile_for_survival(staged)
				check(result.max_hp == profile.max_hp and result.attack_damage == profile.attack_damage,"no battlefield double scaling")
		var detached := MODE.starting_stats(id); detached.max_hp = 1
		check(MODE.starting_stats(id).max_hp == profile.max_hp,"catalog copy isolation")
		table += "%s\t%s\t%d\t%d\t%.0f\t%.0f\t%.2f\t%.0f\n" % [id,CHARS.stage_for_hero(id),profile.max_hp,profile.attack_damage,profile.move_speed,profile.exp_pickup_radius,starter.cooldown,starter.range]
	check(MODE.starting_stats("unknown") == MODE.BASE_HERO_STATS,"unknown character safe baseline")
	check(CHARS.STARTING_STATS.swift_hunter.move_speed > CHARS.STARTING_STATS.ranged_rookie.move_speed and CHARS.STARTING_STATS.swift_hunter.max_hp < 1200,"rogue mobility costs HP")
	check(CHARS.STARTING_STATS.sword_shield_hero.max_hp > 1200 and CHARS.STARTING_STATS.sword_shield_hero.move_speed < 270,"fighter armor costs mobility")
	check(CHARS.STARTING_STATS.purifier_hero.attack_damage < 26 and CHARS.STARTING_STATS.sage_astra.max_hp < 1200,"late defensive kits pay stat budget")
	DirAccess.make_dir_recursive_absolute("res://docs")
	var file := FileAccess.open("res://docs/HERO_STARTING_STATS_20261014.tsv",FileAccess.WRITE); file.store_string(table); file.close()
	print("HERO_STARTING_BALANCE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
