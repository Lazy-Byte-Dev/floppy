extends CharacterBody3D
class_name Player

# Physics constants
const JUMP_VELOCITY = 5.0
const GRAVITY = 15.0
const MAX_FALL_SPEED = -10.0

var score: int = 0

@onready var tap: AudioStreamPlayer3D = $Tap

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y -= GRAVITY * delta

	# Cap fall speed
	velocity.y = max(velocity.y, MAX_FALL_SPEED)

	# Handle jump
	if Input.is_action_just_pressed("jump"):
		tap.playing = true
		velocity.y = JUMP_VELOCITY

	# Apply movement
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		tap.playing = true
		velocity.y = JUMP_VELOCITY
