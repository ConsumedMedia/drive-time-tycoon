extends Node

## WeeklyTick autoload - the core simulation driver.
## Call run_station_week() once per owned station when the player hits
## "End Week (All Stations)".

## Confirmed from design history: flat weekly hype decay, not a percentage.
const BASE_HYPE_DECAY := 7.0

## NOT confirmed from any prior design doc - the original base loyalty gain
## number wasn't recoverable. Placeholder, tune as you playtest.
const BASE_LOYALTY_GAIN := 0.5

const SPONSOR_QUALITY_THRESHOLD := 40.0
const SATISFACTION_DROP_ON_MISS := 15.0
const SATISFACTION_RECOVERY_ON_HIT := 5.0

## NOT confirmed from any prior design doc - these trigger chances and effect
## magnitudes are new placeholder values, not pulled from earlier design work.
## Tune freely as you playtest.
const STATION_EVENT_CHANCE := 0.15
const NETWORK_EVENT_CHANCE := 0.10

const STATION_EVENT_POOL: Array[String] = [
	"res://data/events/bidding_war.tres",
	"res://data/events/star_poach_attempt.tres",
	"res://data/events/viral_clip.tres",
]

const NETWORK_EVENT_POOL: Array[String] = [
	"res://data/events/recession_hits.tres",
]

## Maps Daypart.Slot enum values to the string labels Sponsor uses,
## since Sponsor.demanded_daypart is a plain string, not the Slot enum.
const SLOT_TO_STRING := {
	Daypart.Slot.MORNING: "Morning",
	Daypart.Slot.MIDDAY: "Midday",
	Daypart.Slot.AFTERNOON: "Afternoon",
	Daypart.Slot.NIGHT: "Night",
}


## NOT confirmed from any prior design doc - fatigue magnitude per extra
## syndicated station is a new placeholder value. Tune as you playtest.
const SYNDICATION_FATIGUE_PER_STATION := 3.0

## Network-wide tick, called by the "End Week (All Stations)" button.
## Runs every owned station's week, then handles network-level upkeep.
func run_weekly_tick() -> void:
	GameState.current_week += 1
	GameState.cash -= GameState.total_weekly_salaries()

	for station in GameState.owned_stations:
		run_station_week(station)

	_process_show_lifecycle()
	_process_network_events()


## Runs weekly_update() and syndication fatigue exactly once per unique Show,
## regardless of how many Dayparts (possibly across multiple stations) air
## it. This has to be centralized rather than done per-Daypart in
## run_station_week - a syndicated Show sitting on 3 stations would otherwise
## have weekly_update() (and weeks_running, prestige drift) fire 3 times in
## a single week, which is wrong.
func _process_show_lifecycle() -> void:
	var processed_shows: Array[Show] = []

	for station in GameState.owned_stations:
		for daypart in station.dayparts:
			if daypart.is_staffed() and not processed_shows.has(daypart.show):
				processed_shows.append(daypart.show)

	for show in processed_shows:
		var station_count: int = _count_stations_airing_show(show)
		show.syndicated_station_count = max(0, station_count - 1)

		show.weekly_update()

		if station_count > 1:
			show.apply_syndication_fatigue(station_count)
		else:
			show.apply_exclusivity_bonus()

## Counts how many distinct owned stations currently air this exact Show
## (same object, not just same show_name) on any of their Dayparts.
func _count_stations_airing_show(show: Show) -> int:
	var count := 0
	for station in GameState.owned_stations:
		for daypart in station.dayparts:
			if daypart.show == show:
				count += 1
				break
	return count


func run_station_week(station: Station) -> void:
	var total_listeners_change := 0.0
	var reputation_delta := 0.0
	var total_hype_decay_bonus := 0.0
	var total_loyalty_bonus := 0.0

	for daypart in station.dayparts:
		if not daypart.is_staffed():
			# An empty Daypart actively hurts you - dead air, no listeners held.
			total_listeners_change -= 5.0
			continue

		var show: Show = daypart.show
		var format_fit: float = station.city.get_format_fit(station.format)
		var loyalty_multiplier: float = 1.0 + (station.loyalty / 100.0)
		var rival_pressure: float = station.city.rival_pressure

		var trait_effects := 0.0
		for host in show.hosts:
			trait_effects += host.get_listener_trait_effect()
			total_hype_decay_bonus += host.get_hype_decay_bonus()
			total_loyalty_bonus += host.get_loyalty_bonus()

		# Show quality replaces raw talent_skill as the core driver here -
		# quality already blends production_budget and host skill together.
		var listeners_change: float = (
			(station.hype * format_fit)
			+ (show.quality * loyalty_multiplier)
			- rival_pressure
			+ trait_effects
		)

		total_listeners_change += listeners_change

		# Prestige feeds reputation slowly - a station running high-prestige
		# Shows should drift toward a strong reputation over time.
		reputation_delta += (show.prestige - 50.0) * 0.02

		for host in show.hosts:
			host.fame = clamp(host.fame + host.get_fame_growth_rate(), 0.0, 100.0)

	station.listeners = max(0, station.listeners + total_listeners_change)
	station.reputation = clamp(station.reputation + reputation_delta, 0.0, 100.0)

	# Flat weekly hype decay plus any trait bonuses (e.g. Loose Cannon hosts).
	station.hype = clamp(station.hype - (BASE_HYPE_DECAY + total_hype_decay_bonus), 0.0, 100.0)
	station.loyalty = clamp(station.loyalty + (BASE_LOYALTY_GAIN + total_loyalty_bonus), 0.0, 100.0)

	_process_sponsors(station)
	_process_station_events(station)


