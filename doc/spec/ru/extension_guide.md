# MCP-расширения для Redmine-плагинов

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` позволяет другим плагинам Redmine добавлять собственные MCP tools и при необходимости регистрировать resources, prompts и capabilities без отдельного MCP-сервера и без изменений в коде самого `redmine_mcp`.

## Как это устроено

`redmine_mcp` предоставляет общий MCP Registry, в котором регистрируются tools сторонних Redmine-плагинов через `RedmineMcp::ExtensionApi`.

Типичный вызов проходит так:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` не должен знать бизнес-логику стороннего плагина: плагин сам регистрирует свои tools через Extension API.

## Стабильность и обратная совместимость

Начиная с `redmine_mcp 1.0.0`, публичный Extension API считается стабильным.

Публичным API считаются только методы и контракты `RedmineMcp::ExtensionApi`, описанные в этом руководстве. Внутренние классы, модули и методы `redmine_mcp`, не документированные как часть Extension API, не являются публичным API и могут изменяться без сохранения обратной совместимости.

В пределах одной major-версии `redmine_mcp`:

- существующие публичные методы Extension API не удаляются и не изменяются несовместимым образом;
- новые методы и необязательные параметры могут добавляться;
- устаревающие методы сначала помечаются как deprecated и сохраняются как минимум до следующей major-версии;
- изменения, требующие доработки сторонних плагинов, выпускаются только в новой major-версии.

Все изменения Extension API указываются в `CHANGELOG.md`.

Сторонним плагинам рекомендуется указывать минимальную версию `redmine_mcp`, необходимую для их работы, и проверять `CHANGELOG.md` при обновлении.

## Быстрый старт

1. Создайте файл `mcp.rb` в одном из путей:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<basename_каталога_плагина>/mcp.rb`
   - `lib/<plugin.id без префикса redmine_>/mcp.rb`, если `plugin.id` начинается с `redmine_`
2. Определите модуль `<PluginName>::Mcp`.
3. Подключите `RedmineMcp::ExtensionApi`.
4. Укажите `plugin_id`.
5. Зарегистрируйте первый tool.

Пример минимального issue-scoped расширения:

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

В примере используется `register_issue_tool` — рекомендуемый helper для tools, работающих с задачами. Полный контракт tool — в [mcp_tool_development.md](mcp_tool_development.md).

### Имя модуля `Mcp`

Файл расширения — `mcp.rb`. Zeitwerk выводит из него константу `Mcp`, поэтому пишите `module Mcp`.

Регистрация tools происходит при `require` файла. Загрузчик не проверяет имя константы модуля.

## Именование

Для tools и prompts указывайте короткое имя:

```ruby
name: 'search_issues'
```

Полное имя в MCP формируется автоматически:

```text
redmine_<plugin_id>_<name>
```

Для tools рекомендуется задавать `name` в формате `<verb>_<entity>`.

Предпочтительные глаголы:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Не используйте расплывчатые `manage_*`, `process_*`, `handle_*` и tools с параметром вида `action: create | update | delete`, если операции можно разделить на отдельные понятные tools.

Например:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

Если `plugin_id` уже начинается с `redmine_` (например `redmine_advanced_checklists`), полное имя следует правилу `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

Для resources используйте уникальный URI, например:

```text
redmine://<plugin_id>/<type>/<id>
```

Имена tools/prompts и URI resources должны быть уникальными. Поведение при повторной регистрации зависит от используемого метода; `register_tool_once` не регистрирует tool повторно.

## Регистрация tools

### Обычный tool

Используйте `register_tool_once`, если нужен обычный MCP tool без привязки к конкретной задаче.

Подходит для сценариев вроде:

- поиска по данным плагина;
- получения сводки;
- серверной валидации или вычислений.

Базовый пример:

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

Полный контракт tools — `additionalProperties: false`, annotations по риску и envelope через `SchemaNormalizer.envelope_output` — описан в [mcp_tool_development.md](mcp_tool_development.md).

### Tool для задачи

