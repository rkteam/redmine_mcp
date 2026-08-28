# Extension API for other plugins

[Deutsch](../de/04-extensions.md) | [English](04-extensions.md) | [Español](../es/04-extensions.md) | [Français](../fr/04-extensions.md) | [Italiano](../it/04-extensions.md) | [日本語](../ja/04-extensions.md) | [한국어](../ko/04-extensions.md) | [Polski](../pl/04-extensions.md) | [Português (Brasil)](../pt-BR/04-extensions.md) | [Русский](../ru/04-extensions.md) | [中文](../zh/04-extensions.md)

## Overview

Redmine MCP provides an extension mechanism that lets other installed Redmine plugins register their own tools, resources, and prompts, and extend existing tools.

## Goal

Provide a single approach to integrating Redmine plugins with AI without duplicating an MCP server and without changing Redmine MCP code.

## Affected areas

- Plugins
- API
- Permissions

## Business rules

### Automatic discovery

- On Redmine startup (when MCP is enabled), the system checks all installed plugins.
- A plugin is considered to have an MCP extension if it contains an `mcp.rb` file at one of these paths:
  - `lib/<plugin.id>/mcp.rb`;
  - `lib/<plugin directory basename>/mcp.rb`;
  - `lib/<plugin.id without redmine_ prefix>/mcp.rb` if the identifier starts with `redmine_` (typical scheme like `redmine_advanced_checklists` → `lib/advanced_checklists/mcp.rb`).
- The `redmine_mcp` plugin does not load itself as an extension.
- Plugins whose MCP extension checkbox is unchecked in settings are skipped.
- A failure in one plugin's extension does not block loading others, including a syntax error in the extension file.

### Tool registration

- An extension plugin may register any number of tools.
- Each tool has: name, description, input schema, output schema, permission requirement, and handler.
- Full tool name: `redmine_<plugin_id>_<name>`, for example `redmine_redmine_advanced_checklists_get_issue_checklists`, `redmine_advanced_search_semantic_search_issues`.
- Duplicate tool names are forbidden.
- A tool appears in MCP only for users with the corresponding permissions.
- An issue-scoped extension tool may require an enabled Redmine project module (the module identifier does not have to match the plugin id). In `tools/list`, such a tool is visible if the user has the declared permission in at least one visible project with that module. Without a module requirement, permission in at least one visible project is enough. The call still checks the specific issue: visibility, permission in its project, and enabled module; otherwise the response is "not found".
- Extension write tools in MCP read-only mode do not run the handler: denial is the same as for core write tools.

### Extending existing tools

- A plugin may extend an already registered tool.
- An extension may:
  - add extra input parameters;
  - run code before the main handler;
  - run code after the handler and modify the result.
- Multiple plugins may extend the same tool at once.
- Extra parameters are merged into the shared input schema.
- An extra parameter name must not match a core tool parameter or another extension's parameter for the same tool.
- The resulting schema is normalized before publication in `tools/list`.
- Extension execution order matches plugin load order.

### Resource registration

- A plugin may publish resources with a unique URI. Re-registering the same URI is rejected.
- A resource must have a read handler.
- Recommended URI scheme: `redmine://<plugin_id>/<type>/<id>`.
- A resource may require permission checks; without permission the resource is unavailable.
- Permission checks receive the URI and arguments. The project is taken from `project` / `project_id`, from the URI (`project`/`project_id` in query or `/projects/:id` segment), or from an explicit project resolver defined by the extension. `resources/read` passes `{uri: ...}` to the check.
- If a project is specified in the call but not found or not accessible to the current user, access is denied. The "at least one project" check applies only when no project is specified (discovery with empty arguments).
- Reading a resource returns content in text or JSON format.

### Prompt registration

- A plugin may add prompts with name, description, arguments, and handler.
- Full prompt name: `redmine_<plugin_id>_<name>`.
- Prompts are available to users with the corresponding permissions. Permission checks receive call arguments, including `project` / `project_id`. If a project is specified but not found or not accessible, access is denied; without a specified project the same discovery rule as for resources applies.

### Events (hooks)

- A plugin may subscribe to MCP lifecycle events, for example:
  - tool registration;
  - resource registration;
  - prompt registration;
  - completion of loading all extensions.
- An error in an event handler is logged and does not interrupt the main process.

### Dependencies

- An extending plugin does not have to declare a hard dependency on Redmine MCP.
- It is recommended to check `RedmineMcp::ExtensionApi` / `mcp_extension_enabled?` before registration.
- The extending plugin does not need to include the MCP gem — Redmine MCP API is enough.

### Extension API capabilities

Through Extension API, an extension plugin can:

- verify that MCP is enabled and the extension is not disabled;
- register a tool once (without duplication on reload);
- register an issue-scoped tool with standard permission checks and issue lookup; if the issue disappeared before the handler runs, the response is "not found", not an internal error;
- extend an existing core tool with parameters and before/after handlers;
- register capability modes for `redmine_get_server_info` (for example `issue_search.semantic`);
- call the Redmine or plugin REST API in-process on behalf of the current user through `internal_request` (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`; the target endpoint must accept API auth); REST errors are mapped to canonical MCP codes without the internal request HTTP status;
- publish `outputSchema` in the `{ ok, data | error }` envelope format.

The Ruby API method list and code examples are in the plugin README and in [mcp_tool_development.md](mcp_tool_development.md) (a dev guide, not behavioral SPEC).

## Edge cases

- A plugin without an extension file is ignored.
- If an extension file exists but `require` fails — log entry, extension is not considered loaded; tool registration is a side effect of a successful `require`.
- Attempting to extend a non-existent tool — error during extension registration.
- A plugin with the MCP extension checkbox unchecked in settings is not loaded even if the extension file exists.
- After installing a new extension, a Redmine restart is required; the MCP client may need to reconnect.

## Error handling

- Extension file load error — log entry, continue loading other plugins.
- Tool registration error at startup — log entry.
- Error in an extension `before` handler — aborts tool execution.
- Error in an `after` handler — logged; the main handler result is preserved unless the handler changed control flow.

## Test scenarios

8. Resource and prompt discovery with empty arguments remains available if permission exists in at least one project.
9. A plugin with `plugin.id` like `redmine_*` and file `lib/<id without redmine_ prefix>/mcp.rb` is considered to have MCP integration and appears in MCP extension settings.
10. An issue-scoped tool with a module requirement is not in `tools/list` for a user without any visible project with that module, even if they have the permission on another project.

## Extension examples

| Plugin | Tool | Purpose |
|--------|------------|------------|
| `advanced_search` | `semantic_search_issues` | Semantic issue search |
