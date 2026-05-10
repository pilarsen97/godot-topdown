# Занятие 3 — Враг (Imp), который догоняет

> Уровень с тайлами уже есть. Сейчас добавим первого моба — импа,
> который сам бежит за игроком.

## Что узнаем (теория)

### Группы (Groups)
В Godot узлу можно повесить **тег-метку** — группу. Например, на Player
повесили группу `player`. Любой другой узел может спросить:
> «Эй, дерево, дай мне любой узел из группы player».

Это удобно, когда нужно из имени-группы получить ссылку, не зная пути
к узлу:
```gdscript
var player = get_tree().get_first_node_in_group("player")
```
Без групп пришлось бы хардкодить `$/root/Level_01/Player` — а если узел
переедет в дереве, всё сломается.

### Вектор от точки А к точке Б
Чтобы враг бежал к игроку, нам нужно **направление**:
```
направление = (позиция_игрока − позиция_врага).normalized()
```
- Вычитание двух Vector2 даёт вектор «как добраться от второго к первому».
- `.normalized()` оставляет только направление, длина = 1.
- Умножаем на `max_speed` — получаем скорость, с которой надо двигаться.

### Подводный камень: поиск каждый кадр
Если внутри `_process()` каждый раз искать игрока по группе — это **обход
всего дерева 60 раз в секунду** на каждого врага. С 50 врагами игра уже
тормозит. Сегодня мы сделаем «как все делают сначала» — поиск каждый
кадр. На следующем уроке покажем профайлер и переделаем по-нормальному
(кэш в `_ready()`). Так у детей появится **ощущение «почему это плохо»**.

---

## Что делаем (практика)

### Шаг 1. Сцена Imp
1. Распаковать спрайты `imp_idle_anim_f0..3.png` и `imp_run_anim_f0..3.png`
   в `assets/textures/enemies/imp/`.
2. New Scene → CharacterBody2D, имя `Imp`.
3. AnimatedSprite2D с двумя анимациями `Idle` и `Run` (так же, как у игрока).
4. CollisionShape2D (CircleShape2D, радиус 4).
5. Сохранить в `src/entities/imp/imp.tscn`.

### Шаг 2. Скрипт `imp.gd`
```gdscript
extends CharacterBody2D

var max_speed = 80


func _ready() -> void:
    pass


func _process(delta: float) -> void:
    var direction = get_direction_to_player()
    velocity = max_speed * direction
    move_and_slide()


func get_direction_to_player():
    var player = get_tree().get_first_node_in_group("player") as Node2D
    if player != null:
        return (player.global_position - global_position).normalized()
    return Vector2.ZERO
```

**Разбор:**
- `max_speed = 80` — медленнее игрока (200), чтобы можно было убежать.
- `get_first_node_in_group("player")` — ищет первый узел в группе.
  Раньше мы добавили Player в эту группу. Теперь Imp может его найти,
  не зная, где Player лежит в дереве.
- `as Node2D` — приведение типа: говорим Godot «считай это Node2D»,
  чтобы у нас были `global_position`.
- `if player != null` — защита: если игрок вдруг ещё не появился
  (или умер), возвращаем нулевой вектор → стоим на месте.

### Шаг 3. Положить Imp в уровень
В `level_01.tscn` правой кнопкой → Instantiate Child Scene → `imp.tscn`.
Поставить где-нибудь подальше от игрока.

### Шаг 4. Запуск
F5. Imp бежит к Player. Если убежать — Imp догоняет.

Коммит:
```
git add .
git commit -m "lesson-3: imp chases player"
```

---

## Что получилось
- Первый враг с простым ИИ «беги к цели».
- Используем группы как «адресную книгу» сцены.

## Подводный камень для следующего урока
Если продублировать Imp 50 раз (Ctrl+D), игра начнёт подтормаживать.
Это будет наш аргумент, чтобы переписать на кэш в `_ready()` —
урок 4 начнём именно с этого.

---

## ⚙️ refactor/lesson-3

Здесь главное архитектурное улучшение — **кэшируем игрока в `_ready()`**:

```gdscript
extends CharacterBody2D

@export var max_speed: float = 80.0

var _player: Node2D = null


func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(_delta: float) -> void:
    velocity = max_speed * _direction_to_player()
    move_and_slide()


func _direction_to_player() -> Vector2:
    if _player == null:
        return Vector2.ZERO
    return (_player.global_position - global_position).normalized()
```

**Что поменялось:**
- `_process` → **`_physics_process`** (как везде).
- Поиск игрока — **один раз в `_ready()`**, потом в переменной `_player`.
  С 50 врагами игра не тормозит (в наивной — тормозит).
- Все числа типизированы и `@export`.
- `collision_layer = 2` (`enemy`) — Imp живёт на слое врагов.
- Подчёркивание у `_player` и `_direction_to_player` — конвенция Godot:
  «это приватное, снаружи не трогать».
