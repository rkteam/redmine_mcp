# 인증 및 권한 부여

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## 개요

MCP 접근은 표준 Redmine API 키 인증을 사용합니다. 모든 작업은 키 소유 사용자를 대신하여 실행됩니다.

## 목표

MCP가 Redmine 보안을 우회하지 않도록 하고, 사용자가 허용된 작업만 수행할 수 있게 합니다.

## 영향을 받는 영역

- 권한
- API
- 사용자

## 비즈니스 규칙

### 인증

- `/mcp` 접근을 위해 Redmine REST API가 활성화되어 있어야 합니다.
- API 키는 `X-Redmine-API-Key` 헤더로 전달됩니다(JSON 요청 본문이나 쿼리 문자열에서가 아님).
- 활성 사용자의 키만 수락됩니다.
- 키가 없거나 잘못된 키의 요청은 거부됩니다.

### 전역 MCP 권한

- 사용자는 전역 **Use MCP** 권한(`use_mcp`)을 가지거나 Redmine 관리자여야 합니다.
- `use_mcp` 권한은 **Administration → Roles and permissions**에서 필요한 역할에 수동으로 활성화됩니다.
- 관리자는 항상 MCP 접근 권한이 있습니다. 표준 Redmine 전역 권한 확인은 역할과 관계없이 관리자를 허용합니다.
- `use_mcp` 없는 다른 사용자는 유효한 API 키가 있어도 요청이 거부됩니다.

### 도구 권한

- 각 도구는 자체 Redmine 권한 요구사항이 있습니다.
- 도구는 사용자가 사용 권한이 있을 때만 `tools/list`에 나타납니다.
- 도구 호출 시 권한이 다시 확인됩니다.
- 데이터는 Redmine 가시성 규칙(프로젝트, 이슈, 멤버)에 따라 필터링됩니다.

### 리소스 및 prompt 권한

- 리소스와 prompt는 자체 권한 요구사항을 가질 수 있습니다.
- 권한이 없으면 리소스 또는 prompt는 목록에 없고 읽을 수 없습니다.
- 리소스 및 prompt 권한 확인은 URI와 입력 인수(`project` / `project_id` 포함)를 고려합니다. 인수에 프로젝트가 지정되지 않으면 최소 하나의 보이는 프로젝트에서 권한이 있으면 충분합니다.
- 확장은 URI와 인수에서 프로젝트를 해석하는 명시적 규칙을 정의할 수 있습니다.

## 엣지 케이스

- 비활성 사용자는 이전에 발급된 키가 있어도 MCP를 사용할 수 없습니다.
- 관리자는 별도의 `use_mcp` 할당 없이 MCP 접근 권한이 있습니다.
- 엔티티 범위 권한 확인이 있는 도구(예: 이슈)는 사용자가 최소 하나의 프로젝트에서 해당 권한이 있으면 빈 인수로 `tools/list`에 보일 수 있습니다.
- 그러한 도구가 Redmine 프로젝트 모듈도 요구하는 경우, "최소 하나의 프로젝트"는 사용자가 권한을 가지고 지정된 모듈이 활성화된 보이는 프로젝트를 의미합니다. 모듈 요구사항이 없으면 최소 하나의 보이는 프로젝트에서 권한이 있으면 충분합니다. `tools/list`에 있다고 특정 이슈에 대한 권한을 의미하지 않습니다. 호출 시 권한과 객체 가용성이 다시 확인됩니다.

## 오류 처리

| 상황 | 결과 |
|----------|-----------|
| REST API 비활성화 | HTTP 401 |
| 잘못되거나 누락된 API 키 | HTTP 401 |
| Use MCP 권한 없음 | HTTP 403 |
| 특정 도구 권한 없음 | `tools/list`에서 도구 없음; 직접 호출 — "Permission denied" 오류 |
| 사용자에게 사용 불가 엔티티 | 오류 설명이 있는 도구 응답(예: "Issue not found") |

## 테스트 시나리오

1. 유효한 키와 Use MCP 권한으로 요청 — 성공적인 접근.
2. API 키 헤더 없이 요청 — HTTP 401.
3. Use MCP 권한 없는 비관리자 키로 요청 — HTTP 403.
4. `use_mcp` 역할 없는 관리자 키 — 성공적인 접근.
5. 사용자는 권한이 있는 도구만 `tools/list`에서 봅니다.
6. 접근 불가 이슈에 대한 도구 호출 — 다른 사용자 데이터가 아닌 오류 반환.
7. 프로젝트 모듈 요구사항이 있는 이슈 범위 도구 — 권한은 있지만 해당 모듈이 활성화된 보이는 프로젝트가 없으면 `tools/list`에 없음; 그러한 프로젝트가 있으면 보임.
