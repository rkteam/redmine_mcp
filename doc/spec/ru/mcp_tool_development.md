# Требования к разработке инструментов Redmine MCP

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Статус:** руководство разработчика (dev-guide), не behavioral SPEC плагина  
**Версия:** 1.6  
**Дата:** 2026-08-20  
**Применимость:** все новые инструменты Redmine MCP и существенные изменения существующих инструментов  
**Базовая версия MCP:** Protocol Revision `2025-11-25`

Поведенческие контракты core tools — в `03-core-tools.md` и связанных SPEC. Этот документ задаёт правила проектирования и реализации tools.

---

## 1. Назначение документа

Документ устанавливает единые требования к проектированию, реализации, описанию, тестированию и публикации MCP-инструментов для Redmine. Архитектурные паттерны реализации вынесены в приложение A и не смешиваются с обязательными требованиями основного текста.

Цель стандарта — сделать инструменты:

- однозначными для выбора языковой моделью;
- безопасными при автоматическом вызове;
- предсказуемыми для MCP-клиентов;
- строго валидируемыми;
- удобными для сопровождения и обратной совместимости;
- устойчивыми к повторным вызовам, ошибкам модели и частично заполненным аргументам.

Требования сформулированы с учётом аудита текущего Redmine MCP. На момент подготовки документа сервер публикует 46 инструментов; в контракте обнаружены параметры без `type`, строковые перечни допустимых значений вместо `enum`, универсальные `manage_*`-инструменты и отсутствие `outputSchema`.

---

## 2. Термины обязательности

В документе используются следующие уровни:

- **MUST / ОБЯЗАН** — обязательное требование. Нарушение блокирует merge.
- **MUST NOT / ЗАПРЕЩЕНО** — обязательный запрет.
- **SHOULD / СЛЕДУЕТ** — требование выполняется по умолчанию; отклонение должно быть обосновано в merge request.
- **MAY / МОЖНО** — допустимый вариант.

Архитектурные и implementation-паттерны, не обязательные для каждого tool, собраны в **приложении A**. Они не блокируют merge, если не приняты осознанно для конкретного инструмента.

---

## 3. Основные принципы проектирования

### 3.1. Один инструмент — одно понятное действие

Инструмент ОБЯЗАН представлять одно атомарное пользовательское намерение.

Хорошо:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Плохо:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Инструменты с параметром вида `action: create | update | delete | list` ЗАПРЕЩЕНЫ, если операции:

- требуют разных обязательных аргументов;
- имеют разные уровни риска;
- должны иметь разные MCP annotations;
- возвращают разные структуры данных;
- требуют разных разрешений Redmine.

Исключение допускается только для семантически однородной операции, когда все варианты имеют одинаковый риск и единый контракт. Исключение должно быть явно обосновано.

### 3.2. Чтение, добавление, изменение и удаление разделяются

В одном tool ЗАПРЕЩЕНО объединять:

- read-only и write-операции;
- добавляющие и удаляющие операции;
- обычные пользовательские и административные операции;
- локальные операции Redmine и отправку данных во внешний мир.

Например, `list/create/delete relation` должны быть тремя отдельными инструментами.

### 3.3. Контракт важнее удобства серверной реализации

Нельзя публиковать структуру внутреннего Ruby/Python/REST-метода напрямую только потому, что так проще реализовать обработчик.

MCP-контракт проектируется для модели и клиента, а адаптер внутри сервера преобразует его в формат Redmine API.

Внутренние технические значения плагина или Redmine ОБЯЗАНЫ нормализоваться, если они не являются частью осмысленного внешнего контракта.

Не публиковать без необходимости:

- имена классов Ruby/Rails и STI-типы;
- внутренние имена enum, если MCP уже использует другое значение на входе;
- locale-зависимые даты;
- REST-specific представления одного и того же поля, если MCP уже задал канонический формат;
- технические названия, когда MCP уже использует нормализованное значение.

Пример: входной фильтр `type` — `contact` / `company`; в ответе тоже `contact` / `company`, а не `Clientdesk::Contact` / `Clientdesk::Company`. Если serializer отдаёт STI-класс или локализованную дату, адаптер MCP ОБЯЗАН привести значение к опубликованной схеме.

### 3.4. Сервер не доверяет модели

Все аргументы считаются недоверенными. Сервер ОБЯЗАН повторно проверять:

- типы;
- диапазоны;
- взаимозависимости полей;
- права текущего пользователя;
- принадлежность объекта проекту;
- доступность значения в конкретном workflow;
- ограничения Redmine;
- допустимость операции в текущем состоянии объекта.

JSON Schema, descriptions, annotations и подтверждения клиента не заменяют серверную проверку.

---

## 4. Именование инструментов

### 4.1. Формат имени

Все публикуемые имена tools ОБЯЗАНЫ начинаться с `redmine_`.

Для core tools плагина `redmine_mcp` используется короткий префикс `redmine_`:

```text
redmine_<verb>_<entity>
```

Для инструментов сторонних плагинов полное имя ОБЯЗАНО начинаться с `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Требования:

- только `lower_snake_case`;
- префикс `redmine_` обязателен для всех tools, включая расширения сторонних плагинов;
- имя уникально в пределах сервера;
- внутренний лимит — не более 64 символов;
- имя не меняется без процедуры deprecation.

Примеры:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Допустимые глаголы

Предпочтительные глаголы:

| Глагол | Назначение |
|---|---|
| `get` | получить один объект по точному идентификатору |
| `list` | получить коллекцию по структурированным фильтрам |
| `search` | выполнить текстовый или полнотекстовый поиск |
| `create` | создать объект |
| `update` | изменить существующий объект |
| `set` | установить конкретное поле или флаг в заданное значение |
| `delete` | удалить объект |
| `add` | добавить связь или участника к существующему объекту |
| `remove` | удалить связь без удаления основного объекта |
| `copy` | создать копию |
| `upload` | загрузить файл |
| `download` | получить содержимое файла |
| `send` | отправить сообщение или данные внешнему адресату |
| `summarize` | построить серверный агрегированный отчёт |

Расплывчатые глаголы (`manage`, `process`, `handle`, `execute`, `do`) не использовать — см. §3.1.

Глагол ОБЯЗАН соответствовать реальной семантике операции. Если инструмент переключает булев флаг (параметр вида `enabled: true | false`), его СЛЕДУЕТ называть через `set`, а не через глагол, подразумевающий только одно значение.

Плохо:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` подразумевает только `enabled = true`, хотя параметр допускает и `false`. Имя не совпадает с фактическим действием.

Хорошо:

```text
redmine_advanced_search_set_semantic_index_enabled
```

Имя `set_*` честно отражает, что операция устанавливает флаг в переданное значение.

### 4.3. Названия идентификаторов

Имя параметра ОБЯЗАНО соответствовать его фактическому типу:

- `issue_id` — только integer ID;
- `project_id` — только integer ID;
- `project_identifier` — строковый identifier Redmine;
- `project` — строка, которая специально допускает оба представления и документирована как reference.

Параметр с названием `*_id` не может принимать строковый identifier или значение `"me"`.

Числовые ID ОБЯЗАНЫ иметь `minimum: 1` и содержательный `description`. Формулировки вроде `"Issue id"` без `minimum` ЗАПРЕЩЕНЫ.

Плохо:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Хорошо:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

Рекомендуемый единый вариант для проекта — параметр `project`, принимающий числовой ID (в виде строки) или строковый identifier:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

Массив `examples` (§6.15) показывает модели обе допустимые формы значения и уменьшает вероятность ошибочного ввода.

### 4.4. Оптимистическая блокировка: `expected_updated_at`

Параметр, который передаёт ранее известный timestamp объекта для отклонения устаревшего изменения, ОБЯЗАН называться `expected_updated_at` во всех core tools и расширениях.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Имя `updated_at` для этого смысла ЗАПРЕЩЕНО: оно выглядит как «новое время изменения», хотя фактически это значение для optimistic locking.

