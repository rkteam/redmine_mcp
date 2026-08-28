# 내장 도구 (core tools)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## 개요

Redmine MCP 플러그인은 Redmine 프로젝트, 이슈, 시간 추적, 위키, 포럼, 파일 및 참조 데이터(읽기 및 쓰기) 작업을 위한 도구 세트를 제공합니다.

## 목표

추가 플러그인 설치 없이 AI 클라이언트에 프로젝트 관리, 이슈 작업, 시간 추적, 탐색, 검색 및 위키, 게시판, 파일 작업 및 메타 작업을 제공합니다.

## 영향을 받는 영역

- 프로젝트
- 버전
- 멤버 / 역할
- 이슈 (CRUD, relations, watchers, notes, categories, form options, dry-run validation, 저장된 쿼리)
- 시간 기록
- 트래커, 상태, 우선순위, 쿼리
- 프로젝트 활동
- 위키 페이지
- 게시판 / 메시지
- 프로젝트 파일 / 첨부 파일
- 사용자
- 권한
- 설정 (읽기 전용 모드)

## 비즈니스 규칙

### 일반 규칙

- 전체 도구 이름: `redmine_<name>` (예: `redmine_get_issue`).
- 결과는 `structuredContent`에 JSON 래퍼로 반환되고 `content`에 텍스트로 중복됩니다.
- 데이터는 Redmine 프로젝트/이슈 가시성 및 권한을 통해 필터링됩니다.
- `project` 매개변수는 문자열입니다: 문자열로 된 숫자 id (예: `"1"`) 또는 프로젝트 식별자 (예: `"ecookbook"`).
- **읽기 전용 모드**가 활성화되면 쓰기 도구는 오류를 반환합니다. `list_issue_relations`, `get_issue_form_options`, `validate_issue_create`, `validate_issue_update`를 포함한 읽기 전용 도구는 계속 사용할 수 있습니다.

### 프로젝트 관리

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `get_project_modules` | R | `view_project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### 이슈 작업

| 도구 | R/W | 권한 |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `run_issue_query` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `validate_issue_create` | R | `add_issues` |
| `validate_issue_update` | R | `edit_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | attributes — 편집 가능한 경우; `uploads`만 — 첨부 파일을 추가할 수 있는 경우 |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true`는 추가로 `set_notes_private` 필요 |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | 소스 프로젝트의 `copy_issues` 및 대상의 `add_issues` |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `list_subtasks` | R | `view_issues` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | 저널 항목이 보이고 편집 가능 (`edit_issue_notes` / `edit_own_issue_notes`); `private_notes`는 추가로 `set_notes_private` 필요 |
| `set_issue_note_private` | W | 저널 항목이 보이고 편집 가능하며, `set_notes_private` 추가 필요 |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### 사용자

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; `project` 없이 — 관리자만 |
| `list_groups` | R | (임의 프로젝트에서) `manage_members` 또는 관리자 |

### 시간 추적

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | 현재 사용자가 편집 가능한 항목 (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |
| `import_time_entries` | W | `log_time` |

### 탐색 / 열거

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_project_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `list_all_users` | R | admin |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### 검색 및 위키

| 도구 | R/W | 권한 |
|------|-----|------------|
| `search_all` | R | 검색 대상 유형 중 최소 하나에 대한 접근 (`view_issues` 및/또는 `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; 과거 `version`은 추가로 `view_wiki_edits` 필요 |
| `create_wiki_page` | W | `edit_wiki_pages` 및 페이지가 편집 가능해야 함 |
| `update_wiki_page` | W | `edit_wiki_pages` 및 페이지가 편집 가능해야 함 |
| `delete_wiki_page` | W | `delete_wiki_pages` 및 페이지가 편집 가능해야 함 |
| `rename_wiki_page` | W | `rename_wiki_pages` 및 페이지가 편집 가능해야 함 |

### 게시판

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### 파일 작업

| 도구 | R/W | 권한 |
|------|-----|------------|
| `list_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_file` | W | `manage_files` (또는 컨테이너 권한) |
| `get_attachment` | R | 첨부 파일 컨테이너에 대한 권한 |
| `download_attachment` | R | 첨부 파일 컨테이너에 대한 권한 |

### Meta

| 도구 | R/W | 권한 |
|------|-----|------------|
| `get_server_info` | R | `use_mcp` |

`get_server_info`는 `server_version`, `read_only_mode`, `auth_mode`, 간략한 현재 사용자 데이터 및 `capabilities.issue_search`를 반환합니다. 서드파티 플러그인 설치는 응답에 나열되지 않습니다: 해당 MCP 도구는 `tools/list` 및 확장이 자체 등록하는 `capabilities`를 통해 확인할 수 있습니다.

`capabilities.issue_search`에는 검색 모드가 포함됩니다:

| 모드 | 기본값 | 참고 |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | 항상 |
| `cross_resource` | `available: true`, tool `redmine_search_all` | 항상 |
| `semantic` | `available: false` | 플러그인이 `register_capability(:issue_search, :semantic)`로 재정의 가능 |

`semantic.available: true`일 때 capability에는 `tool`, `provider`, `use_when` / `avoid_when`이 포함되어야 합니다 — 시맨틱 검색을 선택할 때의 간략한 힌트. `Registry#apply_capabilities`는 provider 응답을 정규화합니다: 계약이 위반되면 `{ available: false }`가 게시됩니다.

### 보충 설명

