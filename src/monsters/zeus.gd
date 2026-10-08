extends "res://src/monsters/goblin_thrower.gd"
const DATA := preload("res://src/data/zeus_behavior_catalog.gd")
const ART := preload("res://src/data/zeus_visual_catalog.gd")
const FX := preload("res://src/ui/zeus_combat_effects.gd")
const SLASH_SCENE := preload("res://src/monsters/ZeusSlash.tscn")
const AUDIO := preload("res://src/data/zeus_audio_catalog.gd")
const SFX_BANK := preload("res://src/audio/event_sfx_bank.gd")
var combat_sfx: Node
var effect_layer: Node2D
var transcend_level := 0
var summon_snapshot := 0
var keeping_distance := false
var visual_head_y := -35.0
@onready var crown_layer: Node2D = $CrownLayer
@onready var status_layer: Node2D = $StatusLayer
var gauge := 0.0
var orb_heal_buffer := 0.0
var skill_cooldowns := PackedFloat32Array([0,0,0])
var charge_remaining := 0.0
var crown_remaining := 0.0
var crown_elapsed := 0.0
var crown_heals := 0
var pillar_remaining := 0.0
var pillar_position := Vector2.ZERO
var pillar_kind := "judgment"
var orb_origins := PackedVector2Array()
var orb_ages := PackedFloat32Array()

func _init() -> void:
	monster_type = "zeus"
	monster_role = "ranged"
	for stat in DATA.BASE:
		set(stat,DATA.BASE[stat])
	orb_origins.resize(DATA.MAX_ORBS)
	orb_ages.resize(DATA.MAX_ORBS)
	orb_ages.fill(-1.0)

func configure_transcendence(count: int, level: int) -> void:
	summon_snapshot = maxi(count,0)
	transcend_level = clampi(level,0,5)
	max_hp = int(round(DATA.BASE.max_hp + summon_snapshot * DATA.HP_PER_SUMMON))
	attack_damage = int(round(DATA.BASE.attack_damage + summon_snapshot * DATA.DAMAGE_PER_SUMMON))
	move_speed = DATA.BASE.move_speed
	attack_cooldown = DATA.BASE.attack_cooldown
	attack_range = DATA.BASE.attack_range
	exp_reward = 0
	current_hp = max_hp

func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(ART.PROFILE)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	if texture == null:
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		return
	var bounds := image.get_used_rect()
	if bounds.size.y <= 0:
		return
	var canvas_center := Vector2(texture.get_size())*0.5
	var anchor := Vector2(bounds.get_center().x,bounds.end.y)-canvas_center
	var original_anchor: Vector2 = visual.position+anchor*visual.scale
	var factor := ART.BATTLE_VISIBLE_HEIGHT/float(bounds.size.y)
	visual.scale = Vector2.ONE*factor
	visual.position = original_anchor-anchor*factor
	visual_head_y = visual.position.y+(bounds.position.y-canvas_center.y)*factor

func _ready() -> void:
	crown_layer.draw.connect(_draw_crown_layer)
	status_layer.draw.connect(_draw_status_layer)
	super._ready()
	effect_layer = Node2D.new()
	effect_layer.name = "CombatEffects"
	effect_layer.z_as_relative = false
	effect_layer.z_index = 8 # Above target bodies in castle and legacy maps.
	effect_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(effect_layer)
	effect_layer.draw.connect(_draw_combat_effects)
	combat_sfx = SFX_BANK.new()
	add_child(combat_sfx)
	combat_sfx.configure(AUDIO.CUES, combat_authority, true)
	for kind in DATA.EFFECTS:
		FX.get_pack(kind)

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	if is_instance_valid(combat_authority) and (combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active):
		return
	gauge = minf(DATA.GAUGE_MAX,gauge + get_gauge_regen() * delta)
	for index in range(3):
		skill_cooldowns[index] -= delta
	_tick_crown(delta)
	_tick_orbs(delta)
	pillar_remaining = maxf(pillar_remaining-delta,0.0)
	if charge_remaining > 0.0:
		charge_remaining = maxf(charge_remaining-delta,0.0)
		velocity = Vector2.ZERO
		if charge_remaining <= 0.0:
			_release_thunder()
		queue_redraw()
		return
	if is_instance_valid(combat_authority) and is_instance_valid(combat_authority.hero):
		hero = combat_authority.hero
	if is_instance_valid(hero) and int(hero.current_hp) > 0:
		_try_cast()
	if charge_remaining <= 0.0:
		super._physics_process(delta)
	queue_redraw()

