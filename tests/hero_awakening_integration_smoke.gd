extends SceneTree
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
 root.get_node("CloudStore").stop();root.get_node("LoginGateway").remember_session_enabled=false
 var mode=load("res://src/hero_mode/hero_mode.gd")
 check(mode!=null and mode.can_instantiate(),"real HeroMode including MAX banner compiles")
 var battle=load("res://src/battle/Battle.tscn").instantiate()
 battle._monster_spawn_resources_warmed=true;battle.process_mode=Node.PROCESS_MODE_DISABLED
 root.add_child(battle)
 battle.hero_player_mode=true;battle.online_match_mode=false;battle.battle_over=false
 battle.current_stage_data={"number":1};battle.campaign_difficulty="easy";battle.run_metrics.elapsed_seconds=900
 var before:int=battle.active_monsters.size()
 for index in 144-before:battle.active_monsters[-index-1]=battle.hero
 var boss=battle.spawn_hero_encounter("orc",battle.hero.position+Vector2(300,0),{"type":"boss","target_hp":15400,"target_damage":32})
 check(is_instance_valid(boss) and boss.max_hp==15400,"real Battle factory admits boss when 144 enemies are registered")
 check(battle.active_monsters.size()==145,"actual boss registration uses precisely one extra slot")
 check(battle.spawn_hero_encounter("orc",battle.hero.position+Vector2(300,0),{"type":"boss"})==null,"real Battle rejects duplicate boss")
 # Artificial registry entries exist only to reach the cap; remove before teardown.
 for index in 144-before:battle.active_monsters.erase(-index-1)
 for host in [battle,root.get_node("GameAudio")]:
  for player in host.find_children("*","AudioStreamPlayer",true,false):player.stop()
  for player in host.find_children("*","AudioStreamPlayer2D",true,false):player.stop()
 battle.queue_free();await process_frame;await create_timer(.15).timeout
 print("HERO_AWAKENING_INTEGRATION checks=",checks," failures=",failures);quit(1 if failures else 0)