Плохо (checklist и любые расширения):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Хорошо:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Поле ответа, которое сообщает фактическое время изменения объекта, по-прежнему МОЖЕТ называться `updated_at` / `updated_on` — путаница возникает только у входного параметра locking.

Нормативное поведение при конфликте — в приложении A.2.

---

## 5. `title` и `description`

### 5.1. `title`

`title` ОБЯЗАН быть кратким человекочитаемым названием, а не копией технического имени.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Описание инструмента

`description` ОБЯЗАНО кратко отвечать на ключевые вопросы:

1. Что делает инструмент и какой объект читается или изменяется?
2. Что не включается по умолчанию и как это запросить?
3. Есть ли существенные побочные эффекты?
4. Какой предварительный tool вызвать, если ID или допустимое значение неизвестны?

Description ОБЯЗАНО быть кратким и легко читаемым. ЗАПРЕЩЕНО превращать его в длинный абзац на половину страницы с перечислением всех полей и всех include-опций: перегруженное описание модель читает хуже, чем короткое структурированное.

СЛЕДУЕТ писать несколько коротких строк или список, а не сплошной текст. Значения по умолчанию и способ их изменить показываются компактно.

Хороший пример:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

Плохой пример — слишком коротко, не объясняет результат и поведение по умолчанию:

```text
Gets issue.
```

Плохой пример — перегружено, длинный абзац с перечислением всех полей:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. Ссылки на другие tools

Когда description, description параметра или server instructions отсылают к другому инструменту, ОБЯЗАНО указывать полное зарегистрированное имя из `tools/list`, а не короткий `name` без префикса.

Плохо:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Хорошо:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

Короткие имена неоднозначны между плагинами и заставляют модель угадывать префикс. Это особенно важно для расширений: `semantic_search_issues` без префикса `redmine_advanced_search_` легко перепутать с несуществующим core-tool.

### 5.2.2. Описание возвращаемого результата

Description ОБЯЗАНО кратко объяснять результат инструмента, чтобы модель понимала, достаточно ли одного вызова или потребуется следующий tool.

Описание результата должно указывать:

- возвращается один объект, коллекция, агрегат, подтверждение изменения или ссылка на ресурс;
- какие связанные данные включаются по умолчанию;
- какие большие или чувствительные данные не включаются без явного параметра;
- есть ли пагинация и каков её стандартный предел;
- возвращает ли write-tool обновлённый объект целиком или только идентификатор, URL и время изменения;
- возможен ли частичный успех для массовой операции.

Пример для чтения:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

Пример для списка:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

Пример для записи:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

Про связь description и `outputSchema` — см. §7.1 и §7.1.1. Если list уже возвращает поле, description НЕ ДОЛЖЕН отправлять модель к `get_*` только ради этого поля.

### 5.3. Описание не заменяет схему

ЗАПРЕЩЕНО задавать ограничения только текстом:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Нужно использовать `enum`, `const`, диапазоны и условные схемы.

То же относится к взаимоисключающим полям. Если `description` говорит «exactly one of `user_id` or `group_id`», а `required` содержит только общие поля — схема и текст расходятся. Ограничение ОБЯЗАНО быть формализовано в `inputSchema` (§6.12).

### 5.4. Предсказуемость выбора

Descriptions похожих инструментов должны явно объяснять отличие.

Например:

- `redmine_list_project_members` — участники конкретного проекта и их роли;
- `redmine_admin_list_users` — глобальный список пользователей инсталляции, требует административных прав.

### 5.5. Instructions на уровне сервера

Сервер МОЖЕТ публиковать краткие общие instructions, которые объясняют связи между инструментами и правила рабочего процесса.

Instructions должны добавлять контекст, которого нет в отдельных descriptions, и ссылаться на tools полными именами (§5.2.1), например:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

ЗАПРЕЩЕНО:

- повторять в server instructions descriptions всех tools;
- помещать туда общие инструкции поведения модели, не связанные с сервером;
- писать длинное руководство вместо кратких правил маршрутизации;
- использовать маркетинговые утверждения;
- ссылаться на tools короткими именами без префикса (`list_projects` вместо `redmine_list_projects`).

### 5.6. Изучение Redmine REST API перед разработкой

Перед созданием или существенным изменением инструмента разработчику СЛЕДУЕТ провести документационную разведку. Не рекомендуется проектировать контракт только по существующему MCP-коду, памяти разработчика или одному примеру HTTP-запроса.

СЛЕДУЕТ изучить:

1. Главную страницу Redmine REST API: общие правила аутентификации, пагинации, `include`, custom fields, файлов и validation errors.
2. Отдельную страницу API соответствующего ресурса, например Issues, Time Entries, Versions, Wiki Pages или Project Memberships.
3. Раздел API change history и изменения для поддерживаемых версий Redmine.
4. Фактическую версию Redmine, с которой работает MCP, и минимальную поддерживаемую версию.
5. REST API и исходный код используемых Redmine-плагинов, если инструмент работает с сущностью или полями плагина. Перед публикацией extension tool ОБЯЗАТЕЛЬНО проверить исходный serializer / service / REST endpoint и минимум один реальный успешный ответ для каждой формы результата (list и get, если оба публикуются).
6. Реальные права, workflow, включённые модули, trackers, custom fields и ограничения целевой инсталляции.
7. Уже опубликованные MCP-tools, чтобы не создать дубликат или конфликтующий контракт.

Главная страница `https://www.redmine.org/projects/redmine/wiki/rest_api` является точкой входа, но обычно недостаточна для конкретного tool. СЛЕДУЕТ перейти на страницу соответствующего ресурса и проверить операции, query-параметры, `include`, поля запросов, структуру ответов, коды ошибок и ограничения версии.

### 5.7. Отчёт о покрытии API

До реализации нового tool разработчику СЛЕДУЕТ приложить к merge request краткую таблицу покрытия API:

| Поле | Содержание |
|---|---|
| Redmine resource | Ресурс и ссылка на официальную страницу API |
| Endpoint | HTTP method и path |
| Supported since | Минимальная версия Redmine |
| Request parameters | Все документированные параметры запроса |
| Query filters | Все документированные фильтры и специальные значения |
| Include values | Допустимые связанные данные |
| Required/defaults | Обязательные поля и значения по умолчанию |
| Response | Основные поля и варианты ответа |
| Errors | HTTP-коды и структура ошибок |
| Permissions | Требуемые права и особенности impersonation |
| MCP exposure | Какие параметры опубликованы в MCP |
| Intentionally omitted | Какие параметры не опубликованы и почему |
| Plugin/version differences | Отличия плагинов и поддерживаемых версий |

Цель таблицы — не обязательно опубликовать в MCP каждый параметр Redmine. Цель — не забыть параметры случайно и принимать решение об их публикации осознанно.

Параметр Redmine может быть исключён из MCP, если он:

- опасен или административен;
- дублирует отдельный более понятный tool;
- нестабилен между поддерживаемыми версиями;
- создаёт неоднозначную схему;
- не нужен целевым пользовательским сценариям;
- приводит к чрезмерно большим ответам.

Каждое существенное исключение фиксируется в `Intentionally omitted` с кратким обоснованием.

### 5.8. Инструкция для ИИ-агента, разрабатывающего tools

Если tool создаёт или изменяет ИИ-агент, в рабочей инструкции СЛЕДУЕТ отсылать к этому документу: исследование API (§5.6–5.7), контракт (§3–§8), тесты (§13), checklist (§14).

Рекомендуемый текст:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. Требования к `inputSchema`

### 6.1. Базовая структура

Каждый инструмент ОБЯЗАН иметь валидную JSON Schema.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

Для инструмента без аргументов:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Запрет неописанных свойств

На верхнем уровне и во всех вложенных объектах ОБЯЗАТЕЛЬНО:

```json
"additionalProperties": false
```

Открытый словарь допускается только осознанно. В этом случае схема значений задаётся явно:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Тип каждого параметра

Каждое свойство ОБЯЗАНО содержать `type`, `$ref` или композицию `oneOf` / `anyOf` / `allOf`.

ЗАПРЕЩЕНО:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Обязательные параметры

