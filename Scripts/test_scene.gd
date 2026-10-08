extends Control

@export var enemy_resource: EnemyResource

@onready var enemy_health_bar = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/ProgressBar
@onready var enemy_name = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Label2
@onready var enemy_sprite = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/TextureRect
@onready var player_health_bar = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/ProgressBar

var enemy_health: float = 10
var enemy_max_health: int = 10
var player_health: float = 10
var player_max_health: int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_health_bar()
	enemy_name.text = enemy_resource.enemy_name
	enemy_sprite.texture = enemy_resource.enemy_sprite
	enemy_health = enemy_resource.enemy_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var versus_scene = preload("res://Scenes/versus_inteface.tscn")
	var instance = versus_scene.instantiate()
	add_child(instance)
	instance.versus_finished.connect(_on_versus_finished)

func _on_versus_finished(won):
	if won:
		enemy_health -= 3
	else:
		player_health -= 3
	update_health_bar()
		
func update_health_bar():
	enemy_health_bar.value = enemy_health / enemy_max_health * 100
	player_health_bar.value = player_health / player_max_health * 100
