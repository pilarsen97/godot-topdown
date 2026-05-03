# Методичка: 2D Top-Down на Godot 4.6 (KIBERmax, 12 лет)

Цель курса (6 занятий) — собрать прототип Top-Down игры: герой, который ходит
по карте, враг, который его догоняет, и автоматическая атака. К финалу проект
должен иметь **архитектуру, которая не развалится** при добавлении новых
способностей, врагов и уровней.

## Главные правила архитектуры (повесить на стену кабинета)

1. **Один узел = один файл** (`player.tscn` + `player.gd` лежат рядом).
2. **Player живёт в `World`, а не в `Level`** — при смене уровня герой и его
   здоровье/инвентарь сохраняются.
3. **Враги и предметы живут в `Level`** — умирают вместе с уровнем.
4. **Никто не лезет в чужое дерево** через `get_parent().add_child(...)`.
   Если нужно «положить что-то в мир» — кричим в `EventBus`, мир сам разложит.
5. **Физика = `_physics_process`**, обычная анимация/UI = `_process`.
6. **Все числа — `@export`**, чтобы менять из инспектора, а не лазить в код.

---

## Структура проекта

```
res://
├── src/
│   ├── autoload/         EventBus и другие глобалы
│   ├── entities/         player/, imp/ — .tscn + .gd рядом
│   │   └── player/
│   │       └── abilities/  способности конкретно игрока
│   ├── levels/
│   │   ├── world/        world.tscn — точка входа (Player + текущий Level)
│   │   └── level_01/     level_01.tscn — TileMap + враги + Spawned
│   ├── components/       (на потом) HealthBar, Hitbox — общие узлы
│   └── systems/          (на потом) inventory, dialogue — чистая логика
├── assets/
│   ├── textures/         player/, enemies/, weapons/
│   └── packs/            сырые тайлсеты (импортируются)
├── data/                 .tres ресурсы, конфиги, локализация (на потом)
└── project.godot
```

---

## Урок 1 — «Проект и герой, который ходит»

**Цель:** новый проект, структура папок, Player ходит по WASD.

1. **Создать проект** Godot 4.6, Forward+. Включить *Compatibility* для слабых
   ноутов в школе — обязательно проверить, на чём будут работать дети.
2. **Сразу создать структуру** `src/entities/player/`, `src/levels/level_01/`,
   `src/levels/world/`, `assets/textures/player/`. Объясняем:
   *«мы планируем папки до того, как кодим — иначе потом всё сломается»*.
3. **`.gitignore`**: `.godot/`, `.DS_Store`, `/build/`, `/export/`.
   **НЕ игнорировать** `*.import` и `*.uid` — их версии должны быть в репо,
   иначе у соседа по парте всё развалится.
4. **`git init` + первый коммит** «empty project». Дети с первого занятия
   живут в git — это часть курса, а не «потом, когда вырастут».
5. **Player**: `CharacterBody2D` → `AnimatedSprite2D` + `CollisionShape2D` +
   `Camera2D`. Сохранить как `src/entities/player/player.tscn`.
6. **Скрипт `player.gd`** — сразу с типами и `@export`:
   ```gdscript
   extends CharacterBody2D
   @export var max_speed: float = 200.0

   func _physics_process(_delta: float) -> void:
       var direction := _movement_vector().normalized()
       velocity = max_speed * direction
       move_and_slide()

   func _movement_vector() -> Vector2:
       var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
       var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
       return Vector2(x, y)
   ```

**Почему `_physics_process`, а не `_process`:** *«игра считает движение
не каждый кадр, а 60 раз в секунду по таймеру. Если делать в `_process` —
у одного ребёнка герой летает, у другого ползает, потому что у них разные
компьютеры.»*

**Почему `@export` и `: float`:** *«цифру 200 хочется крутить в инспекторе,
не открывая код. А `: float` — это контракт: тут только число с точкой.»*

7. Настроить input map: `move_left/right/up/down` (WASD).
8. Запустить — герой бегает. Коммит: `feat: player movement`.

---

## Урок 2 — «Слои коллизий и группа player»

**Цель:** Player «знает», что он на слое player; враги его смогут найти.

1. В `Project Settings → Layer Names → 2D Physics` заводим именованные слои:
   `1=player`, `2=enemy`, `3=player_hitbox`, `4=enemy_hitbox`, `5=world`.
   *«Имена нужны, чтобы через 5 уроков понимать, что такое “слой 3”.»*
2. На Player выставить `collision_layer = player`. Mask пока пустой.
3. Добавить Player в группу **`player`** (вкладка Node → Groups). Через
   эту группу враги будут его искать.
4. Коммит: `feat: collision layers + player group`.

---

## Урок 3 — «Уровень из тайлов»

**Цель:** под героем — нарисованная карта.

1. Создать `level_01.tscn` (корень — `Node`, имя `Level_01`).
2. Внутрь `TileMapLayer`. Подключить `TileSet`, нарезать тайлы из атласа
   (`assets/packs/.../atlas_floor-16x16.png`).
3. Нарисовать комнату. Сохранить `level_01.tscn` в `src/levels/level_01/`.
4. **Архитектурный момент:** Player в `level_01.tscn` **НЕ кладём**.
   Он будет жить уровнем выше — в `World`.
5. Коммит: `feat: level_01 tilemap`.

---

## Урок 4 — «World — точка входа и контейнер `Spawned`»

