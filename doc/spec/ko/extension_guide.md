# Redmine 플러그인용 MCP 확장

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp`를 사용하면 다른 Redmine 플러그인이 별도의 MCP 서버 없이, `redmine_mcp` 자체를 변경하지 않고도 자체 MCP tools를 추가하고 필요한 경우 resources, prompts, capabilities를 등록할 수 있습니다.

## 작동 방식

`redmine_mcp`는 서드파티 Redmine 플러그인이 `RedmineMcp::ExtensionApi`를 통해 tools를 등록하는 공유 MCP Registry를 제공합니다.

일반적인 호출 흐름은 다음과 같습니다:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp`는 서드파티 플러그인의 비즈니스 로직을 알아서는 안 됩니다. 플러그인은 Extension API를 통해 자체 tools를 등록합니다.

## 안정성 및 하위 호환성

`redmine_mcp 1.0.0`부터 공개 Extension API는 안정적인 것으로 간주됩니다.

이 가이드에 설명된 `RedmineMcp::ExtensionApi`의 메서드와 계약만 공개 API입니다. Extension API의 일부로 문서화되지 않은 `redmine_mcp`의 내부 클래스, 모듈, 메서드는 공개 API가 아니며 하위 호환성 보장 없이 변경될 수 있습니다.

단일 major 버전의 `redmine_mcp` 내에서:

- 기존 공개 Extension API 메서드는 제거되거나 비호환 방식으로 변경되지 않습니다;
- 새 메서드와 선택적 매개변수를 추가할 수 있습니다;
- deprecated 메서드는 먼저 표시되며 최소한 다음 major 버전까지 유지됩니다;
- 서드파티 플러그인 업데이트가 필요한 변경은 새 major 버전에서만 릴리스됩니다.

모든 Extension API 변경 사항은 `CHANGELOG.md`에 나열됩니다.

서드파티 플러그인은 필요한 최소 `redmine_mcp` 버전을 선언하고 업그레이드 시 `CHANGELOG.md`를 검토하는 것이 좋습니다.

## 빠른 시작

1. 다음 경로 중 하나에 `mcp.rb` 파일을 만듭니다:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `plugin.id`가 `redmine_`로 시작하는 경우 `lib/<plugin.id without the redmine_ prefix>/mcp.rb`
2. `<PluginName>::Mcp` 모듈을 정의합니다.
3. `RedmineMcp::ExtensionApi`를 extend합니다.
4. `plugin_id`를 설정합니다.
5. 첫 번째 tool을 등록합니다.

이슈 범위 확장의 최소 예제:

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

이 예제는 이슈와 함께 작동하는 tools에 권장되는 helper인 `register_issue_tool`을 사용합니다. 전체 tool 계약은 [mcp_tool_development.md](mcp_tool_development.md)에 있습니다.

### `Mcp` 모듈 이름

확장 파일은 `mcp.rb`입니다. Zeitwerk는 파일 이름에서 `Mcp`를 추론하므로 `module Mcp`로 작성합니다.

tools는 파일이 require될 때 등록됩니다. 로더는 모듈 상수 이름을 조회하지 않습니다.

## 이름 지정

tools와 prompts에는 짧은 이름을 사용합니다:

```ruby
name: 'search_issues'
```

전체 MCP 이름은 자동으로 생성됩니다:

```text
redmine_<plugin_id>_<name>
```

tools의 경우 `name`을 `<verb>_<entity>` 형식으로 지정하는 것이 좋습니다.

권장 동사:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

작업을 별도의 명확한 tools로 분리할 수 있는 경우 모호한 `manage_*`, `process_*`, `handle_*` 또는 `action: create | update | delete`와 같은 매개변수를 가진 tools는 사용하지 마세요.

예:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

`plugin_id`가 이미 `redmine_`로 시작하는 경우(예: `redmine_advanced_checklists`)에도 전체 이름은 `redmine_<plugin_id>_<name>` 규칙을 따릅니다: `redmine_redmine_advanced_checklists_<name>`.

resources의 경우 고유한 URI를 사용합니다. 예:

```text
redmine://<plugin_id>/<type>/<id>
```

