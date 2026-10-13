extends SceneTree
## Static budget snapshots, not a combat simulation. All theoretical targets stay in range.
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
func _initialize() -> void:
	var output := FileAccess.open("res://docs/HERO_WEAPON_GROWTH_BUDGET_20261013.tsv",FileAccess.WRITE)
	output.store_csv_line(PackedStringArray(["id","name","rank","evolved","pattern","per_hit_atk_ratio","cooldown_seconds","hits_or_native_actors","fields","field_seconds","field_interval","pulses","pulse_damage_ratio","summon_seconds","nominal_pattern_damage_units_excluding_area_target_count"]),"\t")
	for id in DATA.WEAPONS:
		for phase in [1,3,6,10,11]:
			var rank: int = mini(phase,10); var awakened: bool = phase == 11
			var data := DATA.GROWTH.resolve(id,DATA.WEAPONS[id],rank,awakened)
			var pattern := String(data.pattern)
			var hits := int(data.base_hits)+int(data.get("bonus_hits",0))
			var units := 1.0
			match pattern:
				"burst","combo": units = mini(6,hits)+float(data.get("finish_ratio",0.0))
				"bolt": units = hits # Distinct targets; splash neighbors excluded from this model.
				"chain": units = hits+float(data.get("chain_growth",0.0))*hits*(hits-1)*0.5
				"poison": units = int(data.get("field_count",1))*ceilf(float(data.field_duration)/float(data.field_interval))*float(data.get("field_power",0.25))
				"piercer": units = mini(4,hits)
				"meteor": units = mini(6,hits)
				"ice_pillar": units = mini(3,hits) # Initial hit only; native periodic/status behavior is separate.
				"singularity": units = ceilf(float(data.field_duration)/float(data.field_interval))*float(data.field_power)
				"summon": units = 0.0 # Kind-specific attack snapshots, movement and uptime need separate simulation.
			units += int(data.get("pulse_count",0))*float(data.get("pulse_ratio",0.0))
			var multiplier := float(data.power)*float(data.damage_scale)
			output.store_csv_line(PackedStringArray([String(id),DATA.GROWTH.evolution_name(id) if awakened else String(data.name),str(rank),str(awakened),pattern,str(multiplier),str(float(data.cooldown)*float(data.cooldown_scale)),str(hits),str(data.get("field_count",1)),str(data.get("field_duration",0)),str(data.get("field_interval",0)),str(data.get("pulse_count",0)),str(data.get("pulse_ratio",0)),str(data.get("summon_duration",0)),str(units*multiplier)]),"\t")
	output.close()
	print("HERO_WEAPON_GROWTH_AUDIT rows=300; nominal maximum model only; native basics, shared ammo/gas, caps, shielding/healing, misses and occupancy separate")
	quit()