func _refresh_combat_target() -> void:
	hero_target_refresh_timer = 0.25
	if is_instance_valid(combat_authority):
		hero = combat_authority.hero

func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0.0)*DATA.REGEN_RATIO,DATA.REGEN_CAP) if is_instance_valid(combat_authority) else 0.0

# The shared ranged runtime ticks attacks, hit flashes and movement locks first.
func _tick_retreat_and_heal(delta: float) -> bool:
	var offset := hero.global_position-global_position
	var distance := offset.length()
	var facing := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	cached_direction_to_hero = facing
	_update_visual_lod(distance*distance)
	if distance < DATA.RETREAT_START_DISTANCE:
		keeping_distance = true
	elif distance >= DATA.HOLD_DISTANCE:
		keeping_distance = false
	var direction := Vector2.ZERO
	var remaining := 0.0
	if keeping_distance:
		direction = -facing
		remaining = DATA.HOLD_DISTANCE-distance
	elif distance > attack_range:
		direction = facing
		remaining = distance-DATA.HOLD_DISTANCE
	var speed := move_speed*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	velocity = direction*minf(speed,remaining/maxf(delta,0.0001))
	if velocity.length_squared() > 0.01:
		move_and_slide()
	# Face the target even while stepping backwards.
	_update_visual_motion(facing.x,velocity.length_squared() > 0.01)
	if global_position.distance_squared_to(hero.global_position) <= attack_range*attack_range and attack_timer <= 0.0:
		attack_timer = _get_effective_attack_cooldown()
		_visual_call(&"play_attack")
		_fire_projectile(hero.global_position-global_position)
	return true

func _try_cast() -> void:
	var distance := global_position.distance_to(hero.global_position)
	var chosen := -1
	var oldest := INF
	for index in DATA.CAST_PRIORITY:
		if skill_cooldowns[index] > 0.0 or (index == 1 and crown_remaining > 0.0):
			continue
		if distance > (DATA.SLASH_RANGE if index == 2 else attack_range):
			continue
		if skill_cooldowns[index] < oldest:
			oldest = skill_cooldowns[index]
			chosen = index
	if chosen < 0 or gauge + 0.0001 < DATA.COSTS[chosen]:
		return
	gauge = maxf(gauge-DATA.COSTS[chosen],0.0)
	skill_cooldowns[chosen] = DATA.COOLDOWNS[chosen]
	if chosen == 0:
		charge_remaining = DATA.CHARGE_SECONDS
		play_combat_sound("charge")
		visual.play_skill()
	elif chosen == 1:
		crown_remaining = DATA.CROWN_SECONDS
		play_combat_sound("crown")
		crown_elapsed = 0.0
		crown_heals = 0
	else:
		var shot = combat_authority.acquire_projectile(SLASH_SCENE,"zeus_slash")
		play_combat_sound("slash")
		shot.global_position = global_position
		shot.setup((hero.global_position-global_position).normalized(),self,hero)
		visual.play_skill()

