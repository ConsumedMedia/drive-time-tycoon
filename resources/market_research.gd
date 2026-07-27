extends Resource
class_name MarketResearch

## Which city this research covers
@export var city: City

## Player's discovered approximation of the city's true format_fit — same key structure, noisy values
@export var revealed_format_fit: Dictionary = {}

## How close revealed values are to the truth, 0-100 (higher = tighter noise band)
@export var research_accuracy: float = 0.0

## Which in-game week this research was last run — old research should be allowed to go stale
@export var last_researched_week: int = 0
