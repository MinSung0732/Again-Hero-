extends SceneTree
const DATA:=preload("res://src/data/hero_weapon_catalog.gd")
func _initialize() -> void:
 DirAccess.make_dir_recursive_absolute("res://docs")
 var file:=FileAccess.open("res://docs/HERO_DAMAGE_GROWTH_20261016.tsv",FileAccess.WRITE)
 file.store_line("id\tname\tlevel\tdamage_scale\thit_coefficient\thit_at_attack26\tbase_interval")
 for id in DATA.WEAPONS:
  for level in range(1,12):
   var data:=DATA.GROWTH.resolve(id,DATA.WEAPONS[id],mini(level,10),level==11)
   var coefficient:float=float(data.power)*float(data.damage_scale)
   file.store_line("%s\t%s\t%d\t%.3f\t%.3f\t%d\t%.3f"%[id,data.name,level,data.damage_scale,coefficient,maxi(1,roundi(coefficient*26)),float(data.cooldown)*float(data.cooldown_scale)])
 file.close();print("DAMAGE_GROWTH_EXPORT rows=1100");quit()
