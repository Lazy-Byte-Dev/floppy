extends Node3D

const PIPES = preload("res://scenes/pipes.tscn")
var pipes: Array = []
var spawn_timer: float = 0.0
const BASE_SPAWN_INTERVAL: float = 3.0
const BASE_PIPE_SPEED: float = 2.0
const PIPE_REMOVAL_THRESHOLD: float = -15.0
var current_pipe_speed: float = BASE_PIPE_SPEED
var current_spawn_interval: float = BASE_SPAWN_INTERVAL
var vertical_movement_amplitude: float = 0.0
var difficulty_level: int = 0
var is_game_over: bool = false

@export var player: CharacterBody3D
@onready var in_game: AudioStreamPlayer3D = $InGame
@onready var game_over: AudioStreamPlayer3D = $GameOver 
@onready var panel: Panel = $UI/Panel
@onready var score: Label = $UI/Score
@onready var panel_2: Panel = $UI/Panel2
@onready var label: Label = $UI/Panel/Label

func _ready() -> void:
	panel.visible = false
	in_game.playing = true
	spawn_pipe()
	score.text = str(player.score)
	
func spawn_pipe() -> void:
	var new_pipe = PIPES.instantiate()
	
	# Set initial position (right side of screen, with random y variation)
	new_pipe.position = Vector3(15.0, randf_range(-3.0, 3.0), 0.0)
	
	# Store the initial y position for oscillation
	new_pipe.set_meta("initial_y", new_pipe.position.y)
	new_pipe.set_meta("spawn_time", Time.get_ticks_msec() / 1000.0)
	
	add_child(new_pipe)
	pipes.append(new_pipe)

func update_difficulty() -> void:
	# Calculate difficulty level based on score
	var new_difficulty_level = floor(player.score / 20)
	
	if new_difficulty_level != difficulty_level:
		difficulty_level = new_difficulty_level
		
		# Speed increases with each difficulty level
		current_pipe_speed = BASE_PIPE_SPEED + (difficulty_level * 0.5)
		
		# Spawn interval decreases (but not too much)
		current_spawn_interval = max(BASE_SPAWN_INTERVAL - (difficulty_level * 0.2), 1.2)
		
		# Vertical movement starts after level 2 and increases
		if difficulty_level >= 2:
			vertical_movement_amplitude = min(difficulty_level * 0.5, 4.0)
func _process(delta: float) -> void:
	score.text = str(player.score)

func _physics_process(delta: float) -> void:
	if is_game_over:
		return
		
	# Check for game over conditions
	if player.is_on_wall() or player.is_on_floor() or player.is_on_ceiling() or is_player_completely_out_of_view():
		if !game_over.playing:
			game_over.playing = true
		in_game.playing = false
		panel.visible = true
		player.set_physics_process(false)
		is_game_over = true
		if player.score < 20:
			label.text = "YOU CAN DO BETTER THAN THAT BRO!!"
			
		if player.score > 20 and player.score < 40:
			label.text = "YOU TRIED BUT STILL NOT ENOUGH"
			
		if player.score > 40 and player.score < 60:
			label.text = "YOU GETTING BETTER"
			
		if player.score > 60 and player.score < 8+0:
			label.text = "YOU GOOD, BUT I MADE IT TO A 100"
		return  # Stop processing when game is over
	
	# Update difficulty based on current score
	update_difficulty()
	
	# Handle pipe spawning timing
	spawn_timer += delta
	if spawn_timer >= current_spawn_interval:
		panel_2.visible = false
		spawn_pipe()
		spawn_timer = 0.0
	
	# Update and remove pipes
	var pipes_to_remove = []
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for pipe in pipes:
		# Move pipe to the left
		pipe.position.x -= current_pipe_speed * delta
		
		# Apply vertical oscillation if difficulty level calls for it
		if vertical_movement_amplitude > 0 and pipe.has_meta("initial_y") and pipe.has_meta("spawn_time"):
			var elapsed_time = current_time - pipe.get_meta("spawn_time")
			var initial_y = pipe.get_meta("initial_y")
			
			# Oscillation frequency increases with difficulty
			var frequency = 1.0 + (difficulty_level * 0.2)
			pipe.position.y = initial_y + sin(elapsed_time * frequency) * vertical_movement_amplitude
		
		# Mark pipes that are far off-screen for removal
		if pipe.position.x < PIPE_REMOVAL_THRESHOLD:
			pipes_to_remove.append(pipe)
	
	# Remove pipes that are off-screen
	for pipe in pipes_to_remove:
		pipes.erase(pipe)
		pipe.queue_free()

func is_player_visible() -> bool:
	var camera = get_viewport().get_camera_3d()
	if camera and is_instance_valid(player):
		# Check if player is within camera frustum
		return camera.is_position_in_frustum(player.global_transform.origin)
	return false

func _on_continue_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()

# Function to check if player is completely out of camera view I dont understand how it works yet but thanks Claude
func is_player_completely_out_of_view() -> bool:
	var camera = get_viewport().get_camera_3d()
	if !camera or !is_instance_valid(player):
		return false

	# Get player's collision shape extents
	var player_aabb: AABB
	
	# Find collision shape to get accurate bounds
	for child in player.get_children():
		if child is CollisionShape3D:
			if child.shape is BoxShape3D:
				var box = child.shape as BoxShape3D
				player_aabb = AABB(player.global_position - box.size/2, box.size)
			elif child.shape is SphereShape3D:
				var sphere = child.shape as SphereShape3D
				var size = Vector3(sphere.radius * 2, sphere.radius * 2, sphere.radius * 2)
				player_aabb = AABB(player.global_position - Vector3(sphere.radius, sphere.radius, sphere.radius), size)
			elif child.shape is CapsuleShape3D:
				var capsule = child.shape as CapsuleShape3D
				var size = Vector3(capsule.radius * 2, capsule.height, capsule.radius * 2)
				player_aabb = AABB(player.global_position - Vector3(capsule.radius, capsule.height/2, capsule.radius), size)
			break
	
	# If we couldn't determine bounds, fall back to a small sphere around the player's position
	if player_aabb.size == Vector3.ZERO:
		player_aabb = AABB(player.global_position - Vector3(0.5, 0.5, 0.5), Vector3(1, 1, 1))

	# Check multiple points on the player's bounding box
	var points = [
		player_aabb.position,  # Bottom front left
		player_aabb.position + Vector3(player_aabb.size.x, 0, 0),  # Bottom front right
		player_aabb.position + Vector3(0, player_aabb.size.y, 0),  # Top front left
		player_aabb.position + Vector3(player_aabb.size.x, player_aabb.size.y, 0),  # Top front right
		player_aabb.position + Vector3(player_aabb.size.x/2, player_aabb.size.y/2, 0)  # Center
	]
	
	# The player is completely out of view only if ALL points are outside the frustum
	for point in points:
		if camera.is_position_in_frustum(point):
			return false  # At least one point is visible

	# If we get here, no points were visible
	return true
