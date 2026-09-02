# 다른 플러그인용 Extension API

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## 개요

Redmine MCP는 다른 설치된 Redmine 플러그인이 자체 tools, resources, prompts를 등록하고 기존 도구를 확장할 수 있는 확장 메커니즘을 제공합니다.

## 목표

MCP 서버를 중복하거나 Redmine MCP 코드를 변경하지 않고 Redmine 플러그인을 AI와 통합하는 단일 접근 방식을 제공합니다.

## 영향을 받는 영역

- 플러그인
- API
- 권한

## 비즈니스 규칙

### 자동 검색

- Redmine 시작 시(MCP가 활성화된 경우) 시스템은 설치된 모든 플러그인을 확인합니다.
- 다음 경로 중 하나에 `mcp.rb` 파일이 있으면 플러그인은 MCP 확장이 있는 것으로 간주됩니다.
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<plugin directory basename>/mcp.rb`;
  - 식별자가 `redmine_`로 시작하는 경우 `lib/<plugin.id without redmine_ prefix>/mcp.rb`(일반적인 방식: `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- `redmine_mcp` 플러그인은 확장으로 자신을 로드하지 않습니다.
- 설정에서 MCP 확장 체크박스가 해제된 플러그인은 건너뜁니다.
- 하나의 플러그인 확장 실패는 확장 파일의 구문 오류를 포함하여 다른 플러그인 로드를 차단하지 않습니다.

### 도구 등록

- 확장 플러그인은 임의 수의 도구를 등록할 수 있습니다.
- 각 도구에는 name, description, input schema, output schema, permission requirement, handler가 있습니다.
- 전체 도구 이름: `redmine_<plugin_id>_<name>`. 예: `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- 중복 도구 이름은 금지됩니다.
- 도구는 해당 권한을 가진 사용자에게만 MCP에 나타납니다.
- 이슈 범위 확장 도구는 활성화된 Redmine 프로젝트 모듈을 요구할 수 있습니다(모듈 식별자가 플러그인 id와 일치할 필요는 없음). `tools/list`에서 그러한 도구는 사용자가 해당 모듈이 있는 최소 하나의 보이는 프로젝트에서 선언된 권한을 가질 때 보입니다. 모듈 요구사항이 없으면 최소 하나의 보이는 프로젝트에서 권한이 있으면 충분합니다. 호출 시 특정 이슈를 확인합니다: 가시성, 프로젝트 권한, 활성화된 모듈; 그렇지 않으면 "not found" 응답.
- MCP 읽기 전용 모드에서 확장 쓰기 도구는 handler를 실행하지 않습니다. 거부는 코어 쓰기 도구와 동일합니다.

### 기존 도구 확장

- 플러그인은 이미 등록된 도구를 확장할 수 있습니다.
- 확장은 다음을 수행할 수 있습니다.
  - 추가 입력 매개변수 추가;
  - 메인 handler 전에 코드 실행;
  - handler 후에 코드를 실행하고 결과 수정.
- 여러 플러그인이 동시에 같은 도구를 확장할 수 있습니다.
- 추가 매개변수는 공유 input schema에 병합됩니다.
- 추가 매개변수 이름은 코어 도구 매개변수 또는 같은 도구의 다른 확장 매개변수와 일치해서는 안 됩니다.
- 결과 schema는 `tools/list` 게시 전에 정규화됩니다.
- 확장 실행 순서는 플러그인 로드 순서와 일치합니다.

### 리소스 등록

- 플러그인은 고유 URI로 리소스를 게시할 수 있습니다. 같은 URI 재등록은 거부됩니다.
- 리소스에는 read handler가 있어야 합니다.
- 권장 URI scheme: `redmine://<plugin_id>/<type>/<id>`.
- 리소스는 권한 확인을 요구할 수 있습니다. 권한이 없으면 리소스를 사용할 수 없습니다.
- 권한 확인은 URI와 인수를 받습니다. 프로젝트는 `project` / `project_id`, URI(쿼리 또는 `/projects/:id` 세그먼트의 `project`/`project_id`), 또는 확장이 정의한 명시적 프로젝트 resolver에서 가져옵니다. `resources/read`는 확인에 `{uri: ...}`를 전달합니다.
- 호출에 프로젝트가 지정되었지만 찾을 수 없거나 현재 사용자에게 접근 불가하면 접근이 거부됩니다. "최소 하나의 프로젝트" 확인은 프로젝트가 지정되지 않은 경우(빈 인수로 discovery)에만 적용됩니다.
- 리소스 읽기는 텍스트 또는 JSON 형식으로 내용을 반환합니다.

