extends Resource
class_name City

## Display name — "Chill Coastal Village", "College Town", etc.
@export var city_name: String = "New City"

## Flavor description shown to the player
@export var vibe_description: String = ""

## Caps max Listeners achievable in this city — Small/Medium/Large tiers
@export_enum("Small", "Medium", "Large") var population_cap: String = "Small"

## Format fit multipliers — key = Format's format_name, value = multiplier (e.g. 1.5 = loves it, 0.5 = hates it)
@export var format_fit: Dictionary = {}

## How much rival stations pressure the player here (used in the weekly listener formula)
@export var rival_pressure: float = 0.0

## Cost to acquire/build a station in this city
@export var acquisition_cost: int = 0


## Looks up this city's fit multiplier for a given Format by name.
## Defaults to 1.0 (neutral) if the format isn't in the dictionary at all -
## that's a City missing config, not a format the city "hates."
func get_format_fit(format: Format) -> float:
	if format == null:
		return 1.0
	return format_fit.get(format.format_name, 1.0)
