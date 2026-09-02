# Redmine MCP

[Сайт](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../en/README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | Русский | [中文](../zh/README.md)

MCP-сервер (Model Context Protocol) внутри Redmine. Позволяет AI-клиентам работать с задачами, проектами и пользователями через стандартные права Redmine. Другие плагины могут добавлять собственные tools, resources, prompts и capabilities без изменения этого плагина.

## Требования

| Компонент | Версия |
|---|---|
| Redmine | Redmine 6.0+ (протестировано: 6.0–6.1) |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

Плагин использует MCP protocol `2025-11-25` и Ruby MCP SDK `0.23.x`.
Поддержка более новых версий MCP protocol и SDK на данный момент не заявлена.

- Включённый REST API в Redmine
- gem `mcp` подключается через `plugins/redmine_mcp/Gemfile` и устанавливается вместе с `bundle install`

## Установка и настройка

### 1. Установка плагина

Склонируйте git-репозиторий в папку плагинов Redmine:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Из корня Redmine установите зависимости и перезапустите приложение:

```bash
cd /path/to/redmine
bundle install
```

Перезапустите Redmine.

### 2. Включение в админке

**Администрирование → Плагины → Redmine MCP → Настроить**

| Параметр | Описание |
|----------|----------|
| Включить MCP | Включает эндпоинт `/mcp`. При включении загружаются MCP-расширения установленных плагинов |
| Режим read-only | Блокирует write-инструменты и write-действия (create/update/delete и т.п.) |
| MCP-расширения | Флажки для включения MCP-интеграции установленных плагинов |

### 3. REST API

**Администрирование → Настройки → API** — «Включить REST API».

### 4. Права доступа

**Администрирование → Роли и права** — для нужных ролей вручную включить глобальное право **Использовать MCP** (`use_mcp`). Администраторы Redmine имеют доступ к MCP всегда.

### 5. API-ключ пользователя

Каждый пользователь, который будет работать через MCP, должен иметь API-ключ:

**Моя учётная запись → API key** (или через REST API пользователя).

Ключ передаётся в заголовке:

```
X-Redmine-API-Key: <ваш_ключ>
```

## Подключение MCP-клиента

Сервер работает по протоколу **Streamable HTTP** (stateless). Эндпоинт:

```
https://<ваш-redmine>/mcp
```

Поддерживаются методы: `GET`, `POST`, `DELETE`.

### Пример для Cursor

В настройках MCP (`.cursor/mcp.json` или глобальный конфиг) добавьте сервер с HTTP-транспортом. Точный формат зависит от версии клиента; типичный вариант:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "ваш_api_ключ"
      }
    }
  }
}
```

После подключения клиент выполнит `initialize`, затем сможет вызывать `tools/list`, `tools/call`, `resources/list`, `prompts/list` и т.д.

### Проверка вручную

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: ваш_ключ' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0" }
    }
  }'
```

Успешный ответ содержит `serverInfo.name: "redmine_mcp"`.

### Host и reverse proxy

MCP transport проверяет HTTP `Host` и `Origin` для защиты от DNS rebinding.

Разрешённый host определяется из настройки Redmine:

**Администрирование → Настройки → Общие → Имя хоста и путь**

Значение должно соответствовать публичному адресу Redmine.

Например, если Redmine доступен по:

```
https://redmine.example.com
```

в настройке следует использовать:

```
redmine.example.com
```

Если Redmine работает за reverse proxy, proxy должен передавать исходный заголовок `Host` клиента.

При несовпадении host MCP endpoint может вернуть HTTP `403 Forbidden`.

Клиенты без заголовка `Origin` не затрагиваются проверкой Origin.

## Встроенные инструменты (core tools)

Полные имена имеют формат `redmine_<tool_name>` (например `redmine_get_issue`).

Сервер предоставляет инструменты для работы с проектами, задачами, пользователями, временем, Wiki, форумами и файлами. Ниже приведён краткий список встроенных tools. Полные входные схемы и descriptions доступны MCP-клиенту через `tools/list`.

### Общие параметры

