# Settings and logging

[Deutsch](../de/05-settings.md) | [English](05-settings.md) | [Español](../es/05-settings.md) | [Français](../fr/05-settings.md) | [Italiano](../it/05-settings.md) | [日本語](../ja/05-settings.md) | [한국어](../ko/05-settings.md) | [Polski](../pl/05-settings.md) | [Português (Brasil)](../pt-BR/05-settings.md) | [Русский](../ru/05-settings.md) | [中文](../zh/05-settings.md)

## Overview

The Redmine MCP plugin is configured through the standard Redmine plugin settings interface. MCP operation is additionally logged.

## Goal

Give the administrator control over enabling MCP and enabling MCP integration for individual plugins.

## Affected areas

- Settings
- UI
- Plugins

## Business rules

### Settings parameters

Settings are available in **Administration → Plugins → Redmine MCP → Configure**.

| Parameter | Default | Description |
|----------|--------------|----------|
| Enable MCP | off | Enables or disables the `/mcp` endpoint. When enabled, MCP extensions of installed plugins are loaded automatically |
| Read-only mode | off | Blocks write tools and write actions |
| MCP extensions | all enabled | Checkboxes next to names of installed plugins with MCP integration |

### MCP extensions in the UI

- A text field for a list of identifiers ("Disabled extensions") and a reference list of all installed plugins are not used.
- A separate auto-load extensions checkbox is not used.
- Instead, the settings page shows a list of installed plugins that have MCP integration.
- A plugin is considered to have MCP integration if it has an extension file using the same convention as auto-load (see [04-extensions.md](04-extensions.md)).
- The `redmine_mcp` plugin is not shown in this list.
- Each item has a checkbox and the plugin name.
- The list legend has a Check all / Uncheck all toggle, like projects and trackers on a custom field form.
- A checked box means the plugin's MCP extension is loaded when MCP is enabled.
- An unchecked box means the plugin's extension is not loaded even if the extension file exists.
- If no installed plugin has MCP integration, the list is empty: the standard Redmine "no data" message is shown; the Check all / Uncheck all toggle is hidden.
- Previously saved disabled plugin identifiers continue to apply: the corresponding checkboxes appear unchecked.

### Behavior when settings change

- Disabling MCP immediately blocks all requests to `/mcp` (HTTP 503).
- When MCP is enabled, extensions load on Redmine startup. When MCP is disabled, extension auto-load does not run.
- Changing MCP extension checkboxes takes effect after a Redmine restart.

## Logging

### What is logged

- start and end of extension loading;
- successful registration of tools, resources, prompts;
- extension of existing tools;
- registration and load errors for extensions;
- tool execution errors;
- MCP and tool access denials.

### Format

- Messages are written to the standard Rails log.
- Each message has the `[redmine_mcp]` prefix.
- A separate logging level setting is not used: the plugin writes all its messages.

## Edge cases

- If all MCP extension checkboxes are enabled (or no plugin has integration), all found extensions load when MCP is enabled.
- A plugin without an MCP extension file is not shown in the list and is not disabled by these settings.
- If a plugin later gains MCP integration, its checkbox is enabled by default unless the plugin was previously disabled.
- Unknown or removed plugin identifiers in saved disabled lists are ignored.
- A previously saved extension auto-load flag is ignored: extension loading follows Enable MCP.
- A previously saved logging level is ignored and removed when settings are saved.
- With Read-only mode enabled, write tools remain in `tools/list` (if the user has permissions) but return an error when called; read actions of combined tools continue to work.

## Error handling

- Settings errors must not block Redmine startup.
- Logging errors do not affect MCP request processing.

## Test scenarios

1. MCP disabled — requests to `/mcp` return HTTP 503.
2. MCP enabled — requests are processed.
3. A plugin with MCP integration unchecked — its tools are absent after restart.
4. The settings page has no logging level field; MCP messages are written to the Rails log.
5. The settings page shows names of only installed plugins with MCP integration; each has a checkbox.
6. A plugin without MCP integration is not shown on the settings page.
7. When MCP is disabled, extensions from other plugins are not loaded on startup.
