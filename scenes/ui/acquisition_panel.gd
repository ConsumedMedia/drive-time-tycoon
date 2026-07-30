extends Control

## Lets the player found a new station in a city they don't already own one
## in. Deducts the city's acquisition_cost from GameState.cash and creates
## a new Station with four empty Dayparts, ready for Produce Show.

@export var city_paths: Array[String] = [
	"res://data/cities/chill_coastal_village.tres",
	"res://data/cities/college_town.tres",
	"res://data/cities/retiree_coast.tres",
]

@export var format_paths: Array[String] = [
	"res://data/formats/pop_hits.tres",
	"res://data/formats/chill_lo_fi.tres",
]

## NOT confirmed from any prior design doc - these are placeholder starting
## stats for a freshly founded station, not pulled from earlier design work.
const STARTING_HYPE := 10.0
const STARTING_LOYALTY := 20.0
const STARTING_CASH := 1000

var available_cities: Array[City] = []
var formats: Array[Format] = []

func _ready() -> void:
	for path in city_paths:
		var city: City = load(path)
		if not _city_already_owned(city):
			available_cities.append(city)

	for path in format_paths:
		formats.append(load(path))

	%CityOption.clear()
	if available_cities.is_empty():
		%CityOption.add_item("No new cities available")
		%FoundButton.disabled = true
	else:
		for city in available_cities:
			%CityOption.add_item(city.city_name)
		%CityOption.item_selected.connect(_on_city_selected)
		%FoundButton.disabled = false

	%FormatOption.clear()
	for format in formats:
		%FormatOption.add_item(format.format_name)

	%FoundButton.pressed.connect(_on_found_pressed)

	if not available_cities.is_empty():
		_on_city_selected(0)

func _city_already_owned(city: City) -> bool:
	for station in GameState.owned_stations:
		if station.city == city:
			return true
	return false

func _on_city_selected(index: int) -> void:
	var city: City = available_cities[index]
	%CostLabel.text = "Acquisition Cost: $%d\n%s" % [city.acquisition_cost, city.vibe_description]

func _on_found_pressed() -> void:
	if available_cities.is_empty() or formats.is_empty():
		return

	var city: City = available_cities[%CityOption.selected]
	var format: Format = formats[%FormatOption.selected]

	if GameState.cash < city.acquisition_cost:
		%ResultLabel.text = "Not enough cash - you have $%d, need $%d." % [
			GameState.cash,
			city.acquisition_cost
		]
		return

	GameState.cash -= city.acquisition_cost

	var station := Station.new()
	station.station_name = %StationNameInput.text if %StationNameInput.text != "" else "New Station"
	station.format = format
	station.city = city
	station.listeners = 0
	station.hype = STARTING_HYPE
	station.loyalty = STARTING_LOYALTY
	station.cash = STARTING_CASH
	station.critical_reputation = 0.0
	station.commercial_reputation = 0.0

	for slot in Daypart.Slot.values():
		var daypart := Daypart.new()
		daypart.slot = slot
		station.dayparts.append(daypart)

	GameState.add_station(station)

	%ResultLabel.text = "Founded %s in %s!" % [station.station_name, city.city_name]

	# Remove this city from future candidates and refresh the dropdown.
	available_cities.erase(city)
	%CityOption.clear()
	if available_cities.is_empty():
		%CityOption.add_item("No new cities available")
		%FoundButton.disabled = true
	else:
		for remaining_city in available_cities:
			%CityOption.add_item(remaining_city.city_name)
		_on_city_selected(0)
