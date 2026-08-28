# Redmine MCP Tool Development Requirements

[Deutsch](../de/mcp_tool_development.md) | [English](mcp_tool_development.md) | [Español](../es/mcp_tool_development.md) | [Français](../fr/mcp_tool_development.md) | [Italiano](../it/mcp_tool_development.md) | [日本語](../ja/mcp_tool_development.md) | [한국어](../ko/mcp_tool_development.md) | [Polski](../pl/mcp_tool_development.md) | [Português (Brasil)](../pt-BR/mcp_tool_development.md) | [Русский](../ru/mcp_tool_development.md) | [中文](../zh/mcp_tool_development.md)

**Status:** developer guide (dev-guide), not a behavioral plugin SPEC  
**Version:** 1.6  
**Date:** 2026-08-20  
**Applicability:** all new Redmine MCP tools and substantial changes to existing tools  
**Base MCP version:** Protocol Revision `2025-11-25`

Behavioral contracts for core tools are in `03-core-tools.md` and related SPECs. This document defines rules for designing and implementing tools.

---

## 1. Purpose of this document

This document establishes unified requirements for designing, implementing, describing, testing, and publishing MCP tools for Redmine. Architectural implementation patterns are collected in appendix A and are not mixed with mandatory requirements in the main text.

The goal of this standard is to make tools:

- unambiguous for language model selection;
- safe when invoked automatically;
- predictable for MCP clients;
- strictly validated;
- easy to maintain and backward compatible;
- resilient to repeated calls, model errors, and partially filled arguments.

Requirements are formulated with an audit of the current Redmine MCP in mind. At the time this document was prepared, the server publishes 46 tools; the contract revealed parameters without `type`, string lists of allowed values instead of `enum`, universal `manage_*` tools, and missing `outputSchema`.

---

## 2. Obligation terminology

The following levels are used in this document:

- **MUST / MUST** — mandatory requirement. Violation blocks merge.
- **MUST NOT / FORBIDDEN** — mandatory prohibition.
- **SHOULD / SHOULD** — requirement by default; deviation must be justified in the merge request.
- **MAY / MAY** — acceptable option.

Architectural and implementation patterns that are not mandatory for every tool are collected in **appendix A**. They do not block merge if consciously not adopted for a specific tool.

---

## 3. Core design principles

### 3.1. One tool — one clear action

A tool MUST represent one atomic user intent.

Good:

- `redmine_get_issue`
- `redmine_create_issue`
- `redmine_update_issue`
- `redmine_add_issue_note`
- `redmine_delete_issue`
- `redmine_list_issue_relations`
- `redmine_create_issue_relation`
- `redmine_delete_issue_relation`

Bad:

- `redmine_manage_issue`
- `redmine_manage_relation`
- `redmine_execute_action`

Tools with a parameter like `action: create | update | delete | list` are FORBIDDEN if the operations:

- require different mandatory arguments;
- have different risk levels;
- should have different MCP annotations;
- return different data structures;
- require different Redmine permissions.

An exception is allowed only for a semantically homogeneous operation where all variants have the same risk and a single contract. The exception must be explicitly justified.

### 3.2. Read, add, update, and delete are separated

In one tool it is FORBIDDEN to combine:

- read-only and write operations;
- adding and deleting operations;
- regular user and administrative operations;
- local Redmine operations and sending data to the outside world.

For example, `list/create/delete relation` must be three separate tools.

### 3.3. Contract matters more than server implementation convenience

Do not publish the structure of an internal Ruby/Python/REST method directly just because it is easier to implement the handler that way.

The MCP contract is designed for the model and client; an adapter inside the server converts it to Redmine API format.

Internal technical values of a plugin or Redmine MUST be normalized if they are not part of a meaningful external contract.

Do not publish without necessity:

- Ruby/Rails class names and STI types;
- internal enum names if MCP already uses a different value on input;
- locale-dependent dates;
- REST-specific representations of the same field if MCP already defines a canonical format;
- technical names when MCP already uses a normalized value.

Example: input filter `type` — `contact` / `company`; in the response also `contact` / `company`, not `Clientdesk::Contact` / `Clientdesk::Company`. If a serializer returns an STI class or localized date, the MCP adapter MUST bring the value to the published schema.

### 3.4. The server does not trust the model

All arguments are considered untrusted. The server MUST re-check:

- types;
- ranges;
- field interdependencies;
- rights of the current user;
- object belonging to a project;
- availability of a value in a specific workflow;
- Redmine constraints;
- whether the operation is allowed in the current object state.

JSON Schema, descriptions, annotations, and client confirmations do not replace server-side validation.

---

## 4. Tool naming

### 4.1. Name format

All published tool names MUST start with `redmine_`.

For core tools of the `redmine_mcp` plugin, the short prefix `redmine_` is used:

```text
redmine_<verb>_<entity>
```

For tools from third-party plugins, the full name MUST start with `redmine_`:

- `redmine_<plugin_id>_<verb>_<entity>`.

Requirements:

- only `lower_snake_case`;
- the `redmine_` prefix is mandatory for all tools, including third-party plugin extensions;
- name is unique within the server;
- internal limit — no more than 64 characters;
- name does not change without a deprecation procedure.

Examples:

```text
redmine_get_issue
redmine_list_projects
redmine_search_issues
redmine_create_time_entry
redmine_delete_wiki_page
redmine_advanced_search_semantic_search_issues
```

### 4.2. Allowed verbs

Preferred verbs:

| Verb | Purpose |
|---|---|
| `get` | retrieve one object by exact identifier |
| `list` | retrieve a collection by structured filters |
| `search` | perform text or full-text search |
| `create` | create an object |
| `update` | modify an existing object |
| `set` | set a specific field or flag to a given value |
| `delete` | delete an object |
| `add` | add a relation or member to an existing object |
| `remove` | remove a relation without deleting the main object |
| `copy` | create a copy |
| `upload` | upload a file |
| `download` | retrieve file contents |
| `send` | send a message or data to an external recipient |
| `summarize` | build a server-side aggregated report |

Do not use vague verbs (`manage`, `process`, `handle`, `execute`, `do`) — see §3.1.

The verb MUST match the real semantics of the operation. If a tool toggles a boolean flag (parameter like `enabled: true | false`), it SHOULD be named with `set`, not with a verb implying only one value.

Bad:

```text
redmine_advanced_search_enable_semantic_index
```

`enable` implies only `enabled = true`, although the parameter also allows `false`. The name does not match the actual action.

Good:

```text
redmine_advanced_search_set_semantic_index_enabled
```

The name `set_*` honestly reflects that the operation sets a flag to the passed value.

### 4.3. Identifier parameter names

A parameter name MUST match its actual type:

- `issue_id` — integer ID only;
- `project_id` — integer ID only;
- `project_identifier` — Redmine string identifier;
- `project` — string that deliberately allows both representations and is documented as a reference.