Массив `required` должен отражать минимально исполнимый вызов.

Если без параметра операция невозможна, параметр ОБЯЗАН быть в `required`.

Например, загрузка файла требует как минимум:

```json
"required": ["project", "filename", "content_base64"]
```

Проверка `confirm=true` для удаления выполняется на сервере (§3.4), даже если поле в `required`.

### 6.5. Перечисления

Для конечного набора значений ОБЯЗАТЕЛЬНО использовать `enum` или `const` (не только текст в description — см. §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Строки

Строки должны иметь подходящие ограничения:

- `minLength` для непустых значений;
- `maxLength` согласно ограничениям Redmine или внутренним лимитам;
- `pattern`, когда формат строго определён;
- `format`, когда применим стандартный формат.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

Ограничение `format` в схеме не заменяет серверную проверку (§3.4).

### 6.7. Числа

Для числовых параметров ОБЯЗАТЕЛЬНО задавать разумные границы.

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

```json
"hours": {
  "type": "number",
  "exclusiveMinimum": 0,
  "maximum": 24
}
```

Значение `default` является частью контракта и документации. Сервер не должен предполагать, что клиент сам подставит default.

### 6.8. Массивы

Каждый массив ОБЯЗАН иметь `items`.

При необходимости задаются:

- `minItems`;
- `maxItems`;
- `uniqueItems`.

```json
"role_ids": {
  "type": "array",
  "minItems": 1,
  "maxItems": 20,
  "uniqueItems": true,
  "items": {
    "type": "integer",
    "minimum": 1
  }
}
```

Массив вида `entries: array` без схемы элемента ЗАПРЕЩЁН.

### 6.9. Вложенные объекты

Все вложенные объекты описываются полностью.

```json
"custom_fields": {
  "type": "array",
  "items": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "id": {"type": "integer", "minimum": 1},
      "value": {
        "oneOf": [
          {"type": "string"},
          {"type": "number"},
          {"type": "boolean"},
          {
            "type": "array",
            "items": {"type": "string"}
          }
        ]
      }
    },
    "required": ["id", "value"]
  }
}
```

### 6.10. Нельзя принимать «object или JSON string»

ЗАПРЕЩЕНО описывать один параметр как «object or JSON string».

MCP уже передаёт структурированный JSON. Инструмент должен принимать объект, а не строку, которую сервер затем повторно парсит.

### 6.11. Универсальные `fields` и `extra_fields`

Параметры `fields`, `extra_fields`, `payload`, `data` и аналогичные открытые объекты ЗАПРЕЩЕНЫ для основных бизнес-операций.

Поля задачи должны быть перечислены явно, с содержательным `description` (§6.14) и, где полезно, `examples` (§6.15):

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker ID returned by redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue priority ID returned by redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "User ID of the assignee, from redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Target version ID returned by redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numeric ID of the parent issue."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

Редко используемые поля допускается передавать через строго описанный `custom_fields`.

### 6.12. Взаимозависимые поля

Предпочтительно разделить инструменты. Если разделение невозможно, зависимость формализуется через:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` с взаимоисключающими ветками.

Текст в `description` («exactly one of …») не заменяет схему (§5.3).

Типичный случай — «ровно одно из двух полей». Плохо: `required` перечисляет только общие поля, а XOR остаётся в prose:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {"type": "string", "minLength": 1},
    "user_id": {"type": "integer", "minimum": 1},
    "group_id": {"type": "integer", "minimum": 1},
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "integer", "minimum": 1}
    }
  },
  "required": ["project", "role_ids"]
}
```

Такая схема допускает вызов без `user_id`/`group_id` и вызов с обоими полями сразу.

Хорошо — общий `required` плюс верхнеуровневый `oneOf`:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "User ID from redmine_list_users to add as a project member."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Group ID to add as a project member."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Role IDs from redmine_list_roles."
    }
  },
  "required": ["project", "role_ids"],
  "oneOf": [
    {
      "required": ["user_id"],
      "not": {"required": ["group_id"]}
    },
    {
      "required": ["group_id"],
      "not": {"required": ["user_id"]}
    }
  ]
}
```

Серверная проверка (§3.4) всё равно ОБЯЗАНА отклонять оба некорректных варианта. Схема нужна, чтобы клиент и модель видели ограничение до вызова.

Необходимо проверить совместимость выбранных конструкций с поддерживаемыми MCP-клиентами и SDK.

### 6.13. Поля со значением `null` и очистка значений

`null` допускается только когда он имеет отдельный документированный смысл, например «очистить срок» или «снять назначение».

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "New due date in YYYY-MM-DD format, or null to clear it."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Assignee user ID from redmine_list_users, or null to unassign."
}
```

Не следует использовать пустую строку как неявный эквивалент `null`.

Для `set_*`-инструментов, которые устанавливают необязательное поле (срок, assignee и т.п.), контракт ОБЯЗАН явно решать вопрос очистки. Допустимы три варианта — в порядке предпочтения:

1. **Тот же tool принимает `null`** (предпочтительно), как выше: одно намерение «установить или очистить».
2. **Отдельный clear/unassign tool**, если API или UX лучше разделяют операции, например `redmine_advanced_search_clear_saved_query` и `redmine_advanced_search_unassign_search_owner`.
3. **Явный отказ**: если очистка через MCP не поддерживается, это ОБЯЗАНО быть сказано в `description` инструмента и/или параметра. Молчаливый контракт «только string/integer без null» без пояснения ЗАПРЕЩЁН — модель будет ошибочно считать, что очистить поле нельзя или попытается передать `""` / `0`.

Плохо — поставить срок можно, снять нельзя, и это нигде не сказано:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Описания параметров

Каждый параметр в `inputSchema.properties` ОБЯЗАН иметь содержательный `description`. Параметры без `description` ЗАПРЕЩЕНЫ, в том числе у расширений (checklist item `done`, `sort_order`, `due_date`, ID-поля и т.д.) и у опциональных полей с понятным `enum`.

Описание типа «Filter by tracker ID», «Tracker id» или «Issue id» недостаточно: оно не подсказывает модели, откуда взять допустимое значение и какие есть ограничения.

Описание параметра-идентификатора ОБЯЗАНО указывать, каким инструментом или полем ответа получить допустимое значение (полным именем — §5.2.1; discovery — §6.16), и отмечать существенные ограничения (workflow, права, принадлежность проекту).

Плохо:

```json
"tracker_id": {
  "type": "integer",
  "description": "Filter by tracker ID."
}
```

```json
"done": {
  "type": "boolean"
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]}
}
```

Хорошо:

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker ID returned by redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true marks the item done; false marks it undone."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "User ID from redmine_list_users to add as a project member."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Resource types to search. Omit to search all supported resource types."
}
```

Хорошо, с указанием ограничения:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

Описание параметра не заменяет схему (§5.3) и серверную проверку (§3.4).

### 6.15. Примеры значений (`examples`)

Для параметров, где формат значения неочевиден или допускает несколько представлений, СЛЕДУЕТ добавлять `examples` — стандартный ключевой массив JSON Schema. Примеры помогают модели ввести корректное значение и особенно полезны для reference-параметров, идентификаторов, дат и enum-подобных строк.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format.",
  "examples": ["2026-07-30"]
}
```

Требования:

- значения `examples` ОБЯЗАНЫ быть валидны по самой схеме параметра;
- `examples` иллюстрируют формат, но не подменяют `enum`, диапазоны и прочие ограничения (§5.3, §6.5);
- для параметров с `enum` отдельные `examples` обычно избыточны.

Если MCP-клиент или SDK не поддерживает `examples` в схеме, допускается использовать `x-examples` как расширяющий ключ с той же семантикой.

### 6.16. Discovery path для ID-параметров

Параметр вида `*_id`, который модель не может угадать, ОБЯЗАН иметь явный discovery path: отдельный read/list-tool или поле ответа другого read-tool, на которое указывает `description` параметра (§6.14).

Допустимые варианты (в порядке предпочтения для набора tools):

