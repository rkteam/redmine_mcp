# Redmine MCP — 일반 사양

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## 개요

Redmine MCP 플러그인은 Redmine 설치 내부에 MCP 서버(Model Context Protocol)를 제공합니다. AI 클라이언트는 단일 HTTP 엔드포인트에 연결하여 tools, resources, prompts를 통해 Redmine 데이터에 접근합니다.

플러그인에는 프로젝트, 이슈, 사용자 작업을 위한 기본 도구 세트가 포함되어 있습니다. 다른 Redmine 플러그인은 Redmine MCP 코드를 변경하지 않고 MCP를 확장할 수 있습니다.

## 목표

다음을 충족하는 Redmine과 AI 시스템 간 단일 통합 메커니즘을 제공합니다.

- 사용자는 자신의 Redmine 권한 범위 내에서 작업합니다.
- 플러그인 개발자는 자체 MCP 기능을 추가할 수 있습니다.
- 별도의 MCP 서버나 설치별 fork가 필요하지 않습니다.

## 주요 시나리오

1. **AI 클라이언트 연결** — 관리자가 MCP를 활성화하고, 필요한 역할에 `use_mcp` 권한을 부여하며, API 키를 발급합니다. 사용자는 클라이언트(Cursor 등)를 `/mcp` 엔드포인트에 연결합니다.
2. **Redmine 데이터 작업** — 클라이언트가 도구를 호출하여 프로젝트, 이슈, 사용자를 가져옵니다.
3. **다른 플러그인에 의한 확장** — MCP 확장이 있는 플러그인이 설치되면 해당 도구가 공유 목록에 자동으로 나타납니다.
4. **관리** — MCP 활성화/비활성화 및 개별 플러그인의 MCP 통합 활성화.

## 영향을 받는 영역

- API (HTTP상 MCP)
- 권한
- 설정
- 이슈
- 프로젝트
- 사용자
- 게시판
- 플러그인 (확장)

## 비즈니스 규칙

- MCP는 플러그인 설정에서 명시적으로 활성화된 경우에만 사용할 수 있습니다.
- 모든 작업은 인증된 Redmine 사용자를 대신하여 실행됩니다.
- MCP를 통한 쓰기는 Redmine 모델을 거칩니다. 모델 콜백이 실행됩니다. 컨트롤러 훅(`controller_issues_*_save`, `controller_journals_edit_post` 등)은 MCP에서 호출되지 않습니다.
- 데이터 가시성은 Redmine 규칙을 따릅니다. 사용자는 웹 UI에서 볼 수 있는 것보다 더 많은 정보를 받지 않습니다.
- 도구 및 prompt 이름은 `<plugin_id>_<name>` 형식을 사용합니다. 예: `redmine_list_projects`.
- 코어 도구의 `title`과 `description`은 LLM 선택을 위해 영어로 게시되며 `en.yml`/`ru.yml`을 통한 **현지화되지 않습니다**(MCP 도구 카탈로그에 대한 i18n 표준의 예외). 오류 메시지와 설정 UI는 현지화됩니다.
- 다른 플러그인의 확장은 강한 의존성을 만들지 않습니다. Redmine MCP가 없어도 서드파티 플러그인은 계속 작동합니다.

## 엣지 케이스

- MCP가 비활성화되면 `/mcp`에 대한 모든 요청이 거부됩니다.
- 하나의 확장이 실패해도 다른 확장과 코어 도구는 계속 작동합니다.
- 확장의 새 도구는 Redmine 재시작 후 사용 가능해집니다. MCP 클라이언트는 도구 목록을 새로 고치려면 재연결이 필요할 수 있습니다.
- stateless 모드에서는 각 HTTP 요청이 독립적으로 처리됩니다. 요청 간 세션이 유지되지 않습니다.

## 오류 처리

- 인증 및 권한 부여 오류는 HTTP 수준에서 반환됩니다.
- 도구 실행 오류는 오류 플래그와 함께 MCP 형식으로 반환됩니다.
- 확장 로드 오류는 로그에 기록되며 Redmine 시작을 차단하지 않습니다.

## 사양 파일

| 파일 | 내용 |
|------|---------|
| [console-commands.md](console-commands.md) | 설치, 검증, 유지보수 명령 |
| [01-mcp-server.md](01-mcp-server.md) | HTTP 엔드포인트, MCP 프로토콜, 전송 |
| [02-authentication.md](02-authentication.md) | 인증 및 접근 제어 |
| [03-core-tools.md](03-core-tools.md) | 내장 Redmine 도구 |
| [04-extensions.md](04-extensions.md) | 다른 플러그인용 Extension API |
| [05-settings.md](05-settings.md) | 플러그인 설정 및 로깅 |
| [mcp_tool_development.md](mcp_tool_development.md) | MCP 도구 개발 요구사항(dev-guide) |
| [extension_guide.md](extension_guide.md) | 확장 개발자 가이드 |

## 테스트 시나리오

1. 설치 및 MCP 활성화 후 클라이언트가 `initialize`를 성공적으로 실행하고 서버 정보를 받습니다.
2. Use MCP 권한과 유효한 API 키를 가진 사용자는 자신에게 사용 가능한 도구 목록을 봅니다.
3. Use MCP 권한이 없는 사용자는 `/mcp` 접근이 거부됩니다.
4. 확장 플러그인이 설치되면 해당 도구가 해당 권한을 가진 사용자의 `tools/list`에 있습니다.