A parameter named `*_id` cannot accept a string identifier or the value `"me"`.

Numeric IDs MUST have `minimum: 1` and a meaningful `description`. Formulations like `"Issue id"` without `minimum` are FORBIDDEN.

Bad:

```json
"issue_id": {
  "type": "integer",
  "description": "Issue id"
}
```

Good:

```json
"issue_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Numeric issue ID.",
  "examples": [1]
}
```

The recommended unified option for project is parameter `project`, accepting numeric ID (as a string) or string identifier:

```json
"project": {
  "type": "string",
  "minLength": 1,
  "description": "Project ID as a string, or project identifier. Call redmine_list_projects when the value is unknown.",
  "examples": ["1", "ecookbook"]
}
```

The `examples` array (§6.15) shows the model both allowed value forms and reduces the chance of incorrect input.

### 4.4. Optimistic locking: `expected_updated_at`

A parameter that passes a previously known object timestamp to reject a stale change MUST be named `expected_updated_at` in all core tools and extensions.

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

The name `updated_at` for this meaning is FORBIDDEN: it looks like "new modification time", although it is actually a value for optimistic locking.

Bad (checklist and any extensions):

```json
"updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Current updated_at of the checklist item."
}
```

Good:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

A response field that reports the actual object modification time MAY still be named `updated_at` / `updated_on` — confusion arises only for the locking input parameter.

Normative behavior on conflict is in appendix A.2.

---

## 5. `title` and `description`

### 5.1. `title`

`title` MUST be a short human-readable name, not a copy of the technical name.

```json
{
  "name": "redmine_get_issue",
  "title": "Get Redmine issue"
}
```

### 5.2. Tool description

`description` MUST briefly answer key questions:

1. What does the tool do and which object is read or modified?
2. What is not included by default and how to request it?
3. Are there significant side effects?
4. Which preliminary tool to call if ID or an allowed value is unknown?

Description MUST be brief and easy to read. It is FORBIDDEN to turn it into a long half-page paragraph listing all fields and all include options: an overloaded description is harder for the model to read than a short structured one.

SHOULD write several short lines or a list, not continuous text. Defaults and how to change them are shown compactly.

Good example:

```text
Returns one issue.

Default:
- no journals
- no attachments

Use include_* to request them.
Use redmine_search_issues when issue_id is unknown.
```

Bad example — too short, does not explain the result and default behavior:

```text
Gets issue.
```

Bad example — overloaded, long paragraph listing all fields:

```text
Return one Redmine issue by numeric issue_id with core detail fields including
subject, description, status, priority, tracker, project, assignee, author,
dates, done ratio, custom fields, and optionally journals, attachments,
relations, watchers, child issues and allowed workflow statuses depending on the
include parameters that were passed to the call ...
```

### 5.2.1. References to other tools

When description, parameter description, or server instructions refer to another tool, the full registered name from `tools/list` MUST be used, not a short `name` without prefix.

Bad:

```text
Use list_projects when project is unknown.
Use semantic_search_issues before update.
```

Good:

```text
Use redmine_list_projects when project is unknown.
Use redmine_advanced_search_semantic_search_issues before update.
```

Short names are ambiguous across plugins and force the model to guess the prefix. This is especially important for extensions: `semantic_search_issues` without the `redmine_advanced_search_` prefix is easily confused with a non-existent core tool.

### 5.2.2. Description of the returned result

Description MUST briefly explain the tool result so the model understands whether one call is enough or a next tool is needed.

The result description should indicate:

- whether one object, collection, aggregate, change confirmation, or resource reference is returned;
- which related data is included by default;
- which large or sensitive data is not included without an explicit parameter;
- whether pagination exists and what the standard limit is;
- whether a write tool returns the full updated object or only identifier, URL, and modification time;
- whether partial success is possible for a bulk operation.

Example for read:

```text
Returns one issue with core and custom fields.

Not included by default: journals, attachments, relations, watchers, child issues.
Request them with include_*.
```

Example for list:

```text
Return a paginated list of issues matching the supplied structured filters.
Each item contains summary fields only; use redmine_get_issue for full details.
The result includes total_count, limit, offset, and has_more.
```

Example for write:

```text
Create one issue and return its numeric ID, canonical URL, and creation timestamp.
The response does not include journals or attachments.
```

On the relationship between description and `outputSchema` — see §7.1 and §7.1.1. If a list already returns a field, description MUST NOT send the model to `get_*` only for that field.

### 5.3. Description does not replace schema

It is FORBIDDEN to set constraints only in text:

```json
{
  "type": "string",
  "description": "Operation: create, update, delete"
}
```

Use `enum`, `const`, ranges, and conditional schemas.

The same applies to mutually exclusive fields. If `description` says "exactly one of `user_id` or `group_id`" but `required` contains only common fields — schema and text diverge. The constraint MUST be formalized in `inputSchema` (§6.12).

### 5.4. Predictable selection

Descriptions of similar tools must explicitly explain the difference.

For example:

- `redmine_list_project_members` — members of a specific project and their roles;
- `redmine_admin_list_users` — global list of installation users, requires administrative rights.

### 5.5. Server-level instructions

The server MAY publish brief general instructions that explain relationships between tools and workflow rules.

Instructions should add context not present in individual descriptions and refer to tools by full names (§5.2.1), for example:

```text
Use redmine_search_issues before redmine_get_issue when the issue ID is unknown.
Before creating or updating an issue, call redmine_list_project_trackers and
redmine_list_project_issue_custom_fields when their IDs are not already known.
Private notes must only be requested when the user explicitly needs them and has
the required permission.
```

FORBIDDEN:

- repeating descriptions of all tools in server instructions;
- placing general model behavior instructions unrelated to the server there;
- writing a long guide instead of brief routing rules;
- using marketing statements;
- referring to tools by short names without prefix (`list_projects` instead of `redmine_list_projects`).

### 5.6. Study Redmine REST API before development

Before creating or substantially changing a tool, the developer SHOULD perform documentation research. It is not recommended to design the contract only from existing MCP code, developer memory, or a single HTTP request example.

SHOULD study:

1. Redmine REST API main page: general authentication, pagination, `include`, custom fields, files, and validation error rules.
2. Separate API page for the corresponding resource, e.g. Issues, Time Entries, Versions, Wiki Pages, or Project Memberships.
3. API change history section and changes for supported Redmine versions.
4. Actual Redmine version used by MCP and minimum supported version.
5. REST API and source code of Redmine plugins used if the tool works with a plugin entity or fields. Before publishing an extension tool, MUST verify the source serializer / service / REST endpoint and at least one real successful response for each result form (list and get, if both are published).
6. Real permissions, workflow, enabled modules, trackers, custom fields, and constraints of the target installation.
7. Already published MCP tools to avoid creating a duplicate or conflicting contract.

