# Занятие 5 — AnimationPlayer и автоспавн атаки по таймеру

> На прошлом уроке у меча не было анимации. Сегодня заставим его
> «бить» — поворот, увеличение, исчезновение. И сделаем контроллер,
> который сам спавнит атаку каждые 2 секунды.

## Что узнаем (теория)

### AnimationPlayer
Универсальный узел для **анимирования любых свойств любого узла**:
поворот, масштаб, цвет, позиция, даже вызов функций.
- Анимация — это **набор треков** (track). Один трек = одно свойство.
- Каждый трек — это **ключи** (keyframes): «в момент 0.0 значение такое,
  в момент 0.3 другое», между ними Godot интерполирует.
- Спец-трек **Call Method Track** — в нужный момент вызвать функцию
  (мы вызовем `queue_free`, чтобы меч сам себя удалил).

### `queue_free()`
Убирает узел из дерева в конце текущего кадра. Безопасный способ
«самоуничтожиться». В отличие от `free()`, не падает, если на узел
ещё кто-то ссылается в этом кадре.

### Timer + сигналы
**Timer** — узел-таймер. Свойства:
- `wait_time` — сколько секунд между срабатываниями.
- `autostart` — включается сам.
- сигнал `timeout` — срабатывает по истечении времени.

В Godot **сигнал** = событие, на которое можно подписаться.
В редакторе вкладка **Node → Signals** показывает все сигналы узла.
Двойной клик на сигнал — подключаем к функции.

### Контроллер как отдельная сцена
`AttackController` — это маленькая сцена `Node + Timer`. Она лежит
**внутри Player** (узел `AbilityManager → AttackController`). Так у
игрока со временем будут расти способности: Attack, Dash, Magic — каждая
свой контроллер.

---

## Что делаем (практика)

### Шаг 1. Анимация удара мечом
1. Открыть `attack_ability.tscn`.
2. Добавить дочерним к корню **AnimationPlayer**.
3. Внизу появится панель Animation. Создаём анимацию `attack_animation`,
   длина 0.6 с.
4. Добавляем 2 трека:
   - **Sprite2D:rotation** — ключи: 0.0=`-0.5`, 0.2=`2.5`, 0.6=`-0.5`.
   - **Sprite2D:scale** — ключи: 0.0=`(0,0)`, 0.2=`(1.3,1.3)`, 0.6=`(0,0)`.
5. Третий трек — **Call Method Track** на корне:
   - время 0.6, метод `queue_free`.
6. У AnimationPlayer ставим `Autoplay on Load = attack_animation`.

**Что мы запрограммировали анимацией:**
> «Появляюсь маленьким, размахиваюсь, увеличиваюсь, схлопываюсь
> и удаляю себя. Скрипт писать не надо.»

Проверка: F5 (если AttackAbility лежит в level_01) — меч анимируется
и исчезает через 0.6 с.

### Шаг 2. Сцена контроллера атаки
1. New Scene → **Node**, имя `AttackController`.
2. Добавить дочерним **Timer**: `wait_time = 2.0`, `autostart = on`.
3. На корне (Node) добавить скрипт `attack_controller.gd`.
4. На Timer вкладка Signals → `timeout` → подключить к корню,
   функция `_on_timer_timeout`.
5. Сохранить как `src/entities/player/abilities/attack/attack_controller.tscn`.

### Шаг 3. Скрипт `attack_controller.gd`
```gdscript
extends Node

@export var attack_ability: PackedScene


func _ready() -> void:
    pass


func _process(delta: float) -> void:
    pass


func _on_timer_timeout() -> void:
    var player = get_tree().get_first_node_in_group("player") as Node2D
    if player == null:
        return

    var attack_instance = attack_ability.instantiate() as Node2D
    player.get_parent().add_child(attack_instance)
    attack_instance.global_position = player.global_position
```

**Разбор:**
- `@export var attack_ability: PackedScene` — в инспекторе появится
  слот, куда мы перетащим `attack_ability.tscn`. Так контроллер не знает
  путь к сцене — её даём «снаружи».
- `_on_timer_timeout()` — вызывается каждые 2 секунды.
- `player.get_parent()` — родитель игрока — это уровень. Спавним
  атаку как **соседку игрока** в дереве. *Это сейчас работает, но
  на следующем уроке мы переделаем — лезть в `get_parent()` через
  голову соседа считается плохим тоном.*
- `instance.global_position = player.global_position` — кладём атаку
  туда, где сейчас игрок.

### Шаг 4. Подключить контроллер к игроку
1. Открыть `player.tscn`.
2. Под Player добавить пустой узел `AbilityManager` (тип Node).
3. В AbilityManager → Instantiate Child Scene → `attack_controller.tscn`.
4. Выбрать AttackController, в инспекторе в слот `attack_ability`
   перетащить `attack_ability.tscn` из FileSystem.

### Шаг 5. Запуск
F5. Каждые 2 секунды появляется меч, машет, исчезает.

Коммит:
```
git add .
git commit -m "lesson-5: attack auto-spawn via timer"
```

---

## Что мы поняли по архитектуре
- **Сцена-эффект сама себя убирает** — никто снаружи не должен думать,
  когда удалять.
- **Способность = контроллер + сцена**. Контроллер решает «когда»,
  сцена-визуал решает «как выглядит».
- **`@export PackedScene`** — способ отдать контроллеру нужную сцену
  без жёсткой связи в коде.

## Подводные камни
- Анимация не воспроизводится → не выставлен `Autoplay on Load`.
- Меч появляется, но не удаляется → забыл Call Method Track или
  опечатка в имени `queue_free`.
- Контроллер не реагирует на таймер → сигнал `timeout` не подключён
  к функции (вкладка Node → Signals у Timer).
- AttackAbility появляется, но валится в `(0,0)` → забыл строку
  `instance.global_position = player.global_position`.

## ⚠️ Технический долг этого урока
1. Контроллер ищет игрока **каждый раз** через дерево
   (`get_first_node_in_group`). На уроке 6 это починим.
2. Контроллер делает `player.get_parent().add_child(...)` — лезет
   в чужое дерево. На уроке 6 переделаем через **EventBus** (сигнал
   глобально — кто хочет, ловит).
3. У player.gd движение в `_process`, а должно быть в `_physics_process`.
   Тоже на уроке 6.

Эти три долга — основа следующего урока.