tool/prompt 이름과 resource URI는 고유해야 합니다. 중복 등록 동작은 사용된 메서드에 따라 다릅니다. `register_tool_once`는 동일한 tool을 두 번 등록하지 않습니다.

## tools 등록

### 일반 tool

특정 이슈에 바인딩되지 않은 일반 MCP tool이 필요한 경우 `register_tool_once`를 사용합니다.

일반적인 경우:

- 플러그인 데이터 검색;
- 요약 반환;
- 서버 측 검증 또는 계산.

기본 예제:

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

전체 tool 계약 — `additionalProperties: false`, 위험 annotations, `SchemaNormalizer.envelope_output`를 통한 envelope — 은 [mcp_tool_development.md](mcp_tool_development.md)에 설명되어 있습니다.

### 이슈 tool

tool이 `issue_id`를 받고 이슈와 함께 작동하는 경우 `register_issue_tool`을 사용합니다.

이슈 범위 시나리오에 권장되는 옵션입니다. 다음을 수행합니다:

- `Issue.visible(user)`를 통해 이슈를 찾습니다;
- 필요한 경우 프로젝트 모듈을 확인합니다;
- 이슈 프로젝트에서 지정된 permission을 확인합니다;
- 찾은 `issue`를 block에 전달합니다;
- 이슈를 사용할 수 없거나 찾을 수 없으면 오류를 반환합니다.

권한 섹션도 참조하세요.

`register_issue_tool`의 `module_name`은 선택적 Redmine 프로젝트 모듈 식별자입니다. `plugin_id`와 일치할 필요는 없습니다. 설정된 경우 tool은 사용자가 해당 모듈과 선언된 permission이 있는 최소 하나의 프로젝트를 볼 수 있을 때만 `tools/list`에 나타납니다.

### handler가 반환하는 값

handler는 envelope 없이 성공 데이터 hash를 반환하거나 준비된 envelope `{ok: true, data: ...}` / `{ok: false, error: ...}`를 반환합니다. Registry는 `ToolResponse.from_handler_result`를 통해 결과를 정규화합니다. plain hash는 `{ok: true, data: ...}`로 래핑됩니다. 목록의 경우 이미 `data`와 `meta`를 포함하는 `paginated_list`의 준비된 결과를 반환할 수 있습니다.

오류의 경우 `RedmineMcp::Core::Helpers.error_result`, `mcp_error` 또는 `{ok: false, error: ...}`를 사용합니다.

## 입력 스키마

`SchemaNormalizer.normalize_input`은 객체 schema를 정규화하고 서비스 제약을 추가하지만, 공개 매개변수 계약은 명시적으로 설명해야 합니다.

주요 규칙:

- 모든 매개변수에 정의된 type이 있어야 합니다;
- 숫자 `*_id` 필드는 `type: integer`, `minimum: 1` 및 discovery path가 있는 description을 사용합니다;
- 유한 값 집합은 설명뿐만 아니라 `enum` / `const`로 정의합니다;
- 배열에는 `items`가 있어야 합니다;
- 상호 의존적이고 상호 배타적인 필드는 description뿐만 아니라 JSON Schema(`oneOf`, `if/then/else` 등)로 정의합니다;
- optimistic locking은 `updated_at`이 아닌 `expected_updated_at`을 사용합니다;
- `null`은 명시적으로 문서화된 의미(예: 필드 지우기)에서만 사용합니다;
- 타입이 지정된 비즈니스 매개변수 대신 열린 `fields`, `payload`, `data`를 사용하지 마세요;
- 객체를 JSON 문자열로 받지 마세요;
- 공개 tool에서 임의의 `file_path`를 받지 마세요.

전체 `inputSchema` 요구 사항은 [mcp_tool_development.md](mcp_tool_development.md)에 있습니다.

## 출력 스키마

모든 새 tool에는 `output_schema`가 있어야 합니다.

일반 결과의 경우 표준 envelope를 사용합니다:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

목록의 경우 `SchemaNormalizer.list_envelope_output(item_schema)`를 사용합니다.

