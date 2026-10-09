extends RefCounted
## Presentation-only registry. Keys: domain:owner_id:skill_id (or authored skill name).
## Domains: demon, elite, transcendent, hero. No guessed filenames or combat changes.
const PATHS := {
	"transcendent:bulgasal:전략후퇴": "res://assets/art/Icon/monster/Transcendent/bulgasal/devour.png",
	"transcendent:bulgasal:강철도약": "res://assets/art/Icon/monster/Transcendent/bulgasal/immortal_rampage.png",
	"transcendent:bulgasal:바위돌진": "res://assets/art/Icon/monster/Transcendent/bulgasal/thorn_charge.png",
	"transcendent:bulgasal:바위던지기": "res://assets/art/Icon/monster/Transcendent/bulgasal/iron_bite.png",
	"transcendent:izanami:황천윤무": "res://assets/art/Icon/monster/Transcendent/izanami/soul_lantern.png",
	"transcendent:izanami:명계귀화": "res://assets/art/Icon/monster/Transcendent/izanami/death_blossom.png",
	"transcendent:izanami:원혼추살": "res://assets/art/Icon/monster/Transcendent/izanami/yomi_wave.png",
	"transcendent:shuten_doji:혈주연무": "res://assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill1_icon.png",
	"transcendent:shuten_doji:귀염지폭": "res://assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill2_icon.png",
	"transcendent:shuten_doji:쇄혼귀면": "res://assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill3_icon.png",
	"transcendent:shuten_doji:귀왕해방": "res://assets/art/Icon/monster/Transcendent/shuten-doji/shuten-doji_skill4_icon.png",
	"transcendent:manticore:재앙의 불꽃": "res://assets/art/Icon/monster/Transcendent/manticore/manticore_skill1_icon.png",
	"transcendent:manticore:맹독유성": "res://assets/art/Icon/monster/Transcendent/manticore/manticore_skill2_icon.png",
	"transcendent:manticore:지각분쇄": "res://assets/art/Icon/monster/Transcendent/manticore/manticore_skill3_icon.png",
	"transcendent:manticore:살을 찢는 공포": "res://assets/art/Icon/monster/Transcendent/manticore/manticore_skill4_icon.png",
	"demon:demon:encirclement": "res://assets/art/Icon/demonking/circular_siege.png",
	"demon:demon:line_assault": "res://assets/art/Icon/demonking/line_assault.png",
	"demon:demon:square_siege": "res://assets/art/Icon/demonking/square_siege.png",
	"elite:banshee:elite_banshee_possession": "res://assets/art/Icon/monster/banshee/banshee.png",
	"elite:bat:elite_bat_poison_fang": "res://assets/art/Icon/monster/bat/poison_fang.png",
	"elite:bomb_rat:elite_bomb_rat_vibration": "res://assets/art/Icon/monster/bomb_rat/tremor_sense.png",
	"elite:ghost:elite_ghost_fear": "res://assets/art/Icon/monster/ghost/fear.png",
	"elite:goblin:elite_goblin_commander": "res://assets/art/Icon/monster/goblin/commander.png",
	"elite:goblin_thrower:elite_goblin_thrower_bombardment": "res://assets/art/Icon/monster/goblin_bomber/bomb_drop.png",
	"elite:kobolt:elite_kobolt_fighting_spirit": "res://assets/art/Icon/monster/kobold/fighting_spirit.png",
	"elite:medusa:elite_medusa_hidden_poison": "res://assets/art/Icon/monster/medusa/hidden_poison.png",
	"elite:mummy:elite_mummy_curse": "res://assets/art/Icon/monster/mummy/mummy_curse.png",
	"elite:powwow_mummy:elite_powwow_mummy_multicast": "res://assets/art/Icon/monster/mummy_shaman/multi_cast.png",
	"elite:orc:elite_orc_frenzy": "res://assets/art/Icon/monster/orc/frenzy.png",
	"elite:scorpion:elite_scorpion_consume": "res://assets/art/Icon/monster/scorpion/survival_of_the_fittest.png",
	"elite:skeleton:elite_skeleton_ambush": "res://assets/art/Icon/monster/skeleton_warrior/ambush.png",
	"elite:skeleton_archer:elite_skeleton_archer_arrow_rain": "res://assets/art/Icon/monster/skeleton_archer/arrow_rain.png",
	"elite:slime:elite_slime_proliferation": "res://assets/art/Icon/monster/slime/split_growth.png",
	"elite:spider:elite_spider_web_nest": "res://assets/art/Icon/monster/spider/web_trap.png",
	"elite:wolf:elite_wolf_pack_hunt": "res://assets/art/Icon/monster/wolf/pack_hunt.png",
	"elite:yuki_onna:elite_yuki_snowflake": "res://assets/art/Icon/monster/snow_maiden/snow_flower.png",
	"elite:dullahan:elite_dullahan_march": "res://assets/art/Icon/monster/specter_knight/specter_advance.png",
	"elite:dullahan:elite_dullahan_charge": "res://assets/art/Icon/monster/specter_knight/spectral_charge.png",
	"elite:dullahan:elite_dullahan_slam": "res://assets/art/Icon/monster/specter_knight/specter_smash.png",
	"elite:succubus:elite_succubus_cut": "res://assets/art/Icon/monster/succubus/lacerate.png",
	"elite:succubus:elite_succubus_drain": "res://assets/art/Icon/monster/succubus/essence_drain.png",
	"elite:succubus:elite_succubus_waltz": "res://assets/art/Icon/monster/succubus/waltz_of_temptation.png",
	"hero:ranged_rookie:arcane_piercer": "res://assets/art/Icon/hero/apprentice_mage/arcane_piercer.png",
	"hero:ranged_rookie:arcane_barrier": "res://assets/art/Icon/hero/apprentice_mage/arcane_barrier.png",
	"hero:ranged_rookie:arcane_field": "res://assets/art/Icon/hero/apprentice_mage/arcane_focus.png",
	"hero:swift_hunter:blade_storm": "res://assets/art/Icon/hero/agile_hero/rend.png",
	"hero:swift_hunter:shadow_assassination": "res://assets/art/Icon/hero/agile_hero/ambush_assassination.png",
	"hero:sword_shield_hero:shield_charge": "res://assets/art/Icon/hero/sword_and_shield_hero/shield_charge.png",
	"hero:sword_shield_hero:shield_guard": "res://assets/art/Icon/hero/sword_and_shield_hero/guard.png",
	"hero:sword_shield_hero:fighter_slash": "res://assets/art/Icon/hero/sword_and_shield_hero/slash.png",
	"hero:sword_shield_hero:fighter_thrust": "res://assets/art/Icon/hero/sword_and_shield_hero/thrust.png",
	"hero:pistol_hero:gunner_backstep": "res://assets/art/Icon/hero/gunslinger/backstep.png",
	"hero:pistol_hero:gunner_cylinder": "res://assets/art/Icon/hero/gunslinger/cylinder_strike.png",
	"hero:pistol_hero:gunner_deadeye": "res://assets/art/Icon/hero/gunslinger/deadeye.png",
	"hero:pistol_hero:gunner_quickdraw": "res://assets/art/Icon/hero/gunslinger/quick_draw.png",
	"hero:archmage_hero:archmage_combustion": "res://assets/art/Icon/hero/archmage/ignite.png",
	"hero:archmage_hero:archmage_ice_bolt": "res://assets/art/Icon/hero/archmage/ice_bolt.png",
	"hero:archmage_hero:archmage_earth_spikes": "res://assets/art/Icon/hero/archmage/earth_spike.png",
	"hero:archmage_hero:archmage_holy_power": "res://assets/art/Icon/hero/archmage/holy_power.png",
	"hero:archmage_hero:archmage_chain_dagger": "res://assets/art/Icon/hero/archmage/chain_dagger.png",
	"hero:archmage_hero:archmage_harmony": "res://assets/art/Icon/hero/archmage/harmony.png",
	"hero:archmage_hero:archmage_storm": "res://assets/art/Icon/hero/archmage/storm.png",
	"hero:madness_hero:blood_sword_first": "res://assets/art/Icon/hero/mad_hero/blood_sword_form_1.png",
	"hero:madness_hero:blood_sword_second": "res://assets/art/Icon/hero/mad_hero/blood_sword_form_2.png",
	"hero:madness_hero:blood_sword_third": "res://assets/art/Icon/hero/mad_hero/blood_sword_form_3.png",
	"hero:madness_hero:blood_sword_fourth": "res://assets/art/Icon/hero/mad_hero/blood_sword_form_4.png",
	"hero:chemical_hero:alchemist_catalyst_field": "res://assets/art/Icon/hero/alchemist_hero/catalyst_mixture_field.png",
	"hero:chemical_hero:alchemist_mystery_cauldron": "res://assets/art/Icon/hero/alchemist_hero/what_will_come_out.png",
	"hero:chemical_hero:alchemist_today_failed_again": "res://assets/art/Icon/hero/alchemist_hero/another_failure_today.png",
	"hero:chemical_hero:alchemist_philosopher_stone": "res://assets/art/Icon/hero/alchemist_hero/philosophers_stone.png",
	"hero:summoner_hero:summoner_full_slot_shield": "res://assets/art/Icon/hero/otherworld_hero/saturation_barrier.png",
	"hero:summoner_hero:summoner_gatekeeper": "res://assets/art/Icon/hero/otherworld_hero/gatekeeper.png",
	"hero:summoner_hero:summoner_scout": "res://assets/art/Icon/hero/otherworld_hero/scout.png",
	"hero:summoner_hero:summoner_hound": "res://assets/art/Icon/hero/otherworld_hero/war_hound.png",
	"hero:summoner_hero:summoner_watcher": "res://assets/art/Icon/hero/otherworld_hero/watcher.png",
	"hero:summoner_hero:summoner_open_gate": "res://assets/art/Icon/hero/otherworld_hero/gate_open.png",
	"hero:purifier_hero:purifier_divine_protection": "res://assets/art/Icon/hero/purifier_hero/divine_protection.png",
	"hero:purifier_hero:purifier_crown_of_courage": "res://assets/art/Icon/hero/purifier_hero/crown_of_courage.png",
	"hero:purifier_hero:purifier_purification_orb": "res://assets/art/Icon/hero/purifier_hero/purifying_orb.png",
	"hero:purifier_hero:purifier_cleansing": "res://assets/art/Icon/hero/purifier_hero/purification.png",
	"hero:purifier_hero:purifier_gungnir": "res://assets/art/Icon/hero/purifier_hero/gungnir.png",
	"hero:sage_astra:freezing_point_explosion": "res://assets/art/Icon/hero/archsage/freezing_point_explosion.png",
	"hero:sage_astra:radiance_singularity": "res://assets/art/Icon/hero/archsage/radiant_singularity.png",
	"hero:sage_astra:mana_condensation": "res://assets/art/Icon/hero/archsage/mana_condensation.png",
	"hero:sage_astra:starlight": "res://assets/art/Icon/hero/archsage/starlight.png",
	"hero:sage_astra:annihilation": "res://assets/art/Icon/hero/archsage/annihilation.png",
	"hero:sage_astra:black_spot_explosion": "res://assets/art/Icon/hero/archsage/black_sun_explosion.png",
	"transcendent:zeus:심판": "res://assets/art/Icon/monster/Transcendent/zeus/judgment.png",
	"transcendent:zeus:천둥구체": "res://assets/art/Icon/monster/Transcendent/zeus/thunder_orb.png",
	"transcendent:zeus:왕관": "res://assets/art/Icon/monster/Transcendent/zeus/crown.png",
	"transcendent:zeus:천둥가르기": "res://assets/art/Icon/monster/Transcendent/zeus/thunder_cleave.png",
	"transcendent:zeus:과전압": "res://assets/art/Icon/monster/Transcendent/zeus/overcharge.png",
	"transcendent:izanami:요모츠히라사카": "res://assets/art/Icon/monster/Transcendent/izanami/yomi_gate.png"
}
static var textures: Dictionary = {}
static func key(domain: String, owner_id: String, skill_id: String) -> String:
	return "%s:%s:%s" % [domain,owner_id,skill_id]
