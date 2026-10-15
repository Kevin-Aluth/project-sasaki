extends Control

@onready var progress_bar_white = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2
@onready var progress_bar = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2/ProgressBar
@onready var enemy_face = $MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Enemy_Face
@onready var dialogue_options_container = $MarginContainer3
@onready var dialogue_left = $MarginContainer3/HBoxContainer/DialogueLeft
@onready var dialogue_right = $MarginContainer3/HBoxContainer/DialogueRight

##Size of white bar at the top of the progress bar
@export var progress_bar_white_amount: int = 1
##Value of the Progress bar to reach before the dialogue is shown
@export var show_dialogue_value: int = 75
@export_category("Enemy")
##Enemy resource containing its name, its sprites, its health and its strength
@export var enemy_resource : EnemyResource

#Emitted when the progress bar reaches zero
signal versus_lost

#Emitted when a dialogue option is chosen, passes on the dialogue chosen as String
signal dialogue_chosen(dialogue: String)

#Progress bar fill percentage
var value: float = 50.0

#How much of the progress bar should be filled on each button press, aka Sasaki strength
#Later on could be a get from a global Sasaki statistics script or directly from Sasaki character
var mash_strength: float = 12

#When this is true the dialogue options are shown and can be chosen. It turns true after value goes above show_dialogue_value
var can_choose_dialogue: bool = false

func _ready() -> void:
	dialogue_options_container.visible = false
	enemy_face.texture = enemy_resource.enemy_sprite


func _process(delta: float) -> void:
	#To avoid values going over or under the limit clampf is used
	#The rate at which the Progress bar goes down is dictated by enemy_resource.enemy_strength
	value = clampf(value - delta * enemy_resource.enemy_strength, 0.0, 100.0)
	progress_bar_white.value = clampf(value, 1.0, 100.0)
	
	progress_bar.value = value - progress_bar_white_amount

	if value >= show_dialogue_value and !can_choose_dialogue:
		dialogue_options_container.visible = true
		can_choose_dialogue = true

	if value <= 0:
		versus_lost.emit()
		queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("button_mash"):
		#This dictates how much the Progress bar should fill up on button press
		value += 1 * mash_strength
		return

	if can_choose_dialogue:
		if event.is_action_pressed("left_choice"):
			dialogue_chosen.emit(dialogue_left.text)
			queue_free()
		if event.is_action_pressed("right_choice"):
			dialogue_chosen.emit(dialogue_right.text)
			queue_free()
