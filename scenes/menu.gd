extends Node3D

var welcome: AudioStreamPlayer3D

func _ready() -> void:
	# Use call_deferred to ensure the scene is fully loaded
	call_deferred("setup_audio")

func setup_audio() -> void:
	welcome = $Welcome
	if welcome != null:
		welcome.play()
	

func _on_satrt_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	welcome.playing = false


func _on_quit_pressed() -> void:
	get_tree().quit()
	welcome.playing = false
