extends CanvasLayer
## Слой интерфейса. Поверх всего, не двигается с камерой.
## Слушает EventBus и перерисовывает Label/ProgressBar.

@onready var _score_label: Label = $Margin/Layout/ScoreLabel
@onready var _hp_bar: ProgressBar = $Margin/Layout/HpBar

var _score: int = 0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	_update_score()


func _on_enemy_died(_world_position: Vector2, score_value: int) -> void:
	_score += score_value
	_update_score()


func _on_player_hp_changed(current: int, max_value: int) -> void:
	_hp_bar.max_value = max_value
	_hp_bar.value = current


func _update_score() -> void:
	_score_label.text = "Счёт: %d" % _score
