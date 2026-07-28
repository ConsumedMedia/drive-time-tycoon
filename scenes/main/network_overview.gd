extends Control

## The Network View — the player's home base. Shows every owned station
## as a clickable entry; clicking one drills into that Station's StationView.
## Bottom bar opens overlay panels for network-level management.

@export var station_paths: Array[String] = [
	"res://data/stations/chill_coastal_station.tres",
	"res://data/stations/college_town_station.tres"
]

## Fill this in the Inspector with paths to any candidate Talent .tres files
## you want available to hire at game start.
@export var candidate_talent_paths: Array[String] = []

const MARKET_RESEARCH_PANEL := preload("res://scenes/ui/market_research_panel.tscn")

var current_overlay: Control = null

func _ready() -> void:
	# NetworkOverview itself was never anchored to fill the window (still at
	# its default 40x40 declared size) - everything looked fine until now
	# because Godot doesn't clip overflowing children, but any FULL_RECT
	# anchor set on a child is relative to THIS node's real size. Fix it here.
	# Setting size directly rather than relying only on anchors, since this
	# node's parent (Main) is a Node2D, not a Control, and anchor-based
	# resizing wasn't resolving correctly through that gap.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = get_viewport_rect().size

	# Only load starting stations the first time - if the player already owns
	# stations (returning from StationView), don't re-add duplicates.
	if GameState.owned_stations.is_empty():
		for path in station_paths:
			var station: Station = load(path)
			GameState.add_station(station)

	if GameState.talent_pool.is_empty():
		for path in candidate_talent_paths:
			GameState.talent_pool.append(load(path))

	%EndWeekAll.pressed.connect(_on_end_week_all_pressed)
	%MarketResearchButton.pressed.connect(_on_market_research_pressed)
	%AcquisitionButton.pressed.connect(_on_acquisition_pressed)
	%NetworkAnalyticsButton.pressed.connect(_on_network_analytics_pressed)
	%HQButton.pressed.connect(_on_hq_pressed)
	%MenuButton.pressed.connect(_on_menu_pressed)

	# Force this to fill the screen from code, rather than depending on an
	# editor anchor setting being correct. Ignore mouse input when empty so
	# it doesn't block clicks to the station buttons underneath it.
	%OverlayContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
	%OverlayContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	# Dim backdrop covers the whole screen, blocks clicks to what's behind it,
	# and visually separates the overlay from the Network View underneath -
	# this is what was missing before (Control has no background by default).
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	# PanelContainer has a solid background by default (unlike a bare Control
	# or VBoxContainer), so the actual content reads clearly against the dim.
	var content_panel := PanelContainer.new()
	content_panel.set_anchors_preset(Control.PRESET_CENTER)

	var content_box := VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 8)

	var close_button := Button.new()
	close_button.text = "X Close"
	close_button.custom_minimum_size = Vector2(0, 36)
	close_button.pressed.connect(_close_overlay)
	content_box.add_child(close_button)
	content_box.add_child(panel)

	content_panel.add_child(content_box)
	backdrop.add_child(content_panel)

	%OverlayContainer.add_child(backdrop)
	current_overlay = backdrop

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
