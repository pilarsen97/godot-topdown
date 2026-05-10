class_name Hitbox extends Area2D
## Зона, которая НАНОСИТ урон. Сама ничего не делает — просто несёт значение damage.
## Hurtbox у цели сам её обнаружит и попросит HealthComponent отнять HP.

@export var damage: int = 1
