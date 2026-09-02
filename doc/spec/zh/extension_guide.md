# Redmine 插件的 MCP 扩展

[Deutsch](../de/extension_guide.md) | [English](../en/extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](extension_guide.md)

`redmine_mcp` 允许其他 Redmine 插件添加自己的 MCP 工具，并在需要时注册资源、提示和能力，无需单独的 MCP 服务器，也无需修改 `redmine_mcp` 本身。

## 工作原理

`redmine_mcp` 提供共享的 MCP Registry，第三方 Redmine 插件通过 `RedmineMcp::ExtensionApi` 注册工具。

典型的调用流程如下：

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` 不应了解第三方插件的业务逻辑：插件通过 Extension API 自行注册工具。

## 稳定性与向后兼容性

自 `redmine_mcp 1.0.0` 起，公共 Extension API 被视为稳定。

只有本指南中描述的 `RedmineMcp::ExtensionApi` 的方法和约定属于公共 API。`redmine_mcp` 中未在 Extension API 文档中说明的内部类、模块和方法不属于公共 API，可能在不保证向后兼容的情况下变更。

在 `redmine_mcp` 的同一主版本内：

- 现有的公共 Extension API 方法不会被移除或以不兼容方式修改；
- 可以添加新方法和可选参数；
- 已弃用的方法会先被标记，并至少保留到下一个主版本；
- 需要第三方插件更新的变更仅在新主版本中发布。

所有 Extension API 变更均列于 `CHANGELOG.md`。

建议第三方插件声明所需的最低 `redmine_mcp` 版本，并在升级时查阅 `CHANGELOG.md`。

## 快速入门

1. 在以下路径之一创建 `mcp.rb` 文件：
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - 若 `plugin.id` 以 `redmine_` 开头，则为 `lib/<去掉 redmine_ 前缀的 plugin.id>/mcp.rb`
2. 定义 `<PluginName>::Mcp` 模块。
3. 扩展 `RedmineMcp::ExtensionApi`。
4. 设置 `plugin_id`。
5. 注册第一个工具。

最小化的议题范围扩展示例：

```ruby
module RedmineMyPlugin
  module Mcp
    extend RedmineMcp::ExtensionApi

    plugin_id :my_plugin

    register_issue_tool(
      name: 'get_plugin_data',
      title: 'Get plugin data',
      description: 'Returns plugin data for an issue.',
      output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
        type: 'object',
        properties: {
          issue_id: {type: 'integer', minimum: 1}
        },
        required: ['issue_id']
      ),
      permission: :view_issues,
      annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS
    ) do |issue, _args, _context|
      {issue_id: issue.id}
    end
  end
