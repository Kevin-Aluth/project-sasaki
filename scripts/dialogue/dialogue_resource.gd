class_name DialogueResource
extends Resource

## A whole dialogue: an NPC's (exploration) or a boss's (dating sim).
## Lines are played in list order unless a "next" jumps to an id.

const END := &"end"

@export var lines: Array[DialogueLineResource]

## Index of the line with this id, -1 if there is none.
func index_of(id: StringName) -> int:
	for i in lines.size():
		if lines[i].id == id:
			return i
	return -1

## Where to go after a line or an answer: the line with id "next", or the
## fallback index when "next" is empty. -1 = the dialogue ends (either "end",
## past the last line, or an unknown id, which is also reported as an error).
func resolve(next: StringName, fallback: int) -> int:
	if next == END:
		return -1
	var i := fallback if next.is_empty() else index_of(next)
	if i == -1:
		push_error("Dialogue %s: no line with id \"%s\"" % [resource_path, next])
	return i if i < lines.size() else -1