- `confirm_delete` 없이 `delete_issue`를 호출하면 영향 미리보기를 반환합니다; **하위 작업이 하나라도** 있으면 (사용자에게 보이지 않는 것 포함) `confirm_delete_with_children`이 필요합니다. `impact`의 카운터는 현재 사용자에게 보이는 저널, 관계, 시간 항목, 자식 및 첨부 파일만 포함합니다.
- `scope=subprojects`로 `search_issues`를 호출하면 `project`가 필요하며 해당 프로젝트와 하위 프로젝트에서 검색합니다. `project` 없이는 해당 scope는 매개변수 오류입니다. `scope=my_project`는 사용자가 멤버인 프로젝트로 검색을 제한합니다.
- `get_issue`: 저널, 첨부 파일, 감시자, 관계, 자식 및 사용자 정의 필드는 명시적 `include_*`가 있을 때만 포함됩니다. 중첩 목록에는 별도의 `limit`/`offset` 및 `*_pagination` 필드가 있습니다 (저널: 기본 limit 25, 최대 100; 기타 중첩 목록: 기본 및 최대 100). 해당 `include_*` 없이는 목록이 비어 있고 pagination은 `null`입니다. 선택적 필드 (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`)는 응답에 항상 존재합니다. 사용자 정의 필드 — 현재 사용자에게 보이는 것만. 저널 — Redmine 이슈 기록과 동일한 가시성: 사용자에게 보이는 텍스트 또는 최소 하나의 상세 변경이 있는 항목만 `journals` 및 `journal_pagination`에 나타납니다. 공백, 탭 또는 줄 바꿈만으로 구성된 텍스트는 비어 있는 것으로 처리됩니다. 빈 항목과 숨겨진 상세만 있는 항목 (숨겨진 사용자 정의 필드 포함)은 목록과 `total_count` / `offset` / `has_more` 모두에서 제외됩니다. 비공개 댓글 — 자신의 댓글 또는 `view_private_notes` 권한이 있는 경우. 저널 요소에는 보이는 상세 변경만 포함됩니다. 관계 — 양쪽 모두 사용자에게 보이는 링크만. 동일한 관계 가시성 규칙이 `list_issue_relations`에도 적용됩니다.
- `get_private_notes`는 비어 있지 않은 텍스트가 있는 비공개 댓글만 반환합니다 (공백, 탭 및 줄 바꿈만 있고 다른 내용이 없으면 빈 텍스트로 간주). 페이지는 전체 이슈 기록을 로드하지 않고 `limit`/`offset`으로 제한됩니다.
- `list_project_issue_custom_fields`는 프로젝트에서 사용자에게 보이는 필드를 반환합니다. `tracker_id`가 설정되면 tracker가 프로젝트에 속해야 합니다.
- `copy_issue`는 **소스** 프로젝트에서 이슈 복사 권한과 **대상**에서 이슈 생성 권한이 필요합니다. 감시자는 사용자가 대상 프로젝트에서 감시자 추가 권한이 있을 때만 복사됩니다. 원본 링크 및 첨부 파일 복사는 Redmine 설정 `link_copied_issue` 및 `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`)를 따릅니다. 필드 재정의 없이도 복사는 폼 쓰기 규칙을 거칩니다. 소스 이슈의 부모는 허용될 때 보존됩니다 (동일 프로젝트 내 복사 포함).
- `create_issue_relation`은 허용된 관계 속성만 적용하고 변경을 이슈 저널에 기록합니다. `delete_issue_relation`은 현재 사용자가 관계를 삭제할 수 있을 때만 허용됩니다 (양쪽 이슈가 보이고 최소 한쪽에서 관계 관리 권한이 있음); 삭제도 저널에 기록됩니다.
- `add_project_member` / `update_project_member`는 현재 사용자가 프로젝트에서 관리할 수 있는 역할만 수락합니다. 해당 집합 밖의 역할은 거부됩니다; 역할은 부분적으로 할당되지 않습니다.
- `create_issue_category` / `update_issue_category`: `assigned_to_id`는 principal ID (사용자 또는 그룹)이며 사용자만이 아닙니다.
- 이슈 첨부 파일에 대한 `delete_file`은 전역 `edit_issues`뿐만 아니라 "이 이슈의 첨부 파일을 삭제할 수 있는지" 규칙을 따릅니다 (자신의 이슈 및 tracker 권한 포함). `tools/list`에서 도구는 사용자가 최소 하나의 첨부 파일 (프로젝트 파일, 이슈 또는 위키)을 삭제할 수 있을 때 보이며, 전역 `manage_files`만으로는 보이지 않습니다.
- `get_wiki_page`: `attachments`는 항상 응답에 포함됩니다; 기본값 `[]` 및 `attachments_pagination: null`; `include_attachments=true`일 때 — `attachment_limit`/`attachment_offset` (기본 및 최대 100)으로 페이지네이션된 첨부 파일 목록. 과거 `version`은 위키 편집 보기 권한이 필요합니다. 보호된 페이지 변경, 이름 변경 또는 삭제는 위키 페이지 보호 권한이 필요합니다.
- `list_issues`, `search_issues`, `list_subtasks`, `run_issue_query`: 기본적으로 요약 필드; `fields` 또는 `get_issue`를 통해 전체 설명.
- `create_issue` 및 `update_issue`는 명시적 이슈 **attributes** (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields` 등)를 수락합니다. 생성 시 `subject` 및 `description`을 포함한 모든 명시적으로 전달된 attributes는 Redmine 웹 폼과 동일한 쓰기 규칙을 거칩니다. 허용된 필드 값을 모를 때 에이전트는 `get_issue_form_options`를 호출해야 합니다. Redmine이 적용하지 않은 명시적으로 전달된 값은 부분 성공이 아닌 오류입니다.
- 클라이언트가 `create_issue` / `validate_issue_create`에서 `start_date`를 **전달하지 않았고**, Redmine에 "시작일 = 생성일"이 활성화되어 있으면 (`default_issue_start_date_to_creation_date`), MCP는 `start_date`를 사용자의 오늘 날짜로 설정합니다 — 새 이슈 폼과 같습니다. 명시적 `start_date` ( `null` 포함)는 이 대체를 비활성화합니다. `copy_issue` 및 `update_issue`는 날짜를 자체적으로 대체하지 않습니다.
- `update_issue`는 `notes`, `private_notes` 또는 `watcher_user_ids`를 수락하지 않습니다. 댓글 — `add_issue_note`; 감시자 — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue`는 이슈에 파일을 첨부하기 위한 `uploads`도 지원합니다. 첨부 파일은 속성 검증 (`rejected_fields` 포함) 성공 후에만 처리됩니다. `uploads`만 있는 호출 (attributes 없음)은 사용자가 이슈에 첨부 파일을 추가할 수 있을 때 허용됩니다 — 댓글 작성은 허용되지만 attributes를 편집할 수 없는 경우 포함. 선택적 `idempotency_key`는 응답 손실 후 재시도를 보호합니다 (동일 파일 재업로드 포함). 응답의 `journal_id`는 **이번** 호출의 저널 항목이며 최신 이슈 항목이 아닙니다.
- 선택적 필드를 지우려면 `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` 또는 `estimated_hours`에 `null`을 전달합니다. `update_version.due_date` / `wiki_page_title` 및 `update_issue_category.assigned_to_id`도 동일합니다.
- `create_issue`는 `uploads`를 지원하지 않습니다.
- `update_issue`는 `uploads[*].content_base64` 및 `uploads[*].filename`을 수락합니다. 업로드 성공 후 응답에 `added_attachments`가 포함됩니다 — 이번 호출의 파일만, 전체 이슈 첨부 파일 목록이 아님. 손상된 Base64는 매개변수 오류입니다.
- `update_issue`는 `status_name`을 수락하고 `status_id`로 해석합니다.
- `upload_file`은 `content_base64` (최대 20 MiB)를 수락합니다; `project`, `filename`, `content_base64`는 필수입니다.
- `get_attachment`는 `attachment_id`, `filename`, `content_type`, `size` (첨부 파일 크기) 및 `content_url` (파일 바이트 없음)을 반환합니다.
- `download_attachment`는 현재 사용자에게 보이는 단일 첨부 파일에 대해 `attachment_id`, `filename`, `content_type`, `size` (실제 콘텐츠 크기, 바이트) 및 `content_base64`를 반환합니다. MIME을 알 수 없으면 — `application/octet-stream`. `downloads` 카운터를 증가시키지 않습니다. 크기 제한은 10 MiB (읽기 전 디스크의 `File.size` 및 읽기 후 `bytesize` 확인); 초과 시 — `FILE_TOO_LARGE`. 서버 파일시스템 경로는 응답에 반환되지 않습니다. `attachment_id`는 `include_attachments=true`로 `redmine_get_issue` / `redmine_get_wiki_page`, `redmine_list_files` 또는 `redmine_get_attachment`에서 가져옵니다. 첨부 파일을 파일로 읽거나 파싱하거나 처리하려면 `content_base64`를 로컬에서 디코딩합니다. 존재하지 않거나 접근 불가한 첨부 파일은 동일한 "not found" 응답을 반환합니다.
- `create_time_entry` 및 `import_time_entries.entries` 항목은 `hours`와 `project` 또는 `issue_id` 중 하나가 필요합니다. `hours`는 0일 수 있습니다; 0 유효성 및 일일 최대값은 Redmine이 확인합니다 (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- 이슈 생성/업데이트의 `assigned_to_id`는 principal ID (`get_issue_form_options.assignees`의 사용자 또는 그룹)입니다; `null`은 담당자를 지웁니다. `add_issue_watcher` / `remove_issue_watcher`의 `user_id`는 principal ID (사용자 또는 그룹)입니다. 다른 도구에서 `user_id`는 사용자 ID입니다. 현재 사용자의 경우 `assignee_ref` 또는 `user_ref`에 값 `me`를 사용합니다.
- 민감한 업데이트/삭제의 `expected_updated_at` (선택): `updated_on`과 일치하지 않으면 `CONFLICT`를 반환합니다.
- `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `import_time_entries`, `upload_file`의 `idempotency_key` (선택): 동일한 키와 **동일한 인수 집합** (키 자체 제외)으로 재시도하면 캐시된 성공 결과를 반환합니다 (TTL 24시간). 동일한 키에 다른 payload — `CONFLICT`, 중복 쓰기 없음. 첫 요청이 아직 실행 중일 때 동일한 키로 재시도하면 또 다른 쓰기를 수행하지 않습니다 ("진행 중" 마커는 성공 결과와 동일한 24시간 동안 유지). fingerprint 없는 캐시 항목 (이 버전 이전 캐시)은 TTL 만료 전까지 동일한 키로 이전과 같이 반환됩니다. 서버 타임아웃 60초는 **읽기**에 적용됩니다. 쓰기 작업은 성공적인 저장 후 idempotency 결과를 기록할 수 있도록 서버 타임아웃으로 중단되지 않습니다; 연결을 잃은 경우 클라이언트는 동일한 키로 재시도할 수 있습니다. `import_time_entries`의 예기치 않은 예외는 해당 호출에서 이미 삽입된 항목을 롤백합니다; 개별 행의 일반 검증 오류는 성공한 항목을 롤백하지 않고 계속 수집됩니다.
- `delete_file`은 기본적으로 프로젝트/버전 파일만 삭제합니다; 이슈/위키 첨부 파일의 경우 `confirm_delete_any_attachment=true`가 필요합니다.
- 목록/검색은 `limit`/`offset`을 사용합니다. DB 쿼리의 경우 페이지는 이미 로드된 전체 목록을 자르는 것이 아니라 쿼리 수준에서 제한됩니다. 페이지네이션된 MCP 컬렉션은 명시적이고 안정적인 순서를 가집니다; 마지막 기준은 항상 `id`이므로 페이지가 항목을 건너뛰거나 중복하지 않습니다.
- 부분 문자열 검색 (`query`, `login`, `name` 및 텍스트 `search_issues`)은 문자를 문자 그대로 일치시킵니다: `%` 및 `_`는 SQL 와일드카드가 아닙니다.
- MCP 제한: 읽기 도구 타임아웃 60초, 사용자당 rate limit 120 요청/분, MCP 요청 HTTP 본문 36 MiB, 최대 JSON 도구 args 크기 32 MiB, 업로드 base64 최대 20 MiB, 다운로드 base64 최대 10 MiB. 모든 `content_base64`의 손상된 Base64는 도구 실행 전 매개변수 오류입니다.
- 접근 거부를 포함한 모든 도구 호출은 구조화된 감사 로그 (도구, 사용자, 대상 ID, 결과, duration, correlation_id)에 기록되고 rate limit에 집계됩니다; base64 콘텐츠 및 비공개 댓글은 로그에 기록되지 않습니다. 대상 ID에는 `board_id`, `message_id`, `query_id`, `user_id`, `group_id` 등이 포함됩니다.
- 각 코어 도구의 `outputSchema`는 `data`의 최상위 수준 (목록의 경우 `items` 요소 필드)을 설명하며 임의의 열린 객체가 아닙니다. 스키마 필드 집합은 실제 응답과 일치합니다: `created_on` 없는 `list_users`, `created_on` 있는 `list_all_users`; `get_attachment`는 `size` 및 `content_url` 포함. 실제 응답에서 비어 있을 수 있는 필드는 `null` 허용 (`time_entry.issue`, include 없는 `*_pagination`, `estimation_accuracy`, 첨부 파일 `content_type` 포함). 사용자 정의 필드 값 및 `possible_values`는 객체로만 제한되지 않습니다. `attachments_not_saved`는 파일 이름 배열입니다.
- 스키마의 `summarize_project_status.days`: 기본값 30, 최소 1, 최대 365.
- `search_all.resources`: 최대 두 개의 고유 값.
- `version_id`, `file_id`, `tracker_id`는 1 이상의 정수입니다.