Используйте `register_issue_tool`, если tool принимает `issue_id` и работает с задачей.

Это рекомендуемый вариант для issue-scoped сценариев, потому что он:

- находит задачу через `Issue.visible(user)`;
- при необходимости проверяет модуль проекта;
- проверяет указанное право в проекте задачи;
- передаёт найденный `issue` в block;
- возвращает ошибку, если задача недоступна или не найдена.

См. также раздел «Права (permissions)».

`module_name` в `register_issue_tool` — необязательный идентификатор модуля проекта Redmine. Он не обязан совпадать с `plugin_id`. Если задан, tool виден в `tools/list` только при наличии хотя бы одного видимого проекта с этим модулем и заявленным правом.

### Что возвращает handler

Handler возвращает hash с данными успеха без envelope либо готовый envelope `{ok: true, data: ...}` / `{ok: false, error: ...}`. Registry нормализует результат через `ToolResponse.from_handler_result`: plain hash оборачивается в `{ok: true, data: ...}`; для списков можно вернуть готовый результат `paginated_list`, который уже содержит `data` и `meta`.

Для ошибок используйте `RedmineMcp::Core::Helpers.error_result`, `mcp_error` или `{ok: false, error: ...}`.

## Input schema

`SchemaNormalizer.normalize_input` нормализует объектную schema и добавляет служебные ограничения, но публичный контракт параметров необходимо описывать явно.

Основные правила:

- у каждого параметра должен быть определён тип;
- числовые `*_id` имеют `type: integer`, `minimum: 1` и description с discovery path;
- конечные наборы значений задаются через `enum` / `const`, а не только текстом;
- массивы обязательно имеют `items`;
- взаимозависимости и взаимоисключающие поля задаются через JSON Schema (`oneOf`, `if/then/else` и т.п.), а не только description;
- optimistic locking использует `expected_updated_at`, а не `updated_at`;
- `null` используется только с явно описанной семантикой, например для очистки поля;
- не используйте открытые `fields`, `payload`, `data` вместо типизированных бизнес-параметров;
- не принимайте объект как JSON-строку;
- не принимайте произвольный `file_path` в публичном tool.

Полные требования к `inputSchema` — в [mcp_tool_development.md](mcp_tool_development.md).

## Output schema

Каждый новый tool должен иметь `output_schema`.

Для обычного результата используйте стандартный envelope:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

Для списков используйте `SchemaNormalizer.list_envelope_output(item_schema)`.

Известные стабильные поля результата должны быть описаны явно. Не используйте `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` вместо типизированного контракта, если структура ответа известна. Эти схемы допустимы только для действительно открытых или нестабильных структур.

Полные требования к `outputSchema` — в [mcp_tool_development.md](mcp_tool_development.md).

## Аннотации

| Тип операции | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | зависит от реализации | `false` |
| delete / purge | `false` | `true` | только если повтор действительно безопасен | `false` |
| внешний side effect | `false` | зависит | обычно `false` | `true` |

`destructive` означает необратимую потерю данных, а не любой write.

`open_world` означает выход за пределы известной инсталляции Redmine, а не создание нового объекта внутри Redmine.

Annotations не заменяют проверку прав в handler.

## Права (permissions)

`permission` используется Registry для доступности и предварительной проверки tool, но не заменяет проверку доступа к конкретному объекту внутри handler.

Для issue-scoped tools используйте `register_issue_tool`, который выполняет проверку видимости задачи, модуля проекта и права.

Для других сущностей handler должен повторно проверить доступ к найденному объекту.

## Ошибки

Используйте стандартные MCP error codes:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

Для стандартных ошибок используйте helpers `error_result`.
Для собственного кода — `mcp_error`.
Для optimistic locking — `conflict_if_stale`.

Handler возвращает структурированную ошибку, а не stack trace или необработанное исключение наружу.

## Готовые helpers

`RedmineMcp::Core::Helpers` содержит общие helpers, которые следует переиспользовать вместо дублирования:

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