1. **Отдельный list/discovery-tool** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Опции внутри ответа get/list** — например массив провайдеров с `id` и `name` в ответе `redmine_advanced_search_semantic_search_issues`. Тогда description ОБЯЗАН сослаться на это поле ответа полным именем tool.
3. **Стабильный enum в схеме**, если набор значений фиксирован и мал.

ЗАПРЕЩЕНО публиковать write-tool с `status_id` / `role_ids` / аналогом, если ни один из вариантов выше не выполнен: модель вынуждена угадывать ID.

Плохо — write без discovery:

- есть `redmine_advanced_search_set_search_provider` с `provider_id`;
- нет `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` возвращает только имя текущего провайдера (`provider: "…"`), без списка допустимых значений и без их `id`.

В таком случае description вида `"Search provider ID."` недостаточен. Нужно либо добавить list-tool, либо включить опции провайдеров в ответ get и написать, например:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

Правило относится и к core, и к расширениям (§18).

---

## 7. Требования к `outputSchema` и результатам

### 7.1. Схема outputSchema

Новый инструмент ОБЯЗАН публиковать `outputSchema`. Схема описывает стабильный публичный контракт ответа, а не только форму envelope `{ ok, data | error }`.

Если `description` утверждает, что инструмент возвращает именованные поля или вложенную структуру, `outputSchema` ОБЯЗАН формализовать эти поля, а не ограничиваться верхним уровнем `data` / `items` как «произвольный object».

Плохо: description перечисляет `query`, `results`, snippets и attachment excerpts, а `outputSchema` отсутствует или описывает `items` только как `{ "type": "object", "additionalProperties": true }`.

Для каждого стабильного поля результата:

- ОБЯЗАН быть указан тип;
- гарантированно присутствующее поле ОБЯЗАНО входить в `required`;
- конечный набор значений ОБЯЗАН быть задан через `enum` или `const`;
- дата ОБЯЗАНА иметь `format: date` или `date-time`, если сервер гарантирует соответствующий формат;
- числовой ID ОБЯЗАН сохранять единый тип;
- nullable и optional — разные контракты: если поле всегда возвращается, но может не иметь значения, оно должно быть `required` и допускать `null`;
- для числовых бизнес-значений ОБЯЗАНЫ быть указаны единицы измерения, если они не очевидны из имени поля;
- денежное значение ОБЯЗАНО иметь однозначную семантику: major/minor units и способ определения валюты.

`additionalProperties: true` НЕ ДОЛЖЕН использоваться вместо описания известных стабильных полей результата. Он допустим для обратной совместимости или реально расширяемых структур, но известные бизнес-поля внутри такого объекта всё равно должны быть перечислены в `properties`, а гарантированные — в `required`.

Для list-tools элементы `items` ОБЯЗАНЫ описывать как минимум поля, необходимые модели для идентификации, фильтрации и последующих вызовов tools.

Хорошо — фрагмент типизации `data` (полный success/error envelope — §7.2 и §12):

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ok": {"type": "boolean"},
    "data": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "query": {"type": "string"},
        "results": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": true,
            "properties": {
              "id": {"type": "integer"},
              "subject": {"type": "string"},
              "url": {"type": "string"}
            },
            "required": ["id", "subject"]
          }
        }
      },
      "required": ["query", "results"]
    }
  },
  "required": ["ok"]
}
```

Результату СЛЕДУЕТ возвращать:

- `structuredContent` — машинно-читаемый объект, если клиентам нужна стабильная структура;
- текстовый `content` — краткое представление для обратной совместимости и человека.

### 7.1.1. Согласованность публичного контракта

Перед завершением tool разработчик ОБЯЗАН сверить три представления:

1. фактический ответ handler / REST / service;
2. `description` инструмента;
3. `outputSchema`.

Они не должны противоречить друг другу.

Если description говорит, что поле возвращается всегда, оно должно быть `required` в `outputSchema`.

Если schema задаёт `enum` / `const` / `format`, фактический serializer ОБЯЗАН нормализовать значение к этому контракту. Нельзя публиковать `format: date` и одновременно обещать locale-formatted строку.

Если list уже возвращает данные, description НЕ ДОЛЖЕН отправлять модель к get-tool только ради этих же данных.

Бизнес-инварианты результата ОБЯЗАНЫ быть отражены схемой через `const`, `enum`, `required` или условную schema, а не только следовать из имени tool. Пример: если subscription-tool по определению возвращает только продукты типа `subscription`, `product_type` должен быть `const: "subscription"`, а не `enum` с невозможными значениями.

### 7.2. Единый envelope

Рекомендуемый успешный результат:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Ошибка:

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "status_id 17 is not available for tracker 3",
    "field": "status_id",
    "retryable": false
  }
}
```

При ошибке дополнительно устанавливается:

```json
"isError": true
```

Если публикуется `outputSchema` и error также возвращается в `structuredContent`, схема ОБЯЗАНА описывать обе ветки — success и error. Нельзя публиковать success-only schema и возвращать несовместимый структурированный объект ошибки. Альтернатива: при tool execution error вернуть только текстовый `content` с `isError: true` и не возвращать `structuredContent`. Предпочтительный вариант — единый типизированный envelope с двумя ветками.

### 7.3. Стабильность полей

Выходные поля являются публичным контрактом. ЗАПРЕЩЕНО:

- менять тип поля без major-изменения;
- переименовывать поле без периода deprecation;
- иногда возвращать объект, а иногда массив;
- возвращать ID то числом, то строкой;
- возвращать неограниченный необработанный ответ Redmine API.

### 7.4. Результат одного объекта

Рекомендуемый формат:

```json
{
  "ok": true,
  "data": {
    "id": 12345,
    "subject": "Fix authorization error",
    "status": {"id": 2, "name": "In Progress"},
    "project": {"id": 10, "identifier": "bank-site", "name": "Bank Site"},
    "url": "https://redmine.example/issues/12345",
    "updated_at": "2026-07-22T09:20:00Z"
  }
}
```

### 7.5. Результат списка

```json
{
  "ok": true,
  "data": {
    "items": []
  },
  "meta": {
    "total_count": 143,
    "limit": 25,
    "offset": 0,
    "next_offset": 25,
    "has_more": true
  }
}
```

Схема элемента `items` подчиняется §7.1: идентификаторы, routing-поля и стабильные бизнес-поля описываются явно. Пустой `{ "type": "object", "additionalProperties": true }` как единственное описание элемента ЗАПРЕЩЁН.

### 7.6. Минимально необходимый объём

List/search-инструменты должны по умолчанию возвращать краткие записи. Полное описание, журналы, вложения и большие текстовые поля следует получать отдельным `get_*`.

Это уменьшает токены, задержку и риск передачи лишних чувствительных данных.

### 7.7. Чувствительные данные

Результат не должен содержать без явной необходимости:

- API-токены;
- Authorization headers;
- cookies;
- пути файловой системы сервера;
- внутренние stack traces;
- пароли и секреты;
- поля Redmine, недоступные текущему пользователю;
- приватные заметки, если нет отдельного разрешения.

---

## 8. MCP-аннотации

Annotations являются подсказками клиенту и не являются механизмом авторизации или защиты.

### 8.1. Матрица значений

| Тип операции | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Получить/найти/перечислить данные Redmine | `true` | `false` | `true` | `false` |
| Создать задачу/версию/чеклист | `false` | `false` | `false` | `false` |
| Добавить комментарий/watcher/relation | `false` | `false` | `false` | `false` |
| Изменить поле, переименовать, установить флаг (`update`, `rename`, `set`) | `false` | `false` | зависит от реализации | `false` |
| Удалить, очистить, сбросить (`delete`, `purge`, `reset`) | `false` | `true` | только при гарантированной идемпотентности | `false` |
| Отправить email внешнему адресату | `false` | `false` | `false` | `true` |
| Обратиться к произвольному URL / внешней системе | зависит | зависит | зависит | `true` |

### 8.2. Правила

