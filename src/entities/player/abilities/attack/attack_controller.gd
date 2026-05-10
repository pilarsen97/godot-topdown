extends Node

#var attack_ability: PackedScene = preload("res://src/entities/player/abilities/attack/attack_ability.tscn") 
@export var attack_ability: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var attack_instance = attack_ability.instantiate() as Node2D
	player.get_parent().add_child(attack_instance)
	attack_instance.global_position = player.global_position
	
	
	
	
	
