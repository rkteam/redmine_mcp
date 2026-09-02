# Redmine MCP 도구 개발 요구사항

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**상태:** 개발자 가이드(dev-guide), behavioral 플러그인 SPEC 아님  
**버전:** 1.6  
**날짜:** 2026-08-20  
**적용 범위:** 모든 새 Redmine MCP 도구 및 기존 도구의 중대한 변경  
**기본 MCP 버전:** Protocol Revision `2025-11-25`

core tools의 behavioral 계약은 `03-core-tools.md` 및 관련 SPEC에 있습니다. 이 문서는 도구 설계 및 구현 규칙을 정의합니다.

---

## 1. 이 문서의 목적

이 문서는 Redmine용 MCP 도구를 설계, 구현, 설명, 테스트, 게시하기 위한 통일된 요구사항을 수립합니다. 아키텍처 구현 패턴은 부록 A에 모아 두었으며, 본문의 필수 요구사항과 섞지 않습니다.

이 표준의 목표는 도구를 다음과 같게 만드는 것입니다.

- 언어 모델 선택에 모호하지 않게;
- 자동 호출 시 안전하게;
- MCP 클라이언트에 예측 가능하게;
- 엄격하게 검증되게;
- 유지보수 및 하위 호환이 쉽게;
- 반복 호출, 모델 오류, 부분적으로 채워진 인수에 견고하게.

요구사항은 현재 Redmine MCP 감사를 염두에 두고 작성되었습니다. 이 문서 작성 시점에 서버는 46개 도구를 게시했으며, 계약에서 `type` 없는 매개변수, `enum` 대신 허용 값 문자열 목록, 범용 `manage_*` 도구, `outputSchema` 누락이 확인되었습니다.

---

## 2. 의무 표현 용어

이 문서에서는 다음 수준을 사용합니다.

- **MUST / MUST** — 필수 요구사항. 위반 시 merge가 차단됩니다.
- **MUST NOT / FORBIDDEN** — 필수 금지.
- **SHOULD / SHOULD** — 기본적으로 따라야 하는 요구사항; merge request에서 편차를 정당화해야 합니다.
- **MAY / MAY** — 허용되는 선택.

모든 도구에 필수는 아닌 아키텍처 및 구현 패턴은 **부록 A**에 모았습니다. 특정 도구에 대해 의도적으로 채택하지 않아도 merge를 차단하지 않습니다.

---

## 3. 핵심 설계 원칙

### 3.1. 하나의 도구 — 하나의 명확한 동작

도구는 MUST 하나의 원자적 사용자 의도를 나타냅니다.

좋은 예:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

나쁜 예:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

`action: create | update | delete | list`와 같은 매개변수를 가진 도구는 다음 경우 FORBIDDEN입니다.

- 서로 다른 필수 인수가 필요할 때;
- 위험 수준이 다를 때;
- 서로 다른 MCP annotations가 있어야 할 때;
- 서로 다른 데이터 구조를 반환할 때;
- 서로 다른 Redmine 권한이 필요할 때.

예외는 모든 변형이 동일한 위험과 단일 계약을 가진 의미적으로 동질적인 작업에만 허용됩니다. 예외는 명시적으로 정당화해야 합니다.

### 3.2. 읽기, 추가, 수정, 삭제는 분리

하나의 도구에서 다음을 결합하는 것은 FORBIDDEN입니다.

- 읽기 전용 및 쓰기 작업;
- 추가 및 삭제 작업;
- 일반 사용자 및 관리 작업;
- 로컬 Redmine 작업 및 외부로 데이터 전송.

예를 들어 `list/create/delete relation`은 세 개의 별도 도구여야 합니다.

### 3.3. 계약이 서버 구현 편의보다 중요

핸들러 구현이 더 쉽다는 이유만으로 내부 Ruby/Python/REST 메서드 구조를 그대로 게시하지 않습니다.

MCP 계약은 모델과 클라이언트를 위해 설계되며, 서버 내부 어댑터가 Redmine API 형식으로 변환합니다.

플러그인 또는 Redmine의 내부 기술 값은 의미 있는 외부 계약의 일부가 아니면 MUST 정규화됩니다.

불필요하게 게시하지 않습니다.

- Ruby/Rails 클래스 이름 및 STI 타입;
- MCP가 입력에서 이미 다른 값을 사용하는 경우 내부 enum 이름;
- 로케일 의존 날짜;
- MCP가 이미 정규 형식을 정의한 경우 동일 필드의 REST 전용 표현;
- MCP가 이미 정규화된 값을 사용하는 경우 기술적 이름.

예: 입력 필터 `type` — `contact` / `company`; 응답에서도 `contact` / `company`이며, `Clientdesk::Contact` / `Clientdesk::Company`가 아닙니다. serializer가 STI 클래스나 로컬화된 날짜를 반환하면 MCP 어댑터는 MUST 값을 게시된 schema에 맞춥니다.

### 3.4. 서버는 모델을 신뢰하지 않음

모든 인수는 신뢰할 수 없는 것으로 간주됩니다. 서버는 MUST 다음을 재확인합니다.

- 타입;
- 범위;
- 필드 상호 의존성;
- 현재 사용자의 권한;
- 프로젝트에 속한 객체;
- 특정 workflow에서 값의 사용 가능 여부;
- Redmine 제약;
- 현재 객체 상태에서 작업 허용 여부.

JSON Schema, description, annotations, 클라이언트 확인은 서버 측 검증을 대체하지 않습니다.

---

## 4. 도구 이름

### 4.1. 이름 형식

게시되는 모든 도구 이름은 MUST `redmine_`로 시작합니다.

`redmine_mcp` 플러그인의 core tools는 짧은 접두사 `redmine_`를 사용합니다.

```text
redmine_<verb>_<entity>
```

서드파티 플러그인 도구의 전체 이름은 MUST `redmine_`로 시작합니다.

- `redmine_<plugin_id>_<verb>_<entity>`.

요구사항:

- `lower_snake_case`만 사용;
- 서드파티 플러그인 확장을 포함해 모든 도구에 `redmine_` 접두사 필수;
- 서버 내에서 이름은 고유;
- 내부 제한 — 64자 이하;
- deprecation 절차 없이 이름 변경 금지.

예:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. 허용 동사

권장 동사:

| 동사 | 목적 |
|---|---|
| `get` | 정확한 식별자로 하나의 객체 조회 |
| `list` | 구조화된 필터로 컬렉션 조회 |
| `search` | 텍스트 또는 전문 검색 수행 |
| `create` | 객체 생성 |
| `update` | 기존 객체 수정 |
| `set` | 특정 필드 또는 플래그를 지정 값으로 설정 |
| `delete` | 객체 삭제 |
| `add` | 기존 객체에 관계 또는 멤버 추가 |
| `remove` | 주 객체를 삭제하지 않고 관계 제거 |
| `copy` | 복사본 생성 |
| `upload` | 파일 업로드 |
| `download` | 파일 내용 조회 |
| `send` | 외부 수신자에게 메시지 또는 데이터 전송 |
| `summarize` | 서버 측 집계 보고서 생성 |

모호한 동사(`manage`, `process`, `handle`, `execute`, `do`)는 사용하지 않습니다 — §3.1 참조.

동사는 MUST 실제 작업 의미와 일치합니다. 도구가 boolean 플래그를 토글하면(`enabled: true | false` 같은 매개변수) SHOULD `set`으로 이름 짓고, 한 값만 의미하는 동사는 사용하지 않습니다.

나쁜 예:

```text
redmine_advanced_search_enable_semantic_index
```

`enable`은 `enabled = true`만 의미하지만 매개변수는 `false`도 허용합니다. 이름이 실제 동작과 맞지 않습니다.

좋은 예:

```text
redmine_advanced_search_set_semantic_index_enabled
```

`set_*` 이름은 전달된 값으로 플래그를 설정하는 작업을 정직하게 반영합니다.

### 4.3. 식별자 매개변수 이름

매개변수 이름은 MUST 실제 타입과 일치합니다.

- `issue_id` — 정수 ID만;
- `project_id` — 정수 ID만;
- `project_identifier` — Redmine 문자열 식별자;
- `project` — 두 표현을 의도적으로 허용하고 참조로 문서화된 문자열.

`*_id` 이름의 매개변수는 문자열 식별자나 `"me"` 값을 받을 수 없습니다.

