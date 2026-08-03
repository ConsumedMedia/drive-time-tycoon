extends Control

## Lets the player hire a Talent from GameState.talent_pool onto the
## currently viewed station's roster. StationView sets target_station
## right after instantiating this panel.

var target_station: Station = null

## Candidates matching the currently selected trait filter, in the same
## order as they appear in %CandidateOption - kept in sync so selecting
## an index in the dropdown maps to the right entry in this list, not
## the full unfiltered talent_pool.
var filtered_candidates: Array[Talent] = []

const TRAIT_NAMES := ["Old Reliable", "Rising Star", "Loose Cannon", "Fan Favorite", "Smooth Operator"]

func _ready() -> void:
	%TraitFilterOption.clear()
	for trait_name in TRAIT_NAMES:
		%TraitFilterOption.add_item(trait_name)
	%TraitFilterOption.item_selected.connect(_on_trait_filter_selected)

	%HireButton.pressed.connect(_on_hire_pressed)
	_refresh_candidates()

func _on_trait_filter_selected(_index: int) -> void:
	_refresh_candidates()

func _refresh_candidates() -> void:
	%CandidateOption.clear()
	filtered_candidates.clear()

	var selected_trait: String = TRAIT_NAMES[%TraitFilterOption.selected]

	for talent in GameState.talent_pool:
		if talent.personality_trait == selected_trait:
			filtered_candidates.append(talent)

	if filtered_candidates.is_empty():
		%CandidateOption.add_item("No %s candidates available" % selected_trait)
		%HireButton.disabled = true
		return

	%HireButton.disabled = false
	for talent in filtered_candidates:
		%CandidateOption.add_item(
			"%s | Skill: %d | $%d/wk" % [
				talent.talent_name,
				talent.skill,
				talent.salary
			]
		)

func _on_hire_pressed() -> void:
	if filtered_candidates.is_empty() or target_station == null:
		return

	var talent: Talent = filtered_candidates[%CandidateOption.selected]

	GameState.talent_pool.erase(talent)
	target_station.roster.append(talent)

	%ResultLabel.text = "Hired %s! They're now on %s's roster." % [
		talent.talent_name,
		target_station.station_name
	]
	_refresh_candidates()
