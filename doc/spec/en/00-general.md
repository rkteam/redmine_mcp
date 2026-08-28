# Redmine MCP — general specification

[Deutsch](../de/00-general.md) | [English](00-general.md) | [Español](../es/00-general.md) | [Français](../fr/00-general.md) | [Italiano](../it/00-general.md) | [日本語](../ja/00-general.md) | [한국어](../ko/00-general.md) | [Polski](../pl/00-general.md) | [Português (Brasil)](../pt-BR/00-general.md) | [Русский](../ru/00-general.md) | [中文](../zh/00-general.md)

## Overview

The Redmine MCP plugin provides an MCP server (Model Context Protocol) inside a Redmine installation. AI clients connect to a single HTTP endpoint and access Redmine data through tools, resources, and prompts.

The plugin includes a base set of tools for working with projects, issues, and users. Other installed Redmine plugins can extend MCP without changing Redmine MCP code.

## Goal

Provide a single integration mechanism between Redmine and AI systems where:

- the user operates within their Redmine permissions;
- plugin developers can add their own MCP capabilities;
- no separate MCP server or installation-specific fork is required.

## Main scenarios

1. **Connecting an AI client** — an administrator enables MCP, grants the `use_mcp` permission to the required roles, and issues an API key; the user connects a client (Cursor, etc.) to the `/mcp` endpoint.
2. **Working with Redmine data** — the client calls tools to fetch projects, issues, and users.
3. **Extension by other plugins** — when a plugin with an MCP extension is installed, its tools automatically appear in the shared list.
4. **Administration** — enabling/disabling MCP and enabling MCP integration for individual plugins.

## Affected areas

- API (MCP over HTTP)
- Permissions
- Settings
- Issues
- Projects
- Users
- Boards
- Plugins (extensions)

## Business rules

- MCP is available only when explicitly enabled in the plugin settings.
- All operations run on behalf of the authenticated Redmine user.
- Writes through MCP go through Redmine models: model callbacks run. Controller hooks (`controller_issues_*_save`, `controller_journals_edit_post`, etc.) are not invoked by MCP.
- Data visibility follows Redmine rules: the user does not receive more than they can see in the web UI.
- Tool and prompt names use the format `<plugin_id>_<name>`, for example `redmine_list_projects`.
- Core tool `title` and `description` are published in English for LLM selection and are **not localized** through `en.yml`/`ru.yml` (an exception to the i18n standard for the MCP tool catalog). Error messages and settings UI are localized.
- Extensions from other plugins do not create a hard dependency: if Redmine MCP is absent, the third-party plugin continues to work.

## Edge cases

- When MCP is disabled, all requests to `/mcp` are rejected.
- When one extension fails, other extensions and core tools continue to work.
- New tools from extensions become available after a Redmine restart; the MCP client may need to reconnect to refresh the tool list.
- In stateless mode, each HTTP request is handled independently; no session is preserved between requests.

## Error handling

- Authentication and authorization errors are returned at the HTTP level.
- Tool execution errors are returned in MCP format with an error flag.
- Extension load errors are logged and do not block Redmine startup.

## Specification files

| File | Content |
|------|---------|
| [console-commands.md](console-commands.md) | Installation, verification, and maintenance commands |
| [01-mcp-server.md](01-mcp-server.md) | HTTP endpoint, MCP protocol, transport |
| [02-authentication.md](02-authentication.md) | Authentication and access control |
| [03-core-tools.md](03-core-tools.md) | Built-in Redmine tools |
| [04-extensions.md](04-extensions.md) | Extension API for other plugins |
| [05-settings.md](05-settings.md) | Plugin settings and logging |
| [mcp_tool_development.md](mcp_tool_development.md) | MCP tool development requirements (dev-guide) |
| [extension_guide.md](extension_guide.md) | Extension developer guide |

## Test scenarios

1. After installation and enabling MCP, the client successfully runs `initialize` and receives server information.
2. A user with the Use MCP permission and a valid API key sees the list of tools available to them.
3. A user without the Use MCP permission is denied access to `/mcp`.
4. When an extension plugin is installed, its tools are present in `tools/list` for a user with the corresponding permissions.