### `get_project`

- 입력: `project` (필수).
- 출력: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (객체 `id`/`name`/`identifier` 또는 `null`), `subprojects` (보이는 하위 프로젝트 간략 목록: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`.
- `parent`는 부모 프로젝트가 현재 사용자에게 보일 때만 채워집니다; 그렇지 않으면 `null`.
- 멤버, 활성화된 모듈 또는 이슈 통계를 반환하지 않습니다. 모듈 — `get_project_modules`; 멤버 — `list_project_members`; 이슈 집계 — `summarize_project_status`.

### `get_issue_form_options`

- 생성/업데이트 전 여러 참조 조회 대신 한 번의 호출. 별도의 `list_project_trackers`, `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields`는 계속 사용 가능합니다.
- 입력: `project` (필수); 선택적으로 `tracker_id`, `issue_id`.
- 스냅샷은 전체 프로젝트 구성이 아닌 **현재 사용자의 이슈 폼**을 반영합니다: Redmine UI가 제공하는 것과 동일한 허용 값.
- `issue_id` 없이 `tracker_id`는 생성 폼 컨텍스트를 설정합니다. tracker는 현재 사용자가 폼에서 선택할 수 있어야 합니다; 그렇지 않으면 — 매개변수 오류.
- `issue_id`는 이 프로젝트의 기존 보이는 이슈에 대한 폼을 설정합니다. `issue_id`가 있을 때 `tracker_id`는 이슈의 현재 tracker와 일치할 때만 허용됩니다; 그렇지 않으면 — 매개변수 오류 (tracker 변경은 이 도구를 통해 모델링되지 않음).
- 출력 — 페이지네이션 없는 폼 스냅샷:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: 현재 사용자가 이 폼에서 선택할 수 있는 tracker (`id`, `name`), 프로젝트에 활성화된 모든 tracker가 아님;
  - `priorities`: 활성 우선순위 (`id`, `name`, `is_default`);
  - `categories`: 프로젝트 카테고리 (`id`, `name`);
  - `versions`: 이 폼에서 선택 가능한 버전 (`id`, `name`, `status`, `due_date`);
  - `assignees`: 이 폼 컨텍스트에서 할당할 수 있는 principal. 요소: `id`, `name`, `type` (`user` 또는 `group`); `user`의 경우 추가로 `login`. Redmine에 그룹에 이슈 할당이 활성화되어 있으면 그룹이 포함됩니다;
  - `custom_fields`: 프로젝트/tracker, 가시성, workflow 읽기 전용을 고려하여 현재 사용자가 폼에서 편집할 수 있는 필드만. 요소: `id`, `name`, `field_format`, `required` (필드 필수 또는 workflow에 의해 필수), `readonly` (이 목록에서 항상 `false`), `multiple`, `default_value`, `possible_values`, `trackers`. 폼 컨텍스트 — `issue_id`의 이슈 또는 `tracker_id`를 고려한 생성 초안;
  - `possible_values` — 객체 배열 `{ "label": "...", "value": "..." }`. 별도 label이 없는 목록의 경우 `label`은 `value`와 일치합니다. user/version/enumeration의 경우 `label`은 표시 이름, `value`는 식별자;
  - `statuses`: 현재 사용자의 workflow에서 허용된 상태. `issue_id`가 있으면 — 이 보이는 이슈에 대한 전환. `issue_id` 없이 — 생성용 초기 상태 (`tracker_id`가 설정되면 고려);
  - `editable_fields`: 현재 사용자가 폼에서 설정할 수 있는 create/update에서 이 MCP 계약이 수락하는 속성 이름, 문자열로 된 편집 가능한 사용자 정의 필드 id. `notes`, `private_notes`, `watcher_user_ids` 및 MCP 쓰기 도구에 없는 기타 웹 폼 필드는 포함하지 않음;
  - `required_fields`: 현재 사용자에게 이 폼에서 필수인 필드 이름, `editable_fields`와 동일한 이름 형식.
- 존재하지 않는 `tracker_id`, 사용자에게 허용되지 않는 tracker, 또는 프로젝트 밖/보이지 않는 `issue_id` — 매개변수 오류.

### `add_issue_note`

- 이슈 속성을 변경하지 않고 기존 보이는 이슈에 댓글을 추가합니다.
- 입력: `issue_id` (필수), `notes` (필수), 선택적으로 `private_notes`, `uploads`, `idempotency_key`.
- 권한: 사용자가 이 이슈에 댓글을 추가할 수 있음. `private_notes=true`는 비공개 댓글 작성 권한이 필요합니다; 그렇지 않으면 — 거부, 댓글이 생성되지 않음. 동일 호출의 첨부 파일은 사용자가 이슈에 첨부 파일을 추가할 수 있을 때 허용됩니다.
- 이슈 필드 또는 감시자 목록을 수락하지 않습니다.
- 출력: `issue_id`, `journal_id`, `notes`, `private_notes`; `uploads`가 있으면 — `added_attachments` (이번 호출의 파일만).
- 읽기 전용 모드에서 사용할 수 없습니다.

### `update_issue_note` / `set_issue_note_private`

- 현재 사용자가 **볼 수 있는** 저널 항목에서만 작동합니다 (비공개 댓글 보기 권한 없이 다른 사용자의 비공개 댓글은 접근 불가).
- 항목은 현재 사용자가 편집할 수 있어야 합니다 (댓글 편집 또는 자신의 댓글 편집 권한).
- `update_issue_note.notes`는 빈 문자열일 수 있습니다 (기존 항목의 텍스트 지우기). `add_issue_note`를 통한 새 댓글은 비어 있을 수 없습니다.
- 프라이버시 변경 (`private_notes` / `is_private`)은 댓글을 비공개로 만드는 별도 권한이 필요합니다; 그렇지 않으면 거부, 텍스트가 부분적으로 변경되지 않음.
- 저널 항목을 편집한 사람을 기록합니다.
- 읽기 전용 모드에서 사용할 수 없습니다.

### `validate_issue_create` / `validate_issue_update`

- 쓰기 도구의 `validate_only` 매개변수가 아닌 별도의 읽기 전용 도구. 읽기 전용 모드에서 사용 가능합니다.
- `validate_issue_create`: `idempotency_key` 없이 `create_issue`와 동일한 필드. `project` 및 `subject`는 필수. 권한 `add_issues`.
- `validate_issue_update`: **이슈 attributes**만 dry-run (`uploads` 없이 `update_issue`와 같음). `issue_id`는 필수. 이슈는 현재 사용자가 편집할 수 있어야 합니다. 검증 전에 DB 쓰기 없이 사용자 저널 컨텍스트가 생성됩니다 (실제 업데이트와 같음).
- 동작: 저장하지 않고 attributes를 이슈에 적용. Redmine 데이터는 변경되지 않습니다.
- attributes는 Redmine 웹 폼과 동일한 쓰기 규칙을 거칩니다. 클라이언트가 값을 **명시적으로 전달**했고 Redmine이 적용하지 않았으면 성공이 아닌 MCP 오류입니다.
- 이슈에서 쓰기 가능한 항목에 없는 명시적 필드 (비활성 / workflow 읽기 전용 / 파생 날짜 등)는 `rejected_fields`에 들어갑니다. `tracker_id`, `status_id`, `assigned_to_id`, `is_private`, `parent_issue_id`, `custom_fields`의 경우 요청된 값이 실제로 적용되었는지 추가로 확인됩니다.
- 동일한 규칙이 `create_issue`, `update_issue`, `copy_issue`에 적용됩니다: 명시적으로 요청된 값이 적용되지 않으면 쓰기 없음.
- 성공: `{ "valid": true, "errors": [] }`.
- 실패: `{ "valid": false, "errors": ["..."] }`. 일부 명시적 필드가 적용되지 않았으면 — 추가로 `rejected_fields` (필드 이름, 예: `["tracker_id"]`) 및 일반적인 오류의 경우 create/update와 동일한 형식의 `missing_required_fields` / `hint`.
- 또한 포착: 현재 사용자에게 사용 불가한 tracker; 잘못되었거나 사용 불가한 사용자 정의 필드 값; workflow에 의해 금지된 상태 전환; 할당에 사용 불가한 담당자.

### `list_issues` — 확장 필터

- 기존 평면 필터 (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`)는 유지됩니다.
- 선택적 `filters`: 객체 배열 `{ "field": "...", "operator": "...", "values": ["..."] }`. `values`는 문자열 배열; 값이 없는 연산자의 경우 빈 배열 허용.
- 허용 `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id`, 이슈 사용자 정의 필드의 `cf_<id>`.
- 연산자는 표준 Redmine 쿼리 연산자로 `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*` 포함. 연산자는 필드 유형에 유효해야 합니다; 그렇지 않으면 — 매개변수 오류.
- 알 수 없는 `field` 또는 잘못된 `operator` — 매개변수 오류, 쿼리가 실행되지 않음.
- 평면 필터와 `filters`는 AND로 결합됩니다.
- 필터는 현재 사용자에게 보이는 이슈에만 적용됩니다.

