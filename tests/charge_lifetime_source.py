"""Restore only the reviewed lifetime hooks for existing source regression checks."""
def without_charge_lifetime_guards(source):
    source = source.replace('''\t# Capture the life once; a reused Node must not inherit this dash.
\tif not fighter_charge_reference.capture(charge_target, get_parent()):''', '''\tif not is_instance_valid(charge_target):''')
    source = source.replace('''\tif fighter_charge_reference.resolve(get_parent()) == null:
\t\t_finish_fighter_charge()
\t\treturn
''', '')
    source = source.replace('''\t# Revalidate immediately before damage, including callbacks during movement.
\tvar live_target := fighter_charge_reference.resolve(get_parent()) as Node2D
\tif live_target == null:
\t\t_finish_fighter_charge()
\t\treturn
''', '')
    source = source.replace('''\tif is_instance_valid(live_target):
\t\t_fighter_charge_damage_target(live_target, dash_damage)''', '''\tif is_instance_valid(fighter_charge_target):
\t\t_fighter_charge_damage_target(fighter_charge_target, dash_damage)''')
    return source.replace('\tfighter_charge_reference.clear()\n', '')
