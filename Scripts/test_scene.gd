extends Control

@export var enemy_resource: EnemyResource

@onready var enemy_health_bar = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/ProgressBar
@onready var enemy_name = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Label2
@onready var enemy_sprite = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/TextureRect
@onready var player_health_bar = $VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/ProgressBar
@onready var label = $Label

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
	#Instantiate the versus interface and connect its signals
	var versus_scene = preload("res://Scenes/versus_inteface.tscn")
	var instance = versus_scene.instantiate()
	add_child(instance)
	instance.versus_lost.connect(_on_versus_lost)
	instance.dialogue_chosen.connect(_on_dialogue_chosen)

	#To avoid being able to press the button we pause the tree, while the interface is not pausable. Could also disable the button
	get_tree().paused = true

func _on_versus_lost() -> void:
	#Resume the tree and apply the debuffs on Progress bar depletion 
	get_tree().paused = false
	player_health -= 3
	update_health_bar()
		
func update_health_bar():
	enemy_health_bar.value = enemy_health / enemy_max_health * 100
	player_health_bar.value = player_health / player_max_health * 100

func _on_dialogue_chosen(dialogue: String) -> void:
	#Resume the tree after dialogue is chosen.
	#Can also pass on which one was chosen ("left", "right" or 0 and 1) to have buffs and debuffs assigned accordingly.
	get_tree().paused = false
	label.text = dialogue
