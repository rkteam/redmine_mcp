# Redmine MCP

[网站](https://redmine-kanban.com/)

[Deutsch](../de/README.md) | [English](../../../README.md) | [Español](../es/README.md) | [Français](../fr/README.md) | [Italiano](../it/README.md) | [日本語](../ja/README.md) | [한국어](../ko/README.md) | [Polski](../pl/README.md) | [Português (Brasil)](../pt-BR/README.md) | [Русский](../ru/README.md) | 中文

Redmine 内的 MCP 服务器（Model Context Protocol）。让 AI 客户端通过标准 Redmine 权限处理议题、项目和用户。其他插件可在不修改本插件的情况下添加自己的 tools、resources、prompts 和 capabilities。对于无法修改的第三方插件，`redmine_mcp` 可在 `lib/redmine_mcp/extensions/` 中提供内置 MCP 集成。

## 要求

| 组件 | 版本 |
|---|---|
| Redmine | Redmine 6.0–7.0 |
| MCP protocol | 2025-11-25 |
| Ruby MCP SDK (`mcp`) | 0.23.x |

本插件使用 MCP protocol `2025-11-25` 和 Ruby MCP SDK `0.23.x`。
目前尚未声明对更新 MCP protocol 和 SDK 版本的支持。

- Redmine 中已启用 REST API
- gem `mcp` 在 `plugins/redmine_mcp/Gemfile` 中声明，并通过 `bundle install` 安装

## 安装与配置

### 1. 安装插件

将 git 仓库克隆到 Redmine 的 `plugins` 目录：

```bash
cd /path/to/redmine/plugins
git clone https://github.com/rkteam/redmine_mcp.git
```

在 Redmine 根目录安装依赖并重启应用：

```bash
cd /path/to/redmine
bundle install
```

重启 Redmine。

### 2. 在管理界面启用

**管理 → 插件 → Redmine MCP → 配置**

| 设置 | 描述 |
|---------|-------------|
| 启用 MCP | 启用 `/mcp` 端点。启用时会加载已安装插件的 MCP 扩展 |
| 只读模式 | 阻止 write 工具和 write 操作（create/update/delete 等） |
| MCP 扩展 | 用于启用已安装插件 MCP 集成的复选框 |

### 3. REST API

**管理 → 设置 → API** — 启用「启用 REST Web 服务」。

### 4. 权限

**管理 → 角色和权限** — 为所需角色手动启用全局权限 **使用 MCP**（`use_mcp`）。Redmine 管理员始终拥有 MCP 访问权限。

### 5. 用户 API 密钥

每位通过 MCP 工作的用户都必须拥有 API 密钥：

**我的账户 → API 访问密钥**（或通过用户 REST API）。

在请求头中传递密钥：

```
X-Redmine-API-Key: <your_key>
```

## 连接 MCP 客户端

服务器使用 **Streamable HTTP**（stateless）。端点：

```
https://<your-redmine>/mcp
```

支持的方法：`GET`、`POST`、`DELETE`。

### Cursor 示例

在 MCP 设置（`.cursor/mcp.json` 或全局配置）中添加使用 HTTP 传输的服务器。具体格式取决于客户端版本；典型示例：

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

连接后，客户端将调用 `initialize`，然后可以调用 `tools/list`、`tools/call`、`resources/list`、`prompts/list` 等。

### 手动验证

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

成功响应包含 `serverInfo.name: "redmine_mcp"`。

### Host 与 reverse proxy

MCP transport 会验证 HTTP `Host` 和 `Origin`，以防止 DNS rebinding。

允许的主机来自 Redmine 设置：

**管理 → 设置 → 常规 → 主机名称**

该值必须与 Redmine 的公开 URL 一致。

例如，若 Redmine 可通过以下地址访问：

```
https://redmine.example.com
```

设置中应使用：

```
redmine.example.com
```

若 Redmine 运行在 reverse proxy 之后，代理必须转发客户端原始的 `Host` 请求头。

若主机不匹配，MCP 端点可能返回 HTTP `403 Forbidden`。

没有 `Origin` 请求头的客户端不受 Origin 检查影响。

## 内置工具（core tools）

完整名称格式为 `redmine_<tool_name>`（例如 `redmine_get_issue`）。

服务器提供用于项目、议题、用户、工时记录、Wiki、论坛和文件的工具。下列为内置 tools 的简要概览。完整输入 schema 和 descriptions 可通过 `tools/list` 供 MCP 客户端使用。

### 通用参数

- `project` — 项目字符串 ID 或 identifier。
- `assignee_ref` / `user_ref` 值为 `me` — 当前用户。
- `assigned_to_id` — 被分配议题的用户或组；`null` 清除可选字段。
- `create_time_entry` 需要 `project` 或 `issue_id`。
- `upload_file` 需要 `filename` 和 `content_base64`。

### 操作可靠性

- `expected_updated_at` — 用于敏感的 update/delete 操作。
- `idempotency_key` — 用于 `create_issue`、`copy_issue`、`update_issue`、`add_issue_note`、`create_time_entry`、`import_time_entries`、`upload_file`。

### 限制

- 读取 timeout 60 秒；
- 每用户 120 请求/分钟；
- MCP 请求 HTTP 正文最大 36 MiB；
- tool JSON args 最大 32 MiB；
- base64 附件最大 20 MiB；
- 附件下载最大 10 MiB。

### 生产部署

速率限制和 idempotency 使用 `Rails.cache`。

对于具有多个应用 worker 或多个 Redmine 实例的安装，应使用共享 cache store。

使用进程本地 cache 时，速率限制和 idempotency 保证仅在单个应用进程内有效。

### 项目管理

| 工具 | 描述 |
|------|-------------|
| `list_projects` | 项目列表 |
| `get_project` | 项目详情 |
| `list_project_issue_custom_fields` | 项目议题自定义字段 |
| `summarize_project_status` | 服务器构建的 N 天项目指标摘要 |
| `list_project_activities` | 项目活动 feed（事件，非工时 activity 类型） |
| `list_versions` | 路线图版本（里程碑） |
| `get_version` | 路线图版本详情（含聚合） |
| `create_version` | 创建版本 |
| `update_version` | 更新版本 |
| `delete_version` | 删除版本 |
| `list_project_members` | 项目成员及其角色 |
| `list_project_member_candidates` | 可添加到项目的用户和组 |
| `list_roles` | 项目中可管理的角色 |
| `get_project_modules` | 已启用的项目模块 |
| `add_project_member` | 添加成员 |
| `update_project_member` | 更改成员角色 |
| `remove_project_member` | 移除成员 |

### 议题

| 工具 | 描述 |
|------|-------------|
| `get_issue` | 议题详情（日志、附件、自定义字段等） |
| `list_issues` | 带筛选和分页的议题列表 |
| `search_issues` | 议题文本搜索 |
| `run_issue_query` | 运行已保存的议题查询 |
| `get_issue_form_options` | 允许的议题表单字段值（单次调用） |
| `validate_issue_create` | 不写入的情况下验证创建议题参数 |
| `validate_issue_update` | 不写入的情况下验证更新议题参数 |
| `create_issue` | 创建议题 |
| `update_issue` | 更新议题属性和附件 |
| `add_issue_note` | 为议题添加评论（可选附件） |
| `delete_issue` | 带确认的删除议题 |
| `copy_issue` | 复制议题 |
| `list_issue_relations` | 议题关联列表 |
| `create_issue_relation` | 创建议题间关联 |
| `delete_issue_relation` | 删除议题关联 |
| `list_subtasks` | 子任务 |
| `add_issue_watcher` | 添加关注者 |
| `remove_issue_watcher` | 移除关注者 |
| `update_issue_note` | 编辑日志条目 |
| `set_issue_note_private` | 更改日志条目隐私 |
| `get_private_notes` | 仅私有评论 |
| `list_issue_categories` | 项目议题类别 |
| `create_issue_category` | 创建类别 |
| `update_issue_category` | 更新类别 |
| `delete_issue_category` | 删除类别 |

### 用户

| 工具 | 描述 |
|------|-------------|
| `list_users` | 项目成员；筛选 `query`（姓名/login）和 `login`；全局搜索仅管理员 |
| `list_groups` | 用于 `add_project_member` 中 `group_id` 的 Givable 组 |

### 工时记录

| 工具 | 描述 |
|------|-------------|
| `list_time_entries` | 工时记录列表 |
| `create_time_entry` | 创建工时记录 |
| `update_time_entry` | 更新工时记录 |
| `list_time_entry_activities` | 工时 activity 类型（非项目事件 feed） |
| `import_time_entries` | 批量导入工时记录 |

### 参考数据

| 工具 | 描述 |
|------|-------------|
| `list_trackers` | 所有跟踪器 |
| `list_project_trackers` | 项目跟踪器 |
| `list_issue_statuses` | 议题状态 |
| `list_issue_priorities` | 议题优先级 |
| `admin_list_users` | 带筛选的用户（仅管理员） |
| `get_current_user` | 当前用户 |
| `list_queries` | 已保存查询（元数据；执行为 `run_issue_query`） |

### 搜索与 Wiki

| 工具 | 描述 |
|------|-------------|
| `search_all` | 搜索议题和 Wiki 页面 |
| `list_wiki_pages` | 项目 Wiki 页面 |
| `get_wiki_page` | 获取 Wiki 页面 |
| `create_wiki_page` | 创建 Wiki 页面 |
| `update_wiki_page` | 更新 Wiki 页面 |
| `delete_wiki_page` | 删除 Wiki 页面 |
| `rename_wiki_page` | 重命名 Wiki 页面 |

### 论坛

| 工具 | 描述 |
|------|-------------|
| `list_boards` | 项目论坛板块 |
| `list_board_topics` | 所选板块的主题 |
| `get_board_message` | 含简要回复的论坛消息 |

### 文件

| 工具 | 描述 |
|------|-------------|
| `list_project_files` | 项目文件 |
| `upload_file` | 上传文件 |
| `delete_attachment` | 删除附件 |
| `get_attachment` | 附件元数据和 `content_url` |
| `download_attachment` | 附件内容（`content_base64`，最大 10 MiB） |

### 实用工具

| 工具 | 描述 |
|------|-------------|
| `get_mcp_info` | MCP 插件版本、read-only 模式、当前用户和可用 capabilities |

### 访问与响应

Tools 在 `structuredContent` 中返回 JSON envelope，在 `content` 中返回文本表示。

Write 操作被 **只读模式** 设置阻止。

除工具特定权限外，始终检查全局权限 **使用 MCP**。

数据访问通过标准 Redmine 权限和可见性规则强制执行。对于项目和议题数据，使用 `Project.visible` 和 `Issue.visible`。

## 其他插件的扩展

任何已安装的 Redmine 插件都可以添加自己的 MCP tools，并在需要时注册 resources、prompts 和 capabilities。

对于无法修改的插件，内置集成位于 `redmine_mcp/lib/redmine_mcp/extensions/`，并通过相同的 Extension API 注册。

详细指南：[extension_guide.md](extension_guide.md)。

在 Cursor 或类似 agent 中进行 AI 辅助开发时，将捆绑的 skill 目录 [`redmine-mcp-plugin-integration`](../../skills/redmine-mcp-plugin-integration/) 复制到 agent 的 skills 文件夹，或将其作为自定义 skill 的基础。

启动 skill 时，可在 prompt 中指定通过目标插件（`mcp.rb`）还是 `redmine_mcp` 内置集成（`lib/redmine_mcp/extensions/`）进行集成。如未指定，agent 将自行选择路径。

## 日志

消息写入标准 Rails 日志，前缀为 `[redmine_mcp]`：

- 扩展加载
- tool/resource/prompt 注册
- 注册与执行错误
- 访问拒绝

## 故障排除

| 症状 | 可能原因 |
|---------|-------------------|
| HTTP 503 «MCP is disabled» | 插件设置中未启用 MCP |
| HTTP 401 | API 密钥缺失或无效；REST API 已禁用 |
| HTTP 403（权限） | 用户没有 **使用 MCP** 权限 |
| HTTP 403（`Host`/`Origin`） | **主机名称** 与 Redmine 公开 URL 不一致；reverse proxy 未转发原始 `Host`；客户端中的 MCP URL 不匹配 — transport 拒绝未知 host（DNS rebinding 防护） |
| `tools/list` 中看不到 tool | 缺少所需权限；提供该 tool 的扩展已禁用 |
| MCP reload 后新 tools 未出现 | 在 Cursor 及类似客户端中，reload 服务器可能不会刷新 tool 列表 — 请完全重启应用 |
| 扩展未加载 | 缺少 `lib/.../mcp.rb` 或 `lib/redmine_mcp/extensions/<plugin.id>.rb`；module 未 `extend RedmineMcp::ExtensionApi`；确认 **MCP 扩展** 中已启用扩展复选框；若文件有错误，请查看日志 |
| `Issue not found` / `Project not found` | 根据 Redmine 可见性规则，议题或项目对当前用户不可见 |

## 许可证

本插件依据 GNU General Public License
第 2 版或任何更高版本授权。

详见 [LICENSE](../../../LICENSE)。
