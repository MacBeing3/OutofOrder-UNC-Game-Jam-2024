extends Node2D

@export_enum("Jump","Dash","Double_Jump", "etc", "other") var power_up_type

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	if body == null:
		return
		
	else:
		
		body.pickups_collected.append(power_up_type)
		body.get_node("CartridgeSlots").get_child(power_up_type).visible = true
	
		await get_tree().create_timer(0.5).timeout
		queue_free()

