# MCP 서버 및 HTTP 엔드포인트

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## 개요

Redmine MCP는 요청 간 세션 지속 없이(stateless) Streamable HTTP 모드에서 MCP(Model Context Protocol)를 구현하는 HTTP 엔드포인트 `/mcp`를 제공합니다.

## 목표

별도의 서버 프로세스 없이 표준 MCP 프로토콜을 사용하여 외부 AI 클라이언트가 Redmine과 상호작용할 수 있게 합니다.

## 영향을 받는 영역

- API
- 플러그인

## 비즈니스 규칙

- 엔드포인트는 Redmine 루트 기준 `/mcp`에서 사용할 수 있습니다.
- Streamable HTTP 사양에 따라 HTTP 메서드 `GET`, `POST`, `DELETE`가 지원됩니다.
- 각 요청은 현재 인증된 사용자 컨텍스트에서 처리됩니다.
- 각 요청마다 사용자 권한에 따라 최신 tools, resources, prompts 세트가 구성됩니다.
- 서버는 이름 `redmine_mcp`와 플러그인 버전과 일치하는 버전을 광고합니다.
- MCP Protocol Revision은 `2025-11-25`입니다(헤더 `MCP-Protocol-Version` 및 `initialize`의 `protocolVersion`).
- 표준 MCP 메서드가 지원됩니다: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` 및 지원 프로토콜 버전이 제공하는 기타 메서드.
- 도구 응답은 `structuredContent`에 JSON 래퍼(`ok`, `data` 또는 `error`)를 반환하고, `content`에 짧은 텍스트 표현(성공 시 JSON 문자열, 실패 시 오류 메시지)을 반환합니다.
- API 키는 `X-Redmine-API-Key` 헤더에서만 수락됩니다. JSON-RPC 본문은 인증에 사용되지 않으며 요청 크기 확인 전에 파싱되지 않습니다.
- JSON 파싱 전에 HTTP 본문 크기가 제한됩니다. 한도를 초과하면 요청이 거부되고 MCP 전송은 본문을 읽지 않습니다.

## 엣지 케이스

- MCP가 비활성화되면 엔드포인트는 HTTP 503을 반환하고 MCP 요청을 처리하지 않습니다.
- stateless 모드에서 독립 SSE 스트림용 `GET` 요청은 지원되지 않습니다(HTTP 405) — 예상된 동작입니다.
- 로드 밸런서 뒤에서 작동할 때 sticky session이 필요하지 않습니다.
- 도구 목록은 권한에 따라 사용자마다 다를 수 있습니다.

## 오류 처리

- 잘못된 JSON-RPC 요청 — MCP 프로토콜 오류 응답.
- 내부 요청 처리 오류 — 오류 메시지와 함께 HTTP 500.
- 도구 실행 오류 — `isError: true` 및 텍스트 설명이 있는 MCP 응답.
- 프로세스 내 REST(`InternalRequest`): 404 → `NOT_FOUND`; 버전 충돌 → `CONFLICT`; 충돌 없이 401/403 → `FORBIDDEN`; `errors` 배열 → `VALIDATION_ERROR`. 래퍼에는 내부 요청 HTTP 상태 또는 원시 예외 메시지가 포함되지 않습니다.
- 잘못된 도구 인수(필수 필드 누락, 잘못된 타입, `additionalProperties: false`일 때 추가 속성, min/max 범위 초과) — `structuredContent`에 `VALIDATION_ERROR`가 있는 실행 오류. `content`의 텍스트는 `error.message`와 일치하며 원시 JSON Schema 메시지를 포함하지 않습니다.

## 테스트 시나리오

1. `initialize` 메서드로 `POST /mcp` — capabilities, `serverInfo`, `protocolVersion` `2025-11-25` 반환.
2. `tools/list` 메서드로 `POST /mcp` — 현재 사용자의 도구 목록 반환.
3. 유효한 도구 이름으로 `tools/call` 메서드 `POST /mcp` — `structuredContent`가 있는 결과 반환.
4. MCP 비활성화 시 `/mcp` 요청 — HTTP 503 반환.
5. 존재하지 않는 도구 호출 — "Tool not found" 오류.
6. 도구 권한 없이 `tools/call` — 접근 거부 코드가 있는 실행 오류; 호출은 rate limit 및 구조화된 감사에 집계됩니다.
7. 한도보다 큰 HTTP 본문 — JSON 파싱 전 거부.
8. 읽기 전용 모드에서 쓰기 도구 — 동일한 HTTP/`tools/call` 경로를 통해 오류 반환.
9. 접근 불가 프로젝트 URI로 `resources/read` — 리소스 내용을 반환하지 않음.
10. 접근 불가 프로젝트 인수로 `prompts/get` — 접근 거부.
11. 빈 args, 추가 필드, 잘못된 인수 타입으로 `tools/call` — `isError: true` 및 `structuredContent.error.code` `VALIDATION_ERROR` 반환.