The main page `https://www.redmine.org/projects/redmine/wiki/rest_api` is the entry point but is usually insufficient for a specific tool. SHOULD go to the corresponding resource page and verify operations, query parameters, `include`, request fields, response structure, error codes, and version constraints.

### 5.7. API coverage report

Before implementing a new tool, the developer SHOULD attach a brief API coverage table to the merge request:

| Field | Content |
|---|---|
| Redmine resource | Resource and link to official API page |
| Endpoint | HTTP method and path |
| Supported since | Minimum Redmine version |
| Request parameters | All documented request parameters |
| Query filters | All documented filters and special values |
| Include values | Allowed related data |
| Required/defaults | Mandatory fields and default values |
| Response | Main fields and response variants |
| Errors | HTTP codes and error structure |
| Permissions | Required rights and impersonation specifics |
| MCP exposure | Which parameters are published in MCP |
| Intentionally omitted | Which parameters are not published and why |
| Plugin/version differences | Plugin and supported version differences |

The goal of the table is not necessarily to publish every Redmine parameter in MCP. The goal is not to forget parameters accidentally and to make publication decisions consciously.

A Redmine parameter may be excluded from MCP if it:

- is dangerous or administrative;
- duplicates a separate clearer tool;
- is unstable across supported versions;
- creates an ambiguous schema;
- is not needed for target user scenarios;
- leads to excessively large responses.

Each substantial exclusion is recorded in `Intentionally omitted` with a brief justification.

### 5.8. Instructions for an AI agent developing tools

If a tool is created or changed by an AI agent, the working instructions SHOULD refer to this document: API research (§5.6–5.7), contract (§3–§8), tests (§13), checklist (§14).

Recommended text:

```text
Before implementing or changing a Redmine MCP tool, follow MCP_TOOL_DEVELOPMENT.md:
study the Redmine REST API for the target resource (§5.6–5.7), design one user
intent rather than copying the REST payload (§3), compare with tools/list, then
implement schema/annotations/errors. For plugin extensions, inspect the serializer
or REST response and align description with outputSchema (§7, §18). Pass the code
review checklist (§14).
```

---

## 6. `inputSchema` requirements

### 6.1. Base structure

