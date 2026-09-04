# 其他插件的扩展 API

[Deutsch](../de/04-extensions.md) | [English](../en/04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](04-extensions.md)

## 概述

Redmine MCP 提供扩展机制，让其他已安装的 Redmine 插件注册自己的工具、资源和提示，并扩展现有工具。

## 目标

为 Redmine 插件与 AI 的集成提供统一方式，无需复制 MCP 服务器，也无需修改 Redmine MCP 代码。

## 涉及领域

- 插件
- API
- 权限

## 业务规则

### 自动发现

- Redmine 启动时（MCP 已启用），系统检查所有已安装插件。
- 若找到以下任一来源，则插件视为具备 MCP 扩展：
  - **插件自身扩展** — 以下路径之一的 `mcp.rb` 文件：
    - `lib/<plugin.id>/mcp.rb`；
    - `lib/<插件目录 basename>/mcp.rb`；
    - 若标识符以 `redmine_` 开头，则为 `lib/<去掉 redmine_ 前缀的 plugin.id>/mcp.rb`（典型方案如 `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`）；
  - **`redmine_mcp` 内置集成** — 当目标插件已安装时，`redmine_mcp` 插件内的 `lib/redmine_mcp/extensions/<plugin.id>.rb` 文件。
- 若同一插件两种来源都存在，先加载插件自身的扩展。仅当 `require` 自身 `mcp.rb` 失败时，内置集成才作为 fallback 使用。`mcp.rb` 成功加载时，内置集成不会加载，也不会重复注册 tools/resources/prompts。
- 内置集成使用与第三方 `mcp.rb` 相同的 Extension API；没有单独的注册机制。
- `redmine_mcp` 插件不会将自身作为扩展加载。
- 设置中未勾选 MCP 扩展复选框的插件会被跳过。
- 某个插件扩展失败不会阻止加载其他插件，包括扩展文件中的语法错误。

### 工具注册

- 扩展插件可注册任意数量的工具。
- 每个工具包含：名称、描述、输入 schema、输出 schema、权限要求和处理程序。
- 完整工具名：`redmine_<plugin_id>_<name>`，例如 `redmine_redmine_advanced_checklists_get_issue_checklists`、`redmine_advanced_search_semantic_search_issues`。
- 禁止重复的工具名称。
- 仅对拥有相应权限的用户，工具才会出现在 MCP 中。
- 议题范围的扩展工具可能需要启用 Redmine 项目模块（模块标识符不必与插件 id 一致）。在 `tools/list` 中，若用户在至少一个启用该模块的可见项目中拥有声明的权限，此类工具可见。无模块要求时，在至少一个可见项目中拥有权限即可。调用时仍检查特定议题：可见性、其项目中的权限和已启用模块；否则响应为 "not found"。
- MCP 只读模式下，扩展写入工具不运行处理程序：拒绝方式与核心写入工具相同。

### 扩展现有工具

- 插件可扩展已注册的工具。
- 扩展可以：
  - 添加额外输入参数；
  - 在主处理程序之前运行代码；
  - 在主处理程序之后运行代码并修改结果。
- 多个插件可同时扩展同一工具。
- 额外参数合并到共享输入 schema 中。
- 额外参数名不得与核心工具参数或同一工具的其他扩展参数冲突。
- 发布到 `tools/list` 前，结果 schema 会规范化。
- 扩展执行顺序与插件加载顺序一致。

### 资源注册

- 插件可发布具有唯一 URI 的资源。重复注册同一 URI 会被拒绝。
- 资源必须有读取处理程序。
- 推荐的 URI 方案：`redmine://<plugin_id>/<type>/<id>`。
- 资源可能需要权限检查；无权限时资源不可用。
- 权限检查接收 URI 和参数。项目从 `project` / `project_id`、URI（查询中的 `project`/`project_id` 或 `/projects/:id` 段）或扩展定义的显式项目解析器获取。`resources/read` 向检查传递 `{uri: ...}`。
- 若调用中指定了项目但当前用户找不到或无法访问，则拒绝访问。"至少一个项目" 检查仅在不指定项目时适用（空参数发现）。
- 读取资源返回文本或 JSON 格式的内容。

