---
name: redmine-mcp-plugin-integration
description: Integrate a Redmine plugin with redmine_mcp via Extension API — in the target plugin (mcp.rb) or as a built-in file in redmine_mcp (lib/redmine_mcp/extensions/).
---

# Integrating a Redmine Plugin with Redmine MCP

Use this skill when you need to add MCP integration for a Redmine plugin.

Two integration paths:

1. **Target plugin** — `lib/<...>/mcp.rb` in the third-party plugin (preferred when it can be modified).
2. **Built-in** — `lib/redmine_mcp/extensions/<plugin.id>.rb` inside `redmine_mcp` (when the third-party plugin cannot be modified).

Both paths use the same public `RedmineMcp::ExtensionApi`. Tool/resource/prompt contracts — in `extension_guide.md` and `mcp_tool_development.md`.

## Before You Start

Read these files in `redmine_mcp`:

- `doc/spec/en/extension_guide.md`;
- `doc/spec/en/mcp_tool_development.md`;
- if needed, `doc/spec/en/04-extensions.md`.

Also review the target plugin: models, services, controllers/API, permissions, project modules, settings, and tests.

Decide the path before coding (only if the user has not already specified it):

- Can the target plugin be changed? → path **A**.
- Cannot modify the target plugin? → path **B** only; do not edit the target plugin.

## Workflow

### 1. Analyze

Before making changes, determine:

- which scenarios should be exposed via MCP;
- which entities and relationships are involved;
- which permissions/modules restrict access;
- which existing business logic can be reused;
- which MCP tools/resources/prompts are needed;
- which integration path (A or B) applies.

Draft a short plan:

`path → tool → purpose → permission/scope → data source → side effects`.

### 2. Implement

Use the public `RedmineMcp::ExtensionApi` and follow `extension_guide.md` and `mcp_tool_development.md`.

Do not move business logic into the MCP layer: reuse the target plugin's existing services, models, and API.

If a correct implementation requires a capability that is not available in the Extension API, do not use internal `redmine_mcp` classes, monkey patches, or other workarounds. Stop that part of the work and report which public API is missing.

#### A. Integration in the target plugin

- Add `lib/<...>/mcp.rb` in the target plugin (supported paths — in `04-extensions.md`).
- Module `<PluginName>::Mcp`, `extend RedmineMcp::ExtensionApi`, set `plugin_id`.
- `redmine_mcp` discovers and loads `mcp.rb` automatically on Redmine startup (`ExtensionLoader`). Do not add a separate `require` in the target plugin unless its architecture requires it (for example, plugin load order). A conditional `require` from the plugin entry point is optional, not the default approach.
- Do not modify `redmine_mcp` if this path is sufficient.

#### B. Built-in integration in `redmine_mcp`

Use only when the target plugin cannot be changed.

Checklist:

- Create `plugins/redmine_mcp/lib/redmine_mcp/extensions/<plugin.id>.rb` (filename = target `plugin.id`, e.g. `advanced_search.rb`).
- Module under `RedmineMcp::Extensions::...`, `extend RedmineMcp::ExtensionApi`, `plugin_id :<same_as_target>`.
- Wrap registration in `if mcp_extension_enabled?`; use `register_tool_once` and other `register_*` helpers as usual.
- No `require` / `after_initialize` entry point — `ExtensionLoader` loads the file on Redmine startup when MCP is enabled and the target plugin is installed.
- Helper code may live in `lib/redmine_mcp/extensions/<plugin_id>/` and be loaded via explicit `require` from the main file.
- Do not edit the target plugin.
- If the target plugin already has its own `mcp.rb`, the built-in file is used only when loading that file fails. Do not duplicate tools in both places when both load successfully.
- After adding or changing the file: Redmine restart; check **Administration → Plugins → Redmine MCP → MCP extensions** (extension must be enabled).

Minimal skeleton — full example in `extension_guide.md`:

```ruby
module RedmineMcp
  module Extensions
    module AdvancedSearch
      extend RedmineMcp::ExtensionApi

      plugin_id :advanced_search

      if mcp_extension_enabled?
        register_tool_once(...)
      end
    end
  end
end
```

### 3. Verify the integration

Add the necessary tests according to `mcp_tool_development.md`.

If the environment allows, also verify the integration with real MCP calls (`tools/list`, `tools/call`).

If Redmine, the MCP server, the database, or another required component is unavailable, do not work around the limitation — report what could not be verified.

## Deliverables

In the final response, list:

- integration path used (A or B);
- added MCP capabilities;
- permissions/modules used;
- changed files;
- checks and tests performed;
- unverified parts;
- `redmine_mcp` version requirements, if any arose.
