# Архитектура

Устройство кода. Изменил архитектуру (новая система или папка, связи между системами) — обнови этот файл в том же изменении.

## Папки

| Папка | Что в ней |
|---|---|
| `core/time/` | `GameClock` — игровые часы: минута дня, продвижение действиями и прямая установка |
| `office/` | `office.tscn` — сцена кабинета, `OfficeController` — собирает кабинет |
| `office/time_of_day/` | Время суток без представления: `TimeOfDayCycle` (ключевые кадры и смесь соседних), `TimeOfDayBlend` (какие два состояния и в какой доле), `WindowLightsSchedule` (доля горящих окон в домах по кривой на сутки); данные — `office_cycle.tres`, `office_window_lights.tres` |
| `office/view/` | Представление кабинета: `TimeOfDayLayer` (слой с картинкой на каждое состояние) и шейдер `crossfade.gdshader`, `WindowLightsLayer` (горящие окна в домах) и шейдер `window_lights.gdshader`, `TimeOfDayPresenter` (показывает часы светом) |
| `office/art/` | Картинки кабинета: `room/` — комната целиком, окна в домах тёмные; `desk/` — стол отдельным слоем (прозрачный выше строки 648); по одной на состояние: morning, day, sunset, dusk, night. `window_lights/` — огни окон: `window_lights_color.png` (цвет, альфа — маска) и `window_lights_id.png` (номер окна в красном канале) |
| `core/input/` | `InputActions` — имена действий ввода |
| `cases/data/` | Типы содержания дел: `FactDefinition` (факт за смысловой фразой: тип — время, место, человек, вещь, деньги, событие, примета человека, прочее; запись для блокнота; свои вопросы к факту), `QuestionTemplate` (готовый вопрос: к каким типам фактов подходит, кому задаётся — тому, кто сказал, или другому), `QuestionCatalog` (все вопросы по типам плюс универсальный), `KnowledgeEntry` (строка таблицы знаний: факт + вопрос → ответ), `VisitorDefinition` (посетитель: рассказ, таблица знаний, ответы «нечего сказать», реакции на решения), `ReceptionDayDefinition` (факты дня и очередь, проверка содержания) |
| `cases/questions/` | Вопросы по типам фактов и каталог `question_catalog.tres` |
| `cases/test_day/` | Тестовый день: `test_day.tres` (по [docs/cases/test_day.md](cases/test_day.md)), портреты в `art/` |
| `reception/` | Приём без представления: `Reception` (очередь, сказанное, записи, вопросы, решения), `Notebook` + `NotebookEntry` (блокнот: записи по фактам, кто сказал; запись и удаление), `ReceptionRecord` (итог по посетителю), `ReceptionRules` (цена вопроса и пересказа во времени, каталог вопросов; данные — `reception_rules.tres`) |
| `reception/speech/` | Сказанное: `SpeechParser` (делит размеченную реплику на смысловые фразы и обычный текст), `SpeechChunk` (кусок: текст и факт за ним, у обычного текста факта нет), `SpokenLine` (реплика: кто сказал и куски) |
| `reception/view/` | `ReceptionPresenter` — связывает приём с посетителем и панелями |
| `office/view/` (посетитель и стол) | `VisitorView` — посетитель на стуле, входит и уходит анимацией; `DeskItem` — предмет на столе, открывается крупным планом |
| `ui/reception/` | Панели приёма: `SpeechPanel` (плашка с последней репликой посетителя поверх него, кнопка «Расскажите с начала»), `NotebookPanel` (раскрытый блокнот: записи по страницам людей, выбор записи, вопросы к ней, крестик у незакреплённых), `DecisionPanel` (выпадающий список решений, «Оформить», позвать следующего, сколько в коридоре), `SpeechFormatter` (реплика в BBCode: фразы — ссылки с идентификатором факта, записанные подчёркнуты и выделены цветом) |
| `ui/desk/` | `CloseupPanel` — крупный план предмета со стола |
| `ui/debug/` | `ClockDebugPanel` — отладочная панель часов |
| `tools/art/` | Скрипты подготовки арта вне игры: `extract_window_lights.ps1` — достаёт огни окон из пары кадров «с огнями / без огней» |

## Логика и представление

- **Логика** — `GameClock`, `TimeOfDayCycle`, `TimeOfDayBlend`, `WindowLightsSchedule`. Это `RefCounted` и `Resource` без узлов.
  - `GameClock` хранит минуту дня и сообщает сигналами: `time_advanced` (продвинули действием) и `time_set` (выставили напрямую).
  - `TimeOfDayCycle.blend_at(минута)` отдаёт два соседних состояния и долю второго. Между ключевыми кадрами доля сглажена (`smoothstep`).
  - `WindowLightsSchedule.lit_fraction_at(минута)` отдаёт долю горящих окон по кривой (ось X — доля суток).
