extends SceneTree
## Run: godot --headless --path . --script res://tools/monster_balance_audit.gd
## Data audit only. Does not claim match win rates or infer arbitrary skill power.
const C := preload("res://src/data/monster_catalog.gd")
const B := preload("res://src/data/monster_balance_catalog.gd")
func _init() -> void:
 var issues := 0
 var rows: Array = []
 for id in C.ORDER:
  var data: Dictionary = C.MONSTERS[id]
  var warnings := B.audit(data)
  for warning in warnings:
   push_warning(id+": "+warning)
   issues += 1
  rows.append({"id":id,"name":data.name,"rarity":C.get_rarity(id),"role":B.role_id(data),"cost":C.get_base_cost(id),"base":C.get_base_stats(id),"review":Array(warnings)})
 print(JSON.stringify({"version":B.VERSION,"issues":issues,"monsters":rows}))
 quit(1 if issues else 0)