- `readOnlyHint: true` ставится только если инструмент не меняет состояние и не вызывает побочных эффектов.
- `destructiveHint` описывает необратимую потерю или уничтожение данных, а не сам факт записи. `destructiveHint: true` СЛЕДУЕТ ставить только необратимым операциям — `delete`, `purge`, `reset`, полная очистка поля или связи.
- Обычные `update`, `rename` и `set` НЕ являются destructive: для них `destructiveHint: false`. Например, `update_checklist_title` или `rename_wiki_page` — это обычное обновление, а не разрушение, и destructive-аннотация к ним ошибочна.
- `idempotentHint: true` ставится только если повторный вызов действительно безопасен; СЛЕДУЕТ подтвердить это тестом.
- `openWorldHint` описывает, обращается ли инструмент к открытому, заранее неизвестному внешнему миру, а не к тому, создаётся ли новый объект. Работа с одной сконфигурированной инсталляцией Redmine — это закрытый мир: `openWorldHint: false`.
- Поэтому `create_issue`, `create_time_entry` и другие write-инструменты в пределах своего Redmine используют `openWorldHint: false`, несмотря на создание новых объектов. Создание объекта в известной системе не делает мир открытым.
- `openWorldHint: true` ставится только когда адресат или источник данных не ограничен известной системой: отправка email внешнему адресату, произвольный HTTP-запрос, обращение к внешнему сервису.
- Значение `openWorldHint` СЛЕДУЕТ проставлять осознанно для каждого инструмента, а не копировать по умолчанию: проверьте, действительно ли инструмент выходит за пределы своей инсталляции Redmine.
- Нельзя копировать один набор annotations на все write-tools.

### 8.3. Побочные эффекты Redmine

При оценке идемпотентности учитываются не только итоговые поля, но и:

- создание journal-записи;
- отправка уведомлений;
- webhooks;
- audit log;
- повторная загрузка файла;
- повторное создание relation;
- повторное начисление трудозатрат.

Если повторный вызов создаёт дополнительную запись или уведомление, инструмент неидемпотентен.

---

## 9. Безопасность

### 9.1. Авторизация

Каждый вызов ОБЯЗАН выполняться в контексте аутентифицированного пользователя или явно документированной сервисной учётной записи.

Сервер ОБЯЗАН проверять Redmine permissions для конкретного проекта и объекта. Наличие tool в `tools/list` не означает разрешение на операцию.

Административные инструменты следует:

- публиковать только администраторам;
- либо выносить в отдельный административный MCP profile/server;
- либо защищать отдельным scope.

### 9.2. Минимальные права

MCP-сервер и Redmine API token должны иметь минимально необходимые права. Нельзя использовать глобальный административный токен для всех пользователей, если требуется сохранение пользовательской модели доступа.

### 9.3. Произвольные пути файловой системы запрещены

Параметры вида:

```json
{"file_path": "/etc/app/.env"}
```

ЗАПРЕЩЕНЫ в публичных MCP-инструментах.

Безопасные варианты:

1. `content_base64` с лимитом размера;
2. opaque `upload_token`, выданный доверенным upload-механизмом;
3. MCP resource URI, доступ к которому проверяет host;
4. файл только из выделенного временного каталога с проверкой `realpath` и allowlist.

Сервер ОБЯЗАН проверять:

- максимальный размер;
- MIME type;
- допустимое расширение;
- имя файла;
- отсутствие path traversal;
- антивирусную/контентную проверку, если это требуется политикой организации.

### 9.4. Произвольные URL и SSRF

Инструмент не должен принимать произвольный URL, если это не является его основной задачей.

При необходимости HTTP-доступа:

- использовать allowlist доменов и схем;
- запрещать loopback, link-local, metadata endpoints и внутренние сети, если они не нужны;
- ограничивать redirects;
- задавать timeout и лимит ответа;
- не передавать внутренние credentials на другой origin.

### 9.5. Удаление и опасные операции

Для необратимых операций ОБЯЗАТЕЛЬНО:

- отдельный tool;
- `destructiveHint: true`;
- явное описание необратимости;
- точная серверная проверка прав;
- audit log;
- защита от удаления объекта за пределами ожидаемого проекта;
- проверка дочерних объектов и связанных последствий.

Boolean `confirm_delete: true` МОЖНО использовать как дополнительную защиту от случайного вызова, но нельзя считать механизмом авторизации.

Двухфазное удаление, optimistic locking и idempotency key — см. приложение A.

### 9.6. Логи

В audit log фиксируются:

- имя инструмента;
- аутентифицированный пользователь;
- ID целевого проекта/объекта;
- результат;
- длительность;
- код ошибки;
- correlation ID запроса.

ЗАПРЕЩЕНО логировать:

- access token;
- Authorization header;
- cookies;
- base64-содержимое файлов;
- секретные custom fields;
- полный текст приватных заметок без отдельной необходимости.

### 9.7. Rate limit и timeout

Каждый tool ОБЯЗАН иметь:

- ограничение размера входа;
- rate limit на пользователя/токен;
- лимит количества возвращаемых записей;
- ограничение массовых операций.

Серверный timeout 60 с действует на read-tools. Write-tools не прерываются серверным timeout, чтобы после успешного сохранения можно было зафиксировать результат идемпотентности.

---

## 10. Ошибки

### 10.1. Разделение ошибок

Используются два уровня:

1. **Protocol error** — неизвестный tool, повреждённый JSON-RPC, невозможность обработать MCP-запрос.
2. **Tool execution error** с `isError: true` — ошибка аргумента, Redmine API, прав, workflow или бизнес-логики.

Ошибки, которые модель может исправить изменением аргументов, должны возвращаться как tool execution errors.

### 10.2. Структура ошибки

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "User cannot edit issues in project bank-site.",
    "field": null,
    "retryable": false,
    "details": {
      "project": "bank-site",
      "required_permission": "edit_issues"
    }
  }
}
```

### 10.3. Рекомендуемые коды

```text
VALIDATION_ERROR
NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
REDMINE_API_ERROR
TIMEOUT
FILE_TOO_LARGE
UNSUPPORTED_MEDIA_TYPE
INVALID_STATE
PARTIAL_FAILURE
INTERNAL_ERROR
```

### 10.4. Сообщение должно быть исправимым

Плохо:

```text
Invalid request.
```

Хорошо:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Не возвращать пользователю stack trace. Stack trace сохраняется только в защищённом серверном логе с correlation ID.

---

## 11. Пагинация и объём данных

### 11.1. Инструменты list/search

ОБЯЗАТЕЛЬНЫ параметры:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

Для существующего Redmine API допускается `offset`. При собственной реализации предпочтителен opaque cursor, если данные могут активно меняться во время обхода.

### 11.2. Метаданные пагинации

Результат должен содержать:

- фактический `limit`;
- `offset` или `next_cursor`;
- `has_more`;
- `total_count`, если его получение не создаёт значительной нагрузки.

### 11.3. Выбор полей

Параметр `fields` допускается только как массив из закрытого allowlist:

```json
"fields": {
  "type": "array",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": ["id", "subject", "status", "assignee", "updated_at"]
  }
}
```

Нельзя передавать произвольные имена полей непосредственно в SQL, ActiveRecord `select`, serializer или Redmine API без allowlist.

### 11.4. Большие результаты

Большие журналы, вложения и файлы должны:

- иметь отдельную пагинацию;
- возвращаться отдельным tool/resource;
- для бинарных данных по возможности возвращать resource link или иной ограниченный reference вместо встраивания большого base64 в ответ;
- либо поддерживать task-augmented execution, если операция действительно длительная и клиент это поддерживает.

`execution.taskSupport` не указывается автоматически. По умолчанию используется `forbidden`.

---

## 12. Эталон нового инструмента

Сокращённый пример write-tool с обязательным `title` и типизированным `outputSchema` по §7.1. Формат ошибок — §10. Полный JSON — в приложении B.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer", "minimum": 1},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  }
}
```

---

## 13. Тестирование

### 13.1. Тесты схемы

Для каждого tool ОБЯЗАТЕЛЬНЫ:

- минимум один валидный вызов;
- минимум один негативный вызов (например отсутствие required-поля или неверный тип).

