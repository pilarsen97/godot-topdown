extends CharacterBody2D

@export var max_speed: float = 80.0
@export var score_value: int = 1

@onready var _health: HealthComponent = $HealthComponent

var _player: Node2D = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_health.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	velocity = max_speed * _direction_to_player()
	move_and_slide()


func _direction_to_player() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return (_player.global_position - global_position).normalized()


func _on_died() -> void:
	EventBus.enemy_died.emit(global_position, score_value)
	queue_free()
