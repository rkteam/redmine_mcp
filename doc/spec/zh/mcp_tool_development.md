# Redmine MCP 工具开发要求

[Deutsch](../de/mcp_tool_development.md) | [English](../en/mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](mcp_tool_development.md)

**状态：** 开发者指南（dev-guide），非插件行为 SPEC  
**版本：** 1.6  
**日期：** 2026-08-20  
**适用范围：** 所有新的 Redmine MCP 工具及对现有工具的重大变更  
**基础 MCP 版本：** Protocol Revision `2025-11-25`

核心工具的行为契约见 `03-core-tools.md` 及相关 SPEC。本文档定义工具设计与实现的规则。

---

## 1. 本文档的目的

本文档为 Redmine 的 MCP 工具建立统一的设计、实现、描述、测试与发布要求。架构实现模式汇总于附录 A，不与正文中的强制性要求混写。

本标准的目标是使工具：

- 便于语言模型明确选择；
- 自动调用时安全；
- 对 MCP 客户端可预测；
- 严格校验；
- 易于维护且向后兼容；
- 能抵御重复调用、模型错误和部分填写的参数。

要求的制定考虑了当前 Redmine MCP 的审计结果。在本文档编写时，服务器发布 46 个工具；契约中存在缺少 `type` 的参数、用字符串列表代替 `enum` 的允许值、通用的 `manage_*` 工具，以及缺失的 `outputSchema`。

---

## 2. 义务术语

本文档使用以下级别：

- **MUST / 必须** — 强制性要求。违反将阻止合并。
- **MUST NOT / 禁止** — 强制性禁止。
- **SHOULD / 应当** — 默认要求；偏离必须在合并请求中说明理由。
- **MAY / 可以** — 可接受的选项。

并非每个工具都强制采用的架构与实现模式汇总于**附录 A**。若针对特定工具有意识地不采用，不会阻止合并。

---

## 3. 核心设计原则

### 3.1. 一个工具 — 一个明确动作

工具 MUST 表示一个原子化的用户意图。

良好示例：

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

不良示例：

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

若操作具有以下特征，则 FORBIDDEN 使用 `action: create | update | delete | list` 这类参数的工具：

- 需要不同的必填参数；
- 具有不同的风险级别；
- 应有不同的 MCP 注解；
- 返回不同的数据结构；
- 需要不同的 Redmine 权限。

仅当语义上同质的操作且所有变体具有相同风险和单一契约时，才允许例外。例外必须明确说明理由。

### 3.2. 读、增、改、删相互分离

在一个工具中 FORBIDDEN 合并：

- 只读与写操作；
- 添加与删除操作；
- 普通用户与管理员操作；
- 本地 Redmine 操作与向外部发送数据。

例如，`list/create/delete relation` 必须是三个独立工具。

### 3.3. 契约优先于服务器实现便利

不要仅因这样实现处理程序更方便，就直接发布内部 Ruby/Python/REST 方法的结构。

MCP 契约为模型和客户端而设计；服务器内部适配器将其转换为 Redmine API 格式。

若插件或 Redmine 的内部技术值不属于有意义的外部契约的一部分，则 MUST 进行规范化。

非必要不发布：

- Ruby/Rails 类名和 STI 类型；
- 若 MCP 输入已使用不同值，则内部 enum 名称；
- 依赖 locale 的日期；
- 若 MCP 已定义规范格式，则同一字段的 REST 特定表示；
- MCP 已使用规范化值时的技术名称。

示例：输入过滤器 `type` — `contact` / `company`；响应中也应为 `contact` / `company`，而非 `Clientdesk::Contact` / `Clientdesk::Company`。若序列化器返回 STI 类或本地化日期，MCP 适配器 MUST 将值转换为已发布的 schema。

### 3.4. 服务器不信任模型

所有参数均视为不可信。服务器 MUST 重新检查：

- 类型；
- 范围；
- 字段相互依赖；
- 当前用户的权限；
- 对象是否属于某项目；
- 值在特定 workflow 中是否可用；
- Redmine 约束；
- 当前对象状态下是否允许该操作。

JSON Schema、description、annotations 和客户端确认不能替代服务端校验。

---

## 4. 工具命名

### 4.1. 名称格式

所有已发布工具名称 MUST 以 `redmine_` 开头。

对于 `redmine_mcp` 插件的核心工具，使用短前缀 `redmine_`：

```text
redmine_<verb>_<entity>
```

对于第三方插件的工具，完整名称 MUST 以 `redmine_` 开头：

- `redmine_<plugin_id>_<verb>_<entity>`。

要求：

- 仅 `lower_snake_case`；
- 所有工具（含第三方插件扩展）必须带 `redmine_` 前缀；
- 名称在服务器内唯一；
- 内部限制 — 不超过 64 个字符；
- 名称变更须遵循弃用流程。

示例：

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. 允许的动词

首选动词：

| 动词 | 用途 |
|---|---|
| `get` | 按精确标识符检索单个对象 |
| `list` | 按结构化过滤器检索集合 |
| `search` | 执行文本或全文搜索 |
| `create` | 创建对象 |
| `update` | 修改现有对象 |
| `set` | 将特定字段或标志设为给定值 |
| `delete` | 删除对象 |
| `add` | 向现有对象添加关联或成员 |
| `remove` | 移除关联而不删除主对象 |
| `copy` | 创建副本 |
| `upload` | 上传文件 |
| `download` | 获取文件内容 |
| `send` | 向外部接收方发送消息或数据 |
| `summarize` | 构建服务端聚合报告 |

不要使用模糊动词（`manage`、`process`、`handle`、`execute`、`do`）— 见 §3.1。

动词 MUST 与操作的真实语义一致。若工具切换布尔标志（如 `enabled: true | false` 参数），SHOULD 使用 `set` 命名，而非暗示单一值的动词。

不良示例：

```text
redmine_advanced_search_enable_semantic_index
```

`enable` 仅暗示 `enabled = true`，尽管参数也允许 `false`。名称与实际动作不符。

良好示例：

```text
redmine_advanced_search_set_semantic_index_enabled
```

名称 `set_*` 如实反映操作将标志设为传入值。

### 4.3. 标识符参数名称

参数名称 MUST 与其真实类型一致：

- `issue_id` — 仅整数 ID；
- `project_id` — 仅整数 ID；
- `project_identifier` — Redmine 字符串标识符；
- `project` — 有意允许两种表示形式并文档化为引用的字符串。

名为 `*_id` 的参数不能接受字符串标识符或值 `"me"`。

数值 ID MUST 有 `minimum: 1` 和有意义的 `description`。没有 `minimum` 的 `"Issue id"` 这类表述 FORBIDDEN。

不良示例：

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

良好示例：

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

项目的推荐统一选项是参数 `project`，接受数值 ID（字符串形式）或字符串标识符：

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

`examples` 数组（§6.15）向模型展示两种允许的值形式，并降低错误输入的概率。

### 4.4. 乐观锁：`expected_updated_at`

传递先前已知对象时间戳以拒绝过期变更的参数，在所有核心工具和扩展中 MUST 命名为 `expected_updated_at`。

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

此含义下使用 `updated_at` FORBIDDEN：它看起来像「新的修改时间」，但实际是乐观锁的值。

不良示例（checklist 及任何扩展）：

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

良好示例：

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

报告对象实际修改时间的响应字段 MAY 仍命名为 `updated_at` / `updated_on` — 混淆仅出现在锁定输入参数上。

冲突时的规范性行为见附录 A.2。

---

## 5. `title` 与 `description`

### 5.1. `title`（标题）

`title` MUST 是简短的人类可读名称，而非技术名称的复制。

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. 工具描述

`description` MUST 简要回答以下关键问题：

1. 工具做什么？读取或修改哪个对象？
2. 默认不包含什么？如何请求？
3. 是否有重大副作用？
4. 若 ID 或允许值未知，应调用哪个前置工具？

Description MUST 简短易读。FORBIDDEN 将其变成罗列所有字段和所有 include 选项的长段落：过载的 description 比简短结构化描述更难被模型阅读。

