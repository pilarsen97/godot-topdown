extends Node
## Точка входа. Player живёт здесь и переживает смену уровней.
## Слушает EventBus и кладёт спавны в Level/Spawned.

@onready var _spawn_container: Node = $Level_01/Spawned


func _ready() -> void:
	EventBus.spawn_in_level_requested.connect(_on_spawn_requested)


func _on_spawn_requested(scene: PackedScene, world_position: Vector2) -> void:
	if _spawn_container == null or scene == null:
		return
	var instance := scene.instantiate() as Node2D
	_spawn_container.add_child(instance)
	instance.global_position = world_position
