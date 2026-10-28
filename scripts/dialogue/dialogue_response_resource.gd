class_name DialogueResponseResource
extends Resource

## One of Sasaki's answers to a dialogue line.

## What Sasaki says (in exploration: the text of the choice button).
@export var text: String
## Without this flag the answer is shown but disabled (e.g. something only an
## NPC can tell you). Empty = always available.
@export var requires: StoryFlag
## Unlocked in GameState when this answer is picked.
@export var sets: StoryFlag
## Boss conversation only: the boss's reaction after Sasaki says it, moving his
## ego. Ignored in exploration dialogues.
@export var reaction: ReactionResource
## Id of the line to continue with. Empty = the line after the one with the
## answers; "end" ends the dialogue.
@export var next: StringName
