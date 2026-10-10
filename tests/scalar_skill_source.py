"""Reverse exact scalar reservation edits; unexpected edits still fail comparison."""
import re
REPLACEMENTS = {'_resolve_archmage_ice_pillars': [('if source_life.x < 0:', 'if source_life == null:'),
                                   ('\t\treturn\n'
                                    '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                    '\t',
                                    '\t\treturn\n\t'),
                                   ('_is_delayed_skill_source_current(source_life, '
                                    'source_scope_id)',
                                    '_is_delayed_skill_source_current(source_life)'),
                                   ('pillar_damage, source_life, source_scope_id)',
                                    'pillar_damage, source_life)'),
                                   ('\n'
                                    '\t\tif not _is_delayed_skill_source_current(source_life, '
                                    'source_scope_id):\n'
                                    '\t\t\tbreak\n'
                                    '\t\tawait get_tree().create_timer(',
                                    '\n\t\tawait get_tree().create_timer(')],
 '_cast_archmage_earth_spikes': [('if source_life.x < 0:', 'if source_life == null:'),
                                 ('\t\treturn\n'
                                  '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                  '\t',
                                  '\t\treturn\n\t'),
                                 ('_is_delayed_skill_source_current(source_life, source_scope_id)',
                                  '_is_delayed_skill_source_current(source_life)'),
                                 ('_is_delayed_skill_life_current(source_life, source_scope_id)',
                                  '_is_delayed_skill_life_current(source_life)'),
                                 ('hit_ids, source_life, source_scope_id)',
                                  'hit_ids, source_life)'),
                                 ('\t\t\t\t\tsource_life,\n\t\t\t\t\tsource_scope_id\n',
                                  '\t\t\t\t\tsource_life\n'),
                                 ('\n'
                                  '\t\tif not _is_delayed_skill_source_current(source_life, '
                                  'source_scope_id):\n'
                                  '\t\t\tbreak\n'
                                  '\t\tawait get_tree().create_timer(',
                                  '\n\t\tawait get_tree().create_timer('),
                                 ('\n'
                                  '\t\t\t\tif not _is_delayed_skill_source_current(source_life, '
                                  'source_scope_id):\n'
                                  '\t\t\t\t\tbreak\n'
                                  '\t\t\t\tawait get_tree().create_timer(',
                                  '\n\t\t\t\tawait get_tree().create_timer(')],
 '_cast_archmage_holy_power': [('if source_life.x < 0:', 'if source_life == null:'),
                               ('\t\treturn\n'
                                '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                '\t',
                                '\t\treturn\n\t'),
                               ('_is_delayed_skill_source_current(source_life, source_scope_id)',
                                '_is_delayed_skill_source_current(source_life)'),
                               ('_is_delayed_skill_life_current(source_life, source_scope_id)',
                                '_is_delayed_skill_life_current(source_life)'),
                               ('\n'
                                '\t\tif not _is_delayed_skill_source_current(source_life, '
                                'source_scope_id):\n'
                                '\t\t\tbreak\n'
                                '\t\tawait get_tree().create_timer(',
                                '\n\t\tawait get_tree().create_timer(')],
 '_damage_monsters_in_radius': [('source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0',
                                 'source_life: RefCounted = null'),
                                ('source_scope_id != 0 and not '
                                 '_is_delayed_skill_source_current(source_life, source_scope_id)',
                                 'source_life != null and not '
                                 '_is_delayed_skill_source_current(source_life)')],
 '_damage_monsters_in_radius_once': [('source_life: Vector3i = Vector3i.ZERO, source_scope_id: int '
                                      '= 0',
                                      'source_life: RefCounted = null'),
                                     ('source_scope_id != 0 and not '
                                      '_is_delayed_skill_source_current(source_life, '
                                      'source_scope_id)',
                                      'source_life != null and not '
                                      '_is_delayed_skill_source_current(source_life)')],
 '_capture_delayed_skill_source': [('func _capture_delayed_skill_source() -> Vector3i:\n'
                                    '\t# Scalar reservation: no RefCounted locals retained by '
                                    'abandoned awaits.\n'
                                    '\tif not is_inside_tree() or is_queued_for_deletion() or '
                                    'current_hp <= 0:\n'
                                    '\t\treturn Vector3i(-1, -1, -1)\n'
                                    '\tvar scope := get_parent()\n'
                                    '\tif not is_instance_valid(scope) or '
                                    'scope.is_queued_for_deletion():\n'
                                    '\t\treturn Vector3i(-1, -1, -1)\n'
                                    '\tvar tracked := scope.has_method("get_battle_entity_handle") '
                                    'or scope.has_method("resolve_battle_entity")\n'
                                    '\tif not tracked:\n'
                                    '\t\treturn Vector3i.ZERO\n'
                                    '\tif not scope.has_method("get_battle_entity_handle") or not '
                                    'scope.has_method("resolve_battle_entity"):\n'
                                    '\t\treturn Vector3i(-1, -1, -1)\n'
                                    '\tvar handle: Vector3i = '
                                    'scope.call("get_battle_entity_handle", self)\n'
                                    '\tif handle == Vector3i.ZERO or '
                                    'scope.call("resolve_battle_entity", handle) != self:\n'
                                    '\t\treturn Vector3i(-1, -1, -1)\n'
                                    '\treturn handle\n',
                                    'func _capture_delayed_skill_source() -> RefCounted:\n'
                                    '\t# One immutable reservation per concurrent cast; no '
                                    'allocation on resolve/tick.\n'
                                    '\tif not is_inside_tree() or current_hp <= 0:\n'
                                    '\t\treturn null\n'
                                    '\tvar source_life = BATTLE_TARGET_REFERENCE.new()\n'
                                    '\tif not source_life.capture(self, get_parent()):\n'
                                    '\t\treturn null\n'
                                    '\treturn source_life\n')],
 '_is_delayed_skill_life_current': [('func _is_delayed_skill_life_current(source_life: Vector3i, '
                                     'source_scope_id: int) -> bool:\n'
                                     '\tif not is_inside_tree() or is_queued_for_deletion() or '
                                     'source_life.x < 0:\n'
                                     '\t\treturn false\n'
                                     '\tvar scope := get_parent()\n'
                                     '\tif not is_instance_valid(scope) or '
                                     'scope.is_queued_for_deletion() or scope.get_instance_id() != '
                                     'source_scope_id:\n'
                                     '\t\treturn false\n'
                                     '\tif source_life == Vector3i.ZERO:\n'
                                     '\t\treturn not scope.has_method("get_battle_entity_handle") '
                                     'and not scope.has_method("resolve_battle_entity")\n'
                                     '\treturn scope.has_method("resolve_battle_entity") and '
                                     'scope.call("resolve_battle_entity", source_life) == self\n',
                                     'func _is_delayed_skill_life_current(source_life: RefCounted) '
                                     '-> bool:\n'
                                     '\treturn is_inside_tree() and source_life != null and '
                                     'source_life.resolve(get_parent()) == self\n')],
 '_is_delayed_skill_source_current': [('func _is_delayed_skill_source_current(source_life: '
                                       'Vector3i, source_scope_id: int) -> bool:\n'
                                       '\treturn current_hp > 0 and '
                                       '_is_delayed_skill_life_current(source_life, '
                                       'source_scope_id)\n',
                                       'func _is_delayed_skill_source_current(source_life: '
                                       'RefCounted) -> bool:\n'
                                       '\treturn current_hp > 0 and '
                                       '_is_delayed_skill_life_current(source_life)\n')]}
def without_scalar_skill_guards(source):
    for name, pairs in REPLACEMENTS.items():
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None: continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs): body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
