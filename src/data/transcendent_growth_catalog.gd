extends RefCounted
## Fixed additions per growth unit; BASE and battle event counting stay independent.
## Attack is the TOTAL two-hit addition for burst, divided between hits by its catalog.
const VERSION := "2026-10-11-v1"
const TANK := {"attack_damage":1.5,"max_hp":15.0}
const RANGED := {"attack_damage":1.0,"max_hp":5.0}
const CONTROL := {"attack_damage":1.0,"max_hp":5.0}
const BURST := {"attack_damage":1.5,"max_hp":5.0}
# Damage has a different unit from event counts. Keep fractional units until final rounding.
const DAMAGE_PER_UNIT := 10.0
const BURST_HITS := 2.0
const DAMAGE_GROWTH := {"attack_damage":BURST.attack_damage/DAMAGE_PER_UNIT/BURST_HITS,"max_hp":BURST.max_hp/DAMAGE_PER_UNIT}
