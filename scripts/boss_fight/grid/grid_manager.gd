class_name GridManager
extends Node2D

## Single source of truth for the battle grid: size, cell <-> pixel
## conversion and which entity occupies which cell.
## It never moves anything: entities ask it for permission (see GridMover).
##
## Entities and attacks must be children of this node, so that
## cell_to_local() gives them their position directly.

@export var cell_size: int = 100
## Number of cells (columns, rows). Valid cells go from (0, 0) to size - 1.
@export var size: Vector2i = Vector2i(8, 6)
@export var line_color: Color = Color(1, 1, 1, 0.25)

# Cell -> entity. The reverse lookup (entity -> cell) uses find_key():
# it scans the map, which is negligible on a grid this small.
var _occupants: Dictionary[Vector2i, Node2D] = {}

## Center of the cell, in this node's local space.
func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size

func is_inside(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)

## A cell is free if it is on the grid and nobody occupies or has reserved it.
func is_free(cell: Vector2i) -> bool:
	return is_inside(cell) and not _occupants.has(cell)

## Returns null if the cell is empty.
func get_occupant(cell: Vector2i) -> Node2D:
	return _occupants.get(cell)

## Places an entity on the grid for the first time.
func register(entity: Node2D, cell: Vector2i) -> bool:
	# an entity can only occupy one cell
	if not is_free(cell) or _occupants.find_key(entity) != null:
		return false
	_occupants[cell] = entity
	return true

## Frees the entity's cell (e.g. when it dies or leaves the scene).
func unregister(entity: Node2D) -> void:
	var cell = _occupants.find_key(entity)
	if cell != null:
		_occupants.erase(cell)

## Checks and reserves the destination in a single step.
## The reservation happens when the move *starts*, so two entities heading
## to the same cell can't both succeed: the first one to ask wins.
func request_move(entity: Node2D, to: Vector2i) -> bool:
	# find_key() returns null if the entity was never registered
	var from = _occupants.find_key(entity)
	if from == null or not is_free(to):
		return false
	_occupants.erase(from)
	_occupants[to] = entity
	return true

## Spawns an attack scene (usually a CellAttack) centered on a cell.
## Everything specific to the attack (damage, layer, timings) lives in the
## scene itself. Returns null if the cell is off-grid.
func spawn_attack(scene: PackedScene, cell: Vector2i) -> Node2D:
	if not is_inside(cell):
		return null
	var attack: Node2D = scene.instantiate()
	if attack is CellAttack:
		attack.cell_size = cell_size
	attack.position = cell_to_local(cell)
	add_child(attack)
	return attack

func _draw() -> void:
	var half := Vector2.ONE * cell_size * 0.5
	for x in size.x:
		for y in size.y:
			var center := cell_to_local(Vector2i(x, y))
			draw_rect(Rect2(center - half, half * 2.0), line_color, false, 1.0)
