"""Reverse exact wave lifetime hooks for existing projectile regressions."""
import re
REPLACEMENTS = {'_damage_berserker_wave_sweep': [(') -> void:\n'
                                   '\tvar life_revision := _chain_life_revision\n'
                                   '\tif not _is_wave_life_current(life_revision):\n'
                                   '\t\treturn\n'
                                   '\tvar scope := get_parent()\n'
                                   '\tvar tracked_targets := scope.has_method("get_battle_entity_handle")\n'
                                   '\tvar hit_radius: float = maxf(',
                                   ') -> void:\n\tvar hit_radius: float = maxf('),
                                  ('\t\tsearch_radius\n'
                                   '\t):\n'
                                   '\t\tif not _is_wave_life_current(life_revision):\n'
                                   '\t\t\treturn\n'
                                   '\t\tif not is_instance_valid(node)',
                                   '\t\tsearch_radius\n\t):\n\t\tif not is_instance_valid(node)'),
                                  ('\t\tvar victim_handle := Vector3i.ZERO\n'
                                   '\t\tif tracked_targets:\n'
                                   '\t\t\tvictim_handle = scope.call("get_battle_entity_handle", monster)\n'
                                   '\t\tmonster.call("take_damage", damage)\n'
                                   '\t\tif not _is_wave_life_current(life_revision):\n'
                                   '\t\t\treturn\n'
                                   '\n'
                                   '\t\t# Snapshot the result before hit-heal callbacks can recycle the '
                                   'victim.\n'
                                   '\t\tvar killed := hp_before > 0 and not is_instance_valid(monster)\n'
                                   '\t\tif hp_before > 0 and is_instance_valid(monster):\n'
                                   '\t\t\tvar same_victim := not tracked_targets\n'
                                   '\t\t\tif tracked_targets and victim_handle != Vector3i.ZERO:\n'
                                   '\t\t\t\tvar current_handle: Vector3i = '
                                   'scope.call("get_battle_entity_handle", monster)\n'
                                   '\t\t\t\t# Normal death retires the handle; a new nonzero generation is '
                                   'another victim.\n'
                                   '\t\t\t\tsame_victim = current_handle == victim_handle or current_handle '
                                   '== Vector3i.ZERO\n'
                                   '\t\t\tif same_victim:\n'
                                   '\t\t\t\tvar hp_after_value = monster.get("current_hp")\n'
                                   '\t\t\t\tkilled = hp_after_value != null and int(hp_after_value) <= 0\n'
                                   '\t\tif source_hero.has_method("notify_berserker_blood_art_hit"):\n'
                                   '\t\t\tsource_hero.call("notify_berserker_blood_art_hit")\n'
                                   '\t\t\tif not _is_wave_life_current(life_revision):\n'
                                   '\t\t\t\treturn\n'
                                   '\t\tif killed and '
                                   'source_hero.has_method("notify_berserker_skill_kill"):\n'
                                   '\t\t\tsource_hero.call("notify_berserker_skill_kill")\n'
                                   '\t\t\tif not _is_wave_life_current(life_revision):\n'
                                   '\t\t\t\treturn\n',
                                   '\t\tmonster.call("take_damage", damage)\n'
                                   '\t\tif (\n'
                                   '\t\t\tis_instance_valid(source_hero)\n'
                                   '\t\t\tand source_hero.has_method(\n'
                                   '\t\t\t\t"notify_berserker_blood_art_hit"\n'
                                   '\t\t\t)\n'
                                   '\t\t):\n'
                                   '\t\t\tsource_hero.call(\n'
                                   '\t\t\t\t"notify_berserker_blood_art_hit"\n'
                                   '\t\t\t)\n'
                                   '\n'
                                   '\t\tif hp_before <= 0:\n'
                                   '\t\t\tcontinue\n'
                                   '\t\tvar killed: bool = false\n'
                                   '\t\tif not is_instance_valid(monster):\n'
                                   '\t\t\tkilled = true\n'
                                   '\t\telse:\n'
                                   '\t\t\tvar hp_after_value = monster.get("current_hp")\n'
                                   '\t\t\tif hp_after_value != null and int(hp_after_value) <= 0:\n'
                                   '\t\t\t\tkilled = true\n'
                                   '\t\tif (\n'
                                   '\t\t\tkilled\n'
                                   '\t\t\tand is_instance_valid(source_hero)\n'
                                   '\t\t\tand source_hero.has_method("notify_berserker_skill_kill")\n'
                                   '\t\t):\n'
                                   '\t\t\tsource_hero.call("notify_berserker_skill_kill")\n')],
 '_physics_process': [('\tif skill_type == "berserker_wave":\n'
                       '\t\tif not _is_wave_life_current(life_revision):\n'
                       '\t\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\t\treturn\n'
                       '\t\tvar previous_position:',
                       '\tif skill_type == "berserker_wave":\n\t\tvar previous_position:'),
                      ('\t\t\tglobal_position\n'
                       '\t\t)\n'
                       '\t\tif not _is_wave_life_current(life_revision):\n'
                       '\t\t\t_finish_elemental_revision(life_revision)\n'
                       '\t\t\treturn\n'
                       '\t\tif traveled >= max_range:',
                       '\t\t\tglobal_position\n\t\t)\n\t\tif traveled >= max_range:')],
 'setup': [('\telif skill_type == "ice_bolt" or skill_type == "storm" or skill_type == "berserker_wave":',
            '\telif skill_type == "ice_bolt" or skill_type == "storm":')]}

def without_wave_projectile_guards(body):
    name = re.match(r"func ([^(]+)", body).group(1)
    for new, old in REPLACEMENTS.get(name, []):
        if body.endswith(new.rstrip()):
            new, old = new.rstrip(), old.rstrip()
        assert body.count(new) == 1, (name, new)
        body = body.replace(new, old)
    return body
