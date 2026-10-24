class_name ConversationView
extends Control

## Shows a BossConversation: the dialogue box at the bottom, Sasaki's answers on
## its right and the bubble of a clicked spot. No conversation logic here: it
## displays what BossConversation emits, and calls back line_typed() when a
## line is fully written and advance() when the player wants to go on
## (click on the dialogue box, or the "accept" key).

@export var chars_per_sec := 40.0
## Where the bubble appears, relative to the clicked spot.
@export var bubble_offset := Vector2(6, -6)

@onready var text_box: Control = $TextBox
@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %Text
@onready var next_icon: Label = %NextIcon
@onready var response_list: VBoxContainer = $ResponseList
@onready var bubble: Control = $Bubble
@onready var bubble_text: Label = %BubbleText
@onready var say_button: Button = %SayButton

var _conversation: BossConversation
# Speaker -> name shown above the text
var _names := {}
var _type_tween: Tween
var _bubble_spot: WeaknessSpot

func _ready() -> void:
	text_box.hide()
	bubble.hide()
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_box.gui_input.connect(_on_text_box_input)
	say_button.pressed.connect(_on_say_pressed)

func start(conversation: BossConversation, boss_name: String, sasaki_name: String) -> void:
	_conversation = conversation
	_names = {
		DialogueLineResource.Speaker.OTHER: boss_name,
		DialogueLineResource.Speaker.SASAKI: sasaki_name,
	}
	conversation.line_shown.connect(_on_line_shown)
	conversation.responses_shown.connect(_on_responses_shown)
	conversation.responses_hidden.connect(_clear_responses)
	conversation.finished.connect(_on_finished)
	text_box.show()

## Opens the bubble of a clicked spot, if a spot can be pointed out right now.
func show_bubble(spot: WeaknessSpot) -> void:
	if _conversation == null or not _conversation.can_point_out() or spot.used:
		return
	_bubble_spot = spot
	bubble_text.text = spot.point_out_text
	bubble.reset_size()
	var pos := spot.get_global_transform_with_canvas().origin + bubble_offset
	# keep it on screen
	bubble.position = pos.clamp(Vector2.ZERO, get_viewport_rect().size - bubble.size)
	bubble.show()
	say_button.grab_focus()

func _hide_bubble() -> void:
	bubble.hide()
	_bubble_spot = null

func _on_say_pressed() -> void:
	var spot := _bubble_spot
	_hide_bubble()
	if spot:
		_conversation.point_out(spot)

func _unhandled_input(event: InputEvent) -> void:
	if _conversation == null or _conversation.is_finished():
		return
	if event is InputEventMouseButton:
		# a click anywhere else closes the bubble; if it was on another spot,
		# the spot (physics picking comes after this) opens its own bubble
		if event.pressed and bubble.visible:
			_hide_bubble()
	elif event.is_action_pressed("accept"):
		get_viewport().set_input_as_handled()
		_on_advance()

func _on_text_box_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_advance()

# First press: finish writing the line. Second press: go on.
func _on_advance() -> void:
	if _is_typing():
		_type_tween.kill()
		_finish_typing()
	else:
		_conversation.advance()

func _on_line_shown(speaker: DialogueLineResource.Speaker, text: String, instant: bool) -> void:
	# an answer or an interruption started: nothing can be pointed out now
	if bubble.visible and not _conversation.can_point_out():
		_hide_bubble()
	name_label.text = _names.get(speaker, "")
	text_label.text = text
	next_icon.hide()
	if _type_tween:
		_type_tween.kill()
	if instant:
		_finish_typing()
		return
	text_label.visible_characters = 0
	var total := text_label.get_total_character_count()
	_type_tween = create_tween()
	_type_tween.tween_property(text_label, "visible_characters", total, total / chars_per_sec)
	_type_tween.finished.connect(_finish_typing)

func _finish_typing() -> void:
	text_label.visible_characters = -1
	next_icon.show()
	# may show the answers (or start a queued interruption) right away
	_conversation.line_typed()

func _is_typing() -> bool:
	return _type_tween != null and _type_tween.is_running()

func _on_responses_shown(responses: Array[DialogueResponseResource], available: Array[bool]) -> void:
	_clear_responses()
	next_icon.hide()
	var first: Button
	for i in responses.size():
		var button := Button.new()
		button.text = responses[i].text
		button.disabled = not available[i]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 6)
		button.pressed.connect(_conversation.choose.bind(responses[i]))
		response_list.add_child(button)
		if first == null and available[i]:
			first = button
	if first:
		first.grab_focus()

func _clear_responses() -> void:
	for child in response_list.get_children():
		response_list.remove_child(child)
		child.queue_free()

func _on_finished() -> void:
	text_box.hide()
	_clear_responses()
	_hide_bubble()
