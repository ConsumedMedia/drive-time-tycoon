extends Resource
class_name Analyst

## Display name
@export var analyst_name: String = "New Analyst"

## Research skill — drives how accurate their community analysis is
@export_range(1, 10) var skill: int = 5

## Weekly salary
@export var salary: int = 0

## Grows slowly over time on the job — a way to "train" an analyst without replacing them
@export_range(0, 100) var experience: float = 0.0
