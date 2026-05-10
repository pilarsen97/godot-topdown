# Занятие 9 — Волны врагов через Resource

> Сейчас в `level_01.tscn` сидит **один** имп, поставленный руками.
> Сегодня сделаем «настоящего» противника: спавнер, который сам
> создаёт волны импов с интервалом, а **параметры волны хранятся
> отдельным файлом** — без правок кода.

## Что узнаем (теория)

### Custom Resource
**Resource** в Godot — это «файл с данными». Текстура, материал,
анимация — всё это Resource. Мы можем сделать **свой** класс ресурса:

```gdscript
class_name WaveData extends Resource

@export var enemy_scene: PackedScene
@export var count: int = 10
@export var interval: float = 1.0
```

Что это даёт:
- Можно создать в FileSystem **новый WaveData** через ПКМ → New Resource.
- Параметры редактируются **в инспекторе как у обычного узла**.
- Файл сохраняется как `.tres` (текстовый, влезает в git, видно
  diff между ревизиями).
- Один спавнер + 5 разных `.tres` = 5 волн с разной сложностью.

**Это базовый принцип: данные — отдельно от кода.** Когда геймдизайнер
хочет «увеличить количество врагов в волне 3 на 50%», он правит
`wave_03.tres`, а не лезет в скрипт.

### Где хранить .tres
- Если ресурс — это **данные баланса**, статика → `data/`.
- Если ресурс — это **встроенный кусок сцены** (TileSet, материал) →
  рядом со сценой, которой нужен.

У нас `data/wave_01.tres` — статика баланса.

### Спавнер
Спавнер — это маленький Node, который:
1. В `_ready()` запускает Timer.
2. На каждый `timeout` создаёт инстанс из `wave.enemy_scene`.
3. Кладёт его рядом с собой в дерево.
4. Останавливается, когда `_spawned == wave.count`.

**Спавнер не знает, какого врага он спавнит** — это пришло снаружи
через `@export var wave: WaveData`. Завтра захотим спавнить slime —
просто сделаем `wave_slime.tres`, переключим в инспекторе.

### Случайные позиции
```gdscript
var angle := randf() * TAU
return origin + Vector2(cos(angle), sin(angle)) * radius
```
- `randf()` — случайное число от 0 до 1.
- `TAU` ≈ 6.28 (2π) — полный оборот.
- Точка на окружности радиуса `radius` вокруг `origin`.

Так враги появляются «по кругу» вокруг игрока — со всех сторон.

---

## Что делаем (практика)

### Шаг 1. Класс WaveData
`src/data/wave_data.gd`:
```gdscript
class_name WaveData extends Resource

@export var enemy_scene: PackedScene
@export var count: int = 10
@export var interval: float = 1.0
@export var spawn_radius: float = 120.0
```
**Без сцены**, только скрипт. Это чистый ресурс.

### Шаг 2. Сделать конкретную волну
1. В FileSystem открыть папку `data/` (создать, если её нет).
2. ПКМ → **New Resource** → набрать `WaveData` → ОК.
3. Сохранить как `data/wave_01.tres`.
4. Открыть инспектор, заполнить:
   - `enemy_scene` → перетащить `imp.tscn`;
   - `count = 20`;
   - `interval = 1.5`;
   - `spawn_radius = 140`.

### Шаг 3. Скрипт спавнера
`src/levels/spawner.gd`:
```gdscript
extends Node

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
```

**Разбор:**
- Timer создаём **в коде**, потому что `wait_time` зависит от `wave.interval`.
  В сцену таймер не кладём — он привязан к данным волны.
- `add_child(timer)` — таймер ребёнок спавнера, удалится вместе с уровнем.
- `get_parent().add_child(enemy)` — враг рождается **рядом со спавнером**
  (внутри Level_01), а не **внутри** Spawner. Так дерево чище.
- `push_warning(...)` — мягкое предупреждение в редакторе, если данные
  волны забыли назначить.

### Шаг 4. Положить спавнер в уровень
1. Открыть `level_01.tscn`.
2. **Удалить** руками поставленный `Imp` (импы теперь спавнятся сами).
3. Добавить дочерним к Level_01: **Node** с именем `Spawner`.
4. Прицепить скрипт `spawner.gd`.
5. В инспекторе слот `wave` → перетащить `data/wave_01.tres`.

### Шаг 5. Запуск
F5. Каждые 1.5 секунды вокруг игрока появляются импы на расстоянии 140px.
Когда их 20 — спавнер замолкает.

Коммит:
```
git add .
git commit -m "lesson-9: wave spawner driven by WaveData resource"
```

---

## Что мы поняли по архитектуре
- **Custom Resource** — стандартный способ хранить данные баланса
  отдельно от кода.
- **Спавнер не знает, кого спавнит** — `enemy_scene` приходит из
  ресурса. То же поведение работает для slime, skeleton, boss.
- **Timer создаётся в коде**, когда его параметры зависят от ресурса.
  Если бы wait_time было постоянным — клали бы Timer в сцену.

## Подводные камни
- Импы появляются «штабелем» — забыли `_random_spawn_position()`,
  все стартуют в `(0,0)`.
- Импы не появляются вовсе → проверь, что в инспекторе у Spawner-а
  стоит ссылка на `wave_01.tres`, и что в `wave_01.tres` есть
  `enemy_scene`.
- При загрузке вылетает «Cannot load resource of type WaveData» →
  забыл `class_name WaveData` в скрипте, или `extends Resource`.
- Игра тормозит после 100 импов → нужен **лимит одновременно живых**.
  Это тема следующего урока (пуллинг + ИИ покруче).

## ⚠️ Что дальше (задел на L10+)
- **Несколько волн друг за другом**: массив `WaveData[]` в спавнере,
  следующая включается, когда предыдущая зачищена.
- **Второй уровень** + переход (`Marker2D` `SpawnPoint`,
  `World.load_level(path)`).
- **Звук и музыка** — `AudioStreamPlayer`, шина SFX/Music.
- **Boss** — отдельная сцена + AI-стейт-машина (idle / chase / attack).
- **Сохранение прогресса** — Resource с прогрессом, `ResourceSaver.save`.
