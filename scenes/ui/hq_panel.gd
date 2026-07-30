extends Control

## Shows current HQ tier and its bonuses, and lets the player spend network
## Cash to advance to the next tier, up to GameState.MAX_HQ_TIER.

func _ready() -> void:
	%UpgradeButton.pressed.connect(_on_upgrade_pressed)
	_refresh()

func _refresh() -> void:
	var lines: Array[String] = []

	lines.append("HQ Tier: %d / %d" % [GameState.hq_tier, GameState.MAX_HQ_TIER])
	lines.append("")
	lines.append("Current bonuses:")
	lines.append("- Acquisition cost: -%d%%" % int((1.0 - GameState.acquisition_discount_multiplier()) * 100))
	lines.append("- Weekly salaries: -%d%%" % int((1.0 - GameState.salary_discount_multiplier()) * 100))
	lines.append("- Market Research base accuracy: +%d" % int(GameState.hq_research_accuracy_bonus()))

	if GameState.hq_tier >= GameState.MAX_HQ_TIER:
		lines.append("")
		lines.append("HQ is fully upgraded.")
		%UpgradeButton.disabled = true
	else:
		var cost: int = GameState.hq_upgrade_cost()
		lines.append("")
		lines.append("Next tier costs $%d." % cost)
		%UpgradeButton.text = "Upgrade to Tier %d ($%d)" % [GameState.hq_tier + 1, cost]
		%UpgradeButton.disabled = GameState.cash < cost

	%HQLabel.text = "\n".join(lines)

func _on_upgrade_pressed() -> void:
	var cost: int = GameState.hq_upgrade_cost()

	if GameState.cash < cost or GameState.hq_tier >= GameState.MAX_HQ_TIER:
		return

	GameState.cash -= cost
	GameState.hq_tier += 1

	%ResultLabel.text = "Upgraded to HQ Tier %d!" % GameState.hq_tier

	_refresh()
