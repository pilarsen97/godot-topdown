# Занятие 7 — Здоровье и урон через компоненты

> К концу прошлого блока (`refactor/lesson-6`) у нас есть игрок, имп
> и автоатака — но никакого урона. Сегодня: меч реально убивает имп,
> и мы делаем это **переиспользуемыми компонентами**, а не «прибиваем
> здоровье к импу гвоздями».

## Что узнаем (теория)

### Компонентный подход
Раньше мы писали логику прямо в `imp.gd`. Если завтра появится Slime,
Boss, Skeleton — придётся в каждом скрипте дублировать здоровье, урон,
смерть. Вместо этого делаем **отдельные узлы-компоненты**, которые
можно вешать на кого угодно:

- `HealthComponent` — хранит HP, выдаёт сигналы.
- `Hitbox` — «зона, которая бьёт» (несёт значение `damage`).
- `Hurtbox` — «зона, которая получает удары».

Потом для босса просто перетаскиваем те же три компонента — и всё работает.
Это идея ECS «light»: данные и поведение лежат в маленьких независимых
узлах, а сущность собирается из них как из лего.

### `Area2D`, hitbox и hurtbox
`Area2D` — это узел, который **видит**, кто в него вошёл, но **не
сталкивается** физически.

Конвенция:
- **Hitbox** — Area2D, от которого *исходит* урон (меч, пуля).
  Лежит на «слое атак».
- **Hurtbox** — Area2D, который *получает* урон.
  Сам ничего не атакует, но **в маске** держит слой Hitbox-ов.

Когда Hitbox входит в Hurtbox, срабатывает сигнал `area_entered`,
и Hurtbox отдаёт `damage` своему `HealthComponent`-у.

### Слои коллизий: для чего «player_hitbox»
В наших именах слоёв (Project Settings → Layer Names → 2D Physics):
- `1 = player` — физическое тело игрока (CharacterBody2D).
- `2 = enemy` — физическое тело врага.
- `3 = player_hitbox` — **зоны, наносящие урон от игрока** (меч, стрелы).
- `4 = enemy_hitbox` — зоны, наносящие урон от врагов (туша имп, файрбол).
- `5 = world` — стены, статичная геометрия.

Меч-Hitbox: `layer = player_hitbox`, `mask = 0` (никого не ловит сам).
Hurtbox имп: `layer = 0` (его никто не атакует напрямую),
`mask = player_hitbox` (ловит мечи).

### `class_name`
В скриптах компонентов мы пишем:
```gdscript
class_name HealthComponent extends Node
```
Это регистрирует имя `HealthComponent` глобально, и дальше можно:
- `@export var health_component: HealthComponent` — слот в инспекторе
  принимает только узлы этого типа;
- `if area is Hitbox: ...` — проверять «кто это».

Без `class_name` пришлось бы сравнивать имена строками, что хрупко.

### Сигналы вместо проверок
В `_physics_process` плохо писать `if hp <= 0: queue_free()` — каждую
секунду 60 проверок «жив ли я». Вместо этого `HealthComponent` сам
**эмитит сигнал** `died`, на который подписан владелец и удаляет себя.

---

## Что делаем (практика)

### Шаг 1. HealthComponent
1. Создать `src/components/health_component.gd`:
```gdscript
class_name HealthComponent extends Node

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
```

2. Сцена `src/components/health_component.tscn`: один узел Node со скриптом.

### Шаг 2. Hitbox
`src/components/hitbox.gd`:
```gdscript
class_name Hitbox extends Area2D

@export var damage: int = 1
```
Вся «логика» — лежит и хранит число. Никакого `_process`.

Сцену делать не обязательно: меч сам сделает Hitbox внутри себя.

### Шаг 3. Hurtbox
`src/components/hurtbox.gd`:
```gdscript
class_name Hurtbox extends Area2D

@export var health_component: HealthComponent


func _ready() -> void:
    area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
    if health_component == null:
        return
    if area is Hitbox:
        health_component.take_damage(area.damage)
```

### Шаг 4. Привинтить к Imp
Открыть `imp.tscn`, добавить:
- **HealthComponent** (Node со скриптом, `max_hp = 3`).
- **Hurtbox** (Area2D со скриптом hurtbox.gd):
  - `collision_layer = 0`, `collision_mask = player_hitbox` (галочка в слое 3);
  - дочерний `CollisionShape2D` (CircleShape2D, радиус ~5);
  - в инспекторе слот `health_component` → перетащить `../HealthComponent`.

В `imp.gd` подписаться на сигнал `died`:
```gdscript
@onready var _health: HealthComponent = $HealthComponent

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player") as Node2D
    _health.died.connect(_on_died)


func _on_died() -> void:
    EventBus.enemy_died.emit(global_position, score_value)
    queue_free()
```

### Шаг 5. Hitbox у меча
Открыть `attack_ability.tscn`, добавить **Hitbox** (Area2D со скриптом
hitbox.gd):
- `collision_layer = player_hitbox` (галочка в слое 3), `collision_mask = 0`;
- `damage = 1`;
- дочерний `CollisionShape2D` (CircleShape2D, радиус ~18 — чтобы покрыть
  размах меча).

### Шаг 6. EventBus получает новый сигнал
В `event_bus.gd`:
```gdscript
signal enemy_died(world_position: Vector2, score_value: int)
```
Это пригодится на следующем уроке для счётчика убитых.

### Шаг 7. Запуск
F5. Меч появляется → касается имп → имп исчезает после 3 ударов.

Коммит:
```
git add .
git commit -m "lesson-7: health/hitbox/hurtbox components, imp dies from sword"
```

---

## Что мы поняли по архитектуре
- **Маленькие компоненты лучше больших скриптов**. Каждый делает одну
  вещь и делает её хорошо.
- **Hitbox/Hurtbox + слои + маски** — стандартный шаблон в 2D-играх,
  который дальше масштабируется (стрелы, заклинания, AOE).
- **Сигналы вместо опроса** — `HealthComponent` сам кричит «умер»,
  никто не должен спрашивать каждый кадр.

## Подводные камни
- Имп не получает урон → проверь маски: на Hurtbox в `collision_mask`
  должна стоять галочка слоя `player_hitbox`.
- Имп умирает с одного удара → `damage = 1`, но AnimationPlayer
  меча может за одну анимацию **дважды** войти в Hurtbox (вход —
  выход — снова вход из-за изменения scale). Лечится тем, что меч
  сам себя удаляет в конце анимации (`queue_free`).
- Слот `health_component` в Hurtbox пустой → `area_entered` срабатывает,
  но дальше `if health_component == null: return` молча уходит.
  Не забывай перетащить ссылку.
- `class_name` написан с опечаткой → `if area is Hitbox` всегда `false`.
