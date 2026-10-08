extends Control

@onready var progress_bar_white = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2
@onready var progress_bar = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2/ProgressBar
@onready var enemy_face = $MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Enemy_Face
#@onready var progess_bar_fire = $MarginContainer/VBoxContainer/MarginContainer/ProgressBar2/ProgressBar/ColorRect

@export var progress_bar_white_amount: int = 1
@export var enemy_resource : EnemyResource

signal versus_finished(won)

var value: float = 50.0
var mash_strength: float = 12
var enemy_strength: float = 50

func _ready() -> void:
	#progess_bar_fire.position.y -= progess_bar_fire.size.y / 4
	enemy_strength = enemy_resource.enemy_strength
	enemy_face.texture = enemy_resource.enemy_sprite


func _process(delta: float) -> void:
#	To avoid values going over or under the limit
	value = clampf(value - delta * enemy_strength, 0.0, 100.0)
#	We use progress_bar_white_amount to choose the thickness of the white part on the bar split
	progress_bar.value = value - progress_bar_white_amount
	progress_bar_white.value = clampf(value, 1.0, 100.0)
	#progess_bar_fire.position.x = progress_bar.position.x + (progress_bar.texture_progress.width * (progress_bar.value / 100.0)) - progess_bar_fire.size.x / 2
	if value >= 100:
		print("mash vinto")
		var won: bool = true
		versus_finished.emit(won)
		queue_free()
	if value <= 0:
		print("mash perso")
		var won: bool = false
		versus_finished.emit(won)
		queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("button_mash"):
		value += 1 * mash_strength
