extends Resource
class_name Daypart

## A single programming slot on a Station. As of this pass, every Daypart
## must hold a produced Show - bare Talent-only assignment is no longer valid.

enum Slot {
	MORNING,
	MIDDAY,
	AFTERNOON,
	NIGHT,
}

@export var slot: Slot = Slot.MORNING
@export var show: Show = null

func is_staffed() -> bool:
	return show != null

## Convenience accessor - WeeklyTick and UI code should read hosts through
## the Show rather than expecting Daypart to hold Talent directly.
func get_hosts() -> Array[Talent]:
	if show == null:
		return []
	return show.hosts

func get_quality() -> float:
	if show == null:
		return 0.0
	return show.quality

func get_prestige() -> float:
	if show == null:
		return 0.0
	return show.prestige

## Assigns a produced Show to this slot. Call Show.produce() before this,
## or pass an already-produced Show (e.g. a syndicated one from another station).
func assign_show(new_show: Show) -> void:
	show = new_show

func clear() -> void:
	show = null
