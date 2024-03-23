extends actor

var type = "player"

@export var jump_cancel_force := 500
@export var shoot_pos_x := 60
@export var casting_glyph_time := 0.25
@export_file var end_scene_path:= ""
@export var animation_casting_glyph_now:bool = false
@export var advanced_casting_mode_enabled:bool = false

@onready var shoot_position := $Shoot_Postition
@onready var player_sprite := $PlayerSprite
@onready var sprite_animator:= $SpriteAnimator
@onready var casting_glyph_timer := $Glyph_Cooldowns/Casting_Glyph_Timer
@onready var basic_projectile_timer := $Glyph_Cooldowns/basic_projectile_Timer
@onready var light_glyph_timer := $Glyph_Cooldowns/Light_Glyph_Timer
@onready var ice_glyph_timer := $Glyph_Cooldowns/Ice_Glyph_Timer
@onready var plant_glyph_timer:= $Glyph_Cooldowns/Plant_Glyph_Timer

@onready var anim_player := $JumpNSquish
@onready var on_damaged_player := $OnDamaged


const basic_projectile_scene = preload("res://src/Objects/basic_projectile.tscn")
const light_glyph_scene = preload("res://src/Projectiles/light_glyph.tscn")
const light_glyph_directional_scene = preload("res://src/Projectiles/light_glyph_right_left.tscn")
const ice_glyph_scene = preload("res://src/Projectiles/ice_glyph.tscn")
const ice_glyph_directional_scene = preload("res://src/Projectiles/ice_directional.tscn")
const ice_down_scene = preload("res://src/Projectiles/ice_down.tscn")

enum {basic_projectile_enum,light_glyph_enum,ice_glyph_enum, plant_glyph_enum}

signal health_depleted
signal basic_projectile_uses_changed
signal light_glyph_uses_changed
signal ice_glyph_uses_changed
signal plant_glyph_uses_changed
signal set_glyph_glow(booleen:bool)


var last_direction_x: float
var facing_right: bool = true
var is_in_portal:= false

var plant_glider_active := false
var plant_glider_max_time:int = 2
var plant_already_recharged := false
@onready var plant_max_glide_timer := $Glyph_Cooldowns/Max_Glide_Timer

var is_crouched:bool = false
var sprite_crouching:bool = false

var is_casting_glyph: bool = false

var glyph_recharging := {
	"basic" : false,
	"light" : false,
	"ice" : false,
	"plant" : false
}


@onready var dict_basic_projectile := {
	"basic_scene":basic_projectile_scene,
	"directional_scene": "",
	"up_scene":"",
	"down_scene": "",

	"timer":basic_projectile_timer,
	"recharge_time":1.0,
	"glyph_recharging":glyph_recharging["basic"],
	"uses": 1,
	"signal_uses": basic_projectile_uses_changed
}

#mmake this into glyph class, with light_glyph inherited from glyph, with defined vars
#would be glyph.light.var
@onready var light_glyph := {
	"basic_scene": light_glyph_scene,
	"directional_scene":light_glyph_directional_scene,
	"up_scene":"",
	"down_scene": "",
	
	"timer":light_glyph_timer,
	"recharge_time":1.5,
	"glyph_recharging": glyph_recharging["light"],
	"uses": 1,
	"signal_uses": light_glyph_uses_changed
}

@onready var ice_glyph := {
	"basic_scene":ice_glyph_scene,
	"directional_scene": ice_glyph_directional_scene,
	"up_scene":"",
	"down_scene": ice_down_scene,
	
	"timer":ice_glyph_timer,
	"recharge_time":3.0,
	"glyph_recharging": glyph_recharging["ice"],
	"uses": 2,
	"signal_uses": ice_glyph_uses_changed
}

@onready var plant_glyph := {
	"basic_scene": "", #
	"directional_scene": "" ,#
	"up_scene":"", #
	"down_scene":"" ,#
	
	"timer":plant_glyph_timer,#
	"recharge_time":1,#
	"glyph_recharging": glyph_recharging["plant"],#
	"uses": 1,#
	"signal_uses": plant_glyph_uses_changed#
}

@onready var glyphs_all := [dict_basic_projectile, light_glyph, ice_glyph, plant_glyph]


