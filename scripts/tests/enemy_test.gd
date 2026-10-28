extends Node2D

## Test scene for the grid enemy: Sasaki and the enemy on the same grid.
## The enemy attacks her cell at a fixed interval; she can dodge and hit back.
## Logs both health bars and deaths.

@onready var _player_health: HealthComponent = $GridManager/Player/HealthComponent
@onready var _enemy_health: HealthComponent = $GridManager/Enemy/HealthComponent

func _ready() -> void:
	_player_health.health_changed.connect(func(current: int, max_value: int) -> void:
		print("Sasaki HP: %d/%d" % [current, max_value]))
	_player_health.died.connect(func() -> void: print("Sasaki died"))
	_enemy_health.health_changed.connect(func(current: int, max_value: int) -> void:
		print("Enemy HP: %d/%d" % [current, max_value]))
	_enemy_health.died.connect(func() -> void: print("Enemy died"))
