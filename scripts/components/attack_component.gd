class_name AttackComponent
extends Node

## Runs the attacks of a character, one at a time.
## The sequence is driven by the attack animation, not by timers:
##
##   execute(slot) -> animator plays "attack_<dir>"
##     -> method track calls strike()   : hits spawn on the grid
##     -> animation ends                : busy is released

signal started(attack: AttackData)
signal struck(attack: AttackData)
signal finished(attack: AttackData)

## Attacks by slot name, e.g. &"basic" -> basic.tres.
@export var attacks: Dictionary[StringName, AttackData] = {}
## If left empty, sibling nodes with the default names are used.
@export var mover: GridMover
@export var animator: CharacterAnimator

# Attack currently running; null when idle.
var _current: AttackData

func _ready() -> void:
	var parent := get_parent()
	if mover == null:
		mover = parent.get_node_or_null("GridMover")
	if animator == null:
		animator = parent.get_node_or_null("CharacterAnimator")
	assert(mover != null and animator != null, "%s: AttackComponent needs a GridMover and a CharacterAnimator" % parent.name)
	animator.action_finished.connect(_on_action_finished)

## True from the start of the attack animation to its end.
func is_busy() -> bool:
	return _current != null

## Returns false if already attacking or if the slot is empty.
func execute(slot: StringName) -> bool:
	if is_busy() or not attacks.has(slot):
		return false
	_current = attacks[slot]
	started.emit(_current)
	animator.play_action(_current.animation)
	return true

## Called by the attack animation (method track) on the hit frame.
## Cells are read now, from the logical cell and the current facing.
func strike() -> void:
	if _current == null:
		return
	for offset in _current.pattern:
		mover.grid.spawn_attack(_current.hit_scene, mover.cell + _rotate(offset, mover.facing))
	struck.emit(_current)

## Interrupts the attack: if the hit frame wasn't reached, nothing spawns.
func cancel() -> void:
	if _current != null:
		_current = null
		animator.stop_action()

func _on_action_finished(base: StringName) -> void:
	if _current != null and base == _current.animation:
		var attack := _current
		_current = null
		finished.emit(attack)

# Rotates a right-facing offset towards dir (a 90-degree step rotation).
# Facing left is a 180 turn, so sideways cells flip too: (1, 1) -> (-1, -1).
func _rotate(offset: Vector2i, dir: Vector2i) -> Vector2i:
	return Vector2i(offset.x * dir.x - offset.y * dir.y, offset.x * dir.y + offset.y * dir.x)