SHOULD 写若干短行或列表，而非连续文本。默认值及如何更改应紧凑展示。

良好示例：

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

不良示例 — 过短，未说明结果和默认行为：

```text
Gets issue.
```

不良示例 — 过载，罗列所有字段的长段落：

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. 对其他工具的引用

当 description、参数 description 或服务器 instructions 引用其他工具时，MUST 使用 `tools/list` 中的完整注册名称，而非无前缀的短 `name`。

不良示例：

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

良好示例：

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

短名称在插件间有歧义，迫使模型猜测前缀。这对扩展尤为重要：没有 `redmine_advanced_search_` 前缀的 `semantic_search_issues` 易与不存在的核心工具混淆。

### 5.2.2. 返回结果的描述

Description MUST 简要说明工具结果，使模型了解一次调用是否足够或是否需要下一个工具。

结果描述应说明：

- 返回的是单个对象、集合、聚合、变更确认还是资源引用；
- 默认包含哪些相关数据；
- 哪些大型或敏感数据在没有显式参数时不包含；
- 是否存在分页及标准 limit；
- 写工具返回完整更新对象还是仅 identifier、URL 和修改时间；
- 批量操作是否可能部分成功。

读取示例：

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

列表示例：

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

写入示例：

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

description 与 `outputSchema` 的关系 — 见 §7.1 和 §7.1.1。若列表已返回某字段，description MUST NOT 仅因该字段将模型导向 `get_*`。

### 5.3. 描述不能替代 schema

FORBIDDEN 仅在文本中设置约束：

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

使用 `enum`、`const`、范围和条件 schema。

互斥字段同样适用。若 `description` 说「`user_id` 或 `group_id` 恰好其一」，但 `required` 仅含公共字段 — schema 与文本不一致。约束 MUST 在 `inputSchema` 中形式化（§6.12）。

### 5.4. 可预测的选择

相似工具的 description 必须明确说明差异。

例如：

- `redmine_list_project_members` — 特定项目的成员及其角色；
- `redmine_admin_list_users` — 安装实例用户的全局列表，需要管理员权限。

### 5.5. 服务器级 instructions

服务器 MAY 发布简要通用 instructions，说明工具间关系和 workflow 规则。

Instructions 应补充各 description 中未有的上下文，并以完整名称引用工具（§5.2.1），例如：

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

FORBIDDEN：

- 在服务器 instructions 中重复所有工具的 description；
- 放置与服务器无关的通用模型行为 instructions；
- 写长指南而非简短路由规则；
- 使用营销语句；
- 用无前缀短名称引用工具（`list_projects` 而非 `redmine_list_projects`）。

### 5.6. 开发前研究 Redmine REST API

创建或重大变更工具前，开发者 SHOULD 进行文档研究。不建议仅依据现有 MCP 代码、开发者记忆或单个 HTTP 请求示例设计契约。

SHOULD 研究：

1. Redmine REST API 主页：通用认证、分页、`include`、自定义字段、文件和校验错误规则。
2. 对应资源的独立 API 页面，如 Issues、Time Entries、Versions、Wiki Pages 或 Project Memberships。
3. API 变更历史及各受支持 Redmine 版本的变更。
4. MCP 使用的实际 Redmine 版本和最低支持版本。
5. 若工具处理插件实体或字段，研究所用 Redmine 插件的 REST API 和源代码。发布扩展工具前，MUST 验证源 serializer / service / REST 端点，以及每种结果形式（若同时发布 list 和 get）至少一次真实成功响应。
6. 目标安装实例的实际权限、workflow、已启用模块、tracker、自定义字段和约束。
7. 已发布的 MCP 工具，以避免创建重复或冲突的契约。

主页 `https://www.redmine.org/projects/redmine/wiki/rest_api` 是入口，但对特定工具通常不够。SHOULD 前往对应资源页面，核实操作、查询参数、`include`、请求字段、响应结构、错误码和版本约束。

### 5.7. API 覆盖报告

实现新工具前，开发者 SHOULD 在合并请求中附上简要 API 覆盖表：

| 字段 | 内容 |
|---|---|
| Redmine resource | 资源及官方 API 页面链接 |
| Endpoint | HTTP 方法和路径 |
| Supported since | 最低 Redmine 版本 |
| Request parameters | 所有已文档化的请求参数 |
| Query filters | 所有已文档化的过滤器和特殊值 |
| Include values | 允许的关联数据 |
| Required/defaults | 必填字段和默认值 |
| Response | 主要字段和响应变体 |
| Errors | HTTP 码和错误结构 |
| Permissions | 所需权限和 impersonation 细节 |
| MCP exposure | 哪些参数在 MCP 中发布 |
| Intentionally omitted | 哪些参数未发布及原因 |
| Plugin/version differences | 插件及受支持版本差异 |

表格的目标不一定是将每个 Redmine 参数都发布到 MCP。目标是避免意外遗漏参数，并有意识地做出发布决策。

Redmine 参数在以下情况可从 MCP 排除：

- 危险或属管理性质；
- 与另一个更清晰的工具重复；
- 在受支持版本间不稳定；
- 产生歧义 schema；
- 目标用户场景不需要；
- 导致响应过大。

每项重大排除在 `Intentionally omitted` 中记录并附简要理由。

### 5.8. 开发工具的 AI 代理 instructions

若由 AI 代理创建或变更工具，工作 instructions SHOULD 引用本文档：API 研究（§5.6–5.7）、契约（§3–§8）、测试（§13）、检查清单（§14）。

推荐文本：

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. `inputSchema` 要求

### 6.1. 基本结构

每个工具 MUST 有有效的 JSON Schema。

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

对于无参数的工具：

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. 禁止未文档化的属性

在顶层及所有嵌套对象中：

```json
"additionalProperties": false
```

仅在有意识时才允许开放字典。此时须显式设置值的 schema：

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. 每个参数的类型

每个 property MUST 包含 `type`、`$ref` 或 `oneOf` / `anyOf` / `allOf` 组合。

FORBIDDEN：

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. 必填参数

`required` 数组必须反映最小可执行调用。

若无某参数则操作不可行，该参数 MUST 在 `required` 中。

例如，文件上传至少需要：

```json
"required": ["project", "filename", "content_base64"]
```

删除的 `confirm=true` 检查在服务端执行（§3.4），即使该字段在 `required` 中。

### 6.5. 枚举

对于有限值集，MUST 使用 `enum` 或 `const`（不能仅在 description 中用文本 — 见 §5.3）。

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. 字符串

字符串须有适当约束：

- 非空值用 `minLength`；
- 按 Redmine 约束或内部限制用 `maxLength`；
- 格式严格定义时用 `pattern`；
- 适用标准格式时用 `format`。

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

schema 中的 `format` 约束不能替代服务端校验（§3.4）。

### 6.7. 数字

数值参数 MUST 设置合理边界。

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

```json
"hours": {
  "type": "number",
  "exclusiveMinimum": 0,
  "maximum": 24
}
```

`default` 值是契约和文档的一部分。服务器不得假设客户端会自行替换 default。

### 6.8. 数组

每个数组 MUST 有 `items`。

需要时设置：

- `minItems`；
- `maxItems`；
- `uniqueItems`。

```json
"role_ids": {
  "type": "array",
  "minItems": 1,
  "maxItems": 20,
  "uniqueItems": true,
  "items": {
    "type": "integer",
    "minimum": 1
  }
}
```

像 `entries: array` 这样没有元素 schema 的数组 FORBIDDEN。

### 6.9. 嵌套对象

所有嵌套对象须完整描述。

```json
"custom_fields": {
  "type": "array",
  "items": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "id": {"type": "integer", "minimum": 1},
      "value": {
        "oneOf": [
          {"type": "string"},
          {"type": "number"},
          {"type": "boolean"},
          {
            "type": "array",
            "items": {"type": "string"}
          }
        ]
      }
    },
    "required": ["id", "value"]
  }
}
```

