extends Node2D

## Test scene for damage reception and grid occupancy: spawns CellAttacks
## at a fixed interval and logs health and blocked moves.

const CELL_ATTACK := preload("res://scenes/attacks/cell_attack.tscn")

## Seconds between two spawned attacks.
@export var spawn_interval: float = 1.2
## If true, attacks target the player's cell (test dodging);
## otherwise a random cell (test walking into them).
@export var aim_at_player: bool = true

@onready var grid: GridManager = $GridManager
@onready var _mover: GridMover = $GridManager/Player/GridMover
@onready var _health: HealthComponent = $GridManager/Player/HealthComponent
@onready var _hurtbox: HurtboxComponent = $GridManager/Player/Hurtbox
@onready var _sprite: Sprite2D = $GridManager/Player/Sprite2D

func _ready() -> void:
	_health.health_changed.connect(func(current: int, max_value: int) -> void:
		print("HP: %d/%d" % [current, max_value]))
	_health.died.connect(func() -> void: print("Player died"))
	_hurtbox.hurt.connect(func(hitbox: HitboxComponent) -> void:
		print("Hit for %d damage" % hitbox.damage))
	_mover.move_blocked.connect(func(to: Vector2i, occupant: Node2D) -> void:
		print("Move to %s blocked by %s" % [to, occupant.name if occupant else "grid edge"]))
	# dim the sprite while invincible
	_hurtbox.invincibility_started.connect(func() -> void: _sprite.modulate.a = 0.4)
	_hurtbox.invincibility_ended.connect(func() -> void: _sprite.modulate.a = 1.0)

	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.timeout.connect(_spawn_attack)
	add_child(timer)
	timer.start()

func _spawn_attack() -> void:
	var cell := _mover.cell
	if not aim_at_player:
		cell = Vector2i(randi_range(0, grid.size.x - 1), randi_range(0, grid.size.y - 1))
	var attack: CellAttack = CELL_ATTACK.instantiate()
	attack.cell_size = grid.cell_size
	attack.position = grid.cell_to_local(cell)
	# attacks live under the grid too, so cell_to_local() is their position
	grid.add_child(attack)
