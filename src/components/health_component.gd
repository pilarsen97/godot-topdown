class_name HealthComponent extends Node
## Здоровье как переиспользуемый компонент.
## Вешается на любую сущность (Player, Imp, Bossy) — даёт HP, урон и сигналы.

signal hp_changed(current: int, max_value: int)
signal died

@export var max_hp: int = 3

var current_hp: int


func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		died.emit()
