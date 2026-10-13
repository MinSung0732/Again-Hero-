extends RefCounted
## One-time atlas regions; selection/HUD reuse textures without disk loads.
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const WEAPONS := preload("res://assets/art/ui/hero_augments/weapons_normalized.png")
const PASSIVES := preload("res://assets/art/ui/hero_augments/passives_normalized.png")
const PASSIVE_ORDER := ["survival_power","survival_mobility","survival_projectile","survival_haste","survival_learning","survival_magnet","survival_vitality","survival_armor"]
static var cache: Dictionary = {}
static func texture(id: String) -> Texture2D:
	if cache.is_empty():
		var row := 0
		for hero_id in DATA.HERO_WEAPONS:
			var column := 0
			for weapon in DATA.HERO_WEAPONS[hero_id].slice(0,6):
				cache[weapon] = _region(WEAPONS,column,row,6,10)
				column += 1
			row += 1
		for weapon_id in DATA.WEAPONS:
			var source := String(DATA.WEAPONS[weapon_id].get("icon_source",""))
			if not source.is_empty() and cache.has(source): cache[weapon_id] = cache[source]
		for index in PASSIVE_ORDER.size():
			cache[PASSIVE_ORDER[index]] = _region(PASSIVES,index%4,int(index/4),4,2)
		for passive_id in DATA.PASSIVES:
			var source := String(DATA.PASSIVES[passive_id].get("icon_source",""))
			if cache.has(source): cache[passive_id] = cache[source]
		cache["survival_restore"] = cache["survival_vitality"]
	return cache.get(id,cache["survival_restore"]) as Texture2D
static func _region(atlas: Texture2D,column: int,row: int,columns: int,rows: int) -> AtlasTexture:
	var size := atlas.get_size()
	var left := roundf(size.x*column/columns)
	var top := roundf(size.y*row/rows)
	var right := roundf(size.x*(column+1)/columns)
	var bottom := roundf(size.y*(row+1)/rows)
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = Rect2(left,top,right-left,bottom-top)
	result.filter_clip = true
	return result
