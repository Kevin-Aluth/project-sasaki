class_name WeaknessSpot
extends Area2D

## A spot on the boss's face that Sasaki can point out (put it in the boss's
## close-up scene, with a CollisionShape2D). Clicking it opens a bubble with
## what she would say; saying it interrupts the conversation.
##
## The outcome is fixed per spot: reaction_if_known if the player already
## knows the weakness (e.g. from an NPC), reaction_if_guessed otherwise.

signal clicked(spot: WeaknessSpot)

## The weakness behind this spot. Empty = a pure guess, e.g. a big nose that
## is not a real weakness: reaction_if_guessed is always used.
@export var weakness: Weakness
## The spot only exists once the weakness is known (something only an NPC can
## tell you): it stays hidden until then, and when it shows up it is a sure hit.
@export var hidden_until_known: bool = false
## What Sasaki says, shown in the bubble.
@export_multiline var point_out_text: String
@export var reaction_if_known: ReactionResource
@export var reaction_if_guessed: ReactionResource

## Each spot can be used once per fight.
var used := false

func _ready() -> void:
	assert(not hidden_until_known or weakness != null,
		"%s: a hidden spot needs a weakness to reveal it" % name)
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# flags only change during exploration, so checking once is enough
	if hidden_until_known and not is_known():
		_disable()

func is_known() -> bool:
	return weakness != null and GameState.has_flag(weakness)

func get_reaction() -> ReactionResource:
	return reaction_if_known if is_known() else reaction_if_guessed

func mark_used() -> void:
	used = true
	_disable()

func _disable() -> void:
	hide()
	# hide() doesn't stop physics picking: the area must stop listening too
	input_pickable = false
	if get_viewport():
		_on_mouse_exited()

func _input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# overlapping spots: only the first one gets the click
		viewport.set_input_as_handled()
		clicked.emit(self)

# hand cursor as a hint that something can be clicked here
func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
