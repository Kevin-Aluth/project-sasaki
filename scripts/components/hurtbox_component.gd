class_name HurtboxComponent
extends Area2D

## Receives hits from HitboxComponents.
## Team filtering is done with collision layers: leave collision_layer empty
## and set collision_mask to the hitbox layer of the opposing team.

@export var health: HealthComponent
## Seconds of invincibility after taking a hit. Set to 0 to disable.
@export var invincibility_time: float = 0.5

signal hurt(hitbox: HitboxComponent)
signal invincibility_started
signal invincibility_ended

var _invincible := false
var _invincibility_timer: Timer

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)

	_invincibility_timer = Timer.new()
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)

func is_invincible() -> bool:
	return _invincible

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		_try_hit(area)

func _try_hit(hitbox: HitboxComponent) -> bool:
	if _invincible:
		return false
	hitbox.register_hit(self)
	hurt.emit(hitbox)
	if health:
		health.take_damage(hitbox.damage)
	_start_invincibility()
	return true

func _start_invincibility() -> void:
	if invincibility_time <= 0.0:
		return
	_invincible = true
	invincibility_started.emit()
	_invincibility_timer.start(invincibility_time)

func _on_invincibility_timeout() -> void:
	_invincible = false
	invincibility_ended.emit()
	# area_entered does not fire again for hitboxes that are still overlapping
	for area in get_overlapping_areas():
		if area is HitboxComponent and _try_hit(area):
			break