숫자 ID는 MUST `minimum: 1`과 의미 있는 `description`을 가집니다. `minimum` 없이 `"Issue id"` 같은 표현은 FORBIDDEN입니다.

나쁜 예:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

좋은 예:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

프로젝트에 권장되는 통일 옵션은 숫자 ID(문자열) 또는 문자열 식별자를 받는 매개변수 `project`입니다.

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

`examples` 배열(§6.15)은 모델에 허용된 값 형식을 모두 보여 주며 잘못된 입력 가능성을 줄입니다.

### 4.4. 낙관적 잠금: `expected_updated_at`

이전에 알려진 객체 타임스탬프를 전달해 오래된 변경을 거부하는 매개변수는 core tools와 확장 모두에서 MUST `expected_updated_at`으로 이름 지어야 합니다.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

이 의미로 `updated_at` 이름은 FORBIDDEN입니다. 실제로는 낙관적 잠금 값인데 "새 수정 시각"처럼 보입니다.

나쁜 예(checklist 및 모든 확장):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

좋은 예:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

실제 객체 수정 시각을 보고하는 응답 필드는 MAY 여전히 `updated_at` / `updated_on`으로 이름 지을 수 있습니다 — 혼동은 잠금 입력 매개변수에서만 발생합니다.

충돌 시 규범적 동작은 부록 A.2에 있습니다.

---

## 5. `title` 및 `description`

### 5.1. `title`

`title`은 MUST 기술적 이름의 복사가 아닌 짧은 사람이 읽을 수 있는 이름입니다.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. 도구 description

`description`은 MUST 다음 핵심 질문에 간략히 답합니다.

1. 도구가 무엇을 하며 어떤 객체를 읽거나 수정하는가?
2. 기본적으로 포함되지 않는 것은 무엇이며 어떻게 요청하는가?
3. 중대한 부작용이 있는가?
4. ID 또는 허용 값을 모를 때 어떤 사전 도구를 호출해야 하는가?

Description은 MUST 간결하고 읽기 쉬워야 합니다. 모든 필드와 include 옵션을 나열하는 긴 반 페이지 단락으로 만드는 것은 FORBIDDEN입니다. 과도한 description은 짧고 구조화된 것보다 모델이 읽기 어렵습니다.

SHOULD 연속 텍스트가 아닌 여러 짧은 줄 또는 목록으로 작성합니다. 기본값과 변경 방법은 간결하게 표시합니다.

좋은 예:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

나쁜 예 — 너무 짧아 결과와 기본 동작을 설명하지 않음:

```text
Gets issue.
```

나쁜 예 — 과도하게 길고 모든 필드를 나열:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. 다른 도구 참조

description, 매개변수 description, 서버 instructions가 다른 도구를 참조할 때 MUST `tools/list`의 전체 등록 이름을 사용하고, 접두사 없는 짧은 `name`은 사용하지 않습니다.

나쁜 예:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

좋은 예:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

짧은 이름은 플러그인 간 모호하며 모델이 접두사를 추측하게 합니다. 확장에서 특히 중요합니다. `redmine_advanced_search_` 접두사 없는 `semantic_search_issues`는 존재하지 않는 core tool과 혼동되기 쉽습니다.

### 5.2.2. 반환 결과 description

Description은 MUST 도구 결과를 간략히 설명해 모델이 한 번의 호출로 충분한지 다음 도구가 필요한지 이해하게 합니다.

결과 description은 다음을 나타내야 합니다.

- 하나의 객체, 컬렉션, 집계, 변경 확인, 또는 리소스 참조 중 무엇을 반환하는지;
- 기본적으로 포함되는 관련 데이터;
- 명시적 매개변수 없이는 포함되지 않는 대용량 또는 민감 데이터;
- 페이지네이션이 있는지 및 표준 limit;
- 쓰기 도구가 전체 업데이트 객체를 반환하는지, 식별자·URL·수정 시각만 반환하는지;
- bulk 작업에서 부분 성공이 가능한지.

읽기 예:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

목록 예:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

쓰기 예:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

description과 `outputSchema`의 관계 — §7.1 및 §7.1.1 참조. 목록이 이미 필드를 반환하면 description은 MUST 그 필드만 위해 모델을 `get_*`로 보내지 않습니다.

### 5.3. Description은 schema를 대체하지 않음

제약을 텍스트에만 두는 것은 FORBIDDEN입니다.

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

`enum`, `const`, 범위, 조건부 schema를 사용합니다.

상호 배타적 필드에도 동일합니다. `description`이 "`user_id` 또는 `group_id` 중 정확히 하나"라고 하지만 `required`에 공통 필드만 있으면 schema와 텍스트가 어긋납니다. 제약은 MUST `inputSchema`에 형식화합니다(§6.12).

### 5.4. 예측 가능한 선택

유사 도구의 description은 차이를 명시적으로 설명해야 합니다.

예:

- `redmine_list_project_members` — 특정 프로젝트 멤버 및 역할;
- `redmine_admin_list_users` — 설치 전체 사용자 목록, 관리 권한 필요.

### 5.5. 서버 수준 instructions

서버는 MAY 도구 간 관계와 workflow 규칙을 설명하는 짧은 일반 instructions를 게시합니다.

Instructions는 개별 description에 없는 맥락을 추가하고 전체 이름으로 도구를 참조해야 합니다(§5.2.1). 예:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

FORBIDDEN:

- 서버 instructions에 모든 도구 description 반복;
- 서버와 무관한 일반 모델 동작 instructions 배치;
- 짧은 라우팅 규칙 대신 긴 가이드 작성;
- 마케팅 문구 사용;
- 접두사 없는 짧은 이름으로 도구 참조(`redmine_list_projects` 대신 `list_projects`).

### 5.6. 개발 전 Redmine REST API 학습

도구를 새로 만들거나 중대하게 변경하기 전 개발자는 SHOULD 문서 조사를 수행합니다. 기존 MCP 코드, 개발자 기억, 단일 HTTP 요청 예만으로 계약을 설계하는 것은 권장하지 않습니다.

SHOULD 다음을 학습합니다.

1. Redmine REST API 메인 페이지: 일반 인증, 페이지네이션, `include`, custom fields, 파일, 검증 오류 규칙.
2. 해당 리소스별 API 페이지. 예: Issues, Time Entries, Versions, Wiki Pages, Project Memberships.
3. API 변경 이력 및 지원 Redmine 버전별 변경.
4. MCP가 사용하는 실제 Redmine 버전 및 최소 지원 버전.
5. 도구가 플러그인 엔티티나 필드를 다루면 사용 Redmine 플러그인의 REST API 및 소스 코드. 확장 도구 게시 전 MUST 소스 serializer / service / REST endpoint 및 각 결과 형식(list와 get, 둘 다 게시 시)에 대해 최소 하나의 실제 성공 응답을 확인.
6. 대상 설치의 실제 권한, workflow, 활성 모듈, tracker, custom field, 제약.
7. 중복 또는 충돌 계약을 피하기 위해 이미 게시된 MCP 도구.

메인 페이지 `https://www.redmine.org/projects/redmine/wiki/rest_api`는 진입점이지만 특정 도구에는 보통 불충분합니다. SHOULD 해당 리소스 페이지로 가 operations, query parameters, `include`, request fields, response structure, error codes, version constraints를 확인.

### 5.7. API 커버리지 보고서

새 도구 구현 전 개발자는 SHOULD merge request에 간략한 API coverage 표를 첨부합니다.

| 필드 | 내용 |
|---|---|
| Redmine resource | 리소스 및 공식 API 페이지 링크 |
| Endpoint | HTTP method 및 path |
| Supported since | 최소 Redmine 버전 |
| Request parameters | 문서화된 모든 request parameters |
| Query filters | 문서화된 모든 필터 및 특수 값 |
| Include values | 허용 관련 데이터 |
| Required/defaults | 필수 필드 및 기본값 |
| Response | 주요 필드 및 응답 변형 |
| Errors | HTTP 코드 및 오류 구조 |
| Permissions | 필요 권한 및 impersonation 특성 |
| MCP exposure | MCP에 게시되는 매개변수 |
| Intentionally omitted | 게시하지 않는 매개변수 및 이유 |
| Plugin/version differences | 플러그인 및 지원 버전 차이 |

표의 목표는 반드시 모든 Redmine 매개변수를 MCP에 게시하는 것이 아닙니다. 목표는 매개변수를 실수로 빠뜨리지 않고 게시 결정을 의식적으로 내리는 것입니다.

