extends Node
## Глобальная "доска объявлений".

signal spawn_in_level_requested(scene: PackedScene, position: Vector2)
signal enemy_died(world_position: Vector2, score_value: int)

## HP игрока изменилось — слушает HUD.
signal player_hp_changed(current: int, max_value: int)
## Игрок умер — слушает World (рестарт уровня).
signal player_died
