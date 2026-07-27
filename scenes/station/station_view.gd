extends Control

## StationView - the drill-down from NetworkView. Shows one station's live
## stats and, eventually, its animated Daypart interior. Bottom bar opens
## overlay panels for station-level management.

const PROMOTION_COST: int = 500
const PROMOTION_HYPE_BOOST: float = 25.0

var station: Station

func _ready() -> void:
	# Reads whichever station NetworkView selected. Falls back to the first
	# owned station if none was set, so this scene can still be F6'd standalone.
	station = GameState.selected_station
	if station == null and not GameState.owned_stations.is_empty():
		station = GameState.owned_stations[0]

	%EndWeek.pressed.connect(_on_end_week_pressed)
	%RunPromotion.pressed.connect(_on_run_promotion_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	%HireTalentButton.pressed.connect(_on_hire_talent_pressed)
	%ProduceShowButton.pressed.connect(_on_produce_show_pressed)
	%SponsorsButton.pressed.connect(_on_sponsors_pressed)
	%StationAnalyticsButton.pressed.connect(_on_station_analytics_pressed)

	_refresh_labels()

func _on_end_week_pressed() -> void:
	WeeklyTick.run_weekly_tick()
	_refresh_labels()

func _on_run_promotion_pressed() -> void:
	if station.cash >= PROMOTION_COST:
		station.cash -= PROMOTION_COST
		station.hype = min(100.0, station.hype + PROMOTION_HYPE_BOOST)
	_refresh_labels()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_hire_talent_pressed() -> void:
	print("Hire Talent panel is an empty shell - hire_talent_panel.tscn has no content yet.")

func _on_produce_show_pressed() -> void:
	print("Produce Show panel not built yet - Phase 1 item still outstanding.")

func _on_sponsors_pressed() -> void:
	print("Sponsors panel is an empty shell - sponsor_panel.tscn has no content yet.")

func _on_station_analytics_pressed() -> void:
	print("Station Analytics panel not built yet.")

func _refresh_labels() -> void:
	if station == null:
		%StationName.text = "No station selected"
		return

	%StationName.text = station.station_name
	%Listeners.text = "Listeners: " + str(station.listeners)
	%Hype.text = "Hype: " + str(int(station.hype))
	%Loyalty.text = "Loyalty: " + str(int(station.loyalty))
	%Cash.text = "Cash: $" + str(station.cash)
