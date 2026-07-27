extends Resource
class_name NetworkEvent

## Display name — "Bidding War", "Star Poach Attempt", "Recession Hits", etc.
@export var event_name: String = "New Event"

## Flavor/flavor-text shown to the player when this fires
@export_multiline var description: String = ""

## Which tier this event operates at
@export_enum("Station", "Network") var event_tier: String = "Station"

## Rough condition check, described in plain language for now (actual trigger logic lives in weekly_tick.gd)
@export var trigger_notes: String = ""

## Whether this event presents the player with a choice (vs. just applying an effect automatically)
@export var has_player_choice: bool = false