СЛЕДУЕТ покрывать по мере применимости к схеме:

- полный валидный вызов;
- отсутствие каждого required-поля;
- неверный тип ключевых параметров;
- неизвестное дополнительное поле;
- значение вне enum;
- значение вне диапазона;
- неправильная дата/date-time;
- превышение `maxItems`, `maxLength` и размера файла;
- нарушение взаимозависимости полей (оба XOR-поля сразу; ни одного из обязательной пары).

### 13.2. Тесты прав

Для write-, destructive- и чувствительных read-операций СЛЕДУЕТ проверить:

- пользователь без доступа к проекту;
- пользователь с read-only доступом;
- пользователь с правом изменения;
- администратор, если инструмент затрагивает admin-сценарии;
- доступ к приватным заметкам, если инструмент их возвращает или меняет;
- попытка изменить объект другого проекта через подменённый ID.

Для простых read-only tools без чувствительных данных permission tests МОЖНО ограничить одним негативным сценарием или опустить с кратким обоснованием в MR.

### 13.3. Тесты идемпотентности

Для `idempotentHint: true` СЛЕДУЕТ иметь автоматический или ручной тест двух и более одинаковых последовательных вызовов.

Проверяется отсутствие побочных эффектов, заявленных как идемпотентные, например:

- дополнительных journal entries;
- повторных email;
- дубликатов файлов;
- дубликатов relation;
- повторных time entries;
- лишних webhook events, если это часть гарантии.

### 13.4. Тесты контракта

СЛЕДУЕТ сохранять `tools/list` как snapshot или иным способом отслеживать несовместимые изменения контракта. CI МОЖЕТ выявлять:

- изменение имени;
- удаление параметра;
- изменение типа;
- изменение `required`;
- расширение уровня риска annotations;
- исчезновение `outputSchema`;
- несовместимое изменение полей, типов, `required`, `enum` / `const` или success/error-веток `outputSchema`.

### 13.5. Тесты выбора LLM

Для похожих или легко перепутываемых инструментов СЛЕДУЕТ иметь набор пользовательских запросов и ожидаемых tool calls. Полноценный автоматический LLM-прогон МОЖНО заменить статичными examples в MR или description review.

Примеры:

| Запрос | Ожидаемый tool |
|---|---|
| «Покажи задачу 123» | `redmine_get_issue` |
| «Найди задачи про OAuth» | `redmine_search_issues` |
| «Добавь наблюдателя 15 к задаче 123» | `redmine_add_issue_watcher` |
| «Удали связь между задачами» | `redmine_delete_issue_relation` |
| «Найди похожие задачи» | `redmine_advanced_search_semantic_search_issues` |

Тест или review считается проваленным, если модель с высокой вероятностью выбирает универсальный destructive tool для read-only намерения или вынуждена угадывать значения `action`.

### 13.6. Тесты восстановления после ошибок

СЛЕДУЕТ проверить, что после типичных ошибок модель получает достаточно информации для корректного повторного вызова:

- отсутствующий ID;
- недопустимый status;
- конфликт `expected_updated_at`;
- недостаточные права;
- превышение limit;
- неверный MIME type.

---

## 14. Чеклист code review

Новый tool нельзя merge, пока на все обязательные пункты не получен ответ «да».

### Назначение

- [ ] Одно действие; нет `action`/`manage`, смешивающего операции (§3.1–3.2).
- [ ] Административная операция отделена от обычной.

### Имя и описание

- [ ] Имя начинается с `redmine_`: core — `redmine_<verb>_<entity>`; сторонний плагин — `redmine_<plugin_id>_…` (§4.1).
- [ ] Description: назначение, побочные эффекты, краткий результат; похожие tools различимы (§5).
- [ ] Cross-ссылки на другие tools используют полные имена из `tools/list` (§5.2.1).

### Исследование исходного контракта

- [ ] Для core-tool изучены REST API ресурса, версии и при необходимости плагины; coverage report в MR СЛЕДУЕТ приложить (§5.6–5.7).
- [ ] Для extension-tool ОБЯЗАТЕЛЬНО проверен исходный serializer / service / REST endpoint и минимум один реальный успешный ответ для каждой формы результата (§18.5).
- [ ] Контракт сравнен с текущим `tools/list`.

### Input schema

- [ ] Схема соответствует §6 (`additionalProperties: false`, типы, `required`, `enum`/`const`, ограничения).
- [ ] У каждого параметра есть содержательный `description` (§6.14); у `*_id` — `minimum: 1` (§4.3).
- [ ] Для `*_id` и прочих lookup-значений указан discovery path (§6.16): list-tool, поле ответа get/list или `enum`.
- [ ] Ограничения «exactly one of …» / взаимозависимости формализованы в схеме, а не только в description (§5.3, §6.12).
- [ ] Optimistic locking — только `expected_updated_at`, не `updated_at` (§4.4).
- [ ] Для `set_*` необязательных полей решена очистка: `null`, отдельный clear-tool или явный отказ (§6.13).
- [ ] Нет «object or JSON string» и произвольного `fields`/`payload`.
- [ ] `*_id` — integer; серверная валидация по §3.4.

### Выход и ошибки

- [ ] Новый tool имеет `outputSchema` с success/error envelope (§7.1–7.2).
- [ ] Известные стабильные поля результата описаны в `properties`; `additionalProperties: true` не используется вместо известного контракта.
- [ ] Все гарантированно возвращаемые поля находятся в `required`.
- [ ] Nullable и optional поля различены осознанно.
- [ ] `enum`/`const`, `date`/`date-time`, диапазоны и другие известные ограничения формализованы в schema.
- [ ] Для денежных и других числовых бизнес-значений понятны единицы, валюта и major/minor units.
- [ ] Бизнес-инварианты результата отражены через schema (`const`, `enum`, `required` или условная schema), а не только следуют из имени tool.
- [ ] Description, `outputSchema` и фактический ответ handler/REST/service не противоречат друг другу (§7.1.1).
- [ ] Внутренние REST/Ruby/plugin значения нормализованы в стабильный MCP-контракт; нет утечки STI/class names или locale-dependent форматов (§3.3).
- [ ] List-tool возвращает краткую, но достаточную структуру; description корректно объясняет, когда действительно нужен соответствующий get-tool.
- [ ] Ошибки: `isError`, стабильный code, исправимое message; без секретов и stack trace (§10).

### Аннотации

- [ ] Annotations соответствуют риску (§8); для `idempotentHint: true` тест рекомендуется.

### Безопасность

- [ ] Права, file path, SSRF, limits, логи, destructive/audit — по §9; паттерны из приложения A — по необходимости.

### Тесты

- [ ] Минимальные schema tests; остальное по риску (§13).

---

## 15. Совместимость и изменение существующих инструментов

### 15.1. Несовместимые изменения

Несовместимое изменение (breaking change):

- переименование tool;
- удаление поля;
- изменение типа;
- добавление нового required-поля;
- изменение смысла поля;
- несовместимое изменение output;
- объединение нескольких операций в одну;
- повышение риска без обновления annotations и документации.

### 15.2. Миграция имени

