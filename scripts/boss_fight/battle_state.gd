class_name BattleState
extends RefCounted

## State of ONE boss fight, shared by its phases: the controller creates it and
## hands it to each phase with setup(state). It never ends up in a file.
## Unlocked flags and weaknesses are not here: they belong to the player's
## knowledge and live in GameState.
##
## The boss's life is split in thirds. The grid can take away at most the
## current third; then comes a face to face: won, the third is gone for good;
## lost, the boss gets it back. The boss is defeated when the last third goes.

## How strong the boss's ego is: set by the dating sim, read by the fight
## (HP, attack rate, damage). Asymmetric on purpose: easier to pump him up
## than to bring him down, so the fight never gets too easy.
enum EgoStrength { LOW, NORMAL, HIGH, VERY_HIGH }

const THIRDS := 3

## Emitted when a reaction actually moves the ego.
signal ego_changed(old: EgoStrength, new: EgoStrength)
## Emitted whenever boss or player HP change.
signal hp_changed

var boss: EnemyResource
var ego := EgoStrength.NORMAL

var boss_max_hp: int
var boss_hp: int
var player_max_hp: int
var player_hp: int
## Thirds of the boss's life still standing: 3 = untouched, 0 = defeated.
var boss_thirds := THIRDS
## Result of the last face to face, written by the versus.
var face_to_face_won := false

func _init(p_boss: EnemyResource, p_player_max_hp := 100) -> void:
	boss = p_boss
	boss_max_hp = p_boss.enemy_health
	player_max_hp = p_player_max_hp
	reset_hp()

## Full life for both, as at the start of the fight (also used by "retry").
## The ego is kept: the dating sim is not played again.
func reset_hp() -> void:
	boss_hp = boss_max_hp
	player_hp = player_max_hp
	boss_thirds = THIRDS
	face_to_face_won = false
	hp_changed.emit()

## Moves the ego by the reaction's ego_change, clamped to the enum's range.
func apply_reaction(reaction: ReactionResource) -> void:
	var old := ego
	ego = clampi(ego + reaction.ego_change, EgoStrength.LOW, EgoStrength.VERY_HIGH) as EgoStrength
	if ego == old:
		return
	print("BattleState: %s's ego %s -> %s" % [boss.enemy_name, EgoStrength.keys()[old], EgoStrength.keys()[ego]])
	ego_changed.emit(old, ego)

## HP where the current third ends: the grid can't push the boss below it,
## so no face to face can be skipped.
func third_floor() -> int:
	return roundi(boss_max_hp * (boss_thirds - 1) / float(THIRDS))

## HP where the current third starts: what the boss gets back after a lost
## face to face.
func third_top() -> int:
	return roundi(boss_max_hp * boss_thirds / float(THIRDS))

## The grid took the whole current third: time for a face to face.
func is_third_lost() -> bool:
	return boss_hp <= third_floor()

func damage_boss(amount: int) -> void:
	boss_hp = maxi(boss_hp - amount, third_floor())
	print("BattleState: %s %d/%d HP" % [boss.enemy_name, boss_hp, boss_max_hp])
	hp_changed.emit()

func damage_player(amount: int) -> void:
	player_hp = maxi(player_hp - amount, 0)
	print("BattleState: Sasaki %d/%d HP" % [player_hp, player_max_hp])
	hp_changed.emit()

## Face to face won: the third is gone for good.
func win_face_to_face() -> void:
	boss_thirds -= 1
	print("BattleState: face to face won, %d third(s) left" % boss_thirds)

## Face to face lost: the boss gets the third back.
func lose_face_to_face() -> void:
	boss_hp = third_top()
	print("BattleState: face to face lost, %s back to %d/%d HP" % [boss.enemy_name, boss_hp, boss_max_hp])
	hp_changed.emit()

func is_boss_defeated() -> bool:
	return boss_thirds == 0

func is_player_defeated() -> bool:
	return player_hp <= 0