func _unhandled_key_input(_event: InputEvent):
#	if event.is_action_pressed("shoot_glyph_1") and not dict_basic_projectile["glyph_recharging"]:
#		_on_shoot(dict_basic_projectile)
#
##	if event.is_action_pressed("shoot_glyph_2") and not light_basic["glyph_recharging"]:
##		_on_shoot(light_basic)
#
#	if event.is_action_pressed("shoot_glyph_3") and not ice_glyph["glyph_recharging"] and is_on_floor():
#		_on_shoot(ice_glyph)
#
	pass
		
func _ready() -> void:
	
	pass
	

func _process(_delta) -> void:
	_handle_cast_single_button()


func _physics_process(_delta: float) -> void:
	var is_jump_interrupted = Input.is_action_just_released("jump") and velocity.y < 0.0
	var direction: = get_direction()

	velocity = calculate_move_velocity(velocity,direction,speed, is_jump_interrupted,is_in_portal)
	up_direction = Vector2.UP
	

	
	_get_sprite_state()
	
	if plant_glider_active and is_on_floor():
		_on_plant_glider_decayed()
		
	
	
	if not is_on_floor():
		#start coyote timer
		
		#doing jumping include "and not coyote_timer.ended"
		pass

	
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

	

#
		
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
	
	if not sprite_animator.current_animation == "Ice_Cast":
		output.x = speed.x * direction.x
	else: 
		output = Vector2(0,0)
		return output
	
	
	output.y += gravity * get_physics_process_delta_time()
	
	#jumping up
	if direction.y == -1.0:
		anim_player.play("jump squish_stretch")
		$Node2D/JumpAudio.play()
		output.y = speed.y * direction.y
	
	if velocity.y < 0 and is_jump_interrupted:
		output.y += jump_cancel_force
			

		
	if velocity.y > 0.0: #falling downwards gravity
		if plant_glider_active and not is_on_floor():
			output.y *= 0.65 if not Input.is_action_pressed("move_down")  else 0.95
			output.x *= 1.3
		else:
			output.y -= 0.30 * gravity * get_physics_process_delta_time()
	
			
	if is_in_portal or is_casting_glyph:
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
	if not animation_casting_glyph_now:
		if facing_right:
			player_sprite.flip_h = false
			shoot_position.set_position(Vector2(shoot_pos_x,-45))		
		else: 
			player_sprite.flip_h = true
			shoot_position.set_position(Vector2(-1*shoot_pos_x,-45))
		
		if velocity.x == 0 and not is_crouched:

			sprite_animator.play("Idle")
			sprite_crouching = false

		elif velocity.x == 0 and is_crouched and sprite_crouching == false:
			sprite_animator.play("Crouch")
			sprite_crouching = true

		elif velocity.x != 0:
			sprite_crouching = false
			if facing_right:
				player_sprite.flip_h = false
				if not sprite_animator.current_animation == "Moving_Right":
					sprite_animator.play("Moving_Right")
				shoot_position.set_position(Vector2(shoot_pos_x,-45))
				return
				#run particles
			if not facing_right:
				player_sprite.flip_h = true
				if not sprite_animator.current_animation == "Moving_Right":
					sprite_animator.play("Moving_Right")
				shoot_position.set_position(Vector2(-1*shoot_pos_x,-45))
				return
				#run particles direction * -1
	
	else: 

		if plant_glider_active:
			if facing_right:
				player_sprite.flip_h = false
			else: player_sprite.flip_h = true
			
			if not sprite_animator.current_animation == "Plant_Cast":
				sprite_animator.play("Plant_Cast")
				
		else: return
			




					
				
				
func _on_shoot(glyph:Dictionary, cast_variant:String):
#	if glyph != ice_glyph:
#		HitStopManager._hit_stop_short() #doesnt work with ice glyph, prob because moving player

	var glyph_cast: PackedScene
	
	if cast_variant == "basic":
		glyph_cast = glyph["basic_scene"]
		
	if cast_variant == "directional":
		glyph_cast = glyph["directional_scene"]
		
	if cast_variant == "up":
		glyph_cast = glyph["up_scene"]

	if cast_variant == "down":
		glyph_cast = glyph["down_scene"]

	glyph["uses"]-= 1
	glyph["signal_uses"].emit(glyph["uses"])
	if glyph["uses"] <= 0:

		glyph["glyph_recharging"] = true
		glyph["timer"].start(glyph["recharge_time"])
	

