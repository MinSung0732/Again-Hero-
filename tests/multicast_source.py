"""Reverse exact multicast reset/start guards; unexpected changes fail comparison."""
import re
from ice_impact_source import without_ice_impact_guards
REPLACEMENTS = {'configure_profile': [('\t_cancel_archmage_multicast()',
                        '\tarchmage_multicast_active = false\n'
                        '\tarchmage_multicast_candidates.clear()')],
 '_start_archmage_multicast': [('\tvar source_life := _capture_delayed_skill_source()\n'
                                '\tif source_life.x < 0:\n'
                                '\t\treturn\n'
                                '\tvar source_scope_id := get_parent().get_instance_id()\n'
                                '\t_cancel_archmage_multicast()\n'
                                '\tvar reservation_revision := archmage_multicast_revision\n'
                                '\tfor key',
                                '\tarchmage_multicast_candidates.clear()\n\tfor key'),
                               ('\t\tif reservation_revision != archmage_multicast_revision or not '
                                '_is_delayed_skill_source_current(source_life, source_scope_id):\n'
                                '\t\t\tbreak\n'
                                '\t\tawait get_tree().create_timer(0.30).timeout',
                                '\t\tawait get_tree().create_timer(0.30).timeout'),
                               ('\t\tawait get_tree().create_timer(0.30).timeout\n'
                                '\t\tif reservation_revision != archmage_multicast_revision or not '
                                '_is_delayed_skill_source_current(source_life, source_scope_id):',
                                '\t\tawait get_tree().create_timer(0.30).timeout\n'
                                '\t\tif not is_inside_tree() or current_hp <= 0:'),
                               ('\t# Do not clear candidates or active state owned by a newer '
                                'reservation.\n'
                                '\tif reservation_revision == archmage_multicast_revision and '
                                '_is_delayed_skill_life_current(source_life, source_scope_id):\n'
                                '\t\t_cancel_archmage_multicast()',
                                '\tarchmage_multicast_candidates.clear()\n'
                                '\tarchmage_multicast_active = false')]}
def without_multicast_guards(source):
    source = without_ice_impact_guards(source)
    for name, pairs in REPLACEMENTS.items():
        m = re.search(r"^func " + name + r"\(", source, re.M)
        if m is None: continue
        end = re.search(r"\nfunc ", source[m.start():])
        stop = m.start() + end.start() if end else len(source)
        body = source[m.start():stop]
        for new, old in reversed(pairs): body = body.replace(new, old)
        source = source[:m.start()] + body + source[stop:]
    return source