### 6.10. 不能接受「object 或 JSON string」

FORBIDDEN 将单个参数描述为「object 或 JSON string」。

MCP 已传递结构化 JSON。工具必须接受 object，而非服务器再次解析的 string。

### 6.11. 通用 `fields` 与 `extra_fields`

主要业务操作中 FORBIDDEN 使用 `fields`、`extra_fields`、`payload`、`data` 及类似开放对象参数。

Issue 字段须显式列出，并附有意义的 `description`（§6.14）及（在有用时）`examples`（§6.15）：

```json
{
  "tracker_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Tracker ID returned by redmine_list_trackers.",
    "examples": [1, 2]
  },
  "status_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role.",
    "examples": [1, 2]
  },
  "priority_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Issue priority ID returned by redmine_list_issue_priorities.",
    "examples": [3, 4]
  },
  "assigned_to_id": {
    "type": "integer",
    "minimum": 1,
    "description": "User ID of the assignee, from redmine_list_project_members."
  },
  "fixed_version_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Target version ID returned by redmine_list_versions."
  },
  "parent_issue_id": {
    "type": "integer",
    "minimum": 1,
    "description": "Numeric ID of the parent issue."
  },
  "estimated_hours": {"type": "number", "minimum": 0},
  "start_date": {"type": "string", "format": "date"},
  "due_date": {"type": "string", "format": "date"}
}
```

很少使用的字段可通过严格描述的 `custom_fields` 传递。

### 6.12. 相互依赖的字段

优先拆分工具。若无法拆分，通过以下方式形式化依赖：

- `dependentRequired`；
- `if` / `then` / `else`；
- 带互斥分支的 `oneOf`。

`description` 中的文本（「恰好其一 …」）不能替代 schema（§5.3）。

典型情况 — 「两个字段恰好其一」。不良：`required` 仅列公共字段，XOR 留在正文中：

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {"type": "string", "minLength": 1},
    "user_id": {"type": "integer", "minimum": 1},
    "group_id": {"type": "integer", "minimum": 1},
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "integer", "minimum": 1}
    }
  },
  "required": ["project", "role_ids"]
}
```

此类 schema 允许不含 `user_id`/`group_id` 的调用，以及同时含两个字段的调用。

良好 — 公共 `required` 加顶层 `oneOf`：

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "project": {
      "type": "string",
      "minLength": 1,
      "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown."
    },
    "user_id": {
      "type": "integer",
      "minimum": 1,
      "description": "User ID from redmine_list_users to add as a project member."
    },
    "group_id": {
      "type": "integer",
      "minimum": 1,
      "description": "Group ID to add as a project member."
    },
    "role_ids": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {"type": "integer", "minimum": 1},
      "description": "Role IDs from redmine_list_roles."
    }
  },
  "required": ["project", "role_ids"],
  "oneOf": [
    {
      "required": ["user_id"],
      "not": {"required": ["group_id"]}
    },
    {
      "required": ["group_id"],
      "not": {"required": ["user_id"]}
    }
  ]
}
```

服务端校验（§3.4）MUST 仍拒绝两种错误变体。需要 schema 以便客户端和模型在调用前看到约束。

须验证所选构造与受支持 MCP 客户端和 SDK 的兼容性。

### 6.13. 值为 `null` 的字段与清除值

`null` 仅在有单独文档化含义时允许，如「清除 due date」或「取消分配」。

```json
"due_date": {
  "oneOf": [
    {"type": "string", "format": "date"},
    {"type": "null"}
  ],
  "description": "New due date in YYYY-MM-DD format, or null to clear it."
}
```

```json
"assigned_to_id": {
  "oneOf": [
    {"type": "integer", "minimum": 1},
    {"type": "null"}
  ],
  "description": "Assignee user ID from redmine_list_users, or null to unassign."
}
```

不要用空字符串作为 `null` 的隐式等价物。

对于设置可选字段（due date、assignee 等）的 `set_*` 工具，契约 MUST 明确决定清除方式。允许三种选项 — 按优先级：

1. **同一工具接受 `null`**（首选），如上：一个意图「设置或清除」。
2. **单独的 clear/unassign 工具**，若 API 或 UX 更好分离操作，如 `redmine_advanced_search_clear_saved_query` 和 `redmine_advanced_search_unassign_search_owner`。
3. **明确拒绝**：若 MCP 不支持清除，MUST 在工具 `description` 和/或参数 description 中说明。无解释的静默契约「仅 string/integer 无 null」FORBIDDEN — 模型会误以为无法清除或尝试传 `""` / `0`。

不良 — 可设置 due date，无法清除，且未说明：

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. 参数描述

`inputSchema.properties` 中每个参数 MUST 有有意义的 `description`。无 `description` 的参数 FORBIDDEN，包括扩展中（checklist 项 `done`、`sort_order`、`due_date`、ID 字段等）和有明确 `enum` 的可选字段。

像 "Filter by tracker ID"、"Tracker id" 或 "Issue id" 的 description 不够：未提示如何获取允许值及存在哪些约束。

标识符参数的 description MUST 指明用于允许值的工具或响应字段（完整名称 — §5.2.1；discovery — §6.16），并注明重要约束（workflow、权限、项目归属）。

不良示例：

```json
"tracker_id": {
  "type": "integer",
  "description": "Filter by tracker ID."
}
```

```json
"done": {
  "type": "boolean"
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]}
}
```

良好示例：

```json
"tracker_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Tracker ID returned by redmine_list_trackers."
}
```

```json
"done": {
  "type": "boolean",
  "description": "true marks the item done; false marks it undone."
}
```

```json
"user_id": {
  "type": "integer",
  "minimum": 1,
  "description": "User ID from redmine_list_users to add as a project member."
}
```

```json
"resources": {
  "type": "array",
  "items": {"type": "string", "enum": ["issues", "wiki_pages"]},
  "description": "Resource types to search. Omit to search all supported resource types."
}
```

良好，注明约束：

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

参数 description 不能替代 schema（§5.3）和服务端校验（§3.4）。

### 6.15. 值示例（`examples`）

