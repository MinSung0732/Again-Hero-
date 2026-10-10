extends RefCounted

# Stable protocol IDs. Declaring a future mode does not enable its gameplay.
enum Mode { DEMON_SOLO = 1, HERO_SOLO = 2, PVP_CASUAL = 3, PVP_RANKED = 4 }
enum Role { DEMON = 1, HERO = 2 }
enum Command { SUMMON_AUTO = 1, SUMMON_AT = 2, SUMMON_TRANSCENDENT = 3, DEMON_SKILL = 4, DEMON_AUGMENT_CHOOSE = 5, DEMON_AUGMENT_REROLL = 6, MUTATION_CHOOSE = 7 }
const PROTOCOL_VERSION := 3
const MAX_SEQUENCE := 2147483647
const MAX_CONTENT_ID_LENGTH := 64
const DIRECTIONS := ["", "east", "west", "north", "south"]

static func supports_local_execution(mode: int) -> bool:
	return mode == Mode.DEMON_SOLO

static func command_role(kind: int) -> int:
	match kind:
		Command.SUMMON_AUTO, Command.SUMMON_AT, Command.SUMMON_TRANSCENDENT, Command.DEMON_SKILL, Command.DEMON_AUGMENT_CHOOSE, Command.DEMON_AUGMENT_REROLL, Command.MUTATION_CHOOSE:
			return Role.DEMON
	return 0