알려진 안정적인 결과 필드는 명시적으로 설명해야 합니다. 응답 구조가 알려진 경우 타입이 지정된 계약 대신 `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`를 사용하지 마세요. 이러한 schema는 실제로 열리거나 불안정한 구조에만 허용됩니다.

전체 `outputSchema` 요구 사항은 [mcp_tool_development.md](mcp_tool_development.md)에 있습니다.

## 어노테이션

| 작업 유형 | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | 구현에 따라 다름 | `false` |
| delete / purge | `false` | `true` | 반복이 실제로 안전한 경우에만 | `false` |
| 외부 side effect | `false` | 경우에 따라 다름 | 보통 `false` | `true` |

`destructive`는 모든 write가 아니라 되돌릴 수 없는 데이터 손실을 의미합니다.

`open_world`는 Redmine 내부에 새 객체를 생성하는 것이 아니라 알려진 Redmine 설치 범위를 벗어나는 것을 의미합니다.

Annotations는 handler의 permission 확인을 대체하지 않습니다.

## 권한

`permission`은 Registry에서 tool 가용성 및 사전 확인에 사용되지만 handler 내부에서 특정 객체에 대한 접근 확인을 대체하지 않습니다.

이슈 범위 tools의 경우 이슈 가시성, 프로젝트 모듈, permission을 확인하는 `register_issue_tool`을 사용합니다.

다른 엔티티의 경우 handler가 찾은 객체에 대한 접근을 다시 확인해야 합니다.

## 오류

표준 MCP error codes를 사용합니다:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

표준 오류의 경우 `error_result` helper를 사용합니다.
사용자 정의 코드의 경우 `mcp_error`를 사용합니다.
optimistic locking의 경우 `conflict_if_stale`을 사용합니다.

handler는 stack trace나 처리되지 않은 예외가 아닌 구조화된 오류를 반환합니다.

## 내장 helper

`RedmineMcp::Core::Helpers`에는 중복 대신 재사용해야 하는 공유 helper가 포함되어 있습니다:

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

준비된 schema fragment도 사용할 수 있습니다:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

자체 helper를 만들기 전에 `redmine_mcp`에 적합한 helper가 이미 있는지 확인하세요.

`RedmineMcp::Core::Helpers`와 [04-extensions.md](04-extensions.md)에서 현재 helper 세트를 확인하세요. 이 목록은 주요 사용 가능 기능을 보여 주며 ExtensionApi API 문서를 대체하지 않습니다.

## 읽기 전용 모드 및 멱등성

변경 tools는 전역 읽기 전용 모드를 준수해야 합니다:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

반복 호출이 중복을 생성할 수 있는 작업의 경우 `idempotency_key`와 `RedmineMcp::IdempotencyStore`를 사용할 수 있습니다.

`idempotentHint: true`는 모든 side effect를 고려할 때 반복 호출이 실제로 안전한 경우에만 허용됩니다.

## 코드 구성

`mcp.rb`에는 주로 tool 등록이 포함되어야 합니다: schemas, descriptions, permissions, annotations, 짧은 handlers.

MCP 전용 가져오기, 집계, 데이터 정규화는 다음으로 이동할 수 있습니다:

- `mcp_tools.rb`;
- 파일이 커지면 — `mcp_tools/*.rb`.

일반 비즈니스 로직은 플러그인의 models/services에 유지되어야 하며 MCP에 의존해서는 안 됩니다.

플러그인에 필요한 작업을 구현하고 현재 사용자를 대신한 호출을 지원하는 적합한 REST endpoint가 이미 있는 경우 `internal_request`(읽기 전용 `GET` 호출의 경우 `internal_get`)를 통해 재사용해야 합니다(SHOULD).

이것이 선호되는 옵션입니다. MCP는 기존 플러그인 API와 동일한 permission 확인, 데이터 가져오기, 비즈니스 동작을 사용합니다.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

`POST`, `PUT`, `PATCH`의 경우 JSON 요청 본문 문자열(또는 endpoint가 본문을 기대하지 않으면 `nil`)을 전달합니다. 쿼리 매개변수는 `params`에 넣습니다.

다음 경우 model/service를 직접 호출합니다:

