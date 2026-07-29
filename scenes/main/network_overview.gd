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

## Fill this in the Inspector with paths to any candidate Sponsor .tres files
## you want available to court at game start.
@export var candidate_sponsor_paths: Array[String] = [
	"res://data/sponsors/big_daves_tires.tres"
]

const MARKET_RESEARCH_PANEL := preload("res://scenes/ui/market_research_panel.tscn")
const NETWORK_ANALYTICS_PANEL := preload("res://scenes/ui/network_analytics_panel.tscn")
const ACQUISITION_PANEL := preload("res://scenes/ui/acquisition_panel.tscn")

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

	if GameState.sponsor_pool.is_empty():
		for path in candidate_sponsor_paths:
			GameState.sponsor_pool.append(load(path))

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
	_open_overlay(ACQUISITION_PANEL.instantiate())

func _on_network_analytics_pressed() -> void:
	_open_overlay(NETWORK_ANALYTICS_PANEL.instantiate())

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
	content_panel.add_child(panel)

	# Anchors have been unreliable all session for one-off positioning like
	# this, so just compute the exact pixel position directly instead.
	var close_button := Button.new()
	close_button.text = "X Close"
	close_button.size = Vector2(100, 36)
	close_button.position = Vector2(get_viewport_rect().size.x - 120, 20)
	close_button.pressed.connect(_close_overlay)

	backdrop.add_child(content_panel)
	backdrop.add_child(close_button)

	%OverlayContainer.add_child(backdrop)
	current_overlay = backdrop

	# Center content_panel only after its real size is known (next idle frame) -
	# calculating this immediately used a stale zero size and made it grow
	# toward the bottom-right instead of staying centered.
	call_deferred("_center_content_panel", content_panel)

func _center_content_panel(content_panel: Control) -> void:
	var viewport_size := get_viewport_rect().size
	content_panel.position = (viewport_size - content_panel.size) / 2.0

func _close_overlay() -> void:
	if current_overlay != null:
		current_overlay.queue_free()
		current_overlay = null
	_refresh_display()

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
