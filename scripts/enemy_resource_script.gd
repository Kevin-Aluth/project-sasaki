extends Resource

class_name EnemyResource

@export var enemy_name: String
@export var enemy_sprite: Texture2D
@export_range(0.0, 100.0, 1.0, "or_greater", "hide_control") var enemy_health: float
@export_range(0, 100, 1,"or_greater") var enemy_strength: int
