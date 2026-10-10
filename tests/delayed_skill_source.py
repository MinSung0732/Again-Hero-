"""Reverse only exact reviewed delayed-source hooks in named original methods."""
import re
from scalar_skill_source import without_scalar_skill_guards
REPLACEMENTS = {'_resolve_archmage_ice_pillars': [('\tvar source_life := _capture_delayed_skill_source()\n'
                                    '\tif source_life == null:\n'
                                    '\t\treturn\n'
                                    '\tvar config: Dictionary',
                                    '\tvar config: Dictionary'),
                                   ('\tfor index in range(count):\n'
                                    '\t\tif not _is_delayed_skill_source_current(source_life):\n'
                                    '\t\t\tbreak\n',
                                    '\tfor index in range(count):\n'),
                                   ('_damage_monsters_in_radius(position, hit_radius, '
                                    'pillar_damage, source_life)',
                                    '_damage_monsters_in_radius(position, hit_radius, '
                                    'pillar_damage)')],
 '_cast_archmage_earth_spikes': [('\tvar source_life := _capture_delayed_skill_source()\n'
                                  '\tif source_life == null:\n'
                                  '\t\treturn\n'
                                  '\t_begin_archmage_casting_sequence()',
                                  '\t_begin_archmage_casting_sequence()'),
                                 ('if not _is_delayed_skill_source_current(source_life):',
                                  'if not is_inside_tree() or current_hp <= 0:'),
                                 ('if _is_delayed_skill_source_current(source_life):',
                                  'if is_inside_tree() and current_hp > 0:'),
                                 ('_damage_monsters_in_radius_once(position, radius, spike_damage, '
                                  'hit_ids, source_life)',
                                  '_damage_monsters_in_radius_once(position, radius, spike_damage, '
                                  'hit_ids)'),
                                 ('\t\t\t\t\thit_ids,\n\t\t\t\t\tsource_life\n',
                                  '\t\t\t\t\thit_ids\n'),
                                 ('\n'
                                  '\t\t\t\tif not _is_delayed_skill_source_current(source_life):\n'
                                  '\t\t\t\t\tbreak\n'
                                  '\t\t\t\t_spawn_archmage_fx(\n'
                                  '\t\t\t\t\t'
                                  '"res://assets/art/heroes/stage5_archmage/frames/effect1",\n'
                                  '\t\t\t\t\t"earth", 1, 11, 22.0, false,\n'
                                  '\t\t\t\t\tright_position',
                                  '\n'
                                  '\t\t\t\t_spawn_archmage_fx(\n'
                                  '\t\t\t\t\t'
                                  '"res://assets/art/heroes/stage5_archmage/frames/effect1",\n'
                                  '\t\t\t\t\t"earth", 1, 11, 22.0, false,\n'
                                  '\t\t\t\t\tright_position'),
                                 ('\n'
                                  "\t# Old tasks must not decrement a new life's casting counter.\n"
                                  '\tif _is_delayed_skill_life_current(source_life):\n'
                                  '\t\t_end_archmage_casting_sequence()',
                                  '\n\t_end_archmage_casting_sequence()')],
 '_damage_monsters_in_radius': [('damage: int, source_life: RefCounted = null) -> void:',
                                 'damage: int) -> void:'),
                                ('\tfor node in _combat_monster_scratch:\n'
                                 '\t\tif source_life != null and not '
                                 '_is_delayed_skill_source_current(source_life):\n'
                                 '\t\t\tbreak\n',
                                 '\tfor node in _combat_monster_scratch:\n')],
 '_damage_monsters_in_radius_once': [('\thit_ids: Dictionary,\n\tsource_life: RefCounted = null\n',
                                      '\thit_ids: Dictionary\n'),
                                     ('\tfor node in _combat_monster_scratch:\n'
                                      '\t\tif source_life != null and not '
                                      '_is_delayed_skill_source_current(source_life):\n'
                                      '\t\t\tbreak\n',
                                      '\tfor node in _combat_monster_scratch:\n')],
 '_cast_archmage_holy_power': [('\tvar source_life := _capture_delayed_skill_source()\n'
                                '\tif source_life == null:\n'
                                '\t\treturn\n'
                                '\tvar source_scope := get_parent()\n'
                                '\tvar tracked_targets := '
                                'source_scope.has_method("get_battle_entity_handle")\n'
                                '\t_begin_archmage_casting_sequence()',
                                '\t_begin_archmage_casting_sequence()'),
                               ('\t\tif _is_delayed_skill_life_current(source_life):\n'
                                '\t\t\t_end_archmage_casting_sequence()\n'
                                '\t\treturn',
                                '\t\t_end_archmage_casting_sequence()\n\t\treturn'),
                               ('if not _is_delayed_skill_source_current(source_life):',
                                'if not is_inside_tree() or current_hp <= 0:'),
                               ('\t\tfor node in archmage_query_candidates:\n'
                                '\t\t\tif not _is_delayed_skill_source_current(source_life):\n'
                                '\t\t\t\tbreak\n',
                                '\t\tfor node in archmage_query_candidates:\n'),
                               ('\t\t\t# Capture a scalar handle only; damage callbacks may '
                                'recycle this Node.\n'
                                '\t\t\tvar victim_handle := Vector3i.ZERO\n'
                                '\t\t\tif tracked_targets:\n'
                                '\t\t\t\tvictim_handle = '
                                'source_scope.call("get_battle_entity_handle", monster)\n'
                                '\t\t\tmonster.call("take_damage", dealt)\n'
                                '\t\t\tif not _is_delayed_skill_source_current(source_life):\n'
                                '\t\t\t\tbreak\n'
                                '\t\t\tif not is_instance_valid(monster) or '
                                'monster.is_queued_for_deletion():\n'
                                '\t\t\t\tcontinue\n'
                                '\t\t\tif tracked_targets and (\n'
                                '\t\t\t\tvictim_handle == Vector3i.ZERO\n'
                                '\t\t\t\tor source_scope.call("resolve_battle_entity", '
                                'victim_handle) != monster\n'
                                '\t\t\t):\n'
                                '\t\t\t\tcontinue\n',
                                '\t\t\tmonster.call("take_damage", dealt)\n'),
                               ('\n'
                                '\tif _is_delayed_skill_life_current(source_life):\n'
                                '\t\t_end_archmage_casting_sequence()',
                                '\n\t_end_archmage_casting_sequence()'),
                               ('\t\t\tif not is_instance_valid(node):\n'
                                '\t\t\t\tcontinue\n'
                                '\t\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n',
                                '\t\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n')]}
def without_delayed_skill_guards(source, names=None):
    source = without_scalar_skill_guards(source)
    for name, pairs in REPLACEMENTS.items():
        if names is not None and name not in names:
            continue
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None:
            continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs):
            body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
