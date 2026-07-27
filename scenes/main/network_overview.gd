extends Control

@export var station_paths: Array[String] = [
	"res://data/stations/chill_coastal_station.tres",
	"res://data/stations/college_town_station.tres"
]

func _ready() -> void:
	for path in station_paths:
		var station: Station = load(path)
		GameState.add_station(station)

	%EndWeekAll.pressed.connect(_on_end_week_all_pressed)
	_refresh_display()

func _on_end_week_all_pressed() -> void:
	WeeklyTick.run_weekly_tick()
	_refresh_display()

func _refresh_display() -> void:
	%NetworkHeader.text = GameState.network_name + " — Network Cash: $" + str(GameState.cash)

	for child in %StationList.get_children():
		child.queue_free()

	for station in GameState.owned_stations:
		var row := Label.new()
		row.text = "%s | Listeners: %d | Hype: %d | Loyalty: %d | Cash: $%d" % [
			station.station_name,
			station.listeners,
			int(station.hype),
			int(station.loyalty),
			station.cash
		]
		%StationList.add_child(row)
