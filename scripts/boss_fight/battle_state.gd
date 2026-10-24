class_name BattleState
extends RefCounted

## State of ONE boss fight: created when the fight starts, thrown away when it
## ends. "Retry" simply means creating a new one.
## Unlocked flags and weaknesses are not here: they belong to the player's
## knowledge and live in GameState.

## How strong the boss's ego is: set by the dating sim, read by the fight
## (HP, attack rate, damage). Asymmetric on purpose: easier to pump him up
## than to bring him down, so the fight never gets too easy.
enum EgoStrength { LOW, NORMAL, HIGH, VERY_HIGH }

## Emitted when a reaction actually moves the ego.
signal ego_changed(old: EgoStrength, new: EgoStrength)

var boss: EnemyResource
var ego := EgoStrength.NORMAL

func _init(p_boss: EnemyResource) -> void:
	boss = p_boss

## Moves the ego by the reaction's ego_change, clamped to the enum's range.
func apply_reaction(reaction: ReactionResource) -> void:
	var old := ego
	ego = clampi(ego + reaction.ego_change, EgoStrength.LOW, EgoStrength.VERY_HIGH) as EgoStrength
	if ego == old:
		return
	print("BattleState: %s's ego %s -> %s" % [boss.enemy_name, EgoStrength.keys()[old], EgoStrength.keys()[ego]])
	ego_changed.emit(old, ego)
