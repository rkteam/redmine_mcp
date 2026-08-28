# MCP extensions for Redmine plugins

[Deutsch](../de/extension_guide.md) | [English](extension_guide.md) | [Español](../es/extension_guide.md) | [Français](../fr/extension_guide.md) | [Italiano](../it/extension_guide.md) | [日本語](../ja/extension_guide.md) | [한국어](../ko/extension_guide.md) | [Polski](../pl/extension_guide.md) | [Português (Brasil)](../pt-BR/extension_guide.md) | [Русский](../ru/extension_guide.md) | [中文](../zh/extension_guide.md)

`redmine_mcp` lets other Redmine plugins add their own MCP tools and, if needed, register resources, prompts, and capabilities without a separate MCP server and without changes to `redmine_mcp` itself.

## How it works

`redmine_mcp` provides a shared MCP Registry where third-party Redmine plugins register tools through `RedmineMcp::ExtensionApi`.

A typical call flows like this:

```text
client → tools/list
client → tools/call {name, arguments}
        → Registry validates arguments against the schema
        → checks permission
        → invokes the handler
        → builds the standard MCP response
```

`redmine_mcp` must not know the business logic of a third-party plugin: the plugin registers its own tools through the Extension API.

## Stability and backward compatibility

Starting with `redmine_mcp 1.0.0`, the public Extension API is considered stable.

Only methods and contracts of `RedmineMcp::ExtensionApi` described in this guide are public API. Internal classes, modules, and methods of `redmine_mcp` that are not documented as part of the Extension API are not public API and may change without backward compatibility guarantees.

Within a single major version of `redmine_mcp`:

- existing public Extension API methods are not removed or changed incompatibly;
- new methods and optional parameters may be added;
- deprecated methods are marked first and remain available at least until the next major version;
- changes that require updates in third-party plugins are released only in a new major version.

All Extension API changes are listed in `CHANGELOG.md`.

Third-party plugins are recommended to declare the minimum `redmine_mcp` version they require and to review `CHANGELOG.md` when upgrading.

## Quick start

1. Create an `mcp.rb` file in one of these paths:
   - `lib/<plugin.id>/mcp.rb`
   - `lib/<plugin_directory_basename>/mcp.rb`
   - `lib/<plugin.id without the redmine_ prefix>/mcp.rb` if `plugin.id` starts with `redmine_`
2. Define the `<PluginName>::Mcp` module.
3. Extend `RedmineMcp::ExtensionApi`.
4. Set `plugin_id`.
5. Register the first tool.

Minimal issue-scoped extension example:

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

The example uses `register_issue_tool`, the recommended helper for tools that work with issues. The full tool contract is in [mcp_tool_development.md](mcp_tool_development.md).

### The `Mcp` module name

The extension file is `mcp.rb`. Zeitwerk infers `Mcp` from that filename, so write `module Mcp`.

Tools are registered when the file is required. The loader does not look up the module constant name.

## Naming

For tools and prompts, use a short name:

```ruby
name: 'search_issues'
```

The full MCP name is generated automatically:

```text
redmine_<plugin_id>_<name>
```

For tools, prefer `name` in the `<verb>_<entity>` format.

Preferred verbs:

`get`, `list`, `search`, `create`, `update`, `set`, `delete`, `add`, `remove`, `copy`, `upload`, `download`, `send`, `summarize`.

Do not use vague `manage_*`, `process_*`, `handle_*`, or tools with a parameter like `action: create | update | delete` when the operations can be split into separate, clear tools.

For example:

```text
plugin_id :advanced_search
name: 'semantic_search_issues'

-> redmine_advanced_search_semantic_search_issues
```

If `plugin_id` already starts with `redmine_` (for example `redmine_advanced_checklists`), the full name still follows `redmine_<plugin_id>_<name>`: `redmine_redmine_advanced_checklists_<name>`.

For resources, use a unique URI, for example:

```text
redmine://<plugin_id>/<type>/<id>
```

Tool/prompt names and resource URIs must be unique. Duplicate-registration behavior depends on the method used; `register_tool_once` does not register the same tool twice.

## Registering tools

### Regular tool

Use `register_tool_once` when you need a regular MCP tool that is not bound to a specific issue.