### `run_issue_query`

- 입력: `query_id` (필수, `list_queries`에서); 선택적으로 `project`, `fields`, `limit`/`offset`.
- 현재 사용자에게 보이는 저장된 이슈 쿼리를 실행합니다. 응답 형식은 `list_issues`와 동일한 목록 래퍼입니다.
- 쿼리가 프로젝트 범위이면 결과는 해당 프로젝트 (및 쿼리 가시성 규칙)로 제한됩니다. 프로젝트 쿼리의 선택적 `project`는 쿼리의 프로젝트와 일치해야 합니다; 그렇지 않으면 — 매개변수 오류.
- 쿼리가 전역이면 선택적 `project`는 해당 보이는 프로젝트로 선택을 좁힙니다.
- 보이지 않거나 존재하지 않는 `query_id` — 오류.
- `list_queries`는 쿼리를 실행하지 않습니다; 실행에는 `run_issue_query`를 사용합니다.

### `list_project_activities`

- 입력: `project` (필수); 선택적으로 `from`, `to` (날짜 `YYYY-MM-DD`), `author_id`, `event_types` (문자열 배열), `limit`/`offset`.
- 기본 창 — 최근 7일 (`to` = 오늘, `from` = 오늘에서 6일 전). 최대 창 길이 — 90일; 초과 시 — 매개변수 오류.
- 프로젝트 활동 피드의 이벤트: 유형, 시간, 작성자 (`id`/`name`), `title`, `description`, `url`. 순서 — 최신 이벤트 먼저; 동일 시간 — 더 높은 `id` 먼저.
- 다른 `list_*`와 같은 래퍼.
- `event_types`는 이벤트 유형을 제한합니다. 사용자에게 사용 불가하거나 프로젝트에서 비활성화된 유형은 선택에서 제외됩니다 (오류 없음).
- 존재하지 않는 `author_id` — 빈 목록, 오류 아님.

