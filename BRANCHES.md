# Карта веток репозитория

## Серия `lesson-1` … `lesson-6` — наивная (как в эталонном репо)
Дети проходят шаг за шагом, каждый коммит — одно занятие.
Код «как пишут не задумываясь»: `_process` для физики, без типов, без EventBus.

| Ветка | Содержимое |
|---|---|
| `lesson-1` | Player ходит по WASD на пустой сцене |
| `lesson-2` | Уровень с TileMap, Player инстансом внутри |
| `lesson-3` | Враг Imp догоняет через `get_first_node_in_group` |
| `lesson-4` | Сцена AttackAbility (визуал меча) |
| `lesson-5` | AnimationPlayer + AttackController с автоспавном |
| `lesson-6` | Слои коллизий, имена слоёв, чистка проекта |

## Серия `refactor/lesson-1` … `refactor/lesson-6` — правильная архитектура
То же, но с архитектурными правилами с самого начала.

| Ветка | Что добавляется поверх |
|---|---|
| `refactor/lesson-1` | `_physics_process`, типы, `@export`, именованные слои |
| `refactor/lesson-2` | (без новых правок — кода нет) |
| `refactor/lesson-3` | Кэш игрока в `_ready()`, типизированный Imp |
| `refactor/lesson-4` | (без новых правок — кода нет) |
| `refactor/lesson-5` | **EventBus** + контейнер `Spawned` в уровне |
| `refactor/lesson-6` | **World как точка входа**: Player в World, Imp в Level |

## Где брать методичку

`docs/lesson-N.md` — занятия по порядку. Каждое содержит:
- **Что узнаем (теория)** — определения и принципы.
- **Что делаем (практика)** — пошаговые действия в Godot.
- **Подводные камни** — типовые ошибки, чтобы предусмотреть их.
- **⚙️ refactor/lesson-N** — что добавляется в правильной версии.

В каждой ветке `lesson-N` лежит `docs/lesson-1.md … docs/lesson-N.md`,
прежние сохраняются.

`docs/refactor.md` — обзор всей refactor-серии.

## Как сравнить

```
git diff lesson-3 refactor/lesson-3 -- src/entities/imp/imp.gd
git diff lesson-6 refactor/lesson-6 -- src/levels/
```