Typical cases:

- searching plugin data;
- returning a summary;
- server-side validation or computation.

Basic example:

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

The full tool contract — `additionalProperties: false`, risk annotations, and the envelope via `SchemaNormalizer.envelope_output` — is described in [mcp_tool_development.md](mcp_tool_development.md).

### Issue tool

Use `register_issue_tool` when the tool accepts `issue_id` and works with an issue.

This is the recommended option for issue-scoped scenarios because it:

- finds the issue through `Issue.visible(user)`;
- checks the project module when needed;
- checks the given permission in the issue's project;
- passes the found `issue` into the block;
- returns an error if the issue is unavailable or not found.

See also the Permissions section.

`module_name` in `register_issue_tool` is an optional Redmine project module identifier. It does not have to match `plugin_id`. If set, the tool appears in `tools/list` only when the user can see at least one project with that module and the declared permission.

### What the handler returns

The handler returns a success data hash without an envelope, or a ready-made envelope `{ok: true, data: ...}` / `{ok: false, error: ...}`. The Registry normalizes the result through `ToolResponse.from_handler_result`: a plain hash is wrapped into `{ok: true, data: ...}`; for lists you can return the ready-made result of `paginated_list`, which already contains `data` and `meta`.

For errors, use `RedmineMcp::Core::Helpers.error_result`, `mcp_error`, or `{ok: false, error: ...}`.

## Input schema

`SchemaNormalizer.normalize_input` normalizes the object schema and adds service constraints, but the public parameter contract must be described explicitly.

Main rules:

- every parameter must have a defined type;
- numeric `*_id` fields use `type: integer`, `minimum: 1`, and a description with a discovery path;
- finite value sets are defined through `enum` / `const`, not only in prose;
- arrays must have `items`;
- interdependent and mutually exclusive fields are defined through JSON Schema (`oneOf`, `if/then/else`, and so on), not only in the description;
- optimistic locking uses `expected_updated_at`, not `updated_at`;
- `null` is used only with explicitly documented semantics, for example to clear a field;
- do not use open `fields`, `payload`, or `data` instead of typed business parameters;
- do not accept an object as a JSON string;
- do not accept an arbitrary `file_path` in a public tool.

Full `inputSchema` requirements are in [mcp_tool_development.md](mcp_tool_development.md).

## Output schema

Every new tool must have an `output_schema`.

For a regular result, use the standard envelope:

```ruby
RedmineMcp::SchemaNormalizer.envelope_output(
  type: 'object',
  properties: {
    summary: {type: 'string'}
  },
  required: ['summary']
)
```

For lists, use `SchemaNormalizer.list_envelope_output(item_schema)`.

Known stable result fields must be described explicitly. Do not use `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA` instead of a typed contract when the response structure is known. These schemas are acceptable only for truly open or unstable structures.

Full `outputSchema` requirements are in [mcp_tool_development.md](mcp_tool_development.md).

## Annotations

| Operation type | read_only | destructive | idempotent | open_world |
|---|---|---|---|---|
| get / list / search | `true` | `false` | `true` | `false` |
| create / add | `false` | `false` | `false` | `false` |
| update / rename / set | `false` | `false` | depends on implementation | `false` |
| delete / purge | `false` | `true` | only if a repeat is actually safe | `false` |
| external side effect | `false` | depends | usually `false` | `true` |

`destructive` means irreversible data loss, not any write.

`open_world` means going beyond the known Redmine installation, not creating a new object inside Redmine.

Annotations do not replace permission checks in the handler.

## Permissions

`permission` is used by the Registry for tool availability and preliminary checks, but it does not replace access checks for a specific object inside the handler.

For issue-scoped tools, use `register_issue_tool`, which checks issue visibility, the project module, and the permission.

For other entities, the handler must re-check access to the found object.

## Errors

Use the standard MCP error codes:

`VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `CONFLICT`, `RATE_LIMITED`, `REDMINE_API_ERROR`, `TIMEOUT`, `FILE_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_STATE`, `PARTIAL_FAILURE`, `INTERNAL_ERROR`.

For standard errors, use the `error_result` helpers.
For a custom code, use `mcp_error`.
For optimistic locking, use `conflict_if_stale`.

The handler returns a structured error, not a stack trace or an unhandled exception.

## Built-in helpers

`RedmineMcp::Core::Helpers` contains shared helpers that should be reused instead of duplicated:

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

Ready-made schema fragments are also available:

- `PROJECT_SCHEMA`
- `USER_ID_SCHEMA`
- `USER_REF_SCHEMA`
- `ISSUE_ID_SCHEMA`
- `PAGINATION_INPUT`
- `EXPECTED_UPDATED_AT_SCHEMA`
- `IDEMPOTENCY_KEY_SCHEMA`

Before creating your own helper, check whether a suitable one already exists in `redmine_mcp`.

Check the current helper set in `RedmineMcp::Core::Helpers` and [04-extensions.md](04-extensions.md): this list shows the main available capabilities and does not replace the ExtensionApi API documentation.

## Read-only mode and idempotency

Mutating tools must respect the global read-only mode:

```ruby
blocked = RedmineMcp::Core::ReadOnly.guard_write!
return blocked if blocked
```

For operations where a repeated call may create a duplicate, you can use `idempotency_key` and `RedmineMcp::IdempotencyStore`.

`idempotentHint: true` is allowed only when a repeated call is actually safe considering all side effects.

## Code organization

`mcp.rb` should contain mostly tool registration: schemas, descriptions, permissions, annotations, and short handlers.

MCP-specific fetching, aggregation, and data normalization can be moved to:

- `mcp_tools.rb`;
- when the file grows — `mcp_tools/*.rb`.

Regular business logic should stay in the plugin's models/services and must not depend on MCP.

If the plugin already has a suitable REST endpoint that implements the needed operation and supports calls on behalf of the current user, you SHOULD reuse it through `internal_request` (or `internal_get` for read-only `GET` calls).

This is the preferred option: MCP uses the same permission checks, data fetching, and business behavior as the existing plugin API.

```ruby
result = internal_request(
  method: 'POST',
  path: '/my_plugin/items.json',
  user: context[:user],
  body: JSON.generate(item: {name: args[:name]})
)
return result if internal_request_error?(result)
```

For `POST`, `PUT`, and `PATCH`, pass a JSON request body string (or `nil` when the endpoint does not expect a body). Query parameters go in `params`.

Call a model/service directly when:

- there is no suitable REST endpoint;
- the endpoint does not support the needed operation or data;
- using REST creates an unnecessary or incorrect layer for the operation;
- the shared business logic is already intentionally extracted into a service and the REST endpoint itself is only a thin wrapper around that service.

Do not implement the same business logic separately for REST and MCP. If both layers need shared logic, extract it into a common service.

## Additional capabilities

`RedmineMcp::ExtensionApi` also provides:

| Method | When to use |
|---|---|
| `register_resource` | you need an MCP resource |
| `register_prompt` | you need an MCP prompt |
| `register_capability` | you need to add a capability to `redmine_get_server_info` |
| `extend_tool` | you need to extend an existing tool instead of creating a new one |
| `on` | you need a lifecycle hook |
| `internal_request` | you need to call a Redmine or plugin REST endpoint in-process as the current user (`method`, `path`, optional `params` and `body`) |
| `internal_get` | shorthand for `internal_request(method: 'GET', ...)` |
| `internal_request_error?` | check whether an in-process REST result is an MCP error envelope |

Set `plugin_id` once at the top of the module. Before registering tools, you SHOULD check `mcp_extension_enabled?` when registration is performed by the extension itself. The standard `ExtensionLoader` also does not load `mcp.rb` for disabled extensions.

### Extending an existing tool

Use `extend_tool` only when a separate tool is not a good fit.

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

`before` runs before the handler, `after` runs after it. `extra_params` are added to the input schema. Parameter names must not conflict with the base tool or with other extensions of that tool.

If the extension is required from a plugin's `after_initialize` before `redmine_mcp` registers core tools, defer `extend_tool` for a core tool (for example `redmine_get_issue`) until initialization finishes — use a nested `Rails.application.config.after_initialize` and check `Registry.instance.tool(...)` first.

## Loading and disabling an extension

`redmine_mcp` automatically looks for the extension file in the supported paths when Redmine starts.

Check for `redmine_mcp` only at the `mcp.rb` entry point (usually `lib/<plugin>.rb` or the plugin loader's `after_initialize`). Files loaded only from `mcp.rb` (`mcp_tools.rb`, `mcp_tools/*.rb`, etc.) must not repeat the same checks.

Do not call `ExtensionLoader.load_plugin_extension` manually from a third-party plugin: `ExtensionLoader` is an internal `redmine_mcp` mechanism. A conditional `require` of your `mcp.rb` is enough; if plugin load order prevented that `require`, the standard `redmine_mcp` `ExtensionLoader` acts as a fallback.

Entry point example:

```ruby
# lib/my_plugin.rb

Rails.application.config.after_initialize do
  require "#{File.dirname(__FILE__)}/my_plugin/mcp" if Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
end
```

The extension is registered only if:

- MCP is enabled in `redmine_mcp` settings;
- the `mcp.rb` file is found;
- the `<PluginName>::Mcp` module in `mcp.rb` loads correctly;
- the extension is not disabled in the `MCP extensions` list.

After installing a new extension or changing `mcp.rb`, Redmine usually needs a restart. The MCP client may then need to reconnect. In some applications, such as Cursor, reloading the MCP server is not enough to pick up new tools: if they do not appear, fully restart the application.

## Verifying an extension

After implementation, verify the tool through a real MCP call to check not only the handler, but also:

- registration in `tools/list`;
- input schema;
- permission;
- output envelope;
- errors.

Check the Redmine logs for tool registration and extension load errors.

For every new tool, at minimum:

- one successful schema scenario;
- one negative schema scenario.

Detailed automated test requirements are in [mcp_tool_development.md](mcp_tool_development.md) (§13).

### Extension automated tests

Automated tests for a plugin MCP extension MUST exercise the **full Registry path** (`inputSchema` validation → permission → handler → `{ok, data | error}` envelope), not only a direct handler call.

If `redmine_mcp` is not installed or not loaded, the test class **skips** scenarios (`skip` in `setup`) instead of failing while loading the file:

```ruby
def setup
  skip('redmine_mcp is not installed') unless Redmine::Plugin.installed?(:redmine_mcp) && defined?(RedmineMcp)
  # ...
end
```

In test `setup`, calling `RedmineMcp::ExtensionLoader.load_plugin_extension(Redmine::Plugin.find(:your_plugin))` is acceptable to register tools in `Registry`. Do not call `ExtensionLoader` from plugin production code (see “Loading and disabling an extension”).

To compare the actual response with the published `outputSchema` (`mcp_tool_development.md` §7.1), use `json_schemer` — the same library that `RedmineMcp::InputValidator` applies to input schemas.

Lazy loading of `json_schemer` inside a test helper is allowed. If the library is not available in the environment, the check must be explicitly skipped so plugin tests do not fail due to an optional dependency.

Minimum automated tests for a read-only extension tool:

- one successful Registry call with `outputSchema` validation;
- one negative call rejected by `inputSchema` (for example `oneOf`, enum, or `maxItems` violation);
- when needed — a separate handler-level server validation test (schema does not replace server-side checks; see `mcp_tool_development.md` §3.4).

## Troubleshooting

| Problem | What to check |
|---|---|
| Extension did not load | `mcp.rb` path, module name `Mcp`, whether MCP is enabled, Rails log |
| Tool/resource/prompt did not appear | whether `plugin_id` is set, whether the extension is disabled, name or URI collisions, whether the user has the required permissions |
| Changes did not appear after edits | restart Redmine; in Cursor and similar clients, reloading the MCP server may not pick up new tools — fully restart the application |
| `extend_tool` does not work | whether the base tool is registered, whether `extra_params` conflict with the existing schema |

### Pre-merge checklist

- [ ] The tool has `title`, `description`, `input_schema`, `output_schema`, `permission`, and `annotations`.
- [ ] Every `*_id` has a discovery path.
- [ ] Description, output_schema, and the actual response are consistent.
- [ ] A mutating tool respects read-only mode.
- [ ] MCP-specific logic does not grow inside a lambda/handler.
- [ ] Shared helpers are reused from `redmine_mcp`, not copied.
- [ ] At least one successful and one negative schema scenario have been run.
