extends Node2D

## Dating sim phase: the boss's close-up on the left (with its WeaknessSpots)
## and the conversation at the bottom. Follows the boss fight phase contract:
## setup(state) is called before add_child, "finished" is emitted when the
## conversation ends.

signal finished

@onready var enemy_sprite_origin = $EnemySpriteOrigin
@onready var conversation_view: ConversationView = $CanvasLayer/ConversationView

@export_category("Enemy")
##Enemy Resource, used when the scene is launched on its own (F6). In the boss fight the enemy comes from the BattleState passed to setup()
@export var enemy: EnemyResource = null
@export var sasaki_name := "Sasaki"

@export_category("Debug")
##Flags unlocked when the scene is launched on its own (F6), to test the conversation without going through exploration. Ignored in the real boss fight
@export var debug_flags: Array[StoryFlag]

var state: BattleState
var conversation: BossConversation

## Phase contract: called by the boss fight controller before add_child.
func setup(p_state: BattleState) -> void:
	state = p_state

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if state == null:
		# launched on its own (F6): no boss fight around us, make our own state
		for flag in debug_flags:
			GameState.set_flag(flag)
		state = BattleState.new(enemy)
	var boss := state.boss
	assert(boss != null and boss.conversation != null, "Dating sim: the enemy needs a conversation")

	#Instantiate the left side of the dating sim section (the close-up with the WeaknessSpots).
	#Flags are already set here, so hidden spots know whether to show up
	var closeup = boss.enemy_dating_sim_closeup_scene.instantiate()
	add_child(closeup)

	#Creates the enemy sprite on the right side of the dating sim section. Gets the Texture2D from the EnemyResource.
	#Scale is temporary as the placeholder sprite is too big
	var enemy_sprite = Sprite2D.new()
	enemy_sprite.texture = boss.full_enemy_sprite
	enemy_sprite.scale = Vector2(0.4, 0.4)
	enemy_sprite_origin.add_child(enemy_sprite)

	conversation = BossConversation.new(boss.conversation, state)
	conversation.finished.connect(_on_conversation_finished)
	conversation_view.start(conversation, boss.enemy_name, sasaki_name)
	for spot in _find_spots(closeup):
		spot.clicked.connect(conversation_view.show_bubble)
	conversation.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#Possible zoom shader. It sets the shader's position to the mouse's position every frame
	$Control.position = get_viewport().get_mouse_position()

func _on_conversation_finished() -> void:
	print("Dating sim finished: %s's ego is %s" % [state.boss.enemy_name, BattleState.EgoStrength.keys()[state.ego]])
	finished.emit()

# Every WeaknessSpot under node, at any depth.
func _find_spots(node: Node) -> Array[WeaknessSpot]:
	var spots: Array[WeaknessSpot] = []
	for child in node.get_children():
		if child is WeaknessSpot:
			spots.append(child)
		spots.append_array(_find_spots(child))
	return spots
