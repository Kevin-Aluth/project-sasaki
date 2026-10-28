extends Node2D

## Grid phase of the boss fight: Sasaki and the enemy on the grid.
## Follows the phase contract: setup(state) before add_child, "finished" when
## the boss has lost his current third (-> face to face) or Sasaki is at 0 HP.
##
## The enemy comes from the boss (EnemyResource.grid_enemy_scene) and is
## added at runtime as a child of the GridManager: its GridMover registers it
## on the grid by itself, like any entity written in the scene.
##
## BattleState is the source of truth for the HP: the HealthComponents start
## from it and every change goes back into it. The boss's ego only changes how
## fast the enemy attacks.

signal finished

@onready var grid: GridManager = $GridManager
@onready var player: Node2D = $GridManager/Player
@onready var player_health: HealthComponent = $GridManager/Player/HealthComponent

@export_category("Debug")
## Used only when the scene is launched on its own (F6).
@export var debug_boss: EnemyResource
## Ego of the boss when launched on its own, to try the attack speeds.
@export var debug_ego: BattleState.EgoStrength = BattleState.EgoStrength.NORMAL

var state: BattleState
## The boss's grid enemy, created in _ready.
var enemy: Node2D
var enemy_health: HealthComponent
var _done := false

## Phase contract: called by the boss fight controller before add_child.
func setup(p_state: BattleState) -> void:
	state = p_state

# Runs after the children's _ready: the HealthComponents already set
# current_health = max_health, and here we overwrite both with the state's.
func _ready() -> void:
	if state == null:
		# launched on its own (F6): make our own state
		state = BattleState.new(debug_boss)
		state.ego = debug_ego

	assert(state.boss.grid_enemy_scene != null, "%s has no grid_enemy_scene" % state.boss.enemy_name)
	enemy = state.boss.grid_enemy_scene.instantiate()
	# before add_child: the enemy checks for its target in its own _ready
	enemy.target = player
	grid.add_child(enemy)
	enemy_health = enemy.get_node("HealthComponent")

	player_health.max_health = state.player_max_hp
	player_health.current_health = state.player_hp
	enemy_health.max_health = state.boss_max_hp
	enemy_health.current_health = state.boss_hp
	player_health.health_changed.connect(_on_player_health_changed)
	enemy_health.health_changed.connect(_on_enemy_health_changed)

	enemy.apply_ego(state.ego)
	state.ego_changed.connect(func(_old, new) -> void: enemy.apply_ego(new))

func _on_player_health_changed(current: int, _max_value: int) -> void:
	if _done:
		return
	var lost := state.player_hp - current
	if lost > 0:
		state.damage_player(lost)
	if state.is_player_defeated():
		_finish()

func _on_enemy_health_changed(current: int, _max_value: int) -> void:
	if _done:
		return
	var lost := state.boss_hp - current
	if lost > 0:
		state.damage_boss(lost)
	# the grid can't take more than the current third: give back what went
	# past it. Done before HealthComponent checks for 0 HP, so the enemy doesn't
	# "die" while he still has thirds left.
	enemy_health.current_health = state.boss_hp
	if state.is_third_lost():
		_finish()

func _finish() -> void:
	_done = true
	enemy.stop()
	# no more input for Sasaki: the controller removes this scene right away,
	# but launched on its own the scene stays on screen
	player.set_process(false)
	print("Grid phase finished: %s" % ("Sasaki defeated" if state.is_player_defeated() else "third lost"))
	finished.emit()
