class_name CellAttack
extends Node2D

## Generic attack that hits a single grid cell for a short instant.
## Lifecycle: warning (telegraph) -> active (hitbox enabled) -> queue_free.
## Rockets, melee swings, etc. are variations of this with different timings/visuals.

@export var cell_size: int = 100
## Seconds the cell is telegraphed before the hit. Set to 0 for instant hits.
@export var warning_time: float = 0.6
## Seconds the hitbox stays enabled. Keep it above a couple of physics frames
## (~0.05s at 60 Hz) or the overlap may never be detected.
@export var active_time: float = 0.1
@export var warning_color: Color = Color(1.0, 0.8, 0.0, 0.35)
@export var active_color: Color = Color(1.0, 0.1, 0.1, 0.7)

signal activated
signal finished

@onready var hitbox: HitboxComponent = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var _active := false
var _elapsed := 0.0

func _ready() -> void:
	# shape sized to the cell, with a margin so it doesn't touch neighbours
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * cell_size * 0.8
	_hitbox_shape.shape = shape
	_hitbox_shape.disabled = true

	if warning_time > 0.0:
		await get_tree().create_timer(warning_time, false, true).timeout
	_activate()
	await get_tree().create_timer(active_time, false, true).timeout
	finished.emit()
	queue_free()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _activate() -> void:
	_active = true
	_hitbox_shape.set_deferred("disabled", false)
	activated.emit()

func _draw() -> void:
	var rect := Rect2(Vector2.ONE * -cell_size * 0.5, Vector2.ONE * cell_size)
	if _active:
		draw_rect(rect, active_color)
	else:
		# blink faster as the hit gets closer
		var blink := 0.5 + 0.5 * sin(_elapsed * TAU * lerpf(3.0, 10.0, _elapsed / maxf(warning_time, 0.001)))
		draw_rect(rect, warning_color * Color(1, 1, 1, blink))
		draw_rect(rect, warning_color, false, 2.0)