func _fire_projectile(_offset: Vector2) -> void:
	if not is_instance_valid(hero):
		return
	_show_pillar("judgment",_target_feet_position())
	play_combat_sound("judgment")
	var immune := float(hero.invulnerability_timer) > 0.0
	var amount := attack_damage
	var chance := DATA.BASIC_CHANCE
	var paralysis := DATA.BASIC_PARALYSIS
	if immune:
		if transcend_level < 1:
			return
		amount = int(round(amount*DATA.IMMUNE_DAMAGE_RATIO))
		chance = DATA.IMMUNE_CHANCE
		paralysis = DATA.IMMUNE_PARALYSIS
	var accepted: bool = hero.take_followup_damage(amount,self) if immune else hero.take_damage(amount,self)
	if accepted and randf() < chance:
		apply_paralysis_to(hero,paralysis)

func _release_thunder() -> void:
	if is_instance_valid(combat_sfx):
		combat_sfx.stop_cue("charge")
	if not is_instance_valid(hero) or int(hero.current_hp) <= 0:
		return
	_show_pillar("thunder",_target_feet_position())
	play_combat_sound("thunder")
	var amount := int(round(attack_damage*(DATA.THUNDER_UPGRADED_DAMAGE if transcend_level >= 2 else DATA.THUNDER_DAMAGE)))
	var accepted: bool = hero.take_followup_damage(amount,self) if transcend_level >= 2 else hero.take_damage(amount,self)
	if accepted:
		hero.apply_slow(1.0-DATA.THUNDER_SLOW,DATA.STATUS_SECONDS)
		apply_paralysis_to(hero,DATA.THUNDER_PARALYSIS)

func apply_paralysis_to(target_node: Node, strength: float) -> bool:
	var ratio := strength*(DATA.CROWN_PARALYSIS_MULTIPLIER if crown_remaining > 0.0 else 1.0)
	if not target_node.has_method("apply_paralysis") or not target_node.apply_paralysis(ratio,DATA.STATUS_SECONDS):
		return false
	if transcend_level >= 3 and crown_remaining > 0.0 and target_node.has_method("impose_all_skill_cooldowns"):
		target_node.impose_all_skill_cooldowns(DATA.CROWN_SKILL_DELAY)
	return true

func _tick_crown(delta: float) -> void:
	if crown_remaining <= 0.0:
		return
	crown_elapsed += minf(delta,crown_remaining)
	crown_remaining = maxf(crown_remaining-delta,0.0)
	var due := mini(int(floor((crown_elapsed+0.0001)/DATA.CROWN_HEAL_INTERVAL)),3)
	while crown_heals < due:
		heal_direct(int(round(max_hp*DATA.CROWN_HEAL_RATIO)))
		crown_heals += 1

func on_ally_death(point: Vector2) -> void:
	if dying or current_hp <= 0 or global_position.distance_squared_to(point) > DATA.DEATH_RADIUS*DATA.DEATH_RADIUS:
		return
	for index in range(DATA.MAX_ORBS):
		if orb_ages[index] < 0.0:
			orb_origins[index] = point
			orb_ages[index] = 0.0
			return
	# Visual saturation cannot drop the reward in a dense death burst.
	absorb_orb()

func _tick_orbs(delta: float) -> void:
	for index in range(DATA.MAX_ORBS):
		if orb_ages[index] < 0.0:
			continue
		orb_ages[index] += delta
		if orb_ages[index] >= DATA.ORB_SECONDS:
			orb_ages[index] = -1.0
			absorb_orb()

func absorb_orb() -> void:
	play_combat_sound("orb")
	gauge = minf(DATA.GAUGE_MAX,gauge+DATA.ORB_GAUGE*(2.0 if transcend_level >= 4 else 1.0))
	if transcend_level >= 5:
		orb_heal_buffer += float(max_hp-current_hp)*DATA.ORB_HEAL_MISSING_RATIO
		var whole := int(floor(orb_heal_buffer))
		if whole > 0:
			heal_direct(whole)
			orb_heal_buffer -= whole

func play_combat_sound(cue: String) -> void:
	if not dying and is_instance_valid(combat_sfx):
		combat_sfx.play_cue(cue)

