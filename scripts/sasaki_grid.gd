extends CharacterBody2D

@export var cell_size: int = 64        
@export var grid_max_x: int = 7       
@export var grid_max_y: int = 5       
@export var move_speed: float = 15.0   

@export var grid_position: Vector2i = Vector2i(2, 2)

var target_pixel_pos: Vector2
var buffered_dir: Vector2i = Vector2.ZERO

func _ready() -> void:
	position = Vector2(grid_position) * cell_size
	target_pixel_pos = position

func _process(delta: float) -> void:
	# save input inside a helper variable
	if Input.is_action_just_pressed("ui_right"):
		buffered_dir = Vector2i(1, 0)
	elif Input.is_action_just_pressed("ui_left"):
		buffered_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_down"):
		buffered_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_up"):
		buffered_dir = Vector2i(0, -1)

	# when current position coincides with target position
	if position.distance_to(target_pixel_pos) < 2.0:
		position = target_pixel_pos
		
		# check for input presses
		if buffered_dir != Vector2i.ZERO:
			# upgrade grid position and physical target position
			var next_grid_pos = grid_position + buffered_dir
			
			if next_grid_pos.x >= 0 and next_grid_pos.x <= grid_max_x and \
			   next_grid_pos.y >= 0 and next_grid_pos.y <= grid_max_y:
				grid_position = next_grid_pos
				target_pixel_pos = Vector2(grid_position) * cell_size
			
			# empty the helper variable
			buffered_dir = Vector2i.ZERO

	# move towards target linearly
	position = position.lerp(target_pixel_pos, move_speed * delta)