对于值格式不直观或允许多种表示的参数，SHOULD 添加 `examples` — 标准 JSON Schema 数组键。示例帮助模型输入正确值，对引用参数、标识符、日期和类 enum 字符串尤其有用。

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format.",
  "examples": ["2026-07-30"]
}
```

要求：

- `examples` 值 MUST 对参数 schema 本身有效；
- `examples` 说明格式但不替代 `enum`、范围和其他约束（§5.3、§6.5）；
- 对有 `enum` 的参数，单独的 `examples` 通常多余。

若 MCP 客户端或 SDK 不支持 schema 中的 `examples`，MAY 使用 `x-examples` 作为扩展键，语义相同。

### 6.16. ID 参数的 discovery 路径

模型无法猜测的 `*_id` 形式参数 MUST 有显式 discovery 路径：单独的 read/list 工具，或在参数 `description`（§6.14）中引用的其他 read 工具响应字段。

允许选项（对工具集按优先级）：

1. **单独的 list/discovery 工具** — `redmine_list_issue_statuses`、`redmine_list_roles`、`redmine_advanced_search_list_search_providers`。
2. **get/list 响应内的选项** — 如 `redmine_advanced_search_semantic_search_issues` 响应中带 `id` 和 `name` 的 provider 数组。此时 description MUST 以完整工具名引用该响应字段。
3. **schema 中的稳定 enum**，若值集固定且较小。

若以上均不满足，FORBIDDEN 发布带 `status_id` / `role_ids` / 类似参数的写工具：模型被迫猜测 ID。

不良 — 写操作无 discovery：

- 存在带 `provider_id` 的 `redmine_advanced_search_set_search_provider`；
- 没有 `redmine_advanced_search_list_search_providers`；
- `semantic_search_issues` 仅返回当前 provider 名称（`provider: "…"`），无允许值列表及其 `id`。

此时像 `"Search provider ID."` 的 description 不够。要么添加 list 工具，要么在 get 响应中包含 provider 选项并写明，例如：

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

该规则适用于核心和扩展（§18）。

---

## 7. `outputSchema` 与结果要求

### 7.1. 输出 Schema

新工具 MUST 发布 `outputSchema`。schema 描述稳定的公共响应契约，不仅是 `{ ok, data | error }` 封装形状。

若 `description` 声称工具返回命名字段或嵌套结构，`outputSchema` MUST 形式化这些字段，不能仅将顶层 `data` / `items` 限定为「任意 object」。

不良：description 列出 `query`、`results`、片段和附件摘录，但 `outputSchema` 缺失或仅将 `items` 描述为 `{ "type": "object", "additionalProperties": true }`。

对每个稳定结果字段：

- MUST 指定 type；
- 保证字段 MUST 在 `required` 中；
- 有限值集 MUST 通过 `enum` 或 `const` 设置；
- 若服务器保证对应格式，date MUST 有 `format: date` 或 `date-time`；
- 数值 ID MUST 保持统一 type；
- nullable 与 optional 是不同契约：若字段始终返回但可能无值，须为 `required` 且允许 `null`；
- 对数值业务值，若字段名不明显，MUST 指定单位；
-  monetary 值 MUST 语义明确：major/minor 单位及 currency 如何确定。

不能用 `additionalProperties: true` 代替描述已知稳定结果字段。为向后兼容或真正可扩展结构时允许，但此类 object 内的已知业务字段仍须在 `properties` 中列出，保证字段在 `required` 中。

对 list 工具，`items` 元素 MUST 至少描述模型识别、过滤和后续工具调用所需的字段。

良好 — `data` 片段 typing（完整 success/error 封装 — §7.2 和 §12）：

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "ok": {"type": "boolean"},
    "data": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "query": {"type": "string"},
        "results": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": true,
            "properties": {
              "id": {"type": "integer"},
              "subject": {"type": "string"},
              "url": {"type": "string"}
            },
            "required": ["id", "subject"]
          }
        }
      },
      "required": ["query", "results"]
    }
  },
  "required": ["ok"]
}
```

结果 SHOULD 返回：

- `structuredContent` — 若客户端需要稳定结构，则为机器可读 object；
- 文本 `content` — 为向后兼容和人类提供的简要表示。

### 7.1.1. 公共契约一致性

完成工具前，开发者 MUST 比较三种表示：

1. 实际 handler / REST / service 响应；
2. 工具 `description`；
3. `outputSchema`。

三者不得相互矛盾。

若 description 说某字段始终返回，它须在 `outputSchema` 中为 `required`。

若 schema 设置 `enum` / `const` / `format`，实际 serializer MUST 将值规范化为该契约。不能发布 `format: date` 同时又承诺 locale 格式字符串。

若列表已返回数据，description MUST NOT 仅因相同数据将模型导向 get 工具。

结果的业务不变量 MUST 通过 `const`、`enum`、`required` 或条件 schema 反映在 schema 中，不能仅从工具名推断。示例：若 subscription 工具按定义仅返回 `subscription` 类型产品，`product_type` 须为 `const: "subscription"`，而非含不可能值的 `enum`。

### 7.2. 统一封装

推荐成功结果：

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

