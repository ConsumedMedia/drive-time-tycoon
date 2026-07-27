extends Resource
class_name Show

## The produced content unit that fills a Daypart.
## Replaces bare Talent assignment - every Daypart now requires a Show.

enum ShowType {
	MUSIC_BLOCK,
	TALK_SHOW,
	NEWS_UPDATE,
	COUNTDOWN,
	CALL_IN,
	SYNDICATED_RERUN,
}

enum Tone {
	WHOLESOME,
	EDGY,
	SERIOUS,
	CHAOTIC,
	PRESTIGE,
}

@export var show_name: String = ""
@export var show_type: ShowType = ShowType.MUSIC_BLOCK
@export var tone: Tone = Tone.WHOLESOME
@export var hosts: Array[Talent] = []
@export var production_budget: int = 0

## 0-100, drives listeners_change in WeeklyTick
@export var quality: float = 0.0
## 0-100, contributes to network/station reputation over time
@export var prestige: float = 0.0

## How many stations currently air this Show via syndication (0 = exclusive/unsyndicated)
@export var syndicated_station_count: int = 0
@export var weeks_running: int = 0
@export var is_in_catalog: bool = false

## Recomputes quality from production_budget and host skill.
## Call this once at production time, not every week - quality is meant to be
## a snapshot of how well-made the Show is, not something that drifts on its own.
func produce(budget: int, assigned_hosts: Array[Talent]) -> void:
	production_budget = budget
	hosts = assigned_hosts

	var avg_talent_skill := 0.0
	if hosts.size() > 0:
		for t in hosts:
			avg_talent_skill += t.skill
		avg_talent_skill /= hosts.size()

	# Budget contributes up to 50 points (diminishing past a soft cap of 500),
	# talent skill contributes the other 50. Talent.skill is 1-10, so it's
	# rescaled to a 0-50 range here rather than assumed to already be 0-100.
	var budget_score: float = clamp(float(budget) / 10.0, 0.0, 50.0)
	var talent_score: float = clamp((avg_talent_skill / 10.0) * 50.0, 0.0, 50.0)

	quality = clamp(budget_score + talent_score, 0.0, 100.0)

## Called each WeeklyTick while the Show is airing.
## Prestige grows slowly with sustained quality, decays if quality drops
## (e.g. after a host is poached and the Show limps along under-cast).
func weekly_update() -> void:
	weeks_running += 1

	if quality >= 70.0:
		prestige = clamp(prestige + 1.0, 0.0, 100.0)
	elif quality < 40.0:
		prestige = clamp(prestige - 1.5, 0.0, 100.0)

## Retires the Show from active rotation into the back-catalog.
## Phase 2 hook: back-catalog monetization reads is_in_catalog.
func retire_to_catalog() -> void:
	is_in_catalog = true
