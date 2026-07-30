extends Control

## Read-only network-wide summary: top-line stats plus the recent events log.

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var lines: Array[String] = []

	lines.append("NETWORK: %s" % GameState.network_name)
	lines.append("Week: %d" % GameState.current_week)
	lines.append("Cash: $%d" % GameState.cash)
	lines.append("Network Reputation: %d" % int(GameState.network_reputation))
	lines.append("Total Listeners: %d" % GameState.total_network_listeners())
	lines.append("HQ Tier: %d" % GameState.hq_tier)
	lines.append("Weekly Salary Obligation: $%d" % GameState.total_weekly_salaries())
	lines.append("Stations Owned: %d" % GameState.owned_stations.size())
	lines.append("")
	lines.append("--- Per-Station Breakdown ---")

	for station in GameState.owned_stations:
		lines.append(
			"%s | Listeners: %d | Hype: %d | Critical Rep: %d | Commercial Rep: %d | Cash: $%d" % [
				station.station_name,
				station.listeners,
				int(station.hype),
				int(station.critical_reputation),
				int(station.commercial_reputation),
				station.cash
			]
		)

	lines.append("")
	lines.append("--- Back Catalog ---")

	if GameState.show_catalog.is_empty():
		lines.append("No retired Shows yet.")
	else:
		var total_catalog_income := 0
		for show in GameState.show_catalog:
			var weekly_income: int = int(show.peak_prestige * WeeklyTick.CATALOG_INCOME_PER_PRESTIGE)
			total_catalog_income += weekly_income
			lines.append(
				"\"%s\" | Peak Prestige: %d | Earning $%d/wk" % [
					show.show_name,
					int(show.peak_prestige),
					weekly_income
				]
			)
		lines.append("Total Catalog Income: $%d/wk" % total_catalog_income)

	lines.append("")
	lines.append("--- Recent Events ---")

	if GameState.recent_events.is_empty():
		lines.append("No events yet.")
	else:
		# Show the most recent 10, newest first.
		var recent := GameState.recent_events.slice(max(0, GameState.recent_events.size() - 10))
		recent.reverse()
		for event_message in recent:
			lines.append(event_message)

	%AnalyticsLabel.text = "\n".join(lines)
