# MCP 服务器与 HTTP 端点

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](01-mcp-server.md)

## 概述

Redmine MCP 提供 HTTP 端点 `/mcp`，以 Streamable HTTP 模式实现 MCP（Model Context Protocol），请求之间不保持会话（无状态）。

## 目标

让外部 AI 客户端使用标准 MCP 协议与 Redmine 交互，无需单独的服务器进程。

## 涉及领域

- API
- 插件

## 业务规则

- 端点位于 Redmine 根路径下的 `/mcp`。
- 按 Streamable HTTP 规范支持 HTTP 方法 `GET`、`POST` 和 `DELETE`。
- 每个请求在当前已认证用户的上下文中处理。
- 每个请求根据用户权限构建最新的工具、资源和提示集合。
- 服务器公布名称为 `redmine_mcp`，版本与插件版本一致。
- MCP 协议修订版本为 `2025-11-25`（请求头 `MCP-Protocol-Version` 和 `initialize` 中的 `protocolVersion`）。
- 支持标准 MCP 方法：`initialize`、`tools/list`、`tools/call`、`resources/list`、`resources/read`、`prompts/list`、`prompts/get`，以及所支持协议版本提供的其他方法。
- 工具响应在 `structuredContent` 中返回 JSON 封装（`ok`、`data` 或 `error`），并在 `content` 中返回简短文本表示（成功时为 JSON 字符串，失败时为错误消息）。
- API 密钥仅从 `X-Redmine-API-Key` 请求头接受。JSON-RPC 请求体不用于认证，且在请求大小检查前不解析。
- 在 JSON 解析前限制 HTTP 请求体大小：超出限制时拒绝请求，MCP 传输层不读取请求体。

## 边界情况

- MCP 禁用时，端点返回 HTTP 503，不处理 MCP 请求。
- 在无状态模式下，不支持独立 SSE 流的 `GET` 请求（HTTP 405）——这是预期行为。
- 在负载均衡器后运行时，不需要粘性会话。
- 工具列表可能因用户权限不同而不同。

## 错误处理

- 无效的 JSON-RPC 请求 — MCP 协议错误响应。
- 内部请求处理错误 — HTTP 500 及错误消息。
- 工具执行错误 — 带有 `isError: true` 和文本描述的 MCP 响应。
- 进程内 REST（`InternalRequest`）：404 → `NOT_FOUND`；版本冲突 → `CONFLICT`；无冲突的 401/403 → `FORBIDDEN`；`errors` 数组 → `VALIDATION_ERROR`。封装中不包含内部请求的 HTTP 状态或原始异常消息。
- 无效的工具参数（缺少必填字段、类型错误、`additionalProperties: false` 时的额外属性、超出 min/max 范围）— 执行错误，`structuredContent` 中为 `VALIDATION_ERROR`。`content` 中的文本与 `error.message` 一致，不包含原始 JSON Schema 消息。

## 测试场景

1. 对 `initialize` 方法的 `POST /mcp` 返回 capabilities、`serverInfo` 和 `protocolVersion` `2025-11-25`。
2. 对 `tools/list` 方法的 `POST /mcp` 返回当前用户的工具列表。
3. 对 `tools/call` 方法的 `POST /mcp`（有效工具名）返回带有 `structuredContent` 的结果。
4. MCP 禁用时对 `/mcp` 的请求返回 HTTP 503。
5. 调用不存在的工具返回 "Tool not found" 错误。
6. 无工具权限的 `tools/call` 返回访问拒绝代码的执行错误；调用计入速率限制和结构化审计。
7. 超过限制的 HTTP 请求体在 JSON 解析前被拒绝。
8. 启用只读模式时，写入工具通过相同的 HTTP/`tools/call` 路径返回错误。
9. 对不可访问项目 URI 的 `resources/read` 不返回资源内容。
10. 带有不可访问项目参数的 `prompts/get` 拒绝访问。
11. 参数为空、包含额外字段或参数类型错误的 `tools/call` 返回 `isError: true` 和 `structuredContent.error.code` `VALIDATION_ERROR`。
