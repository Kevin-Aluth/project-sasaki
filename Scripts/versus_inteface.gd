extends Control

@onready var progress_bar_white = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2
@onready var progress_bar = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2/ProgressBar
@onready var enemy_face = $MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Enemy_Face
@onready var dialogue_options_container = $MarginContainer3
@onready var dialogue_left = $MarginContainer3/HBoxContainer/DialogueLeft
@onready var dialogue_right = $MarginContainer3/HBoxContainer/DialogueRight
#@onready var progess_bar_fire = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2/ProgressBar/ColorRect

@export var progress_bar_white_amount: int = 1
@export var enemy_resource : EnemyResource

signal versus_lost
signal dialogue_chosen(dialogue)

var value: float = 50.0
var mash_strength: float = 12
var enemy_strength: float = 50
var can_choose_dialogue: bool = false

func _ready() -> void:
	dialogue_options_container.visible = false
	enemy_strength = enemy_resource.enemy_strength
	enemy_face.texture = enemy_resource.enemy_sprite


func _process(delta: float) -> void:
#	To avoid values going over or under the limit
	value = clampf(value - delta * enemy_strength, 0.0, 100.0)
#	We use progress_bar_white_amount to choose the thickness of the white part on the bar split
	progress_bar.value = value - progress_bar_white_amount
	progress_bar_white.value = clampf(value, 1.0, 100.0)
	if value >= 75 and !can_choose_dialogue:
		print("mash vinto")
		dialogue_options_container.visible = true
		can_choose_dialogue = true

	if value <= 0:
		print("mash perso")
		versus_lost.emit()
		queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("button_mash"):
		value += 1 * mash_strength
		return
	if can_choose_dialogue:
		if event.is_action_pressed("left_choice"):
			dialogue_chosen.emit(dialogue_left.text)
			queue_free()
		if event.is_action_pressed("right_choice"):
			dialogue_chosen.emit(dialogue_right.text)
			queue_free()