static func path(domain: String, owner_id: String, skill_id: String) -> String:
	return String(PATHS.get(key(domain,owner_id,skill_id),""))
static func texture(domain: String, owner_id: String, skill_id: String) -> Texture2D:
	return load_texture(path(domain,owner_id,skill_id))

static func load_texture(location: String) -> Texture2D:
	if location.is_empty(): return null
	if textures.has(location) and textures[location] != null: return textures[location]
	var result: Texture2D
	if ResourceLoader.exists(location):
		var resource = load(location)
		if resource is Texture2D: result = resource
	# Editor import sidecars may not yet exist after pulling newly added PNGs.
	# Exported builds use imported Texture2D; raw fallback is cached once per path.
	if result == null and FileAccess.file_exists(location):
		var image := Image.new()
		if image.load(location) == OK: result = ImageTexture.create_from_image(image)
	# Large authored UI paintings alias badly under point sampling at tiny sizes.
	# Downsample once; existing 128px pixel icons and source files stay intact.
	if result != null and maxf(result.get_width(),result.get_height()) > 256:
		var thumbnail := result.get_image()
		if thumbnail != null:
			var ratio := 128.0 / maxf(thumbnail.get_width(),thumbnail.get_height())
			thumbnail.resize(maxi(1,roundi(thumbnail.get_width()*ratio)),maxi(1,roundi(thumbnail.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
			result = ImageTexture.create_from_image(thumbnail)
	textures[location] = result
	return result

# UI-only entries for existing attacks/passives stored as scalar profile fields.
const EXTRA_HERO_SLOTS := {
	"pistol_hero": [{"id":"gunner_backstep","name":"백스텝"},{"id":"gunner_cylinder","name":"실린더타격"},{"id":"gunner_deadeye","name":"데드아이"},{"id":"gunner_quickdraw","name":"속사"}],
	"sword_shield_hero": [{"id":"fighter_slash","name":"베기"},{"id":"fighter_thrust","name":"찌르기"}],
}
static var hero_hud_paths: Dictionary = {}
static func hero_hud_path(skill_id: String) -> String:
	if hero_hud_paths.is_empty():
		for icon_key in PATHS:
			if String(icon_key).begins_with("hero:"):
				hero_hud_paths[String(icon_key).get_slice(":",2)] = PATHS[icon_key]
	return String(hero_hud_paths.get(skill_id,""))
