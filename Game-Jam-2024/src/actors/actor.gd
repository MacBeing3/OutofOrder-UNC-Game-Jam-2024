extends CharacterBody2D
class_name actor

@export var  speed = Vector2(600.0, 500.0)
@export var gravity = 4000.0

@export var health = 20

#@export var health = 20
#signal health_depleted

func _physics_process(delta: float) -> void:

	velocity.y += gravity * delta
	velocity.y = min(velocity.y,speed.y)
	

#func take_damage(amount: int) -> void:
##	anim_player.play( the on hit animation)
#
#	health -= amount
#	if health <= 0:
#		health_depleted.emit()
#
#	print("damage",amount)
