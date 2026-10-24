extends Node2D

@export var npc_name := "Franco"
@export var portrait: Texture2D
## What this NPC says (a .tres made of DialogueLineResources). Flags to unlock
## go on the lines themselves ("Sets"), not here.
@export var dialogue: DialogueResource

@onready var interact_area: Area2D = $Sprite2D/InteractArea
@onready var prompt: Label = $Sprite2D/Prompt

var _player: Node = null
var _dialog_open := false
var _using_gamepad := false

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	DialogueManager.dialog_started.connect(_on_dialog_started)
	DialogueManager.dialog_finished.connect(_on_dialog_finished)
	_refresh_prompt()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body
		_refresh_prompt()
	
func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_refresh_prompt()
	
func _on_dialog_started() -> void:
	_dialog_open = true
	_refresh_prompt()
	
func _on_dialog_finished() -> void:
	_dialog_open = false
	_refresh_prompt()

func _refresh_prompt() -> void:
	prompt.text = "X" if _using_gamepad else "E"
	prompt.visible = _player != null and not _dialog_open

func _input(event: InputEvent) -> void:
	var gamepad := _using_gamepad
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		gamepad = false
	if gamepad != _using_gamepad:
		_using_gamepad = gamepad
		_refresh_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if _player and not _dialog_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_talk()

# Starts the dialogue, telling DialogueManager who is who
func _talk() -> void:
	DialogueManager.start(dialogue, {
		DialogueLineResource.Speaker.OTHER: {"name": npc_name, "portrait": portrait},
		DialogueLineResource.Speaker.SASAKI: {"name": _player.character_name, "portrait": _player.portrait},
	})