### prompt 등록

- 플러그인은 name, description, arguments, handler가 있는 prompt를 추가할 수 있습니다.
- 전체 prompt 이름: `redmine_<plugin_id>_<name>`.
- prompt는 해당 권한을 가진 사용자에게 사용 가능합니다. 권한 확인은 `project` / `project_id`를 포함한 호출 인수를 받습니다. 프로젝트가 지정되었지만 찾을 수 없거나 접근 불가하면 접근이 거부됩니다. 프로젝트가 지정되지 않으면 리소스와 동일한 discovery 규칙이 적용됩니다.

### 이벤트(hooks)

- 플러그인은 MCP 수명 주기 이벤트를 구독할 수 있습니다. 예:
  - 도구 등록;
  - 리소스 등록;
  - prompt 등록;
  - 모든 확장 로드 완료.
- 이벤트 handler 오류는 로그에 기록되며 메인 프로세스를 중단하지 않습니다.

### 의존성

- 확장 플러그인은 Redmine MCP에 대한 강한 의존성을 선언할 필요가 없습니다.
- 등록 전 `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` 확인을 권장합니다.
- 확장 플러그인은 MCP gem을 포함할 필요가 없습니다. Redmine MCP API만으로 충분합니다.

### Extension API 기능

Extension API를 통해 확장 플러그인은 다음을 수행할 수 있습니다.

- MCP가 활성화되고 확장이 비활성화되지 않았는지 확인;
- 도구를 한 번만 등록(재로드 시 중복 없음);
- 표준 권한 확인 및 이슈 조회가 있는 이슈 범위 도구 등록; handler 실행 전 이슈가 사라진 경우 내부 오류가 아닌 "not found" 응답;
- 매개변수 및 before/after handler로 기존 코어 도구 확장;
- `redmine_get_mcp_info`용 capability 모드 등록(예: `issue_search.semantic`);
- `internal_request`를 통해 현재 사용자를 대신하여 프로세스 내 Redmine 또는 플러그인 REST API 호출(`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; 대상 엔드포인트는 API auth 수락); REST 오류는 내부 요청 HTTP 상태 없이 정규 MCP 코드로 매핑;
- `{ ok, data | error }` 래퍼 형식으로 `outputSchema` 게시.

Ruby API 메서드 목록과 코드 예제는 플러그인 README 및 [mcp_tool_development.md](mcp_tool_development.md)(dev guide, 행동 SPEC 아님)에 있습니다.

## 엣지 케이스

- 확장 파일이 없는 플러그인은 무시됩니다.
- 확장 파일이 있지만 `require`가 실패하면 — 로그 항목, 확장은 로드된 것으로 간주되지 않음; 도구 등록은 성공적인 `require`의 부수 효과.
- 존재하지 않는 도구 확장 시도 — 확장 등록 중 오류.
- 설정에서 MCP 확장 체크박스가 해제된 플러그인은 확장 파일이 있어도 로드되지 않습니다.
- 새 확장 설치 후 Redmine 재시작이 필요합니다. MCP 클라이언트는 재연결이 필요할 수 있습니다.

## 오류 처리

- 확장 파일 로드 오류 — 로그 항목, 다른 플러그인 로드 계속.
- 시작 시 도구 등록 오류 — 로그 항목.
- 확장 `before` handler 오류 — 도구 실행 중단.
- `after` handler 오류 — 로그; handler가 제어 흐름을 변경하지 않으면 메인 handler 결과 유지.

## 테스트 시나리오

8. 빈 인수로 리소스 및 prompt discovery는 최소 하나의 프로젝트에서 권한이 있으면 계속 사용 가능.
9. `redmine_*` 같은 `plugin.id`와 `lib/<id without redmine_ prefix>/mcp.rb` 파일이 있는 플러그인 — MCP 통합이 있는 것으로 간주되며 MCP 확장 설정에 나타남.
10. 모듈 요구사항이 있는 이슈 범위 도구 — 다른 프로젝트에서 권한이 있어도 해당 모듈이 있는 보이는 프로젝트가 없으면 사용자의 `tools/list`에 없음.

## 확장 예제

| 플러그인 | 도구 | 목적 |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | 시맨틱 이슈 검색 |