错误：

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "status_id 17 is not available for tracker 3",
    "field": "status_id",
    "retryable": false
  }
}
```

出错时 additionally 设置：

```json
"isError": true
```

若发布 `outputSchema` 且 error 也在 `structuredContent` 中返回，schema MUST 描述 success 和 error 两个分支。不能发布仅 success 的 schema 却返回不兼容的结构化 error object。替代：工具执行错误时仅返回带 `isError: true` 的文本 `content`，不返回 `structuredContent`。首选 — 带两个分支的统一 typed 封装。

### 7.3. 字段稳定性

输出字段是公共契约。FORBIDDEN：

- 无 major 变更而改变字段 type；
- 无弃用期而重命名字段；
- 有时返回 object，有时 array；
- 有时 ID 为 number，有时为 string；
- 返回未处理的无限 Redmine API 响应。

### 7.4. 单个 object 结果

推荐格式：

```json
{
  "ok": true,
  "data": {
    "id": 12345,
    "subject": "Fix authorization error",
    "status": {"id": 2, "name": "In Progress"},
    "project": {"id": 10, "identifier": "bank-site", "name": "Bank Site"},
    "url": "https://redmine.example/issues/12345",
    "updated_at": "2026-07-22T09:20:00Z"
  }
}
```

### 7.5. 列表结果

```json
{
  "ok": true,
  "data": {
    "items": []
  },
  "meta": {
    "total_count": 143,
    "limit": 25,
    "offset": 0,
    "next_offset": 25,
    "has_more": true
  }
}
```

`items` 元素 schema 遵循 §7.1：identifiers、routing 字段和稳定业务字段须显式描述。仅将 `{ "type": "object", "additionalProperties": true }` 作为元素描述 FORBIDDEN。

### 7.6. 最小必要体量

List/search 工具默认须返回简要记录。完整 description、journals、attachments 和大型文本字段应通过单独的 `get_*` 获取。

这减少 token、延迟和传递过多敏感数据的风险。

### 7.7. 敏感数据

结果非明确需要不得包含：

- API token；
- Authorization 头；
- cookie；
- 服务器文件系统路径；
- 内部 stack trace；
- 密码和 secret；
- 当前用户不可用的 Redmine 字段；
- 无单独权限的 private note。

---

## 8. MCP 注解

Annotations 是给客户端的提示，不是授权或保护机制。

### 8.1. 值矩阵

| 操作类型 | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| 获取/查找/列出 Redmine 数据 | `true` | `false` | `true` | `false` |
| 创建 issue/version/checklist | `false` | `false` | `false` | `false` |
| 添加 comment/watcher/relation | `false` | `false` | `false` | `false` |
| 更改字段、重命名、设置标志（`update`、`rename`、`set`） | `false` | `false` | 取决于实现 | `false` |
| 删除、清除、重置（`delete`、`purge`、`reset`） | `false` | `true` | 仅在有保证的 idempotency 时 | `false` |
| 向外部接收方发送 email | `false` | `false` | `false` | `true` |
| 访问任意 URL / 外部系统 | 取决于情况 | 取决于情况 | 取决于情况 | `true` |

### 8.2. 规则

- 仅当工具不改变状态且不引起副作用时 `readOnlyHint: true`。
- `destructiveHint` 描述不可逆的数据丢失或破坏，而非写入事实。`destructiveHint: true` SHOULD 仅对不可逆操作设置 — `delete`、`purge`、`reset`、完整字段或 relation 清除。
- 普通 `update`、`rename` 和 `set` 不是 destructive：对它们 `destructiveHint: false`。例如 `update_checklist_title` 或 `rename_wiki_page` 是普通 update，不是破坏，destructive annotation 对它们是错误的。
- 仅当重复调用真正安全时 `idempotentHint: true`；SHOULD 用测试确认。
- `openWorldHint` 描述工具是否访问开放的、先前未知的外部世界，而非是否创建新 object。与一个已配置 Redmine 安装协作是 closed world：`openWorldHint: false`。
- 因此 `create_issue`、`create_time_entry` 及其 Redmine 内的其他写工具使用 `openWorldHint: false`，尽管创建新 object。在已知系统中创建 object 不会使 world 变为 open。
- 仅当接收方或数据源不限于已知系统时 `openWorldHint: true`：向外部接收方发送 email、任意 HTTP 请求、访问外部 service。
- 每个工具的 `openWorldHint` 值 SHOULD 有意识地设置，不要默认复制：验证工具是否实际超出其 Redmine 安装。
- 不能将一套 annotation 复制到所有写工具。

### 8.3. Redmine 副作用

评估 idempotency 时，不仅考虑最终字段，还考虑：

- journal entry 创建；
- notification 发送；
- webhook；
- audit log；
- 重复 file upload；
- 重复 relation 创建；
- 重复 time entry 记录。

若重复调用创建额外 record 或 notification，工具不是 idempotent。

---

## 9. 安全

### 9.1. 授权

每次调用 MUST 在已认证用户或明确文档化的 service account 上下文中运行。

服务器 MUST 检查特定 project 和 object 的 Redmine 权限。工具出现在 `tools/list` 中不意味着有操作权限。

管理工具应：

- 仅向管理员发布；
- 或移至单独的管理 MCP profile/server；
- 或用单独 scope 保护。

### 9.2. 最小权限

MCP 服务器和 Redmine API token 须具有最小必要权限。若须保留用户访问模型，不能对所有用户使用全局管理 token。

### 9.3. 禁止任意文件系统路径

如下参数：

```json
{"file_path": "/etc/app/.env"}
```

在公共 MCP 工具中 FORBIDDEN。

安全选项：

1. 带大小限制的 `content_base64`；
2. 由可信 upload 机制签发的 opaque `upload_token`；
3. 由 host 检查访问的 MCP resource URI；
4. 仅来自专用临时目录的文件，经 `realpath` 检查和 allowlist。

服务器 MUST 验证：

- 最大大小；
- MIME type；
- 允许的 extension；
- 文件名；
- 无 path traversal；
- 若组织策略要求，则 antivirus/content 检查。

### 9.4. 任意 URL 与 SSRF

工具不得接受任意 URL，除非这是其主要目的。

需要 HTTP 访问时：

- 使用 domain 和 scheme allowlist；
- 若非必要，禁止 loopback、link-local、metadata 端点和内部网络；
- 限制 redirect；
- 设置 timeout 和响应 limit；
- 不向另一 origin 传递内部 credential。

### 9.5. 删除与危险操作

对不可逆操作，MANDATORY：

- 单独工具；
- `destructiveHint: true`；
- 明确说明不可逆性；
- 精确的服务端权限检查；
- audit log；
- 防止删除预期 project 外的 object；
- 检查子 object 及相关后果。

Boolean `confirm_delete: true` MAY 用作防止意外调用的额外保护，但不能视为授权机制。

两阶段删除、乐观锁和 idempotency key — 见附录 A。

### 9.6. 日志

Audit log 记录：

- 工具名；
- 已认证用户；
- 目标 project/object ID；
- 结果；
- 持续时间；
- 错误码；
- 请求 correlation ID。

FORBIDDEN 记录：

- access token；
- Authorization 头；
- cookie；
- base64 文件内容；
- secret 自定义字段；
- 无单独需要的 private note 全文。

### 9.7. 速率限制与 timeout

每个工具 MUST 有：

- 输入大小 limit；
- 每 user/token 的 rate limit；
- 返回 record 数量的 limit；
- 批量操作 limit。

60 秒服务器 timeout 适用于 read 工具。Write 工具不被服务器 timeout 中断，以便成功保存后可记录 idempotency 结果。

---

## 10. 错误

### 10.1. 错误分离

使用两个级别：

1. **Protocol error** — 未知工具、损坏的 JSON-RPC、无法处理 MCP 请求。
2. 带 `isError: true` 的 **Tool execution error** — 参数错误、Redmine API、权限、workflow 或业务逻辑错误。

模型可通过更改参数修复的错误应作为 tool execution error 返回。

### 10.2. 错误结构

```json
{
  "ok": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "User cannot edit issues in project bank-site.",
    "field": null,
    "retryable": false,
    "details": {
      "project": "bank-site",
      "required_permission": "edit_issues"
    }
  }
}
```

### 10.3. 推荐码

```text
VALIDATION_ERROR
NOT_FOUND
FORBIDDEN
CONFLICT
RATE_LIMITED
REDMINE_API_ERROR
TIMEOUT
FILE_TOO_LARGE
UNSUPPORTED_MEDIA_TYPE
INVALID_STATE
PARTIAL_FAILURE
INTERNAL_ERROR
```

### 10.4. 消息必须可修复

不良示例：

```text
Invalid request.
```

良好示例：

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

不向用户返回 stack trace。Stack trace 仅存储在带 correlation ID 的受保护服务器日志中。

---

## 11. 分页与数据体量

### 11.1. 列表/搜索工具

MANDATORY 参数：

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

对现有 Redmine API，允许 `offset`。对自定义实现，若遍历期间数据可能活跃变化，首选 opaque cursor。

### 11.2. 分页 metadata

结果必须包含：

- 实际 `limit`；
- `offset` 或 `next_cursor`；
- `has_more`；
- 若获取 `total_count` 不会带来显著负载。

### 11.3. 字段选择

`fields` 参数仅允许作为来自封闭 allowlist 的 array：

```json
"fields": {
  "type": "array",
  "uniqueItems": true,
  "items": {
    "type": "string",
    "enum": ["id", "subject", "status", "assignee", "updated_at"]
  }
}
```

不能在没有 allowlist 的情况下将任意字段名直接传给 SQL、ActiveRecord `select`、serializer 或 Redmine API。

### 11.4. 大型结果

大型 journal、attachment 和 file 必须：

- 有单独分页；
- 由单独 tool/resource 返回；
- 对 binary 数据，尽可能返回 resource 链接或其他有限引用，而非在响应中嵌入大型 base64；
- 或若操作确实很长且客户端支持，则支持 task-augmented 执行。

`execution.taskSupport` 不会自动设置。默认值为 `forbidden`。

---

## 12. 新工具参考

按 §7.1 带 mandatory `title` 和 typed `outputSchema` 的 abbreviated 写工具示例。错误格式 — §10。完整 JSON — 见附录 B。

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer", "minimum": 1},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  }
}
```

---

## 13. 测试

### 13.1. Schema 测试

对每个工具，MANDATORY：

- 至少一次有效调用；
- 至少一次 negative 调用（如缺少必填字段或错误 type）。

SHOULD 按 schema 适用情况覆盖：

- 完整有效调用；
- 每个必填字段的缺失；
- 关键参数的错误 type；
- 未知 additional field；
- enum 外的值；
- 范围外的值；
- 错误的 date/date-time；
- 超出 `maxItems`、`maxLength` 和 file 大小；
- 违反字段相互依赖（两个 XOR 字段同时存在；必填对两者皆无）。

### 13.2. 权限测试

对 write、destructive 和 sensitive read 操作 SHOULD 验证：

- 无 project 访问权限的用户；
- 只读访问用户；
- 有 edit 权限的用户；
- 若工具涉及 admin 场景，则管理员；
- 若工具返回或更改 private note，则其访问；
- 通过替换 ID 尝试更改另一 project 的 object。

对无敏感数据的简单 read-only 工具，权限测试 MAY 限制为一个 negative 场景，或在 MR 中简要说明理由后省略。

### 13.3. Idempotency 测试

对 `idempotentHint: true`，SHOULD 有两次或更多相同顺序调用的自动或手动测试。

验证声称 idempotent 的副作用不存在，例如：

- 额外 journal entry；
- 重复 email；
- file 重复；
- relation 重复；
- 重复 time entry；
- 若为保证的一部分，则额外 webhook event。

### 13.4. 契约测试

SHOULD 将 `tools/list` 作为 snapshot 或以其他方式跟踪 breaking 契约变更。CI MAY 检测：

- 名称变更；
- 参数移除；
- type 变更；
- `required` 变更；
- annotation 风险级别上升；
- `outputSchema` 消失；
- `outputSchema` 的 fields、types、`required`、`enum` / `const` 或 success/error 分支的不兼容变更。

### 13.5. LLM 选择测试

对相似或易混淆的工具 SHOULD 有一组用户请求和预期 tool call。完整自动 LLM 运行 MAY 由 MR 或 description 审查中的静态示例替代。

示例：

| 请求 | 预期工具 |
|---|---|
| "显示任务 123" | `redmine_get_issue` |
| "查找关于 OAuth 的任务" | `redmine_search_issues` |
| "为任务 123 添加关注者 15" | `redmine_add_issue_watcher` |
| "删除任务之间的关联" | `redmine_delete_issue_relation` |
| "查找相似任务" | `redmine_advanced_search_semantic_search_issues` |

