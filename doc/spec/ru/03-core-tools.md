# Встроенные инструменты (core tools)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Обзор

Плагин Redmine MCP предоставляет набор инструментов для работы с проектами, задачами, учётом времени, wiki, форумами, файлами и справочными данными Redmine (чтение и запись).

## Цель

Дать AI-клиентам операции управления проектами, работы с задачами, учёта времени, обнаружения, поиска и wiki, форумов, файловых операций и мета-операций без установки дополнительных плагинов.

## Затронутые области

- Проекты
- Версии
- Участники / роли
- Задачи (CRUD, relations, watchers, notes, categories, form options, dry-run validation, saved queries)
- Учёт времени
- Трекеры, статусы, приоритеты, запросы
- Активность проекта
- Wiki-страницы
- Форумы / сообщения
- Файлы проекта / вложения
- Пользователи
- Права
- Настройки (режим только чтения)

## Бизнес-правила

### Общие правила

- Полное имя инструмента: `redmine_<name>` (например `redmine_get_issue`).
- Результат возвращается в формате JSON-envelope в `structuredContent` и дублируется текстом в `content`.
- Данные фильтруются через видимость проектов/задач и права Redmine.
- Параметр `project` — строка: числовой id в виде строки (например `"1"`) или identifier проекта (например `"ecookbook"`).
- При включённом **Read-only mode** write-инструменты возвращают ошибку. Read-only tools, включая `list_issue_relations`, `get_issue_form_options`, `validate_issue_create`, `validate_issue_update`, остаются доступны.

### Управление проектами

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### Операции с задачами

| Инструмент | R/W | Право |
|------|-----|-------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | атрибуты — если они редактируемы; только `uploads` — если можно добавлять вложения |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` дополнительно `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` на исходном проекте и `add_issues` в целевом |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | запись журнала видима и редактируема (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes` дополнительно `set_notes_private` |
| `set_issue_note_private` | W | запись журнала видима и редактируема, плюс `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Пользователи

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_users` | R | `view_members` + `project`; без `project` — только admin |
| `list_groups` | R | `manage_members` (на любом проекте) или admin |

