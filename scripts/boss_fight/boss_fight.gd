extends Node

## Boss fight controller: creates the BattleState, starts the phases one at a
## time and decides what comes next. It doesn't know how a phase works: it
## calls setup(state) before add_child, waits for "finished", then reads the
## state.
##
##   dating sim (once) -> grid -> third lost -> face to face
##     face to face won:  the third is gone; last one -> victory, else grid
##     face to face lost: the boss gets the third back -> grid
##   Sasaki at 0 HP in the grid -> defeat -> "Riprova" -> grid, full HP

enum Phase { DATING, GRID, FACE_TO_FACE }

const SCENES := {
	Phase.DATING: preload("res://scenes/boss_fight/dating_sim/dating_sim.tscn"),
	Phase.GRID: preload("res://scenes/boss_fight/grid/grid_phase.tscn"),
	Phase.FACE_TO_FACE: preload("res://scenes/boss_fight/face_to_face/versus_interface.tscn"),
}

@export var player_max_hp := 100

@export_category("Debug")
## The boss to fight. Temporary: once the dojo entrance exists, the boss will
## come from GameState (step 5 of the plan).
@export var debug_boss: EnemyResource
## Unlocked when the fight starts, to test without going through exploration.
@export var debug_flags: Array[StoryFlag]

var state: BattleState
var _current: Phase
var _node: Node
var _end_layer: CanvasLayer
var _end_label: Label
var _retry_button: Button

func _ready() -> void:
	_build_end_screen()
	for flag in debug_flags:
		GameState.set_flag(flag)
	assert(debug_boss != null, "BossFight: no boss to fight")
	state = BattleState.new(debug_boss, player_max_hp)
	_start(Phase.DATING)

func _start(phase: Phase) -> void:
	_free_phase()
	_current = phase
	_node = SCENES[phase].instantiate()
	assert(_node.has_method("setup") and _node.has_signal("finished"),
		"%s doesn't follow the phase contract" % _node.name)
	_node.setup(state)
	_node.finished.connect(_on_phase_finished, CONNECT_ONE_SHOT)
	add_child(_node)
	print("BossFight: phase %s" % Phase.keys()[phase])

func _on_phase_finished() -> void:
	match _current:
		Phase.DATING:
			_start(Phase.GRID)
		Phase.GRID:
			if state.is_player_defeated():
				_defeat()
			elif state.is_third_lost():
				_start(Phase.FACE_TO_FACE)
			else:
				push_warning("BossFight: the grid ended with no third lost and Sasaki alive")
				_start(Phase.GRID)
		Phase.FACE_TO_FACE:
			if state.face_to_face_won:
				state.win_face_to_face()
				if state.is_boss_defeated():
					_victory()
					return
			else:
				state.lose_face_to_face()
			_start(Phase.GRID)

func _victory() -> void:
	_free_phase()
	if state.boss.defeated_flag:
		GameState.set_flag(state.boss.defeated_flag)
	print("BossFight: %s defeated" % state.boss.enemy_name)
	# step 5 of the plan: back to exploration from here
	_show_end("Vittoria!", false)

func _defeat() -> void:
	_free_phase()
	print("BossFight: Sasaki defeated")
	_show_end("Sconfitta...", true)

# "Retry" starts again from the grid: full HP, the ego from the dating sim stays.
func _on_retry() -> void:
	_end_layer.hide()
	state.reset_hp()
	_start(Phase.GRID)

func _free_phase() -> void:
	if _node:
		_node.queue_free()
		_node = null

func _show_end(text: String, can_retry: bool) -> void:
	_end_label.text = text
	_retry_button.visible = can_retry
	_end_layer.show()
	if can_retry:
		_retry_button.grab_focus()

# Placeholder end screen, built in code: replace it with a real scene later.
func _build_end_screen() -> void:
	_end_layer = CanvasLayer.new()
	_end_layer.hide()
	add_child(_end_layer)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_layer.add_child(box)
	_end_label = Label.new()
	_end_label.add_theme_font_size_override("font_size", 16)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_end_label)
	_retry_button = Button.new()
	_retry_button.text = "Riprova"
	_retry_button.add_theme_font_size_override("font_size", 8)
	_retry_button.pressed.connect(_on_retry)
	box.add_child(_retry_button)
