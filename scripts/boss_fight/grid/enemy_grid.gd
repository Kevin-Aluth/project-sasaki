extends Node2D

## Grid enemy, first embryo: it stands still and, every attack_interval
## seconds, attacks the cell Sasaki is on (the hit scene's telegraph gives her
## time to dodge), the same way damage_test does.
## The components do the rest, as for Sasaki: HealthComponent + Hurtbox (hit by
## her attacks), GridMover (it occupies its cell), CharacterAnimator.

## Who to attack: Sasaki's grid scene (it must have a GridMover).
@export var target: Node2D
## What appears on the target cell: enemy_basic_hit.tscn or another
## inherited scene of cell_attack.tscn on the enemy_hitbox layer.
@export var attack_scene: PackedScene
## Seconds between two attacks with a NORMAL ego.
@export var attack_interval: float = 1.5

@export_group("Ego")
## How much faster it attacks for each ego level of the boss (from the dating
## sim): the real interval is attack_interval / speed. 1 = unchanged.
@export var speed_low: float = 0.7
@export var speed_normal: float = 1.0
@export var speed_high: float = 1.3
@export var speed_very_high: float = 1.8

@onready var mover: GridMover = $GridMover
@onready var animator: CharacterAnimator = $CharacterAnimator
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox

var _timer: Timer

func _ready() -> void:
	assert(target != null and attack_scene != null, "%s: needs a target and an attack_scene" % name)
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)

	_timer = Timer.new()
	_timer.wait_time = attack_interval
	_timer.timeout.connect(_attack)
	add_child(_timer)
	_timer.start()

## Sets the attack speed for the boss's ego. Called by the grid phase: the
## enemy only gets the ego level, not the rest of BattleState.
func apply_ego(ego: BattleState.EgoStrength) -> void:
	var speed: float = [speed_low, speed_normal, speed_high, speed_very_high][ego]
	_timer.wait_time = attack_interval / speed
	# a running timer only picks up a new wait_time on its next cycle: restart it
	if not _timer.is_stopped():
		_timer.start()
	print("Enemy: ego %s -> attacks every %.2f s" % [BattleState.EgoStrength.keys()[ego], _timer.wait_time])

## Stops attacking (e.g. the grid phase is over).
func stop() -> void:
	_timer.stop()

func _attack() -> void:
	var target_mover: GridMover = target.get_node("GridMover")
	animator.play_action(&"attack")
	mover.grid.spawn_attack(attack_scene, target_mover.cell)

func _on_hurt(_hitbox: HitboxComponent) -> void:
	# the hit that kills him plays "death" instead (see _on_died)
	if health.current_health > 0:
		animator.play_action(&"damaged")

func _on_died() -> void:
	_timer.stop()
	# the hurtbox stays on: HealthComponent already ignores damage at 0 HP
	animator.play_action(&"death")
	# once "death" is over, stop the animator: otherwise it would go back to idle
	animator.action_finished.connect(func(_base: StringName) -> void: animator.set_process(false), CONNECT_ONE_SHOT)
