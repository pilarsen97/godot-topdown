extends Node
## Глобальная "доска объявлений".

## Запросить спавн сцены в текущем уровне (атаки, эффекты, дроп).
signal spawn_in_level_requested(scene: PackedScene, position: Vector2)

## Враг умер. score_value — сколько очков начислить.
signal enemy_died(world_position: Vector2, score_value: int)
