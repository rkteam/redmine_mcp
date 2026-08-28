# Authentication and authorization

[Deutsch](../de/02-authentication.md) | [English](02-authentication.md) | [Español](../es/02-authentication.md) | [Français](../fr/02-authentication.md) | [Italiano](../it/02-authentication.md) | [日本語](../ja/02-authentication.md) | [한국어](../ko/02-authentication.md) | [Polski](../pl/02-authentication.md) | [Português (Brasil)](../pt-BR/02-authentication.md) | [Русский](../ru/02-authentication.md) | [中文](../zh/02-authentication.md)

## Overview

Access to MCP uses standard Redmine API key authentication. All operations run on behalf of the user who owns the key.

## Goal

Ensure MCP does not bypass Redmine security and users can perform only actions allowed to them.

## Affected areas

- Permissions
- API
- Users

## Business rules

### Authentication

- Redmine REST API must be enabled to access `/mcp`.
- The API key is passed in the `X-Redmine-API-Key` header (not from the JSON request body or query string).
- Only keys of active users are accepted.
- Requests without a key or with an invalid key are rejected.

### Global MCP permission

- The user must have the global **Use MCP** permission (`use_mcp`), or be a Redmine administrator.
- The `use_mcp` permission is enabled manually for the required roles in **Administration → Roles and permissions**.
- Administrators always have MCP access: the standard Redmine global permission check allows admin regardless of roles.
- For other users without `use_mcp`, the request is rejected even with a valid API key.

### Tool permissions

- Each tool has its own Redmine permission requirement.
- A tool appears in `tools/list` only if the user has permission to use it.
- Permissions are checked again when the tool is called.
- Data is filtered by Redmine visibility rules (projects, issues, members).

### Resource and prompt permissions

- Resources and prompts may have their own permission requirements.
- Without permission, a resource or prompt is not listed and cannot be read.
- Resource and prompt permission checks consider the URI and input arguments (including `project` / `project_id`). If the project is not specified in arguments, permission in at least one visible project is sufficient.
- An extension may define an explicit rule for resolving the project from the URI and arguments.

## Edge cases

- An inactive user cannot use MCP even with a previously issued key.
- An administrator has MCP access without a separate `use_mcp` assignment.
- A tool with entity-scoped permission checks (for example, an issue) may be visible in `tools/list` with empty arguments if the user has the corresponding permission in at least one project.
- If such a tool also requires a Redmine project module, "at least one project" means a visible project where the user has the permission and the specified module is enabled. Without a module requirement, permission in at least one visible project is enough. Presence in `tools/list` does not mean permission for a specific issue: permissions and object availability are checked again on call.

## Error handling

| Situation | Result |
|----------|-----------|
| REST API disabled | HTTP 401 |
| Invalid or missing API key | HTTP 401 |
| No Use MCP permission | HTTP 403 |
| No permission for a specific tool | Tool absent from `tools/list`; direct call — "Permission denied" error |
| Entity unavailable to user | Tool response with an error description (for example, "Issue not found") |

## Test scenarios

1. Request with a valid key and Use MCP permission — successful access.
2. Request without an API key header — HTTP 401.
3. Request with a non-admin key without Use MCP permission — HTTP 403.
4. Administrator key without a role with `use_mcp` — successful access.
5. User sees in `tools/list` only tools they have permission for.
6. Calling a tool for an inaccessible issue returns an error, not another user's data.
7. An issue-scoped tool with a project module requirement is not visible in `tools/list` if the user has the permission but no visible project with the module enabled; it is visible if such a project exists.
