class_name EnemyResource
extends Resource

##Enemy's name
@export var enemy_name: String

##Sprite used in the versus interface
@export var enemy_sprite: Texture2D

##Scene used in the left side of the dating sim
##In here we should find an EnemyDatingSimManager node, a Sprite2D of the enemy, and DatingSimArea Area2Ds
@export var enemy_dating_sim_closeup_scene: PackedScene

##Sprite used in the right side of the dating sim
@export var full_enemy_sprite: Texture2D

##Enemy health, cannot be set under 1.0
@export_range(1.0, 100.0, 1.0, "or_greater", "hide_control") var enemy_health: float

##Enemy strength, cannot be set under 1, affects the rate at which the Progress bar in the versus interface goes down
@export_range(1, 100, 1,"or_greater") var enemy_strength: int