Также доступны готовые schema fragments:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Перед созданием собственного helper проверьте, нет ли уже подходящего в `redmine_mcp`.

Актуальный набор helpers проверяйте в `RedmineMcp::Core::Helpers` и [04-extensions.md](04-extensions.md): этот список показывает основные доступные возможности и не заменяет API-документацию ExtensionApi.

## Read-only и идемпотентность

Мутирующие tools должны учитывать глобальный read-only режим:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

Для операций, где повторный вызов может создать дубликат, можно использовать `idempotency_key` и `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` допускается только когда повторный вызов действительно безопасен с учётом всех побочных эффектов.

## Организация кода

`mcp.rb` должен содержать преимущественно регистрацию tools: schemas, descriptions, permissions, annotations и короткие handlers.

MCP-specific получение, агрегацию и нормализацию данных можно вынести в:

- `mcp_tools.rb`;
- при росте файла — `mcp_tools/*.rb`.

Обычная бизнес-логика должна оставаться в models/services плагина и не зависеть от MCP.

Если у плагина уже есть подходящий REST endpoint, который реализует нужную операцию и поддерживает вызов от имени текущего пользователя, СЛЕДУЕТ переиспользовать его через `internal_request` (или `internal_get` для read-only `GET`).

Это предпочтительный вариант: MCP использует тот же путь проверки прав, получения данных и бизнес-поведения, что и существующий API плагина.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

Для `POST`, `PUT` и `PATCH` передавайте тело запроса в виде JSON-строки (или `nil`, если endpoint тело не ожидает). Параметры запроса — в `params`.

Напрямую вызывать model/service СЛЕДУЕТ, если:

- подходящего REST endpoint нет;
- endpoint не поддерживает нужную операцию или данные;
- использование REST создаёт лишний или некорректный слой для данной операции;
- общая бизнес-логика уже специально вынесена в service и REST endpoint сам является только тонкой обёрткой над этим service.

Не реализовывайте одну и ту же бизнес-логику отдельно для REST и MCP. Если общая логика нужна обоим слоям, её следует вынести в общий service.

## Дополнительные возможности

`RedmineMcp::ExtensionApi` также предоставляет:

| Метод | Когда использовать |
|---|---|
| `register_resource` | нужен MCP resource |
| `register_prompt` | нужен MCP prompt |
| `register_capability` | нужно добавить capability в `redmine_get_server_info` |
| `extend_tool` | нужно расширить существующий tool, а не создавать новый |
| `on` | нужен lifecycle hook |
| `internal_request` | нужно вызвать REST endpoint Redmine или плагина in-process от имени пользователя (`method`, `path`, опционально `params` и `body`) |
| `internal_get` | сокращение для `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | проверить, что результат in-process REST — MCP error envelope |

`plugin_id` задаётся один раз в начале модуля. Перед регистрацией tools СЛЕДУЕТ проверять `mcp_extension_enabled?`, если регистрация выполняется самим extension. Стандартный `ExtensionLoader` также не загружает `mcp.rb` для отключённых расширений.

### Расширение существующего tool

Используйте `extend_tool` только если отдельный tool не подходит.

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` выполняется до handler, `after` — после. `extra_params` добавляются во входную schema. Имена параметров не должны конфликтовать с параметрами базового tool или других расширений этого tool.

Если extension подключается из `after_initialize` плагина раньше, чем `redmine_mcp` регистрирует core tools, вызов `extend_tool` для core tool (например `redmine_get_issue`) нужно отложить до конца инициализации — через вложенный `Rails.application.config.after_initialize` с проверкой `Registry.instance.tool(...)`.

## Загрузка и отключение расширения

`redmine_mcp` автоматически ищет extension-файл в поддерживаемых путях при старте Redmine.

Проверку наличия `redmine_mcp` выполняйте в точке подключения `mcp.rb` (обычно `lib/<plugin>.rb` или `after_initialize` загрузчика плагина). Файлы, которые загружаются только из `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb` и т.п.), повторно проверять не нужно.