### `summarize_project_status`

기존 필드는 유지됩니다: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

`days` 창 (기본값 30, 범위 1–365)은 여전히 `recent_activity` 및 아래 나열된 기간 메트릭에 영향을 줍니다. 범위 밖의 값은 스키마에서 거부됩니다. `totals` 및 breakdown은 날짜 필터 없이 보이는 프로젝트 이슈 전체에 대해 DB 집계를 통해 계산되며, 모든 이슈를 메모리에 로드하지 않습니다. 하위 프로젝트는 포함되지 않습니다.

추가 필드:

- `overdue_count` — `due_date`가 사용자의 오늘보다 엄격히 이전인 열린 보이는 이슈 수.
- `unassigned_count` — 담당자가 없는 열린 보이는 이슈 수.
- `stale_issues_count` — `updated_on`이 `days` 창 시작보다 오래된 열린 보이는 이슈 수.
- `issues_closed_during_period` — `closed_on`이 `days` 창 내에 있는 보이는 이슈 수.
- `estimated_hours` — 보이는 프로젝트 이슈 추정치 합계 (추정이 있는 이슈가 없으면 `null`, 그렇지 않으면 0 포함 숫자).
- `spent_hours` — 보이는 프로젝트 이슈에 소요된 시간 합계 (항목이 없으면 0). 프로젝트에서 `view_time_entries` 필요; 권한 없으면 필드는 `null`.
- `average_resolution_hours` — `days` 창에서 닫힌 이슈의 `(closed_on - created_on)` 평균 시간(시간); 해당 이슈가 없으면 `null`.
- `estimation_accuracy` — 추정과 0이 아닌/기록된 시간이 모두 있는 창에서 닫힌 이슈에 대해: `{ "issues_count", "total_estimated", "total_spent" }`. 일치하는 이슈가 없으면 — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. 프로젝트에서 `view_time_entries` 필요; 권한 없으면 필드는 `null`.
- `reopened_count` — `days` 창 내에 저널 상태가 닫힘에서 열림으로 변경된 보이는 이슈 수. 각 이슈는 최대 한 번 집계됩니다.

