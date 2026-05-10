# Занятие 8 — HUD и урон по игроку

> Имп умирает от меча, но в нас он пройти насквозь. Сегодня:
> игрок тоже получает HP, имп бьёт прикосновением, и сверху появляется
> **HUD** со счётом и полоской здоровья.

## Что узнаем (теория)

### Control / CanvasLayer / UI
В Godot 2D-игра живёт в одном слое (World 2D), а интерфейс — в другом
(`CanvasLayer`). CanvasLayer **не двигается с камерой**, поэтому HUD
всегда в углу экрана, даже когда герой убежал на край карты.

Узлы UI:
- **Control** — базовый узел интерфейса (есть размер, привязки).
- **Label** — текст.
- **ProgressBar** — полоска (HP, mana).
- **MarginContainer / VBoxContainer / HBoxContainer** — раскладка
  «отступ», «вертикально», «горизонтально». Дети ставят узлы в контейнер
  — раскладка получается сама.

### Anchors (якоря)
У Control есть **anchors** — «к каким сторонам экрана я приклеен».
Анкор `15` (full rect) — растянуто на весь экран. Анкор «top right» —
прикреплён к правому верхнему углу. Это экономит много кода ресайза.

### EventBus как клей UI и игры
HUD не должен знать про Player и Imp. Когда игрок теряет HP, игра
кричит в EventBus:
```gdscript
EventBus.player_hp_changed.emit(current, max)
```
HUD подписан на этот сигнал и просто перерисовывает ProgressBar. Через
неделю можно добавить «полоска зелья» — HUD её отрисует, остальное
не трогаем.

### Перезагрузка сцены
Когда HP=0, простейшее решение — `get_tree().reload_current_scene()`.
Текущая сцена закрывается и грузится заново. На уроке 9+ заменим на
полноценный экран «Game Over».

---

## Что делаем (практика)

### Шаг 1. Игрок получает HealthComponent + Hurtbox
Открыть `player.tscn`. Так же, как у имп на прошлом уроке:
- **HealthComponent** (Node, `max_hp = 5`).
- **Hurtbox** (Area2D + hurtbox.gd):
  - `collision_layer = 0`, `collision_mask = enemy_hitbox` (галочка слоя 4);
  - дочерний CollisionShape2D — кружок;
  - `health_component → ../HealthComponent`.

### Шаг 2. Имп получает Hitbox (его «кулак»)
Открыть `imp.tscn`, добавить **Hitbox** (Area2D + hitbox.gd):
- `collision_layer = enemy_hitbox` (галочка слоя 4), `collision_mask = 0`;
- `damage = 1`;
- CollisionShape2D — кружок ~4.

Теперь когда имп физически касается игрока, его Hitbox попадает в
Hurtbox игрока → урон.

### Шаг 3. Player.gd — транслирует свои HP в EventBus
```gdscript
extends CharacterBody2D

@export var max_speed: float = 200.0
@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
    _health.hp_changed.connect(_on_hp_changed)
    _health.died.connect(_on_died)
    _on_hp_changed(_health.max_hp, _health.max_hp)


func _physics_process(_delta: float) -> void:
    var direction := _movement_vector().normalized()
    velocity = max_speed * direction
    move_and_slide()


func _movement_vector() -> Vector2:
    var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    return Vector2(x, y)


func _on_hp_changed(current: int, max_value: int) -> void:
    EventBus.player_hp_changed.emit(current, max_value)


func _on_died() -> void:
    EventBus.player_died.emit()
```

### Шаг 4. EventBus получает два новых сигнала
```gdscript
signal player_hp_changed(current: int, max_value: int)
signal player_died
```

### Шаг 5. Сцена HUD
1. New Scene → **CanvasLayer**, имя `HUD`.
2. Внутрь **MarginContainer** (anchors = full rect, отступы 12/8).
3. Внутрь Margin → **VBoxContainer** «Layout».
4. В Layout кидаем:
   - **Label** «ScoreLabel» с текстом «Счёт: 0».
   - **ProgressBar** «HpBar» (`max_value = 5`, `value = 5`,
     `show_percentage = off`).
5. Сохранить как `src/ui/hud.tscn`.

### Шаг 6. Скрипт HUD
`src/ui/hud.gd`:
```gdscript
extends CanvasLayer

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
```

**Разбор:**
- `@onready` — переменная инициализируется в момент `_ready()`,
  когда дерево уже готово. Без этого `$Margin/Layout/...` упадёт.
- `_on_enemy_died(_world_position, ...)` — нижнее подчёркивание перед
  параметром говорит «знаю, не использую» (Godot не ругается).
- `"Счёт: %d" % _score` — форматирование строки.

### Шаг 7. Положить HUD в World
Открыть `world.tscn`, добавить инстанс `hud.tscn` братом Player.
Иерархия:
```
World
├── Level_01
├── Player
└── HUD (CanvasLayer)
```

### Шаг 8. World реагирует на смерть игрока
`world.gd` дополнить:
```gdscript
func _ready() -> void:
    EventBus.spawn_in_level_requested.connect(_on_spawn_requested)
    EventBus.player_died.connect(_on_player_died)


func _on_player_died() -> void:
    get_tree().reload_current_scene()
```

### Шаг 9. Запуск
F5. В углу — счёт и полоска. Имп догоняет — полоска тает. После 5
ударов сцена перезагружается. Меч убивает имп — счёт растёт.

Коммит:
```
git add .
git commit -m "lesson-8: HUD with score and HP bar, player takes damage"
```

---

## Что мы поняли по архитектуре
- **HUD ничего не знает про игру** — только про EventBus. Это
  хрестоматийный «UI ↔ модель через события».
- **Игрок не знает про HUD** — он эмитит сигнал. Завтра HUD заменим
  на другой — игрок не заметит.
- **Перезагрузка сцены** — самое простое решение для прототипа.

## Подводные камни
- HP-бар не реагирует → проверить, что `HUD._ready()` вызывается **до**
  первого `Player._ready()` (CanvasLayer обычно идёт **после** Player
  в дереве; в `Player._ready()` мы намеренно ещё раз эмитим стартовое
  значение через `_on_hp_changed(...)`).
- Счётчик скачет на 2 при одном убийстве → у имп два Hitbox-а, или
  у меча два Hurtbox-а. Проверь иерархию.
- HUD «прыгает» при движении камеры → забыл сделать корнем `CanvasLayer`,
  поставил Control напрямую в World.
- ProgressBar показывает «0%» текстом — выключи `show_percentage`.

## ⚠️ Технический долг
Имп пока стоит в `level_01.tscn` руками — один штука. Это нормально,
но скучно. На уроке 9 заведём **спавнер**, который сам создаёт волны
импов с интервалом, а параметры волны положим в **Resource**.
