"""Reverse exact ice/storm lifetime hooks for existing projectile regression."""
import re
REPLACEMENTS = {'setup': [('\telif skill_type == "ice_bolt" or skill_type == "storm":\n'
            '\t\tvar scope := get_parent()\n'
            '\t\tif not _chain_source_reference.capture(source_hero, scope) or not '
            '_chain_projectile_reference.capture(self, scope):\n'
            '\t\t\t_finish()\n'
            '\t\t\treturn\n'
            '\t_apply_visual()',
            '\t_apply_visual()')],
 '_physics_process': [('\tvar life_revision := _chain_life_revision\n'
                       '\tif (skill_type == "ice_bolt" or skill_type == "storm") and not '
                       '_is_elemental_life_current(life_revision):\n'
                       '\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\treturn\n'
                       '\tif skill_type == "chain_dagger" and not '
                       '_is_chain_life_current(_chain_life_revision):',
                       '\tif skill_type == "chain_dagger" and not '
                       '_is_chain_life_current(_chain_life_revision):'),
                      ('\t\t_damage_storm_area(false)\n'
                       '\t\tif not _is_elemental_life_current(life_revision):\n'
                       '\t\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\t\treturn\n',
                       '\t\t_damage_storm_area(false)\n'),
                      ('\t\t\t_damage_storm_area(true)\n'
                       '\t\t\tif not _is_elemental_life_current(life_revision):\n'
                       '\t\t\t\t_finish_elemental_revision(life_revision)\n',
                       '\t\t\t_damage_storm_area(true)\n')],
 '_damage_storm_area': [('\tvar life_revision := _chain_life_revision\n'
                         '\tif not _is_elemental_life_current(life_revision):\n',
                         '\tif not is_instance_valid(source_hero):\n'),
                        ('\tvar scope := get_parent()\n'
                         '\tvar tracked_targets := scope.has_method("get_battle_entity_handle")\n'
                         '\tfor node in _get_monster_nodes_near(global_position, radius):\n'
                         '\t\tif not _is_elemental_life_current(life_revision):\n'
                         '\t\t\treturn\n',
                         '\tfor node in _get_monster_nodes_near(global_position, radius):\n'),
                        ('\t\tvar victim_handle := Vector3i.ZERO\n'
                         '\t\tif tracked_targets:\n'
                         '\t\t\tvictim_handle = scope.call("get_battle_entity_handle", monster)\n'
                         '\t\tmonster.call("take_damage", hit_damage)\n'
                         '\t\tif not _is_elemental_life_current(life_revision):\n'
                         '\t\t\treturn\n'
                         '\t\tif is_instance_valid(monster) and not '
                         'monster.is_queued_for_deletion() and (\n'
                         '\t\t\tnot tracked_targets or (victim_handle != Vector3i.ZERO and '
                         'scope.call("resolve_battle_entity", victim_handle) == monster)\n'
                         '\t\t):\n'
                         '\t\t\tmonster.set_meta(',
                         '\t\tmonster.call("take_damage", hit_damage)\n\t\tmonster.set_meta('),
                        ('\t\t\t\t"archmage_root_until",\n'
                         '\t\t\t\tTime.get_ticks_msec()\n'
                         '\t\t\t\t+ int(\n'
                         '\t\t\t\t\tmaxf(float(config.get("root_duration", 2.0)), 0.0)\n'
                         '\t\t\t\t\t* 1000.0\n'
                         '\t\t\t\t)\n'
                         '\t\t\t)',
                         '\t\t\t"archmage_root_until",\n'
                         '\t\t\tTime.get_ticks_msec()\n'
                         '\t\t\t+ int(\n'
                         '\t\t\t\tmaxf(float(config.get("root_duration", 2.0)), 0.0)\n'
                         '\t\t\t\t* 1000.0\n'
                         '\t\t\t)\n'
                         '\t\t)'),
                        ('\t\t\t\tmaxf(float(config.get("gauge_restore_per_hit", 4.0)), 0.0)\n'
                         '\t\t\t)\n'
                         '\t\t\tif not _is_elemental_life_current(life_revision):\n'
                         '\t\t\t\treturn',
                         '\t\t\t\tmaxf(float(config.get("gauge_restore_per_hit", 4.0)), 0.0)\n'
                         '\t\t\t)')],
 '_on_body_entered': [('\tif skill_type == "ice_bolt" and not '
                       '_is_elemental_life_current(life_revision):\n'
                       '\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\treturn\n'
                       '\tif skill_type in ["storm", "berserker_wave"]:',
                       '\tif skill_type in ["storm", "berserker_wave"]:'),
                      ('\t\t"ice_bolt":\n'
                       '\t\t\tvar hit_position := global_position\n'
                       '\t\t\tvar scope := get_parent()\n'
                       '\t\t\tvar tracked_target := scope.has_method("get_battle_entity_handle")\n'
                       '\t\t\tvar victim_handle := Vector3i.ZERO\n'
                       '\t\t\tif tracked_target:\n'
                       '\t\t\t\tvictim_handle = scope.call("get_battle_entity_handle", monster)\n'
                       '\t\t\tmonster.call("take_damage", damage)\n'
                       '\t\t\tif not _is_elemental_life_current(life_revision):\n'
                       '\t\t\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\t\t\treturn\n'
                       '\t\t\tvar live_target: Node2D = null\n'
                       '\t\t\tif is_instance_valid(monster) and not '
                       'monster.is_queued_for_deletion() and (\n'
                       '\t\t\t\tnot tracked_target or (victim_handle != Vector3i.ZERO and '
                       'scope.call("resolve_battle_entity", victim_handle) == monster)\n'
                       '\t\t\t):\n'
                       '\t\t\t\tlive_target = monster\n'
                       '\t\t\tif source_hero.has_method("resolve_archmage_ice_bolt_hit"):\n'
                       '\t\t\t\tsource_hero.call("resolve_archmage_ice_bolt_hit", live_target, '
                       'hit_position, empowered)\n'
                       '\t\t\t_finish_elemental_revision(life_revision)',
                       '\t\t"ice_bolt":\n'
                       '\t\t\tmonster.call("take_damage", damage)\n'
                       '\t\t\tif is_instance_valid(source_hero) and '
                       'source_hero.has_method("resolve_archmage_ice_bolt_hit"):\n'
                       '\t\t\t\tsource_hero.call("resolve_archmage_ice_bolt_hit", monster, '
                       'global_position, empowered)\n'
                       '\t\t\t_finish()')]}
def without_elemental_projectile_guards(source):
    for name, pairs in REPLACEMENTS.items():
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None: continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs): body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
