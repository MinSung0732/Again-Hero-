extends SceneTree
const SKILLS = preload("res://src/data/demon_ultimate_catalog.gd")
const MONSTERS = preload("res://src/data/monster_catalog.gd")
const ROOM = preload("res://src/online/battle_room.gd")
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 assert(SKILLS.CATEGORIES.size() == 5)
 assert(SKILLS.ids_in_category("summon").size() == 3)
 assert(SKILLS.ids_in_category("attack").is_empty())
 var room = ROOM.new()
 root.add_child(room)
 room.set_loadouts({"hero_id":"fighter"},{"team_ids":["slime","spider","orc"],"skill_ids":["encirclement","line_assault","square_siege"],"transcendence_id":""})
 room.prepare(); room.start()
 var battle = room.battle
 battle.process_mode = Node.PROCESS_MODE_DISABLED
 for id in SKILLS.ORDER:
  var skill = SKILLS.get_skill(id)
  assert(skill.category == "summon" and skill.max_monster_cost == 6.0)
  for monster in battle._demon_skill_pool(skill):
   assert(MONSTERS.get_base_cost(monster) <= 6.0)
 for id in SKILLS.ORDER:
  battle.demon_ultimate_spawn_queue.clear()
  battle.demon_ultimate_charge = 100.0
  assert(battle.try_use_demon_ultimate(id, "east"))
  assert(not battle.demon_ultimate_spawn_queue.is_empty())
  for entry in battle.demon_ultimate_spawn_queue:
   assert(MONSTERS.get_base_cost(entry.monster_id) <= 6.0)
  while not battle.demon_ultimate_spawn_queue.is_empty():
   battle._process_demon_ultimate_spawn_queue(1.0)
  assert(not battle.active_monsters.is_empty())
  for monster in battle.active_monsters.values():
   assert(MONSTERS.get_base_cost(monster.monster_type) <= 6.0)
 battle.demon_ultimate_spawn_queue.clear()
 battle.demon_ultimate_cooldowns["encirclement"] = 0.0
 battle.allowed_monster_ids = ["gumiho"]
 battle.demon_ultimate_charge = 100.0
 assert(not battle.try_use_demon_ultimate("encirclement"))
 assert(room.last_action_message.contains("6코스트 이하"))
 room.finish("", "test_complete"); room.queue_free()
 var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
 root.add_child(lobby)
 await process_frame
 lobby._show_formation_mode("skill")
 var cards = lobby.team_monster_grid.get_children()
 assert(cards.size() == 3)
 lobby._select_demon_category("attack")
 for card in cards: assert(not card.visible)
 assert(lobby.demon_category_empty.visible)
 lobby._select_demon_category("summon")
 for card in cards: assert(card.visible)
 assert(lobby.team_monster_grid.get_children() == cards)
 lobby.queue_free()
 print("DEMON_SKILL_CATEGORY_PASS")
 quit()
