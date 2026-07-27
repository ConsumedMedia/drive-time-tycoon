extends Resource
class_name Sponsor

## Display name — fictional & fun: "Big Dave's Tire Emporium", "MoonBucks Coffee"
@export var sponsor_name: String = "New Sponsor"

## Weekly payout while satisfied
@export var payout: int = 0

## Plain-language ask shown to the player, e.g. "Wants Morning slot", "Wants 10 spots this week"
@export var demand_description: String = ""

## Which daypart slot this sponsor wants, if any (empty string = no specific slot demand)
@export_enum("None", "Morning", "Midday", "Afternoon", "Night") var demanded_daypart: String = "None"

## How happy the sponsor is — hits 0 and they walk
@export_range(0, 100) var satisfaction: float = 100.0

## True once this sponsor is part of a network-wide bundle deal across multiple stations
@export var is_bundle_deal: bool = false