- `project` — строковый ID или identifier проекта.
- `assignee_ref` / `user_ref` со значением `me` — текущий пользователь.
- `assigned_to_id` — пользователь или группа, которым назначается задача; `null` очищает необязательные поля.
- `create_time_entry` требует `project` или `issue_id`.
- `upload_file` требует `filename` и `content_base64`.

### Надёжность операций

- `expected_updated_at` — для чувствительных операций обновления и удаления.
- `idempotency_key` — на `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`.

### Лимиты

- timeout 60 с на чтение;
- 120 запросов/мин на пользователя;
- HTTP-тело MCP-запроса до 36 MiB;
- JSON-аргументы инструмента до 32 MiB;
- base64-вложения до 20 MiB;
- скачивание вложений до 10 MiB.

### Развёртывание в production

Ограничение частоты запросов и идемпотентность используют `Rails.cache`.

Для установок с несколькими worker-процессами приложения или несколькими экземплярами Redmine следует использовать общее хранилище кэша.

При локальном кэше гарантии rate limiting и идемпотентности действуют только внутри отдельного процесса приложения.

### Управление проектами

| Инструмент | Описание |
|------------|----------|
| `list_projects` | Список проектов |
| `get_project` | Детали проекта |
| `list_project_issue_custom_fields` | Настраиваемые поля задач проекта |
| `summarize_project_status` | Сводка метрик проекта, формируемая сервером, за N дней |
| `list_project_activities` | Лента активности проекта (события, не типы учёта времени) |
| `list_versions` | Версии roadmap (этапы) |
| `get_version` | Детали версии roadmap с агрегатами |
| `create_version` | Создание версии |
| `update_version` | Изменение версии |
| `delete_version` | Удаление версии |
| `list_project_members` | Участники проекта и их роли |
| `list_project_member_candidates` | Пользователи и группы для добавления в проект |
| `list_roles` | Роли, которыми можно управлять в проекте |
| `get_project_modules` | Включённые модули проекта |
| `add_project_member` | Добавление участника |
| `update_project_member` | Изменение ролей участника |
| `remove_project_member` | Удаление участника |

### Задачи

| Инструмент | Описание |
|------------|----------|
| `get_issue` | Детали задачи (журнал, вложения, настраиваемые поля и др.) |
| `list_issues` | Список задач с фильтрами и постраничной навигацией |
| `search_issues` | Текстовый поиск по задачам |
| `run_issue_query` | Выполнение сохранённого запроса задач |
| `get_issue_form_options` | Допустимые значения полей формы задачи (одним вызовом) |
| `validate_issue_create` | Проверка параметров создания задачи без записи |
| `validate_issue_update` | Проверка параметров обновления задачи без записи |
| `create_issue` | Создание задачи |
| `update_issue` | Обновление атрибутов задачи и вложений |
| `add_issue_note` | Добавление комментария к задаче (опционально с вложениями) |
| `delete_issue` | Удаление задачи с подтверждением |
| `copy_issue` | Копирование задачи |
| `list_issue_relations` | Список связей задачи |
| `create_issue_relation` | Создание связи между задачами |
| `delete_issue_relation` | Удаление связи между задачами |
| `list_subtasks` | Подзадачи |
| `add_issue_watcher` | Добавление наблюдателя |
| `remove_issue_watcher` | Удаление наблюдателя |
| `update_issue_note` | Редактирование записи журнала |
| `set_issue_note_private` | Изменение приватности записи журнала |
| `get_private_notes` | Только приватные комментарии |
| `list_issue_categories` | Список категорий задач проекта |
| `create_issue_category` | Создание категории |
| `update_issue_category` | Изменение категории |
| `delete_issue_category` | Удаление категории |

### Пользователи

| Инструмент | Описание |
|------------|----------|
| `list_users` | Участники проекта; фильтры `query` (имя/login) и `login`; глобальный поиск — только администратор |
| `list_groups` | Givable-группы для `group_id` в `add_project_member` |

### Учёт времени

| Инструмент | Описание |
|------------|----------|
| `list_time_entries` | Список записей учёта времени |
| `create_time_entry` | Создание записи учёта времени |
| `update_time_entry` | Изменение записи учёта времени |
| `list_time_entry_activities` | Типы активностей для учёта времени (не лента событий проекта) |
| `import_time_entries` | Массовый импорт записей учёта времени |