#	ice_glyph_uses_changed.emit(glyph["uses"])
	
	is_casting_glyph = true
	casting_glyph_timer.start(casting_glyph_time)
	
	##prob not ideal solution but will work

	
	var projectile_instance = glyph_cast.instantiate()
	projectile_instance.position = shoot_position.global_position
	projectile_instance.direction = direction_facing()
	projectile_instance.player_velocity = velocity
	projectile_instance.original_position = shoot_position.global_position
	projectile_instance.type = "player"

	add_child(projectile_instance)


func _on_portal_2d_body_entered(_body):
	is_in_portal = true

func take_damage(amount: int) -> void:
	on_damaged_player.play("on_damaged")
	health -= amount
	if health <= 0:
		health_depleted.emit()
	print("damage taken is",amount)
	print("health now is",health)

func _on_health_depleted():
	get_tree().change_scene_to_file(end_scene_path)
	queue_free()
	

func _on_casting_glyph_timer_timeout():
	is_casting_glyph = false
	#this is only if decide that want to stop movement when casting

#for loop to cnnect
func _on_basic_projectile_timer_timeout():
	_on_glyph_timer_timeout(basic_projectile_enum,1)

func _on_light_glyph_timer_timeout():
	_on_glyph_timer_timeout(light_glyph_enum,1)

func _on_ice_glyph_timer_timeout():
	_on_glyph_timer_timeout(ice_glyph_enum,2)
	
func _on_plant_glyph_timer_timeout():
	_on_glyph_timer_timeout(plant_glyph_enum,1)

func _on_glyph_timer_timeout(type: int,set_uses:int):
	var chosen_glyph = glyphs_all[type]
	
	chosen_glyph["glyph_recharging"] = false
	chosen_glyph["uses"] = set_uses
	
	chosen_glyph["signal_uses"].emit(chosen_glyph["uses"])
	
	
func cast_basic_ice():
	if ice_glyph["uses"] > 0:
		_on_shoot(ice_glyph, "basic")





func emit_set_glyph_glow(booleen):
	set_glyph_glow.emit(booleen)


func _on_plant_glider_decayed():
	
	plant_max_glide_timer.stop()

	animation_casting_glyph_now = false
	plant_glider_active = false

		
	if plant_glyph["glyph_recharging"] == false:
		print("i have decayed :(")
		plant_already_recharged = true
			
		plant_glyph["glyph_recharging"] = true
		plant_glyph["timer"].start(plant_glyph["recharge_time"])
		

	


func _handle_cast_unique_key_single_press_code():
		if not animation_casting_glyph_now:

		#	if Input.is_action_just_pressed: start timer 
		#	if Input.is_action_just_released: 
				# if not timer.timeout :stop the timer and cast small
				#if timer.timeout: cast big
			if Input.is_action_pressed("shoot_glyph_1") and not dict_basic_projectile["glyph_recharging"]:
				_on_shoot(dict_basic_projectile, "basic")

			#lgiht glyph
			if Input.is_action_pressed("shoot_glyph_2") and not light_glyph["glyph_recharging"]:
				if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
					_on_shoot(light_glyph, "directional")



				else:
					_on_shoot(light_glyph, "basic")

			#ice_glyph
			if Input.is_action_pressed("shoot_glyph_3") and not ice_glyph["glyph_recharging"]:

				if is_on_floor(): 
					#if animation_casting_glyph_now == true: await animation_casting_glyph_now = false
					animation_casting_glyph_now = true

					#if sprite animator is playing ice_cast await finished
					sprite_animator.play("Ice_Cast")



			#plant glyph
			if Input.is_action_pressed("shoot_glyph_4") and not plant_glyph["glyph_recharging"] and not is_on_floor():
				plant_glider_active = true
				animation_casting_glyph_now = true

				plant_already_recharged = false
				
				await plant_glyph["Timer"].timeout
				#old logic, is wrong, 
				_on_plant_glider_decayed()