若模型高概率为 read-only 意图选择通用 destructive 工具，或被迫猜测 `action` 值，则测试或审查失败。

### 13.6. 错误恢复测试

SHOULD 验证典型错误后模型收到足够信息以正确重试：

- 缺失 ID；
- 无效 status；
- `expected_updated_at` 冲突；
- 权限不足；
- 超出 limit；
- 错误 MIME type。

---

## 14. 代码审查检查清单

新工具在所有 mandatory 项得到「是」的回答前不能合并。

### 目的

- [ ] 一个动作；无 `action`/`manage` 混合操作（§3.1–3.2）。
- [ ] 管理操作与普通操作分离。

### 名称与描述

- [ ] 名称以 `redmine_` 开头：核心 — `redmine_<verb>_<entity>`；第三方插件 — `redmine_<plugin_id>_…`（§4.1）。
- [ ] Description：目的、副作用、简要结果；相似工具可区分（§5）。
- [ ] 对其他工具的交叉引用使用 `tools/list` 中的完整名称（§5.2.1）。

### 源契约研究

- [ ] 对核心工具，已研究资源 REST API、版本及所需插件；coverage report SHOULD 附于 MR（§5.6–5.7）。
- [ ] 对扩展工具，MUST 验证源 serializer / service / REST 端点及每种结果形式至少一次真实成功响应（§18.5）。
- [ ] 契约与当前 `tools/list` 比较。

### 输入 schema

- [ ] Schema 符合 §6（`additionalProperties: false`、types、`required`、`enum`/`const`、constraints）。
- [ ] 每个参数有有意义的 `description`（§6.14）；`*_id` 有 `minimum: 1`（§4.3）。
- [ ] 对 `*_id` 和其他 lookup 值，指定 discovery 路径（§6.16）：list 工具、get/list 响应字段或 `enum`。
- [ ] 「恰好其一 …」/ 相互依赖约束在 schema 中形式化，不仅于 description（§5.3、§6.12）。
- [ ] 乐观锁 — 仅 `expected_updated_at`，非 `updated_at`（§4.4）。
- [ ] 对 `set_*` 可选字段，已决定清除方式：`null`、单独 clear 工具或明确拒绝（§6.13）。
- [ ] 无「object 或 JSON string」和任意 `fields`/`payload`。
- [ ] `*_id` — integer；按 §3.4 服务端校验。

### 输出与错误

- [ ] 新工具有带 success/error 封装的 `outputSchema`（§7.1–7.2）。
- [ ] 已知稳定结果字段在 `properties` 中描述；不用 `additionalProperties: true` 代替已知契约。
- [ ] 所有保证字段在 `required` 中。
- [ ] Nullable 与 optional 字段有 conscious 区分。
- [ ] `enum`/`const`、`date`/`date-time`、范围和其他已知约束在 schema 中形式化。
- [ ] 对 monetary 和其他数值业务值，units、currency 和 major/minor units 清晰。
- [ ] 结果的业务不变量反映在 schema 中（`const`、`enum`、`required` 或条件 schema），不仅从工具名推断。
- [ ] Description、`outputSchema` 和实际 handler/REST/service 响应不矛盾（§7.1.1）。
- [ ] 内部 REST/Ruby/plugin 值规范化为稳定 MCP 契约；无 STI/class 名或 locale 依赖格式泄漏（§3.3）。
- [ ] List 工具返回简要但足够的结构；description 正确说明何时真正需要对应 get 工具。
- [ ] 错误：`isError`、稳定 code、可修复 message；无 secret 或 stack trace（§10）。

### 注解

- [ ] Annotations 匹配风险（§8）；对 `idempotentHint: true` 建议测试。

### 安全

- [ ] 权限、file path、SSRF、limits、logs、destructive/audit — 按 §9；按需采用附录 A 模式。

### 测试

- [ ] 最低 schema 测试；其余按风险（§13）。

---

## 15. 兼容性与变更现有工具

### 15.1. Breaking 变更

Breaking 变更：

- 工具重命名；
- 字段移除；
- type 变更；
- 添加新必填字段；
- 更改字段含义；
- 不兼容 output 变更；
- 将多个操作合并为一个；
- 提高风险但未更新 annotations 和文档。

### 15.2. 名称迁移

迁移时，例如从旧前缀 `redmine_mcp_`：

```text
redmine_mcp_get_issue
```

到短前缀 `redmine_`：

```text
redmine_get_issue
```

遵循：

1. 添加新名称；
2. 暂时保留旧 alias；
3. 在 description 中将旧工具标记为 deprecated **或若 alias 仅用于 `tools/call` 则不将其发布到 `tools/list`**；
4. 收集旧名称调用 metrics；
5. 约定期满后移除 alias；
6. 若服务器声明 `listChanged`，发送 `notifications/tools/list_changed`。

当前示例（见 [03-core-tools.md](03-core-tools.md)）：`redmine_list_all_users` → `redmine_admin_list_users`；`redmine_list_files` → `redmine_list_project_files`；`redmine_delete_file` → `redmine_delete_attachment`；`redmine_get_server_info` → `redmine_get_mcp_info`。alias 在 `tools/call` 中被接受，不在 `tools/list` 中发布。

### 15.3. 更改描述

Description 影响模型工具选择，视为行为变更。重大 description 变更时 SHOULD 审查 LLM 选择示例或进行重复选择审查。

### 15.4. 服务器版本

MCP 服务器版本由单独 read-only 工具或服务器 metadata 返回。无真正需要支持并行不兼容契约时，不要给每个名称加 `v1`、`v2`。

---

## 16. 当前 Redmine MCP 问题的规则

开发新工具时，禁止重复当前契约审计中的模式。规范规则在对应章节；以下仅为问题映射：

| 审计问题 | 章节 |
|---|---|
| 无 `redmine_` 前缀的名称（含第三方插件）/ 单插件内混合风格 | §4.1 |
| 动词与语义不符（`complete_*` 带 `done=true/false` 而非 `set_*`） | §4.2 |
| 无 `minimum: 1` 或 description 为 "Issue id" 的数值 ID | §4.3 |
| 乐观锁用 `updated_at` 而非 `expected_updated_at` | §4.4, A.2 |
| 通用 `manage_*` / `patch_*` 和 `action` 参数 | §3.1, §4.2 |
| 无 `type` 的参数、enum 仅在 description 中、无 `items` 的 array | §5.3, §6 |
| 无 `description` 的参数；过短且无 lookup 工具引用的 description | §6.14 |
| 引用参数和标识符无 `examples` | §6.15 |
| 带 `*_id` 的写工具无 discovery 路径（无 list 工具且 get 响应无选项） | §6.16 |
| Description 承诺「A 或 B 恰好其一」，schema 未编码 | §5.3, §6.12 |
| 交叉引用中的短工具名（`list_projects` 而非 `redmine_list_projects`） | §5.2.1 |
| 过载的工具 description 半页长 | §5.2 |
| 无 schema 的 `fields` / `extra_fields`；额外 `required` | §6.4, §6.11 |
| `set_*` 无法清除字段且无明确拒绝 | §6.13 |
| 所有写工具共用一套 annotation；过多 `openWorldHint` | §8 |
| 普通 `update` / `rename` 上 `destructiveHint: true`；`create_*` 上错误 `openWorldHint` | §8.1, §8.2 |
| Description 承诺响应结构，但 `outputSchema` 缺失或仅描述任意 object | §7.1 |
| Description、schema 和实际响应矛盾 | §7.1.1 |
| MCP 响应中的 STI/class 名或 locale 日期 | §3.3 |
| 用 `additionalProperties: true` 代替已知 list/get 字段 | §7.1 |
| 任意 `file_path`、project-scope 绕过、SSRF | §9 |
| 本地变更与 email/外部效果在同一工具 | §3.2 |
| 相似工具的歧义对 | §5.4 |

---

## 17. 工具集结构

完整当前工具列表不在本文档中重复 — 它会很快过时。

