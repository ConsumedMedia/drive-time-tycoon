extends Control

## Shows a station's currently active sponsors with satisfaction, and lets
## the player court a new one from GameState.sponsor_pool. StationView sets
## target_station right after instantiating this panel.

var target_station: Station = null

func _ready() -> void:
	%CourtButton.pressed.connect(_on_court_pressed)
	_refresh_active_sponsors()
	_refresh_candidate_options()

func _refresh_active_sponsors() -> void:
	var lines: Array[String] = []

	if target_station == null or target_station.active_sponsors.is_empty():
		lines.append("No active sponsors yet.")
	else:
		for sponsor in target_station.active_sponsors:
			lines.append(
				"%s | Wants: %s | Satisfaction: %d%% | Pays $%d/wk" % [
					sponsor.sponsor_name,
					sponsor.demanded_daypart,
					int(sponsor.satisfaction),
					sponsor.payout
				]
			)

	%ActiveSponsorsLabel.text = "\n".join(lines)

func _refresh_candidate_options() -> void:
	%CandidateOption.clear()

	if GameState.sponsor_pool.is_empty():
		%CandidateOption.add_item("No sponsors currently available to court")
		%CourtButton.disabled = true
		return

	%CourtButton.disabled = false
	for sponsor in GameState.sponsor_pool:
		%CandidateOption.add_item(
			"%s | Wants: %s | Pays $%d/wk" % [
				sponsor.sponsor_name,
				sponsor.demanded_daypart,
				sponsor.payout
			]
		)

func _on_court_pressed() -> void:
	if GameState.sponsor_pool.is_empty() or target_station == null:
		return

	var index: int = %CandidateOption.selected
	var sponsor: Sponsor = GameState.sponsor_pool[index]

	GameState.sponsor_pool.remove_at(index)
	target_station.active_sponsors.append(sponsor)

	%ResultLabel.text = "%s is now sponsoring %s!" % [
		sponsor.sponsor_name,
		target_station.station_name
	]

	_refresh_active_sponsors()
	_refresh_candidate_options()
