class_name GridMover
extends Node

## Moves its parent (the "body") from cell to cell on a GridManager.
## Shared by the player and enemies: whoever owns it only decides *where*
## to go by calling try_move(); this component handles the rest.

## Emitted when a move starts (the destination is already reserved).
signal moved(from: Vector2i, to: Vector2i)
## Emitted when a move is refused. occupant is null if the cell is off-grid.
signal move_blocked(to: Vector2i, occupant: Node2D)

## If left empty, the body's parent is used (entities live under the grid).
@export var grid: GridManager
@export var start_cell: Vector2i = Vector2i(2, 2)
## Lerp speed: higher = snappier movement.
@export var move_speed: float = 15.0

@onready var body: Node2D = get_parent()

## Logical cell. Changes as soon as a move starts, not when the body arrives:
## during the slide the body visually lags behind its logical cell.
var cell: Vector2i
# Pixel position the body is sliding towards.
var _target: Vector2

func _ready() -> void:
	if grid == null:
		grid = body.get_parent() as GridManager
	assert(grid != null, "%s: GridMover needs a GridManager" % body.name)

	cell = start_cell
	if not grid.register(body, cell):
		push_error("%s: start cell %s is not free" % [body.name, cell])
	body.position = grid.cell_to_local(cell)
	_target = body.position
	# free the cell automatically when the body leaves the scene
	body.tree_exiting.connect(grid.unregister.bind(body))

func is_moving() -> bool:
	return body.position.distance_to(_target) >= 2.0

## Returns false if still moving or if the grid refuses the destination.
func try_move(dir: Vector2i) -> bool:
	if is_moving():
		return false
	var to := cell + dir
	if not grid.request_move(body, to):
		move_blocked.emit(to, grid.get_occupant(to))
		return false
	moved.emit(cell, to)
	cell = to
	_target = grid.cell_to_local(cell)
	return true

func _process(delta: float) -> void:
	if is_moving():
		body.position = body.position.lerp(_target, move_speed * delta)
	else:
		# snap once close enough, the lerp alone would never reach the target
		body.position = _target
