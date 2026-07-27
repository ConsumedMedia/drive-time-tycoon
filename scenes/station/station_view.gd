extends Control

@export var station_resource_path: String = "res://data/stations/chill_coastal_station.tres"

var station: Station

func _ready() -> void:
	station = load(station_resource_path)
	GameState.add_station(station)
	%EndWeek.pressed.connect(_on_end_week_pressed)
	_refresh_labels()

func _on_end_week_pressed() -> void:
	WeeklyTick.run_weekly_tick()
	_refresh_labels()

func _refresh_labels() -> void:
	%StationName.text = station.station_name
	%Listeners.text = "Listeners: " + str(station.listeners)
	%Hype.text = "Hype: " + str(int(station.hype))
	%Loyalty.text = "Loyalty: " + str(int(station.loyalty))
	%Cash.text = "Cash: $" + str(station.cash)
