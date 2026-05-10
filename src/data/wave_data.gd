class_name WaveData extends Resource
## Описание волны врагов. Просто данные — никакой логики.
## Сохраняется как .tres, лежит в data/, редактируется в инспекторе.

@export var enemy_scene: PackedScene
@export var count: int = 10
@export var interval: float = 1.0
@export var spawn_radius: float = 120.0
