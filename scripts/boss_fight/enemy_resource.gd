class_name EnemyResource
extends Resource

##Enemy's name
@export var enemy_name: String

##Sprite used in the versus interface
@export var enemy_sprite: Texture2D

##Scene used in the left side of the dating sim
##In here we should find a Sprite2D of the enemy's face and the WeaknessSpot Area2Ds that Sasaki can point out
@export var enemy_dating_sim_closeup_scene: PackedScene

##Scene of the enemy on the grid, instantiated by the grid phase (e.g. enemy_grid.tscn)
##Its root needs a GridMover, a HealthComponent and a "target" export for Sasaki
@export var grid_enemy_scene: PackedScene

##Sprite used in the right side of the dating sim
@export var full_enemy_sprite: Texture2D

##Enemy health, cannot be set under 1. Split in thirds in the boss fight: each third lost in the grid leads to a face to face
@export_range(1, 100, 1, "or_greater", "hide_control") var enemy_health: int

##Enemy strength, cannot be set under 1, affects the rate at which the Progress bar in the versus interface goes down
@export_range(1, 100, 1,"or_greater") var enemy_strength: int

##Weaknesses of this enemy, discovered in the dating sim or told by NPCs during exploration
@export var weaknesses: Array[Weakness]

##Conversation with Sasaki in the dating sim
@export var conversation: DialogueResource

##Unlocked in GameState when the boss is defeated (exploration can react to it)
@export var defeated_flag: StoryFlag
