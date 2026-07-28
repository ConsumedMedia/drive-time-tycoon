extends Control

## Lets the player produce a Show using a Talent already on the current
## station's roster, and assign it to one of that station's Dayparts.
## StationView sets target_station right after instantiating this panel.

var target_station: Station = null

const SHOW_TYPE_NAMES := ["Music Block", "Talk Show", "News Update", "Countdown", "Call-In", "Syndicated Rerun"]
const TONE_NAMES := ["Wholesome", "Edgy", "Serious", "Chaotic", "Prestige"]
const DAYPART_SLOT_NAMES := ["Morning", "Midday", "Afternoon", "Night"]

func _ready() -> void:
	%ShowTypeOption.clear()
	for name in SHOW_TYPE_NAMES:
		%ShowTypeOption.add_item(name)

	%ToneOption.clear()
	for name in TONE_NAMES:
		%ToneOption.add_item(name)

	_refresh_host_options()
	_refresh_daypart_options()

	%ProduceButton.pressed.connect(_on_produce_pressed)

func _refresh_host_options() -> void:
	%HostOption.clear()

	if target_station == null or target_station.roster.is_empty():
		%HostOption.add_item("No Talent on roster - hire someone first")
		%ProduceButton.disabled = true
		return

	%ProduceButton.disabled = false
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

func _on_produce_pressed() -> void:
	if target_station == null or target_station.roster.is_empty():
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
