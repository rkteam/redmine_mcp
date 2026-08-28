# Redmine MCP — 通用规范

[Deutsch](../de/00-general.md) | [English](../en/00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](00-general.md)

## 概述

Redmine MCP 插件在 Redmine 安装实例内提供 MCP 服务器（Model Context Protocol）。AI 客户端连接到单一 HTTP 端点，通过工具（tools）、资源（resources）和提示（prompts）访问 Redmine 数据。

插件包含用于处理项目、议题和用户的基础工具集。其他已安装的 Redmine 插件可在不修改 Redmine MCP 代码的情况下扩展 MCP。

## 目标

提供 Redmine 与 AI 系统之间的单一集成机制，其中：

- 用户在自身 Redmine 权限范围内操作；
- 插件开发者可添加自己的 MCP 能力；
- 无需单独的 MCP 服务器或针对特定安装的分支版本。

## 主要场景

1. **连接 AI 客户端** — 管理员启用 MCP，为所需角色授予 `use_mcp` 权限并签发 API 密钥；用户将客户端（Cursor 等）连接到 `/mcp` 端点。
2. **使用 Redmine 数据** — 客户端调用工具获取项目、议题和用户。
3. **其他插件扩展** — 安装带有 MCP 扩展的插件后，其工具自动出现在共享列表中。
4. **管理** — 启用/禁用 MCP，以及为单个插件启用 MCP 集成。

## 涉及领域

- API（基于 HTTP 的 MCP）
- 权限
- 设置
- 议题
- 项目
- 用户
- 论坛
- 插件（扩展）

## 业务规则

- 仅在插件设置中显式启用时，MCP 才可用。
- 所有操作以已认证的 Redmine 用户身份执行。
- 通过 MCP 的写入操作经过 Redmine 模型：会触发模型回调。控制器钩子（`controller_issues_*_save`、`controller_journals_edit_post` 等）不会被 MCP 调用。
- 数据可见性遵循 Redmine 规则：用户不会获得超出 Web UI 可见范围的数据。
- 工具和提示名称格式为 `<plugin_id>_<name>`，例如 `redmine_list_projects`。
- 核心工具的 `title` 和 `description` 以英文发布，供 LLM 选择，**不**通过 `en.yml`/`ru.yml` 本地化（MCP 工具目录的 i18n 标准例外）。错误消息和设置 UI 会本地化。
- 其他插件的扩展不会形成硬依赖：若 Redmine MCP 不存在，第三方插件仍可正常工作。

## 边界情况

- MCP 禁用时，所有对 `/mcp` 的请求都会被拒绝。
- 某个扩展失败时，其他扩展和核心工具仍可工作。
- 扩展的新工具在 Redmine 重启后可用；MCP 客户端可能需要重新连接以刷新工具列表。
- 在无状态模式下，每个 HTTP 请求独立处理；请求之间不保留会话。

## 错误处理

- 认证和授权错误在 HTTP 层返回。
- 工具执行错误以 MCP 格式返回，并带有错误标志。
- 扩展加载错误会记录日志，不会阻止 Redmine 启动。

## 规范文件

| 文件 | 内容 |
|------|---------|
| [console-commands.md](console-commands.md) | 安装、验证和维护命令 |
| [01-mcp-server.md](01-mcp-server.md) | HTTP 端点、MCP 协议、传输 |
| [02-authentication.md](02-authentication.md) | 认证与访问控制 |
| [03-core-tools.md](03-core-tools.md) | 内置 Redmine 工具 |
| [04-extensions.md](04-extensions.md) | 其他插件的扩展 API |
| [05-settings.md](05-settings.md) | 插件设置与日志 |
| [mcp_tool_development.md](mcp_tool_development.md) | MCP 工具开发要求（开发指南） |
| [extension_guide.md](extension_guide.md) | 扩展开发者指南 |

## 测试场景

1. 安装并启用 MCP 后，客户端成功执行 `initialize` 并收到服务器信息。
2. 拥有 Use MCP 权限且 API 密钥有效的用户可看到对其可用的工具列表。
3. 没有 Use MCP 权限的用户无法访问 `/mcp`。
4. 安装扩展插件后，拥有相应权限的用户在 `tools/list` 中可看到其工具。
