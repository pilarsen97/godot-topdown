extends Node
## Глобальная "доска объявлений": кто-то кричит — кто-то слышит.
## Никто не лезет в чужие узлы напрямую через get_parent().

## Запросить спавн способности/снаряда в текущем уровне.
signal spawn_in_level_requested(scene: PackedScene, position: Vector2)