- **Представление** только слушает часы:
  - `TimeOfDayPresenter` на `time_advanced` плавно догоняет новое время за `transition_duration`, на `time_set` показывает сразу. На каждом шаге раздаёт смесь слоям и долю горящих окон слою огней.
  - `TimeOfDayLayer` передаёт две картинки и долю в шейдер `crossfade.gdshader`. Собственная текстура узла задаёт только размер.
  - `WindowLightsLayer` передаёт долю горящих окон и зерно узора в `window_lights.gdshader`. Шейдер по номеру окна и зерну считает случайный порог: окно горит, когда доля выше порога. Время двигается плавно, поэтому окна вспыхивают по одному. Новое зерно (`reshuffle`) — другой набор и порядок окон.

## Приём

- **Содержание** — ресурсы. В репликах смысловые фразы размечены как `[текст|id]`, у каждого факта есть `note` — что следователь пишет в блокнот. Остальной текст не кликается. Таблица знаний посетителя — строки «факт + вопрос → ответ».
- **`Reception`** (логика, `RefCounted`):
  - `call_next` — следующий из очереди садится и говорит свой рассказ;
  - каждая реплика (`_speak`) разбирается `SpeechParser` на куски и уходит сигналом `visitor_spoke(SpokenLine)`;
  - `toggle_note(факт, кто сказал)` — записать фразу в `Notebook` или убрать, если уже записана; `remove_note(запись)` — убрать крестиком; `retell` — рассказать с начала (стоит `ReceptionRules.retell_minutes`). Убирать можно только записи со слов сидящего напротив: когда он уходит, `Notebook.fix_entries_from` их закрепляет. Блокнот хранит записи по фактам, каждый факт один раз;
  - `get_questions(запись)` — вопросы из `QuestionCatalog`: о записи своего собеседника — по типу факта, свои вопросы факта и универсальный «Расскажите подробнее.»; о записи другого человека — только вопросы-предъявления;
  - `ask(запись, вопрос)` — продвигает `GameClock` на `ReceptionRules.question_minutes`, отвечает строкой таблицы или следующим ответом «нечего сказать» (`fallback_replies` по кругу), запоминает заданный вопрос (`was_asked`);
  - `decide(решение)` — принять, отказать или отговорить. Если отговорить нельзя (`can_be_talked_out`), человек отвечает `talk_out_fail_reply` и остаётся; попытка отмечается в `ReceptionRecord`.
  - Сигналы: `visitor_entered`, `visitor_spoke`, `decision_made`, `visitor_left`. При создании проверяет содержание дня (`ReceptionDayDefinition.validate`) и пишет ошибки в консоль.
- **`ReceptionPresenter`** слушает приём, раздаёт показ `VisitorView`, `SpeechPanel`, `NotebookPanel`, `DecisionPanel`, передаёт их сигналы обратно в `Reception` и обновляет список вопросов при смене выбора, посетителя и после вопроса. `SpeechPanel` и `NotebookPanel` сами слушают `Notebook.entry_added` и `entry_removed`, чтобы выделять записанное и обновлять страницы.
- **Предметы на столе** (`DeskItem`) — кнопки-заглушки в сцене; клик открывает общий `CloseupPanel` с названием и текстом предмета. Закрывается крестиком, Esc (`InputActions.CANCEL`) или повторным кликом.

## Порядок слоёв кабинета

Снизу вверх, как в `office.tscn`: `Room` → `WindowLights` → `Visitor` → `Desk` → `DeskItems` → `NotebookPanel`, `SpeechPanel`, `DecisionPanel` → `CloseupPanel` → `ClockDebugPanel`.

## Связи

- `OfficeController` — корень сцены. В `_ready` создаёт `GameClock` с `day_start_minute`, `Notebook`, `Reception` (день и правила — `@export`) и генератор случайных чисел, перемешивает узор окон и раздаёт: часы — `TimeOfDayPresenter.bind` и `ClockDebugPanel.bind`, приём и блокнот — `ReceptionPresenter.bind`. Корень получает `_ready` последним, поэтому слои уже готовы.
- `ClockDebugPanel` сигналом `window_lights_reshuffle_requested` просит новый узор окон, `OfficeController` передаёт это в `TimeOfDayPresenter.reshuffle_window_lights`. Когда появятся игровые дни, узор будет перемешиваться в начале каждого дня.
- Зависимости на узлы сцены — `@export`-поля, назначенные в `office.tscn`. Узлы внутри своей сцены — через `%UniqueName` (так `ClockDebugPanel` находит свои кнопки и ползунок).
- Порядок картинок в `TimeOfDayLayer.textures` совпадает с порядком `TimeOfDayCycle.keyframe_minutes`. `TimeOfDayPresenter` проверяет совпадение количества при запуске.