**权威来源：**

- 核心工具 — [03-core-tools.md](03-core-tools.md) 及安装实例上的实际 `tools/list`；
- 第三方插件工具 — §18 及安装实例上的 MCP `tools/list` 响应。

**分组原则**（每组 — 按 §3 的独立原子工具）：

| 组 | 示例意图 | 前缀 |
|---|---|---|
| 任务 | get、list、search、create、update、delete、copy、子任务 | `redmine_` |
| 关系与关注者 | 关系的 list/create/delete；add/remove 关注者 | `redmine_` |
| 项目与成员 | 项目、模块、成员、角色 | `redmine_` |
| 版本与类别 | 版本；任务类别 | `redmine_` |
| 工时记录 | list、create、update、import、活动 | `redmine_` |
| Wiki | list、get、create、update、rename、delete | `redmine_` |
| 文件与附件 | list、upload、delete、download | `redmine_` |
| 管理 | 用户、角色、MCP 会话信息 | `redmine_admin_` 或 `redmine_get_mcp_info` |
| 插件实体 | 清单、搜索等 | `redmine_` + `plugin_id`，如 `redmine_advanced_search_` |

添加新工具前 SHOULD 检查 MCP `tools/list` 响应和对应组：不重复现有工具，不在一个名称中混合不同意图。

若组有带 ID 参数（`status_id`、`role_ids`、…）的写工具，同组 MUST 有 discovery 路径（§6.16）。

管理工具仅向有所需权限的用户发布（§9.1）。

---

## 18. 第三方插件扩展

面向通过 Extension API 添加工具的 Redmine 插件作者的章节。API、hooks 和边界情况的技术描述 — 见 [04-extensions.md](04-extensions.md)。

扩展遵循与 `redmine_mcp` 核心工具相同的契约、安全和命名规则（§3–§10、§4.1）。

### 18.1. 何时发布什么

| 原语 | 何时使用 |
|---|---|
| **Tool** | 对插件 entity 或 Redmine 的一个动作：create、get、update、delete、search |
| **Resource** | 通过稳定 URI 的大型或静态内容：wiki body、file、长报告 |
| **Prompt** | 面向用户的可重复场景模板，非有副作用的操作 |
| **`extend_tool`** | 逻辑上属于现有核心工具的 parameter 或 hook（如读取 issue 时的 `include_*`） |

若模型可用独立工具实现意图而无需猜测 `action` — 优先 **自有 tool**，而非用 `extend_tool` 膨胀另一 schema。

### 18.2. 注册

- 扩展文件在 Redmine 启动时加载（见 `ExtensionLoader`）：
  - 在第三方插件中 — `lib/<plugin_id>/mcp.rb`（及其他支持的路径，见 [04-extensions.md](04-extensions.md)）；
  - 在 `redmine_mcp` 内置集成中 — 若目标插件没有自身 `mcp.rb`，或其 `mcp.rb` 加载失败时作为 fallback，使用 `lib/redmine_mcp/extensions/<plugin.id>.rb`。
- `mcp.rb` 中的 module MUST 为 `PluginName::Mcp`（`extend RedmineMcp::ExtensionApi`）：Zeitwerk 从文件推导名称。
- 注册前 SHOULD 检查 `mcp_extension_enabled?` — gemspec 中不必硬依赖 `redmine_mcp`。
- 注册使用 `register_tool_once`，以免 reload 重复 tool。
- `tools/list` 中的完整名称 MUST 以 `redmine_` 开头（§4.1）。
- Tool MUST 有 `title`、`description`、`input_schema`、`output_schema`、`permission` 和 `annotations`；禁止名称重复。
- Tool 仅对有相应权限的用户在 MCP `tools/list` 响应中可见。

### 18.3. 命名

- 名称 MUST 以 `redmine_` 开头；然后 — `plugin_id` 和 `<verb>_<entity>`：`redmine_redmine_advanced_checklists_<verb>_<entity>`、`redmine_advanced_search_<verb>_<entity>`。
- 动词和 `manage_*` 禁止 — 按 §4.2 和 §3.1。
- 不要复制核心工具名称，不要以不同名称发布相同意图的第二个 tool。

注册前 SHOULD 与目标安装实例上的 `tools/list` 响应比较。

### 18.4. 权限与安全

- `permission` MUST 匹配真实 Redmine 或插件权限，而非单独的「mcp-only」角色。
- 对 issue 操作 SHOULD 使用 `register_issue_tool` 和 `find_accessible_issue`，而非复制 visibility 和 project module 检查。
- 若设置 `module_name`，tool MUST 仅当用户在至少一个可见且已启用 module 的 project 中有声明权限时才出现在 `tools/list`。无 `module_name` 时，在至少一个可见 project 中有权限即可。Handler 仍检查特定 issue，包括其 project module。
- Handler 中重复的服务端参数和权限校验 — 按 §3.4 和 §9，即使 tool 对其他用户隐藏在 `tools/list` 外。

### 18.5. 清晰实现

**薄 MCP 层。** `mcp.rb` 应主要包含 tool 注册：schemas、descriptions、permissions、annotations 和短 handler。Handler 校验参数、检查 context，并将执行委托给单独的 class/service。

插件业务逻辑应保留在普通 model 和 service 中，不依赖 MCP。

若逻辑仅 MCP 需要 — 如合并多个 model 的数据、将 REST 响应规范化为 MCP 契约、计算派生字段或准备 tool 结果 — MAY 移至单独的 `mcp_tools.rb`。若文件变大，SHOULD 按 entity 或 operation 拆分为 class，如 `mcp_tools/clients.rb`、`mcp_tools/deals.rb`、`mcp_tools/subscriptions.rb`。

不要将业务逻辑和大型转换直接放在 `mcp.rb` 内的 lambda/handler 中。

**数据访问。**

- 插件 model 和 service — 若逻辑已存在。
- `internal_request` / `internal_get` / REST — 若需复用现有 API controller；endpoint 须支持 `accept_api_auth`。对 `POST`、`PUT`、`PATCH` 和 `DELETE` 使用 `internal_request`；对 read 使用 `internal_get` 或 `internal_request(method: 'GET', ...)`。用 `internal_request_error?` 检查失败。

**`extend_tool` — 适度。** 当 parameter 是与核心工具同一意图的一部分时合适。当插件实质上添加独立子系统时不合适：更好自有 prefix 和自有 tools，与核心的链接在 `description` 或 server instructions 中描述。

**契约如核心。** Input — 按 §6。Output — 按 §7.1 和 §7.1.1：稳定 fields、`required`、`enum`/`const`、units、内部 API 规范化。Annotations 按风险，可修复错误（§8、§10）。乐观锁 — `expected_updated_at`（§4.4）。每个 parameter — `description`（§6.14）。交叉引用 — 完整名称（§5.2.1）。每个写 parameter `*_id` — discovery 路径（§6.16）：单独 `list_*` 或 get/list 响应中带 `id` 的选项，并在 parameter description 中显式引用。

发布扩展 tool 前 MUST 验证源 serializer / service / REST 端点及每种结果形式至少一次真实成功响应。

**共享代码 — 在 `redmine_mcp` 中。** 开发扩展时，若片段可能被另一 MCP 插件需要，SHOULD 立即添加到核心 `redmine_mcp`，而非复制到 `lib/<plugin>/mcp*.rb`。

准则：逻辑不绑定单一插件域（checklists、search、…），且描述 MCP 契约、Extension API 或典型集成模式。

