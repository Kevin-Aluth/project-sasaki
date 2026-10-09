class_name HealthComponent
extends Node

## Stores health points. Knows nothing about hitboxes or hurtboxes.

@export var max_health: int = 100

signal health_changed(current: int, max_value: int)
signal died

var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
