class_name EnemyResource
extends Resource


@export var enemy_name: String
@export var enemy_sprite: Texture2D
@export var enemy_dating_sim_closeup_scene: PackedScene
@export var full_enemy_sprite: Texture2D
@export_range(1.0, 100.0, 1.0, "or_greater", "hide_control") var enemy_health: float
@export_range(1, 100, 1,"or_greater") var enemy_strength: int
