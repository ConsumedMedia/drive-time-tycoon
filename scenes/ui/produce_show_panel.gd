extends Control

## Lets the player either produce a NEW Show using a Talent already on the
## current station's roster, or SYNDICATE an existing Show already airing
## somewhere else in the network onto one of this station's Dayparts.
## StationView sets target_station right after instantiating this panel.

var target_station: Station = null

## All Shows currently airing anywhere in the network, excluding ones
## already airing on target_station (syndicating a Show to a station that
## already has it doesn't make sense).
var syndicatable_shows: Array[Show] = []

const SHOW_TYPE_NAMES := ["Music Block", "Talk Show", "News Update", "Countdown", "Call-In", "Syndicated Rerun"]
const TONE_NAMES := ["Wholesome", "Edgy", "Serious", "Chaotic", "Prestige"]
const DAYPART_SLOT_NAMES := ["Morning", "Midday", "Afternoon", "Night"]
const MODE_NAMES := ["Produce New Show", "Syndicate Existing Show", "Retire Show to Catalog"]

func _ready() -> void:
	%ModeOption.clear()
	for name in MODE_NAMES:
		%ModeOption.add_item(name)
	%ModeOption.item_selected.connect(_on_mode_selected)

	%ShowTypeOption.clear()
	for name in SHOW_TYPE_NAMES:
		%ShowTypeOption.add_item(name)

	%ToneOption.clear()
	for name in TONE_NAMES:
		%ToneOption.add_item(name)

	_refresh_host_options()
	_refresh_daypart_options()
	_refresh_syndicatable_shows()

	%ProduceButton.pressed.connect(_on_produce_pressed)

	_on_mode_selected(0)

func _on_mode_selected(index: int) -> void:
	var is_syndicate_mode: bool = index == 1
	var is_retire_mode: bool = index == 2
	var is_produce_mode: bool = index == 0

	%HostOption.visible = is_produce_mode
	%ShowTypeOption.visible = is_produce_mode
	%ToneOption.visible = is_produce_mode
	%BudgetInput.visible = is_produce_mode
	%ExistingShowOption.visible = is_syndicate_mode

	if is_syndicate_mode:
		%ProduceButton.text = "Syndicate Show"
	elif is_retire_mode:
		%ProduceButton.text = "Retire to Catalog"
	else:
		%ProduceButton.text = "Produce Show"

func _refresh_host_options() -> void:
	%HostOption.clear()

	if target_station == null or target_station.roster.is_empty():
		%HostOption.add_item("No Talent on roster - hire someone first")
		return

	for talent in target_station.roster:
		%HostOption.add_item("%s (Skill: %d)" % [talent.talent_name, talent.skill])

func _refresh_daypart_options() -> void:
	%DaypartOption.clear()

	if target_station == null:
		return

	for daypart in target_station.dayparts:
		var slot_name: String = DAYPART_SLOT_NAMES[daypart.slot]
		var status: String = "empty" if not daypart.is_staffed() else "will replace current Show"
		%DaypartOption.add_item("%s (%s)" % [slot_name, status])

func _refresh_syndicatable_shows() -> void:
	syndicatable_shows.clear()
	%ExistingShowOption.clear()

	for station in GameState.owned_stations:
		for daypart in station.dayparts:
			if not daypart.is_staffed():
				continue
			if daypart.show in syndicatable_shows:
				continue
			if _station_already_airs_show(target_station, daypart.show):
				continue
			syndicatable_shows.append(daypart.show)
			%ExistingShowOption.add_item(
				"\"%s\" (Quality: %d, on %d station%s)" % [
					daypart.show.show_name,
					int(daypart.show.quality),
					daypart.show.syndicated_station_count + 1,
					"" if daypart.show.syndicated_station_count == 0 else "s"
				]
			)

	if syndicatable_shows.is_empty():
		%ExistingShowOption.add_item("No syndicatable Shows available yet")

func _station_already_airs_show(station: Station, show: Show) -> bool:
	if station == null:
		return false
	for daypart in station.dayparts:
		if daypart.show == show:
			return true
	return false

func _on_produce_pressed() -> void:
	if target_station == null:
		return

	if %ModeOption.selected == 1:
		_on_syndicate_pressed()
		return

	if %ModeOption.selected == 2:
		_on_retire_pressed()
		return

	if target_station.roster.is_empty():
		%ResultLabel.text = "No Talent on roster - hire someone first."
		return

	var budget: int = int(%BudgetInput.value)
	if budget > target_station.cash:
		%ResultLabel.text = "Not enough cash - you have $%d." % target_station.cash
		return

	var host: Talent = target_station.roster[%HostOption.selected]
	var daypart: Daypart = target_station.dayparts[%DaypartOption.selected]

	var show := Show.new()
	show.show_name = "%s's %s" % [host.talent_name, SHOW_TYPE_NAMES[%ShowTypeOption.selected]]
	show.show_type = %ShowTypeOption.selected as Show.ShowType
	show.tone = %ToneOption.selected as Show.Tone
	show.produce(budget, [host])

	target_station.cash -= budget
	daypart.assign_show(show)

	%ResultLabel.text = "Produced \"%s\" (Quality: %d) - now airing %s." % [
		show.show_name,
		int(show.quality),
		DAYPART_SLOT_NAMES[daypart.slot]
	]

	_refresh_daypart_options()
	_refresh_syndicatable_shows()

func _on_syndicate_pressed() -> void:
	if syndicatable_shows.is_empty():
		return

	var show: Show = syndicatable_shows[%ExistingShowOption.selected]
	var daypart: Daypart = target_station.dayparts[%DaypartOption.selected]

	daypart.assign_show(show)

	%ResultLabel.text = "Syndicated \"%s\" onto %s's %s slot." % [
		show.show_name,
		target_station.station_name,
		DAYPART_SLOT_NAMES[daypart.slot]
	]

	_refresh_daypart_options()
	_refresh_syndicatable_shows()

## Pulls the Show off EVERY station currently airing it (not just this one -
## retiring is a network-wide action on the Show itself, since it's the same
## underlying object wherever it's syndicated) and moves it into
## GameState.show_catalog for passive income.
func _on_retire_pressed() -> void:
	var daypart: Daypart = target_station.dayparts[%DaypartOption.selected]

	if not daypart.is_staffed():
		%ResultLabel.text = "That slot is already empty - nothing to retire."
		return

	var show: Show = daypart.show
	show.retire_to_catalog()

	for station in GameState.owned_stations:
		for other_daypart in station.dayparts:
			if other_daypart.show == show:
				other_daypart.clear()

	if not GameState.show_catalog.has(show):
		GameState.show_catalog.append(show)

	%ResultLabel.text = "Retired \"%s\" to the back catalog (Peak Prestige: %d). It's now earning passive income." % [
		show.show_name,
		int(show.peak_prestige)
	]

	_refresh_daypart_options()
	_refresh_syndicatable_shows()
