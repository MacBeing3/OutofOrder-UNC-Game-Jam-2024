extends Node2D

var original_position:Vector2
var player_velocity:Vector2
var tweened_speed:= 1000
var top_speed:= 1500
var time_till_max_speed:= 0.5
var direction: Vector2
var facing_right:bool


# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)
	
	_get_flipped_state()
	
	position.y = original_position.y


	
#	_detect_moving(player_velocity)	

	
#	if player_velocity.x > 0:
#		tweened_speed += player_velocity.x
#
#	if player_velocity.x < 0:
#		tweened_speed -= player_velocity.x
	
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "tweened_speed", top_speed, time_till_max_speed).from_current()


	
	$AnimationPlayer.play("fly")
#	await anim_sprite.animation_finished
#	anim_sprite.play("flying")








func _on_area_2d_body_entered(body):
	pass # Replace with function body.
	if body.has_method("do_death"):
		body.do_death()

#func _on_area_2d_area_entered(area):
#	pass # Replace with function body.
##	area.get_parent().damage
#
#

	
#func on_timer_timeout():
#	queue_free()


func _physics_process(delta: float) -> void:
		position.x += direction.x * tweened_speed * delta
#	hitbox_collision_shape.disabled = 


func _get_flipped_state():
	if direction.x > 0:
		get_child(0).flip_h = false
#		impact_collision_shape.set_position(Vector2(5,0))
#		hitbox_collision_shape.set_position(Vector2(5,0))
		facing_right = true
	else:
		get_child(0).flip_h = true
#		impact_collision_shape.set_position(Vector2(-5,0)) 
#		hitbox_collision_shape.set_position(Vector2(-5,0))
		facing_right = false
