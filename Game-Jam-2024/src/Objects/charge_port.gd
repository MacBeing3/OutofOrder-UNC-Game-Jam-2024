extends Node2D

@onready var animation_player = $AnimationPlayer

@onready var player_body

var charging:bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("Idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	if player_body:
		if AutoLoad.rocket_fuel_left < 6 and charging:
			AutoLoad.rocket_fuel_left += get_physics_process_delta_time() * 3
			player_body.loading_energy_bar.visible = true
			player_body.loading_energy_bar.value = AutoLoad.rocket_fuel_left
		if AutoLoad.rocket_fuel_left > 5 and charging:
			roundi(AutoLoad.rocket_fuel_left)
			

func _on_area_2d_body_entered(body):
	player_body = body
	if body._power_can_fly == true:
		animation_player.play("Charging")
		charging = true
	else: return

func _on_area_2d_body_exited(body):
	animation_player.play("Idle")
	charging = false
	body.loading_energy_bar.visible = false
