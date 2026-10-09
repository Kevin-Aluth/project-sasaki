class_name CharacterAnimator
extends Node

## Picks the animation to play from what the character is doing and where
## it faces. Callers only use base names ("attack"), this component adds the
## direction ("attack_side") and flips the sprite when facing left.
##
## Two sources, chosen per animation:
## - AnimationPlayer, if it has the animation: used for actions with gameplay
##   events (method tracks). Its timeline drives the sprite frames.
## - Otherwise the SpriteFrames of the AnimatedSprite2D, with their own FPS
##   (idle, move: plain loops).

## Emitted when an action (anything started with play_action) ends.
signal action_finished(base: StringName)

## If left empty, sibling nodes with the default names are used.
@export var sprite: AnimatedSprite2D
@export var animation_player: AnimationPlayer
@export var mover: GridMover

# Base name of the running action; empty = free to loop idle/move.
var _action: StringName = &""

func _ready() -> void:
	var parent := get_parent()
	if sprite == null:
		sprite = parent.get_node_or_null("AnimatedSprite2D")
	if animation_player == null:
		animation_player = parent.get_node_or_null("AnimationPlayer")
	if mover == null:
		mover = parent.get_node_or_null("GridMover")
	assert(sprite != null and mover != null, "%s: CharacterAnimator needs an AnimatedSprite2D and a GridMover" % parent.name)

	sprite.animation_finished.connect(_on_animation_finished)
	if animation_player:
		animation_player.animation_finished.connect(func(_name: StringName) -> void: _on_animation_finished())

## Plays a one-shot action (attack, hurt, death...) until it ends.
func play_action(base: StringName) -> void:
	_action = base
	if not _play(base):
		# missing animation: end the action right away instead of getting stuck
		push_warning("%s: no animation for '%s'" % [get_parent().name, _full_name(base)])
		_on_animation_finished.call_deferred()

## Interrupts the current action (e.g. hit during an attack's windup).
func stop_action() -> void:
	_action = &""
	if animation_player:
		animation_player.stop()

func is_playing_action() -> bool:
	return not _action.is_empty()

func _process(_delta: float) -> void:
	if _action.is_empty():
		_play(&"move" if mover.is_moving() else &"idle")

# Returns false if neither source has the animation.
func _play(base: StringName) -> bool:
	var anim := _full_name(base)
	sprite.flip_h = mover.facing == Vector2i.LEFT

	if animation_player and animation_player.has_animation(anim):
		if animation_player.current_animation != anim:
			# the timeline sets the frames: the sprite must not advance on its own
			sprite.pause()
			animation_player.play(anim)
		return true

	if sprite.sprite_frames.has_animation(anim):
		if animation_player and animation_player.is_playing():
			animation_player.stop()
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
		return true
	return false

# "attack" + facing -> "attack_down" / "attack_side" / "attack_up".
# Animations without directional variants (e.g. "death") are used as they are.
func _full_name(base: StringName) -> StringName:
	var suffix := "_side"
	if mover.facing == Vector2i.DOWN:
		suffix = "_down"
	elif mover.facing == Vector2i.UP:
		suffix = "_up"
	var directional := StringName(base + suffix)
	var has_directional := sprite.sprite_frames.has_animation(directional) \
		or (animation_player != null and animation_player.has_animation(directional))
	return directional if has_directional else base

func _on_animation_finished() -> void:
	if _action.is_empty():
		return
	var finished := _action
	_action = &""
	action_finished.emit(finished)
