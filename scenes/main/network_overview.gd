extends Control

## The Network View — the player's home base. Shows every owned station
## as a clickable entry; clicking one drills into that Station's StationView.
## Bottom bar opens overlay panels for network-level management.

@export var station_paths: Array[String] = [
	"res://data/stations/chill_coastal_station.tres",
	"res://data/stations/college_town_station.tres"
]

const MARKET_RESEARCH_PANEL := preload("res://scenes/ui/market_research_panel.tscn")

var current_overlay: Control = null

func _ready() -> void:
	# Only load starting stations the first time - if the player already owns
	# stations (returning from StationView), don't re-add duplicates.
	if GameState.owned_stations.is_empty():
		for path in station_paths:
			var station: Station = load(path)
			GameState.add_station(station)

	%EndWeekAll.pressed.connect(_on_end_week_all_pressed)
	%MarketResearchButton.pressed.connect(_on_market_research_pressed)
	%AcquisitionButton.pressed.connect(_on_acquisition_pressed)
	%NetworkAnalyticsButton.pressed.connect(_on_network_analytics_pressed)
	%HQButton.pressed.connect(_on_hq_pressed)
	%MenuButton.pressed.connect(_on_menu_pressed)

	_refresh_display()

func _on_end_week_all_pressed() -> void:
	WeeklyTick.run_weekly_tick()
	_refresh_display()

func _on_station_button_pressed(station: Station) -> void:
	GameState.select_station(station)
	get_tree().change_scene_to_file("res://scenes/station/station_view.tscn")

func _on_market_research_pressed() -> void:
	_open_overlay(MARKET_RESEARCH_PANEL.instantiate())

func _on_acquisition_pressed() -> void:
	print("Acquisition panel not built yet - Phase 1 item still outstanding.")

func _on_network_analytics_pressed() -> void:
	print("Network Analytics panel not built yet - Phase 1 item still outstanding.")

func _on_hq_pressed() -> void:
	print("HQ/Progression panel not built yet - Phase 2 item.")

func _on_menu_pressed() -> void:
	print("Save/Load/Settings menu not built yet. Quit works via the OS window controls for now.")

func _open_overlay(panel: Control) -> void:
	_close_overlay()

	panel.set_anchors_preset(Control.PRESET_CENTER)

	var close_button := Button.new()
	close_button.text = "X Close"
	close_button.pressed.connect(_close_overlay)

	var overlay_root := VBoxContainer.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(close_button)
	overlay_root.add_child(panel)

	%OverlayContainer.add_child(overlay_root)
	current_overlay = overlay_root

func _close_overlay() -> void:
	if current_overlay != null:
		current_overlay.queue_free()
		current_overlay = null

func _refresh_display() -> void:
	%CashLabel.text = "Cash: $" + str(GameState.cash)
	%ReputationLabel.text = "Reputation: %d" % int(GameState.network_reputation)
	%ListenersLabel.text = "Listeners: " + str(GameState.total_network_listeners())
	%WeekLabel.text = "Week: " + str(GameState.current_week)
	%NetworkHeader.text = GameState.network_name

	for child in %StationList.get_children():
		child.queue_free()

	for station in GameState.owned_stations:
		var button := Button.new()
		button.text = "%s | Listeners: %d | Hype: %d | Cash: $%d" % [
			station.station_name,
			station.listeners,
			int(station.hype),
			station.cash
		]
		button.pressed.connect(_on_station_button_pressed.bind(station))
		%StationList.add_child(button)
