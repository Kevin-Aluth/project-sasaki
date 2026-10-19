class_name Weakness
extends StoryFlag

## A boss weakness. It is a StoryFlag, so it is unlocked and saved like any
## other flag: found in the dating sim or told by an NPC during exploration.
## Save each weakness as its own .tres (not built-in), because the same one is
## referenced by dating sim areas, clash lines and dialogues.

## Shown when the weakness is discovered (e.g. "Crooked teeth!").
@export var display_name: String
