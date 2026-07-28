extends Node

## The player's overall broadcast group — this is the top-level singleton.

var network_name: String = "New Network"
var cash: int = 10000
var network_reputation: float = 0.0

## HQ upgrade tier — gates loans, sponsor bundle slots, scouting bonuses
var hq_tier: int = 1

## Stations the player currently owns
var owned_stations: Array[Station] = []

## Talent not currently assigned to any station (bench/reserve)
var talent_pool: Array[Talent] = []

## Analysts not currently assigned (bench/reserve) — used for Market Research
var analyst_pool: Array[Analyst] = []

## Sponsors not currently courted by any station (bench/reserve)
var sponsor_pool: Array[Sponsor] = []

## Market Research results, one per city that's been scouted
var market_research: Array[MarketResearch] = []

## Tracks in-game week count, used for research staleness and other time-based logic
var current_week: int = 0

## Which station the player has drilled into from the Network View.
## Set this before changing scene to station_view.tscn - StationView reads
## this instead of a hardcoded station path.
var selected_station: Station = null

## Log of fired NetworkEvent messages, newest last. No UI reads this yet -
## it's here so Station/Network Analytics panels have something to show
## once they're built.
var recent_events: Array[String] = []

## Called once when the game starts / new game begins
func start_new_game() -> void:
	network_name = "New Network"
	cash = 10000
	network_reputation = 0.0
	hq_tier = 1
	current_week = 0
	owned_stations.clear()
	talent_pool.clear()
	analyst_pool.clear()
	sponsor_pool.clear()
	market_research.clear()
	selected_station = null
	recent_events.clear()

## Adds a newly built or acquired station to the network
func add_station(station: Station) -> void:
	owned_stations.append(station)

## Sets which station StationView should display when it loads
func select_station(station: Station) -> void:
	selected_station = station

## Total weekly salary obligation across every owned station's roster
func total_weekly_salaries() -> int:
	var total: int = 0
	for station in owned_stations:
		for talent in station.roster:
			total += talent.salary
	return total

## Sum of listeners across every owned station, for the network-level top bar
func total_network_listeners() -> int:
	var total: int = 0
	for station in owned_stations:
		total += station.listeners
	return total

## Looks up existing research for a given city, or null if never researched
func get_research_for_city(city: City) -> MarketResearch:
	for research in market_research:
		if research.city == city:
			return research
	return null

## Stores new research, replacing any existing entry for the same city
func store_research(research: MarketResearch) -> void:
	for i in range(market_research.size()):
		if market_research[i].city == research.city:
			market_research[i] = research
			return
	market_research.append(research)
