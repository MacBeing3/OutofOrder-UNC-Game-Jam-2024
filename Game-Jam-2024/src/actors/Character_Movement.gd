extends actor


@export var jump_cancel_force := 500
@export_file var end_scene_path:= ""

#fly export vars

@export var fly_accel:= 500
@export var fly_max_speed:= 500

#animators
@onready var body_sprite_animator:= $Animators/SpriteAnimator
@onready var face_flash_animator:=$Animators/FaceFlashEffect #make into a shader?
@onready var ecord_sprite_animator:=$Animators/ECordAnimator
@onready var jump_squish_animator:=$Animators/JumpNSquish
@onready var face_animator:=$Animators/FaceAnimator

@onready var face_sprite:= $PlayerSprites/FaceSprite
@onready var expression_sprite :=$PlayerSprites/ExpressionSprite

@onready var loading_energy_bar:= $PlayerSprites/LoadingProgressBar
@onready var flying_particles:= $Particles/FlyingBoost

@onready var shoot_position := $ShootPosition
@onready var lazer_beam := preload("res://src/Objects/lazer_beam.tscn")

@onready var cart_slots:= []



var player_sprites:= []
var face_flash_timer = 0

enum{Jump,Dash,Fly, etc, other}
var pickups_collected:=[]
var _power_can_jump: bool = false
var _jump_finished: bool = false


var _power_can_dash: bool= false
var _is_dashing:bool = false


var _power_can_fly: bool= false
var _is_flying:bool = false

#fly stuff



signal health_depleted

var last_direction_x: float
var facing_right: bool = true
var is_in_portal:= false


var is_crouched:bool = false
var sprite_crouching:bool = false


var loading_value:float

		
func _ready() -> void:
	var node_player_sprites:=$PlayerSprites
	
	_check_pickups()
	
	for child in  node_player_sprites.get_child_count():
		if node_player_sprites.get_child(child) is Sprite2D:
			player_sprites.append(node_player_sprites.get_child(child))
		
		
	for child in $CartridgeSlots.get_child_count():
		cart_slots.append( $CartridgeSlots.get_child(child))

	
	
	

func _process(_delta) -> void:
	pass


func _physics_process(_delta: float) -> void:
	var is_jump_interrupted = Input.is_action_just_released("jump") and velocity.y < 0.0
	var direction: = get_direction()

	velocity = calculate_move_velocity(velocity,direction,speed, is_jump_interrupted,is_in_portal)
	up_direction = Vector2.UP
	
	_handle_inputs()
	
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
	
#	X movement
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

#		Y Movemtn

	output.y += gravity * get_physics_process_delta_time() if not _is_flying else 0

	#jumping up
	if direction.y == -1.0 and _power_can_jump:
		_jump_finished = false
		jump_squish_animator.play("jump squish_stretch")
		#$Node2D/JumpAudio.play()
		output.y = speed.y * direction.y
		
	if _is_flying:

		output.y -= direction.y* fly_accel * get_physics_process_delta_time()
		output.y = direction.y * min(output.y, fly_max_speed)

	if velocity.y < 0 and is_jump_interrupted and not _is_flying:
		output.y += jump_cancel_force

		
	if velocity.y > 0.0: #falling downwards gravity
		pass
	
	
			
	if is_in_portal:
		output.x = 0.0

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

	if facing_right:
		for sprite in player_sprites:
			sprite.flip_h = false

		for slots in cart_slots:
			if slots.position.x < 0:
				slots.position.x *= -1
				slots.position.x -= 3
		loading_energy_bar.position.x = -7

	else: 
		for sprite in player_sprites:
			sprite.flip_h = true
			
		for slots in cart_slots:
			if slots.position.x >= 0:
				slots.position.x *= -1
				slots.position.x -= 3

		loading_energy_bar.position.x = -5

	if true: #cant be bothered to unident
		if velocity.x == 0 and not is_crouched:

			body_sprite_animator.play("Idle",-1,0.5)
			ecord_sprite_animator.stop()
			sprite_crouching = false
	#
	#		elif velocity.x == 0 and is_crouched and sprite_crouching == false:
	#			sprite_animator.play("Crouch")
	#			sprite_crouching = true

		if velocity.x != 0:
			sprite_crouching = false
			if facing_right:
				if not body_sprite_animator.current_animation == "Moving_Right":
					body_sprite_animator.play("Moving_Right")
					ecord_sprite_animator.play("Moving_Right")
					face_animator.play("Moving_Right")

				
					#run particles
			if not facing_right:
				if not body_sprite_animator.current_animation == "Moving_Right":
					body_sprite_animator.play("Moving_Right")
					ecord_sprite_animator.play("Moving_Right")
				
					#run particles direction * -1

	if _is_flying: 
		body_sprite_animator.stop()
		if face_animator.current_animation != "flying":
			face_animator.play("flying")


		loading_energy_bar.visible = true

		AutoLoad.rocket_fuel_left -= get_physics_process_delta_time()
		loading_energy_bar.value = AutoLoad.rocket_fuel_left

			
		if AutoLoad.rocket_fuel_left <= 0:
			_is_flying = false
			flying_particles.set_emitting(false)
	#		else: return
#
	#after effects

	face_flash_timer -= get_process_delta_time()
	if face_flash_timer <= 0: #could make a random interval
		face_flash_timer = 0
		face_flash_animator.play("face_flash")
		face_flash_timer = randi_range(2,5)
		
		#maybe make it so screen only changes when this flashes
		# so stays on previous animation
		print("pickups collected  ", pickups_collected)
		
#	if loading_energy_bar.visible == true:
#		_update_loading_bar(loading_value)



func _handle_inputs():
	
	if velocity.y > 0 and Input.is_action_pressed("jump") and not _is_flying:
		_jump_finished = true
	
	if (Input.is_action_pressed("jump") and _power_can_fly) and ((not is_on_floor() and _jump_finished) or (_power_can_jump == false)) and AutoLoad.rocket_fuel_left != 0:
		_is_flying = true
		flying_particles.set_emitting(true)

	
	if Input.is_action_just_released("jump"):
		_is_flying = false
		flying_particles.set_emitting(false)
		loading_energy_bar.visible = false
	

	if Input.is_action_just_pressed("space_bar"): #should not be jump but just for now
		_shoot_lazer()

	

func _check_pickups():
	for pickup in AutoLoad.pickups_collected:
		if pickup == Jump:
			_power_can_jump = true
			get_node("CartridgeSlots").get_child(Jump).visible = true
		if pickup == Fly:
			_power_can_fly = true
			get_node("CartridgeSlots").get_child(Fly).visible = true
				
	


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


		

func _on_timer_timeout():
	print("5 sec has passed")


#func _update_loading_bar(new_value:float):
#	loading_energy_bar.value = new_value
func _shoot_lazer():
	
	var projectile_instance = lazer_beam.instantiate()
	projectile_instance.position = shoot_position.global_position
	projectile_instance.direction = direction_facing()
	projectile_instance.player_velocity = velocity
	projectile_instance.original_position = shoot_position.global_position

	add_child(projectile_instance)


