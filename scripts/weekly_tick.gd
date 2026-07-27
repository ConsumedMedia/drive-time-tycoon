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

## Maps Daypart.Slot enum values to the string labels Sponsor uses,
## since Sponsor.demanded_daypart is a plain string, not the Slot enum.
const SLOT_TO_STRING := {
	Daypart.Slot.MORNING: "Morning",
	Daypart.Slot.MIDDAY: "Midday",
	Daypart.Slot.AFTERNOON: "Afternoon",
	Daypart.Slot.NIGHT: "Night",
}


## Network-wide tick, called by the "End Week (All Stations)" button.
## Runs every owned station's week, then handles network-level upkeep.
func run_weekly_tick() -> void:
	GameState.current_week += 1
	GameState.cash -= GameState.total_weekly_salaries()

	for station in GameState.owned_stations:
		run_station_week(station)


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

		show.weekly_update()

		for host in show.hosts:
			host.fame = clamp(host.fame + host.get_fame_growth_rate(), 0.0, 100.0)

	station.listeners = max(0, station.listeners + total_listeners_change)
	station.reputation = clamp(station.reputation + reputation_delta, 0.0, 100.0)

	# Flat weekly hype decay plus any trait bonuses (e.g. Loose Cannon hosts).
	station.hype = clamp(station.hype - (BASE_HYPE_DECAY + total_hype_decay_bonus), 0.0, 100.0)
	station.loyalty = clamp(station.loyalty + (BASE_LOYALTY_GAIN + total_loyalty_bonus), 0.0, 100.0)

	_process_sponsors(station)


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
