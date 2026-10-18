extends SceneTree
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks += 1
 if not ok: failures += 1; push_error(message)
func run():
 root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
 var SCOPE = load("res://src/systems/account_save_scope.gd")
 SCOPE.guest_directory = "user://max_native_"+str(Time.get_ticks_usec()); SCOPE.select_guest()
 var data = load("res://src/data/hero_weapon_catalog.gd")
 var script = load("res://src/hero_mode/hero_weapon_runtime.gd")
 var empty: Array[Texture2D] = []
 for row in data.WEAPONS.values(): script.ART.cache[String(row.effect_dir)] = empty
 var battle = load("res://src/battle/Battle.tscn").instantiate()
 battle._monster_spawn_resources_warmed = true; battle.process_mode = Node.PROCESS_MODE_DISABLED
 root.add_child(battle)
 var hero = battle.hero
 var runtime = script.new(); runtime.install(hero); runtime.identity = null; hero.player_weapons = runtime
 var id := "ranged_rookie_barrier_book"
 runtime.levels[id] = 10; runtime.evolved[id] = true
 runtime._cast(id)
 var watch: Dictionary = {}
 for slot in runtime.evolution.slots:
  if slot.left > 0 and slot.kind == "counter": watch = slot; break
 check(not watch.is_empty() and hero.shield_hp > 0,"real hero receives MAX shield and counter watcher")
 hero.invulnerability_timer = 0.0
 check(hero.take_damage(50),"real shield receives combat damage")
 check(float(watch.absorbed) > 0,"actual Hero shield absorption dispatch reaches evolution runtime")
 var absorbed: float = watch.absorbed
 hero.invulnerability_timer = 99
 check(not hero.take_damage(50) and float(watch.absorbed) == absorbed,"invulnerability cannot charge a counter")
 # Expiring support cannot create free counter damage without an absorbed hit.
 watch.absorbed = 0.0
 runtime.evolution.tick(float(watch.left)+.1)
 check(float(watch.left) <= 0 and hero.current_hp > 0,"natural shield timeout does not counter")
 var native = load("res://src/hero_mode/hero_survival_identity_runtime.gd").new()
 # The genuine native starter dispatch runs the extra behavior through _cast.
 for owner in ["archmage_hero","purifier_hero","sage_astra"]:
  var fake = load("res://tests/hero_max_native_host.gd").new()
  fake.hero_id = owner; battle.add_child(fake)
  var weapons = script.new(); weapons.install(fake)
  weapons.identity = native
  native.hero = fake; native.weapon_ref = weakref(weapons); native.starter = data.STARTERS[owner]
  native.archetype = "native_probe"; native.spec = {"native_basic":"native_attack"}
  var target = load("res://tests/hero_weapon_extension_smoke.gd").Target.new(); battle.add_child(target); fake.target = target
  # This fixture target is explicitly registered with the real generation registry.
  battle._activate_battle_entity(target)
  var key: String = data.STARTERS[owner]
  weapons.levels[key] = 10; weapons.evolved[key] = true; weapons.resolved.clear()
  weapons._cast(key)
  var carriers := 0
  for shot in weapons.projectiles:
   if shot.active and shot.data.has("max_mechanic"): carriers += 1
  check(fake.native_calls == 1 and carriers == 3,owner+" genuine native dispatch also launches MAX carrier plus two wings")
  fake.queue_free(); target.queue_free()
 # Drain all playing dummy audio before freeing the scene.
 for host in [battle,root.get_node("GameAudio")]:
  for player in host.find_children("*","AudioStreamPlayer",true,false): player.stop()
  for player in host.find_children("*","AudioStreamPlayer2D",true,false): player.stop()
 battle.queue_free(); await process_frame; await create_timer(.15).timeout
 print("HERO_MAX_NATIVE checks=",checks," failures=",failures)
 quit(1 if failures else 0)
