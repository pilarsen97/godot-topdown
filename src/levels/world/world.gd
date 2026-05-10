extends Node
## Точка входа. Player живёт здесь и переживает смену уровней.
## Слушает EventBus и кладёт спавны в Level/Spawned, рестартует игру при смерти.

@onready var _spawn_container: Node = $Level_01/Spawned


func _ready() -> void:
	EventBus.spawn_in_level_requested.connect(_on_spawn_requested)
	EventBus.player_died.connect(_on_player_died)


func _on_spawn_requested(scene: PackedScene, world_position: Vector2) -> void:
	if _spawn_container == null or scene == null:
		return
	var instance := scene.instantiate() as Node2D
	_spawn_container.add_child(instance)
	instance.global_position = world_position


func _on_player_died() -> void:
	# Простейший рестарт. Позже (урок 9+) сюда положим экран Game Over.
	get_tree().reload_current_scene()