Redmine 매개변수는 다음 경우 MCP에서 제외될 수 있습니다.

- 위험하거나 관리용;
- 별도의 더 명확한 도구와 중복;
- 지원 버전 간 불안정;
- 모호한 schema 생성;
- 대상 사용자 시나리오에 불필요;
- 과도하게 큰 응답 유발.

각 중대한 제외는 `Intentionally omitted`에 간략한 정당화와 함께 기록합니다.

### 5.8. 도구를 개발하는 AI agent용 instructions

AI agent가 도구를 만들거나 변경하면 작업 instructions는 SHOULD 이 문서를 참조합니다. API 조사(§5.6–5.7), 계약(§3–§8), 테스트(§13), checklist(§14).

권장 텍스트:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. `inputSchema` 요구사항

### 6.1. 기본 구조

모든 도구는 MUST 유효한 JSON Schema를 가져야 합니다.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

인수가 없는 도구:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. 문서화되지 않은 속성 금지

최상위 및 모든 중첩 객체에서:

```json
"additionalProperties": false
```

오픈 딕셔너리는 의도적으로만 허용됩니다. 이 경우 값 schema를 명시적으로 설정합니다:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. 각 매개변수의 타입

모든 속성은 MUST `type`, `$ref`, 또는 `oneOf` / `anyOf` / `allOf` 합성을 포함해야 합니다.

FORBIDDEN:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. 필수 매개변수

`required` 배열은 최소 실행 가능한 호출을 반영해야 합니다.

매개변수 없이는 작업이 불가능하면 해당 매개변수는 MUST `required`에 있어야 합니다.

예를 들어 파일 업로드에는 최소한 다음이 필요합니다:

```json
"required": ["project", "filename", "content_base64"]
```

삭제의 `confirm=true` 검사는 필드가 `required`에 있어도 서버에서 수행됩니다(§3.4).

### 6.5. 열거

유한한 값 집합에는 MUST `enum` 또는 `const`를 사용합니다(description 텍스트만으로는 불가 — §5.3 참조).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. 문자열

문자열에는 적절한 제약이 필요합니다:

- 비어 있지 않은 값에는 `minLength`;
- Redmine 제약 또는 내부 제한에 따른 `maxLength`;
- 형식이 엄격히 정의된 경우 `pattern`;
- 표준 형식이 적용되는 경우 `format`.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

schema의 `format` 제약은 서버 측 검증을 대체하지 않습니다(§3.4).

### 6.7. 숫자

숫자 매개변수에는 MUST 합리적인 경계를 설정합니다.

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

`default` 값은 계약과 문서의 일부입니다. 서버는 클라이언트가 스스로 기본값을 대입할 것이라 가정해서는 안 됩니다.

### 6.8. 배열

모든 배열은 MUST `items`를 가져야 합니다.

필요 시 설정:

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

요소 schema 없이 `entries: array` 같은 배열은 FORBIDDEN입니다.

### 6.9. 중첩 객체

모든 중첩 객체는 완전히 기술합니다.

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

### 6.10. 「객체 또는 JSON 문자열」은 받지 않음

하나의 매개변수를 「객체 또는 JSON 문자열」로 기술하는 것은 FORBIDDEN입니다.

MCP는 이미 구조화된 JSON을 전달합니다. 도구는 객체를 받아야 하며, 서버가 다시 파싱하는 문자열이 아닙니다.

### 6.11. 범용 `fields` 및 `extra_fields`

`fields`, `extra_fields`, `payload`, `data` 및 유사한 오픈 객체 매개변수는 주요 비즈니스 작업에서 FORBIDDEN입니다.

이슈 필드는 의미 있는 `description`(§6.14)과, 유용한 경우 `examples`(§6.15)와 함께 명시적으로 나열해야 합니다:

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

드물게 쓰이는 필드는 엄격히 기술된 `custom_fields`를 통해 전달할 수 있습니다.

### 6.12. 상호 의존 필드

도구 분할을 우선합니다. 분할이 불가능하면 의존성은 다음으로 형식화합니다:

- `dependentRequired`;
- `if` / `then` / `else`;
- 상호 배타적 분기를 가진 `oneOf`.

`description`의 텍스트(「… 중 정확히 하나」)는 schema를 대체하지 않습니다(§5.3).

전형적인 경우 — 「두 필드 중 정확히 하나」. 나쁜 예: `required`에 공통 필드만, XOR는 산문에 남음:

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

이 schema는 `user_id`/`group_id` 없는 호출과 두 필드를 동시에 넣는 호출을 허용합니다.

좋은 예 — 공통 `required`와 최상위 `oneOf`:

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

서버 측 검증(§3.4)은 MUST 여전히 두 잘못된 변형을 거부합니다. schema는 클라이언트와 모델이 호출 전에 제약을 볼 수 있게 합니다.

선택한 구성이 지원되는 MCP 클라이언트 및 SDK와 호환되는지 검증해야 합니다.

### 6.13. `null` 값 필드 및 값 지우기

`null`은 별도로 문서화된 의미가 있을 때만 허용됩니다. 예: 「마감일 지우기」 또는 「담당자 해제」.

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

빈 문자열을 `null`의 암묵적 동등물로 사용하지 않습니다.

선택적 필드(마감일, 담당자 등)를 설정하는 `set_*` 도구에서는 계약이 MUST 지우기를 명시적으로 결정해야 합니다. 세 가지 옵션이 허용됩니다 — 우선순:

1. **같은 도구가 `null`을 받음**(권장), 위와 같이: 하나의 의도 「설정 또는 지우기」.
2. **별도 clear/unassign 도구**, API 또는 UX가 작업을 더 적절히 분리할 때. 예: `redmine_advanced_search_clear_saved_query`와 `redmine_advanced_search_unassign_search_owner`.
3. **명시적 거부**: MCP로 지우기가 지원되지 않으면 MUST 도구 `description` 및/또는 매개변수 description에 명시합니다. 설명 없이 「null 없는 string/integer만」인 암묵적 계약은 FORBIDDEN — 모델은 지우기가 불가능하다고 오해하거나 `""` / `0`을 넘기려 합니다.

나쁜 예 — 마감일은 설정할 수 있으나 지울 수 없고, 어디에도 명시되지 않음:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. 매개변수 description

`inputSchema.properties`의 모든 매개변수는 MUST 의미 있는 `description`을 가져야 합니다. `description` 없는 매개변수는 FORBIDDEN입니다. 확장(checklist 항목 `done`, `sort_order`, `due_date`, ID 필드 등)과 명확한 `enum`을 가진 선택 필드도 포함합니다.

「Filter by tracker ID」, 「Tracker id」, 「Issue id」 같은 description은 불충분합니다: 허용 값을 어디서 얻는지, 어떤 제약이 있는지를 알려주지 않습니다.

식별자 매개변수 description은 MUST 허용 값에 사용할 도구 또는 응답 필드(전체 이름 — §5.2.1; 디스커버리 — §6.16)를 나타내고, 중요한 제약(workflow, 권한, 프로젝트 소속)을 언급해야 합니다.

나쁜 예:

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

좋은 예:

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

제약을 명시한 좋은 예:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

매개변수 description은 schema(§5.3)와 서버 측 검증(§3.4)을 대체하지 않습니다.

### 6.15. 값 예시(`examples`)

값 형식이 자명하지 않거나 여러 표현을 허용하는 매개변수에는 SHOULD `examples`를 추가합니다 — 표준 JSON Schema 배열 키. 예시는 모델이 올바른 값을 입력하는 데 도움이 되며, 참조 매개변수, 식별자, 날짜, enum 유사 문자열에 특히 유용합니다.

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

요구사항:

- `examples` 값은 MUST 매개변수 schema 자체에 대해 유효해야 합니다;
- `examples`는 형식을 보여 주지만 `enum`, 범위 및 기타 제약을 대체하지 않습니다(§5.3, §6.5);
- `enum`이 있는 매개변수에서는 별도 `examples`가 보통 중복입니다.

MCP 클라이언트 또는 SDK가 schema의 `examples`를 지원하지 않으면 MAY 동일한 의미로 확장 키 `x-examples`를 사용할 수 있습니다.

### 6.16. ID 매개변수의 디스커버리 경로

모델이 추측할 수 없는 `*_id` 형식 매개변수는 MUST 명시적 디스커버리 경로가 있어야 합니다: 별도 read/list 도구, 또는 매개변수 `description`(§6.14)에서 참조되는 다른 read 도구 응답의 필드.

