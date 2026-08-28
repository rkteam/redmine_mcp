# 설치, 검증 및 유지보수 명령

[Deutsch](../de/console-commands.md) | [English](../en/console-commands.md) | [Español](../es/console-commands.md) | [Français](../fr/console-commands.md) | [Italiano](../it/console-commands.md) | [日本語](../ja/console-commands.md) | [한국어](console-commands.md) | [Polski](../pl/console-commands.md) | [Português (Brasil)](../pt-BR/console-commands.md) | [Русский](../ru/console-commands.md) | [中文](../zh/console-commands.md)

## 설치

```bash
bundle install
```

의존성 설치 후 Redmine을 재시작합니다.

## 엔드포인트 검증

MCP 초기화 확인:

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
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

예상 결과: HTTP 200, 응답의 `serverInfo.name`이 `redmine_mcp`와 같음.

## 도구 목록 확인

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## 도구 호출 확인

```bash
curl -s -X POST 'http://localhost:3000/mcp' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2025-11-25' \
  -H 'X-Redmine-API-Key: YOUR_API_KEY' \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "redmine_list_projects",
      "arguments": { "limit": 5 }
    }
  }'
```

## 로그 보기

플러그인 메시지는 `[redmine_mcp]` 접두사와 함께 표준 Rails 로그에 기록됩니다.

```bash
tail -f log/production.log | grep redmine_mcp
```

## 유지보수

- 플러그인 설정 변경 또는 새 확장 설치 후 — Redmine 재시작.
- 새 MCP 도구 추가 후 — MCP 클라이언트 재연결(Cursor 재시작 또는 MCP 설정에서 서버 제거/추가).
