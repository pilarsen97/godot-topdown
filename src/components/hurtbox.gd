class_name Hurtbox extends Area2D
## Зона, которая ПРИНИМАЕТ урон. Когда внутрь заходит Hitbox — отдаёт его damage
## своему health_component.
## Layer = 0 (никого не привлекает), mask = слой ожидаемых Hitbox-ов.

@export var health_component: HealthComponent


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if health_component == null:
		return
	if area is Hitbox:
		health_component.take_damage(area.damage)