허용 옵션(도구 집합에서 우선순):

1. **별도 list/디스커버리 도구** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **get/list 응답 내 옵션** — 예: `redmine_advanced_search_semantic_search_issues` 응답의 `id`와 `name`을 가진 provider 배열. 이 경우 description은 MUST 전체 도구 이름으로 해당 응답 필드를 참조해야 합니다.
3. **schema의 안정적 enum**, 값 집합이 고정되고 작을 때.

위 항목을 하나도 만족하지 않으면 `status_id` / `role_ids` / 유사한 쓰기 도구를 게시하는 것은 FORBIDDEN입니다: 모델이 ID를 추측해야 합니다.

나쁜 예 — 디스커버리 없는 쓰기:

- `provider_id`를 가진 `redmine_advanced_search_set_search_provider`가 존재;
- `redmine_advanced_search_list_search_providers` 없음;
- `semantic_search_issues`는 현재 provider 이름(`provider: "…"`)만 반환하고, 허용 값과 그 `id` 목록 없음.

이 경우 `"Search provider ID."` 같은 description은 불충분합니다. list 도구를 추가하거나 get 응답에 provider 옵션을 포함하고 다음처럼 작성합니다:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

이 규칙은 core와 확장(§18)에 적용됩니다.

---

## 7. `outputSchema` 및 결과 요구사항

### 7.1. 출력 스키마

새 도구는 MUST `outputSchema`를 게시해야 합니다. schema는 엔벨로프 형태 `{ ok, data | error }`만이 아니라 안정적인 공개 응답 계약을 기술합니다.

`description`이 명명된 필드 또는 중첩 구조를 반환한다고 주장하면 `outputSchema`는 MUST 해당 필드를 형식화해야 하며, 최상위 `data` / `items`를 「임의 객체」로만 제한해서는 안 됩니다.

나쁜 예: description이 `query`, `results`, 스니펫, 첨부 발췌를 나열하지만 `outputSchema`가 없거나 `items`를 `{ "type": "object", "additionalProperties": true }`만으로 기술.

각 안정 결과 필드에 대해:

- MUST 타입을 지정;
- 보장되는 필드는 MUST `required`에 포함;
- 유한 값 집합은 MUST `enum` 또는 `const`로 설정;
- 서버가 해당 형식을 보장하면 날짜에 MUST `format: date` 또는 `date-time`;
- 숫자 ID는 MUST 통일된 타입 유지;
- nullable과 optional은 다른 계약: 필드가 항상 반환되지만 값이 없을 수 있으면 `required`이고 `null`을 허용해야 함;
- 숫자 비즈니스 값에는 필드 이름에서 자명하지 않으면 MUST 단위 지정;
- 금액 값에는 MUST 명확한 의미: 주/부 단위와 통화 결정 방법.

알려진 안정 결과 필드 기술 대신 `additionalProperties: true`를 사용해서는 MUST NOT 됩니다. 하위 호환성 또는 진정 확장 가능한 구조에서는 허용되지만, 그런 객체 내 알려진 비즈니스 필드는 여전히 `properties`에 나열하고 보장되는 것은 `required`에 포함해야 합니다.

목록 도구에서는 `items` 요소가 MUST 모델이 식별, 필터링, 후속 도구 호출에 필요한 최소 필드를 기술해야 합니다.

좋은 예 — `data` 타입 지정 조각(전체 성공/오류 엔벨로프 — §7.2 및 §12):

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

결과는 SHOULD 다음을 반환:

- `structuredContent` — 클라이언트가 안정 구조가 필요할 때의 기계 판독 객체;
- 텍스트 `content` — 하위 호환성과 사람을 위한 간략 표현.

### 7.1.1. 공개 계약 일관성

도구를 완료하기 전 개발자는 MUST 세 가지 표현을 비교해야 합니다:

1. 실제 handler / REST / service 응답;
2. 도구 `description`;
3. `outputSchema`.

서로 모순되어서는 안 됩니다.

description이 필드가 항상 반환된다고 하면 `outputSchema`에서 `required`여야 합니다.

schema가 `enum` / `const` / `format`을 설정하면 실제 serializer는 MUST 값을 그 계약에 맞게 정규화해야 합니다. `format: date`를 게시하면서 로케일 형식 문자열을 약속할 수 없습니다.

목록이 이미 데이터를 반환하면 description은 MUST 같은 데이터만 위해 모델을 get 도구로 보내지 않아야 합니다.

결과의 비즈니스 불변 조건은 MUST 도구 이름에서만 추론하지 않고 schema의 `const`, `enum`, `required`, 또는 조건부 schema로 반영해야 합니다. 예: 구독 도구가 정의상 `subscription` 타입 제품만 반환하면 `product_type`은 불가능한 값을 가진 `enum`이 아니라 `const: "subscription"`이어야 합니다.

### 7.2. 통일 엔벨로프

권장 성공 결과:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

오류:

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

오류 시 추가로 설정:

```json
"isError": true
```

`outputSchema`가 게시되고 오류도 `structuredContent`로 반환되면 schema는 MUST 성공과 오류 두 분기를 기술해야 합니다. 성공만의 schema를 게시하고 호환되지 않는 구조화 오류 객체를 반환할 수 없습니다. 대안: 도구 실행 오류 시 `isError: true`인 텍스트 `content`만 반환하고 `structuredContent`는 반환하지 않음. 권장 옵션 — 두 분기를 가진 통일 타입 엔벨로프.

### 7.3. 필드 안정성

출력 필드는 공개 계약입니다. FORBIDDEN:

- major 변경 없이 필드 타입 변경;
- deprecation 기간 없이 필드 이름 변경;
- 때로는 객체, 때로는 배열 반환;
- ID를 때로는 숫자, 때로는 문자열 반환;
- 무제한 미처리 Redmine API 응답 반환.

### 7.4. 단일 객체 결과

권장 형식:

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

### 7.5. 목록 결과

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

`items` 요소 schema는 §7.1을 따릅니다: 식별자, 라우팅 필드, 안정 비즈니스 필드를 명시적으로 기술. 유일한 요소 설명으로 빈 `{ "type": "object", "additionalProperties": true }`는 FORBIDDEN입니다.

### 7.6. 최소 필요 용량

목록/검색 도구는 기본적으로 MUST 간략한 레코드를 반환해야 합니다. 전체 description, journals, attachments, 큰 텍스트 필드는 별도 `get_*`로 얻어야 합니다.

이는 토큰, 지연, 과도한 민감 데이터 전달 위험을 줄입니다.

### 7.7. 민감 데이터

명시적 필요 없이 결과에 포함해서는 안 됩니다:

- API 토큰;
- Authorization 헤더;
- 쿠키;
- 서버 파일시스템 경로;
- 내부 stack trace;
- 비밀번호와 시크릿;
- 현재 사용자에게 사용 불가한 Redmine 필드;
- 별도 권한 없는 private notes.

---

## 8. MCP 어노테이션

annotations는 클라이언트용 힌트이며 인가 또는 보호 메커니즘이 아닙니다.

### 8.1. 값 매트릭스

| 작업 유형 | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Redmine 데이터 get/find/list | `true` | `false` | `true` | `false` |
| 이슈/버전/checklist 생성 | `false` | `false` | `false` | `false` |
| 댓글/watcher/relation 추가 | `false` | `false` | `false` | `false` |
| 필드 변경, 이름 변경, 플래그 설정(`update`, `rename`, `set`) | `false` | `false` | 구현에 따라 다름 | `false` |
| 삭제, 지우기, 리셋(`delete`, `purge`, `reset`) | `false` | `true` | 보장된 멱등성이 있을 때만 | `false` |
| 외부 수신자에게 이메일 전송 | `false` | `false` | `false` | `true` |
| 임의 URL / 외부 시스템 접근 | 상황에 따라 | 상황에 따라 | 상황에 따라 | `true` |

### 8.2. 규칙

