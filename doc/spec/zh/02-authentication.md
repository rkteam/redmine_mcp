# 认证与授权

[Deutsch](../de/02-authentication.md) | [English](../en/02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](02-authentication.md)

## 概述

MCP 访问使用标准 Redmine API 密钥认证。所有操作以密钥所属用户身份执行。

## 目标

确保 MCP 不绕过 Redmine 安全机制，用户只能执行被允许的操作。

## 涉及领域

- 权限
- API
- 用户

## 业务规则

### 认证

- 访问 `/mcp` 必须启用 Redmine REST API。
- API 密钥通过 `X-Redmine-API-Key` 请求头传递（不从 JSON 请求体或查询字符串获取）。
- 仅接受活跃用户的密钥。
- 无密钥或密钥无效的请求会被拒绝。

### 全局 MCP 权限

- 用户必须拥有全局 **Use MCP** 权限（`use_mcp`），或为 Redmine 管理员。
- `use_mcp` 权限在 **管理 → 角色和权限** 中为所需角色手动启用。
- 管理员始终拥有 MCP 访问权限：标准 Redmine 全局权限检查允许管理员无视角色。
- 其他没有 `use_mcp` 的用户即使 API 密钥有效也会被拒绝。

### 工具权限

- 每个工具有各自的 Redmine 权限要求。
- 仅当用户有权限使用时，工具才会出现在 `tools/list` 中。
- 调用工具时会再次检查权限。
- 数据按 Redmine 可见性规则过滤（项目、议题、成员）。

### 资源与提示权限

- 资源和提示可能有各自的权限要求。
- 无权限时，资源或提示不会列出且无法读取。
- 资源和提示的权限检查考虑 URI 和输入参数（包括 `project` / `project_id`）。若参数中未指定项目，在至少一个可见项目中拥有权限即可。
- 扩展可定义从 URI 和参数解析项目的显式规则。

## 边界情况

- 非活跃用户即使持有先前签发的密钥也无法使用 MCP。
- 管理员无需单独分配 `use_mcp` 即可访问 MCP。
- 具有实体范围权限检查的工具（例如议题）在用户至少在某个项目中拥有相应权限时，可能在 `tools/list` 中可见（参数为空）。
- 若此类工具还需要 Redmine 项目模块，"至少一个项目"指用户拥有权限且指定模块已启用的可见项目。无模块要求时，在至少一个可见项目中拥有权限即可。出现在 `tools/list` 中并不意味着对特定议题有权限：调用时会再次检查权限和对象可用性。

## 错误处理

| 情况 | 结果 |
|----------|-----------|
| REST API 已禁用 | HTTP 401 |
| API 密钥无效或缺失 | HTTP 401 |
| 无 Use MCP 权限 | HTTP 403 |
| 无特定工具权限 | 工具不在 `tools/list` 中；直接调用 — "Permission denied" 错误 |
| 用户无法访问的实体 | 工具响应带错误描述（例如 "Issue not found"） |

## 测试场景

1. 有效密钥且拥有 Use MCP 权限的请求 — 成功访问。
2. 无 API 密钥请求头的请求 — HTTP 401。
3. 非管理员密钥且无 Use MCP 权限的请求 — HTTP 403。
4. 管理员密钥但角色无 `use_mcp` — 成功访问。
5. 用户在 `tools/list` 中仅看到其有权限的工具。
6. 对不可访问议题调用工具返回错误，而非其他用户的数据。
7. 需要项目模块的议题范围工具：用户有权限但无启用该模块的可见项目时，不在 `tools/list` 中；存在此类项目时可见。