**Цель:** объяснить детям главное архитектурное решение.

1. Создать `src/levels/world/world.tscn`, корень — `Node`, имя `World`.
2. Внутрь инстансим `Level_01` и `Player`. Сохраняем.
3. В `Project Settings → Application → Run` — main scene = `world.tscn`.
4. **Объяснение для детей** (повесить на доску):
   ```
   World
   ├── Level_01     ← меняется при load_level()
   │   └── Spawned  ← сюда мир кладёт стрелы, эффекты
   └── Player       ← остаётся при смене уровня (HP, инвентарь не теряет)
   ```
5. Внутрь `Level_01` добавить пустой `Node` с именем **`Spawned`** —
   это «коробка для всего временного, что появляется на карте».
6. Коммит: `feat: world entry scene + spawned container`.

---

## Урок 5 — «Враг (Imp), который догоняет»

**Цель:** показать сигнал-группу и **кэширование ссылок**.

1. Сцена `src/entities/imp/imp.tscn` — `CharacterBody2D` + AnimatedSprite +
   CollisionShape. `collision_layer = enemy`.
2. Скрипт `imp.gd`:
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
       if _player == null: return Vector2.ZERO
       return (_player.global_position - global_position).normalized()
   ```
3. **Урок-ловушка:** показать детям «плохой» вариант — поиск по группе
   в `_physics_process` каждый кадр. Запустить с 50 импами через дублирование,
   профайлер покажет лаги. Потом перенести поиск в `_ready()` —
   *«запомнили один раз, дальше пользуемся».*
4. **Почему `Imp` живёт в `Level_01`, а не в `World`:** уровень закончился —
   мобы умерли. Иначе при смене уровня старые импы будут бегать по новой
   карте.
5. Коммит: `feat: imp enemy chases player`.

---

## Урок 6 — «Способность Attack + EventBus»

**Цель:** автоматическая атака по таймеру + первый «настоящий паттерн» —
глобальный EventBus.

1. Сцена `attack_ability.tscn` — `Node2D` + `Sprite2D` (меч) +
   `AnimationPlayer` (анимация удара, в конце вызывает `queue_free`).
2. Сцена `attack_controller.tscn` — `Node` + `Timer` (`autostart`,
   `wait_time = 2.0`). Сигнал `timeout → _on_timer_timeout`.
3. **`AttackController` инстансим внутрь `player.tscn`** — узел `AbilityManager`
   → `AttackController`. Способность принадлежит игроку.
4. **EventBus** — `src/autoload/event_bus.gd`:
   ```gdscript
   extends Node
   signal spawn_in_level_requested(scene: PackedScene, position: Vector2)
   ```
   Зарегистрировать в `Project Settings → AutoLoad` под именем `EventBus`.
5. **`attack_controller.gd`** — НЕ лезет в чужое дерево, а кричит:
   ```gdscript
   func _on_timer_timeout() -> void:
       if attack_ability == null: return
       var player := get_tree().get_first_node_in_group("player") as Node2D
       if player == null: return
       EventBus.spawn_in_level_requested.emit(attack_ability, player.global_position)
   ```
6. **`world.gd`** слушает и кладёт в `Level_01/Spawned`:
   ```gdscript
   extends Node
   @onready var _spawn_container: Node = $Level_01/Spawned

   func _ready() -> void:
       EventBus.spawn_in_level_requested.connect(_on_spawn_requested)

   func _on_spawn_requested(scene: PackedScene, world_position: Vector2) -> void:
       var instance := scene.instantiate() as Node2D
       _spawn_container.add_child(instance)
       instance.global_position = world_position
   ```
7. **Демонстрация на доске** *(самая важная часть урока):*
   ```
        AttackController                       World
              │                                  │
              │ EventBus.spawn_in_level_requested │
              └──────────────►  📢  ──────────────┘
                                                 │
                                                 ▼
                                        Level_01/Spawned
                                          ← attack здесь
   ```
   *«AttackController не знает про World. World не знает про
   AttackController. Они общаются через “радио”. Завтра захотим, чтобы
   босс тоже стрелял — он подключится к тому же радио, World даже
   не заметит.»*
8. Коммит: `feat: attack ability via EventBus`.

---

## Чек-лист «правильной архитектуры» к концу урока 6

- [ ] `_physics_process` для всего, что двигается через `velocity`.
- [ ] Все числа — `@export`, типизированные.
- [ ] Никаких `get_parent().add_child(...)` через два узла вверх.
- [ ] Поиск по группе — только в `_ready()`, не каждый кадр.
- [ ] Player в `World`, враги и `Spawned` — в `Level`.
- [ ] Именованные слои коллизий, группа `player`.
- [ ] Один `EventBus`-autoload — единственное «глобальное» в проекте.
- [ ] Каждый урок = 1–2 коммита с понятным сообщением.

---

## Что добавлять дальше (уроки 7+)

- **Здоровье как компонент** — `HealthComponent.tscn` в `src/components/`,
  переиспользуется и для игрока, и для врага.
- **Hitbox/Hurtbox** через `Area2D` на слоях `*_hitbox`.
- **Второй уровень + смена уровня** — функция `World.load_level(path)`,
  которая удаляет `Level_01`, инстансит новый, ставит игрока в `SpawnPoint`
  (`Marker2D` в каждом уровне).
- **Resource-based балансировка** — `EnemyStat.tres` в `data/`, статы
  не зашиты в код.
