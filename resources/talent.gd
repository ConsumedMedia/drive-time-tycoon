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