도구는 텍스트 "프로젝트 상태 분석"이 아닌 사실을 반환합니다.

### `get_version`

- 입력: `version_id` (필수); 선택적으로 `project`. `project`가 설정되면 버전이 이 보이는 프로젝트의 공유 버전에 있을 때 접근 가능합니다 (버전의 소스 프로젝트가 사용자에게 보이지 않아도). `project` 없이는 버전이 소스 프로젝트에서 보여야 합니다.
- 출력: `list_versions` 요소와 같은 필드 (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) 및 집계: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- 집계는 현재 사용자에게 보이는 버전 이슈에 대해서만 계산됩니다.
- 이슈 목록은 반환되지 않습니다.
- `spent_hours`는 버전 프로젝트에서 `view_time_entries` 필요; 권한 없으면 — `null`. 보이는 버전 이슈에 대해서만, 현재 사용자가 볼 수 있는 시간 항목만 합산 (`time_entries_visibility=own` 포함).

### 게시판

- 프로젝트 포럼 모듈이 활성화되어 있어야 합니다; 그렇지 않으면 오류 "Boards module is not enabled for this project" (위키 유사).
- 권한 `view_messages`. 포럼 쓰기 작업 없음.
- `list_boards`: `project` 필수; 페이지네이션. 요소: `id`, `name`, `description`, `parent_id` (루트 보드는 `null`), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` 필수; 페이지네이션. 루트 메시지만 (부모 없음). 요소: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` 필수. 출력: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — 각 답글의 전체 텍스트 없이 간략한 답글 목록 (`id`, `subject`, `author`, `created_on`), `replies_limit`/`replies_offset` (기본 및 최대 100) 및 `replies_pagination`.
- 보이지 않는 보드/메시지 또는 다른 프로젝트의 보드 — "not found" 오류.

### `list_users`

- `project`가 있으면: 활성 **사용자** 프로젝트 멤버 (권한 `view_members`). 프로젝트의 그룹 멤버십은 그룹으로 나타나지 않습니다; 그룹의 사용자는 직접 멤버인 경우에만. `project` 없이 — 관리자만.
- 요소: `id`, `login`, `firstname`, `lastname`, `mail`. `created_on`은 포함하지 않음 (해당 필드는 `list_all_users`에 있음).
- 선택적 `query`: `login`, `firstname`, `lastname`에 대한 대소문자 구분 없는 부분 문자열.
- 선택적 `login`은 유지됩니다 (login 부분 문자열만) 호환성을 위해. `query`와 `login`이 모두 설정되면 두 조건 모두 적용 (AND).

### `list_groups`

- `add_project_member`에서 `group_id` 선택을 위한 **보이는** 부여 가능 그룹 (`id`, `name`)의 페이지네이션 목록.
- 선택적 `query`: 그룹 이름에 대한 대소문자 구분 없는 부분 문자열; `%` 및 `_`는 문자 그대로 일치.
- 권한: 관리자 또는 최소 하나의 보이는 프로젝트에서 `manage_members`.
- 그룹 멤버십 또는 멤버십을 반환하지 않습니다.

### `list_project_member_candidates`

- 프로젝트에 추가할 후보: 아직 프로젝트에 없는 활성 보이는 사용자 및 그룹.
- 입력: `project` (필수); 선택적으로 `query` (부분 문자열, Redmine 멤버 선택기와 같음).
- 출력 목록 래퍼: `id`, `name`, `type` (`user` 또는 `group`); 사용자의 경우 추가로 `login`.
- 프로젝트에서 권한 `manage_members`.
- `add_project_member`: 사용자만 `user_id`, 그룹만 `group_id`. 잘못된 유형의 ID — 매개변수 오류. 추가 전에 이 도구 (또는 후보가 이미 알려진 경우 `list_users` / `list_groups`)에서 ID를 가져옵니다.

### `list_roles`

- 지정된 프로젝트에서 현재 사용자가 관리할 수 있는 역할만.
- 입력: `project` (필수).
- 프로젝트에서 권한 `manage_members`.
- 관리자의 경우 집합은 할당 가능한 프로젝트 역할과 일치합니다 (Non member / Anonymous 제외).

## 엣지 케이스

