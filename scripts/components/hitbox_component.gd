class_name HitboxComponent
extends Area2D

## Carries the damage data of an attack.
## Team filtering is done with collision layers: put this area on the
## attacker's hitbox layer (e.g. player_hitbox or enemy_hitbox).

@export var damage: int = 10

signal hit_landed(hurtbox: HurtboxComponent)

func _ready() -> void:
	# the hurtbox is the one looking for hitboxes, not the other way around
	monitoring = false
	monitorable = true

func register_hit(hurtbox: HurtboxComponent) -> void:
	hit_landed.emit(hurtbox)
