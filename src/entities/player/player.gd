extends CharacterBody2D

@export var max_speed: float = 200.0

@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
	_health.hp_changed.connect(_on_hp_changed)
	_health.died.connect(_on_died)
	# Сразу транслируем стартовое значение в HUD.
	_on_hp_changed(_health.max_hp, _health.max_hp)


func _physics_process(_delta: float) -> void:
	var direction := _movement_vector().normalized()
	velocity = max_speed * direction
	move_and_slide()


func _movement_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y)


func _on_hp_changed(current: int, max_value: int) -> void:
	EventBus.player_hp_changed.emit(current, max_value)


func _on_died() -> void:
	EventBus.player_died.emit()
