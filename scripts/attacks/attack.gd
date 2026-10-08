class_name Attack
extends Node

## One attack type of a character (sword, buster, claw...).
## Its scene is added as a child of the character and holds everything that
## depends on the attack, not on who uses it: timings, target cells, hit scene.
## The character only calls execute(); the actual hit is the hit_scene,
## spawned on the grid so it doesn't follow the attacker around.
##
##   execute() -> windup -> spawn hits -> recovery -> done

## Emitted when the attack begins: hook the character's animation here.
signal started
## Emitted right after the hits are spawned.
signal struck
signal finished

## What appears on each target cell (an inherited scene of cell_attack.tscn).
@export var hit_scene: PackedScene
## Target cells relative to the attacker, written as if facing right:
## x = forward, y = sideways. (1, 0) = cell in front.
## Rotated automatically towards the attacker's facing.
@export var pattern: Array[Vector2i] = [Vector2i(1, 0)]
## Seconds between the input and the hit.
@export var windup_time: float = 0.1
## Seconds after the hit before the character can act again.
@export var recovery_time: float = 0.2
## If left empty, the sibling node named "GridMover" is used.
@export var mover: GridMover

var _busy := false
# A child Timer instead of create_timer(): if the character is freed
# mid-attack, the timer dies with it and the coroutine is simply dropped.
var _timer: Timer

func _ready() -> void:
	if mover == null:
		mover = get_parent().get_node_or_null("GridMover")
	assert(mover != null, "%s: Attack needs a GridMover" % name)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)

## True from the start of the windup to the end of the recovery.
func is_busy() -> bool:
	return _busy

## Starts the attack and returns immediately; false if it's already running.
func execute() -> bool:
	if _busy:
		return false
	_busy = true
	_run()
	return true

# The timed sequence, running in the background (coroutine).
func _run() -> void:
	started.emit()
	await _wait(windup_time)
	# cells are read *now*, after the windup, from the logical cell
	for offset in pattern:
		mover.grid.spawn_attack(hit_scene, mover.cell + _rotate(offset, mover.facing))
	struck.emit()

	await _wait(recovery_time)
	_busy = false
	finished.emit()

# Rotates a right-facing offset towards dir (a 90-degree step rotation).
# Facing left is a 180 turn, so sideways cells flip too: (1, 1) -> (-1, -1).
func _rotate(offset: Vector2i, dir: Vector2i) -> Vector2i:
	return Vector2i(offset.x * dir.x - offset.y * dir.y, offset.x * dir.y + offset.y * dir.x)

func _wait(time: float) -> void:
	if time > 0.0:
		_timer.start(time)
		await _timer.timeout
