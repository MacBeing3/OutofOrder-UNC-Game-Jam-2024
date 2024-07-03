extends Node2D

@export_enum("Jump","Dash","Fly", "etc", "other") var power_up_type
signal autoload_pickups_collected
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func _on_area_2d_body_entered(body):
	if body == null:
		return
		
	else:
		AutoLoad.pickups_collected.append(power_up_type)
#		body.pickups_collected.append(power_up_type)
		body._check_pickups()
#		body.get_node("CartridgeSlots").get_child(power_up_type).visible = true
	
		await get_tree().create_timer(0.5).timeout
		queue_free()

