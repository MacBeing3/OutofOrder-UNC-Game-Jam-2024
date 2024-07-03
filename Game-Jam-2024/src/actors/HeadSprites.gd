extends Sprite2D

@onready var head_pos:= get_parent().get_child(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = head_pos.position