| 位置 | 内容 |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`、`REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`、`ExtensionApi` 扩展（`register_issue_tool`、`issue_permission`、`internal_request`、…）、`ToolResponse`、按 `issue_id` / `project_id` 的通用权限 helper |
| **Plugin extension** | `mcp.rb` — tool 注册和短 handler；`mcp_tools.rb` / `mcp_tools/*.rb` — MCP 专用 fetch、aggregation、normalization；普通 model/service — 不依赖 MCP 的业务逻辑 |

**扩展的推荐放置：**

- `mcp.rb` — tool 注册和短 handler；
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP 专用 fetch、aggregation 和数据 normalization；
- 普通 model/service — 不依赖 MCP 的业务逻辑。

从另一扩展复制 helper 前 SHOULD 检查 `redmine_mcp` 中是否已有类似物；若无 — 在同一 PR 中移至核心，不要重复。

更多扩展 API — [04-extensions.md](04-extensions.md)（§ "ExtensionApi helper methods"）。

### 18.6. 反模式

FORBIDDEN 或不推荐：

- 在每个 HTTP 请求上注册 tool；
- 启动时因邻居插件错误而失败；
- 在一个 tool 中混合 read、write 和 admin；
- 以「不同名称」复制核心 tool；
- 用「为未来」的可选 parameter 扩展另一 tool；
- 在 MCP 中返回插件 UI/API 中用户不可用的内部 field；
- 若 MCP schema 定义不同契约，发布 STI class 名、locale 日期或 REST 表示（§3.3、§7.1.1）；
- 仅将 list 元素描述为 `{ "type": "object", "additionalProperties": true }`（§7.1）；
- 发布带 `status_id` 的 `set_*_status` / 类似工具而不给模型获知允许 ID 的方式（§6.16）；
- 若其位置在 `redmine_mcp`，在扩展中重复通用 MCP helper（封装 `outputSchema`、`internal_request` wrapper、issue permission）— 见 §18.5。

### 18.7. 合并前验证

- [ ] 工具名按 §4.1 / §18.3 以 `redmine_` 开头。
- [ ] 扩展在启动时加载；对有权限的用户 tool 出现在 `tools/list` 中。
- [ ] 对无权限用户及插件 MCP 扩展 flag 禁用时 tool 不存在。
- [ ] 契约和检查清单（§14）满足，含 description / outputSchema / 实际响应比较（§7.1.1）；按需 §13 测试。
- [ ] Serializer / REST / service 对每种已发布结果形式至少一次真实成功响应已验证（如两者都发布则 list 和 get）。
- [ ] `tools/list` 中无现有 tool 重复。
- [ ] 每个 `*_id` 写 parameter 有 discovery 路径（§6.16）。

---

## 19. 来源与规范基础

文档基于以下主要来源，编写于 2026-07-22：

1. Model Context Protocol，**Protocol Revision 2025-11-25**  
   https://modelcontextprotocol.io/specification/2025-11-25

2. Model Context Protocol，**Tools**  
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Model Context Protocol，**Schema Reference**  
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Model Context Protocol，**Security Best Practices**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Model Context Protocol，**Understanding Authorization in MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog，**Tool Annotations as Risk Vocabulary: What Hints Can and Can't Do**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog，**Server Instructions: Giving LLMs a user manual for your server**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON Schema，**Reference**  
   https://json-schema.org/understanding-json-schema/reference

9. JSON Schema，**Enumerated values**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON Schema，**Conditional schema validation**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine，**REST API overview**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine，**REST Issues**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine，**REST API changes**  
    REST API 页面上的链接 `API changes for each version`；已为所有受支持版本验证。

---

## 20. 新工具就绪准则

当 mandatory 代码审查检查清单项（§14）满足时，新 MCP 工具视为就绪。

对第三方插件工具 additionally — 检查清单 §18.7。

风险建议：coverage report（§5.7）、额外测试 §13.2–13.6 和附录 A。最低 schema 测试（§13.1）和 `outputSchema` 规则（§7.1、§7.1.1）为 mandatory。

---

## 附录 A. 推荐实现模式

以下模式并非每个 MCP 工具都 mandatory。对 elevated 风险 SHOULD 考虑：destructive 操作、admin 工具、bulk write、外部副作用、因 timeout 的重复调用。

### A.1. 两阶段删除（prepare / confirm）

对尤其危险的管理操作：

1. `redmine_prepare_delete_*` 返回简要后果描述和一次性 token；
2. `redmine_confirm_delete_*` 接受短 TTL 的 token。

destructive 操作的规范性要求 — 见 §9.5。

### A.2. 乐观锁

在并发变更下 update/delete 时，parameter MUST 命名为 `expected_updated_at`（§4.4），非 `updated_at`：

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

名称对核心工具和扩展（含 checklist 写工具）统一。

冲突时返回 `CONFLICT`、实际 object 修改时间（响应中的 `updated_at` / `updated_on`）及重新读取 object 的建议。

### A.3. 幂等键（Idempotency key）

对因 timeout 重复可能产生 duplicate 的操作：

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

尤其适用于：

- issue 创建；
- time entry import；
- file upload；
- bulk 操作；
- email 发送。

若 tool 发布 `idempotentHint: true`，重复调用必须安全（§8.2）；`idempotency_key` 是确保方式之一。

---

## 附录 B. 完整工具示例

参考 `redmine_create_issue`。当错误格式或封装变更时，更新 §7、§10 和本节；§12 保持 abbreviated。

```json
{
  "name": "redmine_create_issue",
  "title": "Create Redmine issue",
  "description": "Create one issue in a Redmine project. Use redmine_list_project_trackers and redmine_list_project_issue_custom_fields when valid IDs are unknown. This operation may create notifications and is not idempotent unless idempotency_key is supplied.",
  "inputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "project": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
        "examples": ["1", "ecookbook"]
      },
      "subject": {
        "type": "string",
        "minLength": 1,
        "maxLength": 255,
        "description": "Issue subject."
      },
      "description": {
        "type": "string",
        "maxLength": 100000,
        "description": "Issue description in Redmine text format."
      },
      "tracker_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Tracker ID returned by redmine_list_project_trackers.",
        "examples": [1, 2]
      },
      "priority_id": {
        "type": "integer",
        "minimum": 1,
        "description": "Issue priority ID returned by redmine_list_issue_priorities.",
        "examples": [3, 4]
      },
      "assigned_to_id": {
        "type": "integer",
        "minimum": 1,
        "description": "User ID of the assignee, from redmine_list_project_members."
      },
      "due_date": {
        "type": "string",
        "format": "date",
        "description": "Due date in YYYY-MM-DD format.",
        "examples": ["2026-07-30"]
      },
      "custom_fields": {
        "type": "array",
        "maxItems": 100,
        "items": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "id": {"type": "integer", "minimum": 1},
            "value": {
              "oneOf": [
                {"type": "string"},
                {"type": "number"},
                {"type": "boolean"},
                {
                  "type": "array",
                  "items": {"type": "string"}
                }
              ]
            }
          },
          "required": ["id", "value"]
        }
      },
      "idempotency_key": {
        "type": "string",
        "minLength": 8,
        "maxLength": 128
      }
    },
    "required": ["project", "subject"]
  },
  "outputSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ok": {"type": "boolean"},
      "data": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "id": {"type": "integer"},
          "url": {"type": "string", "format": "uri"},
          "created_at": {"type": "string", "format": "date-time"}
        },
        "required": ["id", "url", "created_at"]
      },
      "error": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "code": {"type": "string"},
          "message": {"type": "string"},
          "field": {
            "oneOf": [
              {"type": "string"},
              {"type": "null"}
            ]
          },
          "retryable": {"type": "boolean"}
        },
        "required": ["code", "message", "retryable"]
      }
    },
    "required": ["ok"],
    "oneOf": [
      {
        "properties": {"ok": {"const": true}},
        "required": ["data"],
        "additionalProperties": true,
        "not": {"required": ["error"]}
      },
      {
        "properties": {"ok": {"const": false}},
        "required": ["error"],
        "additionalProperties": true,
        "not": {"required": ["data"]}
      }
    ]
  },
  "annotations": {
    "readOnlyHint": false,
    "destructiveHint": false,
    "idempotentHint": false,
    "openWorldHint": false
  },
  "execution": {
    "taskSupport": "forbidden"
  }
}
```

注：若服务器在存在 `idempotency_key` 时保证 idempotency，annotation 仍描述 tool 整体。因此若允许无 key 的调用，安全值仍为 `false`。

