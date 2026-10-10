"""Reverse exact combustion/source/FX revision hooks; no function whitelist."""
import re
REPLACEMENTS = {'_cast_archmage_combustion': [('\tvar source_life := _capture_delayed_skill_source()\n'
                                '\tif source_life.x < 0:\n'
                                '\t\treturn\n'
                                '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                '\t_begin_archmage_casting_sequence()',
                                '\t_begin_archmage_casting_sequence()'),
                               ('\tvar charge_fx_revision := '
                                'int(charge_fx.get_meta("archmage_cast_revision", 0)) if '
                                'is_instance_valid(charge_fx) else 0\n'
                                '\tvar duration :=',
                                '\tvar duration :='),
                               ('while elapsed < duration and '
                                '_is_delayed_skill_source_current(source_life, source_scope_id):',
                                'while elapsed < duration and is_inside_tree() and current_hp > '
                                '0:'),
                               ('_damage_monsters_in_radius(orb_position, radius, tick_damage, '
                                'source_life, source_scope_id)',
                                '_damage_monsters_in_radius(orb_position, radius, tick_damage)'),
                               ('\t\tif not _is_delayed_skill_source_current(source_life, '
                                'source_scope_id):\n'
                                '\t\t\tbreak\n'
                                '\t\tawait get_tree().create_timer(tick_interval)',
                                '\t\tawait get_tree().create_timer(tick_interval)'),
                               ('\tif is_instance_valid(charge_fx):\n'
                                '\t\t_recycle_archmage_fx_if_current(charge_fx, '
                                'charge_fx_revision, source_scope_id)',
                                '\tif is_instance_valid(charge_fx):\n'
                                '\t\t_recycle_archmage_fx(charge_fx)'),
                               ('\tif not _is_delayed_skill_source_current(source_life, '
                                'source_scope_id):\n'
                                '\t\tif _is_delayed_skill_life_current(source_life, '
                                'source_scope_id):\n'
                                '\t\t\t_end_archmage_casting_sequence()',
                                '\tif not is_inside_tree() or current_hp <= 0:\n'
                                '\t\t_end_archmage_casting_sequence()'),
                               ('\t\tthrust_damage,\n\t\tsource_life,\n\t\tsource_scope_id\n',
                                '\t\tthrust_damage\n'),
                               ('\tif _is_delayed_skill_source_current(source_life, '
                                'source_scope_id):\n'
                                '\t\t_ensure_archmage_audio_runtime()\n'
                                '\t\t_play_archmage_player(archmage_combustion_release_audio)\n'
                                '\tif _is_delayed_skill_life_current(source_life, '
                                'source_scope_id):\n'
                                '\t\t_end_archmage_casting_sequence()',
                                '\t_ensure_archmage_audio_runtime()\n'
                                '\t_play_archmage_player(archmage_combustion_release_audio)\n'
                                '\t_end_archmage_casting_sequence()')],
 '_spawn_archmage_fx': [('\t# A pooled sprite may now belong to another delayed cast.\n'
                         '\tfx.set_meta("archmage_cast_revision", '
                         'int(fx.get_meta("archmage_cast_revision", 0)) + 1)\n'
                         '\tfx.stop()\n',
                         '\tfx.stop()\n')],
 '_damage_monsters_in_corridor': [('\tdamage: int,\n'
                                   '\tsource_life: Vector3i = Vector3i.ZERO,\n'
                                   '\tsource_scope_id: int = 0\n',
                                   '\tdamage: int\n'),
                                  ('\tfor node in _combat_monster_scratch:\n'
                                   '\t\tif source_scope_id != 0 and not '
                                   '_is_delayed_skill_source_current(source_life, '
                                   'source_scope_id):\n'
                                   '\t\t\tbreak\n',
                                   '\tfor node in _combat_monster_scratch:\n'),
                                  ('\t\tif not is_instance_valid(node):\n'
                                   '\t\t\tcontinue\n'
                                   '\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n',
                                   '\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n')],
 '_damage_monsters_in_radius': [('\t\tif not is_instance_valid(node):\n'
                                 '\t\t\tcontinue\n'
                                 '\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n',
                                 '\t\tif not HERO_TARGET_POLICY.is_detectable(node):\n')]}
def without_fire_skill_guards(source):
    for name, pairs in REPLACEMENTS.items():
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None: continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs): body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
