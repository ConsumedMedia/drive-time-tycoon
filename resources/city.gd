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
