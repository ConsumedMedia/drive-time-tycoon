extends Node2D

func _ready() -> void:
	var station: Station = load("res://data/stations/chill_coastal_station.tres")
	GameState.add_station(station)
	print("Before: Listeners = ", station.listeners, ", Hype = ", station.hype, ", Loyalty = ", station.loyalty)
	WeeklyTick.run_weekly_tick()
	print("After:  Listeners = ", station.listeners, ", Hype = ", station.hype, ", Loyalty = ", station.loyalty)
