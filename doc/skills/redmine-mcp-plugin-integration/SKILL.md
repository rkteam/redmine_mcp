---
name: redmine-mcp-plugin-integration
description: Extend a third-party Redmine plugin to integrate with redmine_mcp via the Extension API.
---

# Integrating a Third-Party Redmine Plugin with Redmine MCP

Use this skill when you need to add MCP integration to a third-party Redmine plugin.

## Before You Start

Read these files in `redmine_mcp`:

- `doc/spec/en/extension_guide.md`;
- `doc/spec/en/mcp_tool_development.md`;
- if needed, `doc/spec/en/04-extensions.md`.

Also review the target plugin: models, services, controllers/API, permissions, project modules, settings, and tests.

## Workflow

### 1. Analyze

Before making changes, determine:

- which scenarios should be exposed via MCP;
- which entities and relationships are involved;
- which permissions/modules restrict access;
- which existing business logic can be reused;
- which MCP tools/resources/prompts are needed.

Draft a short plan:

`tool → purpose → permission/scope → data source → side effects`.

### 2. Implement integration in the target plugin

Use the public `RedmineMcp::ExtensionApi` and follow `extension_guide.md` and `mcp_tool_development.md`.

Do not move business logic into the MCP layer: reuse the target plugin's existing services, models, and API.

Do not modify `redmine_mcp` if its public Extension API is sufficient.

If a correct implementation requires a capability that is not available in the Extension API, do not use internal `redmine_mcp` classes, monkey patches, or other workarounds. Stop that part of the work and report which public API is missing.

### 3. Verify the integration

Add the necessary tests according to `mcp_tool_development.md`.

If the environment allows, also verify the integration with real MCP calls (`tools/list`, `tools/call`).

If Redmine, the MCP server, the database, or another required component is unavailable, do not work around the limitation — report what could not be verified.

## Deliverables

In the final response, list:

- added MCP capabilities;
- permissions/modules used;
- changed files;
- checks and tests performed;
- unverified parts;
- `redmine_mcp` version requirements, if any arose.
