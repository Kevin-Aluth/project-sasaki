extends CharacterBody2D

## Player controller: only reads input. Grid logic lives in GridManager,
## movement in the GridMover component.

@onready var mover: GridMover = $GridMover

var buffered_dir: Vector2i = Vector2i.ZERO

func _process(_delta: float) -> void:
	# save input inside a helper variable
	if Input.is_action_just_pressed("ui_right"):
		buffered_dir = Vector2i(1, 0)
	elif Input.is_action_just_pressed("ui_left"):
		buffered_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_down"):
		buffered_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_up"):
		buffered_dir = Vector2i(0, -1)

	# consume the buffer once the previous move is over; a refused move
	# (wall or occupied cell) is discarded, as before.
	# The parent processes before its children, so GridMover starts
	# moving in this same frame.
	if buffered_dir != Vector2i.ZERO and not mover.is_moving():
		mover.try_move(buffered_dir)
		buffered_dir = Vector2i.ZERO
