class_name AttackData
extends Resource

## Data of one attack type (sword, buster, claw...), saved as a .tres file.
## Timing is not here: the attack animation decides when the hit lands
## (method track calling AttackComponent.strike()) and when it ends.

## What appears on each target cell (an inherited scene of cell_attack.tscn).
@export var hit_scene: PackedScene
## Target cells relative to the attacker, written as if facing right:
## x = forward, y = sideways. (1, 0) = cell in front.
## Rotated automatically towards the attacker's facing.
@export var pattern: Array[Vector2i] = [Vector2i(1, 0)]
## Base animation name: the animator adds the direction (attack -> attack_side).
@export var animation: StringName = &"attack"