- `readOnlyHint: true`는 도구가 상태를 변경하지 않고 부작용을 일으키지 않을 때만.
- `destructiveHint`는 쓰기 사실이 아니라 비가역적 데이터 손실 또는 파괴를 기술합니다. `destructiveHint: true`는 SHOULD 비가역 작업 — `delete`, `purge`, `reset`, 필드 또는 relation 전체 지우기 — 에만 설정.
- 일반 `update`, `rename`, `set`은 파괴적이지 않음: 이들에 `destructiveHint: false`. 예: `update_checklist_title` 또는 `rename_wiki_page`는 일반 업데이트이며 파괴가 아니므로 destructive annotation은 잘못됨.
- `idempotentHint: true`는 반복 호출이 진정 안전할 때만; SHOULD 테스트로 확인.
- `openWorldHint`는 새 객체가 생성되는지가 아니라 도구가 열리고 이전에 알려지지 않은 외부 세계에 접근하는지를 기술합니다. 하나의 구성된 Redmine 설치 작업은 닫힌 세계: `openWorldHint: false`.
- 따라서 `create_issue`, `create_time_entry` 및 Redmine 내 다른 쓰기 도구는 새 객체를 만들어도 `openWorldHint: false`. 알려진 시스템에서 객체 생성이 세계를 열지는 않음.
- `openWorldHint: true`는 수신자 또는 데이터 소스가 알려진 시스템으로 제한되지 않을 때만: 외부 수신자에게 이메일, 임의 HTTP 요청, 외부 서비스 접근.
- `openWorldHint` 값은 SHOULD 각 도구에 대해 의식적으로 설정; 기본값으로 복사하지 말 것: 도구가 실제로 Redmine 설치를 넘어서는지 검증.
- 하나의 annotation 집합을 모든 쓰기 도구에 복사할 수 없음.

### 8.3. Redmine 부작용

멱등성 평가 시 최종 필드뿐 아니라 다음도 고려:

- journal 항목 생성;
- 알림 전송;
- webhook;
- 감사 로그;
- 반복 파일 업로드;
- 반복 relation 생성;
- 반복 time entry 기록.

반복 호출이 추가 레코드 또는 알림을 만들면 도구는 멱등하지 않습니다.

---

## 9. 보안

### 9.1. 인가

모든 호출은 MUST 인증된 사용자 또는 명시적으로 문서화된 service account 컨텍스트에서 실행되어야 합니다.

서버는 MUST 특정 프로젝트와 객체에 대한 Redmine 권한을 확인해야 합니다. `tools/list`에 도구가 있다고 작업 권한이 있는 것은 아닙니다.

관리 도구는 다음을 해야 합니다:

- 관리자에게만 게시;
- 또는 별도 관리 MCP 프로필/서버로 이동;
- 또는 별도 scope로 보호.

### 9.2. 최소 권한

MCP 서버와 Redmine API 토큰은 MUST 최소 필요 권한을 가져야 합니다. 사용자 접근 모델을 유지해야 하면 모든 사용자에 전역 관리 토큰을 사용할 수 없습니다.

### 9.3. 임의 파일시스템 경로 금지

다음 같은 매개변수:

```json
{"file_path": "/etc/app/.env"}
```

는 공개 MCP 도구에서 FORBIDDEN입니다.

안전한 옵션:

1. 크기 제한이 있는 `content_base64`;
2. 신뢰할 수 있는 업로드 메커니즘이 발급한 불투명 `upload_token`;
3. 호스트가 접근을 확인하는 MCP resource URI;
4. `realpath` 검사와 allowlist가 있는 전용 임시 디렉터리의 파일만.

서버는 MUST 다음을 확인해야 합니다:

- 최대 크기;
- MIME 타입;
- 허용 확장자;
- 파일 이름;
- path traversal 부재;
- 조직 정책에서 요구 시 바이러스/콘텐츠 검사.

### 9.4. 임의 URL 및 SSRF

도구는 그것이 주 목적이 아니면 임의 URL을 받아서는 안 됩니다.

HTTP 접근이 필요할 때:

- 도메인과 scheme allowlist 사용;
- 필요 없으면 loopback, link-local, metadata endpoint, 내부 네트워크 금지;
- 리다이렉트 제한;
- timeout과 응답 제한 설정;
- 내부 자격 증명을 다른 origin에 전달하지 않음.

### 9.5. 삭제 및 위험한 작업

비가역 작업에 MANDATORY:

- 별도 도구;
- `destructiveHint: true`;
- 비가역성의 명시적 description;
- 정확한 서버 측 권한 검사;
- 감사 로그;
- 예상 프로젝트 밖 객체 삭제 방지;
- 자식 객체 및 관련 결과 검사.

boolean `confirm_delete: true`는 MAY 실수 호출에 대한 추가 보호로 사용할 수 있으나 인가 메커니즘으로 간주할 수 없습니다.

2단계 삭제, 낙관적 잠금, 멱등성 키 — 부록 A 참조.

### 9.6. 로그

감사 로그에 기록:

- 도구 이름;
- 인증된 사용자;
- 대상 프로젝트/객체 ID;
- 결과;
- 소요 시간;
- 오류 코드;
- 요청 correlation ID.

로그에 기록해서는 FORBIDDEN:

- 액세스 토큰;
- Authorization 헤더;
- 쿠키;
- base64 파일 내용;
- 비밀 사용자 정의 필드;
- 별도 필요 없이 private notes 전문.

### 9.7. rate limit 및 timeout

모든 도구는 MUST 다음을 가져야 합니다:

- 입력 크기 제한;
- 사용자/토큰당 rate limit;
- 반환 레코드 수 제한;
- bulk 작업 제한.

읽기 도구에는 60초 서버 timeout이 적용됩니다. 쓰기 도구는 저장 성공 후 멱등성 결과를 기록할 수 있도록 서버 timeout으로 중단되지 않습니다.

---

## 10. 오류

### 10.1. 오류 분리

두 수준을 사용합니다:

1. **프로토콜 오류** — 알 수 없는 도구, 손상된 JSON-RPC, MCP 요청 처리 불가.
2. **`isError: true`인 도구 실행 오류** — 인수 오류, Redmine API, 권한, workflow, 또는 비즈니스 로직 오류.

모델이 인수 변경으로 수정할 수 있는 오류는 도구 실행 오류로 반환해야 합니다.

### 10.2. 오류 구조

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

### 10.3. 권장 코드

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

### 10.4. 메시지는 수정 가능해야 함

나쁜 예:

```text
Invalid request.
```

좋은 예:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

사용자에게 stack trace를 반환하지 않습니다. stack trace는 correlation ID가 있는 보호된 서버 로그에만 저장됩니다.

---

## 11. 페이지네이션 및 데이터 용량

### 11.1. 목록/검색 도구

MANDATORY 매개변수:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

기존 Redmine API에서는 `offset`이 허용됩니다. 커스텀 구현에서는 순회 중 데이터가 활발히 바뀔 수 있으면 불투명 cursor를 선호합니다.

### 11.2. 페이지네이션 메타데이터

결과는 MUST 다음을 포함해야 합니다:

- 실제 `limit`;
- `offset` 또는 `next_cursor`;
- `has_more`;
- 획득이 큰 부하를 만들지 않으면 `total_count`.

### 11.3. 필드 선택

`fields` 매개변수는 닫힌 allowlist의 배열로만 허용됩니다:

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

allowlist 없이 임의 필드 이름을 SQL, ActiveRecord `select`, serializer, 또는 Redmine API에 직접 전달할 수 없습니다.

### 11.4. 큰 결과

큰 journals, attachments, 파일은 MUST:

- 별도 페이지네이션;
- 별도 도구/resource로 반환;
- 바이너리 데이터는 가능하면 큰 base64를 응답에 넣는 대신 resource 링크 또는 다른 제한된 참조 반환;
- 또는 작업이 진짜 길고 클라이언트가 지원하면 task-augmented 실행 지원.

`execution.taskSupport`는 자동 설정되지 않습니다. 기본값은 `forbidden`.

---

## 12. 새 도구 참조

§7.1에 따른 필수 `title`과 타입 `outputSchema`를 가진 축약 쓰기 도구 예. 오류 형식 — §10. 전체 JSON — 부록 B.

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

## 13. 테스트

### 13.1. schema 테스트

모든 도구에 MANDATORY:

- 최소 하나의 유효 호출;
- 최소 하나의 부정 호출(예: 필수 필드 누락 또는 잘못된 타입).

schema에 따라 SHOULD 다음을 커버:

- 전체 유효 호출;
- 각 필수 필드 부재;
- 핵심 매개변수의 잘못된 타입;
- 알 수 없는 추가 필드;
- enum 밖 값;
- 범위 밖 값;
- 잘못된 date/date-time;
- `maxItems`, `maxLength`, 파일 크기 초과;
- 필드 상호 의존 위반(XOR 필드 동시; 필수 쌍 둘 다 없음).

