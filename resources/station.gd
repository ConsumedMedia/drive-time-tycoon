extends Resource
class_name Station

## Basic identity
@export var station_name: String = "New Station"
@export var format: Format
@export var city: City

## Core stats — the numbers the player watches
@export var listeners: int = 0
@export var hype: float = 0.0        # 0-100
@export var loyalty: float = 0.0     # 0-100
@export var cash: int = 0
## Split from a single Reputation stat - Critical is driven by prestige/quality
## content, Commercial is driven by reach/hype/mass appeal. Deliberately
## deferred in earlier design, revisited now that Syndication/Distribution
## Choice give the two axes something real to differentiate.
@export var critical_reputation: float = 0.0    # 0-100
@export var commercial_reputation: float = 0.0  # 0-100

## Dayparts: Morning, Midday, Afternoon, Night
@export var dayparts: Array[Daypart] = []

## Talent under contract at this station
@export var roster: Array[Talent] = []

## Sponsors currently running campaigns here
@export var active_sponsors: Array[Sponsor] = []
