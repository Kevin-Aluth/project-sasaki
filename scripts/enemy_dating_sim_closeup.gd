class_name EnemyDatingSimManager
extends Node2D


var dating_areas: Array[DatingSimArea]
var active_area: DatingSimArea = null

signal area_clicked(dialogue: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dating_areas.append_array(find_children("*", "DatingSimArea"))
	for area in dating_areas:
		area.mouse_entered.connect(_on_area_mouse_entered.bind(area))
		area.mouse_exited.connect(_on_area_mouse_exited.bind(area))


func _on_area_mouse_entered(area: DatingSimArea) -> void:
	active_area = area
	print(area)
	
func _on_area_mouse_exited(area: DatingSimArea) -> void:
	active_area = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accept") and active_area:
		area_clicked.emit(active_area.text_line)
