extends CharacterBody2D

@export var max_speed: float = 200.0


func _physics_process(_delta: float) -> void:
	var direction := _movement_vector().normalized()
	velocity = max_speed * direction
	move_and_slide()


func _movement_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y)
