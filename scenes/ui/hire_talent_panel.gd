extends Control

## Lets the player hire a Talent from GameState.talent_pool onto the
## currently viewed station's roster. StationView sets target_station
## right after instantiating this panel.

var target_station: Station = null

func _ready() -> void:
	%HireButton.pressed.connect(_on_hire_pressed)
	_refresh_candidates()

func _refresh_candidates() -> void:
	%CandidateOption.clear()

	if GameState.talent_pool.is_empty():
		%CandidateOption.add_item("No candidates available")
		%HireButton.disabled = true
		return

	%HireButton.disabled = false
	for talent in GameState.talent_pool:
		%CandidateOption.add_item(
			"%s | %s | Skill: %d | $%d/wk" % [
				talent.talent_name,
				talent.personality_trait,
				talent.skill,
				talent.salary
			]
		)

func _on_hire_pressed() -> void:
	if GameState.talent_pool.is_empty() or target_station == null:
		return

	var index: int = %CandidateOption.selected
	var talent: Talent = GameState.talent_pool[index]

	GameState.talent_pool.remove_at(index)
	target_station.roster.append(talent)

	%ResultLabel.text = "Hired %s! They're now on %s's roster." % [
		talent.talent_name,
		target_station.station_name
	]
	_refresh_candidates()