Every tool MUST have a valid JSON Schema.

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {},
  "required": []
}
```

For a tool without arguments:

```json
{
  "type": "object",
  "additionalProperties": false
}
```

### 6.2. Prohibition of undocumented properties

At the top level and in all nested objects:

```json
"additionalProperties": false
```

An open dictionary is allowed only consciously. In that case, the value schema is set explicitly:

```json
"additionalProperties": {
  "type": "string"
}
```

### 6.3. Type of every parameter

Every property MUST contain `type`, `$ref`, or a `oneOf` / `anyOf` / `allOf` composition.

FORBIDDEN:

```json
"project_id": {
  "description": "Project ID or identifier"
}
```

### 6.4. Required parameters

The `required` array must reflect the minimally executable call.

If the operation is impossible without a parameter, the parameter MUST be in `required`.

For example, file upload requires at least:

```json
"required": ["project", "filename", "content_base64"]
```

`confirm=true` check for deletion is performed on the server (§3.4), even if the field is in `required`.

### 6.5. Enumerations

For a finite set of values, MUST use `enum` or `const` (not only text in description — see §5.3).

```json
"status": {
  "type": "string",
  "enum": ["open", "locked", "closed"]
}
```

### 6.6. Strings

Strings must have appropriate constraints:

- `minLength` for non-empty values;
- `maxLength` according to Redmine constraints or internal limits;
- `pattern` when format is strictly defined;
- `format` when a standard format applies.

```json
"due_date": {
  "type": "string",
  "format": "date",
  "description": "Due date in YYYY-MM-DD format."
}
```

`format` constraint in schema does not replace server-side validation (§3.4).

### 6.7. Numbers

For numeric parameters, reasonable bounds MUST be set.

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

The `default` value is part of the contract and documentation. The server must not assume the client will substitute default on its own.

### 6.8. Arrays

Every array MUST have `items`.

When needed, set:

- `minItems`;
- `maxItems`;
- `uniqueItems`.

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

An array like `entries: array` without element schema is FORBIDDEN.

### 6.9. Nested objects

All nested objects are described fully.

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

### 6.10. Cannot accept "object or JSON string"

It is FORBIDDEN to describe one parameter as "object or JSON string".

MCP already passes structured JSON. The tool must accept an object, not a string that the server then parses again.

### 6.11. Universal `fields` and `extra_fields`

Parameters `fields`, `extra_fields`, `payload`, `data`, and similar open objects are FORBIDDEN for main business operations.

Issue fields must be listed explicitly with meaningful `description` (§6.14) and, where useful, `examples` (§6.15):

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

Rarely used fields may be passed through a strictly described `custom_fields`.

### 6.12. Interdependent fields

Prefer splitting tools. If splitting is impossible, dependency is formalized through:

- `dependentRequired`;
- `if` / `then` / `else`;
- `oneOf` with mutually exclusive branches.

Text in `description` ("exactly one of …") does not replace schema (§5.3).

Typical case — "exactly one of two fields". Bad: `required` lists only common fields, XOR remains in prose:

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

Such schema allows a call without `user_id`/`group_id` and a call with both fields at once.

Good — common `required` plus top-level `oneOf`:

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

Server-side validation (§3.4) MUST still reject both incorrect variants. Schema is needed so client and model see the constraint before the call.

Must verify compatibility of chosen constructs with supported MCP clients and SDK.

### 6.13. Fields with `null` value and clearing values

`null` is allowed only when it has a separate documented meaning, e.g. "clear due date" or "unassign".

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

Do not use empty string as implicit equivalent of `null`.

For `set_*` tools that set an optional field (due date, assignee, etc.), the contract MUST explicitly decide clearing. Three options are allowed — in order of preference:

1. **The same tool accepts `null`** (preferred), as above: one intent "set or clear".
2. **Separate clear/unassign tool**, if API or UX better separates operations, e.g. `redmine_advanced_search_clear_saved_query` and `redmine_advanced_search_unassign_search_owner`.
3. **Explicit refusal**: if clearing via MCP is not supported, this MUST be stated in tool `description` and/or parameter description. Silent contract "only string/integer without null" without explanation is FORBIDDEN — the model will wrongly think clearing is impossible or try to pass `""` / `0`.

Bad — can set due date, cannot clear, and nowhere stated:

```json
"due_date": {
  "type": "string",
  "format": "date"
}
```

### 6.14. Parameter descriptions

Every parameter in `inputSchema.properties` MUST have a meaningful `description`. Parameters without `description` are FORBIDDEN, including in extensions (checklist item `done`, `sort_order`, `due_date`, ID fields, etc.) and optional fields with clear `enum`.

Descriptions like "Filter by tracker ID", "Tracker id", or "Issue id" are insufficient: they do not hint where to get an allowed value and what constraints exist.

An identifier parameter description MUST indicate which tool or response field to use for allowed values (full name — §5.2.1; discovery — §6.16), and note significant constraints (workflow, permissions, project belonging).

Bad:

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

Good:

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

Good, with constraint noted:

```json
"status_id": {
  "type": "integer",
  "minimum": 1,
  "description": "Issue status ID returned by redmine_list_issue_statuses; must be allowed by the workflow for the current tracker and role."
}
```

Parameter description does not replace schema (§5.3) and server-side validation (§3.4).

### 6.15. Value examples (`examples`)

For parameters where value format is non-obvious or allows multiple representations, SHOULD add `examples` — standard JSON Schema array key. Examples help the model enter a correct value and are especially useful for reference parameters, identifiers, dates, and enum-like strings.

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

Requirements:

- `examples` values MUST be valid against the parameter schema itself;
- `examples` illustrate format but do not replace `enum`, ranges, and other constraints (§5.3, §6.5);
- for parameters with `enum`, separate `examples` are usually redundant.

If an MCP client or SDK does not support `examples` in schema, `x-examples` MAY be used as an extension key with the same semantics.

### 6.16. Discovery path for ID parameters

A parameter of the form `*_id` that the model cannot guess MUST have an explicit discovery path: a separate read/list tool or a field in another read tool response referenced in parameter `description` (§6.14).

Allowed options (in order of preference for a tool set):

1. **Separate list/discovery tool** — `redmine_list_issue_statuses`, `redmine_list_roles`, `redmine_advanced_search_list_search_providers`.
2. **Options inside get/list response** — e.g. provider array with `id` and `name` in `redmine_advanced_search_semantic_search_issues` response. Then description MUST refer to that response field with full tool name.
3. **Stable enum in schema**, if the value set is fixed and small.

FORBIDDEN to publish a write tool with `status_id` / `role_ids` / similar if none of the above is satisfied: the model is forced to guess IDs.

Bad — write without discovery:

- `redmine_advanced_search_set_search_provider` exists with `provider_id`;
- no `redmine_advanced_search_list_search_providers`;
- `semantic_search_issues` returns only current provider name (`provider: "…"`), without list of allowed values and their `id`.

In that case description like `"Search provider ID."` is insufficient. Either add a list tool, or include provider options in get response and write, for example:

```text
Search provider ID returned in the provider options from
redmine_advanced_search_semantic_search_issues.
```

The rule applies to core and extensions (§18).

---

## 7. `outputSchema` and result requirements

### 7.1. `outputSchema`

A new tool MUST publish `outputSchema`. The schema describes a stable public response contract, not only the envelope shape `{ ok, data | error }`.

If `description` claims the tool returns named fields or nested structure, `outputSchema` MUST formalize those fields, not limit itself to top-level `data` / `items` as "arbitrary object".

Bad: description lists `query`, `results`, snippets and attachment excerpts, but `outputSchema` is missing or describes `items` only as `{ "type": "object", "additionalProperties": true }`.

For each stable result field:

- type MUST be specified;
- a guaranteed field MUST be in `required`;
- a finite value set MUST be set via `enum` or `const`;
- a date MUST have `format: date` or `date-time` if the server guarantees the corresponding format;
- numeric ID MUST keep a unified type;
- nullable and optional are different contracts: if a field is always returned but may have no value, it must be `required` and allow `null`;
- for numeric business values, units MUST be specified if not obvious from the field name;
- monetary value MUST have unambiguous semantics: major/minor units and how currency is determined.

`additionalProperties: true` MUST NOT be used instead of describing known stable result fields. It is allowed for backward compatibility or truly extensible structures, but known business fields inside such object must still be listed in `properties`, and guaranteed ones in `required`.

For list tools, `items` elements MUST describe at least fields needed by the model for identification, filtering, and subsequent tool calls.

Good — fragment typing `data` (full success/error envelope — §7.2 and §12):

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

The result SHOULD return:

- `structuredContent` — machine-readable object if clients need stable structure;
- text `content` — brief representation for backward compatibility and humans.

### 7.1.1. Public contract consistency

Before completing a tool, the developer MUST compare three representations:

1. actual handler / REST / service response;
2. tool `description`;
3. `outputSchema`.

They must not contradict each other.

If description says a field is always returned, it must be `required` in `outputSchema`.

If schema sets `enum` / `const` / `format`, the actual serializer MUST normalize the value to that contract. Cannot publish `format: date` and simultaneously promise locale-formatted string.

If a list already returns data, description MUST NOT send the model to a get tool only for the same data.

Business invariants of the result MUST be reflected in schema via `const`, `enum`, `required`, or conditional schema, not only inferred from tool name. Example: if a subscription tool by definition returns only products of type `subscription`, `product_type` must be `const: "subscription"`, not `enum` with impossible values.

### 7.2. Unified envelope

Recommended successful result:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Error:

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

On error, additionally set:

```json
"isError": true
```

If `outputSchema` is published and error is also returned in `structuredContent`, schema MUST describe both branches — success and error. Cannot publish success-only schema and return incompatible structured error object. Alternative: on tool execution error return only text `content` with `isError: true` and do not return `structuredContent`. Preferred option — unified typed envelope with two branches.

### 7.3. Field stability

Output fields are a public contract. FORBIDDEN:

- changing field type without a major change;
- renaming a field without deprecation period;
- sometimes returning object, sometimes array;
- returning ID as number sometimes, string sometimes;
- returning unlimited unprocessed Redmine API response.

### 7.4. Single object result

Recommended format:

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

### 7.5. List result

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

`items` element schema follows §7.1: identifiers, routing fields, and stable business fields are described explicitly. Empty `{ "type": "object", "additionalProperties": true }` as sole element description is FORBIDDEN.

### 7.6. Minimally necessary volume

List/search tools must by default return brief records. Full description, journals, attachments, and large text fields should be obtained via separate `get_*`.

This reduces tokens, latency, and risk of passing excess sensitive data.

### 7.7. Sensitive data

Result must not contain without explicit need:

- API tokens;
- Authorization headers;
- cookies;
- server filesystem paths;
- internal stack traces;
- passwords and secrets;
- Redmine fields unavailable to current user;
- private notes without separate permission.

---

## 8. MCP annotations

Annotations are hints for the client and are not an authorization or protection mechanism.

### 8.1. Value matrix

| Operation type | `readOnlyHint` | `destructiveHint` | `idempotentHint` | `openWorldHint` |
|---|---:|---:|---:|---:|
| Get/find/list Redmine data | `true` | `false` | `true` | `false` |
| Create issue/version/checklist | `false` | `false` | `false` | `false` |
| Add comment/watcher/relation | `false` | `false` | `false` | `false` |
| Change field, rename, set flag (`update`, `rename`, `set`) | `false` | `false` | depends on implementation | `false` |
| Delete, clear, reset (`delete`, `purge`, `reset`) | `false` | `true` | only with guaranteed idempotency | `false` |
| Send email to external recipient | `false` | `false` | `false` | `true` |
| Access arbitrary URL / external system | depends | depends | depends | `true` |

### 8.2. Rules

- `readOnlyHint: true` only if the tool does not change state and does not cause side effects.
- `destructiveHint` describes irreversible loss or destruction of data, not the fact of writing. `destructiveHint: true` SHOULD be set only for irreversible operations — `delete`, `purge`, `reset`, full field or relation clearing.
- Ordinary `update`, `rename`, and `set` are NOT destructive: for them `destructiveHint: false`. For example, `update_checklist_title` or `rename_wiki_page` is ordinary update, not destruction, and destructive annotation is wrong for them.
- `idempotentHint: true` only if repeated call is truly safe; SHOULD confirm with a test.
- `openWorldHint` describes whether the tool accesses an open, previously unknown external world, not whether a new object is created. Work with one configured Redmine installation is a closed world: `openWorldHint: false`.
- Therefore `create_issue`, `create_time_entry`, and other write tools within their Redmine use `openWorldHint: false`, despite creating new objects. Creating an object in a known system does not make the world open.
- `openWorldHint: true` only when recipient or data source is not limited to the known system: sending email to external recipient, arbitrary HTTP request, access to external service.
- `openWorldHint` value SHOULD be set consciously for each tool, not copied by default: verify whether the tool actually goes beyond its Redmine installation.
- Cannot copy one annotation set to all write tools.

### 8.3. Redmine side effects

When assessing idempotency, consider not only final fields but also:

- journal entry creation;
- notification sending;
- webhooks;
- audit log;
- repeated file upload;
- repeated relation creation;
- repeated time entry logging.

If a repeated call creates an additional record or notification, the tool is not idempotent.

---

## 9. Security

### 9.1. Authorization

Every call MUST run in context of an authenticated user or explicitly documented service account.

The server MUST check Redmine permissions for the specific project and object. Tool presence in `tools/list` does not mean permission for the operation.

Administrative tools should:

- be published only to administrators;
- or be moved to a separate administrative MCP profile/server;
- or be protected by a separate scope.

### 9.2. Minimum rights

MCP server and Redmine API token must have minimally necessary rights. Cannot use a global administrative token for all users if user access model must be preserved.

### 9.3. Arbitrary filesystem paths forbidden

Parameters like:

```json
{"file_path": "/etc/app/.env"}
```

are FORBIDDEN in public MCP tools.

Safe options:

1. `content_base64` with size limit;
2. opaque `upload_token` issued by trusted upload mechanism;
3. MCP resource URI where access is checked by host;
4. file only from dedicated temporary directory with `realpath` check and allowlist.

The server MUST verify:

- maximum size;
- MIME type;
- allowed extension;
- file name;
- absence of path traversal;
- antivirus/content check if required by organization policy.

### 9.4. Arbitrary URLs and SSRF

A tool must not accept arbitrary URL unless that is its main purpose.

When HTTP access is needed:

- use domain and scheme allowlist;
- forbid loopback, link-local, metadata endpoints, and internal networks if not needed;
- limit redirects;
- set timeout and response limit;
- do not pass internal credentials to another origin.

### 9.5. Deletion and dangerous operations

For irreversible operations, MANDATORY:

- separate tool;
- `destructiveHint: true`;
- explicit description of irreversibility;
- precise server-side permission check;
- audit log;
- protection against deleting object outside expected project;
- check of child objects and related consequences.

Boolean `confirm_delete: true` MAY be used as additional protection against accidental call, but cannot be considered an authorization mechanism.

Two-phase deletion, optimistic locking, and idempotency key — see appendix A.

### 9.6. Logs

Audit log records:

- tool name;
- authenticated user;
- target project/object IDs;
- outcome;
- duration;
- error code;
- request correlation ID.

FORBIDDEN to log:

- access token;
- Authorization header;
- cookies;
- base64 file contents;
- secret custom fields;
- full text of private notes without separate need.

### 9.7. Rate limit and timeout

Every tool MUST have:

- input size limit;
- rate limit per user/token;
- limit on number of returned records;
- bulk operation limits.

Server timeout of 60 s applies to read tools. Write tools are not interrupted by server timeout so that after successful save idempotency result can be recorded.

---

## 10. Errors

### 10.1. Error separation

Two levels are used:

1. **Protocol error** — unknown tool, corrupted JSON-RPC, inability to process MCP request.
2. **Tool execution error** with `isError: true` — argument error, Redmine API, permissions, workflow, or business logic error.

Errors the model can fix by changing arguments should return as tool execution errors.

### 10.2. Error structure

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

### 10.3. Recommended codes

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

### 10.4. Message must be fixable

Bad:

```text
Invalid request.
```

Good:

```text
field status_id must be one of [2, 4, 7] for tracker_id=3 in project bank-site.
Call redmine_list_allowed_issue_transitions to retrieve current values.
```

Do not return stack trace to user. Stack trace is stored only in protected server log with correlation ID.

---

## 11. Pagination and data volume

### 11.1. List/search tools

MANDATORY parameters:

```json
"limit": {
  "type": "integer",
  "default": 25,
  "minimum": 1,
  "maximum": 100
}
```

For existing Redmine API, `offset` is allowed. For custom implementation, opaque cursor is preferred if data may change actively during traversal.

### 11.2. Pagination metadata

Result must contain:

- actual `limit`;
- `offset` or `next_cursor`;
- `has_more`;
- `total_count` if obtaining it does not create significant load.

### 11.3. Field selection

`fields` parameter is allowed only as array from closed allowlist:

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

Cannot pass arbitrary field names directly to SQL, ActiveRecord `select`, serializer, or Redmine API without allowlist.

### 11.4. Large results

Large journals, attachments, and files must:

- have separate pagination;
- be returned by separate tool/resource;
- for binary data, return resource link or other limited reference instead of embedding large base64 in response when possible;
- or support task-augmented execution if operation is truly long and client supports it.

`execution.taskSupport` is not set automatically. Default is `forbidden`.

---

## 12. Reference for a new tool

Abbreviated write tool example with mandatory `title` and typed `outputSchema` per §7.1. Error format — §10. Full JSON — in appendix B.

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

## 13. Testing

### 13.1. Schema tests

For every tool, MANDATORY:

- at least one valid call;
- at least one negative call (e.g. missing required field or wrong type).

SHOULD cover as applicable to schema:

- full valid call;
- absence of each required field;
- wrong type of key parameters;
- unknown additional field;
- value outside enum;
- value outside range;
- wrong date/date-time;
- exceeding `maxItems`, `maxLength`, and file size;
- violation of field interdependency (both XOR fields at once; neither of mandatory pair).

### 13.2. Permission tests

For write, destructive, and sensitive read operations SHOULD verify:

- user without project access;
- user with read-only access;
- user with edit permission;
- administrator if tool touches admin scenarios;
- access to private notes if tool returns or changes them;
- attempt to change object of another project via substituted ID.

For simple read-only tools without sensitive data, permission tests MAY be limited to one negative scenario or omitted with brief justification in MR.

### 13.3. Idempotency tests

For `idempotentHint: true`, SHOULD have automatic or manual test of two or more identical sequential calls.

Verify absence of side effects claimed as idempotent, e.g.:

- additional journal entries;
- repeated emails;
- file duplicates;
- relation duplicates;
- repeated time entries;
- extra webhook events if part of guarantee.

### 13.4. Contract tests

SHOULD keep `tools/list` as snapshot or otherwise track breaking contract changes. CI MAY detect:

- name change;
- parameter removal;
- type change;
- `required` change;
- annotation risk level increase;
- `outputSchema` disappearance;
- incompatible change of fields, types, `required`, `enum` / `const`, or success/error branches of `outputSchema`.

### 13.5. LLM selection tests

For similar or easily confused tools SHOULD have a set of user requests and expected tool calls. Full automatic LLM run MAY be replaced by static examples in MR or description review.

Examples:

| Request | Expected tool |
|---|---|
| "Show issue 123" | `redmine_get_issue` |
| "Find issues about OAuth" | `redmine_search_issues` |
| "Add watcher 15 to issue 123" | `redmine_add_issue_watcher` |
| "Delete relation between issues" | `redmine_delete_issue_relation` |
| "Find similar issues" | `redmine_advanced_search_semantic_search_issues` |

Test or review fails if model with high probability chooses universal destructive tool for read-only intent or is forced to guess `action` values.

### 13.6. Error recovery tests

SHOULD verify that after typical errors the model receives enough information for correct retry:

- missing ID;
- invalid status;
- `expected_updated_at` conflict;
- insufficient permissions;
- limit exceeded;
- wrong MIME type.

---

## 14. Code review checklist

A new tool cannot merge until all mandatory items receive a "yes" answer.

### Purpose

- [ ] One action; no `action`/`manage` mixing operations (§3.1–3.2).
- [ ] Administrative operation separated from ordinary.

### Name and description

- [ ] Name starts with `redmine_`: core — `redmine_<verb>_<entity>`; third-party plugin — `redmine_<plugin_id>_…` (§4.1).
- [ ] Description: purpose, side effects, brief result; similar tools distinguishable (§5).
- [ ] Cross-references to other tools use full names from `tools/list` (§5.2.1).

### Source contract research

- [ ] For core tool, REST API of resource, versions, and plugins if needed studied; coverage report SHOULD be attached to MR (§5.6–5.7).
- [ ] For extension tool, source serializer / service / REST endpoint and at least one real successful response for each result form MUST be verified (§18.5).
- [ ] Contract compared with current `tools/list`.

### Input Schema

- [ ] Schema matches §6 (`additionalProperties: false`, types, `required`, `enum`/`const`, constraints).
- [ ] Every parameter has meaningful `description` (§6.14); `*_id` has `minimum: 1` (§4.3).
- [ ] For `*_id` and other lookup values, discovery path specified (§6.16): list tool, get/list response field, or `enum`.
- [ ] "Exactly one of …" / interdependency constraints formalized in schema, not only in description (§5.3, §6.12).
- [ ] Optimistic locking — only `expected_updated_at`, not `updated_at` (§4.4).
- [ ] For `set_*` optional fields, clearing decided: `null`, separate clear tool, or explicit refusal (§6.13).
- [ ] No "object or JSON string" and arbitrary `fields`/`payload`.
- [ ] `*_id` — integer; server-side validation per §3.4.

### Output and errors

- [ ] New tool has `outputSchema` with success/error envelope (§7.1–7.2).
- [ ] Known stable result fields described in `properties`; `additionalProperties: true` not used instead of known contract.
- [ ] All guaranteed fields are in `required`.
- [ ] Nullable and optional fields distinguished consciously.
- [ ] `enum`/`const`, `date`/`date-time`, ranges, and other known constraints formalized in schema.
- [ ] For monetary and other numeric business values, units, currency, and major/minor units are clear.
- [ ] Business invariants of result reflected in schema (`const`, `enum`, `required`, or conditional schema), not only inferred from tool name.
- [ ] Description, `outputSchema`, and actual handler/REST/service response do not contradict (§7.1.1).
- [ ] Internal REST/Ruby/plugin values normalized to stable MCP contract; no STI/class name or locale-dependent format leakage (§3.3).
- [ ] List tool returns brief but sufficient structure; description correctly explains when corresponding get tool is truly needed.
- [ ] Errors: `isError`, stable code, fixable message; no secrets or stack trace (§10).

### Annotations

- [ ] Annotations match risk (§8); test recommended for `idempotentHint: true`.

### Security

- [ ] Permissions, file path, SSRF, limits, logs, destructive/audit — per §9; appendix A patterns as needed.

### Tests

- [ ] Minimum schema tests; rest by risk (§13).

---

## 15. Compatibility and changing existing tools

### 15.1. Breaking changes

Breaking change:

- tool rename;
- field removal;
- type change;
- adding new required field;
- changing field meaning;
- incompatible output change;
- merging several operations into one;
- increasing risk without updating annotations and documentation.

### 15.2. Name migration

When migrating, for example, from old prefix `redmine_mcp_`:

```text
redmine_mcp_get_issue
```

to short prefix `redmine_`:

```text
redmine_get_issue
```

follow:

1. add new name;
2. temporarily keep old alias;
3. mark old tool as deprecated in description;
4. collect metrics of old name calls;
5. remove alias after agreed period;
6. send `notifications/tools/list_changed` if server declares `listChanged`.

### 15.3. Changing descriptions

Description affects model tool selection and is considered a behavioral change. On substantial description change SHOULD review LLM selection examples or conduct repeat selection review.

### 15.4. Server version

MCP server version is returned by separate read-only tool or server metadata. Do not add `v1`, `v2` to every name without real need to support parallel incompatible contracts.

---

## 16. Rules for current Redmine MCP problems

When developing new tools, it is forbidden to repeat patterns from the audit of the current contract. Canonical rules are in corresponding sections; below is only a problem map:

| Audit problem | Section |
|---|---|
| Names without `redmine_` prefix (including third-party plugins) / mixed style within one plugin | §4.1 |
| Verb does not match semantics (`complete_*` with `done=true/false` instead of `set_*`) | §4.2 |
| Numeric ID without `minimum: 1` or with "Issue id" description | §4.3 |
| Optimistic locking as `updated_at` instead of `expected_updated_at` | §4.4, A.2 |
| Universal `manage_*` / `patch_*` and `action` parameter | §3.1, §4.2 |
| Parameters without `type`, enum only in description, arrays without `items` | §5.3, §6 |
| Parameters without `description`; too short descriptions without lookup tool reference | §6.14 |
| No `examples` on reference parameters and identifiers | §6.15 |
| Write tool with `*_id` without discovery path (no list tool and options in get response) | §6.16 |
| Description promises "exactly one of A or B", schema does not encode it | §5.3, §6.12 |
| Short tool names in cross-references (`list_projects` instead of `redmine_list_projects`) | §5.2.1 |
| Overloaded tool description half a page long | §5.2 |
| `fields` / `extra_fields` without schema; extra `required` | §6.4, §6.11 |
| `set_*` without way to clear field and without explicit refusal | §6.13 |
| One annotation set on all write tools; excess `openWorldHint` | §8 |
| `destructiveHint: true` on ordinary `update` / `rename`; wrong `openWorldHint` on `create_*` | §8.1, §8.2 |
| Description promises response structure, but `outputSchema` missing or describes only arbitrary object | §7.1 |
| Description, schema, and actual response contradict | §7.1.1 |
| STI/class names or locale dates in MCP response | §3.3 |
| `additionalProperties: true` instead of known list/get fields | §7.1 |
| Arbitrary `file_path`, project-scope bypass, SSRF | §9 |
| Email/external effect in one tool with local change | §3.2 |
| Ambiguous pairs of similar tools | §5.4 |

---

## 17. Tool set structure

The full current tool list is not duplicated in this document — it quickly becomes outdated.

**Source of truth:**

- core tools — [03-core-tools.md](03-core-tools.md) and actual `tools/list` on the installation;
- third-party plugin tools — §18 and MCP `tools/list` response on the installation.

**Grouping principles** (each group — separate atomic tools per §3):

| Group | Example intents | Prefix |
|---|---|---|
| Issues | get, list, search, create, update, delete, copy, subtasks | `redmine_` |
| Relations and watchers | list/create/delete relation; add/remove watcher | `redmine_` |
| Projects and members | projects, modules, members, roles | `redmine_` |
| Versions and categories | versions; issue categories | `redmine_` |
| Time entries | list, create, update, import, activities | `redmine_` |
| Wiki | list, get, create, update, rename, delete | `redmine_` |
| Files and attachments | list, upload, delete, download | `redmine_` |
| Admin | users, roles, server info | `redmine_admin_` or `redmine_get_server_info` |
| Plugin entities | checklists, search, etc. | `redmine_` + `plugin_id`, e.g. `redmine_advanced_search_` |

Before adding a new tool SHOULD check MCP `tools/list` response and corresponding group: do not duplicate existing tool and do not mix different intents in one name.

If a group has write tool with ID parameter (`status_id`, `role_ids`, …), the same group MUST have discovery path (§6.16).

Administrative tools are published only for users with required rights (§9.1).

---

## 18. Third-party plugin extensions

Section for authors of Redmine plugins that add tools via Extension API. Technical description of API, hooks, and edge cases — in [04-extensions.md](04-extensions.md).

Extensions follow the same contract, security, and naming rules (§3–§10, §4.1) as core tools of `redmine_mcp`.

### 18.1. When to publish what

| Primitive | When to use |
|---|---|
| **Tool** | One action on plugin entity or Redmine: create, get, update, delete, search |
| **Resource** | Large or static content by stable URI: wiki body, file, long report |
| **Prompt** | Repeatable scenario template for user, not operation with side effect |
| **`extend_tool`** | Parameter or hook logically part of existing core tool (e.g. `include_*` when reading issue) |

If the model can fulfill intent with separate tool without guessing `action` — prefer **own tool**, not `extend_tool` bloating another schema.

### 18.2. Registration

- Extension file loads at Redmine start: `lib/<plugin_id>/mcp.rb` (see `ExtensionLoader`).
- Module in `mcp.rb` MUST be `PluginName::Mcp` (`extend RedmineMcp::ExtensionApi`): Zeitwerk derives name from file.
- Before registration SHOULD check `mcp_extension_enabled?` — hard dependency on `redmine_mcp` in gemspec is not required.
- Use `register_tool_once` for registration so reload does not duplicate tool.
- Full name in `tools/list` MUST start with `redmine_` (§4.1).
- Tool MUST have `title`, `description`, `input_schema`, `output_schema`, `permission`, and `annotations`; name duplication forbidden.
- Tool is visible in MCP `tools/list` response only to users with corresponding permission.

### 18.3. Naming

- Name MUST start with `redmine_`; then — `plugin_id` and `<verb>_<entity>`: `redmine_redmine_advanced_checklists_<verb>_<entity>`, `redmine_advanced_search_<verb>_<entity>`.
- Verbs and `manage_*` prohibition — per §4.2 and §3.1.
- Do not copy core tool names and do not publish second tool with same intent under different name.

Before registration SHOULD compare with `tools/list` response on target installation.

### 18.4. Permissions and security

- `permission` MUST match real Redmine or plugin permissions, not separate "mcp-only" role.
- For issue operations SHOULD use `register_issue_tool` and `find_accessible_issue` instead of copying visibility and project module checks.
- If `module_name` is set, tool MUST be in `tools/list` only when user has declared permission in at least one visible project with enabled module. Without `module_name`, permission in at least one visible project is enough. Handler still checks specific issue, including its project module.
- Repeated server-side argument and permission validation in handler — per §3.4 and §9, even if tool is hidden from `tools/list` for other users.

### 18.5. Clean implementation

**Thin MCP layer.** `mcp.rb` should contain mainly tool registration: schemas, descriptions, permissions, annotations, and short handlers. Handler validates arguments, checks context, and delegates execution to separate class/service.

Plugin business logic should remain in ordinary models and services and not depend on MCP.

If logic is needed only for MCP — e.g. merging data from several models, normalizing REST response to MCP contract, computing derived fields, or preparing tool result — MAY move it to separate `mcp_tools.rb`. If such file becomes large, SHOULD split into classes by entity or operation, e.g. `mcp_tools/clients.rb`, `mcp_tools/deals.rb`, `mcp_tools/subscriptions.rb`.

Do not place business logic and large transformations directly in lambda/handler inside `mcp.rb`.

**Data access.**

- Plugin models and services — if logic is already there.
- `internal_request` / `internal_get` / REST — if need to reuse existing API controller; endpoint must support `accept_api_auth`. Use `internal_request` for `POST`, `PUT`, `PATCH`, and `DELETE`; use `internal_get` or `internal_request(method: 'GET', ...)` for reads. Check failures with `internal_request_error?`.

**`extend_tool` — moderately.** Appropriate when parameter is part of one intent with core tool. Inappropriate when plugin essentially adds separate subsystem: better own prefix and own tools, link to core described in `description` or server instructions.

**Contract like core.** Input — per §6. Output — per §7.1 and §7.1.1: stable fields, `required`, `enum`/`const`, units, internal API normalization. Annotations by risk, fixable errors (§8, §10). Optimistic locking — `expected_updated_at` (§4.4). Every parameter — `description` (§6.14). Cross-references — full names (§5.2.1). Every write parameter `*_id` — discovery path (§6.16): separate `list_*` or options with `id` in get/list response, and explicit reference in parameter description.

Before publishing extension tool MUST verify source serializer / service / REST endpoint and at least one real successful response for each result form.

**Shared code — in `redmine_mcp`.** When developing extension, if a fragment may be needed by another MCP plugin, SHOULD add it to core `redmine_mcp` immediately, not copy to `lib/<plugin>/mcp*.rb`.

Criterion: logic is not tied to one plugin domain (checklists, search, …) and describes MCP contract, Extension API, or typical integration pattern.

| Where | What |
|------|-----|
| **`redmine_mcp`** | `SchemaNormalizer.envelope_output`, `REST_OBJECT_SCHEMA` / `REST_ARRAY_SCHEMA`, `ExtensionApi` extension (`register_issue_tool`, `issue_permission`, `internal_request`, …), `ToolResponse`, common permission helpers by `issue_id` / `project_id` |
| **Plugin extension** | `mcp.rb` — tool registration and short handlers; `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-specific fetch, aggregation, normalization; ordinary models/services — business logic not depending on MCP |