- 적합한 REST endpoint가 없는 경우;
- endpoint가 필요한 작업이나 데이터를 지원하지 않는 경우;
- REST 사용이 작업에 불필요하거나 잘못된 레이어를 만드는 경우;
- 공유 비즈니스 로직이 이미 의도적으로 service로 추출되었고 REST endpoint 자체가 해당 service를 감싸는 얇은 래퍼인 경우.

REST와 MCP에 대해 동일한 비즈니스 로직을 별도로 구현하지 마세요. 두 레이어 모두 공유 로직이 필요하면 공통 service로 추출하세요.

## 추가 기능

`RedmineMcp::ExtensionApi`는 다음도 제공합니다:

| 메서드 | 사용 시점 |
|---|---|
| `register_resource` | MCP resource가 필요한 경우 |
| `register_prompt` | MCP prompt가 필요한 경우 |
| `register_capability` | `redmine_get_server_info`에 capability를 추가해야 하는 경우 |
| `extend_tool` | 새 tool을 만드는 대신 기존 tool을 확장해야 하는 경우 |
| `on` | lifecycle hook이 필요한 경우 |
| `internal_request` | 현재 사용자로 Redmine 또는 플러그인 REST endpoint를 in-process로 호출해야 하는 경우(`method`, `path`, 선택적 `params` 및 `body`) |
| `internal_get` | `internal_request(method: 'GET', ...)`의 축약형 |
| `internal_request_error?` | in-process REST 결과가 MCP error envelope인지 확인 |

`plugin_id`는 모듈 상단에 한 번 설정합니다. 등록이 확장 자체에서 수행되는 경우 tools를 등록하기 전에 `mcp_extension_enabled?`를 확인해야 합니다(SHOULD). 표준 `ExtensionLoader`도 비활성화된 확장에 대해 `mcp.rb`를 로드하지 않습니다.

### 기존 tool 확장

별도의 tool이 적합하지 않은 경우에만 `extend_tool`을 사용합니다.

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

`before`는 handler 전에 실행되고 `after`는 handler 후에 실행됩니다. `extra_params`는 input schema에 추가됩니다. 매개변수 이름은 기본 tool 또는 해당 tool의 다른 확장과 충돌해서는 안 됩니다.

확장이 `redmine_mcp`가 core tools를 등록하기 전에 플러그인의 `after_initialize`에서 require되는 경우 core tool(예: `redmine_get_issue`)에 대한 `extend_tool`을 초기화가 완료될 때까지 지연하세요 — 중첩된 `Rails.application.config.after_initialize`를 사용하고 먼저 `Registry.instance.tool(...)`을 확인합니다.

## 확장 로드 및 비활성화

`redmine_mcp`는 Redmine 시작 시 지원되는 경로에서 확장 파일을 자동으로 찾습니다.

`redmine_mcp` 확인은 `mcp.rb` 진입점(보통 `lib/<plugin>.rb` 또는 플러그인 로더의 `after_initialize`)에서만 수행합니다. `mcp.rb`에서만 로드되는 파일(`mcp_tools.rb`, `mcp_tools/*.rb` 등)은 동일한 확인을 반복하지 않아야 합니다.

서드파티 플러그인에서 `ExtensionLoader.load_plugin_extension`을 수동으로 호출하지 마세요. `ExtensionLoader`는 `redmine_mcp`의 내부 메커니즘입니다. 조건부 `require`로 `mcp.rb`를 로드하는 것으로 충분합니다. 플러그인 로드 순서로 인해 해당 `require`가 실행되지 않은 경우 표준 `redmine_mcp` `ExtensionLoader`가 대체 수단으로 작동합니다.

진입점 예제:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

확장은 다음 조건을 모두 만족할 때만 등록됩니다:

- `redmine_mcp` 설정에서 MCP가 활성화됨;
- `mcp.rb` 파일이 발견됨;
- `mcp.rb`의 `<PluginName>::Mcp` 모듈이 올바르게 로드됨;
- `MCP extensions` 목록에서 확장이 비활성화되지 않음.

