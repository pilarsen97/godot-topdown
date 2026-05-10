extends Node
## Спавнер волны врагов. Не знает, кого спавнит — берёт сцену из WaveData.tres.
## Появляются на случайной точке вокруг игрока в радиусе spawn_radius.

@export var wave: WaveData

var _spawned: int = 0
var _player: Node2D = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if wave == null or wave.enemy_scene == null:
		push_warning("Spawner: wave or enemy_scene не назначены")
		return
	var timer := Timer.new()
	timer.wait_time = wave.interval
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)


func _on_tick() -> void:
	if _spawned >= wave.count:
		return
	_spawned += 1
	var enemy := wave.enemy_scene.instantiate() as Node2D
	get_parent().add_child(enemy)
	enemy.global_position = _random_spawn_position()


func _random_spawn_position() -> Vector2:
	var origin := _player.global_position if _player != null else Vector2.ZERO
	var angle := randf() * TAU
	return origin + Vector2(cos(angle), sin(angle)) * wave.spawn_radius
