"""Reverse exact ice impact source hooks; preserve previous fixture comparisons."""
import re
REPLACEMENTS = {'_capture_delayed_skill_source': [('func _capture_delayed_skill_source(require_alive: bool = true) -> '
                                    'Vector3i:\n'
                                    '\t# Scalar reservation: no RefCounted locals retained by abandoned '
                                    'awaits.\n'
                                    '\tif not is_inside_tree() or is_queued_for_deletion() or (require_alive '
                                    'and current_hp <= 0):',
                                    'func _capture_delayed_skill_source() -> Vector3i:\n'
                                    '\t# Scalar reservation: no RefCounted locals retained by abandoned '
                                    'awaits.\n'
                                    '\tif not is_inside_tree() or is_queued_for_deletion() or current_hp <= '
                                    '0:')],
 '_damage_monsters_in_radius': [('func _damage_monsters_in_radius(origin: Vector2, radius: float, damage: '
                                 'int, source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0, '
                                 'require_alive: bool = true) -> void:',
                                 'func _damage_monsters_in_radius(origin: Vector2, radius: float, damage: '
                                 'int, source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0) -> '
                                 'void:'),
                                ('\tfor node in _combat_monster_scratch:\n'
                                 '\t\tif source_scope_id != 0 and (\n'
                                 '\t\t\tnot _is_delayed_skill_life_current(source_life, source_scope_id)\n'
                                 '\t\t\tor (require_alive and current_hp <= 0)\n'
                                 '\t\t):\n'
                                 '\t\t\tbreak\n'
                                 '\t\tif not is_instance_valid(node):',
                                 '\tfor node in _combat_monster_scratch:\n'
                                 '\t\tif source_scope_id != 0 and not '
                                 '_is_delayed_skill_source_current(source_life, source_scope_id):\n'
                                 '\t\t\tbreak\n'
                                 '\t\tif not is_instance_valid(node):')],
 'resolve_archmage_ice_bolt_hit': [(') -> void:\n'
                                    '\t# Already emitted ice keeps its impact at HP0 until this source life '
                                    'retires.\n'
                                    '\tvar source_life := _capture_delayed_skill_source(false)\n'
                                    '\tif source_life.x < 0:\n'
                                    '\t\treturn\n'
                                    '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                    '\t_ensure_archmage_audio_runtime()\n'
                                    '\t_play_archmage_player(archmage_ice_impact_audio)',
                                    ') -> void:\n'
                                    '\t_ensure_archmage_audio_runtime()\n'
                                    '\t_play_archmage_player(archmage_ice_impact_audio)'),
                                   ('\t\timpact_radius,\n'
                                    '\t\timpact_damage, source_life, source_scope_id, false\n'
                                    '\t)\n'
                                    '\tif not _is_delayed_skill_life_current(source_life, source_scope_id):\n'
                                    '\t\treturn\n'
                                    '\t_resolve_archmage_ice_pillars(hit_position, empowered)',
                                    '\t\timpact_radius,\n'
                                    '\t\timpact_damage\n'
                                    '\t)\n'
                                    '\t_resolve_archmage_ice_pillars(hit_position, empowered)')]}

def without_ice_impact_guards(source):
    for name, pairs in REPLACEMENTS.items():
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None: continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs):
            body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
