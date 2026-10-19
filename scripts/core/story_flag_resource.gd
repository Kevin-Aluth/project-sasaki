class_name StoryFlag
extends Resource

## A fact the player can discover or unlock: an event, an item, a piece of
## information from an NPC. Only the definition lives here: whether it is
## unlocked is runtime state, kept in GameState and never written back here.
##
## Pass the resource around in code (drag the .tres in the inspector), never
## its id as a string: GameState reads the id for you.

## Key used by GameState and by save files: once in use, never change it.
## It must be unique across all flags, weaknesses included.
@export var id: StringName
## Only to find your way around in the editor.
@export_multiline var description: String