**Recommended placement for extension:**

- `mcp.rb` — tool registration and short handlers;
- `mcp_tools.rb` / `mcp_tools/*.rb` — MCP-specific fetch, aggregation, and data normalization;
- ordinary models/services — business logic not depending on MCP.

Before copying helper from another extension SHOULD check if analogue already exists in `redmine_mcp`; if absent — move to core in same PR, do not duplicate.

More on extension API — [04-extensions.md](04-extensions.md) (§ "ExtensionApi helper methods").

### 18.6. Anti-patterns

FORBIDDEN or not recommended:

- registering tools on every HTTP request;
- failing on neighbor plugin error at start;
- mixing read, write, and admin in one tool;
- duplicating core tool "with different name";
- extending another tool with optional parameters "for the future";
- returning in MCP internal fields unavailable to user in plugin UI/API;
- publishing STI class names, locale dates, or REST representation if MCP schema defines different contract (§3.3, §7.1.1);
- describing list element only as `{ "type": "object", "additionalProperties": true }` (§7.1);
- publishing `set_*_status` / similar with `status_id` without giving model way to know allowed IDs (§6.16);
- duplicating common MCP helpers in extension (envelope `outputSchema`, `internal_request` wrappers, issue permission) if their place is in `redmine_mcp` — see §18.5.