end
```

该示例使用 `register_issue_tool`，这是处理议题相关工具的推荐辅助方法。完整工具约定见 [mcp_tool_development.md](mcp_tool_development.md)。

### `Mcp` 模块名称

扩展文件为 `mcp.rb`。Zeitwerk 根据该文件名推断 `Mcp`，因此应编写 `module Mcp`。

工具在文件被 require 时注册。加载器不会查找模块常量名称。

## 命名

对于工具和提示，使用简短名称：

```ruby
name: 'search_issues'
```

完整的 MCP 名称会自动生成：

```text
redmine_<plugin_id>_<name>
```

对于工具，建议 `name` 采用 `<verb>_<entity>` 格式。

推荐动词：

`get`、`list`、`search`、`create`、`update`、`set`、`delete`、`add`、`remove`、`copy`、`upload`、`download`、`send`、`summarize`。

不要使用含义模糊的 `manage_*`、`process_*`、`handle_*`，也不要在操作可以拆分为独立、清晰工具时使用类似 `action: create | update | delete` 的参数。

例如：

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

若 `plugin_id` 已以 `redmine_` 开头（例如 `redmine_advanced_checklists`），完整名称仍遵循 `redmine_<plugin_id>_<name>`：`redmine_redmine_advanced_checklists_<name>`。

对于资源，使用唯一 URI，例如：

```text
redmine://<plugin_id>/<type>/<id>
```

工具/提示名称和资源 URI 必须唯一。重复注册的行为取决于所使用的方法；`register_tool_once` 不会重复注册同一工具。

## 注册工具

### 常规工具

当需要不绑定特定议题的常规 MCP 工具时，使用 `register_tool_once`。

典型场景：

- 搜索插件数据；
- 返回摘要；
- 服务端验证或计算。

基本示例：

```ruby
register_tool_once(
  name: 'get_summary',
  title: 'Get plugin summary',
  description: 'Returns plugin summary.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {}
  },
  output_schema: RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    additionalProperties: false,
    properties: {
      summary: {type: 'string'}
    },
    required: ['summary']
  ),
  permission: :view_issues,
  annotations: RedmineMcp::Core::Helpers::READ_ONLY_ANNOTATIONS,
  handler: lambda { |_args, _context| {summary: 'ok'} }
)
```

完整工具约定——`additionalProperties: false`、风险注解以及通过 `SchemaNormalizer.envelope_output` 构建的封装——见 [mcp_tool_development.md](mcp_tool_development.md)。

### 议题工具

当工具接受 `issue_id` 并处理议题时，使用 `register_issue_tool`。

这是议题范围场景的推荐选项，因为它会：

- 通过 `Issue.visible(user)` 查找议题；
- 在需要时检查项目模块；
- 在议题所属项目中检查指定权限；
- 将找到的 `issue` 传入块；
- 若议题不可用或未找到，则返回错误。

另见「权限」一节。

`register_issue_tool` 中的 `module_name` 是可选的 Redmine 项目模块标识符，不必与 `plugin_id` 一致。若已设置，仅当用户能在至少一个启用该模块的项目中看到声明的权限时，工具才会出现在 `tools/list` 中。

### 处理程序的返回值

处理程序返回不含封装的成功数据哈希，或返回现成的封装 `{ok: true, data: ...}` / `{ok: false, error: ...}`。Registry 通过 `ToolResponse.from_handler_result` 规范化结果：普通哈希会被包装为 `{ok: true, data: ...}`；对于列表，可以返回 `paginated_list` 的现成结果，其中已包含 `data` 和 `meta`。

对于错误，使用 `RedmineMcp::Core::Helpers.error_result`、`mcp_error` 或 `{ok: false, error: ...}`。

## 输入 schema

`SchemaNormalizer.normalize_input` 会规范化对象 schema 并添加服务约束，但公共参数约定必须显式描述。

主要规则：

- 每个参数必须有明确的类型；
- 数值型 `*_id` 字段使用 `type: integer`、`minimum: 1`，并在描述中注明发现路径；
- 有限值集合通过 `enum` / `const` 定义，而不仅写在正文中；
- 数组必须有 `items`；
- 相互依赖和互斥字段通过 JSON Schema（`oneOf`、`if/then/else` 等）定义，而不仅写在描述中；
- 乐观锁使用 `expected_updated_at`，而非 `updated_at`；
- `null` 仅在与显式文档化的语义一起使用时采用，例如用于清空字段；
- 不要使用开放的 `fields`、`payload` 或 `data` 代替类型化的业务参数；
- 不要接受 JSON 字符串形式的对象；
- 不要在公共工具中接受任意 `file_path`。

完整的 `inputSchema` 要求见 [mcp_tool_development.md](mcp_tool_development.md)。

## 输出 schema

每个新工具都必须有 `output_schema`。

对于常规结果，使用标准封装：

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

对于列表，使用 `SchemaNormalizer.list_envelope_output(item_schema)`。

已知且稳定的结果字段必须显式描述。当响应结构已知时，不要使用 `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` 代替类型化约定。这些 schema 仅适用于真正开放或不稳定的结构。

完整的 `outputSchema` 要求见 [mcp_tool_development.md](mcp_tool_development.md)。

## 注解

| 操作类型 | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | 取决于实现 | `false` |
| delete / purge | `false` | `true` | 仅当重复调用确实安全时 | `false` |
| 外部副作用 | `false` | 视情况而定 | 通常为 `false` | `true` |

`destructive` 表示不可逆的数据丢失，而非任何写入操作。

`open_world` 表示超出已知 Redmine 安装范围，而非在 Redmine 内部创建新对象。

注解不能替代处理程序中的权限检查。

## 权限

`permission` 由 Registry 用于工具可用性和初步检查，但不能替代处理程序内对特定对象的访问检查。

对于议题范围工具，使用 `register_issue_tool`，它会检查议题可见性、项目模块和权限。

对于其他实体，处理程序必须重新检查对已找到对象的访问权限。

## 错误

使用标准 MCP 错误代码：

`VALIDATION_ERROR`、`NOT_FOUND`、`FORBIDDEN`、`CONFLICT`、`RATE_LIMITED`、`REDMINE_API_ERROR`、`TIMEOUT`、`FILE_TOO_LARGE`、`UNSUPPORTED_MEDIA_TYPE`、`INVALID_STATE`、`PARTIAL_FAILURE`、`INTERNAL_ERROR`。

对于标准错误，使用 `error_result` 辅助方法。
对于自定义代码，使用 `mcp_error`。
对于乐观锁，使用 `conflict_if_stale`。

处理程序返回结构化错误，而非堆栈跟踪或未处理的异常。

## 内置辅助方法

`RedmineMcp::Core::Helpers` 包含应复用而非重复实现的共享辅助方法：

- `find_project`
- `any_project_allows?`
- `resolve_user_ref`
- `clamp_limit` / `clamp_offset`
- `paginated_list` / `paginate_collection`
- `integer_id`
- `serialize_named_ref`
- `error_result`
- `mcp_error`
- `model_errors`
- `conflict_if_stale`
- `truthy?`

还提供现成的 schema 片段：

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

在创建自己的辅助方法之前，请检查 `redmine_mcp` 中是否已有合适的方法。

在 `RedmineMcp::Core::Helpers` 和 [04-extensions.md](04-extensions.md) 中查看当前辅助方法集合：该列表展示主要可用能力，不能替代 ExtensionApi API 文档。

## 只读模式与幂等性

变更类工具必须遵守全局只读模式：

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

对于重复调用可能产生重复结果的操作，可以使用 `idempotency_key` 和 `RedmineMcp::IdempotencyStore`。

仅当考虑到所有副作用后重复调用确实安全时，才允许 `idempotentHint: true`。

## 代码组织

`mcp.rb` 应主要包含工具注册：schema、描述、权限、注解和简短处理程序。

MCP 专用的获取、聚合和数据规范化可以移至：

- `mcp_tools.rb`；
- 当文件变大时——`mcp_tools/*.rb`。

常规业务逻辑应保留在插件的 model/service 中，且不得依赖 MCP。

若插件已有合适的 REST 端点，实现了所需操作并支持代表当前用户调用，则应通过 `internal_request`（只读 `GET` 调用可使用 `internal_get`）复用。

这是首选方案：MCP 使用与现有插件 API 相同的权限检查、数据获取和业务行为。

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

对于 `POST`、`PUT` 和 `PATCH`，传入 JSON 请求体字符串（若端点不需要请求体则传 `nil`）。查询参数放在 `params` 中。

在以下情况下直接调用 model/service：

- 没有合适的 REST 端点；
- 端点不支持所需操作或数据；
- 使用 REST 会为该操作引入不必要或不正确的层次；
- 共享业务逻辑已有意提取到 service 中，而 REST 端点本身只是该 service 的薄封装。

不要为 REST 和 MCP 分别实现相同的业务逻辑。若两层都需要共享逻辑，应将其提取到公共 service 中。

## 附加能力

`RedmineMcp::ExtensionApi` 还提供：

| 方法 | 使用场景 |
|---|---|
| `register_resource` | 需要 MCP 资源时 |
| `register_prompt` | 需要 MCP 提示时 |
| `register_capability` | 需要向 `redmine_get_mcp_info` 添加能力时 |
| `extend_tool` | 需要扩展现有工具而非创建新工具时 |
| `on` | 需要生命周期钩子时 |
| `internal_request` | 需要以当前用户身份在进程内调用 Redmine 或插件 REST 端点时（`method`、`path`，可选 `params` 和 `body`） |
| `internal_get` | `internal_request(method: 'GET', ...)` 的简写 |
| `internal_request_error?` | 检查进程内 REST 结果是否为 MCP 错误封装 |

在模块顶部设置一次 `plugin_id`。在注册工具之前，若扩展自行执行注册，应检查 `mcp_extension_enabled?`。标准的 `ExtensionLoader` 也不会为已禁用的扩展加载 `mcp.rb`。

### 扩展现有工具

仅当单独的工具不合适时，才使用 `extend_tool`。

```ruby
extend_tool(
  'redmine_search_issues',
  extra_params: {
    semantic_hint: {
      type: 'string',
      description: 'Optional semantic hint for ranking.'
    }
  }
)
```

`before` 在处理程序之前运行，`after` 在其之后运行。`extra_params` 会添加到输入 schema 中。参数名称不得与基础工具或该工具的其他扩展冲突。

若扩展在插件的 `after_initialize` 中被 require，且此时 `redmine_mcp` 尚未注册核心工具，则应将核心工具的 `extend_tool`（例如 `redmine_get_issue`）推迟到初始化完成之后——使用嵌套的 `Rails.application.config.after_initialize`，并先检查 `Registry.instance.tool(...)`。

## 加载与禁用扩展

`redmine_mcp` 在 Redmine 启动时会自动在支持的路径中查找扩展文件。

仅在 `mcp.rb` 入口点（通常为 `lib/<plugin>.rb` 或插件加载器的 `after_initialize`）检查 `redmine_mcp`。仅从 `mcp.rb` 加载的文件（`mcp_tools.rb`、`mcp_tools/*.rb` 等）不应重复相同检查。

不要从第三方插件手动调用 `ExtensionLoader.load_plugin_extension`：`ExtensionLoader` 是 `redmine_mcp` 的内部机制。有条件地 `require` 你的 `mcp.rb` 即可；若插件加载顺序导致该 `require` 未执行，标准的 `redmine_mcp` `ExtensionLoader` 会作为后备。

入口点示例：

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

扩展仅在以下条件下注册：

- 在 `redmine_mcp` 设置中启用了 MCP；
- 找到了 `mcp.rb` 文件；
- `mcp.rb` 中的 `<PluginName>::Mcp` 模块加载正确；
- 扩展未在「MCP extensions」列表中禁用。

安装新扩展或修改 `mcp.rb` 后，通常需要重启 Redmine。之后 MCP 客户端可能需要重新连接。在某些应用（如 Cursor）中，仅重新加载 MCP 服务器不足以获取新工具：若工具未出现，请完全重启应用。

## 验证扩展

实现后，通过真实的 MCP 调用验证工具，不仅检查处理程序，还要检查：

- 在 `tools/list` 中的注册；
- 输入 schema；
- 权限；
- 输出封装；
- 错误。

检查 Redmine 日志中的工具注册和扩展加载错误。

对于每个新工具，至少应包含：

- 一个成功的 schema 场景；
- 一个负向 schema 场景。

详细的自动化测试要求见 [mcp_tool_development.md](mcp_tool_development.md)（§13）。

### 扩展自动化测试

插件 MCP 扩展的自动化测试必须覆盖**完整的 Registry 路径**（`inputSchema` 验证 → 权限 → 处理程序 → `{ok, data | error}` 封装），而不仅直接调用处理程序。

若未安装或未加载 `redmine_mcp`，测试类应**跳过**场景（在 `setup` 中使用 `skip`），而不是在加载文件时失败：

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

在测试 `setup` 中，调用 `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` 以在 `Registry` 中注册工具是可以接受的。不要在插件生产代码中调用 `ExtensionLoader`（见「加载与禁用扩展」）。

要将实际响应与已发布的 `outputSchema`（`mcp_tool_development.md` §7.1）进行比较，使用 `json_schemer`——与 `RedmineMcp::InputValidator` 应用于输入 schema 的库相同。

允许在测试辅助方法中延迟加载 `json_schemer`。若环境中没有该库，必须显式跳过检查，以免插件测试因可选依赖而失败。

只读扩展工具的最小自动化测试：

- 一次成功的 Registry 调用，并验证 `outputSchema`；
- 一次被 `inputSchema` 拒绝的负向调用（例如违反 `oneOf`、enum 或 `maxItems`）；
- 必要时——单独的服务端验证测试（schema 不能替代服务端检查；见 `mcp_tool_development.md` §3.4）。

## 故障排除

| 问题 | 检查项 |
|---|---|
| 扩展未加载 | `mcp.rb` 路径、模块名 `Mcp`、MCP 是否启用、Rails 日志 |
| 工具/资源/提示未出现 | 是否设置了 `plugin_id`、扩展是否被禁用、名称或 URI 冲突、用户是否拥有所需权限 |
| 修改后变更未生效 | 重启 Redmine；在 Cursor 等客户端中，重新加载 MCP 服务器可能无法获取新工具——请完全重启应用 |
| `extend_tool` 不工作 | 基础工具是否已注册、`extra_params` 是否与现有 schema 冲突 |

### 合并前检查清单

- [ ] 工具具有 `title`、`description`、`input_schema`、`output_schema`、`permission` 和 `annotations`。
- [ ] 每个 `*_id` 都有发现路径。
- [ ] 描述、`output_schema` 和实际响应一致。
- [ ] 变更类工具遵守只读模式。
- [ ] MCP 专用逻辑未在 lambda/处理程序中膨胀。
- [ ] 复用 `redmine_mcp` 的共享辅助方法，而非复制。
- [ ] 至少运行过一个成功和一个负向 schema 场景。