### Учёт времени

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | запись редактируема текущим пользователем (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### Обнаружение / перечисление

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Поиск и Wiki

| Инструмент | R/W | Право |
|------|-----|-------|
| `search_all` | R | доступ хотя бы к одному из искомых типов (`view_issues` и/или `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; историческая `version` дополнительно `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` и страница должна быть редактируемой |
| `update_wiki_page` | W | `edit_wiki_pages` и страница должна быть редактируемой |
| `delete_wiki_page` | W | `delete_wiki_pages` и страница должна быть редактируемой |
| `rename_wiki_page` | W | `rename_wiki_pages` и страница должна быть редактируемой |

### Форумы

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Файловые операции

| Инструмент | R/W | Право |
|------|-----|-------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files` (или права на контейнер) |
| `get_attachment` | R | права на контейнер вложения |
| `download_attachment` | R | права на контейнер вложения |

### Мета

| Инструмент | R/W | Право |
|------|-----|-------|
| `get_server_info` | R | `use_mcp` |

`get_server_info` возвращает `server_version`, `read_only_mode`, `auth_mode`, краткие данные текущего пользователя и `capabilities.issue_search`. Установка сторонних плагинов в ответе не перечисляется: наличие их MCP-tools видно через `tools/list` и через `capabilities`, которые расширения регистрируют сами.

`capabilities.issue_search` содержит режимы поиска:

| Режим | По умолчанию | Примечание |
|-------|--------------|------------|
| `keyword` | `available: true`, tool `redmine_search_issues` | Всегда |
| `cross_resource` | `available: true`, tool `redmine_search_all` | Всегда |
| `semantic` | `available: false` | Плагины могут заменить через `register_capability(:issue_search, :semantic)` |

При `semantic.available: true` capability ДОЛЖНА включать `tool`, `provider`, а также `use_when` / `avoid_when` — краткие подсказки, когда выбирать семантический поиск. `Registry#apply_capabilities` нормализует ответ provider-а: при нарушении контракта публикуется `{ available: false }`.

### Уточнения

- `delete_issue` без `confirm_delete` возвращает impact preview; при наличии **любых** подзадач (включая невидимые пользователю) нужен `confirm_delete_with_children`. Счётчики в `impact` — только видимые текущему пользователю journals, relations, time entries, children и attachments.
- `search_issues` с `scope=subprojects` требует `project` и ищет в этом проекте и его потомках. Без `project` такой scope — ошибка параметров. `scope=my_project` ограничивает поиск проектами, где пользователь участник.
- `get_issue`: journals, attachments, watchers, relations, children и custom fields включаются только при явном `include_*`. Вложенные списки имеют отдельные `limit`/`offset` и поле `*_pagination` (journals: лимит по умолчанию 25, максимум 100; остальные вложенные списки: по умолчанию и максимум 100). Без соответствующего `include_*` список пустой, пагинация — `null`. Опциональные поля (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) всегда присутствуют в ответе. Custom fields — только видимые текущему пользователю. Журналы — та же видимость, что история задачи в Redmine: запись попадает в `journals` и в `journal_pagination`, только если у неё есть текст или хотя бы одна видимая пользователю деталь изменения. Текст из одних пробелов, табуляций или переводов строки считается пустым. Пустые записи и записи только со скрытыми деталями (включая скрытые custom fields) не входят ни в список, ни в `total_count` / `offset` / `has_more`. Приватные комментарии — свои либо при праве `view_private_notes`. В элементах журнала — только видимые детали изменений. Relations — только связи, обе стороны которых видимы пользователю. То же правило видимости связей — у `list_issue_relations`.
- `get_private_notes` возвращает только приватные комментарии с непустым текстом (пробелы, табуляции и переводы строки без другого содержимого — пустой текст). Страница ограничивается запросом `limit`/`offset` без загрузки всей истории задачи.
- `list_project_issue_custom_fields` возвращает поля, видимые пользователю в проекте. Если задан `tracker_id`, трекер должен принадлежать проекту.
- `copy_issue` требует право копировать задачи на **исходном** проекте и право создавать задачи на **целевом**. Наблюдатели копируются, только если есть право добавлять наблюдателей на целевом проекте. Связь с оригиналом и копирование вложений следуют настройкам Redmine `link_copied_issue` и `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Без переопределения полей копия всё равно проходит правила записи формы. Parent исходной задачи сохраняется, если это допустимо (в том числе при копировании в тот же проект).
- `create_issue_relation` применяет только допустимые атрибуты связи и пишет изменение в журнал задачи. `delete_issue_relation` допускается, только если связь можно удалить текущему пользователю (видимы обе задачи и есть право управлять связями хотя бы на одной стороне); удаление тоже пишется в журнал.
- `add_project_member` / `update_project_member` принимают только роли, которыми текущий пользователь может управлять в проекте. Роль вне этого набора — отказ, роли не назначаются частично.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` — ID principal (пользователь или группа), не только пользователя.
- `delete_file` для вложения задачи следует правилу «можно ли удалять вложения этой задачи» (включая собственные задачи и права трекера), а не только глобальному `edit_issues`. В `tools/list` инструмент виден, если у пользователя может существовать хотя бы одно удаляемое вложение (файлы проекта, задачи или wiki), а не только при глобальном `manage_files`.
- `get_wiki_page`: `attachments` всегда в ответе; по умолчанию `[]` и `attachments_pagination: null`; при `include_attachments=true` — страница вложений с `attachment_limit`/`attachment_offset` (по умолчанию и максимум 100). Историческая `version` требует право видеть правки wiki. Изменение, переименование и удаление защищённой страницы требуют право защищать wiki-страницы.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: по умолчанию summary-поля; полное описание — через `fields` или `get_issue`.
- `create_issue` и `update_issue` принимают явные **атрибуты** задачи (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields` и др.). Все явно переданные атрибуты, включая `subject` и `description` при создании, проходят те же правила записи, что веб-форма Redmine. Перед create/update агенту СЛЕДУЕТ вызывать `get_issue_form_options`, когда допустимые значения полей неизвестны. Явно переданное значение, которое Redmine не применил, даёт ошибку, а не частичный успех.
- Если клиент **не передал** `start_date` в `create_issue` / `validate_issue_create`, а в настройках Redmine включено «дата начала = дата создания» (`default_issue_start_date_to_creation_date`), MCP ставит `start_date` на сегодняшнюю дату пользователя — как форма новой задачи. Явный `start_date` (включая `null`) эту подстановку отключает. `copy_issue` и `update_issue` дату сами не подставляют.
- `update_issue` не принимает `notes`, `private_notes` и `watcher_user_ids`. Комментарий — `add_issue_note`; наблюдатели — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` также поддерживает `uploads` для прикрепления вложений к задаче. Вложения обрабатываются только после успешной проверки атрибутов (включая `rejected_fields`). Вызов только с `uploads` (без атрибутов) допускается, если пользователь может добавлять вложения к задаче — в том числе когда можно комментировать, но нельзя редактировать атрибуты. Опциональный `idempotency_key` защищает повтор после потери ответа (в том числе повторную загрузку тех же файлов). `journal_id` в ответе — запись журнала **этого** вызова, а не последняя запись задачи.
- Чтобы очистить необязательное поле, передайте `null` для `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` или `estimated_hours`. То же для `update_version.due_date` / `wiki_page_title` и `update_issue_category.assigned_to_id`.
- `create_issue` не поддерживает `uploads`.
- `update_issue` принимает `uploads[*].content_base64` и `uploads[*].filename`. После успешной загрузки ответ содержит `added_attachments` — только файлы этого вызова, не полный список вложений задачи. Повреждённый Base64 — ошибка параметров.
- `update_issue` принимает `status_name` и резолвит его в `status_id`.
- `upload_file` принимает `content_base64` (до 20 MiB); обязательны `project`, `filename` и `content_base64`.
- `get_attachment` возвращает `attachment_id`, `filename`, `content_type`, `size` (filesize вложения) и `content_url` (без байтов файла).
- `download_attachment` возвращает `attachment_id`, `filename`, `content_type`, `size` (фактический размер содержимого в байтах) и `content_base64` для одного вложения, видимого текущему пользователю. Если MIME неизвестен — `application/octet-stream`. Не увеличивает счётчик `downloads`. Лимит размера — 10 MiB (проверка `File.size` на диске до чтения и `bytesize` после чтения); при превышении — `FILE_TOO_LARGE`. Пути файловой системы сервера в ответе не возвращаются. `attachment_id` берут из `redmine_get_issue` / `redmine_get_wiki_page` с `include_attachments=true`, `redmine_list_files` или `redmine_get_attachment`. Чтобы прочитать, разобрать или обработать вложение как файл, декодируйте `content_base64` локально. Несуществующее и недоступное вложение дают одинаковый ответ «не найдено».
- `create_time_entry` и элементы `import_time_entries.entries` требуют `hours` и либо `project`, либо `issue_id`. `hours` может быть 0; допустимость нуля и дневного максимума проверяет Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` при создании/обновлении задачи — ID principal (пользователь или группа из `get_issue_form_options.assignees`); `null` снимает исполнителя. `user_id` у `add_issue_watcher` / `remove_issue_watcher` — ID principal (пользователь или группа). В остальных tools `user_id` — ID пользователя. Для текущего пользователя используйте `assignee_ref` или `user_ref` со значением `me`.
- `expected_updated_at` (опционально) на чувствительных update/delete: при расхождении с `updated_on` возвращается `CONFLICT`.
- `idempotency_key` (опционально) на `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`: повтор с тем же ключом и **тем же набором аргументов** (кроме самого ключа) возвращает закешированный успешный результат (TTL 24 ч). Тот же ключ с другим payload — `CONFLICT`, повторная запись не выполняется. Пока первый запрос ещё выполняется, повтор с тем же ключом не выполняет запись ещё раз (маркер «в процессе» живёт те же 24 ч, что и успешный результат). Запись без fingerprint (кэш до этой версии) при том же ключе возвращается как раньше до истечения TTL. Серверный timeout 60 с действует на **чтение**. Операции записи не прерываются серверным timeout, чтобы после успешного сохранения можно было записать результат идемпотентности; клиент может повторить с тем же ключом, если сам потерял соединение. Неожиданное исключение в `import_time_entries` откатывает уже вставленные в этом вызове записи; обычные ошибки валидации отдельных строк по-прежнему собираются без отката успешных.
- `delete_file` по умолчанию удаляет только project/version files; для issue/wiki вложений нужен `confirm_delete_any_attachment=true`.
- List/search используют `limit`/`offset`. Для выборок из БД страница ограничивается на уровне запроса, а не обрезкой уже загруженного полного списка. Любая MCP-коллекция с пагинацией имеет явный стабильный порядок; последним критерием всегда является `id`, чтобы страницы не пропускали и не повторяли элементы.
- Подстроковый поиск (`query`, `login`, `name` и текстовый `search_issues`) ищет символы буквально: `%` и `_` не являются SQL-шаблонами.
- Лимиты MCP: timeout 60 с на read-tools, rate limit 120 запросов/мин на пользователя, HTTP-тело MCP-запроса 36 MiB, максимальный размер JSON args tool 32 MiB, upload base64 до 20 MiB, download base64 до 10 MiB. Повреждённый Base64 в любом `content_base64` — ошибка параметров ещё до выполнения tool.
- Каждый вызов tool, включая отказ в доступе, пишется в structured audit log (tool, user, target IDs, outcome, duration, correlation_id) и учитывается в rate limit; содержимое base64 и private notes не логируется. Target IDs включают в том числе `board_id`, `message_id`, `query_id`, `user_id`, `group_id`.
- `outputSchema` каждого core-tool описывает верхний уровень `data` (для списков — поля элемента `items`), а не открытый произвольный объект. Набор полей схемы совпадает с фактическим ответом: `list_users` без `created_on`, `list_all_users` с `created_on`; `get_attachment` включает `size` и `content_url`. Поля, которые в реальном ответе бывают пустыми, допускают `null` (в том числе `time_entry.issue`, `*_pagination` без include, `estimation_accuracy`, `content_type` вложения). Значения custom fields и `possible_values` не ограничены объектами. `attachments_not_saved` — массив имён файлов.
- `summarize_project_status.days` в схеме: по умолчанию 30, минимум 1, максимум 365.
- `search_all.resources`: не более двух уникальных значений.
- `version_id`, `file_id`, `tracker_id` — целые числа не меньше 1.

### `get_project`

- Вход: `project` (обязателен).
- Выход: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (объект `id`/`name`/`identifier` или `null`), `subprojects` (краткий список видимых дочерних проектов: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent` заполняется, только если родительский проект видим текущему пользователю; иначе `null`.
- Не возвращает участников, включённые модули и статистику задач. Для модулей — `get_project_modules`; для участников — `list_project_members`; для агрегатов задач — `summarize_project_status`.

### `get_issue_form_options`

- Один вызов вместо нескольких справочников перед create/update. Отдельные `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` сохраняются.
- Вход: `project` (обязателен); опционально `tracker_id`, `issue_id`.
- Снимок отражает **форму задачи для текущего пользователя**, а не полную конфигурацию проекта: те же допустимые значения, что предлагает UI Redmine.
- `tracker_id` без `issue_id` задаёт контекст формы создания. Трекер должен быть доступен текущему пользователю для выбора на форме; иначе — ошибка параметров.
- `issue_id` задаёт форму существующей видимой задачи этого проекта. Вместе с `issue_id` параметр `tracker_id` допускается только если он совпадает с текущим трекером задачи; иначе — ошибка параметров (смена трекера через этот tool не моделируется).
- Выход — снимок формы без пагинации:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: трекеры, которые текущий пользователь может выбрать на этой форме (`id`, `name`), а не все трекеры, подключённые к проекту;
  - `priorities`: активные приоритеты (`id`, `name`, `is_default`);
  - `categories`: категории проекта (`id`, `name`);
  - `versions`: версии, доступные для выбора на этой форме (`id`, `name`, `status`, `due_date`);
  - `assignees`: principals, которым можно назначить задачу в контексте этой формы. Элемент: `id`, `name`, `type` (`user` или `group`); для `user` дополнительно `login`. Группы включаются, если в Redmine включено назначение задач группам;
  - `custom_fields`: только поля, которые текущий пользователь может редактировать на форме, с учётом project/tracker, видимости, workflow read-only. Элемент: `id`, `name`, `field_format`, `required` (обязательность поля или required по workflow), `readonly` (всегда `false` в этом списке), `multiple`, `default_value`, `possible_values`, `trackers`. Контекст формы — задача из `issue_id` либо черновик создания с учётом `tracker_id`;
  - `possible_values` — массив объектов `{ "label": "...", "value": "..." }`. Для списков без отдельных подписей `label` совпадает с `value`. Для user/version/enumeration `label` — отображаемое имя, `value` — идентификатор;
  - `statuses`: статусы, допустимые workflow текущего пользователя. Если передан `issue_id` — переходы этой видимой задачи. Без `issue_id` — стартовые статусы для создания (с учётом `tracker_id`, если задан);
  - `editable_fields`: имена атрибутов, которые этот MCP-контракт принимает на create/update и которые текущий пользователь может задать на форме, плюс id редактируемых настраиваемых полей строками. Не включает `notes`, `private_notes`, `watcher_user_ids` и прочие поля веб-формы, которых нет в MCP write-tools;
  - `required_fields`: имена полей, обязательных на этой форме для текущего пользователя, в том же виде имён, что `editable_fields`.
- Несуществующий `tracker_id`, трекер вне допустимых для пользователя, или `issue_id` вне проекта / вне видимости — ошибка параметров.

### `add_issue_note`

- Добавляет комментарий к существующей видимой задаче без изменения атрибутов задачи.
- Вход: `issue_id` (обязателен), `notes` (обязателен), опционально `private_notes`, `uploads` и `idempotency_key`.
- Право: пользователь может добавлять комментарии к этой задаче. `private_notes=true` требует право делать приватные комментарии; иначе — отказ, комментарий не создаётся. Вложения в том же вызове допускаются, если пользователь может добавлять вложения к задаче.
- Не принимает поля задачи и список наблюдателей.
- Выход: `issue_id`, `journal_id`, `notes`, `private_notes`; при `uploads` — `added_attachments` (только файлы этого вызова).
- В Read-only mode недоступен.

### `update_issue_note` / `set_issue_note_private`

- Работают только с записью журнала, которую текущий пользователь **видит** (чужие приватные комментарии без права видеть приватные недоступны).
- Запись должна быть редактируема текущим пользователем (право редактировать комментарии или свои комментарии).
- `update_issue_note.notes` может быть пустой строкой (очистка текста существующей записи). Новый комментарий через `add_issue_note` пустым быть не может.
- Изменение признака приватности (`private_notes` / `is_private`) требует отдельного права делать комментарии приватными; иначе отказ, текст не меняется частично.
- Сохраняется, кто отредактировал запись журнала.
- В Read-only mode недоступны.

### `validate_issue_create` / `validate_issue_update`

- Отдельные read-only tools, не параметр `validate_only` на write-инструментах. Доступны в Read-only mode.
- `validate_issue_create`: те же поля, что `create_issue`, без `idempotency_key`. Обязательны `project` и `subject`. Право `add_issues`.
- `validate_issue_update`: dry-run только для **атрибутов задачи** (как у `update_issue`, без `uploads`). Обязателен `issue_id`. Задача должна быть редактируема текущим пользователем. Перед проверкой создаётся journal context пользователя без записи в БД (как у реального update).
- Поведение: применить атрибуты к задаче без сохранения. Данные Redmine не изменяются.
- Атрибуты по-прежнему проходят через те же правила записи, что веб-форма Redmine. Если клиент **явно передал** значение, а Redmine его не применил, это ошибка MCP, а не успех.
- Явное поле, которого нет среди допустимых для записи на задаче (disabled / workflow read-only / derived dates и т.п.), попадает в `rejected_fields`. Для `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id` и `custom_fields` дополнительно проверяется, что запрошенное значение реально применилось.
- То же правило действует для `create_issue`, `update_issue` и `copy_issue`: запись не выполняется, если явно запрошенное значение не применилось.
- Успех: `{ "valid": true, "errors": [] }`.
- Неуспех: `{ "valid": false, "errors": ["..."] }`. Если часть явных полей не применилась — ещё `rejected_fields` (имена полей, например `["tracker_id"]`) и при типичных ошибках — `missing_required_fields` / `hint` в том же виде, что у create/update.
- Ловятся в том числе: трекер, недоступный текущему пользователю; некорректное или недоступное значение custom field; переход статуса, запрещённый workflow; исполнитель, недоступный для назначения.

### `list_issues` — расширенные фильтры

- Существующие плоские фильтры (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) сохраняются.
- Опциональный `filters`: массив объектов `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` — массив строк; для операторов без значения допускается пустой массив.
- Допустимые `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id`, а также `cf_<id>` для настраиваемых полей задач.
- Операторы — штатные операторы запросов Redmine, в том числе `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. Оператор должен быть допустим для типа поля; иначе — ошибка параметров.
- Неизвестный `field` или недопустимый `operator` — ошибка параметров, запрос не выполняется.
- Плоские фильтры и `filters` комбинируются через AND.
- Фильтры применяются только к видимым текущему пользователю задачам.

### `run_issue_query`

- Вход: `query_id` (обязателен, из `list_queries`); опционально `project`, `fields`, `limit`/`offset`.
- Выполняет сохранённый запрос задач, видимый текущему пользователю. Формат ответа — тот же list-envelope, что у `list_issues`.
- Если запрос привязан к проекту, результаты ограничены этим проектом (и правилами видимости запроса). Опциональный `project` для проектного запроса должен совпадать с проектом запроса, иначе — ошибка параметров.
- Если запрос глобальный, опциональный `project` сужает выборку до этого видимого проекта.
- Невидимый или несуществующий `query_id` — ошибка.
- `list_queries` не выполняет запрос; для выполнения используется `run_issue_query`.

### `list_project_activities`

- Вход: `project` (обязателен); опционально `from`, `to` (даты `YYYY-MM-DD`), `author_id`, `event_types` (массив строк), `limit`/`offset`.
- По умолчанию окно — последние 7 дней (`to` = сегодня, `from` = сегодня минус 6 дней). Максимальная длина окна — 90 дней; при превышении — ошибка параметров.
- События из ленты активности проекта: тип, время, автор (`id`/`name`), `title`, `description`, `url`. Порядок — новые события сначала; при равном времени — больший `id` раньше.
- Envelope как у остальных `list_*`.
- `event_types` ограничивает типы событий. Тип, недоступный пользователю или выключенный в проекте, в выборку не попадает (без ошибки).
- Несуществующий `author_id` — пустой список, не ошибка.

### `summarize_project_status`

Существующие поля сохраняются: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

Окно `days` (по умолчанию 30, диапазон 1–365) по-прежнему влияет на `recent_activity` и на перечисленные ниже метрики периода. Значение вне диапазона отклоняется схемой. `totals` и breakdowns считаются по всем видимым задачам проекта без фильтра по дате, агрегацией на стороне БД, без загрузки всех задач в память. Подпроекты не входят.

Дополнительные поля:

- `overdue_count` — число открытых видимых задач с `due_date` строго раньше сегодняшней даты пользователя.
- `unassigned_count` — число открытых видимых задач без исполнителя.
- `stale_issues_count` — число открытых видимых задач с `updated_on` старше начала окна `days`.
- `issues_closed_during_period` — число видимых задач с `closed_on` внутри окна `days`.
- `estimated_hours` — сумма оценок видимых задач проекта (`null`, если ни у одной нет оценки, иначе число, включая 0).
- `spent_hours` — сумма трудозатрат по видимым задачам проекта (0, если записей нет). Требует право `view_time_entries` на проект; без права поле равно `null`.
- `average_resolution_hours` — среднее `(closed_on - created_on)` в часах для задач, закрытых в окне `days`; `null`, если таких задач нет.
- `estimation_accuracy` — по задачам, закрытым в окне, у которых есть и оценка, и ненулевые/зафиксированные трудозатраты: `{ "issues_count", "total_estimated", "total_spent" }`. Если подходящих задач нет — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Требует `view_time_entries` на проект; без права поле равно `null`.
- `reopened_count` — число видимых задач, у которых в окне `days` в журнале статус сменился с закрытого на открытый. Одна задача учитывается не более одного раза.

Инструмент отдаёт факты, не текстовый «анализ здоровья» проекта.

### `get_version`

- Вход: `version_id` (обязателен); опционально `project`. Если задан `project`, версия доступна, когда она входит в shared-версии этого видимого проекта (даже если исходный проект версии пользователю не виден). Без `project` версия должна быть видима на своём исходном проекте.
- Выход: поля как у элемента `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) плюс агрегаты: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Агрегаты считаются только по задачам версии, видимым текущему пользователю.
- Список задач не возвращается.
- `spent_hours` требует `view_time_entries` на проект версии; без права — `null`. Сумма только по видимым задачам версии и только по трудозатратам, которые текущий пользователь может видеть (в том числе `time_entries_visibility=own`).

### Форумы

- Модуль форумов проекта должен быть включён; иначе ошибка «Boards module is not enabled for this project» (аналог wiki).
- Право `view_messages`. Write-операции форумов отсутствуют.
- `list_boards`: обязателен `project`; пагинация. Элемент: `id`, `name`, `description`, `parent_id` (`null` для корневой доски), `topics_count`, `messages_count`.
- `list_board_topics`: обязателен `board_id`; пагинация. Только корневые сообщения (без родителя). Элемент: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: обязателен `message_id`. Выход: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — краткий список ответов (`id`, `subject`, `author`, `created_on`) без полного текста каждого ответа, с `replies_limit`/`replies_offset` (по умолчанию и максимум 100) и `replies_pagination`.
- Невидимая доска/сообщение или доска другого проекта — ошибка «not found».

### `list_users`

- С `project`: активные **пользователи**-участники проекта (право `view_members`). Membership группы в проекте не попадает в список как группа; пользователи из группы — только если они сами участники. Без `project` — только администратор.
- Элемент: `id`, `login`, `firstname`, `lastname`, `mail`. Не включает `created_on` (это поле есть у `list_all_users`).
- Опциональный `query`: регистронезависимый substring по `login`, `firstname` и `lastname`.
- Опциональный `login` сохраняется (только substring по login) для совместимости. Если заданы и `query`, и `login`, применяются оба условия (AND).

### `list_groups`

- Пагинированный список givable-групп (`id`, `name`), **видимых** текущему пользователю, для выбора `group_id` в `add_project_member`.
- Опциональный `query`: регистронезависимый substring по имени группы; символы `%` и `_` ищутся буквально.
- Право: администратор или `manage_members` хотя бы на одном видимом проекте.
- Не возвращает состав группы и memberships.

### `list_project_member_candidates`

- Кандидаты для добавления в проект: активные видимые пользователи и группы, которые ещё не состоят в проекте.
- Вход: `project` (обязателен); опционально `query` (substring, как в подборе участников Redmine).
- Выход list-envelope: `id`, `name`, `type` (`user` или `group`); для пользователя дополнительно `login`.
- Право `manage_members` на проект.
- `add_project_member`: `user_id` только для пользователя, `group_id` только для группы. ID другого типа — ошибка параметров. Перед добавлением берут ID из этого tool (или из `list_users` / `list_groups`, если кандидат уже известен).

### `list_roles`

- Только роли, которыми текущий пользователь может управлять в указанном проекте.
- Вход: `project` (обязателен).
- Право `manage_members` на проект.
- Для администратора набор совпадает с назначаемыми ролями проекта (без Non member / Anonymous).

## Граничные случаи

- Несуществующий/недоступный проект или задача — `{ "error": "..." }`.
- Read-only mode — `{ "error": "MCP is in read-only mode..." }` для write-инструментов **до** вызова handler, в том числе для инструментов Extension API; validate/form options/list/get остаются доступны.
- Пустой результат list/search — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- List/search с пагинацией всегда возвращают `data.items` и `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Лимит по умолчанию 25, максимум 100.
- Все `list_*` tools (включая справочники: trackers, statuses, roles, queries, boards, board topics и т.д.) используют тот же envelope. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` и validate-tools — одиночные объекты, не list-envelope.
- `download_attachment`: несуществующее и недоступное вложение — одинаковая ошибка «не найдено»; файл на диске нечитаем — ошибка; размер на диске или после чтения выше 10 MiB — `FILE_TOO_LARGE` (лимит не обходится заниженным `filesize` в БД). То же правило неразличимости «нет / нет доступа» — у `get_attachment`.
- `list_project_activities`: окно больше 90 дней — ошибка параметров; `from` позже `to` — ошибка параметров.
- `run_issue_query`: запрос невидим — как несуществующий.
- `get_issue_form_options` с `issue_id` задачи из другого проекта — ошибка параметров.
- `get_issue_form_options` с `issue_id` и `tracker_id`, не равным трекеру этой задачи — ошибка параметров.
- Validate-tools не создают задачу, не обновляют задачу, не создают записи журнала и не расходуют `idempotency_key`.
- Запись через MCP идёт через модели Redmine. Срабатывают model callbacks; controller hooks веб-интерфейса не вызываются.

## Обработка ошибок

- Отсутствие прав — tool не виден в `tools/list` или «Permission denied».
- Ошибки валидации моделей — `{ "error": "<messages>" }` (для issue create/update и validate-tools дополнительно `missing_required_fields` как имена полей по символам ошибок модели, без разбора текста перевода, и `hint`).
- Выключенный модуль wiki/boards — отдельное сообщение об ошибке, не «not found».
- Канонический код ошибки в envelope задаёт обработчик явно; код не выводится из текста сообщения и не зависит от языка пользователя.

## Тестовые сценарии

1. `list_projects` / `list_issues` возвращают envelope `data.items` + `meta` с пагинацией.
2. `get_issue` без `include_*` не отдаёт journals/attachments; с `include_journals` — journals с пагинацией.
3. `search_issues` по тексту находит задачи; `search_all` включает wiki при запросе по нескольким типам.
4. `create_issue` / `update_issue` с валидными полями успешны; без прав или в read-only — ошибка.
4a. `create_issue` без `start_date` при включённой настройке даты начала ставит сегодняшнюю дату; явный `start_date` или `null` не перезаписывается этой настройкой.
5. `delete_issue` без `confirm_delete` возвращает `INVALID_STATE` и impact; с подтверждением удаляет.
6. `create_time_entry` требует `hours` и `project` или `issue_id`; `import_time_entries` принимает пачку.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` работают при включённом модуле Wiki.
8. `upload_file` требует `filename` и `content_base64`; `delete_file` для issue-вложения требует confirm.
9. Пользователь без `use_mcp` не проходит аутентификацию MCP; без права на tool не видит его в `tools/list`.
10. Повтор `create_issue` с тем же `idempotency_key` и теми же аргументами не создаёт дубликат; тот же ключ с другим subject — `CONFLICT`.
11. `download_attachment` для видимого issue-вложения возвращает `content_base64` с `size` фактического содержимого; для файла > 10 MiB на диске (даже при малом metadata) — `FILE_TOO_LARGE`; несуществующее и недоступное вложение неотличимы.
12. `get_project` по identifier возвращает описание, subprojects и `last_activity_date`; недоступный проект — ошибка.
13. `get_issue_form_options` для проекта возвращает trackers/statuses/priorities/categories/versions/assignees/custom_fields и списки `editable_fields` / `required_fields`; `trackers` — только доступные текущему пользователю; с `issue_id` statuses отражают допустимые переходы этой задачи; `issue_id` + другой `tracker_id` — ошибка; `possible_values` — объекты `label`/`value`.
14. `validate_issue_create` с недопустимым tracker или статусом возвращает `valid: false` и `rejected_fields`, не создаёт задачу; в read-only mode вызов успешен.
15. `list_issues` с `filters` (`due_date` `<=` даты, `priority_id` `!`) возвращает только подходящие видимые задачи; неизвестный `field` — ошибка.
16. `run_issue_query` по видимому `query_id` возвращает те же задачи, что сохранённый запрос в UI; невидимый query — ошибка.
17. `list_project_activities` за 3 дня возвращает события проекта с пагинацией; окно 91 день — ошибка.
18. `summarize_project_status` включает `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` и `reopened_count`.
19. `get_version` возвращает агрегаты `open_issues_count` / `completed_percent` без списка задач.
20. `list_boards` / `list_board_topics` / `get_board_message` работают при включённом модуле Boards; при выключенном — ошибка модуля.
21. `list_users` с `project` и `query` по имени находит участника без знания login.
22. `get_issue_form_options` возвращает assignees с `type` user/group и только editable custom fields с `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create` с явно переданным значением, которое Redmine не применяет (включая disabled/read-only core fields, в том числе `description` при создании), возвращают ошибку и не сохраняют частичное изменение.
24. `validate_issue_update` не принимает notes; комментарий создаёт `add_issue_note`. `add_issue_note` с `add_issue_notes` успешен без `edit_issues`; `private_notes` без `set_notes_private` — отказ. `update_issue` только с `uploads` успешен при праве добавлять вложения без `edit_issues`.
25. `list_groups` возвращает givable-группы для пользователя с `manage_members`.
26. `update_issue` с `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` очищает поле, если оно допустимо для записи.
27. `update_issue_note` / `set_issue_note_private` не изменяют чужой приватный комментарий, если у пользователя нет права видеть приватные комментарии.
28. Пользователь с правом редактировать комментарии, но без права делать их приватными, может изменить текст публичного комментария и не может изменить признак приватности.
29. `add_issue_note` с `uploads` создаёт комментарий и вложение одним вызовом; повтор с тем же `idempotency_key` не дублирует их.
30. `update_issue` с `uploads` и `idempotency_key`: повтор с тем же payload не дублирует вложение; другой файл с тем же ключом — `CONFLICT`. Повреждённый Base64 — ошибка параметров.
31. `get_issue` не возвращает скрытые custom fields, невидимые journal details и связи с невидимыми задачами. `get_version` считает агрегаты только по видимым задачам.
32. `copy_issue` без права копировать на исходном проекте — отказ, даже если есть `add_issues` на целевом.
33. `add_project_member` / `update_project_member` с ролью, которой пользователь не управляет, — отказ без частичного назначения.
34. `create_version` / `update_version` с недопустимым для пользователя `sharing` — отказ. `delete_version` для занятой версии — отказ без удаления.
35. Автор записи учёта времени с `edit_own_time_entries` может обновить свою запись через `update_time_entry`.
36. `search_all` доступен пользователю с правом wiki без `view_issues`, если поиск включает wiki.
37. `list_project_member_candidates` возвращает пользователей и группы, которых ещё нет в проекте; `add_project_member` с `user_id` группы — ошибка.
38. `list_roles` для проекта возвращает только роли, которыми пользователь может управлять; без `project` — ошибка схемы. Не включает встроенные Non member и Anonymous.
39. Повтор `copy_issue` / `create_time_entry` с тем же `idempotency_key` не создаёт дубликат; другой payload с тем же ключом — `CONFLICT`.
40. `search_issues` и поиск пользователей/групп по `%` или `_` ищут эти символы буквально, а не как шаблон.
41. `get_version.spent_hours` при `time_entries_visibility=own` считает только свои трудозатраты.
42. `search_issues` с `scope=subprojects` без `project` — ошибка; с `project` находит задачи в потомках.
43. `list_project_activities` отдаёт более новые события раньше более старых.
44. `delete_issue` impact не включает скрытые journals, relations и чужие time entries; скрытые подзадачи всё равно требуют `confirm_delete_with_children`.
45. `get_project` не возвращает родителя, которого текущий пользователь не видит.
46. `update_version` с `due_date`/`wiki_page_title` = `null` очищает поле.
47. `update_issue_category` с `assigned_to_id` = `null` снимает исполнителя по умолчанию.
48. Схема `hours` принимает 0 и значения больше 24; отказ даёт только валидация Redmine.
49. `update_issue_note` с пустым `notes` очищает текст существующего комментария.
50. `list_users` с `project` возвращает только пользователей, даже если в проекте есть membership группы.
51. Историческая версия wiki-страницы без `view_wiki_edits` недоступна; защищённую страницу нельзя изменить без права защищать wiki.
52. `copy_issue` без права добавлять наблюдателей не копирует watchers; настройки `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` запрещают связь и вложения; parent в том же проекте сохраняется.
53. Write-tool расширения в read-only mode не вызывает handler.
54. `delete_file` виден в `tools/list` пользователю, который может удалять вложения задачи, без `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` принимают group principal.
56. `get_version` с `project` возвращает shared-версию, которую отдал `list_versions` этого проекта.
57. `get_issue` / `get_wiki_page` / `get_board_message` ограничивают вложенные списки `limit`/`offset` и отдают `*_pagination`; без include пагинация — `null`.
58. Реальные ответы tools, включая nullable-поля, соответствуют опубликованному `outputSchema`.
59. `get_issue` с `include_journals`: журнал только со скрытой custom-field detail не входит в список и не учитывается в `journal_pagination.total_count`.
60. Скрытый журнал между двумя видимыми не создаёт разрыв страницы: при `journal_limit=2` возвращаются два видимых, `total_count` равен числу видимых.
61. Приватный комментарий другого пользователя не возвращается в `get_issue` без права `view_private_notes`.
62. `get_private_notes` отдаёт страницу по `limit`/`offset` без загрузки всей истории задачи.
63. `get_issue` с журналами `attr`, `cf` и `relation` одновременно не падает и отдаёт только видимые записи.
64. Журнал со скрытой custom-field detail и notes из пробелов, табуляции или перевода строки не входит в `get_issue`.
65. `get_private_notes` не возвращает комментарий из одних пробелов, табуляций или переводов строки.