При переходе, например, со старого префикса `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

на короткий префикс `redmine_`:

```text
redmine_get_issue
```

следует:

1. добавить новое имя;
2. временно сохранить старый alias;
3. пометить старый tool как deprecated в description;
4. собирать метрики вызовов старого имени;
5. удалить alias после согласованного периода;
6. отправить `notifications/tools/list_changed`, если сервер объявляет `listChanged`.

### 15.3. Изменение описаний

Description влияет на выбор инструмента моделью и рассматривается как поведенческое изменение. При существенном изменении description СЛЕДУЕТ пересмотреть LLM selection examples или провести повторный selection review.

### 15.4. Версия сервера

Версия MCP-сервера возвращается отдельным read-only tool или server metadata. Не следует добавлять `v1`, `v2` в каждое имя без реальной необходимости поддерживать параллельные несовместимые контракты.

---

## 16. Правила для текущих проблем Redmine MCP

При разработке новых инструментов запрещено повторять паттерны аудита текущего контракта. Канонические правила — в соответствующих разделах; ниже только карта проблем:

| Проблема аудита | Раздел |
|---|---|
| Имена без префикса `redmine_` (в т.ч. у сторонних плагинов) / смешанный стиль внутри одного плагина | §4.1 |
| Глагол не совпадает с семантикой (`complete_*` при `done=true/false` вместо `set_*`) | §4.2 |
| Числовой ID без `minimum: 1` или с описанием «Issue id» | §4.3 |
| Optimistic locking как `updated_at` вместо `expected_updated_at` | §4.4, A.2 |
| Универсальные `manage_*` / `patch_*` и параметр `action` | §3.1, §4.2 |
| Параметры без `type`, enum только в description, массивы без `items` | §5.3, §6 |
| Параметры без `description`; слишком короткие описания без ссылки на lookup-tool | §6.14 |
| Нет `examples` у reference-параметров и идентификаторов | §6.15 |
| Write-tool с `*_id` без discovery path (нет list-tool и опций в get-ответе) | §6.16 |
| Description обещает «exactly one of A or B», а схема это не кодирует | §5.3, §6.12 |
| Короткие имена tools в cross-ссылках (`list_projects` вместо `redmine_list_projects`) | §5.2.1 |
| Перегруженное описание инструмента на половину страницы | §5.2 |
| `fields` / `extra_fields` без схемы; лишние `required` | §6.4, §6.11 |
| `set_*` без способа очистить поле и без явного отказа | §6.13 |
| Один набор annotations на все write-tools; лишний `openWorldHint` | §8 |
| `destructiveHint: true` у обычных `update` / `rename`; неверный `openWorldHint` у `create_*` | §8.1, §8.2 |
| Description обещает структуру ответа, а `outputSchema` отсутствует или описывает только произвольный object | §7.1 |
| Description, schema и фактический ответ противоречат друг другу | §7.1.1 |
| STI/class names или locale-даты в MCP-ответе | §3.3 |
| `additionalProperties: true` вместо известных полей list/get | §7.1 |
| Произвольный `file_path`, обход project-scope, SSRF | §9 |
| Email/внешний эффект в одном tool с локальным изменением | §3.2 |
| Неоднозначные пары похожих tools | §5.4 |

---

## 17. Структура набора tools

Полный актуальный список инструментов не дублируется в этом документе — он быстро устаревает.

**Источник истины:**

- core tools — [03-core-tools.md](03-core-tools.md) и фактический `tools/list` на инсталляции;
- tools сторонних плагинов — §18 и ответ MCP-метода `tools/list` на инсталляции.

**Принципы группировки** (каждая группа — отдельные атомарные tools по §3):

| Группа | Примеры намерений | Префикс |
|---|---|---|
| Задачи | get, list, search, create, update, delete, copy, подзадачи | `redmine_` |
| Связи и наблюдатели | list/create/delete relation; add/remove watcher | `redmine_` |
| Проекты и участники | projects, modules, members, roles | `redmine_` |
| Версии и категории | versions; категории задач | `redmine_` |
| Учёт времени | list, create, update, import, activities | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| Файлы и вложения | list, upload, delete, download | `redmine_` |
| Администрирование | users, roles, server info | `redmine_admin_` или `redmine_get_server_info` |
| Сущности плагинов | чеклисты, поиск и т.д. | `redmine_` + `plugin_id`, напр. `redmine_advanced_search_` |

Перед добавлением нового tool СЛЕДУЕТ проверить ответ MCP-метода `tools/list` и соответствующую группу: не дублировать существующий инструмент и не смешивать разные намерения в одном имени.

Если в группе есть write-tool с ID-параметром (`status_id`, `role_ids`, …), в той же группе ОБЯЗАН быть discovery path (§6.16).

Административные tools публикуются только для пользователей с нужными правами (§9.1).

---

## 18. Расширения сторонних плагинов

Раздел для авторов плагинов Redmine, которые добавляют tools через Extension API. Техническое описание API, hooks и edge cases — в [04-extensions.md](04-extensions.md).

Расширения подчиняются тем же правилам контракта, безопасности и именования (§3–§10, §4.1), что и core tools `redmine_mcp`.

### 18.1. Когда что публиковать

| Примитив | Когда использовать |
|---|---|
| **Tool** | Одно действие над сущностью плагина или Redmine: создать, получить, изменить, удалить, поиск |
| **Resource** | Большой или статический контент по стабильному URI: тело wiki, файл, длинный отчёт |
| **Prompt** | Повторяемый шаблон сценария для пользователя, а не операция с побочным эффектом |
| **`extend_tool`** | Параметр или hook логически является частью уже существующего core-tool (например `include_*` при чтении задачи) |

Если модель может выполнить намерение отдельным tool без угадывания `action` — предпочтителен **собственный tool**, а не `extend_tool` с раздуванием чужой схемы.

### 18.2. Регистрация

- Файл расширения загружается при старте Redmine: `lib/<plugin_id>/mcp.rb` (см. `ExtensionLoader`).
- Модуль в `mcp.rb` ОБЯЗАН быть `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): так Zeitwerk выводит имя из файла.
- Перед регистрацией СЛЕДУЕТ проверять `mcp_extension_enabled?` — жёсткая зависимость от `redmine_mcp` в gemspec не обязательна.
- Для регистрации использовать `register_tool_once`, чтобы повторная загрузка не дублировала tool.
- Полное имя в `tools/list` ОБЯЗАНО начинаться с `redmine_` (§4.1).
- Tool ОБЯЗАН иметь `title`, `description`, `input_schema`, `output_schema`, `permission` и `annotations`; дублирование имён запрещено.
- Tool виден в ответе MCP-метода `tools/list` только пользователям с соответствующим правом.

### 18.3. Именование

- Имя ОБЯЗАНО начинаться с `redmine_`; дальше — `plugin_id` и `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Глаголы и запрет `manage_*` — по §4.2 и §3.1.
- Не копировать имена core tools и не публиковать второй tool с тем же намерением под другим именем.

Перед регистрацией СЛЕДУЕТ свериться с ответом `tools/list` на целевой инсталляции.

### 18.4. Права и безопасность

- `permission` ОБЯЗАН соответствовать реальным правам Redmine или плагина, а не отдельной «mcp-only» роли.
- Для операций по задаче СЛЕДУЕТ использовать `register_issue_tool` и `find_accessible_issue` вместо копирования проверки видимости и модуля проекта.
- Если задан `module_name`, tool ОБЯЗАН быть в `tools/list` только когда у пользователя есть заявленное право хотя бы в одном видимом проекте с включённым модулем. Без `module_name` достаточно права хотя бы в одном видимом проекте. Handler по-прежнему проверяет конкретную задачу, включая модуль её проекта.
- Повторная серверная валидация аргументов и прав в handler — по §3.4 и §9, даже если tool скрыт из `tools/list` у других пользователей.

### 18.5. Чистая реализация

**Тонкий MCP-слой.** `mcp.rb` должен содержать преимущественно регистрацию tools: схемы, descriptions, permissions, annotations и короткие handlers. Handler валидирует аргументы, проверяет контекст и передаёт выполнение в отдельный класс/сервис.

Бизнес-логика плагина должна оставаться в обычных моделях и сервисах и не зависеть от MCP.

Если логика нужна только для MCP — например, объединение данных нескольких моделей, нормализация REST-ответа под MCP-контракт, вычисление производных полей или подготовка результата tool — её МОЖНО вынести в отдельный `mcp_tools.rb`. Если такой файл становится большим, СЛЕДУЕТ разделить его на классы по сущностям или операциям, например `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Не размещать бизнес-логику и большие преобразования непосредственно в lambda/handler внутри `mcp.rb`.

**Доступ к данным.**

- Модели и сервисы плагина — если логика уже там.
- `internal_request` / `internal_get` / REST — если нужно переиспользовать существующий API-контроллер; endpoint должен поддерживать `accept_api_auth`. Для `POST`, `PUT`, `PATCH` и `DELETE` используйте `internal_request`; для чтения — `internal_get` или `internal_request(method: 'GET', ...)`. Ошибки проверяйте через `internal_request_error?`.

