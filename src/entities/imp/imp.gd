extends CharacterBody2D

@export var max_speed: float = 80.0

var _player: Node2D = null


func _ready() -> void:
	# Кэшируем игрока один раз — поиск по дереву каждый кадр это дорого.
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(_delta: float) -> void:
	var direction := _direction_to_player()
	velocity = max_speed * direction
	move_and_slide()


func _direction_to_player() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return (_player.global_position - global_position).normalized()
