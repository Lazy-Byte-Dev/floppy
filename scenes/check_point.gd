extends Area3D

@onready var check_point_sound: AudioStreamPlayer3D = $"../CheckPointSound"

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		check_point_sound.playing = true
		body.score += 1
