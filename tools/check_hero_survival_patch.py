#!/usr/bin/env python3
"""Static content/connection audit, explicitly not a Godot runtime test."""
from pathlib import Path
import json
import math
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
def source(path): return (ROOT / path).read_text()
def constant(text, name):
    prefix = f"const {name} := "
    payload = re.sub(r",\s*([}\]])", r"\1", text.split(prefix, 1)[1])
    return json.JSONDecoder().raw_decode(payload)[0]
def half_up(value): return math.floor(value + 0.5)

catalog = source("src/data/hero_weapon_catalog.gd")
mode = source("src/data/hero_mode_catalog.gd")
runtime = source("src/hero_mode/hero_weapon_runtime.gd")
hero = source("src/hero/hero.gd")
ui = source("src/hero_mode/hero_mode.gd")
icons = source("src/ui/hero_augment_icons.gd")
weapons = constant(catalog, "WEAPONS")
kits = constant(catalog, "HERO_WEAPONS")
passives = constant(catalog, "PASSIVES")
assert len(weapons) == 60 and len(kits) == 10
assert len(passives) == 8 and constant(catalog, "PASSIVE_SLOTS") == 6
assert constant(catalog, "WEAPON_SLOTS") == 3
assert set(p["stat"] for p in passives.values()) == {
    "power", "mobility", "projectile", "haste", "learning", "magnet", "vitality", "armor"}
for data in passives.values():
    assert f'"{data["stat"]}"' in runtime and data["value"] > 0
for owner, pool in kits.items():
    assert len(pool) == 6 and all(weapons[x]["owner"] == owner for x in pool)
assert set(sum(kits.values(), [])) == set(weapons)
phases = constant(mode, "PHASES")
assert phases[0]["interval"] == .9 and phases[0]["batch"] == 2
assert phases[0]["limit"] == 36 and phases[0]["regen"] == 20
assert all(a["interval"] > b["interval"] and a["batch"] < b["batch"]
           for a, b in zip(phases, phases[1:]))
assert phases[-1]["limit"] == constant(mode, "MONSTER_LIMIT") == 72
assert constant(mode, "DURATION") == 900
# Evaluate the numeric expression extracted from the authored curve.
expression = re.search(r'return roundi\(([^\n]+)\)', mode).group(1)
def required(level):
    return half_up(eval(expression, {"__builtins__": {}}, {"rank": max(level-1, 0)}))
assert [required(n) for n in (1, 10, 30)] == [20, 151, 731]
ratio = constant(mode, "EXP_REWARD_RATIO")
for amount in (25, 100, 1972, 3432):
    for bonus in (1.0, 1.08, 1.8):
        total, carry = 0, 0.0
        for _ in range(amount):
            scaled = ratio*bonus + carry
            gained = math.floor(scaled + 1e-9)
            carry = max(0.0, scaled - gained)
            total += gained
        assert total == math.floor(amount*ratio*bonus + 1e-10)
assert "player_exp_remainder = maxf(0.0,scaled_exp-gained_exp)" in hero
assert "gained_exp = maxi(1,int(round(float(amount)*maxf(exp_gain_multiplier,0.0))))" in hero
assert "return 50 + maxi(target_level - 1, 0) * 25" in hero
assert "not damage_already_mitigated" in hero.split("raw_damage *= player_weapons.damage_multiplier")[0][-120:]
assert "hero.exp_pickup_radius = base_pickup_radius*(1.0+bonus)" in runtime
assert "get_battle_entity_handle" in runtime and "resolve_battle_entity" in runtime
assert "const PROJECTILE_LIMIT := 64" in runtime
for forbidden in ("get_nodes_in_group", "instantiate(", "queue_free("):
    assert forbidden not in runtime
assert "HorizontalAugmentCards" in ui and "Control.PRESET_CENTER" in ui
assert "MOUSE_FILTER_IGNORE" in ui and "TEXTURE_FILTER_NEAREST" in ui
order = constant(icons, "PASSIVE_ORDER")
assert len(order) == 8 and set(order) == set(passives)
manifest = json.loads(source("assets/art/UI/hero_augments/manifest.json"))
assert set(manifest["icons"]) == set(weapons) | set(passives)
for sheet, grid in (("weapons.png", (6, 10)), ("passives.png", (4, 2))):
    data = (ROOT / "assets/art/UI/hero_augments" / sheet).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height = struct.unpack('>II', data[16:24])
    assert data[25] == 6  # RGBA transparency
    assert abs(width/grid[0] - height/grid[1]) < 1
    cells = [v["region"] for v in manifest["icons"].values() if v["sheet"] == sheet]
    assert len(cells) == grid[0]*grid[1]
    assert len(set(map(tuple, cells))) == len(cells)
    for x, y, w, h in cells:
        assert x >= 0 and y >= 0 and w > 0 and h > 0 and x+w <= width and y+h <= height
print("HERO_SURVIVAL_STATIC_AUDIT PASS: 60 weapons, 8 passives/6 slots, 68 atlas regions, XP boundaries, bounded projectiles, centered cards")
