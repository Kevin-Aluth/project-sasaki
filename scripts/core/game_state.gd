extends Node

## Autoload "GameState": persistent state of the playthrough. It survives
## scene changes and is what will be saved.
## (No class_name: it would clash with the autoload's name.)
##
## Definitions (StoryFlag, Weakness) stay read-only .tres files: this node
## only remembers which of them are unlocked, keyed by their id.

## Emitted when a flag actually changes, so open scenes can react
## (e.g. a dialogue choice unlocking while it is on screen).
signal flag_changed(id: StringName, value: bool)

# Flag id -> unlocked. Missing ids count as locked.
var _flags: Dictionary[StringName, bool] = {}
# Flag id -> resource_path of the first flag seen with it (debug builds only):
# two different .tres sharing an id would silently unlock each other.
var _seen_paths: Dictionary[StringName, String] = {}

func has_flag(flag: StoryFlag) -> bool:
	_check(flag)
	return _flags.get(flag.id, false)

## True if every flag is unlocked (true for an empty list).
## Takes a plain Array so that Array[Weakness] can be passed too: typed
## arrays in GDScript don't convert to Array[StoryFlag].
func has_all(flags: Array) -> bool:
	return flags.all(has_flag)

func set_flag(flag: StoryFlag, value := true) -> void:
	_check(flag)
	if _flags.get(flag.id, false) == value:
		return
	_flags[flag.id] = value
	flag_changed.emit(flag.id, value)

func _check(flag: StoryFlag) -> void:
	assert(flag != null, "StoryFlag is null (export left empty?)")
	assert(not flag.id.is_empty(), "%s has no id" % flag.resource_path)
	if OS.is_debug_build():
		var first_path: String = _seen_paths.get_or_add(flag.id, flag.resource_path)
		if first_path != flag.resource_path:
			push_error("StoryFlag id '%s' used by both %s and %s" % [flag.id, first_path, flag.resource_path])