### 13.2. 권한 테스트

쓰기, 파괴적, 민감 읽기 작업에 SHOULD 다음을 검증:

- 프로젝트 접근 없는 사용자;
- 읽기 전용 접근 사용자;
- 편집 권한 사용자;
- 도구가 관리 시나리오를 다루면 관리자;
- 도구가 반환하거나 변경하는 private notes 접근;
- 대체 ID로 다른 프로젝트 객체 변경 시도.

민감 데이터 없는 단순 읽기 전용 도구에서는 권한 테스트를 MAY 하나의 부정 시나리오로 제한하거나 MR에 간략한 정당화와 함께 생략할 수 있습니다.

### 13.3. 멱등성 테스트

`idempotentHint: true`에 SHOULD 동일 연속 호출 2회 이상의 자동 또는 수동 테스트.

멱등하다고 주장되는 부작용 부재를 검증. 예:

- 추가 journal 항목;
- 반복 이메일;
- 파일 중복;
- relation 중복;
- 반복 time entry;
- 보장 일부인 경우 추가 webhook 이벤트.

### 13.4. 계약 테스트

SHOULD `tools/list`를 스냅샷으로 유지하거나 breaking 계약 변경을 별도 추적. CI는 MAY 다음을 감지:

- 이름 변경;
- 매개변수 제거;
- 타입 변경;
- `required` 변경;
- annotation 위험 수준 증가;
- `outputSchema` 소실;
- `outputSchema`의 필드, 타입, `required`, `enum` / `const`, 또는 성공/오류 분기의 비호환 변경.

### 13.5. LLM 선택 테스트

유사하거나 혼동하기 쉬운 도구에 SHOULD 사용자 요청과 기대 도구 호출 집합. 전체 자동 LLM 실행은 MAY MR의 정적 예 또는 description 리뷰로 대체.

예:

| 요청 | 기대 도구 |
|---|---|
| "이슈 123 보기" | `redmine_get_issue` |
| "OAuth 관련 이슈 찾기" | `redmine_search_issues` |
| "이슈 123에 감시자 15 추가" | `redmine_add_issue_watcher` |
| "이슈 간 관계 삭제" | `redmine_delete_issue_relation` |
| "유사 이슈 찾기" | `redmine_advanced_search_semantic_search_issues` |

모델이 높은 확률로 읽기 전용 의도에 범용 파괴 도구를 선택하거나 `action` 값을 추측해야 하면 테스트 또는 리뷰는 실패합니다.

### 13.6. 오류 복구 테스트

SHOULD 전형적 오류 후 모델이 올바른 재시도에 충분한 정보를 받는지 검증:

- ID 누락;
- 잘못된 status;
- `expected_updated_at` 충돌;
- 권한 부족;
- 제한 초과;
- 잘못된 MIME 타입.

---

## 14. 코드 리뷰 checklist

새 도구는 모든 필수 항목이 「예」 답을 받을 때까지 merge할 수 없습니다.

### 목적

- [ ] 하나의 동작; `action`/`manage`로 작업 혼합 없음(§3.1–3.2).
- [ ] 관리 작업은 일반 작업과 분리.

### 이름과 description

- [ ] 이름은 `redmine_`로 시작: core — `redmine_<verb>_<entity>`; 서드파티 플러그인 — `redmine_<plugin_id>_…`(§4.1).
- [ ] description: 목적, 부작용, 간략한 결과; 유사 도구 구분 가능(§5).
- [ ] 다른 도구 상호 참조는 `tools/list`의 전체 이름 사용(§5.2.1).

### 소스 계약 조사

- [ ] core 도구는 리소스 REST API, 버전, 필요 시 플러그인 조사; coverage report SHOULD MR에 첨부(§5.6–5.7).
- [ ] 확장 도구는 소스 serializer / service / REST endpoint와 각 결과 형식에 대해 최소 하나의 실제 성공 응답 MUST 검증(§18.5).
- [ ] 계약을 현재 `tools/list`와 비교.

### 입력 스키마

- [ ] schema가 §6과 일치(`additionalProperties: false`, 타입, `required`, `enum`/`const`, 제약).
- [ ] 모든 매개변수에 의미 있는 `description`(§6.14); `*_id`에 `minimum: 1`(§4.3).
- [ ] `*_id` 및 기타 lookup 값에 디스커버리 경로 지정(§6.16): list 도구, get/list 응답 필드, 또는 `enum`.
- [ ] 「… 중 정확히 하나」/ 상호 의존 제약을 description뿐 아니라 schema로 형식화(§5.3, §6.12).
- [ ] 낙관적 잠금 — `expected_updated_at`만, `updated_at` 아님(§4.4).
- [ ] `set_*` 선택 필드에 대해 지우기 결정: `null`, 별도 clear 도구, 또는 명시적 거부(§6.13).
- [ ] 「객체 또는 JSON 문자열」 및 임의 `fields`/`payload` 없음.
- [ ] `*_id` — 정수; §3.4에 따른 서버 측 검증.

### 출력과 오류

- [ ] 새 도구에 성공/오류 엔벨로프가 있는 `outputSchema`(§7.1–7.2).
- [ ] 알려진 안정 결과 필드를 `properties`에 기술; 알려진 계약 대신 `additionalProperties: true` 사용 안 함.
- [ ] 모든 보장 필드가 `required`에 있음.
- [ ] nullable과 optional 필드를 의식적으로 구분.
- [ ] `enum`/`const`, `date`/`date-time`, 범위 및 기타 알려진 제약을 schema로 형식화.
- [ ] 금액 및 기타 숫자 비즈니스 값에 단위, 통화, 주/부 단위가 명확.
- [ ] 결과 비즈니스 불변 조건이 도구 이름 추론뿐 아니라 schema(`const`, `enum`, `required`, 또는 조건부 schema)에 반영.
- [ ] description, `outputSchema`, 실제 handler/REST/service 응답이 모순 없음(§7.1.1).
- [ ] 내부 REST/Ruby/플러그인 값을 안정 MCP 계약으로 정규화; STI/클래스 이름 또는 로케일 의존 형식 누출 없음(§3.3).
- [ ] 목록 도구는 간략하지만 충분한 구조 반환; description이 해당 get 도구가 진짜 필요한 경우를 올바르게 설명.
- [ ] 오류: `isError`, 안정 코드, 수정 가능 메시지; 시크릿 또는 stack trace 없음(§10).

### annotations

- [ ] annotations가 위험과 일치(§8); `idempotentHint: true`에는 테스트 권장.

### 보안

- [ ] 권한, 파일 경로, SSRF, 제한, 로그, 파괴적/audit — §9; 필요 시 부록 A 패턴.

### 테스트

- [ ] 최소 schema 테스트; 나머지는 위험에 따라(§13).

---

## 15. 호환성 및 기존 도구 변경

### 15.1. breaking 변경

breaking 변경:

- 도구 이름 변경;
- 필드 제거;
- 타입 변경;
- 새 필수 필드 추가;
- 필드 의미 변경;
- 비호환 출력 변경;
- 여러 작업을 하나로 병합;
- annotations와 문서 업데이트 없이 위험 증가.

### 15.2. 이름 마이그레이션

예를 들어 이전 접두사 `redmine_mcp_`에서 마이그레이션할 때:

```text
redmine_mcp_get_issue
```

짧은 접두사 `redmine_`으로:

```text
redmine_get_issue
```

다음을 따릅니다:

1. 새 이름 추가;
2. 일시적으로 이전 alias 유지;
3. description에서 이전 도구를 deprecated로 표시**하거나 alias가 `tools/call`에만 필요한 경우 `tools/list`에 게시하지 않음**;
4. 이전 이름 호출 메트릭 수집(호출된 도구 이름별 기존 audit log로 충분);
5. 합의된 기간 후 alias 제거(별도 합의가 없으면 다음 major 버전 이전에는 제거하지 않음);
6. 서버가 `listChanged`를 선언하면 `notifications/tools/list_changed` 전송.

현재 예([03-core-tools.md](03-core-tools.md) 참조): `redmine_list_all_users` → `redmine_admin_list_users`; `redmine_list_files` → `redmine_list_project_files`; `redmine_delete_file` → `redmine_delete_attachment`; `redmine_get_server_info` → `redmine_get_mcp_info`. alias는 `tools/call`에서 허용되며 `tools/list`에는 게시되지 않음.

### 15.3. description 변경

