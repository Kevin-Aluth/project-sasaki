class_name DialogueLineResource
extends Resource

## One line of a dialogue. The same format is used by the NPCs in exploration
## (played by DialogueManager) and by the boss in the dating sim (played by
## BossConversation).

## OTHER = whoever Sasaki is talking to (an NPC or the boss).
enum Speaker { OTHER, SASAKI }

## Only needed if some "next" points to this line.
@export var id: StringName
@export var speaker: Speaker = Speaker.OTHER
@export_multiline var text: String
## Unlocked in GameState once the line is fully written (e.g. an NPC telling
## Sasaki about the boss's weakness). Accepts a StoryFlag or a Weakness.
@export var sets: StoryFlag
## Sasaki's answers, shown once the line is fully written.
## Empty = the player just goes on to the next line.
@export var responses: Array[DialogueResponseResource]
## Id of the line to continue with. Empty = the following line in the list;
## "end" ends the dialogue. Ignored when the line has answers: each answer has
## its own "next".
@export var next: StringName
