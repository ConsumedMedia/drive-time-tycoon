extends Control

## Read-only station-level summary: stats, roster, dayparts, sponsors, and
## this station's slice of the recent events log. StationView sets
## target_station right after instantiating this panel.

var target_station: Station = null

const DAYPART_SLOT_NAMES := ["Morning", "Midday", "Afternoon", "Night"]

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var lines: Array[String] = []

	if target_station == null:
		%AnalyticsLabel.text = "No station selected."
		return

	lines.append("STATION: %s" % target_station.station_name)
	lines.append("Listeners: %d" % target_station.listeners)
	lines.append("Hype: %d" % int(target_station.hype))
	lines.append("Loyalty: %d" % int(target_station.loyalty))
	lines.append("Critical Reputation: %d" % int(target_station.critical_reputation))
	lines.append("Commercial Reputation: %d" % int(target_station.commercial_reputation))
	lines.append("Cash: $%d" % target_station.cash)
	lines.append("")
	lines.append("--- Dayparts ---")

	for daypart in target_station.dayparts:
		var slot_name: String = DAYPART_SLOT_NAMES[daypart.slot]
		if daypart.is_staffed():
			lines.append(
				"%s: \"%s\" (Quality: %d, Prestige: %d)" % [
					slot_name,
					daypart.show.show_name,
					int(daypart.show.quality),
					int(daypart.show.prestige)
				]
			)
		else:
			lines.append("%s: empty" % slot_name)

	lines.append("")
	lines.append("--- Roster ---")

	if target_station.roster.is_empty():
		lines.append("No Talent hired.")
	else:
		for talent in target_station.roster:
			lines.append(
				"%s | %s | Skill: %d | Fame: %d | $%d/wk" % [
					talent.talent_name,
					talent.personality_trait,
					talent.skill,
					int(talent.fame),
					talent.salary
				]
			)

	lines.append("")
	lines.append("--- Active Sponsors ---")

	if target_station.active_sponsors.is_empty():
		lines.append("None.")
	else:
		for sponsor in target_station.active_sponsors:
			lines.append(
				"%s | Satisfaction: %d%% | $%d/wk" % [
					sponsor.sponsor_name,
					int(sponsor.satisfaction),
					sponsor.payout
				]
			)

	lines.append("")
	lines.append("--- Recent Events (this station) ---")

	var station_events: Array[String] = []
	for event_message in GameState.recent_events:
		if event_message.contains(target_station.station_name):
			station_events.append(event_message)

	if station_events.is_empty():
		lines.append("No events yet.")
	else:
		var recent := station_events.slice(max(0, station_events.size() - 5))
		recent.reverse()
		for event_message in recent:
			lines.append(event_message)

	%AnalyticsLabel.text = "\n".join(lines)