func _handle_cast_advanced():

		print("advanced casting mode enabled")
		return
		if Input.is_action_pressed("shoot_glyph_1") and not dict_basic_projectile["glyph_recharging"]:
			_on_shoot(dict_basic_projectile, "basic")
			

		if Input.is_action_pressed("shoot_glyph_2") and not light_glyph["glyph_recharging"]:
			if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
				_on_shoot(light_glyph, "directional")
				$Node2D/Shoot.play()
					
				
				
			else:
				_on_shoot(light_glyph, "basic")
				
		if Input.is_action_pressed("shoot_glyph_3") and not ice_glyph["glyph_recharging"]:
				if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
					_on_shoot(ice_glyph, "directional")
	
				elif Input.is_action_pressed("move_down") and is_on_floor():
					_on_shoot(ice_glyph, "down")
				
				if is_on_floor() and not Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_down"): 
					animation_casting_glyph_now = true
					sprite_animator.play("Ice_Cast")
					

			#plant glyph
		if Input.is_action_pressed("shoot_glyph_4") and not plant_glyph["glyph_recharging"] and not is_on_floor():
			plant_glider_active = true
			animation_casting_glyph_now = true
				
			plant_max_glide_timer.start(plant_glider_max_time)
			#ned to redo not good
			_on_plant_glider_decayed()


func _handle_cast_two_button():
	#light and ice for 1, fire and plant for 2
	if not animation_casting_glyph_now:
		
#			if Input.is_action_just_pressed("shoot_glyph_1") and not dict_basic_projectile["glyph_recharging"]:
#				return
#				await get_tree().create_timer(1).timeout
#				if Input.is_action_pressed("shoot_glyph_1"):
#					var glyph_powered_up:= true
#			if Input.is_action_just_pressed: start timer 
#			if Input.is_action_just_released: 
#				 if not timer.timeout :stop the timer and cast small
#				if timer.timeout: cast big
				
			if Input.is_action_pressed("shoot_glyph_1"):
				if (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")) and not light_glyph["glyph_recharging"]:
					_on_shoot(light_glyph, "directional")
					
				
				
				elif not (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")) and not ice_glyph["glyph_recharging"]:
					if is_on_floor(): 
					#if animation_casting_glyph_now == true: await animation_casting_glyph_now = false
						animation_casting_glyph_now = true
						
						#if sprite animator is playing ice_cast await finished
						sprite_animator.play("Ice_Cast")
				

			if Input.is_action_pressed("shoot_glyph_2"):
				if Input.is_action_pressed("jump") and not plant_glyph["glyph_recharging"] and not is_on_floor():

					plant_glider_active = true
					animation_casting_glyph_now = true
					plant_already_recharged = false
					
					plant_max_glide_timer.start(plant_glider_max_time)
					

				
				
				elif not dict_basic_projectile["glyph_recharging"]:
					_on_shoot(dict_basic_projectile, "basic")
					
					
func _handle_cast_single_button():
	#light and ice for 1, fire and plant for 2
	if not animation_casting_glyph_now:
	
		if is_on_floor():
	#			if Input.is_action_just_pressed("shoot_glyph_1") and not dict_basic_projectile["glyph_recharging"]:
	#				return
	#				await get_tree().create_timer(1).timeout
	#				if Input.is_action_pressed("shoot_glyph_1"):
	#					var glyph_powered_up:= true
	#			if Input.is_action_just_pressed: start timer 
	#			if Input.is_action_just_released: 
	#				 if not timer.timeout :stop the timer and cast small
	#				if timer.timeout: cast big
					
			if Input.is_action_pressed("shoot_glyph_1"):
					if (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")) and not light_glyph["glyph_recharging"]:
						#MAKE IT SO it stops player movment
						_on_shoot(light_glyph, "directional")
						
					
					#if pressing down
					elif Input.is_action_pressed("move_down") and not ice_glyph["glyph_recharging"]:
						#if animation_casting_glyph_now == true: await animation_casting_glyph_now = false
							
							sprite_animator.play("Ice_Cast")
							sprite_animator.advance(0.05) #temp solution

					
					
					elif not dict_basic_projectile["glyph_recharging"] and not (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_down")):
						_on_shoot(dict_basic_projectile, "basic")
						
		else:
			if Input.is_action_pressed("shoot_glyph_1"):
				if not plant_glyph["glyph_recharging"]: #and Input.is_action_pressed("jump") :

					plant_glider_active = true
					animation_casting_glyph_now = true
					plant_already_recharged = false
					
					plant_max_glide_timer.start(plant_glider_max_time)
					

func _on_max_glide_timer_timeout():
	_on_plant_glider_decayed()
