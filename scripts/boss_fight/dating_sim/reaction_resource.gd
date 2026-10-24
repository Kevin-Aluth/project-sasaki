class_name ReactionResource
extends Resource

## How the boss reacts to something Sasaki says (an answer or a spot pointed
## out): what he replies and how it moves his ego (BattleState.ego).

## The boss's lines, shown one after the other.
@export var lines: Array[String]
## How many ego levels this moves: negative = it hurts him (weaker in the
## fight), positive = it pumps him up (stronger), 0 = no effect.
## The result is clamped between LOW and VERY_HIGH.
@export_range(-3, 3) var ego_change: int = 0
