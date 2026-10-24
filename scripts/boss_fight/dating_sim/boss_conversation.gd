class_name BossConversation
extends RefCounted

## Runs the dating sim conversation: the main lines, Sasaki's answers and the
## interruptions (a spot on the boss's face pointed out).
## It only decides WHAT is said. ConversationView shows it and calls back
## line_typed() when a line is fully written and advance() when the player
## wants to go on.
##
## Answers and interruptions push a short sequence of lines on a stack
## (Sasaki's sentence, then the boss's reaction). The main conversation sits
## underneath, with its position kept: when the sequence on top runs out it is
## popped, and an interruption shows the interrupted line again, already
## written, so the conversation picks up the thread.

## A line to show. instant = already fully written (the interrupted line coming back).
signal line_shown(speaker: DialogueLineResource.Speaker, text: String, instant: bool)
## Sasaki's answers: available[i] is false for answers whose flag is missing.
signal responses_shown(responses: Array[DialogueResponseResource], available: Array[bool])
signal responses_hidden
signal finished

var _conversation: DialogueResource
var _state: BattleState
# Index of the current line of the main conversation.
var _main := -1
# Sequences on top of the main conversation: {lines, pos, then}.
# lines = [{speaker, text}], then = what to do when they run out.
var _stack: Array[Dictionary] = []
# Spot picked while a line was still being written: it waits for the line.
var _queued_spot: WeaknessSpot
# The line on screen is fully written.
var _typed := false
# Sasaki's answers are on screen.
var _choosing := false
var _done := false

func _init(conversation: DialogueResource, state: BattleState) -> void:
	_conversation = conversation
	_state = state

func start() -> void:
	_goto(&"", 0)

func is_finished() -> bool:
	return _done

## A spot can be pointed out only while the main conversation is on screen:
## never inside an answer or another interruption, never twice in a row.
func can_point_out() -> bool:
	return not _done and _stack.is_empty() and _queued_spot == null

## Called by the view when the line on screen is fully written.
func line_typed() -> void:
	if _typed:
		return
	_typed = true
	if _stack.is_empty():
		_set_flag(_current().sets)
	if _queued_spot:
		var spot := _queued_spot
		_queued_spot = null
		_interrupt(spot)
	elif _stack.is_empty():
		_offer_responses()

## Called by the view when the player wants to go on.
func advance() -> void:
	if _done or not _typed or _choosing:
		return
	if not _stack.is_empty():
		_next_in_sequence()
	else:
		_goto(_current().next, _main + 1)

## Sasaki picks an answer.
func choose(response: DialogueResponseResource) -> void:
	if not _choosing or not _is_available(response):
		return
	_choosing = false
	responses_hidden.emit()
	_set_flag(response.sets)
	_apply(response.reaction)
	_push([_sasaki(response.text)] + _boss_lines(response.reaction), _goto.bind(response.next, _main + 1))

## Sasaki points out a spot. If the boss is still writing his line, she waits
## for him to finish. Returns false if it's not possible right now.
func point_out(spot: WeaknessSpot) -> bool:
	if not can_point_out() or spot.used:
		return false
	spot.mark_used()
	if _typed:
		_interrupt(spot)
	else:
		_queued_spot = spot
	return true

func _interrupt(spot: WeaknessSpot) -> void:
	# the answers come back with the interrupted line
	if _choosing:
		_choosing = false
		responses_hidden.emit()
	var reaction := spot.get_reaction()
	_apply(reaction)
	_push([_sasaki(spot.point_out_text)] + _boss_lines(reaction), _show_main.bind(true))

func _push(lines: Array, then: Callable) -> void:
	_stack.push_back({"lines": lines, "pos": 0, "then": then})
	_show_sequence_line()

func _next_in_sequence() -> void:
	var top: Dictionary = _stack.back()
	top.pos += 1
	if top.pos < top.lines.size():
		_show_sequence_line()
	else:
		_stack.pop_back()
		top.then.call()

func _show_sequence_line() -> void:
	var top: Dictionary = _stack.back()
	var line: Dictionary = top.lines[top.pos]
	_typed = false
	line_shown.emit(line.speaker, line.text, false)

# Jumps to the line with this id; an empty id means the fallback index.
func _goto(id: StringName, fallback: int) -> void:
	var i := _conversation.resolve(id, fallback)
	if i == -1:
		_finish()
	else:
		_main = i
		_show_main(false)

func _show_main(instant: bool) -> void:
	var line := _current()
	_typed = false
	line_shown.emit(line.speaker, line.text, instant)

func _offer_responses() -> void:
	var responses := _current().responses
	if responses.is_empty():
		return
	var available: Array[bool] = []
	for response in responses:
		available.append(_is_available(response))
	if not available.has(true):
		push_error("BossConversation: line \"%s\" has no available answer" % _current().text)
		return
	_choosing = true
	responses_shown.emit(responses, available)

func _is_available(response: DialogueResponseResource) -> bool:
	return response.requires == null or GameState.has_flag(response.requires)

func _set_flag(flag: StoryFlag) -> void:
	if flag:
		GameState.set_flag(flag)

func _apply(reaction: ReactionResource) -> void:
	if reaction:
		_state.apply_reaction(reaction)

func _current() -> DialogueLineResource:
	return _conversation.lines[_main]

func _sasaki(text: String) -> Dictionary:
	return {"speaker": DialogueLineResource.Speaker.SASAKI, "text": text}

func _boss_lines(reaction: ReactionResource) -> Array:
	var out := []
	if reaction:
		for text in reaction.lines:
			out.append({"speaker": DialogueLineResource.Speaker.OTHER, "text": text})
	return out

func _finish() -> void:
	_done = true
	finished.emit()