새 확장을 설치하거나 `mcp.rb`를 변경한 후에는 보통 Redmine 재시작이 필요합니다. 그 후 MCP 클라이언트가 다시 연결해야 할 수 있습니다. Cursor와 같은 일부 애플리케이션에서는 MCP 서버를 다시 로드하는 것만으로는 새 tools가 반영되지 않습니다. 나타나지 않으면 애플리케이션을 완전히 재시작하세요.

## 확장 확인

구현 후 실제 MCP 호출을 통해 tool을 확인하여 handler뿐만 아니라 다음도 검증하세요:

- `tools/list` 등록;
- 입력 스키마;
- 권한;
- 출력 envelope;
- 오류.

Redmine 로그에서 tool 등록 및 확장 로드 오류를 확인하세요.

모든 새 tool에 대해 최소한 다음이 필요합니다:

- 하나의 성공 schema 시나리오;
- 하나의 부정 schema 시나리오.

자세한 자동화 테스트 요구 사항은 [mcp_tool_development.md](mcp_tool_development.md)(§13)에 있습니다.

### 확장 자동화 테스트

플러그인 MCP 확장의 자동화 테스트는 직접 handler 호출뿐만 아니라 **전체 Registry 경로**(`inputSchema` 검증 → permission → handler → `{ok, data | error}` envelope)를 검증해야 합니다(MUST).

`redmine_mcp`가 설치되지 않았거나 로드되지 않은 경우 테스트 클래스는 파일 로드 중 실패하지 않고 시나리오를 **건너뜁니다**(`setup`에서 `skip`):

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

테스트 `setup`에서 `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))`를 호출하여 `Registry`에 tools를 등록하는 것은 허용됩니다. 플러그인 프로덕션 코드에서 `ExtensionLoader`를 호출하지 마세요(「확장 로드 및 비활성화」 참조).

실제 응답을 게시된 `outputSchema`(`mcp_tool_development.md` §7.1)와 비교하려면 `json_schemer`를 사용하세요 — `RedmineMcp::InputValidator`가 input schema에 적용하는 것과 동일한 라이브러리입니다.

테스트 helper 내부에서 `json_schemer`의 지연 로딩은 허용됩니다. 환경에 라이브러리가 없으면 확인을 명시적으로 건너뛰어 선택적 의존성으로 인해 플러그인 테스트가 실패하지 않도록 해야 합니다.

읽기 전용 확장 tool의 최소 자동화 테스트:

- `outputSchema` 검증이 포함된 하나의 성공 Registry 호출;
- `inputSchema`에 의해 거부된 하나의 부정 호출(예: `oneOf`, enum, `maxItems` 위반);
- 필요한 경우 — 별도의 handler 수준 서버 검증 테스트(schema는 서버 측 확인을 대체하지 않음. `mcp_tool_development.md` §3.4 참조).

## 문제 해결

| 문제 | 확인 사항 |
|---|---|
| 확장이 로드되지 않음 | `mcp.rb` 경로, 모듈 이름 `Mcp`, MCP 활성화 여부, Rails log |
| tool/resource/prompt이 나타나지 않음 | `plugin_id` 설정 여부, 확장 비활성화 여부, 이름 또는 URI 충돌, 사용자에게 필요한 permission 보유 여부 |
| 편집 후 변경 사항이 반영되지 않음 | Redmine 재시작; Cursor 및 유사 클라이언트에서 MCP 서버를 다시 로드하는 것만으로는 새 tools가 반영되지 않을 수 있음 — 애플리케이션을 완전히 재시작 |
| `extend_tool`이 작동하지 않음 | 기본 tool 등록 여부, `extra_params`가 기존 schema와 충돌하는지 |

### 병합 전 체크리스트

- [ ] tool에 `title`, `description`, `input_schema`, `output_schema`, `permission`, `annotations`가 있음.
- [ ] 모든 `*_id`에 discovery path가 있음.
- [ ] description, output_schema, 실제 응답이 일치함.
- [ ] 변경 tool이 읽기 전용 모드를 준수함.
- [ ] MCP 전용 로직이 lambda/handler 내부에서 비대해지지 않음.
- [ ] 공유 helper를 `redmine_mcp`에서 복사하지 않고 재사용함.
- [ ] 최소 하나의 성공 및 하나의 부정 schema 시나리오를 실행함.