### 18.7. Pre-merge verification

- [ ] Tool name starts with `redmine_` per §4.1 / §18.3.
- [ ] Extension loads at start; tool appears in `tools/list` for user with rights.
- [ ] Tool absent for user without rights and when plugin MCP extension flag disabled.
- [ ] Contract and checklist (§14) satisfied, including description / outputSchema / actual response comparison (§7.1.1); tests per §13 if needed.
- [ ] Serializer / REST / service verified on at least one real successful response for each published result form (e.g. list and get if both published).
- [ ] No duplication of existing tool in `tools/list`.
- [ ] For each `*_id` write parameter there is discovery path (§6.16).

---

## 19. Sources and normative base

Document prepared as of 2026-07-22 based on the following primary sources:

1. Model Context Protocol, **Protocol Revision 2025-11-25**  
   https://modelcontextprotocol.io/specification/2025-11-25

2. Model Context Protocol, **Tools**  
   https://modelcontextprotocol.io/specification/2025-11-25/server/tools

3. Model Context Protocol, **Schema Reference**  
   https://modelcontextprotocol.io/specification/2025-11-25/schema

4. Model Context Protocol, **Security Best Practices**  
   https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices

5. Model Context Protocol, **Understanding Authorization in MCP**  
   https://modelcontextprotocol.io/docs/tutorials/security/authorization

