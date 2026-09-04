# Redmine MCP

[웹사이트](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../../../README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | 한국어 | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | [中文](../zh/README.md)

Redmine 내부의 MCP 서버(Model Context Protocol). AI 클라이언트가 표준 Redmine 권한을 통해 이슈, 프로젝트, 사용자와 작업할 수 있게 합니다. 다른 플러그인은 이 플러그인을 변경하지 않고 자체 tools, resources, prompts, capabilities를 추가할 수 있습니다. 수정할 수 없는 서드파티 플러그인을 위해 `redmine_mcp`는 `lib/redmine_mcp/extensions/`에 내장 MCP 통합을 제공할 수 있습니다.

## 요구 사항

| 구성 요소 | 버전 |
|---|---|
| Redmine | Redmine 6.0–7.0 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

이 플러그인은 MCP protocol `2025-11-25`와 Ruby MCP SDK `0.23.x`를 사용합니다.
더 새로운 MCP protocol 및 SDK 버전에 대한 지원은 현재 선언되지 않았습니다.

- Redmine에서 REST API가 활성화되어 있어야 함
- gem `mcp`는 `plugins/redmine_mcp/Gemfile`에 선언되며 `bundle install`로 설치됨

## 설치 및 설정

### 1. 플러그인 설치

Redmine `plugins` 디렉터리에 git 저장소를 클론합니다:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

Redmine 루트 디렉터리에서 의존성을 설치하고 애플리케이션을 재시작합니다:

```bash
cd /path/to/redmine
bundle install
```

Redmine을 재시작합니다.

### 2. 관리 화면에서 활성화

**관리 → 플러그인 → Redmine MCP → 설정**

| 설정 | 설명 |
|---------|-------------|
| MCP 사용 | `/mcp` 엔드포인트를 활성화합니다. 활성화 시 설치된 플러그인의 MCP 확장이 로드됩니다 |
| 읽기 전용 모드 | write 도구 및 write 작업(create/update/delete 등)을 차단합니다 |
| MCP 확장 | 설치된 플러그인의 MCP 통합을 활성화하는 체크박스 |

### 3. REST API

**관리 → 설정 → API** — «REST 웹서비스 활성화»를 활성화합니다.

### 4. 권한

**관리 → 역할 및 권한** — 필요한 역할에 대해 전역 권한 **MCP 사용**(`use_mcp`)를 수동으로 활성화합니다. Redmine 관리자는 항상 MCP에 접근할 수 있습니다.

### 5. 사용자 API 키

MCP를 통해 작업할 모든 사용자는 API 키를 보유해야 합니다:

**내 계정 → API 접근키**(또는 사용자 REST API를 통해).

키는 헤더로 전달합니다:

```
X-Redmine-API-Key: <your_key>
```

## MCP 클라이언트 연결

서버는 **Streamable HTTP**(stateless)를 사용합니다. 엔드포인트:

```
https://<your-redmine>/mcp
```

지원 메서드: `GET`, `POST`, `DELETE`.

### Cursor 예시

MCP 설정(`.cursor/mcp.json` 또는 전역 구성)에서 HTTP 전송 서버를 추가합니다. 정확한 형식은 클라이언트 버전에 따라 다릅니다. 일반적인 예:

```json
{
  "mcpServers": {
    "redmine": {
      "url": "https://your-redmine.example.com/mcp",
      "headers": {
        "X-Redmine-API-Key": "your_api_key"
      }
    }
  }
}
```

연결 후 클라이언트는 `initialize`를 호출한 다음 `tools/list`, `tools/call`, `resources/list`, `prompts/list` 등을 호출할 수 있습니다.

### 수동 확인

```bash
curl -s -X POST 'https://your-redmine.example.com/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: your_key' \
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

성공 응답에는 `serverInfo.name: "redmine_mcp"`가 포함됩니다.

### Host 및 reverse proxy

MCP transport는 DNS rebinding 방지를 위해 HTTP `Host`와 `Origin`을 검증합니다.

허용된 host는 Redmine 설정에서 가져옵니다:

**관리 → 설정 → 일반 → 호스트 이름과 경로**

값은 Redmine의 공개 URL과 일치해야 합니다.

예를 들어 Redmine이 다음에서 사용 가능한 경우:

```
https://redmine.example.com
```

설정에는 다음을 사용하는 것이 권장됩니다:

```
redmine.example.com
```

Redmine이 reverse proxy 뒤에서 실행되는 경우 proxy는 클라이언트의 원본 `Host` 헤더를 전달해야 합니다.

host가 일치하지 않으면 MCP 엔드포인트가 HTTP `403 Forbidden`을 반환할 수 있습니다.

`Origin` 헤더가 없는 클라이언트는 Origin 검사의 영향을 받지 않습니다.

## 내장 도구 (core tools)

전체 이름은 `redmine_<tool_name>` 형식입니다(예: `redmine_get_issue`).

서버는 프로젝트, 이슈, 사용자, 시간 추적, Wiki, 게시판, 파일용 도구를 제공합니다. 아래는 내장 tools의 간략한 개요입니다. 전체 입력 스키마와 descriptions는 `tools/list`를 통해 MCP 클라이언트가 사용할 수 있습니다.

### 공통 매개변수

- `project` — 프로젝트 문자열 ID 또는 identifier.
- `assignee_ref` / `user_ref` 값 `me` — 현재 사용자.
- `assigned_to_id` — 일감에 할당된 사용자 또는 그룹; `null`은 선택적 필드를 지웁니다.
- `create_time_entry`에는 `project` 또는 `issue_id`가 필요합니다.
- `upload_file`에는 `filename`과 `content_base64`가 필요합니다.

### 작업 신뢰성

- `expected_updated_at` — 민감한 update/delete 작업에서 사용.
- `idempotency_key` — `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`에서 사용.

### 제한

- 읽기 timeout 60초;
- 사용자당 120 요청/분;
- MCP 요청 HTTP 본문 최대 36 MiB;
- tool JSON args 최대 32 MiB;
- base64 첨부 파일 최대 20 MiB;
- 첨부 파일 다운로드 최대 10 MiB.

### 프로덕션 배포

속도 제한과 idempotency는 `Rails.cache`를 사용합니다.

여러 애플리케이션 worker 또는 여러 Redmine 인스턴스가 있는 설치에서는 공유 cache store 사용이 권장됩니다.

프로세스 로컬 cache를 사용하면 속도 제한 및 idempotency 보장은 개별 애플리케이션 프로세스 내에서만 적용됩니다.

### 프로젝트 관리

| 도구 | 설명 |
|------|-------------|
| `list_projects` | 프로젝트 목록 |
| `get_project` | 프로젝트 세부 정보 |
| `list_project_issue_custom_fields` | 프로젝트 이슈 사용자 정의 필드 |
| `summarize_project_status` | N일간 서버가 생성한 프로젝트 메트릭 요약 |
| `list_project_activities` | 프로젝트 활동 피드(이벤트, 시간 기록 activity 유형 아님) |
| `list_versions` | 로드맵 버전(마일스톤) |
| `get_version` | 로드맵 버전 세부정보(집계 포함) |
| `create_version` | 버전 생성 |
| `update_version` | 버전 업데이트 |
| `delete_version` | 버전 삭제 |
| `list_project_members` | 프로젝트 멤버 및 역할 |
| `list_project_member_candidates` | 프로젝트에 추가할 수 있는 사용자 및 그룹 |
| `list_roles` | 프로젝트에서 관리할 수 있는 역할 |
| `get_project_modules` | 활성화된 프로젝트 모듈 |
| `add_project_member` | 멤버 추가 |
| `update_project_member` | 멤버 역할 변경 |
| `remove_project_member` | 멤버 제거 |

### 이슈

| 도구 | 설명 |
|------|-------------|
| `get_issue` | 이슈 세부 정보(저널, 첨부 파일, 사용자 정의 필드 등) |
| `list_issues` | 필터 및 페이지네이션이 있는 이슈 목록 |
| `search_issues` | 이슈 텍스트 검색 |
| `run_issue_query` | 저장된 이슈 쿼리 실행 |
| `get_issue_form_options` | 허용된 이슈 양식 필드 값(단일 호출) |
| `validate_issue_create` | 쓰기 없이 이슈 생성 매개변수 검증 |
| `validate_issue_update` | 쓰기 없이 이슈 업데이트 매개변수 검증 |
| `create_issue` | 이슈 생성 |
| `update_issue` | 이슈 속성 및 첨부 파일 업데이트 |
| `add_issue_note` | 이슈에 댓글 추가(선택적으로 첨부 파일 포함) |
| `delete_issue` | 확인과 함께 이슈 삭제 |
| `copy_issue` | 이슈 복사 |
| `list_issue_relations` | 이슈 관계 목록 |
| `create_issue_relation` | 이슈 간 관계 생성 |
| `delete_issue_relation` | 이슈 관계 삭제 |
| `list_subtasks` | 하위 작업 |
| `add_issue_watcher` | 감시자 추가 |
| `remove_issue_watcher` | 감시자 제거 |
| `update_issue_note` | 저널 항목 편집 |
| `set_issue_note_private` | 저널 항목 비공개 설정 변경 |
| `get_private_notes` | 비공개 댓글만 |
| `list_issue_categories` | 프로젝트 이슈 카테고리 |
| `create_issue_category` | 카테고리 생성 |
| `update_issue_category` | 카테고리 업데이트 |
| `delete_issue_category` | 카테고리 삭제 |

### 사용자

| 도구 | 설명 |
|------|-------------|
| `list_users` | 프로젝트 멤버; 필터 `query`(이름/login) 및 `login`; 전역 검색은 관리자만 |
| `list_groups` | `add_project_member`의 `group_id`용 Givable 그룹 |

### 시간 추적

| 도구 | 설명 |
|------|-------------|
| `list_time_entries` | 시간 기록 목록 |
| `create_time_entry` | 시간 기록 생성 |
| `update_time_entry` | 시간 기록 업데이트 |
| `list_time_entry_activities` | 시간 기록 activity 유형(프로젝트 이벤트 피드 아님) |
| `import_time_entries` | 시간 기록 일괄 가져오기 |

### 참조 데이터

| 도구 | 설명 |
|------|-------------|
| `list_trackers` | 모든 트래커 |
| `list_project_trackers` | 프로젝트 트래커 |
| `list_issue_statuses` | 이슈 상태 |
| `list_issue_priorities` | 이슈 우선순위 |
| `admin_list_users` | 필터가 있는 사용자(관리자만) |
| `get_current_user` | 현재 사용자 |
| `list_queries` | 저장된 쿼리(메타데이터; 실행은 `run_issue_query`) |

### 검색 및 Wiki

| 도구 | 설명 |
|------|-------------|
| `search_all` | 이슈 및 Wiki 페이지 검색 |
| `list_wiki_pages` | 프로젝트 Wiki 페이지 |
| `get_wiki_page` | Wiki 페이지 가져오기 |
| `create_wiki_page` | Wiki 페이지 생성 |
| `update_wiki_page` | Wiki 페이지 업데이트 |
| `delete_wiki_page` | Wiki 페이지 삭제 |
| `rename_wiki_page` | Wiki 페이지 이름 변경 |

### 게시판

| 도구 | 설명 |
|------|-------------|
| `list_boards` | 프로젝트 게시판 |
| `list_board_topics` | 선택한 게시판의 주제 |
| `get_board_message` | 간략한 답글이 있는 게시판 메시지 |

### 파일

| 도구 | 설명 |
|------|-------------|
| `list_project_files` | 프로젝트 파일 |
| `upload_file` | 파일 업로드 |
| `delete_attachment` | 첨부 파일 삭제 |
| `get_attachment` | 첨부 파일 메타데이터 및 `content_url` |
| `download_attachment` | 첨부 파일 내용(`content_base64`, 최대 10 MiB) |

### 유틸리티

| 도구 | 설명 |
|------|-------------|
| `get_mcp_info` | MCP 플러그인 버전, read-only 모드, 현재 사용자 및 사용 가능한 capabilities |

### 접근 및 응답

Tools는 `structuredContent`의 JSON envelope와 `content`의 텍스트 표현을 반환합니다.

Write 작업은 **읽기 전용 모드** 설정으로 차단됩니다.

도구별 권한 외에 전역 권한 **MCP 사용**이 항상 확인됩니다.

데이터 접근은 표준 Redmine 권한 및 가시성 규칙을 통해 적용됩니다. 프로젝트 및 이슈 데이터에는 `Project.visible`과 `Issue.visible`이 사용됩니다.

## 다른 플러그인의 확장

설치된 Redmine 플러그인은 필요한 경우 자체 MCP tools를 추가하고 resources, prompts, capabilities를 등록할 수 있습니다.

수정할 수 없는 플러그인을 위한 내장 통합은 `redmine_mcp/lib/redmine_mcp/extensions/`에 있으며 동일한 Extension API로 등록됩니다.

자세한 가이드: [extension_guide.md](extension_guide.md).

Cursor 또는 유사 에이전트에서 AI 지원 개발을 위해 번들 skill 디렉터리 [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/)를 AI 에이전트의 skills 폴더에 복사하거나 자체 skill의 기반으로 사용하세요.

skill 실행 시 프롬프트에서 대상 플러그인(`mcp.rb`) 통합 또는 `redmine_mcp`(`lib/redmine_mcp/extensions/`) 내장 통합 여부를 지정할 수 있습니다. 지정하지 않으면 에이전트가 경로를 선택합니다.

## 로깅

메시지는 `[redmine_mcp]` 접두사와 함께 표준 Rails 로그에 기록됩니다:

- 확장 로드
- tool/resource/prompt 등록
- 등록 및 실행 오류
- 접근 거부

## 문제 해결

| 증상 | 가능한 원인 |
|---------|-------------------|
| HTTP 503 «MCP is disabled» | 플러그인 설정에서 MCP가 활성화되지 않음 |
| HTTP 401 | API 키가 없거나 잘못됨; REST API가 비활성화됨 |
| HTTP 403(권한) | 사용자에게 **MCP 사용** 권한이 없음 |
| HTTP 403(`Host`/`Origin`) | **호스트 이름과 경로**가 Redmine 공개 URL과 일치하지 않음; reverse proxy가 원본 `Host`를 전달하지 않음; 클라이언트의 MCP URL이 일치하지 않음 — transport가 알 수 없는 host를 거부(DNS rebinding 방지) |
| `tools/list`에 tool이 보이지 않음 | 필요한 권한이 없음; tool을 제공하는 확장이 비활성화됨 |
| MCP reload 후 새 tools가 나타나지 않음 | Cursor 및 유사 클라이언트에서 서버 reload가 tool 목록을 새로 고치지 않을 수 있음 — 애플리케이션을 완전히 재시작 |
| 확장이 로드되지 않음 | `lib/.../mcp.rb` 또는 `lib/redmine_mcp/extensions/<plugin.id>.rb` 없음; 모듈이 `extend RedmineMcp::ExtensionApi`하지 않음; **MCP 확장**에서 확장 체크박스가 활성화되었는지 확인; 파일에 오류가 있으면 로그 확인 |
| `Issue not found` / `Project not found` | Redmine 가시성 규칙에 따라 이슈 또는 프로젝트가 현재 사용자에게 보이지 않음 |

## 라이선스

이 플러그인은 GNU General Public License
버전 2 또는 그 이후 버전에 따라 라이선스됩니다.

자세한 내용은 [LICENSE](../../../LICENSE)를 참조하세요.