description은 모델 도구 선택에 영향을 주며 behavioral 변경으로 간주됩니다. description의 실질적 변경 시 SHOULD LLM 선택 예를 리뷰하거나 선택 리뷰를 반복.

### 15.4. 서버 버전

MCP 서버 버전은 별도 읽기 전용 도구 또는 서버 메타데이터로 반환됩니다. 병렬 비호환 계약을 지원할 실제 필요 없이 모든 이름에 `v1`, `v2`를 추가하지 않습니다.

---

## 16. 현재 Redmine MCP 문제에 대한 규칙

새 도구 개발 시 현재 계약 감사의 패턴을 반복하는 것은 금지됩니다. 규범적 규칙은 해당 섹션에 있으며, 아래는 문제 맵만 있습니다:

| 감사 문제 | 섹션 |
|---|---|
| `redmine_` 접두사 없는 이름(서드파티 플러그인 포함) / 한 플러그인 내 혼재 스타일 | §4.1 |
| 동사가 의미와 불일치(`set_*` 대신 `done=true/false`의 `complete_*`) | §4.2 |
| `minimum: 1` 없거나 "Issue id" description의 숫자 ID | §4.3 |
| `expected_updated_at` 대신 `updated_at`으로 낙관적 잠금 | §4.4, A.2 |
| 범용 `manage_*` / `patch_*` 및 `action` 매개변수 | §3.1, §4.2 |
| `type` 없는 매개변수, description만의 enum, `items` 없는 배열 | §5.3, §6 |
| `description` 없는 매개변수; lookup 도구 참조 없는 너무 짧은 description | §6.14 |
| 참조 매개변수와 식별자에 `examples` 없음 | §6.15 |
| 디스커버리 경로 없는 `*_id` 쓰기 도구(list 도구와 get 응답 옵션 없음) | §6.16 |
| description이 「A 또는 B 중 정확히 하나」를 약속하지만 schema가 인코딩하지 않음 | §5.3, §6.12 |
| 상호 참조의 짧은 도구 이름(`redmine_list_projects` 대신 `list_projects`) | §5.2.1 |
| 반 페이지 분량의 과도한 도구 description | §5.2 |
| schema 없는 `fields` / `extra_fields`; 여분 `required` | §6.4, §6.11 |
| 필드 지우기 방법도 명시적 거부도 없는 `set_*` | §6.13 |
| 모든 쓰기 도구에 하나의 annotation 집합; 과도한 `openWorldHint` | §8 |
| 일반 `update` / `rename`에 `destructiveHint: true`; `create_*`에 잘못된 `openWorldHint` | §8.1, §8.2 |
| description이 응답 구조를 약속하지만 `outputSchema` 누락 또는 임의 객체만 기술 | §7.1 |
| description, schema, 실제 응답이 모순 | §7.1.1 |
| MCP 응답의 STI/클래스 이름 또는 로케일 날짜 | §3.3 |
| 알려진 list/get 필드 대신 `additionalProperties: true` | §7.1 |
| 임의 `file_path`, 프로젝트 scope 우회, SSRF | §9 |
| 로컬 변경과 한 도구에서의 이메일/외부 효과 | §3.2 |
| 유사 도구의 모호한 쌍 | §5.4 |

---

## 17. 도구 집합 구조

전체 현재 도구 목록은 이 문서에 중복하지 않습니다 — 곧 오래됩니다.

**진실의 원천:**

- core tools — [03-core-tools.md](03-core-tools.md) 및 설치의 실제 `tools/list`;
- 서드파티 플러그인 도구 — §18 및 설치의 MCP `tools/list` 응답.

**그룹화 원칙**(각 그룹 — §3에 따른 별도 원자 도구):

| 그룹 | 의도 예 | 접두사 |
|---|---|---|
| 이슈 | get, list, search, create, update, delete, copy, 하위 이슈 | `redmine_` |
| 관계 및 감시자 | relation list/create/delete; watcher add/remove | `redmine_` |
| 프로젝트 및 멤버 | 프로젝트, 모듈, 멤버, 역할 | `redmine_` |
| 버전 및 카테고리 | 버전; 이슈 카테고리 | `redmine_` |
| 시간 기록 | list, create, update, import, 활동 | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| 파일 및 첨부 | list, upload, delete, download | `redmine_` |
| 관리 | 사용자, 역할, MCP 세션 정보 | `redmine_admin_` 또는 `redmine_get_mcp_info` |
| 플러그인 엔티티 | 체크리스트, 검색 등 | `redmine_` + `plugin_id`, 예: `redmine_advanced_search_` |

새 도구 추가 전 SHOULD MCP `tools/list` 응답과 해당 그룹을 확인: 기존 도구를 중복하지 않고 다른 의도를 하나의 이름에 섞지 않음.

그룹에 ID 매개변수(`status_id`, `role_ids`, …)를 가진 쓰기 도구가 있으면 같은 그룹에 MUST 디스커버리 경로(§6.16).

관리 도구는 필요 권한을 가진 사용자에게만 게시됩니다(§9.1).

---

## 18. 서드파티 플러그인 확장

Extension API로 도구를 추가하는 Redmine 플러그인 작성자용 섹션. API, hook, 엣지 케이스의 기술 설명 — [04-extensions.md](04-extensions.md).

확장은 `redmine_mcp` core tools와 동일한 계약, 보안, 명명 규칙(§3–§10, §4.1)을 따릅니다.

### 18.1. 무엇을 언제 게시할지

| 프리미티브 | 사용 시기 |
|---|---|
| **Tool** | 플러그인 엔티티 또는 Redmine에 대한 하나의 동작: create, get, update, delete, search |
| **Resource** | 안정 URI의 크거나 정적인 콘텐츠: wiki 본문, 파일, 긴 보고서 |
| **Prompt** | 부작용이 있는 작업이 아닌 사용자용 반복 가능 시나리오 템플릿 |
| **`extend_tool`** | 기존 core 도구의 논리적 일부인 매개변수 또는 hook(예: 이슈 읽기 시 `include_*`) |

모델이 `action`을 추측하지 않고 별도 도구로 의도를 충족할 수 있으면 — 다른 schema를 비대하게 만드는 `extend_tool`보다 **자체 도구**를 선호.

### 18.2. 등록

- 확장 파일은 Redmine 시작 시 로드: `lib/<plugin_id>/mcp.rb`(`ExtensionLoader` 참조).
- `mcp.rb`의 모듈은 MUST `PluginName::Mcp`(`extend RedmineMcp::ExtensionApi`): Zeitwerk가 파일에서 이름을 유도.
- 등록 전 SHOULD `mcp_extension_enabled?` 확인 — gemspec에서 `redmine_mcp`에 대한 hard dependency는 불필요.
- reload 시 도구가 중복되지 않도록 `register_tool_once` 사용.
- `tools/list`의 전체 이름은 MUST `redmine_`로 시작(§4.1).
- 도구는 MUST `title`, `description`, `input_schema`, `output_schema`, `permission`, `annotations`를 가져야 함; 이름 중복 금지.
- 도구는 해당 권한을 가진 사용자에게만 MCP `tools/list` 응답에 표시.

### 18.3. 명명

- 이름은 MUST `redmine_`로 시작; 다음 — `plugin_id`와 `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- 동사와 `manage_*` 금지 — §4.2 및 §3.1.
- core 도구 이름을 복사하지 않고 같은 의도의 두 번째 도구를 다른 이름으로 게시하지 않음.

등록 전 SHOULD 대상 설치의 `tools/list` 응답과 비교.

### 18.4. 권한과 보안

- `permission`은 MUST 별도 「mcp 전용」역할이 아니라 실제 Redmine 또는 플러그인 권한과 일치.
- 이슈 작업에는 SHOULD 가시성과 프로젝트 모듈 검사를 복사하는 대신 `register_issue_tool`과 `find_accessible_issue` 사용.
- `module_name`이 설정되면 사용자가 활성 모듈이 있는 최소 하나의 가시 프로젝트에서 선언 권한을 가질 때만 MUST 도구가 `tools/list`에 포함. `module_name` 없으면 최소 하나의 가시 프로젝트에서 권한이면 충분. handler는 여전히 특정 이슈(프로젝트 모듈 포함)를 확인.
- 다른 사용자에게 `tools/list`에서 숨겨져도 handler에서 반복 서버 측 인수 및 권한 검증 — §3.4 및 §9.

### 18.5. 깔끔한 구현

**얇은 MCP 레이어.** `mcp.rb`에는 주로 도구 등록: schema, description, 권한, annotations, 짧은 handler. handler는 인수를 검증하고 컨텍스트를 확인하며 실행을 별도 클래스/service에 위임.

플러그인 비즈니스 로직은 일반 model과 service에 남기고 MCP에 의존하지 않아야 합니다.

MCP에만 필요한 로직 — 예: 여러 model에서 데이터 병합, REST 응답을 MCP 계약으로 정규화, 파생 필드 계산, 도구 결과 준비 — 은 MAY 별도 `mcp_tools.rb`로 이동. 그런 파일이 커지면 SHOULD 엔티티 또는 작업별로 클래스 분할. 예: `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

