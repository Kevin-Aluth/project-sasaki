extends CharacterBody2D

func _physics_process(delta: float) -> void:
	var x_input = Input.get_axis("ui_left", "ui_right")
	
	if not is_on_floor():
		velocity.y += 200 * delta
	
	velocity.x = x_input * 120
	move_and_slide()
