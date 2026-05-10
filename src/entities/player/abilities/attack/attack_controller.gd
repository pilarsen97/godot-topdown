extends Node

@export var attack_ability: PackedScene


func _on_timer_timeout() -> void:
	if attack_ability == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Не лезем в чужое дерево — просим уровень заспавнить за нас.
	EventBus.spawn_in_level_requested.emit(attack_ability, player.global_position)
