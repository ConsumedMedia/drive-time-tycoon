extends Control

## StationView - the drill-down from NetworkView. Shows one station's live
## stats and, eventually, its animated Daypart interior. Bottom bar opens
## overlay panels for station-level management.

const PROMOTION_COST: int = 500
const PROMOTION_HYPE_BOOST: float = 25.0

const HIRE_TALENT_PANEL := preload("res://scenes/ui/hire_talent_panel.tscn")

var station: Station
var current_overlay: Control = null

func _ready() -> void:
	# Same fix as NetworkOverview - this node's parent is a Node2D, not a
	# Control, so anchor-based resizing doesn't resolve reliably through
	# that gap. Set pixel size directly instead.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = get_viewport_rect().size

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

	%OverlayContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
	%OverlayContainer.position = Vector2.ZERO
	%OverlayContainer.size = size
	%OverlayContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	var panel := HIRE_TALENT_PANEL.instantiate()
	panel.target_station = station
	_open_overlay(panel)

func _on_produce_show_pressed() -> void:
	print("Produce Show panel not built yet - Phase 1 item still outstanding.")

func _on_sponsors_pressed() -> void:
	print("Sponsors panel is an empty shell - sponsor_panel.tscn has no content yet.")

func _on_station_analytics_pressed() -> void:
	print("Station Analytics panel not built yet.")

func _open_overlay(panel: Control) -> void:
	_close_overlay()

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	var content_panel := PanelContainer.new()
	content_panel.set_anchors_preset(Control.PRESET_CENTER)
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

func _close_overlay() -> void:
	if current_overlay != null:
		current_overlay.queue_free()
		current_overlay = null
	_refresh_labels()

func _refresh_labels() -> void:
	if station == null:
		%StationName.text = "No station selected"
		return

	%StationName.text = station.station_name
	%Listeners.text = "Listeners: " + str(station.listeners)
	%Hype.text = "Hype: " + str(int(station.hype))
	%Loyalty.text = "Loyalty: " + str(int(station.loyalty))
	%Cash.text = "Cash: $" + str(station.cash)
