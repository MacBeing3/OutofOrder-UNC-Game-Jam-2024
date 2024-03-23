@tool
extends Area2D

@onready var anim_player := $AnimationPlayer 
@export var next_scene: PackedScene




func _on_body_entered(body):
	teleport()

	

func _get_configuration_warnings() -> PackedStringArray:
	return ["The next scene property cannot be empty" if not next_scene else ""]


func teleport()->void:
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	get_tree().change_scene_to_packed(next_scene)