- 존재하지 않거나 접근 불가한 프로젝트 또는 이슈 — `{ "error": "..." }`.
- 읽기 전용 모드 — handler 호출 **전에** Extension API 도구를 포함한 쓰기 도구에 `{ "error": "MCP is in read-only mode..." }`; validate/form options/list/get는 계속 사용 가능.
- 빈 목록/검색 결과 — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- 페이지네이션이 있는 목록/검색은 항상 `data.items` 및 `meta` (`total_count`, `limit`, `offset`, `has_more`, `next_offset`)를 반환합니다. 기본 limit 25, 최대 100.
- 모든 `list_*` 도구 (참조 포함: trackers, statuses, roles, queries, boards, board topics 등)는 동일한 래퍼를 사용합니다. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` 및 validate 도구 — 목록 래퍼가 아닌 단일 객체.
- `download_attachment`: 존재하지 않거나 접근 불가한 첨부 파일 — 동일한 "not found" 오류; 디스크에서 파일을 읽을 수 없음 — 오류; 디스크 또는 읽기 후 크기가 10 MiB 초과 — `FILE_TOO_LARGE` (낮은 DB `filesize`로 제한을 우회하지 않음). 구분 불가능한 "없음 / 접근 없음" 규칙 — `get_attachment`에도 동일.
- `list_project_activities`: 90일보다 긴 창 — 매개변수 오류; `from`이 `to` 이후 — 매개변수 오류.
- `run_issue_query`: 보이지 않는 쿼리 — 존재하지 않는 것으로 처리.
- 다른 프로젝트의 이슈에 대한 `issue_id`로 `get_issue_form_options` — 매개변수 오류.
- 해당 이슈의 tracker와 같지 않은 `issue_id` 및 `tracker_id`로 `get_issue_form_options` — 매개변수 오류.
- Validate 도구는 이슈를 생성하지 않고, 이슈를 업데이트하지 않으며, 저널 항목을 생성하지 않고, `idempotency_key`를 소비하지 않습니다.
- MCP를 통한 쓰기는 Redmine 모델을 거칩니다. 모델 콜백이 실행됩니다; 웹 인터페이스 컨트롤러 hook은 호출되지 않습니다.

## 오류 처리

- 권한 없음 — `tools/list`에 도구가 보이지 않거나 "Permission denied".
- 모델 검증 오류 — `{ "error": "<messages>" }` (이슈 create/update 및 validate 도구의 경우 추가로 번역 텍스트 파싱 없이 모델 오류 심볼의 필드 이름인 `missing_required_fields` 및 `hint`).
- 비활성화된 위키/boards 모듈 — "not found"가 아닌 별도 오류 메시지.
- 래퍼의 정규 오류 코드는 handler가 명시적으로 설정합니다; 코드는 메시지 텍스트에서 파생되지 않으며 사용자 언어에 의존하지 않습니다.

## 테스트 시나리오

1. `list_projects` / `list_issues`는 페이지네이션이 있는 래퍼 `data.items` + `meta`를 반환합니다.
2. `include_*` 없이 `get_issue`는 저널/첨부 파일을 반환하지 않음; `include_journals`가 있으면 — 페이지네이션이 있는 저널.
3. 텍스트로 `search_issues`는 이슈를 찾음; `search_all`은 여러 유형 검색 시 위키를 포함.
4. 유효한 필드로 `create_issue` / `update_issue`는 성공; 권한 없거나 읽기 전용 — 오류.
4a. 시작일 설정이 활성화된 상태에서 `start_date` 없이 `create_issue`는 오늘 날짜를 설정; 명시적 `start_date` 또는 `null`은 해당 설정으로 덮어쓰이지 않음.
5. `confirm_delete` 없이 `delete_issue`는 `INVALID_STATE` 및 impact를 반환; 확인 시 삭제.
6. `create_time_entry`는 `hours`와 `project` 또는 `issue_id`가 필요; `import_time_entries`는 배치를 수락.
7. Wiki 모듈이 활성화되면 `list_wiki_pages` / `get_wiki_page` / `create_wiki_page`가 작동.
8. `upload_file`은 `filename` 및 `content_base64`가 필요; 이슈 첨부 파일에 대한 `delete_file`은 확인 필요.
9. `use_mcp` 없는 사용자는 MCP 인증을 통과하지 않음; 도구 권한 없으면 `tools/list`에서 보이지 않음.
10. 동일한 `idempotency_key` 및 동일한 인수로 `create_issue` 재시도는 중복을 생성하지 않음; 다른 subject로 동일한 키 — `CONFLICT`.
11. 보이는 이슈 첨부 파일에 대한 `download_attachment`는 실제 콘텐츠 `size`가 있는 `content_base64`를 반환; 디스크에서 > 10 MiB 파일 (작은 메타데이터여도) — `FILE_TOO_LARGE`; 존재하지 않거나 접근 불가한 첨부 파일은 구분 불가.
12. 식별자로 `get_project`는 description, subprojects 및 `last_activity_date`를 반환; 접근 불가 프로젝트 — 오류.
13. 프로젝트에 대한 `get_issue_form_options`는 trackers/statuses/priorities/categories/versions/assignees/custom_fields 및 `editable_fields` / `required_fields` 목록을 반환; `trackers` — 현재 사용자에게 사용 가능한 것만; `issue_id`가 있으면 statuses는 해당 이슈에 허용된 전환을 반영; `issue_id` + 다른 `tracker_id` — 오류; `possible_values` — `label`/`value` 객체.
14. 잘못된 tracker 또는 status로 `validate_issue_create`는 `valid: false` 및 `rejected_fields`를 반환, 이슈를 생성하지 않음; 읽기 전용 모드에서 호출은 성공.
15. `filters` (`due_date` `<=` 날짜, `priority_id` `!`)가 있는 `list_issues`는 일치하는 보이는 이슈만 반환; 알 수 없는 `field` — 오류.
16. 보이는 `query_id`로 `run_issue_query`는 UI의 저장된 쿼리와 동일한 이슈를 반환; 보이지 않는 쿼리 — 오류.
17. 3일에 대한 `list_project_activities`는 페이지네이션이 있는 프로젝트 이벤트를 반환; 91일 창 — 오류.
18. `summarize_project_status`는 `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period`, `reopened_count`를 포함.
19. `get_version`은 이슈 목록 없이 집계 `open_issues_count` / `completed_percent`를 반환.
20. Boards 모듈이 활성화되면 `list_boards` / `list_board_topics` / `get_board_message`가 작동; 비활성화 시 — 모듈 오류.
21. `project` 및 이름으로 `query`가 있는 `list_users`는 login을 모르고도 멤버를 찾음.
22. `get_issue_form_options`는 `type` user/group이 있는 assignees 및 `required`/`readonly`가 있는 편집 가능한 사용자 정의 필드만 반환.
23. Redmine이 적용하지 않는 명시적으로 전달된 값 (비활성/읽기 전용 코어 필드, 생성 시 `description` 포함)으로 `create_issue` / `update_issue` / `copy_issue` / `validate_issue_create`는 오류를 반환하고 부분 변경을 저장하지 않음.
24. `validate_issue_update`는 notes를 수락하지 않음; 댓글은 `add_issue_note`로 생성. `add_issue_notes`로 `add_issue_note`는 `edit_issues` 없이 성공; `set_notes_private` 없이 `private_notes` — 거부. `uploads`만 있는 `update_issue`는 `edit_issues` 없이 첨부 파일 추가 권한으로 성공.
25. `manage_members`가 있는 사용자에게 `list_groups`는 부여 가능한 그룹을 반환.
26. `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null`로 `update_issue`는 쓰기 가능하면 필드를 지움.
27. `update_issue_note` / `set_issue_note_private`는 비공개 댓글 보기 권한이 없으면 다른 사용자의 비공개 댓글을 변경하지 않음.
28. 댓글 편집 권한은 있지만 비공개로 만들 권한이 없는 사용자는 공개 댓글 텍스트를 변경할 수 있고 프라이버시 플래그는 변경할 수 없음.
29. `uploads`가 있는 `add_issue_note`는 한 번의 호출로 댓글과 첨부 파일을 생성; 동일한 `idempotency_key`로 재시도는 중복하지 않음.
30. `uploads` 및 `idempotency_key`가 있는 `update_issue`: 동일한 payload로 재시도는 첨부 파일을 중복하지 않음; 동일한 키로 다른 파일 — `CONFLICT`. 손상된 Base64 — 매개변수 오류.
31. `get_issue`는 숨겨진 사용자 정의 필드, 보이지 않는 저널 상세 또는 보이지 않는 이슈가 있는 관계를 반환하지 않음. `get_version` 집계는 보이는 이슈에 대해서만.
32. 소스 프로젝트에서 복사 권한 없이 `copy_issue` — 거부, 대상에 `add_issues`가 있어도.
33. 사용자가 관리할 수 없는 역할로 `add_project_member` / `update_project_member` — 부분 할당 없이 거부.
34. 사용자에게 허용되지 않는 `sharing`으로 `create_version` / `update_version` — 거부. 사용 중인 버전에 대한 `delete_version` — 삭제 없이 거부.
35. `edit_own_time_entries`가 있는 시간 항목 작성자는 `update_time_entry`를 통해 자신의 항목을 업데이트할 수 있음.
36. 검색에 위키가 포함되면 `view_issues` 없이 위키 권한이 있는 사용자에게 `search_all` 사용 가능.
37. `list_project_member_candidates`는 아직 프로젝트에 없는 사용자 및 그룹을 반환; 그룹 `user_id`로 `add_project_member` — 오류.
38. 프로젝트에 대한 `list_roles`는 사용자가 관리할 수 있는 역할만 반환; `project` 없이 — 스키마 오류. 내장 Non member 및 Anonymous는 포함하지 않음.
39. 동일한 `idempotency_key`로 `copy_issue` / `create_time_entry` 재시도는 중복을 생성하지 않음; 동일한 키로 다른 payload — `CONFLICT`.
40. `%` 또는 `_`에 대한 `search_issues` 및 사용자/그룹 검색은 와일드카드가 아닌 해당 문자를 문자 그대로 일치.
41. `time_entries_visibility=own`일 때 `get_version.spent_hours`는 자신의 시간 항목만 집계.
42. `project` 없이 `scope=subprojects`로 `search_issues` — 오류; `project`가 있으면 하위 프로젝트에서 이슈를 찾음.
43. `list_project_activities`는 오래된 이벤트보다 최신 이벤트를 먼저 반환.
44. `delete_issue` impact는 숨겨진 저널, 관계 및 다른 사람의 시간 항목을 포함하지 않음; 숨겨진 하위 작업은 여전히 `confirm_delete_with_children` 필요.
45. `get_project`는 현재 사용자에게 보이지 않는 부모를 반환하지 않음.
46. `due_date`/`wiki_page_title` = `null`로 `update_version`은 필드를 지움.
47. `assigned_to_id` = `null`로 `update_issue_category`는 기본 담당자를 지움.
48. 스키마는 0 및 24 이상의 `hours`를 수락; Redmine 검증만 거부.
49. 빈 `notes`로 `update_issue_note`는 기존 댓글의 텍스트를 지움.
50. `project`가 있는 `list_users`는 프로젝트에 그룹 멤버십이 있어도 사용자만 반환.
51. `view_wiki_edits` 없이 과거 위키 페이지 버전은 접근 불가; 보호된 페이지는 위키 보호 권한 없이 변경할 수 없음.
52. 감시자 추가 권한 없이 `copy_issue`는 감시자를 복사하지 않음; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no`는 링크 및 첨부 파일을 금지; 동일 프로젝트의 부모는 보존됨.
53. 읽기 전용 모드에서 Extension 쓰기 도구는 handler를 호출하지 않음.
54. `manage_files` 없이 이슈 첨부 파일을 삭제할 수 있는 사용자에게 `delete_file`이 `tools/list`에 보임.
55. `add_issue_watcher` / `remove_issue_watcher`는 그룹 principal을 수락.
56. `project`가 있는 `get_version`은 해당 프로젝트의 `list_versions`가 반환한 공유 버전을 반환.
57. `get_issue` / `get_wiki_page` / `get_board_message`는 `limit`/`offset`으로 중첩 목록을 제한하고 `*_pagination`을 반환; include 없이 pagination은 `null`.
58. nullable 필드를 포함한 실제 도구 응답은 게시된 `outputSchema`와 일치.
59. `include_journals`가 있는 `get_issue`: 숨겨진 사용자 정의 필드 상세만 있는 저널은 목록에 없고 `journal_pagination.total_count`에도 집계되지 않음.
60. 두 보이는 항목 사이의 숨겨진 저널은 페이지 간격을 만들지 않음: `journal_limit=2`일 때 두 보이는 항목이 반환되고 `total_count`는 보이는 수와 같음.
61. `view_private_notes` 권한 없이 `get_issue`는 다른 사용자의 비공개 댓글을 반환하지 않음.
62. `get_private_notes`는 전체 이슈 기록을 로드하지 않고 `limit`/`offset`으로 페이지를 반환.
63. 저널 `attr`, `cf`, `relation`이 동시에 있는 `get_issue`는 실패하지 않고 보이는 항목만 반환.
64. 숨겨진 사용자 정의 필드 상세와 공백, 탭 또는 줄 바꿈으로만 구성된 notes가 있는 저널은 `get_issue`에 포함되지 않음.
65. `get_private_notes`는 공백, 탭 또는 줄 바꿈만으로 구성된 댓글을 반환하지 않음.
