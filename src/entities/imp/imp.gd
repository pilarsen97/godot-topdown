extends CharacterBody2D

var max_speed = 80

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	var direction = get_direction_to_player()
	velocity = max_speed * direction
	move_and_slide()
	
func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		# Схема с началом вектора и концом
		return (player.global_position - global_position).normalized()
	return Vector2.ZERO