6. Model Context Protocol Blog, **Tool Annotations as Risk Vocabulary: What Hints Can and Can't Do**  
   https://blog.modelcontextprotocol.io/posts/2026-03-16-tool-annotations/

7. Model Context Protocol Blog, **Server Instructions: Giving LLMs a user manual for your server**  
   https://blog.modelcontextprotocol.io/posts/2025-11-03-using-server-instructions/

8. JSON Schema, **Reference**  
   https://json-schema.org/understanding-json-schema/reference

9. JSON Schema, **Enumerated values**  
   https://json-schema.org/understanding-json-schema/reference/enum

10. JSON Schema, **Conditional schema validation**  
    https://json-schema.org/understanding-json-schema/reference/conditionals

11. Redmine, **REST API overview**  
    https://www.redmine.org/projects/redmine/wiki/rest_api

12. Redmine, **REST Issues**  
    https://www.redmine.org/projects/redmine/wiki/Rest_Issues

13. Redmine, **REST API changes**  
    Link `API changes for each version` on REST API page; verified for all supported versions.

---

## 20. New tool readiness criterion

A new MCP tool is considered ready when mandatory code review checklist items (§14) are satisfied.

For third-party plugin tools additionally — checklist §18.7.

Risk recommendations: coverage report (§5.7), additional tests §13.2–13.6 and appendix A. Minimum schema tests (§13.1) and `outputSchema` rules (§7.1, §7.1.1) are mandatory.

