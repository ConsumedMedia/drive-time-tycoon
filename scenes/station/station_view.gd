extends Control

## StationView - the drill-down from NetworkView. Shows one station's live
## stats and its animated Daypart interior. Bottom bar opens overlay panels
## for station-level management.

const PROMOTION_COST: int = 500
const PROMOTION_HYPE_BOOST: float = 25.0

const HIRE_TALENT_PANEL := preload("res://scenes/ui/hire_talent_panel.tscn")
const PRODUCE_SHOW_PANEL := preload("res://scenes/ui/produce_show_panel.tscn")
const SPONSOR_PANEL := preload("res://scenes/ui/sponsor_panel.tscn")
const STATION_ANALYTICS_PANEL := preload("res://scenes/ui/station_analytics_panel.tscn")
const CHARACTER_SPRITE := preload("res://scenes/characters/character_sprite.tscn")

const DEFAULT_ROOM_BACKGROUND := "res://art/station_room/station_room_bg.png"
const CITY_ROOM_BACKGROUNDS := {
	"Chill Coastal Village": "res://art/station_room/station_room_bg_chill_coastal_village.png",
	"College Town": "res://art/station_room/station_room_bg_college_town.png",
	"Retiree Coast": "res://art/station_room/station_room_bg_retiree_coast.png",
}

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

	_refresh_room_background()
	_refresh_display()

func _refresh_room_background() -> void:
	if station == null or station.city == null:
		return
	var bg_path: String = CITY_ROOM_BACKGROUNDS.get(station.city.city_name, DEFAULT_ROOM_BACKGROUND)
	%Room.texture = load(bg_path)

func _on_end_week_pressed() -> void:
	WeeklyTick.run_weekly_tick()
	_refresh_display()

func _on_run_promotion_pressed() -> void:
	if station.cash >= PROMOTION_COST:
		station.cash -= PROMOTION_COST
		station.hype = min(100.0, station.hype + PROMOTION_HYPE_BOOST)
	_refresh_display()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_hire_talent_pressed() -> void:
	var panel := HIRE_TALENT_PANEL.instantiate()
	panel.target_station = station
	_open_overlay(panel)

func _on_produce_show_pressed() -> void:
	var panel := PRODUCE_SHOW_PANEL.instantiate()
	panel.target_station = station
	_open_overlay(panel)

func _on_sponsors_pressed() -> void:
	var panel := SPONSOR_PANEL.instantiate()
	panel.target_station = station
	_open_overlay(panel)

func _on_station_analytics_pressed() -> void:
	var panel := STATION_ANALYTICS_PANEL.instantiate()
	panel.target_station = station
	_open_overlay(panel)

func _open_overlay(panel: Control) -> void:
	_close_overlay()

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

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
	if station == null:
		%StationName.text = "No station selected"
		return

	%StationName.text = station.station_name
	%StationNameIcon.hint_text = "%s | %s format | %s" % [
		station.city.city_name,
		station.format.format_name,
		station.city.vibe_description
	]
	%Listeners.text = str(station.listeners)
	%Hype.text = str(int(station.hype))
	%Loyalty.text = str(int(station.loyalty))
	%Cash.text = "$" + str(station.cash)

	_refresh_desks()

## Updates each of the 4 desk positions to show (or clear) the correct
## host's sprite, based on whether that Daypart is actually staffed.
## Matches by Daypart.slot value rather than array order, since dayparts
## aren't guaranteed to be populated in a fixed order.
func _refresh_desks() -> void:
	for i in range(4):
		var desk: Node2D = %DeskArea.get_child(i)
		var daypart: Daypart = _find_daypart_for_slot(i)
		_refresh_desk_character(desk, daypart)

func _find_daypart_for_slot(slot: int) -> Daypart:
	for daypart in station.dayparts:
		if daypart.slot == slot:
			return daypart
	return null

func _refresh_desk_character(desk: Node2D, daypart: Daypart) -> void:
	var anchor: Marker2D = desk.get_node("CharacterAnchor")
	var existing := anchor.get_node_or_null("HostCharacter")
	if existing:
		existing.free()

	if daypart != null and daypart.is_staffed() and not daypart.show.hosts.is_empty():
		var host: Talent = daypart.show.hosts[0]
		var char_instance := CHARACTER_SPRITE.instantiate()
		char_instance.name = "HostCharacter"
		anchor.add_child(char_instance)
		char_instance.configure(
			host.sprite_path,
			host.blink_overlay_left_offset,
			host.blink_overlay_right_offset,
			host.blink_overlay_color
		)
