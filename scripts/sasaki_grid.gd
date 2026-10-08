extends CharacterBody2D

## Player controller: only reads input. Grid logic lives in GridManager,
## movement in the GridMover component, attacks in Attack child scenes.

@onready var mover: GridMover = $GridMover
@onready var basic_attack: Attack = $BasicAttack

var buffered_dir: Vector2i = Vector2i.ZERO
var buffered_attack := false

func _process(_delta: float) -> void:
	# save input inside helper variables
	if Input.is_action_just_pressed("ui_right"):
		buffered_dir = Vector2i(1, 0)
	elif Input.is_action_just_pressed("ui_left"):
		buffered_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_down"):
		buffered_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_up"):
		buffered_dir = Vector2i(0, -1)
	if Input.is_action_just_pressed("attack"):
		buffered_attack = true

	# act only when idle: not sliding to a cell and not inside an attack
	if mover.is_moving() or basic_attack.is_busy():
		return

	# attack has priority; the move pressed together with it is dropped
	if buffered_attack:
		basic_attack.execute()
		buffered_attack = false
		buffered_dir = Vector2i.ZERO
	# a refused move (wall or occupied cell) is discarded, as before.
	# The parent processes before its children, so GridMover starts
	# moving in this same frame.
	elif buffered_dir != Vector2i.ZERO:
		# turn even if the move is refused (wall, enemy): you can aim in place
		mover.facing = buffered_dir
		mover.try_move(buffered_dir)
		buffered_dir = Vector2i.ZERO