비즈니스 로직과 큰 변환을 `mcp.rb` 내 lambda/handler에 직접 두지 않음.

**데이터 접근.**

- 플러그인 model과 service — 로직이 이미 있을 때.
- `internal_request` / `internal_get` / REST — 기존 API controller를 재사용할 때; endpoint는 `accept_api_auth`를 지원해야 함. `POST`, `PUT`, `PATCH`, `DELETE`에는 `internal_request` 사용; 읽기에는 `internal_get` 또는 `internal_request(method: 'GET', ...)` 사용. `internal_request_error?`로 실패 확인.

**`extend_tool` — 적당히.** 매개변수가 core 도구와 하나의 의도의 일부일 때 적절. 플러그인이 본질적으로 별도 하위 시스템을 추가할 때는 부적절: 자체 접두사와 자체 도구가 낫고, core 링크는 `description` 또는 서버 instructions에 기술.

**core와 같은 계약.** 입력 — §6. 출력 — §7.1 및 §7.1.1: 안정 필드, `required`, `enum`/`const`, 단위, 내부 API 정규화. 위험에 따른 annotations, 수정 가능 오류(§8, §10). 낙관적 잠금 — `expected_updated_at`(§4.4). 모든 매개변수 — `description`(§6.14). 상호 참조 — 전체 이름(§5.2.1). 모든 쓰기 `*_id` 매개변수 — 디스커버리 경로(§6.16): 별도 `list_*` 또는 get/list 응답의 `id` 옵션, 매개변수 description의 명시적 참조.

확장 도구 게시 전 MUST 소스 serializer / service / REST endpoint와 각 결과 형식에 대해 최소 하나의 실제 성공 응답을 검증.

**공유 코드 — `redmine_mcp`에.** 확장 개발 시 조각이 다른 MCP 플러그인에 필요할 수 있으면 SHOULD 즉시 core `redmine_mcp`에 추가하고 `lib/<plugin>/mcp*.rb`에 복사하지 않음.

기준: 로직이 하나의 플러그인 도메인(checklist, search, …)에 묶이지 않고 MCP 계약, Extension API, 또는 전형적 통합 패턴을 기술.

| 위치 | 내용 |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, `ExtensionApi` 확장(`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, `issue_id` / `project_id`별 공통 권한 helper |
| **플러그인 확장** | `mcp.rb` — 도구 등록과 짧은 handler; `mcp_tools.rb` / `mcp_tools/*.rb` — MCP 전용 fetch, 집계, 정규화; 일반 model/service — MCP에 의존하지 않는 비즈니스 로직 |

**확장 권장 배치:**

- `mcp.rb` — 도구 등록과 짧은 handler;
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP 전용 fetch, 집계, 데이터 정규화;
- 일반 model/service — MCP에 의존하지 않는 비즈니스 로직.

다른 확장에서 helper를 복사하기 전 SHOULD `redmine_mcp`에 유사 항목이 이미 있는지 확인; 없으면 같은 PR에서 core로 이동하고 중복하지 않음.

확장 API 자세히 — [04-extensions.md](04-extensions.md)(§ "ExtensionApi helper methods").

### 18.6. 안티패턴

FORBIDDEN 또는 비권장:

- 모든 HTTP 요청마다 도구 등록;
- 시작 시 이웃 플러그인 오류로 실패;
- 한 도구에서 읽기, 쓰기, 관리 혼합;
- 「다른 이름」의 core 도구 중복;
- 「미래를 위해」선택 매개변수로 다른 도구 확장;
- 플러그인 UI/API에서 사용자에게 사용 불가한 내부 필드를 MCP에서 반환;
- MCP schema가 다른 계약을 정의할 때 STI 클래스 이름, 로케일 날짜, REST 표현 게시(§3.3, §7.1.1);
- 목록 요소를 `{ "type": "object", "additionalProperties": true }`만으로 기술(§7.1);
- 모델이 허용 ID를 알 방법 없이 `status_id`를 가진 `set_*_status` / 유사 게시(§6.16);
- 위치가 `redmine_mcp`인 경우 확장에서 공통 MCP helper(envelope `outputSchema`, `internal_request` wrapper, 이슈 권한) 중복 — §18.5 참조.

### 18.7. merge 전 검증

- [ ] 도구 이름이 §4.1 / §18.3에 따라 `redmine_`로 시작.
- [ ] 확장이 시작 시 로드; 권한 사용자의 `tools/list`에 도구 표시.
- [ ] 권한 없는 사용자 및 플러그인 MCP 확장 플래그 비활성 시 도구 부재.
- [ ] 계약과 checklist(§14) 충족, description / outputSchema / 실제 응답 비교(§7.1.1) 포함; 필요 시 §13 테스트.
- [ ] 각 게시 결과 형식(예: list와 get 둘 다 게시 시 둘 다)에 대해 serializer / REST / service를 최소 하나의 실제 성공 응답으로 검증.
- [ ] `tools/list`의 기존 도구와 중복 없음.
- [ ] 각 `*_id` 쓰기 매개변수에 디스커버리 경로(§6.16).

---

## 19. 출처 및 규범적 기반

본 문서는 2026-07-22 기준 다음 주요 출처에 기반하여 작성되었습니다:

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
    REST API 페이지의 링크 `API changes for each version`; 모든 지원 버전에 대해 검증됨.

---

## 20. 새 도구 준비 완료 기준

새 MCP 도구는 필수 코드 리뷰 checklist 항목(§14)이 충족되면 준비 완료로 간주됩니다.

서드파티 플러그인 도구는 추가로 — checklist §18.7.

위험 권장: coverage report(§5.7), 추가 테스트 §13.2–13.6 및 부록 A. 최소 schema 테스트(§13.1)와 `outputSchema` 규칙(§7.1, §7.1.1)은 필수.

---

## 부록 A. 권장 구현 패턴

아래 패턴은 모든 MCP 도구에 필수는 아닙니다. SHOULD 위험이 높은 경우 고려: 파괴적 작업, 관리 도구, bulk 쓰기, 외부 부작용, timeout으로 인한 반복 호출.

### A.1. 2단계 삭제(prepare / confirm)

특히 위험한 관리 작업의 경우:

1. `redmine_prepare_delete_*`는 간략한 결과 description과 일회용 토큰 반환;
2. `redmine_confirm_delete_*`는 짧은 TTL의 토큰 수락.

파괴적 작업의 규범적 요구사항 — §9.5.

### A.2. 낙관적 잠금

동시 변경 하의 update/delete에서는 매개변수는 MUST `updated_at`이 아니라 `expected_updated_at`(§4.4)으로 이름 지어야 합니다:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

이름은 core tools와 확장(checklist 쓰기 도구 포함)에서 통일됩니다.

충돌 시 `CONFLICT`, 실제 객체 수정 시각(응답의 `updated_at` / `updated_on`), 객체 재읽기 권장을 반환합니다.

### A.3. 멱등성 키

timeout으로 인한 반복이 중복을 만들 수 있는 작업:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

특히 적합:

- 이슈 생성;
- 시간 기록 가져오기;
- 파일 업로드;
- bulk 작업;
- 이메일 전송.

도구가 `idempotentHint: true`를 게시하면 반복 호출은 MUST 안전해야 함(§8.2); `idempotency_key`는 그것을 보장하는 한 방법.

---

## 부록 B. 전체 도구 예

참조 `redmine_create_issue`. 오류 형식 또는 엔벨로프가 바뀌면 §7, §10, 본 섹션을 업데이트; §12는 축약본 유지.

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

참고: 서버가 `idempotency_key`가 있을 때 멱등성을 보장해도 annotation은 도구 전체를 기술합니다. 따라서 키 없는 호출이 허용되면 안전한 값은 `false`로 유지됩니다.

