class_name EnemyDatingSimManager
extends Node2D

#Array of DatingSimArea Area2Ds
var dating_areas: Array[DatingSimArea]

#If the mouse goes on the CollisionShape2D the parent DatingSimArea Area2D gets saved here
var active_area: DatingSimArea = null

signal area_clicked(dialogue: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Saving all DatingSimArea Area2Ds in the dating_areas array and connecting the mouse_entered and mouse_exited signals.
	#Should be sorted top to bottom in the inspector list
	dating_areas.append_array(find_children("*", "DatingSimArea"))
	for area in dating_areas:
		area.mouse_entered.connect(_on_area_mouse_entered.bind(area))
		area.mouse_exited.connect(_on_area_mouse_exited.bind(area))


func _on_area_mouse_entered(area: DatingSimArea) -> void:
	active_area = area
	print(area)


func _on_area_mouse_exited(area: DatingSimArea) -> void:
	#When mouse exits a CollisionShape2D child of the current active_area, sets active_area to null
	#This if prevents an overlapping DatingSimArea overwriting active_area
	if active_area == area:
		active_area = null


func _input(event: InputEvent) -> void:
	#Emits signal when active_area is clicked. It sends the dialogue line linked to the active_area as String
	if event.is_action_pressed("accept") and active_area:
		area_clicked.emit(active_area.text_line)
