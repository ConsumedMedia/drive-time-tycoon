extends Control

## Lets the player pick a city and (optionally) an analyst, run research,
## and see the noisy/accurate revealed format_fit results.

@export var city_paths: Array[String] = [
	"res://data/cities/chill_coastal_village.tres",
	"res://data/cities/college_town.tres",
]

var cities: Array[City] = []

func _ready() -> void:
	for path in city_paths:
		cities.append(load(path))

	%CityOption.clear()
	for city in cities:
		%CityOption.add_item(city.city_name)

	_refresh_analyst_options()

	%RunResearchButton.pressed.connect(_on_run_research_pressed)

func _refresh_analyst_options() -> void:
	%AnalystOption.clear()
	%AnalystOption.add_item("None (base accuracy)")
	for analyst in GameState.analyst_pool:
		%AnalystOption.add_item(analyst.analyst_name)

func _on_run_research_pressed() -> void:
	if cities.is_empty():
		return

	var city: City = cities[%CityOption.selected]

	var analyst: Analyst = null
	var analyst_index: int = %AnalystOption.selected
	if analyst_index > 0:
		analyst = GameState.analyst_pool[analyst_index - 1]

	var research: MarketResearch = MarketResearchService.run_research(
		city, analyst, GameState.current_week
	)
	GameState.store_research(research)
	_display_research(research)

func _display_research(research: MarketResearch) -> void:
	var lines: Array[String] = []
	lines.append("Accuracy: %d%%" % int(research.research_accuracy))
	lines.append("")

	for format_name in research.revealed_format_fit.keys():
		var value: float = research.revealed_format_fit[format_name]
		lines.append("%s: %.2f" % [format_name, value])

	%ResultLabel.text = "\n".join(lines)