Не вызывайте `ExtensionLoader.load_plugin_extension` вручную из стороннего плагина: `ExtensionLoader` — внутренний механизм `redmine_mcp`. Достаточно условного `require` своего `mcp.rb`; если порядок загрузки плагинов не позволил выполнить этот `require`, сработает стандартный `ExtensionLoader` самого `redmine_mcp`.

Пример точки входа:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

Расширение будет зарегистрировано, только если:

- MCP включён в настройках `redmine_mcp`;
- файл `mcp.rb` найден;
- модуль `<PluginName>::Mcp` в `mcp.rb` корректно загружается;
- расширение не отключено в списке `MCP extensions`.

После установки нового расширения или изменения `mcp.rb` обычно нужен перезапуск Redmine. MCP-клиенту после этого может потребоваться переподключение. В некоторых приложениях, например Cursor, reload MCP-сервера недостаточно, чтобы подхватить новые tools: если они не появились, полностью перезапустите приложение.

## Проверка расширения

После реализации проверьте tool через настоящий MCP-вызов, чтобы проверить не только handler, но и:

- регистрацию в `tools/list`;
- input schema;
- permission;
- output envelope;
- ошибки.

В логах Redmine проверьте регистрацию tool и ошибки загрузки расширения.

Для каждого нового tool обязательны минимум:

- один успешный schema-сценарий;
- один негативный schema-сценарий.

Подробные требования к автотестам — в [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Автотесты расширения

Автотесты плагина с MCP-расширением должны проверять **полный путь Registry** (валидация `inputSchema` → permission → handler → envelope `{ok, data | error}`), а не только прямой вызов handler.

Если `redmine_mcp` не установлен или не загружен, тестовый класс **пропускает** сценарии (`skip` в `setup`), а не падает при загрузке файла:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

В `setup` теста допустимо вызвать `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))`, чтобы зарегистрировать tools в `Registry`. В production-коде плагина `ExtensionLoader` вызывать не нужно (см. раздел «Загрузка и отключение расширения»).

Для сверки фактического ответа с опубликованным `outputSchema` (§7.1 `mcp_tool_development.md`) используйте `json_schemer` — ту же библиотеку, которую `RedmineMcp::InputValidator` применяет для входных схем.

Допускается ленивое подключение `json_schemer` внутри test helper. Если библиотека отсутствует в окружении, проверка должна быть явно пропущена, чтобы тесты плагина не завершались ошибкой из-за необязательной зависимости.

Минимальный набор автотестов для read-only tool расширения:

- успешный вызов через Registry с проверкой `outputSchema`;
- негативный вызов, отклонённый `inputSchema` (например нарушение `oneOf`, enum, `maxItems`);
- при необходимости — отдельный тест серверной проверки в handler (schema не заменяет повторную валидацию на сервере, см. `mcp_tool_development.md` §3.4).

## Устранение неполадок

| Проблема | Что проверить |
|---|---|
| Extension не загрузился | путь `mcp.rb`, имя модуля `Mcp`, включён ли MCP, ошибки в Rails log |
| Tool/resource/prompt не появился | задан ли `plugin_id`, не отключено ли расширение, нет ли коллизии имени или URI, есть ли у пользователя необходимые права |
| Изменения не появились после правок | перезапуск Redmine; в Cursor и похожих клиентах reload MCP-сервера может не подхватить новые tools — полностью перезапустите приложение |
| `extend_tool` не работает | зарегистрирован ли базовый tool, не конфликтуют ли `extra_params` с существующей schema |

### Checklist перед merge

- [ ] Tool имеет `title`, `description`, `input_schema`, `output_schema`, `permission` и `annotations`.
- [ ] Каждый `*_id` имеет discovery path.
- [ ] Description, output_schema и фактический ответ согласованы.
- [ ] Мутирующий tool учитывает read-only режим.
- [ ] MCP-specific логика не разрастается внутри lambda/handler.
- [ ] Общие helpers переиспользуются из `redmine_mcp`, а не копируются.
- [ ] Выполнен минимум один успешный и один негативный schema-сценарий.
