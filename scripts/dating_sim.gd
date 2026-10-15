extends Node2D

@onready var label = $Label
@onready var enemy_sprite_origin = $EnemySpriteOrigin

@export var enemy: EnemyResource = null



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enemy:
		var instance = enemy.enemy_dating_sim_closeup_scene.instantiate()
		instance.area_clicked.connect(_on_area_clicked)
		add_child(instance)
		var enemy_sprite = Sprite2D.new()
		enemy_sprite.texture = enemy.full_enemy_sprite
		enemy_sprite.scale = Vector2(0.4, 0.4)
		enemy_sprite_origin.add_child(enemy_sprite)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Control.position = get_viewport().get_mouse_position()

func _on_area_clicked(dialogue: String) -> void:
	#Show the text line linked to the area clicked
	label.text = dialogue
