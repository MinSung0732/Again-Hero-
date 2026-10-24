extends RefCounted
## World dimensions shown by the solo Camera2D at its default zoom.
## Keep these in step with Main.tscn/BattleViewport and HeroMode._create_battle.
const DEMON_SIZE := Vector2(1080, 1174)
const HERO_SIZE := Vector2(1080, 1920 - preload("res://src/ui/hero_survival_hud.gd").BATTLE_TOP)

static func viewport_size(hero_role: bool) -> Vector2:
	return HERO_SIZE if hero_role else DEMON_SIZE