### Справочники

| Инструмент | Описание |
|------------|----------|
| `list_trackers` | Все трекеры |
| `list_project_trackers` | Трекеры проекта |
| `list_issue_statuses` | Статусы задач |
| `list_issue_priorities` | Приоритеты задач |
| `admin_list_users` | Пользователи с фильтрами (только администратор) |
| `get_current_user` | Текущий пользователь |
| `list_queries` | Сохранённые запросы (метаданные; выполнение — `run_issue_query`) |

### Поиск и Wiki

| Инструмент | Описание |
|------------|----------|
| `search_all` | Поиск по задачам и страницам Wiki |
| `list_wiki_pages` | Список страниц Wiki проекта |
| `get_wiki_page` | Получение страницы Wiki |
| `create_wiki_page` | Создание страницы Wiki |
| `update_wiki_page` | Изменение страницы Wiki |
| `delete_wiki_page` | Удаление страницы Wiki |
| `rename_wiki_page` | Переименование страницы Wiki |

### Форумы

| Инструмент | Описание |
|------------|----------|
| `list_boards` | Доски форума проекта |
| `list_board_topics` | Темы выбранной доски |
| `get_board_message` | Сообщение форума с краткими ответами |

### Работа с файлами

| Инструмент | Описание |
|------------|----------|
| `list_project_files` | Файлы проекта |
| `upload_file` | Загрузка файла |
| `delete_attachment` | Удаление вложения |
| `get_attachment` | Метаданные и `content_url` вложения |
| `download_attachment` | Содержимое вложения (`content_base64`, до 10 MiB) |

### Служебные

| Инструмент | Описание |
|------------|----------|
| `get_mcp_info` | Версия MCP-плагина, режим read-only, текущий пользователь и доступные capabilities |

### Доступ и ответы

Tools возвращают JSON-envelope в `structuredContent` и текстовое представление в `content`.

Write-операции блокируются настройкой **Режим read-only**.

Дополнительно к правам на инструмент всегда проверяется глобальное право **Использовать MCP**.

Доступ к данным проверяется через стандартные права и механизмы видимости Redmine. Для данных проектов и задач используются `Project.visible` и `Issue.visible`.

## Расширения от других плагинов

Любой установленный плагин Redmine может добавлять собственные MCP tools и при необходимости регистрировать resources, prompts и capabilities.

Подробная инструкция: [extension_guide.md](extension_guide.md).

Для разработки с помощью AI в Cursor или похожих агентах скопируйте каталог skill [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) в директорию skills вашего AI-агента или используйте его как основу для собственного skill.

## Логирование

Сообщения пишутся в стандартный лог Rails с префиксом `[redmine_mcp]`:

- загрузка расширений
- регистрация tools/resources/prompts
- ошибки регистрации и выполнения
- отказы в доступе

## Устранение неполадок

| Симптом | Возможная причина |
|---------|-------------------|
| HTTP 503 «MCP is disabled» | Не включён MCP в настройках плагина |
| HTTP 401 | Неверный или отсутствующий API-ключ; REST API выключен |
| HTTP 403 (права) | У пользователя нет права **Использовать MCP** |
| HTTP 403 (`Host`/`Origin`) | «Имя хоста и путь» не соответствует публичному адресу Redmine; reverse proxy не передаёт исходный `Host`; в клиенте указан другой URL MCP — transport отклоняет неизвестные `Host`/`Origin` (DNS rebinding) |
| Tool не виден в `tools/list` | Нет необходимых прав; расширение, предоставляющее tool, отключено |
| Новые tools не появились после reload MCP | В Cursor и похожих клиентах reload сервера может не обновить список tools — полностью перезапустите приложение |
| Расширение не загружается | Нет файла `lib/.../mcp.rb`; модуль не `extend RedmineMcp::ExtensionApi`; убедитесь, что флажок расширения установлен в **MCP-расширения**; ошибка в файле — смотрите лог |
| `Issue not found` / `Project not found` | Задача или проект недоступны текущему пользователю по правилам видимости Redmine |

## Лицензия

Плагин распространяется на условиях GNU General Public License,
версии 2 или любой более поздней версии.

Подробности — в [LICENSE](../../../LICENSE).
