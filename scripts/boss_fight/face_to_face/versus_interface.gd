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
##Which of the two lines is the right one. Temporary: later the lines (and which one hurts the boss) will come from the boss resource
@export_enum("Left", "Right") var correct_choice: int = 0
@export_category("Enemy")
##Enemy resource containing its name, its sprites, its health and its strength. Only used when the scene is launched on its own: in the boss fight the enemy comes from the BattleState passed to setup()
@export var enemy_resource : EnemyResource

#Emitted when the progress bar reaches zero
signal versus_lost

#Emitted when a dialogue option is chosen, passes on the dialogue chosen as String
signal dialogue_chosen(dialogue: String)

#Phase contract: emitted when the face to face is over. The result is already in state.face_to_face_won
signal finished

#Shared state of the boss fight, given by the controller with setup()
var state: BattleState

#True once the face to face is over, so nothing else happens until the controller removes this scene
var _done := false

#Progress bar fill percentage
var value: float = 50.0

#How much of the progress bar should be filled on each button press, aka Sasaki strength
#Later on could be a get from a global Sasaki statistics script or directly from Sasaki character
var mash_strength: float = 12

#When this is true the dialogue options are shown and can be chosen. It turns true after value goes above show_dialogue_value
var can_choose_dialogue: bool = false

##Phase contract: called by the boss fight controller before add_child
func setup(p_state: BattleState) -> void:
	state = p_state

func _ready() -> void:
	#Launched on its own (or from the old test scene): make our own state
	if state == null:
		state = BattleState.new(enemy_resource)
	dialogue_options_container.visible = false
	enemy_face.texture = state.boss.enemy_sprite


func _process(delta: float) -> void:
	#To avoid values going over or under the limit clampf is used
	#The rate at which the Progress bar goes down is dictated by the boss's enemy_strength
	value = clampf(value - delta * state.boss.enemy_strength, 0.0, 100.0)
	progress_bar_white.value = clampf(value, 1.0, 100.0)
	
	progress_bar.value = value - progress_bar_white_amount

	if value >= show_dialogue_value and !can_choose_dialogue:
		dialogue_options_container.visible = true
		can_choose_dialogue = true

	if value <= 0:
		versus_lost.emit()
		_end(false)


func _input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("button_mash"):
		#This dictates how much the Progress bar should fill up on button press
		value += 1 * mash_strength
		return

	if can_choose_dialogue:
		if event.is_action_pressed("left_choice"):
			_choose(0)
		elif event.is_action_pressed("right_choice"):
			_choose(1)

#0 = left line, 1 = right line
func _choose(choice: int) -> void:
	dialogue_chosen.emit(dialogue_left.text if choice == 0 else dialogue_right.text)
	_end(choice == correct_choice)

#Writes the result and stops: whoever added this scene removes it (the controller, or the old test scene)
func _end(won: bool) -> void:
	if _done:
		return
	_done = true
	set_process(false)
	state.face_to_face_won = won
	print("Versus: %s" % ("won" if won else "lost"))
	finished.emit()
