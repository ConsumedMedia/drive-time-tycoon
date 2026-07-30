extends Node

## Call this to run/refresh research on a city using a given analyst
func run_research(city: City, analyst: Analyst, current_week: int) -> MarketResearch:
	var research := MarketResearch.new()
	research.city = city
	research.last_researched_week = current_week

	var base_accuracy: float = 40.0  # accuracy with no analyst at all
	if analyst != null:
		base_accuracy = 40.0 + (analyst.skill * 5.0) + (analyst.experience * 0.2)
	base_accuracy += GameState.hq_research_accuracy_bonus()
	research.research_accuracy = min(100.0, base_accuracy)

	var noise_range: float = 1.0 - (research.research_accuracy / 100.0)  # 0.0 = perfect, 1.0 = wildly noisy

	var revealed: Dictionary = {}
	for format_name in city.format_fit.keys():
		var true_value: float = city.format_fit[format_name]
		var noise: float = randf_range(-noise_range, noise_range)
		revealed[format_name] = max(0.0, true_value + noise)

	research.revealed_format_fit = revealed
	return research
