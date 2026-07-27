extends Node

## WeeklyTick autoload - the core simulation driver.
## Call run_station_week() once per owned station when the player hits
## "End Week (All Stations)".

const SPONSOR_QUALITY_THRESHOLD := 40.0
const SATISFACTION_DROP_ON_MISS := 15.0
const SATISFACTION_RECOVERY_ON_HIT := 5.0

func run_station_week(station: Station) -> void:
	var total_listeners_change := 0.0
	var reputation_delta := 0.0

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
			trait_effects += host.get_trait_effect(station)

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

		# Fame growth for hosts, same as before Show existed.
		for host in show.hosts:
			host.fame = clamp(host.fame + host.get_fame_growth_rate(), 0.0, 100.0)

	station.listeners = max(0, station.listeners + total_listeners_change)
	station.reputation = clamp(station.reputation + reputation_delta, 0.0, 100.0)

	# Hype decay and loyalty drift unchanged from your existing formula.
	station.hype = clamp(station.hype - station.hype * 0.15, 0.0, 100.0)
	station.loyalty = clamp(station.loyalty + (station.hype - 50.0) * 0.01, 0.0, 100.0)

	_process_sponsors(station)


## Rebuilt sponsor logic: each sponsor demands a specific Daypart slot be
## staffed at a minimum quality. Meeting demand pays out and nudges
## satisfaction back up. Missing it drops satisfaction. Hitting 0
## satisfaction walks the sponsor off the station entirely.
func _process_sponsors(station: Station) -> void:
	var sponsors_to_remove: Array[Sponsor] = []

	for sponsor in station.active_sponsors:
		var demanded_daypart: Daypart = null
		for daypart in station.dayparts:
			if daypart.slot == sponsor.daypart_demand:
				demanded_daypart = daypart
				break

		var demand_met: bool = (
			demanded_daypart != null
			and demanded_daypart.is_staffed()
			and demanded_daypart.get_quality() >= SPONSOR_QUALITY_THRESHOLD
		)

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