### 提示注册

- 插件可添加具有名称、描述、参数和处理程序的提示。
- 完整提示名：`redmine_<plugin_id>_<name>`。
- 提示对拥有相应权限的用户可用。权限检查接收调用参数，包括 `project` / `project_id`。若指定了项目但找不到或无法访问，则拒绝访问；未指定项目时适用与资源相同的发现规则。

### 事件（钩子）

- 插件可订阅 MCP 生命周期事件，例如：
  - 工具注册；
  - 资源注册；
  - 提示注册；
  - 所有扩展加载完成。
- 事件处理程序中的错误会记录日志，不会中断主流程。

### 依赖

- 扩展插件不必声明对 Redmine MCP 的硬依赖。
- 建议在注册前检查 `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?`。
- 扩展插件无需包含 MCP gem — Redmine MCP API 已足够。

### Extension API 能力

通过 Extension API，扩展插件可以：

- 验证 MCP 已启用且扩展未被禁用；
- 注册工具一次（重载时不重复）；
- 注册议题范围工具，带标准权限检查和议题查找；若处理程序运行前议题已消失，响应为 "not found"，而非内部错误；
- 用参数和 before/after 处理程序扩展现有核心工具；
- 为 `redmine_get_mcp_info` 注册能力模式（例如 `issue_search.semantic`）；
- 通过 `internal_request` 以当前用户身份在进程内调用 Redmine 或插件 REST API（`GET`、`POST`、`PUT`、`PATCH`、`DELETE`；目标端点必须接受 API 认证）；REST 错误映射为规范 MCP 代码，不含内部请求 HTTP 状态；
- 以 `{ ok, data | error }` 封装格式发布 `outputSchema`。

Ruby API 方法列表和代码示例在插件 README 和 [mcp_tool_development.md](mcp_tool_development.md)（开发指南，非行为 SPEC）中。

## 边界情况

- 无扩展文件且无内置集成的插件会被忽略。
- 若扩展文件存在但 `require` 失败 — 记录日志，扩展视为未加载；工具注册是成功 `require` 的副作用。
- 尝试扩展不存在的工具 — 扩展注册期间出错。
- 设置中未勾选 MCP 扩展复选框的插件即使扩展文件存在也不会加载。
- 安装新扩展后需要 Redmine 重启；MCP 客户端可能需要重新连接。

## 错误处理

- 扩展文件加载错误 — 记录日志，继续加载其他插件。
- 启动时工具注册错误 — 记录日志。
- 扩展 `before` 处理程序中的错误 — 中止工具执行。
- `after` 处理程序中的错误 — 记录日志；除非处理程序改变了控制流，否则保留主处理程序结果。

## 测试场景

8. 空参数时，若在至少一个项目中拥有权限，资源和提示发现仍可用。
9. `plugin.id` 形如 `redmine_*` 且文件为 `lib/<去掉 redmine_ 前缀的 id>/mcp.rb` 的插件视为具备 MCP 集成，并出现在 MCP 扩展设置中。
10. 需要模块的议题范围工具：用户在其他项目有权限但没有任何启用该模块的可见项目时，不在 `tools/list` 中。
11. 没有自身 `mcp.rb`、但目标插件已安装且 `redmine_mcp` 中存在 `lib/redmine_mcp/extensions/<plugin.id>.rb` 文件的插件，视为具备 MCP 集成并出现在 MCP 扩展设置中。
12. 若插件同时有自身 `mcp.rb` 和 `redmine_mcp` 中的内置集成，在 `mcp.rb` 成功加载时 MCP 中可用其 tools/resources/prompts；若 `require` `mcp.rb` 失败，加载器会尝试内置集成。

## 扩展示例

| 插件 | 工具 | 用途 |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | 语义议题搜索 |
