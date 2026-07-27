extends Resource
class_name Format

## Display name — Pop Hits, Classic Rock, Comedy Talk, True Crime, Sports Rage, Chill Lo-Fi, Country Roads, Hip-Hop Heat
@export var format_name: String = "New Format"

## Flavor tags for matching against Talent personality and City vibe (not deeply wired yet, just descriptive for now)
@export var vibe_tags: Array[String] = []

## How much this format's popularity drifts over time in a given market
@export var trend_volatility: float = 0.0

## Recurring cost to run this format (licensing, syndication, etc.)
@export var licensing_cost: int = 0