**`extend_tool` — умеренно.** Уместен, когда параметр — часть одного намерения с core-tool. Неуместен, когда плагин по сути добавляет отдельную подсистему: лучше свой префикс и свои tools, а связь с core описать в `description` или server instructions.

**Контракт как у core.** Input — по §6. Output — по §7.1 и §7.1.1: стабильные поля, `required`, `enum`/`const`, единицы измерения, нормализация внутреннего API. Annotations по риску, исправимые ошибки (§8, §10). Optimistic locking — `expected_updated_at` (§4.4). У каждого параметра — `description` (§6.14). Cross-ссылки — полные имена (§5.2.1). У каждого write-параметра `*_id` — discovery path (§6.16): отдельный `list_*` или опции с `id` в ответе get/list, и явная ссылка на них в description параметра.

Перед публикацией extension tool ОБЯЗАТЕЛЬНО проверить исходный serializer / service / REST endpoint и минимум один реальный успешный ответ для каждой формы результата.

**Общий код — в `redmine_mcp`.** При разработке расширения, если фрагмент может понадобиться другому плагину с MCP, его СЛЕДУЕТ сразу добавлять в core `redmine_mcp`, а не копировать в `lib/<plugin>/mcp*.rb`.

Критерий: логика не привязана к домену одного плагина (чек-листы, поиск, …) и описывает контракт MCP, Extension API или типовой паттерн интеграции.

| Куда | Что |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, расширение `ExtensionApi` (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, общие permission-хелперы по `issue_id` / `project_id` |
| **Плагин-расширение** | `mcp.rb` — регистрация tools и короткие handlers; `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-specific получение, агрегация и нормализация; обычные models/services — бизнес-логика, не зависящая от MCP |

**Рекомендуемое размещение для extension:**

- `mcp.rb` — регистрация tools и короткие handlers;
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-specific получение, агрегация и нормализация данных;
- обычные models/services — бизнес-логика, не зависящая от MCP.

Перед копированием helper из другого расширения СЛЕДУЕТ проверить, нет ли уже аналога в `redmine_mcp`; при отсутствии — вынести в core в том же PR, а не дублировать.

Подробнее про API расширений — [04-extensions.md](04-extensions.md) (§ «Вспомогательные методы ExtensionApi»).

### 18.6. Антипаттерны

ЗАПРЕЩЕНО или не рекомендуется:

- регистрировать tools при каждом HTTP-запросе;
- падать при ошибке соседнего плагина на старте;
- смешивать read, write и admin в одном tool;
- дублировать core tool «с другим названием»;
- расширять чужой tool optional-параметрами «на будущее»;
- отдавать в MCP внутренние поля, недоступные пользователю в UI/API плагина;
- публиковать STI-имена классов, locale-даты или REST-представление, если MCP-схема задаёт другой контракт (§3.3, §7.1.1);
- описывать элемент list только как `{ "type": "object", "additionalProperties": true }` (§7.1);
- публиковать `set_*_status` / аналог с `status_id`, не дав модели способ узнать допустимые ID (§6.16);
- дублировать в расширении общие MCP-хелперы (envelope `outputSchema`, обёртки `internal_request`, permission по задаче), если их место в `redmine_mcp` — см. §18.5.

### 18.7. Проверка перед merge

- [ ] Имя tool начинается с `redmine_` по §4.1 / §18.3.
- [ ] Расширение загружается при старте; tool появляется в `tools/list` у пользователя с правами.
- [ ] Tool отсутствует у пользователя без прав и при отключённом флажке MCP-расширения плагина.
- [ ] Контракт и checklist (§14) выполнены, включая сверку description / outputSchema / фактического ответа (§7.1.1); при необходимости — тесты по §13.
- [ ] Serializer / REST / service проверен минимум на одном реальном успешном ответе для каждой публикуемой формы результата (например list и get, если публикуются обе).
- [ ] Нет дублирования существующего tool в `tools/list`.
- [ ] Для каждого `*_id` write-параметра есть discovery path (§6.16).

---

## 19. Источники и нормативная база

Документ подготовлен по состоянию на 2026-07-22 на основе следующих первичных источников:

1. Model Context Protocol, **Protocol Revision 2025-11-25**  
   https://modelcontextprotocol.io/specification/2025-11-25

2. Model Context Protocol, **Tools**  
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Model Context Protocol, **Schema Reference**  
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Model Context Protocol, **Security Best Practices**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Model Context Protocol, **Understanding Authorization in MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog, **Tool Annotations as Risk Vocabulary: What Hints Can and Can't Do**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Server Instructions: Giving LLMs a user manual for your server**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON Schema, **Reference**  
   https://json-schema.org/understanding-json-schema/reference

9. JSON Schema, **Enumerated values**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON Schema, **Conditional schema validation**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **REST API overview**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **REST Issues**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **REST API changes**  
    Ссылка `API changes for each version` на странице REST API; проверяется для всех поддерживаемых версий.

---

## 20. Критерий готовности нового инструмента

Новый MCP-tool считается готовым, когда обязательные пункты code review checklist (§14) выполнены.

Для tools стороннего плагина дополнительно — чеклист §18.7.

Рекомендации по риску: coverage report (§5.7), дополнительные тесты §13.2–13.6 и приложение A. Минимальные schema tests (§13.1) и правила `outputSchema` (§7.1, §7.1.1) обязательны.

---

## Приложение A. Рекомендуемые паттерны реализации

Паттерны ниже не являются обязательными для каждого MCP-tool. Их СЛЕДУЕТ рассматривать при повышенном риске: destructive-операции, admin-tools, массовые write, внешние побочные эффекты, повторные вызовы из-за timeout.

### A.1. Двухфазное удаление (prepare / confirm)

Для особо опасных административных операций:

1. `redmine_prepare_delete_*` возвращает краткое описание последствий и одноразовый token;
2. `redmine_confirm_delete_*` принимает token с коротким TTL.

Нормативные требования к destructive-операциям — в §9.5.

### A.2. Оптимистическая блокировка

Для update/delete при конкурентном изменении параметр ОБЯЗАН называться `expected_updated_at` (§4.4), а не `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Имя едино для core tools и расширений (включая checklist write-tools).

При конфликте возвращается `CONFLICT`, актуальное время изменения объекта (`updated_at` / `updated_on` в ответе) и рекомендация перечитать объект.

### A.3. Ключ идемпотентности

Для операций, где повтор из-за timeout может создать дубликат:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Особенно уместно для:

- создания задач;
- импорта трудозатрат;
- загрузки файлов;
- массовых операций;
- отправки email.

Если инструмент публикует `idempotentHint: true`, повторный вызов должен быть безопасен (§8.2); `idempotency_key` — один из способов это обеспечить.

---

## Приложение B. Полный пример инструмента

Эталон `redmine_create_issue`. При изменении формата ошибок или envelope обновляют §7, §10 и этот раздел; §12 остаётся сокращённым.

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown. This operation may create notifications and is not idempotent unless idempotency_key is supplied.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Issue description in Redmine text format."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker ID returned by redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Issue priority ID returned by redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "User ID of the assignee, from redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format.",
        "examples": ["2026-07-30"]
      },
      "custom_fields": {
        "type": "array",
        "maxItems": 100,
        "items": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {"type": "integer", "minimum": 1},
            "value": {
              "oneOf": [
                {"type": "string"},
                {"type": "number"},
                {"type": "boolean"},
                {
                  "type": "array",
                  "items": {"type": "string"}
                }
              ]
            }
          },
          "required": ["id", "value"]
        }
      },
      "idempotency_key": {
        "type": "string",
        "minLength": 8,
        "maxLength": 128
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer"},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  },
  "execution": {
    "taskSupport": "forbidden"
  }
}
```

Примечание: если сервер гарантирует идемпотентность при наличии `idempotency_key`, annotation всё равно описывает инструмент в целом. Поэтому безопасное значение остаётся `false`, если вызов без ключа допускается.

