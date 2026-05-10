# Занятие 1 — Знакомство с Godot и герой, который ходит

## Что узнаем (теория)

### Что такое Godot и зачем он нужен
Godot — это **бесплатный игровой движок**. В нём из готовых «кубиков» (узлов)
собираются сцены, к ним прикрепляются скрипты — и получается игра.
В отличие от Scratch, мы пишем настоящий код на языке **GDScript** — он похож
на Python.

### Узлы и сцены
- **Узел (Node)** — один кирпичик: спрайт, камера, физическое тело и т.д.
- **Сцена (.tscn)** — готовая постройка из узлов, которую можно сохранить
  и потом переиспользовать.
- В одной сцене **один корневой узел** и сколько угодно дочерних.

### Координаты и движение
- Y направлен **вниз** (как в письме). Чем больше Y — тем ниже.
- `Vector2(x, y)` — пара чисел: «вправо/влево, вниз/вверх».
- Чтобы герой шёл по диагонали с той же скоростью, что и прямо, направление
  **нормализуют**: `direction.normalized()` — длина вектора становится равной 1.

### CharacterBody2D
Это узел «персонаж с физикой». Он:
- Сам сталкивается со стенами и другими телами.
- Имеет переменную `velocity` (куда и с какой скоростью движется).
- Имеет метод `move_and_slide()` — двигает тело и скользит вдоль стен.

### Action-карта (Input Map)
Чтобы не писать «нажата ли клавиша W», заводят **действия**:
`move_up`, `move_down`, `move_left`, `move_right`. Потом одно действие можно
повесить и на клавиатуру, и на геймпад, и на тач — код останется тот же.

`Input.get_action_strength("move_right")` возвращает **число от 0 до 1** —
насколько сильно нажата клавиша/стик.

---

## Что делаем (практика)

### Шаг 1. Создаём проект
1. Открыть Godot 4.6 → New Project.
2. Выбрать пустую папку, имя `Arsen 2D TopDown SunMax`.
3. Renderer = **Forward+** (Compatibility — если ноут слабый).
4. Создать.

### Шаг 2. Папки
Сразу делаем структуру:
```
src/entities/player/
assets/textures/player/
docs/
```
**Почему сразу:** через 3 урока папок будет 10 — без структуры запутаемся.

### Шаг 3. .gitignore и первый коммит
Создать `.gitignore`:
```
.godot/
.DS_Store
/build/
/export/
```
**НЕ игнорируем** `*.import` и `*.uid` — они нужны другим участникам.

Терминал:
```
git init
git add .
git commit -m "lesson-1: project setup"
```

### Шаг 4. Action-карта
Project Settings → Input Map. Заводим 4 действия с привязкой к WASD:
- `move_up` → W
- `move_down` → S
- `move_left` → A
- `move_right` → D

### Шаг 5. Сцена Player
1. New Scene → Other Node → **CharacterBody2D**.
2. Переименовать корень в `Player`.
3. Добавить дочерним: **AnimatedSprite2D** (анимации идла/бега).
4. В инспекторе SpriteFrames создать две анимации: `Idle` и `Run`,
   натащить кадры из `assets/textures/player/`.
5. Добавить **CollisionShape2D** (CircleShape2D, радиус ~5).
6. Добавить **Camera2D** — чтобы камера ехала за героем.
7. Назначить узлу группу **`player`** (вкладка Node → Groups).
   *Зачем:* через эту группу враги будут его искать.
8. Сохранить сцену в `src/entities/player/player.tscn`.

### Шаг 6. Скрипт `player.gd`
```gdscript
extends CharacterBody2D

var max_speed = 200


func _ready() -> void:
    pass


func _process(delta: float) -> void:
    var direction = movement_vector().normalized()
    velocity = max_speed * direction
    move_and_slide()


func movement_vector():
    var movement_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var movement_y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    return Vector2(movement_x, movement_y)
```

**Разбор по строкам:**
- `extends CharacterBody2D` — наш скрипт продолжает узел `CharacterBody2D`,
  значит, у него уже есть `velocity` и `move_and_slide()`.
- `var max_speed = 200` — пикселей в секунду.
- `_ready()` — вызывается **один раз** при появлении узла на сцене.
- `_process(delta)` — вызывается **каждый кадр** (60 раз в секунду).
- `movement_vector()` — наша функция: смотрим, какие клавиши нажаты,
  и собираем вектор направления.
- `direction.normalized()` — приводим длину к 1, чтобы по диагонали
  не было быстрее.
- `velocity = max_speed * direction` — задаём скорость.
- `move_and_slide()` — Godot сам двигает героя и скользит по стенам.

### Шаг 7. Главная сцена
Project Settings → Application → Run → **Main Scene = `player.tscn`**.

### Шаг 8. Запуск
F5. Герой бегает по WASD.
Коммит:
```
git add .
git commit -m "lesson-1: player walks"
```

---

## Что получилось и куда дальше
К концу урока:
- Есть проект с осмысленной структурой папок.
- Есть герой с двумя анимациями (Idle/Run autoplay = Idle).
- Герой ходит по WASD с одинаковой скоростью по диагонали.
- Всё закоммичено в git.

На следующем занятии нарисуем **уровень из тайлов**, по которому будет
ходить герой.

## Подводные камни занятия
- Если герой летит «слишком быстро по диагонали» — забыли `.normalized()`.
- Если герой не двигается — проверить Input Map (опечатка в названиях
  действий) и что `Main Scene` указывает на player.tscn.
- Если кадры анимации перепутаны — порядок в SpriteFrames важен.

---

## ⚙️ refactor/lesson-1 (для самостоятельных)

В ветке `refactor/lesson-1` тот же урок, но код сразу правильный:

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

**Что поменялось и зачем:**
- `_process` → **`_physics_process`** — физика обновляется фиксированно
  60 раз в секунду, не зависит от FPS машины.
- `var max_speed = 200` → **`@export var max_speed: float = 200.0`** —
  редактируется из инспектора, нельзя случайно положить туда строку.
- `: Vector2`, `:= ` — **типы**: компилятор ловит опечатки, IDE подсказывает.
- В `project.godot` сразу заводим **именованные слои** (player/enemy/...).
- `collision_layer = 1` (`player`) у Player — он живёт на своём слое.

Эти правила — на всю серию. Дальше они только добавляются.