func take_damage(amount: int) -> void:
	var before := current_hp
	super.take_damage(amount)
	if current_hp > 0 and current_hp < before:
		play_combat_sound("hit")

func _begin_death() -> void:
	if is_instance_valid(combat_sfx):
		combat_sfx.stop_all()
	# The cinematic owns the death sound so natural actor removal cannot cut it off.
	super._begin_death()
	effect_layer.queue_redraw()

func _target_feet_position() -> Vector2:
	return hero.get_combat_feet_position() if hero.has_method("get_combat_feet_position") else hero.global_position

func _show_pillar(kind: String, point: Vector2) -> void:
	pillar_kind = kind
	pillar_position = point
	pillar_remaining = 0.30 if kind == "judgment" else 0.50

func _draw() -> void:
	effect_layer.queue_redraw()
	crown_layer.queue_redraw()
	status_layer.queue_redraw()
	if not visual.is_visual_ready():
		draw_circle(Vector2(0,-8),20,Color.WHITE if hit_flash_timer > 0 else Color(0.42,0.74,0.34))
	if dying:
		return

func _draw_combat_effects() -> void:
	if dying:
		return
	if charge_remaining > 0.0:
		var progress := 1.0-charge_remaining/DATA.CHARGE_SECONDS
		FX.draw_frame(effect_layer,"charge",mini(int(progress*7),6),Vector2(0,visual_head_y+ART.BATTLE_VISIBLE_HEIGHT*0.55),lerpf(0.35,1.0,progress))
	if pillar_remaining > 0.0:
		var lifetime := 0.30 if pillar_kind == "judgment" else 0.50
		FX.draw_frame(effect_layer,pillar_kind,int((lifetime-pillar_remaining)*10),to_local(pillar_position))
	for index in range(DATA.MAX_ORBS):
		var age := float(orb_ages[index])
		if age < 0.0:
			continue
		var progress := clampf((age-0.35)/(DATA.ORB_SECONDS-0.35),0.0,1.0)
		var point := orb_origins[index].lerp(global_position+Vector2(0,visual_head_y+ART.BATTLE_VISIBLE_HEIGHT*0.55),progress*progress)
		FX.draw_frame(effect_layer,"orb",mini(int(age*14),4) if age < 0.35 else 5+int(age*14)%2,to_local(point))

func _draw_crown_layer() -> void:
	if dying or crown_remaining <= 0.0:
		return
	var frame := mini(int(crown_elapsed*10),3) if crown_elapsed < 0.4 else (6+mini(int((0.2-crown_remaining)*10),1) if crown_remaining < 0.2 else 4+int(crown_elapsed*10)%2)
	FX.draw_frame(crown_layer,"crown",frame,Vector2(0,visual_head_y))

func _draw_status_layer() -> void:
	if dying:
		return
	var hp_y := visual_head_y-30.0
	status_layer.draw_rect(Rect2(-29,hp_y,58,7),Color(0.12,0.12,0.14))
	status_layer.draw_rect(Rect2(-29,hp_y,58*float(current_hp)/maxi(max_hp,1),7),Color(0.3,0.9,0.45))
	status_layer.draw_rect(Rect2(-29,visual_head_y-41.0,58,6),Color("241c13"))
	status_layer.draw_rect(Rect2(-29,visual_head_y-41.0,58*gauge/DATA.GAUGE_MAX,6),Color("ffdb3b"))
	var shield := int(get_meta("support_shield_hp",0))
	if shield > 0:
		var ratio := clampf(float(shield)/maxi(int(get_meta("support_shield_capacity",shield)),1),0.0,1.0)
		status_layer.draw_rect(Rect2(-29,hp_y-23.0,58,6),Color("202c40"))
		status_layer.draw_rect(Rect2(-29,hp_y-23.0,58*ratio,6),Color("61ddff"))
