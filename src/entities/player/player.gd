extends CharacterBody2D

var max_speed = 200

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	var direction = movement_vector().normalized()
	velocity = max_speed * direction
	#print(direction)
	move_and_slide()
	
func movement_vector():
	var movement_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var movement_y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(movement_x, movement_y)