## Each sponsor demands a specific Daypart slot be staffed at a minimum
## quality - or, if demanded_daypart is "None", just wants ANY daypart
## staffed at that quality (general on-air presence rather than a specific slot).
## Meeting demand pays out and nudges satisfaction back up. Missing it drops
## satisfaction. Hitting 0 satisfaction walks the sponsor off the station.
func _process_sponsors(station: Station) -> void:
	var sponsors_to_remove: Array[Sponsor] = []

	for sponsor in station.active_sponsors:
		var demand_met := false

		if sponsor.demanded_daypart == "None":
			for daypart in station.dayparts:
				if daypart.is_staffed() and daypart.get_quality() >= SPONSOR_QUALITY_THRESHOLD:
					demand_met = true
					break
		else:
			for daypart in station.dayparts:
				if SLOT_TO_STRING.get(daypart.slot) == sponsor.demanded_daypart:
					demand_met = (
						daypart.is_staffed()
						and daypart.get_quality() >= SPONSOR_QUALITY_THRESHOLD
					)
					break

		if demand_met:
			station.cash += sponsor.payout
			sponsor.satisfaction = clamp(
				sponsor.satisfaction + SATISFACTION_RECOVERY_ON_HIT, 0.0, 100.0
			)
		else:
			sponsor.satisfaction = clamp(
				sponsor.satisfaction - SATISFACTION_DROP_ON_MISS, 0.0, 100.0
			)

		if sponsor.satisfaction <= 0.0:
			sponsors_to_remove.append(sponsor)

	for sponsor in sponsors_to_remove:
		station.active_sponsors.erase(sponsor)
		# Hook point for Phase 1 UI: surface a "sponsor walked" notification here.


## Rolls a chance for one random Station-tier NetworkEvent to fire on this
## station this week. Effects are applied by name match below - NetworkEvent
## itself only carries flavor data, actual mechanics live here per its
## trigger_notes design intent.
func _process_station_events(station: Station) -> void:
	if randf() > STATION_EVENT_CHANCE or STATION_EVENT_POOL.is_empty():
		return

	var event_path: String = STATION_EVENT_POOL[randi() % STATION_EVENT_POOL.size()]
	var event: NetworkEvent = load(event_path)

	_apply_station_event(event, station)
	_log_event(event, station)

## Rolls a chance for one random Network-tier NetworkEvent to fire this week.
func _process_network_events() -> void:
	if randf() > NETWORK_EVENT_CHANCE or NETWORK_EVENT_POOL.is_empty():
		return

	var event_path: String = NETWORK_EVENT_POOL[randi() % NETWORK_EVENT_POOL.size()]
	var event: NetworkEvent = load(event_path)

	_apply_network_event(event)
	_log_event(event, null)

func _apply_station_event(event: NetworkEvent, station: Station) -> void:
	match event.event_name:
		"Bidding War":
			station.hype = clamp(station.hype - 15.0, 0.0, 100.0)
		"Star Poach Attempt":
			if not station.roster.is_empty():
				var top_talent: Talent = station.roster[0]
				for talent in station.roster:
					if talent.skill > top_talent.skill:
						top_talent = talent
				station.loyalty = clamp(station.loyalty - 10.0, 0.0, 100.0)
				top_talent.fame = clamp(top_talent.fame + 5.0, 0.0, 100.0)
		"Viral Clip":
			station.hype = clamp(station.hype + 20.0, 0.0, 100.0)
			station.reputation = clamp(station.reputation + 5.0, 0.0, 100.0)

func _apply_network_event(event: NetworkEvent) -> void:
	match event.event_name:
		"Recession Hits":
			GameState.cash = int(GameState.cash * 0.9)
			for station in GameState.owned_stations:
				station.hype = clamp(station.hype - 5.0, 0.0, 100.0)

## Logs a fired event to GameState for future UI, and prints it so it's
## visible during testing before any event notification UI exists.
func _log_event(event: NetworkEvent, station: Station) -> void:
	var context: String = station.station_name if station != null else "Network-wide"
	var message: String = "[Week %d] %s - %s: %s" % [
		GameState.current_week,
		context,
		event.event_name,
		event.description
	]
	GameState.recent_events.append(message)
	print(message)