---

## Appendix A. Recommended implementation patterns

Patterns below are not mandatory for every MCP tool. SHOULD consider them for elevated risk: destructive operations, admin tools, bulk write, external side effects, repeated calls due to timeout.

### A.1. Two-phase deletion (prepare / confirm)

For especially dangerous administrative operations:

1. `redmine_prepare_delete_*` returns brief consequence description and one-time token;
2. `redmine_confirm_delete_*` accepts token with short TTL.

Normative requirements for destructive operations — in §9.5.

### A.2. Optimistic locking

For update/delete under concurrent change, parameter MUST be named `expected_updated_at` (§4.4), not `updated_at`:

```json
"expected_updated_at": {
  "type": "string",
  "format": "date-time",
  "description": "Reject the operation if the object changed after this timestamp."
}
```

Name is unified for core tools and extensions (including checklist write tools).

On conflict returns `CONFLICT`, actual object modification time (`updated_at` / `updated_on` in response), and recommendation to re-read object.

### A.3. Idempotency key

For operations where repeat due to timeout may create duplicate:

```json
"idempotency_key": {
  "type": "string",
  "minLength": 8,
  "maxLength": 128
}
```

Especially appropriate for:

- issue creation;
- time entry import;
- file upload;
- bulk operations;
- email sending.

If tool publishes `idempotentHint: true`, repeated call must be safe (§8.2); `idempotency_key` is one way to ensure that.

---

## Appendix B. Full tool example

Reference `redmine_create_issue`. When error format or envelope changes, update §7, §10, and this section; §12 remains abbreviated.

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

Note: if server guarantees idempotency when `idempotency_key` is present, annotation still describes tool as a whole. Therefore safe value remains `false` if call without key is allowed.

