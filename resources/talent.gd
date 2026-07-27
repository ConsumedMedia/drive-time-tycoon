extends Resource
class_name Talent

## Display name
@export var talent_name: String = "New Talent"

## Personality trait — drives the gameplay quirk, not just flavor
@export_enum("Loose Cannon", "Fan Favorite", "Smooth Operator", "Rising Star", "Old Reliable") var personality_trait: String = "Old Reliable"

## Single skill number, 1-10
@export_range(1, 10) var skill: int = 5

## Weekly cost to keep this Talent on roster
@export var salary: int = 0

## Grows with good weeks; high fame = rival poaching risk
@export var fame: float = 0.0

## Happiness — low morale increases scandal/dead-air event odds
@export_range(0, 100) var morale: float = 100.0

## Contract length remaining, in weeks (0 = no active contract / free agent)
@export var contract_weeks_remaining: int = 0


## Direct listener swing this Talent contributes to their Daypart's week.
## Only Loose Cannon has a direct effect here - other traits work through
## hype decay, loyalty, or fame instead (see below).
func get_listener_trait_effect() -> float:
	match personality_trait:
		"Loose Cannon":
			return randf_range(-10.0, 30.0)
		_:
			return 0.0

## Extra hype decay this Talent adds on top of the station's base decay.
func get_hype_decay_bonus() -> float:
	match personality_trait:
		"Loose Cannon":
			return 3.0
		_:
			return 0.0

## Extra loyalty gain this Talent adds on top of the station's base gain.
func get_loyalty_bonus() -> float:
	match personality_trait:
		"Fan Favorite":
			return 1.0
		_:
			return 0.0

## Weekly fame growth rate. Rising Star and Old Reliable are confirmed from
## design history. The other three traits' rates are NOT confirmed from any
## prior design doc - 0.5 is a placeholder default, tune as you playtest.
func get_fame_growth_rate() -> float:
	match personality_trait:
		"Rising Star":
			return 2.0
		"Old Reliable":
			return 0.2
		_:
			return 0.5  # placeholder for Loose Cannon / Fan Favorite / Smooth Operator
