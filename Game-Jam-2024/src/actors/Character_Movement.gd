extends actor


@export var jump_cancel_force := 500
@export_file var end_scene_path:= ""


signal health_depleted

var last_direction_x: float
var facing_right: bool = true
var is_in_portal:= false


var is_crouched:bool = false
var sprite_crouching:bool = false


		
func _ready() -> void:
	
	pass
	

func _process(_delta) -> void:
	pass


func _physics_process(_delta: float) -> void:
	var is_jump_interrupted = Input.is_action_just_released("jump") and velocity.y < 0.0
	var direction: = get_direction()

	velocity = calculate_move_velocity(velocity,direction,speed, is_jump_interrupted,is_in_portal)
	up_direction = Vector2.UP
	
	
	_get_sprite_state()
	
	
	move_and_slide()




func get_direction() -> Vector2:
	
	var direction_x
	if Input.is_action_pressed("move_down") and is_on_floor():
		direction_x = 0
		is_crouched = true

	else: 
		direction_x = Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
		is_crouched = false

	
	var direction_y = -1.0 if Input.get_action_strength("jump") and is_on_floor() else 1.0

	if Input.is_action_pressed("move_left"):
		last_direction_x = -1.0
	else: last_direction_x = 1.0
	
	_last_direction_input()
	
	
	return Vector2(direction_x, direction_y)


func calculate_move_velocity(
	linear_velocity: Vector2,
	direction: Vector2,
	speed: Vector2,
	is_jump_interrupted: bool,
	is_in_portal:bool
) -> Vector2:
	
	var output = linear_velocity
	
	
	if direction.x == 1:
		output.x +=  horizontal_accel * get_physics_process_delta_time()
		output.x = direction.x *min(output.x, speed.x)
		
	elif direction.x == -1:
		output.x +=  horizontal_accel * get_physics_process_delta_time()
		output.x = direction.x *max(output.x, speed.x)
	
	elif direction.x == 0:
		if output.x > 0:
			output.x = max(output.x - 2000 * get_physics_process_delta_time(),0)

		elif output.x < 0:
			output.x = min(output.x + 2000 * get_physics_process_delta_time(),0)	

		
	output.y += gravity * get_physics_process_delta_time()
	print(direction.x)
	#jumping up
	if direction.y == -1.0:
		#anim_player.play("jump squish_stretch")
		#$Node2D/JumpAudio.play()
		output.y = speed.y * direction.y
	
	if velocity.y < 0 and is_jump_interrupted:
		output.y += jump_cancel_force
			

		
	if velocity.y > 0.0: #falling downwards gravity
		pass
	
			
	if is_in_portal:
		output.x = 0.0

	print("velcoity is ", output.x)
	return output


#func calculate_stomp_velocity(linear_velocity: Vector2, impulse:float) -> Vector2:
#	var out = linear_velocity
#	out.y = -impulse
#	return out




func _last_direction_input():
	if Input.is_action_pressed("move_right"):
		facing_right = true
	
	if Input.is_action_pressed("move_left"):
		facing_right = false
		
	else: return
	
	
func direction_facing() -> Vector2:
	var direction = Vector2.ZERO
	
	if facing_right:
		direction.x = 1.0
	
	else:
		direction.x = -1.0

	return direction



func _get_sprite_state() -> void:
	pass
#		if facing_right:
#			player_sprite.flip_h = false
#			shoot_position.set_position(Vector2(shoot_pos_x,-45))		
#		else: 
#			player_sprite.flip_h = true
#			shoot_position.set_position(Vector2(-1*shoot_pos_x,-45))
#
#		if velocity.x == 0 and not is_crouched:
#
#			sprite_animator.play("Idle")
#			sprite_crouching = false
#
#		elif velocity.x == 0 and is_crouched and sprite_crouching == false:
#			sprite_animator.play("Crouch")
#			sprite_crouching = true
#
#		elif velocity.x != 0:
#			sprite_crouching = false
#			if facing_right:
#				player_sprite.flip_h = false
#				if not sprite_animator.current_animation == "Moving_Right":
#					sprite_animator.play("Moving_Right")
#				shoot_position.set_position(Vector2(shoot_pos_x,-45))
#				return
#				#run particles
#			if not facing_right:
#				player_sprite.flip_h = true
#				if not sprite_animator.current_animation == "Moving_Right":
#					sprite_animator.play("Moving_Right")
#				shoot_position.set_position(Vector2(-1*shoot_pos_x,-45))
#				return
#				#run particles direction * -1
#
#	else: 
#
#		if plant_glider_active:
#			if facing_right:
#				player_sprite.flip_h = false
#			else: player_sprite.flip_h = true
#
#			if not sprite_animator.current_animation == "Plant_Cast":
#				sprite_animator.play("Plant_Cast")
#
#		else: return
#
#



					
				


func _on_portal_2d_body_entered(_body):
	is_in_portal = true

func take_damage(amount: int) -> void:
#	Eon_damaged_player.play("on_damaged")
	health -= amount
	if health <= 0:
		health_depleted.emit()
	print("damage taken is",amount)
	print("health now is",health)

func _on_health_depleted():
	get_tree().change_scene_to_file(end_scene_path)
	queue_free()


func _on_area_2d_area_entered(area):
	print("I entered teh body")
