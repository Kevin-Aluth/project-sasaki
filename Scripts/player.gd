extends CharacterBody2D

@export var speed := 200.0
@export var character_name := "Sasaki"
@export var portrait: Texture2D

var can_move := true

func _ready() -> void:
	add_to_group("player")
	DialogueManager.dialog_started.connect(_on_dialog_started)
	DialogueManager.dialog_finished.connect(_on_dialog_finished)

func _on_dialog_started() -> void:
	can_move = false

func _on_dialog_finished() -> void:
	can_move = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	
	if can_move:
		var direction := Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * speed
	else:
		velocity.x = 0.0
	move_and_slide()
	
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0
