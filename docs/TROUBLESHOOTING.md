# Шпаргалка: типовые проблемы и переключение веток

> Этот файл лежит в `docs/` всех веток `refactor/lesson-5..9`.
> Если что-то не открывается, сначала загляни сюда.

## Переключение между ветками

### Вариант 1 — VS Code
1. `code .` в терминале, открыть проект.
2. Слева внизу — синяя плашка с названием ветки. Кликнуть → выбрать нужную.
3. Вернуться в Godot → **Project → Reload Current Project**.

### Вариант 2 — GitHub Desktop
1. https://desktop.github.com/ → Add Local Repository.
2. Сверху меню «Current Branch» → выбрать ветку.
3. В Godot — Reload Current Project.

### Вариант 3 — терминал
```bash
git switch lesson-3            # или refactor/lesson-7, и т.д.
```
В Godot — Reload Current Project (или закрыть/открыть проект).

---

## Ошибка: «Не удалось загрузить сцену из-за отсутствия зависимостей»

Появляется почти всегда после **переключения веток**, особенно между
`lesson-N` и `refactor/lesson-N`. Причина: Godot держит кэш импортов
в `.godot/`, и UID-ы из прошлой ветки не совпадают с файлами текущей.

**Лечение (3 шага):**
1. **Закрыть Godot** полностью (Cmd+Q / Alt+F4).
2. В терминале:
   ```bash
   rm -rf .godot
   ```
3. Открыть проект заново. Внизу будет прогресс «Importing…» 10–30 сек.

После этого всё должно открываться. Если Godot пересохранил .tscn —
закоммить изменения как `chore: editor reformat`.

### Полезный алиас в `~/.zshrc`
```bash
godot-clean() { rm -rf .godot && open -a Godot . ; }
```
Использовать после каждого `git switch` между сильно отличающимися ветками.

---

## EventBus не виден из скрипта

Симптом: GDScript ругается `Identifier "EventBus" not declared in current scope`.

**Чек-лист:**
1. Project → Project Settings → **Autoload** → есть ли строка `EventBus`?
2. **Имя** ровно `EventBus` (большая E, большая B — регистр важен).
3. Галочка **Global Singleton (Enabled)** включена.
4. В `project.godot` есть секция:
   ```
   [autoload]
   EventBus="*res://src/autoload/event_bus.gd"
   ```
5. Если всё на месте, но всё равно красное → **Project → Reload Current Project**.

---

## После `git pull` сцены красные / dependency missing

Тот же кэш-баг, что и при переключении веток. Лечится так же:
закрыть Godot → `rm -rf .godot` → открыть.

---

## `.uid` файлы появились как «неотслеживаемые»

Godot генерирует `.uid` файлы для каждого `.gd` и кладёт рядом.
Их **нужно коммитить**:
```bash
git add src/**/*.uid
git commit -m "chore: .uid файлы (генерация Godot)"
```
**Не игнорируй** их в `.gitignore` — без них у одноклассника всё разъедется.

---

## Сцена пересохранилась сама после открытия

Godot 4.6 нормализует формат `.tscn` (убирает `unique_id`, упорядочивает
блоки) при первом сохранении. Это безопасно, просто закоммить:
```bash
git add -A
git commit -m "chore: editor reformat"
```

---

## Меч не наносит урон / имп не получает урон (lesson-7+)

1. **Слои** на Hitbox/Hurtbox: меч `collision_layer = 4` (player_hitbox),
   Hurtbox имп `collision_mask = 4`.
2. Слот **`health_component`** в Hurtbox должен указывать на
   `../HealthComponent`.
3. У Hitbox / Hurtbox **обязательно** должен быть дочерний
   `CollisionShape2D` с заданной формой.
4. `class_name Hitbox extends Area2D` — без этой строки `if area is Hitbox`
   всегда даст false.

### Битовые значения слоёв (для тех, кто правит .tscn руками)
| Layer | Bit | Value |
|---|---|---|
| 1 (player) | 0 | 1 |
| 2 (enemy) | 1 | 2 |
| 3 (player_hitbox) | 2 | 4 |
| 4 (enemy_hitbox) | 3 | 8 |
| 5 (world) | 4 | 16 |

В инспекторе обычно ставят галочки, и Godot сам пишет правильное число.

---

## HUD не реагирует на сигналы (lesson-8)

1. `HUD` должен быть **CanvasLayer**, а не Control в корне.
2. В `_ready()` HUD-а должен быть вызов `EventBus.player_hp_changed.connect(...)`.
3. `Player._ready()` после `await get_tree().process_frame` (или просто
   эмит в конце `_ready`) — чтобы HUD уже подписался на момент первого
   эмита. У нас в коде уже сделано — Player эмитит стартовое HP в
   `_ready()` через `_on_hp_changed(...)`.

---

## Игра тормозит после 50+ импов (lesson-9)

Это нормально для прототипа без оптимизаций. Что улучшить дальше:
- Лимит одновременно живых импов в спавнере.
- **Object pooling** — переиспользовать инстансы вместо `instantiate()` /
  `queue_free()`.
- Замена `move_and_slide()` на простой `position += velocity * delta`
  для дешёвых мобов.
